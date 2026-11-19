// Change port on a Linux board (PortEngine): the checks that refuse before
// any write, the three files it writes (each into .tmp, then mv), the restart
// and the verification (GetKioskInfo through the SSH connection; the ss
// listener only a hint), the rollback, a connection that drops before or
// after the restart, and SSH uses that never answer (a half-open link).
import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart' show SSHSocket, SSHStateError;
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/updater/engine.dart';
import 'package:operator_app/updater/kiosk.dart';
import 'package:operator_app/updater/port_engine.dart';
import 'package:operator_app/updater/server_port.dart';

import 'fake_server.dart';
import 'scripted_ssh.dart';

const _avahi = kAvahiServiceFile;

/// The rollback's removal of the .tmp files a write may leave.
const _rmTemps = "rm -f '$kBoardPortFile.tmp' '$kCompose.tmp' '$_avahi.tmp'";
const _restartServer = 'systemctl restart $kServiceUnit';

String _compose({String image = 'facesnap2:2.0.28-arm64', String ports = '      - "50051:50051"\n'}) =>
    'services:\n'
    '  face_snap:\n'
    '    image: $image\n'
    '    restart: always\n'
    '    ports:\n'
    '$ports'
    '    volumes:\n'
    '      - ./data:/data\n';

String _listenerLine(int port) => 'LISTEN 0      4096   0.0.0.0:$port   0.0.0.0:*\n';

/// A board answering like a real one. [portFile]: the port file's content
/// (null: no file). [busy]: what `ss -ltnH` shows for the new port before
/// the restart; [busyOwner]: what `ss -ltnpH` shows. [listening]: whether a
/// server listens on a port after the restart (default: yes).
ScriptedSsh _board({
  String? portFile,
  String? compose,
  String image = 'facesnap2:2.0.28-arm64',
  bool avahi = true,
  String imageEnv = '["PATH=/usr/local/bin:/usr/bin","FACE_SNAP_DATA_DIR=/data"]',
  int imageEnvExit = 0,
  String busy = '',
  String busyOwner = '',
  int busyExit = 0,
  bool Function(int port, ScriptedSsh ssh)? listening,
}) {
  final ssh = ScriptedSsh();
  int restarts() => ssh.commands.where((c) => c == _restartServer).length;
  ssh
    ..on(RegExp(r'^uname -s -m$'), CmdResult(0, 'Linux aarch64\n', ''))
    ..on(RegExp('device-tree/model'), CmdResult(0, 'Radxa Dragon Q6A', ''))
    ..on(RegExp('^test -f ${RegExp.escape(kBoardPortFile)} && cat'),
        portFile == null ? CmdResult(1, '', '') : CmdResult(0, portFile, ''))
    ..on(RegExp(RegExp.escape(composeImageCmd(kCompose))), CmdResult(0, '$image\n', ''))
    ..on(RegExp('^cat ${RegExp.escape(kCompose)}\$'),
        CmdResult(0, compose ?? _compose(image: image), ''))
    ..on(RegExp(r"^docker inspect --format '\{\{json \.Config\.Env\}\}' "),
        CmdResult(imageEnvExit, imageEnvExit == 0 ? '$imageEnv\n' : '',
            imageEnvExit == 0 ? '' : 'Error: No such image'))
    ..on(RegExp(r'^ss -ltnpH '), CmdResult(0, busyOwner, ''))
    ..onCall(RegExp(r'^ss -ltnH "sport = :(\d+)"$'), (command) {
      final port = int.parse(RegExp(r':(\d+)"$').firstMatch(command)!.group(1)!);
      if (restarts() == 0) {
        return CmdResult(busyExit, busy, busyExit == 0 ? '' : 'ss: command not found');
      }
      final up = listening?.call(port, ssh) ?? true;
      return CmdResult(0, up ? _listenerLine(port) : '', '');
    })
    ..on(RegExp('^test -f ${RegExp.escape(kBoardPortFile)}\$'),
        CmdResult(portFile == null ? 1 : 0, '', ''))
    ..on(RegExp('^test -f ${RegExp.escape(_avahi)}\$'), CmdResult(avahi ? 0 : 1, '', ''))
    // D-4: a chain of cp / mv -f / rm -f in one command, run part by part
    // (cp copies into [ScriptedSsh.writes] — a file the fake never wrote as
    // "<copy of path>" — mv -f moves a written file; the first failure ends
    // the chain).
    ..onCall(RegExp(r' && '), (command) {
      for (final part in command.split(' && ')) {
        final mv = RegExp(r"^mv -f '([^']+)' '([^']+)'$").firstMatch(part);
        final cp = RegExp(r"^cp '([^']+)' '([^']+)'$").firstMatch(part);
        if (cp != null) {
          ssh.writes[cp.group(2)!] = ssh.writes[cp.group(1)!] ?? '<copy of ${cp.group(1)}>';
        } else if (mv != null) {
          final content = ssh.writes.remove(mv.group(1)!);
          if (content == null) return CmdResult(1, '', 'mv: cannot stat');
          ssh.writes[mv.group(2)!] = content;
        } else if (!RegExp(r'^(cp|rm -f) ').hasMatch(part)) {
          return CmdResult(127, '', 'scripted chain: no rule for "$part"');
        }
      }
      return CmdResult(0, '', '');
    })
    ..on(RegExp(r'^cp '), CmdResult(0, '', ''))
    ..on(RegExp(r'^rm -f '), CmdResult(0, '', ''))
    // mv -f '<path>.tmp' '<path>': the written file takes the final name.
    ..onCall(RegExp(r"^mv -f '([^']+)' '([^']+)'$"), (command) {
      final m = RegExp(r"^mv -f '([^']+)' '([^']+)'$").firstMatch(command)!;
      final content = ssh.writes.remove(m.group(1)!);
      if (content == null) return CmdResult(1, '', 'mv: cannot stat');
      ssh.writes[m.group(2)!] = content;
      return CmdResult(0, '', '');
    })
    ..on(RegExp(r'^systemctl restart '), CmdResult(0, '', ''));
  return ssh;
}

class _Engine extends PortEngine {
  _Engine(this.fake, int newPort, this.logs, {super.checkServer, super.timeouts})
      : super(
            host: 'kiosk',
            user: 'root',
            password: 'secret-pw',
            newPort: newPort,
            pollInterval: Duration.zero,
            readyTimeout: Duration.zero,
            onChanged: () {},
            onLog: logs.add);
  final SshRunner fake;
  final List<String> logs;

  @override
  Future<SshRunner> openSsh() async => fake;
}

/// A server that answers GetKioskInfo with the port it was asked about.
Future<int?> _honest(SshRunner ssh, int port) async => port;

/// Every SSH limit zero: a command that never answers fails at once (no
/// real waits); the scripted answers still arrive first.
const _noWaits = PortTimeouts(
    query: Duration.zero,
    write: Duration.zero,
    restartSlack: Duration.zero,
    boardRestart: Duration.zero,
    tunnel: Duration.zero);

({_Engine engine, List<String> logs, List<int> asked}) _engine(ScriptedSsh ssh, int newPort,
    {Future<int?> Function(SshRunner ssh, int port)? checkServer,
    PortTimeouts timeouts = const PortTimeouts()}) {
  final logs = <String>[];
  final asked = <int>[];
  final engine = _Engine(ssh, newPort, logs, timeouts: timeouts, checkServer: (s, port) {
    asked.add(port);
    return (checkServer ?? _honest)(s, port);
  });
  return (engine: engine, logs: logs, asked: asked);
}

/// The commands sent after the first server restart.
List<String> _afterRestart(ScriptedSsh ssh) {
  final i = ssh.commands.indexOf(_restartServer);
  return i < 0 ? const [] : ssh.commands.sublist(i + 1);
}

/// D-4: the one command that moves every written .tmp file into place.
String _moveAll(List<String> paths) =>
    paths.map((p) => "mv -f '$p.tmp' '$p'").join(' && ');

/// D-4: the rollback's one command that puts the backups back ([portFile]:
/// there was a port file before; [avahi]: the board announces itself).
String _restore({bool portFile = true, bool avahi = true}) {
  final paths = [if (portFile) kBoardPortFile, kCompose, if (avahi) _avahi];
  return [
    for (final p in paths) "cp '$p.port-bak' '$p.tmp'",
    _moveAll(paths),
    if (!portFile) "rm -f '$kBoardPortFile'",
  ].join(' && ');
}

void main() {
  group('D-4: all .tmp files first, then every move in ONE command', () {
    test('the three moves arrive in one command, after all three writes', () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n');
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue, reason: r.engine.summary.join('\n'));

      final move = _moveAll([kBoardPortFile, kCompose, _avahi]);
      expect(ssh.commands.where((c) => c.startsWith('mv ')), [move]);
      final at = ssh.commands.indexOf(move);
      for (final path in [kBoardPortFile, kCompose, _avahi]) {
        expect(ssh.commands.indexOf('write $path.tmp'), lessThan(at), reason: path);
      }
      expect(ssh.writes.keys, unorderedEquals([kBoardPortFile, kCompose, _avahi]));
      expect(ssh.commands.indexOf(_restartServer), greaterThan(at));
    });

    test('no avahi: the two moves in one command', () async {
      final ssh = _board(avahi: false);
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue, reason: r.engine.summary.join('\n'));

      expect(ssh.commands.where((c) => c.startsWith('mv ')), [_moveAll([kBoardPortFile, kCompose])]);
    });

    test('a link drop between the writes leaves no file moved', () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n')
        ..failAfter(RegExp('^write ${RegExp.escape(kCompose)}\\.tmp\$'));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse); // no throw

      expect(ssh.commands.where((c) => c.startsWith('mv ')), isEmpty);
      expect(ssh.writes.keys, unorderedEquals(['$kBoardPortFile.tmp', '$kCompose.tmp']),
          reason: 'only .tmp files: every real file is still the old one');
    });

    test('the rollback puts the backups back in one command too (a port file before)', () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n');
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse);

      final restore = _restore();
      final after = _afterRestart(ssh);
      expect(after.where((c) => c.contains('.port-bak')), [restore]);
      expect(after.indexOf(_restartServer), greaterThan(after.indexOf(restore)));
      expect(r.engine.resultPort, 50051);
    });

    test('the rollback without a port file before: the removal is in that command', () async {
      final ssh = _board();
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse);

      final restore = _restore(portFile: false);
      expect(_afterRestart(ssh).where((c) => c.contains('.port-bak')), [restore]);
      expect(r.engine.resultPort, 50051);
    });
  });

  group('success', () {
    test('50051 (no port file) → 50052: the three files, the restarts, verified', () async {
      final ssh = _board();
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue);

      expect(r.engine.oldPort, 50051);
      expect(r.engine.resultPort, 50052);
      expect(ssh.writes.keys, unorderedEquals([kBoardPortFile, kCompose, _avahi]));
      expect(ssh.writes[kBoardPortFile], '{"grpc_port": 50052}\n');
      expect(ssh.writes[kCompose], contains('- "50052:50052"'));
      expect(ssh.writes[kCompose], withComposePort(_compose(), 50052));
      expect(ssh.writes[_avahi], contains('<port>50052</port>'));
      expect(ssh.writes[_avahi], avahiService(50052));
      expect(ssh.commands, contains('cp $kCompose $kCompose.port-bak'));
      expect(ssh.commands, contains('cp $_avahi $_avahi.port-bak'));
      expect(r.logs.join('\n'), contains('no port file'));
      expect(ssh.commands, contains(_restartServer));
      expect(ssh.commands, contains('systemctl restart avahi-daemon'));
      // The restart only after every write.
      expect(ssh.commands.indexOf(_restartServer),
          greaterThan(ssh.commands.lastIndexOf("mv -f '$kCompose.tmp' '$kCompose'")));
      expect(r.asked, [50052]);
      expect(r.engine.steps.map((s) => s.title),
          ['Connect', 'Check', 'Back up', 'Write', 'Restart', 'Verify']);
      expect(r.engine.steps.every((s) => s.status == StepStatus.ok), isTrue,
          reason: r.engine.steps.map((s) => '${s.title}: ${s.status} ${s.detail}').join('\n'));
      expect(r.engine.steps[2].detail, '2 copies (no port file)');
      expect(r.engine.notice, contains('New address: kiosk:50052'));
      expect(r.engine.summary.join('\n'), contains('kiosk now uses port 50052'));
      expect(r.logs.join('\n'), isNot(contains('secret-pw')));
    });

    test('a port file is backed up too: three .port-bak copies', () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n');
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue);

      expect(
          ssh.commands.where((c) => c.startsWith('cp ') && c.endsWith('.port-bak')),
          unorderedEquals([
            'cp $kCompose $kCompose.port-bak',
            'cp $kBoardPortFile $kBoardPortFile.port-bak',
            'cp $_avahi $_avahi.port-bak',
          ]));
      // Every backup before the first write.
      expect(ssh.commands.indexOf('cp $kBoardPortFile $kBoardPortFile.port-bak'),
          lessThan(ssh.commands.indexWhere((c) => c.startsWith('write '))));
      expect(r.engine.steps[2].detail, '3 copies');
      expect(r.engine.resultPort, 50052);
    });

    test('Review Focus 3: no avahi on the board → the port still changes, announcement skipped',
        () async {
      final ssh = _board(avahi: false);
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue);

      expect(r.engine.resultPort, 50052);
      expect(ssh.writes.keys, unorderedEquals([kBoardPortFile, kCompose]));
      expect(ssh.commands, isNot(contains('systemctl restart avahi-daemon')));
      expect(r.logs.join('\n'), contains('network announcement skipped'));
      expect(r.engine.steps[2].detail, '1 copy (no port file)');
    });

    test('Review Focus 4: back to 50051 writes {"grpc_port": 50051} explicitly', () async {
      final ssh = _board(
          portFile: '{"grpc_port": 50052}\n',
          compose: _compose(ports: '      - "50052:50052"\n'));
      final r = _engine(ssh, 50051);

      expect(await r.engine.run(), isTrue);

      expect(r.engine.oldPort, 50052);
      expect(ssh.writes[kBoardPortFile], '{"grpc_port": 50051}\n');
      expect(ssh.commands.where((c) => c.contains("rm -f '$kBoardPortFile'")), isEmpty);
      expect(ssh.writes[kCompose], contains('- "50051:50051"'));
      expect(r.engine.resultPort, 50051);
    });

    test('R7: GetKioskInfo is asked again until it answers within the wait', () async {
      var calls = 0;
      final ssh = _board();
      final logs = <String>[];
      final engine = PortEngineForTest(ssh, 50052, logs,
          checkServer: (_, port) async => ++calls >= 3 ? port : null,
          readyTimeout: const Duration(seconds: 5),
          pollInterval: Duration.zero);

      expect(await engine.run(), isTrue);
      expect(calls, 3);
      expect(engine.resultPort, 50052);
    });

    test('R8: no ss listener, but GetKioskInfo answers 50052 → success', () async {
      final ssh = _board(listening: (_, _) => false);
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue);

      expect(r.asked, [50052]);
      expect(r.engine.resultPort, 50052);
      expect(ssh.commands.where((c) => c.contains('.port-bak')),
          isNot(contains(contains("'$kCompose.tmp'"))), reason: 'no rollback');
    });

    test('I2/R13: the waits default to 2 s polls within 180 s on a board, 60 s on Windows',
        () {
      final engine = PortEngine(
          host: 'kiosk',
          user: 'root',
          password: 'x',
          newPort: 50052,
          onChanged: () {},
          onLog: (_) {});
      expect(engine.pollInterval, const Duration(seconds: 2));
      engine.targetKind = TargetKind.linuxBoard;
      expect(engine.readyTimeout, const Duration(seconds: 180));
      engine.targetKind = TargetKind.windowsPc;
      expect(engine.readyTimeout, const Duration(seconds: 60));
      // A given timeout wins on both.
      final given = PortEngine(
          host: 'kiosk',
          user: 'root',
          password: 'x',
          newPort: 50052,
          readyTimeout: const Duration(seconds: 7),
          onChanged: () {},
          onLog: (_) {})
        ..targetKind = TargetKind.linuxBoard;
      expect(given.readyTimeout, const Duration(seconds: 7));
      // The SSH limits (I3).
      const t = PortTimeouts();
      expect((t.query, t.write, t.restartSlack, t.tunnel), (
        const Duration(seconds: 30),
        const Duration(seconds: 60),
        const Duration(seconds: 30),
        const Duration(seconds: 10),
      ));
    });

    test('I1: each file goes to <path>.tmp first, then mv -f over the file', () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n');
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue);

      for (final path in [kBoardPortFile, kCompose, _avahi]) {
        final write = ssh.commands.indexOf('write $path.tmp');
        final mv = ssh.commands.indexWhere((c) => c.contains("mv -f '$path.tmp' '$path'"));
        expect(write, isNonNegative, reason: path);
        expect(mv, greaterThan(write), reason: path);
        expect(ssh.commands, isNot(contains('write $path')), reason: 'never written in place');
      }
      expect(ssh.writes.keys, unorderedEquals([kBoardPortFile, kCompose, _avahi]));
    });
  });

  group('refused before any write', () {
    Future<({bool ok, ScriptedSsh ssh, String summary, _Engine engine})> refused(
        ScriptedSsh ssh, int newPort) async {
      final r = _engine(ssh, newPort);
      final ok = await r.engine.run();
      expect(ssh.writes, isEmpty);
      expect(ssh.commands.where((c) => c.startsWith('cp ') || c.startsWith('systemctl')), isEmpty);
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
      return (ok: ok, ssh: ssh, summary: r.engine.summary.join('\n'), engine: r.engine);
    }

    for (final port in [1023, 65536]) {
      test('port $port is out of range', () async {
        final r = await refused(_board(), port);
        expect(r.ok, isFalse);
        expect(r.summary, contains('port $port is outside 1024–65535'));
        expect(r.ssh.commands, isEmpty, reason: 'refused before connecting');
        expect(r.engine.resultPort, isNull);
      });
    }

    test('the same port as now', () async {
      final r = await refused(_board(portFile: '{"grpc_port": 50052}'), 50052);
      expect(r.ok, isFalse);
      expect(r.summary, contains('nothing to change'));
      expect(r.summary, contains('kiosk stays on port 50052'));
      expect(r.engine.resultPort, 50052);
    });

    test('an environment override in docker-compose.yml', () async {
      final compose = _compose().replaceFirst('    volumes:\n',
          '    environment:\n      - FACESNAP_NET_PORT=50060\n    volumes:\n');
      final r = await refused(_board(compose: compose), 50052);
      expect(r.ok, isFalse);
      expect(r.summary, contains("this kiosk's docker-compose.yml sets FACESNAP_NET_PORT; "
          'the port file would be ignored'));
      // A commented-out override is no override; the map form counts.
      expect(composePortOverride(_compose().replaceFirst(
              '    volumes:\n', '    # - FACE_SNAP_GRPC_BIND=0.0.0.0:50060\n    volumes:\n')),
          isNull);
      expect(composePortOverride('      FACE_SNAP_GRPC_BIND: "[::]:50060"\n'),
          'FACE_SNAP_GRPC_BIND');
    });

    test('a busy port names the process from ss -p', () async {
      final r = await refused(
          _board(
              busy: _listenerLine(50052),
              busyOwner: 'LISTEN 0 4096 0.0.0.0:50052 0.0.0.0:* users:(("CTest",pid=812,fd=7))\n'),
          50052);
      expect(r.ok, isFalse);
      expect(r.summary, contains('port 50052 is in use on kiosk by CTest'));
    });

    test('a busy port without a process name is still refused', () async {
      final r = await refused(_board(busy: _listenerLine(50052)), 50052);
      expect(r.ok, isFalse);
      expect(r.summary, contains('port 50052 is already in use on kiosk'));
    });

    test('a busy check that cannot run refuses (never fails open)', () async {
      final r = await refused(_board(busyExit: 127), 50052);
      expect(r.ok, isFalse);
      expect(r.summary, contains('could not check whether port 50052 is free'));
    });

    test("an image older than 2.0.28 (the Odroid's 2.0.27 head-turn image) → "
        'update this kiosk first', () async {
      final r = await refused(_board(image: 'facesnap2:2.0.27-arm64'), 50052);
      expect(r.ok, isFalse);
      expect(r.summary, contains('update this kiosk first'));
      expect(r.summary, contains('facesnap2:2.0.27-arm64'));
    });

    test('an unversioned tag → update this kiosk first', () async {
      final r = await refused(_board(image: 'facesnap2:latest'), 50052);
      expect(r.ok, isFalse);
      expect(r.summary, contains('update this kiosk first'));
    });

    test('an unexpected ports line', () async {
      final r = await refused(
          _board(compose: _compose(ports: '      - "50051:50051"\n      - "8080:8080"\n')),
          50052);
      expect(r.ok, isFalse);
      expect(r.summary, contains('unexpected ports line in docker-compose.yml'));
    });

    test('a Windows PC takes the Windows path, never the board commands (Task 5)', () async {
      // Every PowerShell call answers like the platform probe: the facts
      // script then prints no JSON line, which refuses.
      final ssh = ScriptedSsh()
        ..on(RegExp(r'^uname'), CmdResult(1, '', "'uname' is not recognized"))
        ..on(RegExp(r'^powershell '), CmdResult(0, 'Win32NT\r\nDELL-KIOSK\r\nAMD64\r\n', ''));
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isFalse);
      expect(ssh.writes, isEmpty);
      expect(r.engine.targetKind, TargetKind.windowsPc);
      expect(ssh.commands.where((c) => !c.startsWith('uname') && !c.startsWith('powershell ')),
          isEmpty);
      expect(r.engine.summary.join('\n'), contains('could not read the server setup on kiosk'));
    });

    test('neither Linux nor Windows: refused at Connect', () async {
      final ssh = ScriptedSsh()
        ..on(RegExp(r'^uname'), CmdResult(0, 'Darwin arm64\n', ''))
        ..on(RegExp(r'^powershell '), CmdResult(127, '', 'powershell: not found'));
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isFalse);
      expect(ssh.writes, isEmpty);
      expect(r.engine.steps[0].status, StepStatus.fail);
      expect(r.engine.summary.join('\n'),
          contains('kiosk is neither a Linux board nor a Windows PC'));
      expect(r.engine.resultPort, isNull);
    });
  });

  group('rollback', () {
    test('GetKioskInfo does not answer → the three files restored, back on port 50051',
        () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n');
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse);

      final after = _afterRestart(ssh);
      expect(after, contains(_restore()));
      expect(after, contains(_rmTemps), reason: "a write's leftover .tmp files go too");
      expect(after.indexOf(_restartServer), greaterThan(after.indexOf(_rmTemps)));
      expect(after.where((c) => c == _restartServer), hasLength(1), reason: 'restart again');
      expect(after.indexOf(_restartServer),
          greaterThan(after.indexOf(_restore())));
      expect(r.asked, [50052, 50051]);
      expect(r.engine.resultPort, 50051);
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
      expect(r.engine.steps.last.title, 'Roll back');
      expect(r.engine.steps.last.status, StepStatus.ok);
      expect(r.engine.steps.firstWhere((s) => s.title == 'Verify').status, StepStatus.fail);
    });

    test('no port file before → the rollback removes it', () async {
      final ssh = _board();
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse);

      expect(_afterRestart(ssh), contains(_restore(portFile: false)));
      expect(r.engine.resultPort, 50051);
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
    });

    test('the server answers with another port → rolled back', () async {
      final ssh = _board();
      final r = _engine(ssh, 50052, checkServer: (_, port) async => 50051);

      expect(await r.engine.run(), isFalse);

      expect(_afterRestart(ssh), contains(_restore(portFile: false)));
      expect(r.engine.resultPort, 50051);
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
    });

    test('R8: the old port answers without an ss listener → back on port 50051', () async {
      final ssh = _board(listening: (_, _) => false);
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse);

      expect(r.asked, [50052, 50051]);
      expect(r.engine.resultPort, 50051);
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
      expect(r.engine.summary.join('\n'), contains('(no listener seen)'));
      expect(r.engine.steps.last.status, StepStatus.ok);
    });

    test('a failed write is rolled back too', () async {
      final ssh = _board()..failWrite(RegExp(RegExp.escape(kCompose)));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(ssh.commands, contains(_restore(portFile: false)));
      expect(ssh.commands, contains(_rmTemps), reason: 'the failed write may have left its .tmp');
      expect(r.engine.resultPort, 50051);
      // M1: the restart was never sent, so the rollback sends none either.
      expect(ssh.commands.where((c) => c.startsWith('systemctl restart')), isEmpty);
      expect(r.logs, contains('The server was not restarted: it still serves port 50051.'));
      expect(r.asked, [50051], reason: 'the old port is still checked');
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
    });

    test('the rollback fails too → the message names the backup files', () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n');
      final r = _engine(ssh, 50052, checkServer: (_, _) async => null);

      expect(await r.engine.run(), isFalse);

      final summary = r.engine.summary.join('\n');
      expect(summary, contains('docker-compose.yml.port-bak'));
      expect(summary, contains('server_config.json.port-bak'));
      expect(summary, contains('kiosk may be on port 50052 or 50051'));
      expect(r.engine.resultPort, isNull);
      expect(r.engine.steps.last.title, 'Roll back');
      expect(r.engine.steps.last.status, StepStatus.fail);
    });
  });

  group('Review Focus 5: the connection drops', () {
    test('during the restart → no throw, no rollback, "connection lost"', () async {
      final ssh = _board()..failAfter(RegExp('^${RegExp.escape(_restartServer)}\$'));
      final r = _engine(ssh, 50052);

      final ok = await r.engine.run(); // must not throw
      expect(ok, isFalse);

      expect(r.engine.resultPort, isNull);
      expect(r.engine.summary.join('\n'),
          contains('connection lost: kiosk may be on port 50052 or 50051; check with Search'));
      expect(ssh.commands.where((c) => c.contains('.port-bak ')), isEmpty,
          reason: 'no restore over a dead connection');
      expect(ssh.commands.where((c) => c == _restartServer), hasLength(1));
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
    });

    test('during the listener wait → the same', () async {
      final ssh = _board()..failAfter(RegExp(r'^systemctl restart avahi-daemon$'));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(r.engine.resultPort, isNull);
      expect(r.engine.summary.join('\n'),
          contains('connection lost: kiosk may be on port 50052 or 50051; check with Search'));
      expect(ssh.commands.where((c) => c.contains('.port-bak ')), isEmpty);
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
    });
  });

  group('the connection drops during the rollback', () {
    test('→ "connection lost" plus how to restore the backups by hand', () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n')
        ..failAfter(RegExp('^${RegExp.escape(_restore())}\$'));
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse); // no throw

      final summary = r.engine.summary.join('\n');
      expect(summary,
          contains('connection lost: kiosk may be on port 50052 or 50051; check with Search'));
      expect(summary, contains('The rollback was interrupted'));
      expect(summary, contains('docker-compose.yml.port-bak'));
      expect(summary, contains('server_config.json.port-bak'));
      expect(r.engine.resultPort, isNull);
      expect(r.engine.steps.last.title, 'Roll back');
      expect(r.engine.steps.last.status, StepStatus.fail);
    });
  });

  group('I1: the connection drops between the first write and the restart', () {
    test('after the port file → "partly changed", old port until the next restart, '
        'how to restore; no rollback, no restart', () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n')
        ..failAfter(RegExp('^write ${RegExp.escape(kBoardPortFile)}\\.tmp\$'));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse); // no throw

      final summary = r.engine.summary.join('\n');
      expect(summary,
          contains('connection lost: the port files on kiosk may be partly changed; '
              'its server runs on port 50051 only until its next restart.'));
      expect(summary, contains('Check by hand: restore $kCompose.port-bak'));
      expect(summary, contains('$kBoardPortFile.port-bak'));
      expect(summary, isNot(contains('check with Search')));
      expect(summary, isNot(contains('rollback was interrupted')));
      expect(ssh.commands.where((c) => c.startsWith('systemctl')), isEmpty);
      expect(ssh.commands.where((c) => c.contains('.port-bak ')), isEmpty,
          reason: 'no restore over a dead connection');
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
      expect(r.engine.steps.firstWhere((s) => s.title == 'Write').status, StepStatus.fail);
      expect(r.engine.resultPort, isNull);
    });
  });

  group('I3: an SSH use that never answers (a half-open link)', () {
    test('the restart never answers → a rollback is tried; its restart never answers '
        'either → "connection lost" with how to restore', () async {
      final ssh = _board(portFile: '{"grpc_port": 50051}\n')
        ..hang(RegExp('^${RegExp.escape(_restartServer)}\$'));
      final r = _engine(ssh, 50052, timeouts: _noWaits);

      expect(await r.engine.run(), isFalse); // no hang, no throw

      expect(ssh.commands.where((c) => c == _restartServer), hasLength(2),
          reason: "the restart, then the rollback's restart");
      expect(ssh.commands, contains(_restore()));
      final summary = r.engine.summary.join('\n');
      expect(summary,
          contains('connection lost: kiosk may be on port 50052 or 50051; check with Search.'));
      expect(summary, contains('The rollback was interrupted.'));
      expect(summary, contains('Check by hand: restore $kCompose.port-bak'));
      expect(r.logs.join('\n'), contains('no answer from kiosk to $_restartServer within 0 s'));
      expect(r.engine.steps.last.title, 'Roll back');
      expect(r.engine.steps.last.status, StepStatus.fail);
      expect(r.engine.resultPort, isNull);
    });

    test('a write that never finishes → treated as a failure: rolled back, no restart',
        () async {
      final ssh = _board()..hangWrite(RegExp('^${RegExp.escape(kCompose)}\\.tmp\$'));
      final r = _engine(ssh, 50052, timeouts: _noWaits);

      expect(await r.engine.run(), isFalse);

      expect(ssh.commands, contains(_restore(portFile: false)));
      expect(ssh.commands.where((c) => c.startsWith('systemctl restart')), isEmpty);
      final summary = r.engine.summary.join('\n');
      expect(summary, contains('no answer from kiosk to the write of $kCompose.tmp within 0 s'));
      expect(summary, contains('back on port 50051'));
      expect(r.engine.resultPort, 50051);
    });

    test('the default server check: a forward that never opens → null (no answer)', () async {
      final ssh = ScriptedSsh()..onForward = (host, port) => Completer<SSHSocket>().future;
      expect(await PortEngine.defaultCheckServer(ssh, 50052, openTimeout: Duration.zero), isNull);
      expect(ssh.commands, ['forward 127.0.0.1:50052']);
    });
  });

  group('M2/M4: more refusals before any write', () {
    test("the image's environment sets FACESNAP_NET_PORT → refused", () async {
      final ssh = _board(imageEnv: '["PATH=/usr/bin","FACESNAP_NET_PORT=50060"]');
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isFalse);
      expect(ssh.writes, isEmpty);
      expect(ssh.commands, contains("docker inspect --format '{{json .Config.Env}}' "
          'facesnap2:2.0.28-arm64'));
      expect(r.engine.summary.join('\n'),
          contains("this kiosk's image facesnap2:2.0.28-arm64 sets FACESNAP_NET_PORT; "
              'the port file would be ignored'));
      expect(imagePortOverride('["A=1","FACE_SNAP_GRPC_BIND=[::]:50060"]'),
          'FACE_SNAP_GRPC_BIND');
      expect(imagePortOverride('["FACE_SNAP_DATA_DIR=/data","X=FACESNAP_NET_PORT"]'), isNull);
    });

    test("the image's environment cannot be read → refused (never fails open)", () async {
      final ssh = _board(imageEnvExit: 1);
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isFalse);
      expect(ssh.writes, isEmpty);
      expect(r.engine.summary.join('\n'),
          contains('could not read the environment of facesnap2:2.0.28-arm64 on kiosk'));
    });

    test('a Linux machine that is not aarch64 → refused at Connect', () async {
      final pc = ScriptedSsh()
        ..on(RegExp(r'^uname -s -m$'), CmdResult(0, 'Linux x86_64\n', ''))
        ..on(RegExp('device-tree/model'), CmdResult(1, '', ''));
      final r = _engine(pc, 50052);
      expect(await r.engine.run(), isFalse);
      expect(pc.writes, isEmpty);
      expect(pc.commands, hasLength(2), reason: 'uname and the model only');
      expect(r.engine.steps[0].status, StepStatus.fail);
      expect(r.engine.summary.join('\n'),
          contains('Port not changed: Target is x86_64, expected aarch64 (a kiosk board).'));
    });
  });

  group('the default server check', () {
    late Server server;
    setUp(() async {
      server = await serveFakes([_Kiosk('50052')]);
    });
    tearDown(() => server.shutdown());

    test('asks GetKioskInfo through the SSH connection on the given port', () async {
      final ssh = ScriptedSsh()..onForward = (host, port) => SSHSocket.connect('127.0.0.1', server.port!);
      expect(await PortEngine.defaultCheckServer(ssh, 50052), 50052);
      expect(ssh.commands, ['forward 127.0.0.1:50052']);
      expect(ssh.closed, isFalse, reason: 'the engine keeps using the connection');
    });

    test('a lost SSH transport is rethrown, not read as "no answer"', () async {
      final ssh = ScriptedSsh()
        ..on('true', CmdResult(0, '', ''))
        ..failAfter(RegExp(r'^true$'));
      await ssh.run('true');
      await expectLater(PortEngine.defaultCheckServer(ssh, 50052), throwsA(isA<SSHStateError>()));
    });

    test('a refused forward → null', () async {
      final ssh = ScriptedSsh()
        ..onForward = (host, port) async => throw const SocketException('refused');
      expect(await PortEngine.defaultCheckServer(ssh, 50052), isNull);
    });
  });
}

class PortEngineForTest extends PortEngine {
  PortEngineForTest(this.fake, int newPort, List<String> logs,
      {required super.checkServer, required super.readyTimeout, required super.pollInterval})
      : super(
            host: 'kiosk',
            user: 'root',
            password: 'x',
            newPort: newPort,
            onChanged: () {},
            onLog: logs.add);
  final SshRunner fake;

  @override
  Future<SshRunner> openSsh() async => fake;
}

class _Kiosk extends KioskServiceBase {
  _Kiosk(this.port);
  final String port;

  @override
  Future<KioskInfoResponse> getKioskInfo(ServiceCall call, Empty request) async =>
      KioskInfoResponse(kioskInfo: KioskInfo(port: port));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}
