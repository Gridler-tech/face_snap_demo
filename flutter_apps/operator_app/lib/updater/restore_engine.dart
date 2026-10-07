// Restores configuration files (settings, camera calibration) from a backup
// tgz made by the remove flow (or the updater's on-kiosk backups). Only the
// data/ directory is restored — the docker-compose.yml inside a backup is
// deliberately ignored: it is infrastructure owned by the updater, and an old
// copy could reference an image that is no longer on the kiosk.
import 'dart:io';

import 'engine.dart';
import 'kiosk.dart';

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
        await _doRestore();
        await _doStart();
        await _doVerify();
        return true;
      }, beforeClose: () async {
        await sshOrNull?.run('rm -f $_remoteTgz');
      });

  Future<void> _doInspect() async {
    setStep(_inspect, StepStatus.running);
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
    final settings = entries
        .where((e) => e.startsWith('data/') && e.endsWith('.json'))
        .map((e) => e.substring('data/'.length))
        .toList();
    if (settings.isEmpty) {
      throw Exception('The archive contains no configuration files '
          '(no data/*.json entries) — is this a FaceSnap backup?');
    }
    setStep(_upload, StepStatus.ok, '${settings.length} settings file(s)');
    log('Backup is valid. Configuration files: ${settings.join(', ')}');
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
    // Only data/ is restored; a compose file in the archive is ignored (see
    // the header comment).
    await ssh.runChecked(
        'mkdir -p $kKioskDir && tar xzf $_remoteTgz -C $kKioskDir data && '
        'rm -f $_remoteTgz');
    final restored = await ssh.runChecked('ls $kKioskDir/data/');
    final files = restored.stdout
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .join(', ');
    setStep(_restore, StepStatus.ok);
    log('Restored into $kKioskDir/data: $files');
    summary
        .add('Configuration restored from ${basenameOf(backupFile.path)}.');
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
      await Future<void>.delayed(const Duration(seconds: 5));
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
    setStep(_verify, StepStatus.ok, 'server running with restored settings');
    log('Server is up with the restored configuration.');
    summary.add('Server restarted and running.');
  }
}
