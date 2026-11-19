// Restores configuration files (settings, camera calibration) from a backup
// tgz made by the remove flow (or the updater's on-kiosk backups). Only the
// data/ directory is restored — the docker-compose.yml inside a backup is
// deliberately ignored: it is infrastructure owned by the updater, and an old
// copy could reference an image that is no longer on the kiosk. The port
// file data/server_config.json is infrastructure too (ruling R12): it must
// agree with the compose `ports:` line and the avahi announcement, which stay,
// so the board keeps its server port.
import 'dart:io';

import 'engine.dart';
import 'kiosk.dart';
import 'port_engine.dart' show PortEngine;
import 'server_port.dart' show kDefaultPort, readBoardPort;
import '../services/ssh_runner.dart';

class RestoreEngine extends KioskEngine {
  RestoreEngine({
    required super.host,
    required super.user,
    required super.password,
    required this.backupFile,
    required super.onChanged,
    required super.onLog,
  });

  final File backupFile;

  static const _remoteTgz = '/tmp/facesnap_restore.tgz';

  /// The kiosk's data/ as it was before the restore (FL-7): the extract
  /// merges the backup over data/, so this is the only way back. The next
  /// restore replaces it.
  static const snapshotPath = '$kKioskDir/data_before_restore.tgz';

  /// The summary line of a restore: the column settings (spec 2026-10-10
  /// section 2) are the column's, from its LED board - the restored settings
  /// files' values of them are replaced at the server's next start.
  static const columnSettingsNote =
      "The column's settings (LED, calibration, focus …) come from the column's "
      "LED board; to keep the backup's values, save them on the Column page.";

  /// The command that puts a backup's data/ in place (and removes the upload).
  /// data/column_profile/ is left out (spec 2026-10-10 section 5.6): the
  /// column's profile lives on its LED board, and an old pending save from a
  /// backup would be written over the column's newer standard at the next
  /// connect. The kiosk keeps its own column_profile/ folder as it is.
  /// data/server_config.json is left out too (ruling R12): a backup's port
  /// behind the board's unchanged compose mapping would leave the kiosk
  /// unreachable.
  static String extractCommand(String remoteTgz) =>
      'mkdir -p $kKioskDir && tar xzf $remoteTgz -C $kKioskDir '
      '${notRestored.map((x) => "--exclude='$x' ").join()}data && '
      'rm -f $remoteTgz';

  /// The archive members [extractCommand] leaves out (a member or everything
  /// under it, as GNU tar's --exclude matches).
  static const notRestored = ['data/column_profile', 'data/server_config.json'];

  static bool _isRestored(String member) =>
      !notRestored.any((x) => member == x || member.startsWith('$x/'));

  @override
  final List<UpdateStep> steps = [
    UpdateStep('Connect to the kiosk'),
    UpdateStep('Inspect the current installation'),
    UpdateStep('Upload and validate the backup'),
    UpdateStep('Stop the server'),
    UpdateStep('Restore configuration files'),
    UpdateStep('Start the server'),
    UpdateStep('Verify'),
  ];

  bool _serverInstalled = false;

  /// The board's server port (data/server_config.json, kept by the restore).
  int _port = kDefaultPort;

  /// GetKioskInfo through the SSH forward on the board's 127.0.0.1:port
  /// ([PortEngine.defaultCheckServer]): the port the server reports, null
  /// when it does not answer. A test seam, like [delay].
  Future<int?> Function(SshRunner ssh, int port) checkServer =
      PortEngine.defaultCheckServer;

  UpdateStep get _connect => steps[0];
  UpdateStep get _inspect => steps[1];
  UpdateStep get _upload => steps[2];
  UpdateStep get _stop => steps[3];
  UpdateStep get _restore => steps[4];
  UpdateStep get _start => steps[5];
  UpdateStep get _verify => steps[6];

  Future<bool> run() => runGuarded('Restore', () async {
        await connectStep(_connect);
        await _doInspect();
        await _doUpload();
        await _doStop();
        try {
          await _doRestore();
          await _doStart();
          await _doVerify();
        } catch (_) {
          // The server was stopped for the restore: start it again whatever
          // the restore left, so a failure never leaves the kiosk down (FL-1).
          if (_serverInstalled) {
            log('Starting the server again …');
            try {
              await ssh.run('systemctl start $kServiceUnit');
            } catch (e) {
              log('The server could not be started: ${shorten('$e')}');
            }
          }
          rethrow;
        }
        return true;
      }, beforeClose: () async {
        await sshOrNull?.run('rm -f $_remoteTgz');
      });

  Future<void> _doInspect() async {
    setStep(_inspect, StepStatus.running);
    // A first-generation board's server reads the settings files next to
    // its compose file, not data/ (FL-8): a restore there would change
    // nothing the server reads and still report success.
    final compose = await ssh.run('cat $kCompose');
    if (compose.ok && isLegacyCompose(compose.stdout)) {
      throw Exception('This kiosk has the first-generation layout (no data/ '
          'folder), which a restore does not reach: update this kiosk to a '
          'data/ server first, then restore.');
    }
    _serverInstalled =
        (await ssh.run('test -f /etc/systemd/system/$kServiceUnit')).ok;
    final running =
        (await ssh.run("docker ps $kContainerFilter --format '{{.Names}}'"))
            .stdout
            .trim()
            .isNotEmpty;
    setStep(
        _inspect,
        StepStatus.ok,
        _serverInstalled
            ? 'server installed${running ? ', running' : ''}'
            : 'server not installed');
    log(_serverInstalled
        ? 'Server installed${running ? ' and running' : ''} — it will be '
            'restarted around the restore.'
        : 'No server installed — the restored settings will be used by a '
            'future install.');
  }

  Future<void> _doUpload() async {
    setStep(_upload, StepStatus.running);
    log('Uploading ${basenameOf(backupFile.path)} …');
    final upload = await ssh.runWithFileStdin('cat > $_remoteTgz', backupFile);
    if (!upload.ok) {
      throw Exception('Upload failed:\n${upload.combined}');
    }
    // Validate: must be a readable tgz containing a data/ directory.
    final listing = await ssh.run('tar tzf $_remoteTgz');
    if (!listing.ok) {
      throw Exception('The selected file is not a readable backup archive '
          '(.tgz):\n${listing.stderr}');
    }
    final entries =
        listing.stdout.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final json =
        entries.where((e) => e.startsWith('data/') && e.endsWith('.json')).toList();
    if (json.isEmpty) {
      throw Exception('The archive contains no configuration files '
          '(no data/*.json entries) — is this a FaceSnap backup?');
    }
    // Only what the extract puts in place counts: not the port file (R12) nor
    // the column profile.
    final settings = json
        .where(_isRestored)
        .map((e) => e.substring('data/'.length))
        .toList();
    setStep(_upload, StepStatus.ok, '${settings.length} settings file(s)');
    log('Backup is valid. Configuration files: '
        '${settings.isEmpty ? 'none to restore' : settings.join(', ')}');
  }

  Future<void> _doStop() async {
    if (!_serverInstalled) {
      setStep(_stop, StepStatus.skipped, 'server not installed');
      return;
    }
    setStep(_stop, StepStatus.running);
    await ssh.run('systemctl stop $kServiceUnit');
    setStep(_stop, StepStatus.ok);
    log('Server stopped.');
  }

  Future<void> _doRestore() async {
    setStep(_restore, StepStatus.running);
    // Keep today's data/ first (FL-7): a failed snapshot stops the restore
    // before anything is overwritten.
    final hasData = (await ssh.run('test -d $kKioskDir/data')).ok;
    if (hasData) {
      await ssh.runChecked('tar czf $snapshotPath -C $kKioskDir data');
      log('The current settings are kept in $snapshotPath.');
    } else {
      log('The kiosk has no data/ folder yet — nothing to keep before the '
          'restore.');
    }
    // Only data/ is restored; a compose file in the archive is ignored (see
    // the header comment).
    await ssh.runChecked(extractCommand(_remoteTgz));
    final restored = await ssh.runChecked('ls $kKioskDir/data/');
    final files = restored.stdout
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && _isRestored('data/$l'))
        .join(', ');
    setStep(_restore, StepStatus.ok);
    log('Restored into $kKioskDir/data: $files');
    _port = await readBoardPort(ssh, onWarning: (w) => log('WARNING: $w'));
    log('The board keeps its server port ($_port).');
    summary
      ..add('Configuration restored from ${basenameOf(backupFile.path)}.')
      ..add(columnSettingsNote);
    if (hasData) {
      summary.add('The settings from before the restore are kept on the '
          'kiosk as $snapshotPath.');
    }
  }

  Future<void> _doStart() async {
    if (!_serverInstalled) {
      setStep(_start, StepStatus.skipped, 'server not installed');
      summary.add('No server installed — the settings are in place for a '
          'future install.');
      return;
    }
    setStep(_start, StepStatus.running);
    await ssh.runChecked('systemctl start $kServiceUnit',
        timeout: const Duration(minutes: 4));
    setStep(_start, StepStatus.ok);
    log('Server starting …');
  }

  Future<void> _doVerify() async {
    if (!_serverInstalled) {
      setStep(_verify, StepStatus.skipped);
      return;
    }
    setStep(_verify, StepStatus.running);
    var bound = false;
    for (var i = 0; i < 36; i++) {
      await pause(const Duration(seconds: 5));
      final logs = await containerLogs(400);
      if (kServerReadyMarker.hasMatch(logs)) {
        bound = true;
        break;
      }
      setStep(
          _verify, StepStatus.running, 'waiting for server boot (${(i + 1) * 5}s)');
    }
    if (!bound) {
      throw Exception('The server did not come back up within 3 minutes '
          'after the restore.');
    }
    // The ready marker appears whatever port the server bound (X-12).
    int? answered;
    for (var i = 0; i < 6 && answered == null; i++) {
      if (i > 0) await pause(const Duration(seconds: 5));
      answered = await checkServer(ssh, _port);
    }
    if (answered == null) {
      throw Exception('The server reported ready but does not answer '
          "GetKioskInfo on port $_port (the board's port) after the restore.");
    }
    log('GetKioskInfo answers on port $_port.');
    setStep(_verify, StepStatus.ok, 'server running with restored settings');
    log('Server is up with the restored configuration.');
    summary.add('Server restarted and running.');
  }
}
