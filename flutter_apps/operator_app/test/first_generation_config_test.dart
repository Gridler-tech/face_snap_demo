// FL-8: a first-generation board (face_snap:1.4.x) keeps its settings files
// next to docker-compose.yml, with no data/ folder. Backup and Remove's
// backup archive those files (Remove with "delete configs" must not lose the
// only calibration copy), and Restore — which writes data/ — refuses such a
// board instead of reporting a restore its server never reads. On the
// scripted SSH fake; no board.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/updater/backup_engine.dart';
import 'package:operator_app/updater/engine.dart';
import 'package:operator_app/updater/kiosk.dart';
import 'package:operator_app/updater/remove_engine.dart';
import 'package:operator_app/updater/restore_engine.dart';

import 'scripted_ssh.dart';

const _image = 'face_snap:1.4.3';

/// The tar a first-generation backup must run: the compose file and the
/// three settings files next to it (no data/).
const _legacyTar = 'cd $kKioskDir && tar czf $kConfigBackupTgz '
    'docker-compose.yml camera_settings.json kiosk_settings.json light_settings.json';

/// A first-generation board: compose + the three settings files in
/// /root/face_snap, no data/; the server installed and running.
ScriptedSsh _legacyBoard() {
  var removed = false;
  var unit = true;
  CmdResult ok([String out = '']) => CmdResult(0, out, '');
  final ssh = ScriptedSsh()
    ..remoteFiles[kConfigBackupTgz] = 'tgz bytes'
    ..on(RegExp(r'^uname -m$'), ok('aarch64\n'))
    ..on(RegExp('device-tree/model'), ok('ODROID-N2Plus'))
    // What exists in /root/face_snap (ls -d of the backup's members).
    ..on(RegExp('^cd ${RegExp.escape(kKioskDir)} && ls -d '),
        CmdResult(2, 'docker-compose.yml\n${kSettingsFiles.join('\n')}\n',
            "ls: cannot access 'data': No such file or directory"))
    ..on(RegExp('^test -d ${RegExp.escape(kKioskDir)}/data\$'), CmdResult(1, '', ''))
    ..on(RegExp('^test -d ${RegExp.escape(kKioskDir)}\$'), ok())
    ..on(RegExp('^cd ${RegExp.escape(kKioskDir)} && tar czf '), ok())
    ..on(RegExp('^cat ${RegExp.escape(kCompose)}\$'), ok(legacyComposeTemplate(_image)))
    ..on(RegExp(RegExp.escape(composeImageCmd(kCompose, tolerateMissing: true))), ok('$_image\n'))
    ..onCall(RegExp(r'^docker images '), (_) => ok(removed ? '' : '$_image\n'))
    ..onCall(RegExp(r'^docker rmi '), (_) {
      removed = true;
      return ok();
    })
    ..onCall(RegExp('^test -f /etc/systemd/system/'), (_) => CmdResult(unit ? 0 : 1, '', ''))
    ..on(RegExp(r'^docker ps '), ok())
    ..on(RegExp(r'^docker image prune'), ok())
    ..on(RegExp(r'^systemctl '), ok())
    ..onCall(RegExp(r'^rm -f /etc/systemd/system/'), (_) {
      unit = false;
      return ok();
    })
    ..on(RegExp(r'^find '), ok())
    ..on(RegExp(r'^rm -rf '), ok())
    ..on(RegExp(r'^rm -f '), ok())
    ..on(RegExp(r'^df '), ok('8000000000\n'));
  return ssh;
}

class _Backup extends BackupEngine {
  _Backup(this.fake, String path, List<String> logs)
      : super(host: 'kiosk', user: 'root', password: 'x', backupPath: path,
            onChanged: () {}, onLog: logs.add);
  final SshRunner fake;
  @override
  Future<SshRunner> openSsh() async => fake;
}

class _Remove extends RemoveEngine {
  _Remove(this.fake, String path, List<String> logs)
      : super(host: 'kiosk', user: 'root', password: 'x', deleteConfigs: true,
            backupPath: path, onChanged: () {}, onLog: logs.add);
  final SshRunner fake;
  @override
  Future<SshRunner> openSsh() async => fake;
}

class _Restore extends RestoreEngine {
  _Restore(this.fake, File backup, List<String> logs)
      : super(host: 'kiosk', user: 'root', password: 'x', backupFile: backup,
            onChanged: () {}, onLog: logs.add) {
    delay = (_) async {};
  }
  final SshRunner fake;
  @override
  Future<SshRunner> openSsh() async => fake;
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('first_gen_'));
  tearDown(() => dir.deleteSync(recursive: true));
  String local(String name) => '${dir.path}${Platform.pathSeparator}$name';

  test('Backup on a first-generation board archives the three settings files and the compose',
      () async {
    final ssh = _legacyBoard();
    final logs = <String>[];

    final ok = await _Backup(ssh, local('backup.tgz'), logs).run();

    expect(ok, isTrue, reason: logs.join('\n'));
    expect(ssh.commands, contains(_legacyTar));
    expect(File(local('backup.tgz')).readAsStringSync(), 'tgz bytes');
  });

  test('Remove with backup + delete configs archives the settings files BEFORE rm -rf',
      () async {
    final ssh = _legacyBoard();
    final logs = <String>[];

    final ok = await _Remove(ssh, local('remove.tgz'), logs).run();

    expect(ok, isTrue, reason: logs.join('\n'));
    final tar = ssh.commands.indexOf(_legacyTar);
    expect(tar, isNonNegative, reason: ssh.commands.join('\n'));
    expect(ssh.commands.indexOf('rm -rf $kKioskDir'), greaterThan(tar));
  });

  test('Restore onto a first-generation compose is refused before anything is touched',
      () async {
    final ssh = _legacyBoard();
    final logs = <String>[];
    final backup = File(local('restore.tgz'))..writeAsStringSync('tgz');
    final engine = _Restore(ssh, backup, logs);

    final ok = await engine.run();

    expect(ok, isFalse);
    expect(engine.summary.join('\n'), contains('first-generation layout'));
    expect(engine.summary.join('\n'), contains('update this kiosk to a data/ server first'));
    expect(ssh.commands.where((c) => c.startsWith('cat > ')), isEmpty, reason: 'no upload');
    expect(ssh.commands.where((c) => c.startsWith('systemctl stop')), isEmpty);
    expect(ssh.commands.where((c) => c.contains('tar xzf')), isEmpty);
    expect(engine.steps[1].status, StepStatus.fail);
  });
}
