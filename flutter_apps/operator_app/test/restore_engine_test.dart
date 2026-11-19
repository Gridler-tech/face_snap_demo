// The updater's config restore and the column profile (spec 2026-10-10 section 5.6, final
// review I-2): a backup's data/column_profile/ (the column's cached profile and a save that
// waited for its board) is never restored - an old pending save would be written over the
// column's newer standard at the next connect - and the summary says where the nine column
// settings come from. The port file data/server_config.json is never restored either
// (ruling R12): the board keeps its server port, which its compose mapping and avahi
// announcement (both kept) agree with. No real SSH: a scripted board whose `tar xzf`
// applies the command's --exclude patterns to the archive. The verify's
// GetKioskInfo (X-12) goes through the board's SSH forward to an in-process
// fake Kiosk server.
import 'dart:io';

import 'package:dartssh2/dartssh2.dart' show SSHSocket;
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/updater/engine.dart';
import 'package:operator_app/updater/kiosk.dart';
import 'package:operator_app/updater/restore_engine.dart';
import 'package:operator_app/updater/server_port.dart';

import 'fake_server.dart';
import 'scripted_ssh.dart';

/// The board's gRPC server as GetKioskInfo sees it (started once).
late Server _kioskServer;

/// A board with the server installed and running; [files] is its disk
/// (path → content), [archive] the uploaded backup (member → content).
/// [extractFails]: `tar xzf` fails (a corrupt archive, a full disk);
/// [snapshotFails]: the `tar czf` of the current data/ fails (FL-7).
/// [answers]: whether the server answers GetKioskInfo on a port (default:
/// on every port).
ScriptedSsh _board(Map<String, String> files, Map<String, String> archive,
    {bool extractFails = false,
    bool snapshotFails = false,
    bool Function(int port)? answers}) {
  final ssh = ScriptedSsh()
    ..onForward = (host, port) async {
      if (answers?.call(port) ?? true) return SSHSocket.connect('127.0.0.1', _kioskServer.port!);
      throw const SocketException('Connection refused');
    };
  ssh
    ..onCall(RegExp('^test -d ${RegExp.escape(kKioskDir)}/data\$'), (_) => CmdResult(
        files.keys.any((p) => p.startsWith('$kKioskDir/data/')) ? 0 : 1, '', ''))
    ..onCall(RegExp(r'^tar czf '), (_) => snapshotFails
        ? CmdResult(2, '', 'tar: write error: No space left on device')
        : CmdResult(0, '', ''))
    ..on(RegExp(r'^uname -m$'), CmdResult(0, 'aarch64\n', ''))
    ..on(RegExp('device-tree/model'), CmdResult(0, 'Radxa Dragon Q6A', ''))
    ..on(RegExp('^test -f /etc/systemd/system/'), CmdResult(0, '', ''))
    ..on(RegExp(r"^docker ps --filter name=face_snap --format '\{\{\.Names\}\}'$"),
        CmdResult(0, 'face_snap-face_snap-1\n', ''))
    ..on(RegExp(r'^cat > /tmp/facesnap_restore\.tgz$'), CmdResult(0, '', ''))
    ..on(RegExp(r'^tar tzf '), CmdResult(0, '${archive.keys.join('\n')}\n', ''))
    ..on(RegExp(r'^systemctl (stop|start) '), CmdResult(0, '', ''))
    ..onCall(RegExp(r'tar xzf '), (command) {
      if (extractFails) return CmdResult(2, '', 'tar: Unexpected EOF in archive');
      // GNU tar: an --exclude pattern matches a member or everything under it.
      final excluded = RegExp(r"--exclude='([^']+)'")
          .allMatches(command)
          .map((m) => m.group(1)!)
          .toList();
      for (final e in archive.entries) {
        if (excluded.any((x) => e.key == x || e.key.startsWith('$x/'))) continue;
        files['$kKioskDir/${e.key}'] = e.value;
      }
      return CmdResult(0, '', '');
    })
    ..onCall(RegExp('^ls ${RegExp.escape(kKioskDir)}/data/\$'), (_) => CmdResult(
        0,
        files.keys
            .where((p) => p.startsWith('$kKioskDir/data/'))
            .map((p) => p.substring('$kKioskDir/data/'.length))
            .join('\n'),
        ''))
    ..onCall(RegExp('^test -f ${RegExp.escape(kBoardPortFile)} && cat'), (_) {
      final text = files[kBoardPortFile];
      return text == null ? CmdResult(1, '', '') : CmdResult(0, text, '');
    })
    ..on(RegExp(r'^docker ps -q '), CmdResult(0, 'abc123\n', ''))
    ..on(RegExp(r'^docker logs '), CmdResult(0, 'Server 2.0 bound to port 50052\n', ''))
    ..on(RegExp(r'^rm -f '), CmdResult(0, '', ''));
  return ssh;
}

class _Engine extends RestoreEngine {
  _Engine(this.fake, File backup, List<String> logs)
      : super(
            host: 'kiosk',
            user: 'root',
            password: 'x',
            backupFile: backup,
            onChanged: () {},
            onLog: logs.add) {
    delay = (_) async {}; // no real waits in the verify polls
  }
  final SshRunner fake;

  @override
  Future<SshRunner> openSsh() async => fake;
}

void main() {
  setUpAll(() async => _kioskServer = await serveFakes([_Kiosk()]));
  tearDownAll(() => _kioskServer.shutdown());

  test('the restore extracts data/ without the column profile folder or the port file', () {
    final command = RestoreEngine.extractCommand('/tmp/x.tgz');
    expect(command, contains('tar xzf /tmp/x.tgz -C $kKioskDir '));
    expect(command, contains("--exclude='data/column_profile'"));
    expect(command, contains("--exclude='data/server_config.json'"));
    expect(command.indexOf('--exclude'), lessThan(command.lastIndexOf(' data ')),
        reason: 'the exclusions come before the member they filter');
    expect(command, endsWith('rm -f /tmp/x.tgz'));
  });

  test('the summary says the column settings come from the column', () {
    expect(RestoreEngine.columnSettingsNote,
        contains("come from the column's LED board"));
    expect(RestoreEngine.columnSettingsNote, contains('Column page'));
  });

  test('C1/R12: a backup with port 50051, the board on 50052 → the port file stays, '
      'the log says so', () async {
    final dir = await Directory.systemTemp.createTemp('restore_port_');
    addTearDown(() => dir.delete(recursive: true));
    final backup = File('${dir.path}${Platform.pathSeparator}backup.tgz')
      ..writeAsStringSync('tgz bytes');
    final files = {
      kBoardPortFile: portFileContent(50052),
      '$kKioskDir/data/kiosk_settings.json': '{"old": true}',
    };
    final ssh = _board(files, {
      'data/kiosk_settings.json': '{"restored": true}',
      'data/server_config.json': portFileContent(50051),
      'data/column_profile/pending.json': '{}',
    });
    final logs = <String>[];

    final ok = await _Engine(ssh, backup, logs).run();

    expect(ok, isTrue, reason: logs.join('\n'));
    expect(files['$kKioskDir/data/kiosk_settings.json'], '{"restored": true}',
        reason: 'the settings are restored');
    expect(files[kBoardPortFile], portFileContent(50052), reason: 'the port file is not');
    expect(files.keys, isNot(contains('$kKioskDir/data/column_profile/pending.json')));
    expect(logs, contains('The board keeps its server port (50052).'));
    // Only what is put in place is counted and listed as restored.
    expect(logs, contains('Backup is valid. Configuration files: kiosk_settings.json'));
    expect(logs, contains('Restored into $kKioskDir/data: kiosk_settings.json'));
    expect(logs.join('\n'), isNot(contains('server_config.json')));
    expect(ssh.writes, isEmpty);
  });

  test('FL-1: the extract fails after the stop → the server is started again, the restore fails',
      () async {
    final dir = await Directory.systemTemp.createTemp('restore_fail_');
    addTearDown(() => dir.delete(recursive: true));
    final backup = File('${dir.path}${Platform.pathSeparator}backup.tgz')
      ..writeAsStringSync('tgz bytes');
    final ssh = _board({}, {'data/kiosk_settings.json': '{}'}, extractFails: true);
    final logs = <String>[];

    final ok = await _Engine(ssh, backup, logs).run();

    expect(ok, isFalse);
    final stop = ssh.commands.indexOf('systemctl stop $kServiceUnit');
    expect(stop, greaterThan(0));
    expect(ssh.commands.sublist(stop), contains('systemctl start $kServiceUnit'),
        reason: logs.join('\n'));
  });

  group('X-12: the restore verify needs GetKioskInfo on the board port', () {
    Future<File> backupFile() async {
      final dir = await Directory.systemTemp.createTemp('restore_x12_');
      addTearDown(() => dir.delete(recursive: true));
      return File('${dir.path}${Platform.pathSeparator}backup.tgz')..writeAsStringSync('tgz');
    }

    test('the server answers on the board port 50052 → restored and verified', () async {
      final files = {kBoardPortFile: portFileContent(50052)};
      final ssh = _board(files, {'data/kiosk_settings.json': '{}'},
          answers: (port) => port == 50052);
      final logs = <String>[];

      final ok = await _Engine(ssh, await backupFile(), logs).run();

      expect(ok, isTrue, reason: logs.join('\n'));
      expect(ssh.commands, contains('forward 127.0.0.1:50052'));
    });

    test('the ready marker but no answer on port 50052 → the restore fails', () async {
      final files = {kBoardPortFile: portFileContent(50052)};
      final ssh = _board(files, {'data/kiosk_settings.json': '{}'}, answers: (_) => false);
      final logs = <String>[];
      final engine = _Engine(ssh, await backupFile(), logs);

      final ok = await engine.run();

      expect(ok, isFalse, reason: logs.join('\n'));
      expect(ssh.commands, contains('forward 127.0.0.1:50052'));
      expect(engine.summary.join('\n'), contains('does not answer GetKioskInfo on port 50052'));
      expect(engine.steps.last.status, StepStatus.fail);
    });
  });

  group('FL-7: a snapshot of the current data/ before the extract', () {
    const snapshot = '$kKioskDir/data_before_restore.tgz';
    const snapshotCmd = 'tar czf $snapshot -C $kKioskDir data';

    Future<File> backupFile() async {
      final dir = await Directory.systemTemp.createTemp('restore_fl7_');
      addTearDown(() => dir.delete(recursive: true));
      return File('${dir.path}${Platform.pathSeparator}backup.tgz')..writeAsStringSync('tgz');
    }

    test('the snapshot runs before the extract, and the summary names it', () async {
      final files = {'$kKioskDir/data/light_settings.json': '{"today": true}'};
      final ssh = _board(files, {'data/light_settings.json': '{"old": true}'});
      final logs = <String>[];
      final engine = _Engine(ssh, await backupFile(), logs);

      expect(await engine.run(), isTrue, reason: logs.join('\n'));

      final snap = ssh.commands.indexOf(snapshotCmd);
      expect(snap, isNonNegative, reason: ssh.commands.join('\n'));
      expect(ssh.commands.indexWhere((c) => c.contains('tar xzf')), greaterThan(snap));
      expect(engine.summary.join('\n'), contains(snapshot));
    });

    test('a failing snapshot stops the restore; the server is started again', () async {
      final files = {'$kKioskDir/data/light_settings.json': '{"today": true}'};
      final ssh = _board(files, {'data/light_settings.json': '{"old": true}'}, snapshotFails: true);
      final logs = <String>[];
      final engine = _Engine(ssh, await backupFile(), logs);

      expect(await engine.run(), isFalse);

      expect(ssh.commands, contains(snapshotCmd));
      expect(ssh.commands.where((c) => c.contains('tar xzf')), isEmpty, reason: 'nothing extracted');
      expect(files['$kKioskDir/data/light_settings.json'], '{"today": true}');
      final stop = ssh.commands.indexOf('systemctl stop $kServiceUnit');
      expect(ssh.commands.sublist(stop), contains('systemctl start $kServiceUnit'));
      expect(engine.summary.join('\n'), contains('No space left on device'));
    });

    test('no data/ yet: nothing to snapshot, the restore goes on', () async {
      final files = <String, String>{};
      final ssh = _board(files, {'data/kiosk_settings.json': '{}'});
      final logs = <String>[];
      final engine = _Engine(ssh, await backupFile(), logs);

      expect(await engine.run(), isTrue, reason: logs.join('\n'));

      expect(ssh.commands, isNot(contains(snapshotCmd)));
      expect(logs.join('\n'), contains('no data/ folder yet'));
      expect(engine.summary.join('\n'), isNot(contains(snapshot)));
    });
  });
}

class _Kiosk extends KioskServiceBase {
  @override
  Future<KioskInfoResponse> getKioskInfo(ServiceCall call, Empty request) async =>
      KioskInfoResponse(kioskInfo: KioskInfo(port: '50052'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}
