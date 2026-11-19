// Change port on a Windows PC (PortEngine): the facts that refuse before any
// write (administrator, the FaceSnapServer service, set_server_port.ps1 in the
// service's folder), set_server_port.ps1 -Query / -Port / -Restore / -Remove
// through `powershell -EncodedCommand`, the restart with its listener wait,
// the GetKioskInfo verification, the rollback, a connection dropped before or
// after the restart, and calls that never answer (a half-open link).
import 'dart:convert';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart' show LocalServerConfig;
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/updater/engine.dart';
import 'package:operator_app/updater/port_engine.dart';
import 'package:operator_app/updater/server_port.dart';

import 'scripted_ssh.dart';

const _app = r'C:\Program Files\FaceSnap';
const _setPort = r"& 'C:\Program Files\FaceSnap\set_server_port.ps1'";

CmdResult _json(Object json, [int exitCode = 0]) => CmdResult(exitCode, '${jsonEncode(json)}\r\n', '');

/// A Windows PC answering like a real one. [portFile]: the text of
/// server_config.json (null: no file). [portAnswer]: the answer to
/// `-Port N` (default: written, ok). [listening]: what the restart's
/// listener wait reports for a port (default: yes).
ScriptedSsh _pc({
  bool admin = true,
  bool service = true,
  String app = _app,
  bool script = true,
  String override = '',
  String? portFile,
  CmdResult? portAnswer,
  CmdResult? queryAnswer,
  CmdResult? factsAnswer,
  CmdResult? restoreAnswer,
  CmdResult? stopAnswer,
  bool Function(int port)? listening,
  CmdResult? Function(int port, int nth)? restartAnswer,
}) {
  var restarts = 0;
  final content = portFile == null ? '' : base64.encode(utf8.encode(portFile));
  final current = portFile == null ? kDefaultPort : LocalServerConfig.parsePort(portFile);
  return ScriptedSsh()
    ..on(RegExp(r'^uname -s -m$'), CmdResult(1, '', "'uname' is not recognized as an internal or external command"))
    ..onPs(RegExp(r'OSVersion\.Platform'), (_) => CmdResult(0, 'Win32NT\r\nDELL-KIOSK\r\nAMD64\r\n', ''))
    ..onPs(RegExp(r'Win32_Service'), (_) =>
        factsAnswer ??
        _json({
          'admin': admin,
          'service': service,
          'app': service ? app : '',
          'script': script,
          'override': override,
          'error': '',
        }))
    ..onPs(RegExp(r'set_server_port\.ps1. -Query$'), (_) =>
        queryAnswer ??
        _json({'port': current, 'source': portFile == null ? 'default' : 'file', 'content': content}))
    ..onPs(RegExp(r'set_server_port\.ps1. -Port (\d+)$'), (s) {
      final port = int.parse(RegExp(r'-Port (\d+)$').firstMatch(s)!.group(1)!);
      return portAnswer ?? _json({'ok': true, 'port': port});
    })
    ..onPs(RegExp(r'set_server_port\.ps1. -Restore \S+$'), (_) => restoreAnswer ?? _json({'ok': true, 'port': current}))
    ..onPs(RegExp(r'set_server_port\.ps1. -Remove$'), (_) => _json({'ok': true, 'port': 50051}))
    ..onPs(RegExp(r'Stop-Service -Name FaceSnapServer'), (_) => stopAnswer ?? _json({'stopped': true}))
    ..onPs(RegExp(r'Start-Service -Name FaceSnapServer'), (s) {
      final port = int.parse(RegExp(r'-LocalPort (\d+)').firstMatch(s)!.group(1)!);
      return restartAnswer?.call(port, ++restarts) ??
          _json({'listening': listening?.call(port) ?? true});
    });
}

class _Engine extends PortEngine {
  _Engine(this.fake, int newPort, this.logs, {super.checkServer, super.timeouts})
      : super(
            host: 'dell',
            user: 'kioskadmin',
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

Future<int?> _honest(SshRunner ssh, int port) async => port;

/// Every SSH limit zero: a call that never answers fails at once (no real
/// waits); the scripted answers still arrive first.
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

/// The set_server_port.ps1 calls, as "-Query", "-Port 50052", "-Remove", …
List<String> _calls(ScriptedSsh ssh) => [
      for (final s in ssh.scripts)
        if (RegExp(r"^\$ProgressPreference = 'SilentlyContinue'; & '.*set_server_port\.ps1' (.+)$")
                .firstMatch(s)
            case final m?)
          m.group(1)!,
    ];

/// The service and set_server_port.ps1 calls in order: "-Query", "stop",
/// "-Port 50052", "start 50052", "restart 50052", …
List<String> _sequence(ScriptedSsh ssh) => [
      for (final s in ssh.scripts)
        if (RegExp(r"set_server_port\.ps1' (.+)$").firstMatch(s) case final m?)
          m.group(1)!
        else if (s.contains('Stop-Service -Name FaceSnapServer'))
          'stop'
        else if (RegExp(r'^(Start|Restart)-Service -Name FaceSnapServer', multiLine: true)
                .firstMatch(s)
            case final m?)
          '${m.group(1)!.toLowerCase()} ${RegExp(r'-LocalPort (\d+)').firstMatch(s)!.group(1)}',
    ];

/// The Start-Service scripts (each with its listener wait).
List<String> _restarts(ScriptedSsh ssh) =>
    ssh.scripts.where((s) => s.contains('Start-Service -Name')).toList();

void main() {
  group('D-1: Stop-Service before the port write, Start-Service after it', () {
    // NSSM's pre-stop hook (signal_stop.ps1) reads the port FILE to find the
    // server it waits for: stopped while the file still names the port the
    // server runs on, the orderly shutdown completes.
    test('success: stop, -Port 50052, start on 50052; never Restart-Service', () async {
      final ssh = _pc();
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue, reason: r.engine.summary.join('\n'));

      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', 'start 50052']);
      expect(r.engine.resultPort, 50052);
    });

    test('rollback after a failed verify: stop (the file still says 50052), -Restore, '
        'start on 50060', () async {
      const file = '{"grpc_port": 50060}\r\n';
      final ssh = _pc(portFile: file);
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse);

      expect(_sequence(ssh), [
        '-Query',
        'stop',
        '-Port 50052',
        'start 50052',
        'stop',
        "-Restore '${base64.encode(utf8.encode(file))}'",
        'start 50060',
      ]);
      expect(r.engine.resultPort, 50060);
      expect(r.engine.summary.join('\n'), contains('back on port 50060'));
    });

    test('rollback when the start never happened (-Port failed): -Remove, start on 50051',
        () async {
      final ssh = _pc(portAnswer: CmdResult(1, '', 'A parameter cannot be found'));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', '-Remove', 'start 50051']);
      expect(r.asked, [50051]);
      expect(r.engine.resultPort, 50051);
    });

    test('-Port writes nothing (exit 3): the service is started again on the old port',
        () async {
      final ssh = _pc(portAnswer: _json({'ok': false, 'error': 'Port 50052 is in use by CTest.exe'}, 3));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', 'start 50051']);
      expect(r.asked, [50051]);
      expect(r.engine.resultPort, 50051);
      expect(r.engine.summary.join('\n'),
          contains('dell stays on port 50051: Port 50052 is in use by CTest.exe'));
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
    });

    test('Stop-Service fails: nothing written, the service started again, refused', () async {
      final ssh = _pc(stopAnswer: CmdResult(1, '', 'Stop-Service : Cannot stop service FaceSnapServer'));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(_sequence(ssh), ['-Query', 'stop', 'start 50051']);
      final summary = r.engine.summary.join('\n');
      expect(summary, contains('dell stays on port 50051: could not stop the FaceSnapServer service'));
      expect(summary, contains('Cannot stop service FaceSnapServer'));
      expect(r.engine.resultPort, 50051);
    });

    test('the connection drops after the stop → "may be stopped" and how to restore by hand',
        () async {
      final ssh = _pc()..failAfterPs(RegExp('Stop-Service'));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse); // no throw

      final summary = r.engine.summary.join('\n');
      expect(summary,
          contains('connection lost: the FaceSnapServer service on dell may be stopped, '
              'and its server_config.json may already say port 50052.'));
      expect(summary,
          contains('Check by hand, as an administrator on dell: Stop-Service FaceSnapServer, '
              'then $_setPort -Remove, then Start-Service FaceSnapServer.'));
      expect(r.engine.resultPort, isNull);
    });

    test('the stop script stops the service and prints its JSON line', () {
      expect(windowsStopScript, contains('Stop-Service -Name FaceSnapServer'));
      expect(windowsStopScript, contains('"stopped":true'));
      expect(windowsStopScript.length, lessThan(kMaxPsScriptLength));
    });
  });

  group('success', () {
    test('50051 (no port file) → 50052: -Port 50052, the restart, verified', () async {
      final ssh = _pc();
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue, reason: r.engine.summary.join('\n'));

      expect(r.engine.targetKind, TargetKind.windowsPc);
      expect(r.engine.oldPort, 50051);
      expect(r.engine.resultPort, 50052);
      expect(_calls(ssh), ['-Query', '-Port 50052']);
      expect(ssh.scripts.where((s) => s.contains('-Port 50052')).single,
          endsWith('$_setPort -Port 50052'));
      final restarts = _restarts(ssh);
      expect(restarts, hasLength(1));
      expect(restarts.single, contains('-LocalPort 50052'));
      expect(restarts.single, contains("'face_snap_server'"));
      // The start only after the write.
      final scripts = ssh.scripts;
      expect(scripts.indexWhere((s) => s.contains('Start-Service')),
          greaterThan(scripts.indexWhere((s) => s.contains('-Port 50052'))));
      expect(r.asked, [50052]);
      expect(ssh.writes, isEmpty, reason: 'only set_server_port.ps1 writes on Windows');
      expect(r.engine.steps.map((s) => s.title),
          ['Connect', 'Check', 'Back up', 'Write', 'Restart', 'Verify']);
      expect(r.engine.steps.every((s) => s.status == StepStatus.ok), isTrue,
          reason: r.engine.steps.map((s) => '${s.title}: ${s.status} ${s.detail}').join('\n'));
      // M3/R14: the Windows server listens on that PC only.
      expect(r.engine.notice,
          'New port on dell: 50052 (the server accepts local connections only).\n'
          'The FaceSnap apps on that PC follow after they restart; '
          'other programs on that PC must use 127.0.0.1:50052.');
      expect(r.engine.notice, isNot(contains('New address')));
      expect(r.engine.notice, isNot(contains('firewall')));
      expect(r.engine.summary.join('\n'), contains('dell now uses port 50052 (was 50051)'));
      expect(r.logs.join('\n'), isNot(contains('secret-pw')));
      expect(ssh.commands.every((c) => c.startsWith('uname') || decodedPowerShell(c) != null), isTrue,
          reason: 'every Windows command is powershell -EncodedCommand');
    });

    test('Review Focus 4: back to 50051 → -Port 50051 (written), never -Remove', () async {
      final ssh = _pc(portFile: '{"grpc_port": 50052}\r\n');
      final r = _engine(ssh, 50051);

      expect(await r.engine.run(), isTrue, reason: r.engine.summary.join('\n'));

      expect(r.engine.oldPort, 50052);
      expect(_calls(ssh), ['-Query', '-Port 50051']);
      expect(_calls(ssh), isNot(contains('-Remove')));
      expect(r.engine.resultPort, 50051);
    });

    test('the app folder comes from the facts; a quote in it is doubled', () async {
      final ssh = _pc(app: r"D:\Kiosk's\FaceSnap");
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue, reason: r.engine.summary.join('\n'));

      expect(ssh.scripts.where((s) => s.contains('-Port 50052')).single,
          contains(r"& 'D:\Kiosk''s\FaceSnap\set_server_port.ps1' -Port 50052"));
    });

    test('GetKioskInfo is asked again until it answers within the wait', () async {
      var calls = 0;
      final ssh = _pc();
      final logs = <String>[];
      final engine = _WaitEngine(ssh, 50052, logs,
          checkServer: (_, port) async => ++calls >= 3 ? port : null,
          readyTimeout: const Duration(seconds: 5));

      expect(await engine.run(), isTrue);
      expect(calls, 3);
      // The listener wait gets the engine's timeout, in seconds.
      expect(_restarts(ssh).single, contains('AddSeconds(5)'));
    });

    test('no listener reported, but GetKioskInfo answers 50052 → success', () async {
      final ssh = _pc(listening: (_) => false);
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isTrue);
      expect(r.engine.resultPort, 50052);
      expect(_calls(ssh), isNot(contains('-Remove')));
    });
  });

  group('refused before any write (no -Port sent)', () {
    Future<({bool ok, ScriptedSsh ssh, String summary, _Engine engine, List<String> logs})>
        refused(ScriptedSsh ssh, int newPort) async {
      final r = _engine(ssh, newPort);
      final ok = await r.engine.run();
      expect(ok, isFalse);
      expect(_calls(ssh).where((c) => c != '-Query'), isEmpty, reason: 'nothing but -Query');
      expect(_restarts(ssh), isEmpty);
      expect(ssh.writes, isEmpty);
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
      return (
        ok: ok,
        ssh: ssh,
        summary: r.engine.summary.join('\n'),
        engine: r.engine,
        logs: r.logs,
      );
    }

    test('not an administrator', () async {
      final r = await refused(_pc(admin: false), 50052);
      expect(r.summary, contains('this account is not an administrator'));
      expect(_calls(r.ssh), isEmpty, reason: 'refused before -Query');
    });

    test('no FaceSnapServer service', () async {
      final r = await refused(_pc(service: false), 50052);
      expect(r.summary, contains('update the server on this PC to 1.1.25 or later first'));
      expect(_calls(r.ssh), isEmpty);
    });

    test('no set_server_port.ps1 in the service folder', () async {
      final r = await refused(_pc(script: false), 50052);
      expect(r.summary, contains('update the server on this PC to 1.1.25 or later first'));
      expect(r.summary, contains(_app));
      expect(_calls(r.ssh), isEmpty);
    });

    test('the facts script prints no JSON → refused, the raw output in the log', () async {
      final r = await refused(
          _pc(factsAnswer: CmdResult(1, 'Get-CimInstance : Access denied\r\n', 'more')), 50052);
      expect(r.summary, contains('could not read the server setup on dell'));
      expect(r.logs.join('\n'), contains('Get-CimInstance : Access denied'));
      expect(_calls(r.ssh), isEmpty);
    });

    test('the same port as now', () async {
      final r = await refused(_pc(portFile: '{"grpc_port": 50052}\r\n'), 50052);
      expect(r.summary, contains('nothing to change'));
      expect(r.summary, contains('dell stays on port 50052'));
      expect(r.engine.resultPort, 50052);
    });

    test('-Query fails → refused', () async {
      final r = await refused(
          _pc(queryAnswer: _json({'ok': false, 'error': 'Could not read C:\\x: denied', 'written': false}, 4)),
          50052);
      expect(r.summary, contains('could not read the port on dell'));
      expect(r.summary, contains('Could not read C:\\x: denied'));
    });

    for (final port in [1023, 65536]) {
      test('port $port is out of range: refused before connecting', () async {
        final r = await refused(_pc(), port);
        expect(r.summary, contains('port $port is outside 1024–65535'));
        expect(r.ssh.commands, isEmpty);
      });
    }
  });

  group('set_server_port.ps1 -Port refuses (nothing written)', () {
    test('exit 3 → the script message verbatim, same port, started again, no rollback', () async {
      final ssh = _pc(portAnswer: _json({'ok': false, 'error': 'Port 50052 is in use by CTest.exe'}, 3));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(_calls(ssh), ['-Query', '-Port 50052']);
      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', 'start 50051']);
      final summary = r.engine.summary.join('\n');
      expect(summary, contains('Port 50052 is in use by CTest.exe'));
      expect(summary, contains('dell stays on port 50051'));
      expect(r.engine.resultPort, 50051);
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
      expect(r.engine.steps.firstWhere((s) => s.title == 'Write').status, StepStatus.fail);
    });

    test('exit 4 with "written": false → not changed, no rollback', () async {
      final ssh = _pc(portAnswer: _json({
        'ok': false,
        'error': 'Could not check whether port 50052 is free: WMI broke',
        'written': false,
      }, 4));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(_calls(ssh), ['-Query', '-Port 50052']);
      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', 'start 50051']);
      expect(r.engine.summary.join('\n'), contains('Could not check whether port 50052 is free: WMI broke'));
      expect(r.engine.resultPort, 50051);
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
    });
  });

  group('rollback', () {
    test('a previous file: -Restore <its base64>, restart, back on port 50060', () async {
      const file = '{"grpc_port": 50060}\r\n';
      final ssh = _pc(portFile: file);
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse);

      expect(_calls(ssh), ['-Query', '-Port 50052', "-Restore '${base64.encode(utf8.encode(file))}'"]);
      final restarts = _restarts(ssh);
      expect(restarts, hasLength(2));
      expect(restarts.last, contains('-LocalPort 50060'));
      expect(r.asked, [50052, 50060]);
      expect(r.engine.resultPort, 50060);
      expect(r.engine.summary.join('\n'), contains('back on port 50060'));
      expect(r.engine.steps.last.title, 'Roll back');
      expect(r.engine.steps.last.status, StepStatus.ok);
      expect(r.engine.steps.firstWhere((s) => s.title == 'Verify').status, StepStatus.fail);
    });

    test('no file before: -Remove, restart, back on port 50051', () async {
      final ssh = _pc();
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse);

      expect(_calls(ssh), ['-Query', '-Port 50052', '-Remove']);
      expect(_restarts(ssh), hasLength(2));
      expect(r.engine.resultPort, 50051);
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
    });

    test('exit 4 with "written": true (the ACL failed) → rolled back, started on the old port',
        () async {
      final ssh = _pc(portAnswer: _json({
        'ok': false,
        'error': r'Wrote C:\ProgramData\FaceSnap\server_config.json but could not set its access rights: icacls exit code 5',
        'written': true,
      }, 4));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(_calls(ssh), ['-Query', '-Port 50052', '-Remove']);
      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', '-Remove', 'start 50051'],
          reason: 'the server never started on the new port');
      expect(r.asked, [50051], reason: 'the old port still answers');
      expect(r.engine.resultPort, 50051);
      final summary = r.engine.summary.join('\n');
      expect(summary, contains('could not set its access rights'));
      expect(summary, contains('back on port 50051'));
      expect(r.engine.steps.last.title, 'Roll back');
      expect(r.engine.steps.last.status, StepStatus.ok);
    });

    test('-Port prints no JSON line → treated as a failure and rolled back', () async {
      final ssh = _pc(portAnswer: CmdResult(1, '', 'A parameter cannot be found'));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(_calls(ssh), ['-Query', '-Port 50052', '-Remove']);
      expect(r.engine.resultPort, 50051);
      expect(r.engine.summary.join('\n'), contains('A parameter cannot be found'));
    });

    test('the restart fails (no JSON, exit 1) → rolled back, restarted on the old port',
        () async {
      final ssh = _pc(
          restartAnswer: (port, nth) => nth == 1
              ? CmdResult(1, '', 'Start-Service : Service FaceSnapServer cannot be started')
              : null);
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse);

      expect(_calls(ssh), ['-Query', '-Port 50052', '-Remove']);
      final restarts = _restarts(ssh);
      expect(restarts, hasLength(2));
      expect(restarts.last, contains('-LocalPort 50051'));
      expect(r.engine.resultPort, 50051);
      expect(r.engine.summary.join('\n'), contains('cannot be started'));
      expect(r.engine.steps.firstWhere((s) => s.title == 'Restart').status, StepStatus.fail);
    });

    test('the rollback fails too → "may be on port 50052 or 50051" and how to restore', () async {
      const file = '{"grpc_port": 50051}\r\n';
      final ssh = _pc(
          portFile: file,
          restoreAnswer: _json({'ok': false, 'error': 'Could not write x: denied', 'written': false}, 4));
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse);

      final summary = r.engine.summary.join('\n');
      expect(summary, contains('Could not write x: denied'));
      expect(summary, contains('dell may be on port 50052 or 50051'));
      expect(summary, contains("-Restore '${base64.encode(utf8.encode(file))}'"));
      expect(summary, contains('Start-Service FaceSnapServer'));
      expect(r.engine.resultPort, isNull);
      expect(r.engine.steps.last.status, StepStatus.fail);
    });
  });

  group('Review Focus 5 on Windows: the connection drops', () {
    test('during the restart → no throw, no rollback, "connection lost"', () async {
      // The restart is the last command that gets through; the next SSH use
      // is the real check's forward for GetKioskInfo, which meets the dead
      // transport (SSHStateError) — not "no answer yet".
      final ssh = _pc()..failAfterPs(RegExp('Start-Service'));
      final r = _engine(ssh, 50052, checkServer: PortEngine.defaultCheckServer);

      expect(await r.engine.run(), isFalse); // no throw

      expect(r.engine.resultPort, isNull);
      expect(r.engine.summary.join('\n'),
          contains('connection lost: dell may be on port 50052 or 50051; '
              'check the server on that PC.'));
      expect(r.engine.summary.join('\n'), isNot(contains('Search')));
      expect(r.engine.summary.join('\n'), isNot(contains('rollback')));
      expect(_calls(ssh), ['-Query', '-Port 50052']);
      expect(_restarts(ssh), hasLength(1));
      expect(r.asked, [50052]);
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
    });

    test('during the rollback → "connection lost" plus how to restore by hand', () async {
      const file = '{"grpc_port": 50060}\r\n';
      final ssh = _pc(portFile: file)..failAfterPs(RegExp(r'-Restore '));
      final r = _engine(ssh, 50052, checkServer: (_, port) async => port == 50052 ? null : port);

      expect(await r.engine.run(), isFalse); // no throw

      final summary = r.engine.summary.join('\n');
      expect(summary,
          contains('connection lost: dell may be on port 50052 or 50060; '
              'check the server on that PC.'));
      expect(summary, contains('The rollback was interrupted'));
      expect(summary, contains("-Restore '${base64.encode(utf8.encode(file))}'"));
      expect(r.engine.resultPort, isNull);
      expect(r.engine.steps.last.title, 'Roll back');
      expect(r.engine.steps.last.status, StepStatus.fail);
    });
  });

  group('P6: more -Port answers', () {
    test('exit 2 (out of range) → nothing written: refused, started again, no rollback',
        () async {
      final ssh = _pc(portAnswer: _json({'ok': false, 'error': 'Port must be 1024-65535'}, 2));
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isFalse);
      expect(_calls(ssh), ['-Query', '-Port 50052']);
      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', 'start 50051']);
      expect(r.engine.summary.join('\n'), contains('dell stays on port 50051: Port must be 1024-65535'));
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
      expect(r.engine.resultPort, 50051);
    });

    test('exit 0 but another port → rolled back', () async {
      final ssh = _pc(portAnswer: _json({'ok': true, 'port': 50060}));
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isFalse);
      expect(_calls(ssh), ['-Query', '-Port 50052', '-Remove']);
      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', '-Remove', 'start 50051']);
      expect(r.engine.summary.join('\n'), contains('-Port 50052 reported port 50060'));
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
    });

    test('exit 4 without "written" → maybe written: rolled back', () async {
      final ssh = _pc(portAnswer: _json({'ok': false, 'error': 'Could not write: disk full'}, 4));
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isFalse);
      expect(_calls(ssh), ['-Query', '-Port 50052', '-Remove']);
      expect(r.engine.summary.join('\n'), contains('Could not write: disk full'));
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
    });

    test('extra stdout lines around the JSON line → the JSON line counts: success', () async {
      final ssh = _pc(
          portAnswer: CmdResult(
              0, 'WARNING: something\r\n{"ok":true,"port":50052}\r\nmore text\r\n', ''));
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isTrue, reason: r.engine.summary.join('\n'));
      expect(r.engine.resultPort, 50052);
    });

    test('exit 1 with the usage JSON → treated as a failure: rolled back', () async {
      final ssh = _pc(
          portAnswer: _json({'ok': false, 'error': 'usage: set_server_port.ps1 -Query | -Port N'}, 1));
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isFalse);
      expect(_calls(ssh), ['-Query', '-Port 50052', '-Remove']);
      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', '-Remove', 'start 50051']);
      expect(r.engine.summary.join('\n'), contains('usage: set_server_port.ps1'));
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
    });
  });

  group('I1 on Windows: the connection drops after -Port, before the restart', () {
    test('→ the service may be stopped (D-1: stopped before the write), how to restore; '
        'no start, no rollback', () async {
      const file = '{"grpc_port": 50060}\r\n';
      final ssh = _pc(portFile: file)..failAfterPs(RegExp(r'-Port 50052$'));
      final r = _engine(ssh, 50052);

      expect(await r.engine.run(), isFalse); // no throw

      final summary = r.engine.summary.join('\n');
      expect(summary,
          contains('connection lost: the FaceSnapServer service on dell may be stopped, '
              'and its server_config.json may already say port 50052.'));
      expect(summary, contains("Check by hand, as an administrator on dell: "
          "Stop-Service FaceSnapServer, then $_setPort -Restore '${base64.encode(utf8.encode(file))}', "
          'then Start-Service FaceSnapServer.'));
      expect(summary, isNot(contains('Search')));
      expect(_calls(ssh), ['-Query', '-Port 50052']);
      expect(_restarts(ssh), isEmpty);
      expect(r.engine.steps.map((s) => s.title), isNot(contains('Roll back')));
      expect(r.engine.resultPort, isNull);
    });
  });

  group('I3 on Windows: calls that never answer', () {
    test('the setup check never answers → failed before any write', () async {
      final ssh = _pc()..hangPs(RegExp('Win32_Service'));
      final r = _engine(ssh, 50052, timeouts: _noWaits);
      expect(await r.engine.run(), isFalse);
      expect(_calls(ssh), isEmpty);
      expect(r.engine.summary.join('\n'),
          contains('Change port failed: no answer from dell to the setup check within 0 s'));
    });

    test('-Query never answers → failed before any write', () async {
      final ssh = _pc()..hangPs(RegExp(r'-Query$'));
      final r = _engine(ssh, 50052, timeouts: _noWaits);
      expect(await r.engine.run(), isFalse);
      expect(_calls(ssh), ['-Query']);
      expect(r.engine.summary.join('\n'), contains('set_server_port.ps1 -Query within 0 s'));
    });

    test('-Port never answers → a failure: rolled back (-Remove), started on the old port', () async {
      final ssh = _pc()..hangPs(RegExp(r'-Port 50052$'));
      final r = _engine(ssh, 50052, timeouts: _noWaits);
      expect(await r.engine.run(), isFalse);
      expect(_calls(ssh), ['-Query', '-Port 50052', '-Remove']);
      expect(_sequence(ssh), ['-Query', 'stop', '-Port 50052', '-Remove', 'start 50051']);
      expect(r.engine.summary.join('\n'), contains('back on port 50051'));
      expect(r.engine.resultPort, 50051);
    });

    test('the restart never answers; the rollback\'s restart neither → "connection lost" '
        'with how to restore', () async {
      final ssh = _pc()..hangPs(RegExp('Start-Service'));
      final r = _engine(ssh, 50052, timeouts: _noWaits);
      expect(await r.engine.run(), isFalse); // no hang, no throw
      expect(_calls(ssh), ['-Query', '-Port 50052', '-Remove']);
      expect(_restarts(ssh), hasLength(2));
      final summary = r.engine.summary.join('\n');
      expect(summary, contains('connection lost: dell may be on port 50052 or 50051; '
          'check the server on that PC. The rollback was interrupted.'));
      expect(summary, contains('Stop-Service FaceSnapServer, then $_setPort -Remove, '
          'then Start-Service FaceSnapServer.'));
      expect(r.logs.join('\n'), contains('Start-Service FaceSnapServer within 0 s'));
      expect(r.engine.resultPort, isNull);
    });

    test('the limits: restart = ready timeout + 30 s; identify/facts/query 30 s; writes 60 s',
        () async {
      // Recorded by a runner that notes the timeout each call asks for.
      final ssh = _TimeoutRecorder(_pc());
      final engine = _Engine(ssh, 50052, <String>[], checkServer: _honest);
      expect(await engine.run(), isTrue, reason: engine.summary.join('\n'));
      String limitOf(String what) => ssh.limits.entries
          .firstWhere((e) => decodedPowerShell(e.key)?.contains(what) ?? false)
          .value
          .toString();
      expect(limitOf('OSVersion.Platform'), const Duration(seconds: 30).toString());
      expect(limitOf('Win32_Service'), const Duration(seconds: 30).toString());
      expect(limitOf('-Query'), const Duration(seconds: 30).toString());
      expect(limitOf('-Port 50052'), const Duration(seconds: 60).toString());
      // readyTimeout zero here (the test engine) + 30 s.
      expect(limitOf('Stop-Service'), const Duration(seconds: 60).toString());
      expect(limitOf('Start-Service'), const Duration(seconds: 30).toString());
    });
  });

  group('M2 on Windows: FACE_SNAP_GRPC_BIND set for the service', () {
    test('→ refused before -Query', () async {
      final ssh = _pc(override: 'FACE_SNAP_GRPC_BIND');
      final r = _engine(ssh, 50052);
      expect(await r.engine.run(), isFalse);
      expect(_calls(ssh), isEmpty);
      expect(r.engine.summary.join('\n'),
          contains('the FaceSnapServer service on dell sets FACE_SNAP_GRPC_BIND; '
              'the port file would be ignored'));
    });

    test('the facts script asks NSSM and the machine environment', () {
      expect(windowsFactsScript, contains('get FaceSnapServer AppEnvironmentExtra'));
      expect(windowsFactsScript, contains("Join-Path \$app 'nssm.exe'"));
      expect(windowsFactsScript, contains("GetEnvironmentVariable(\$bind, 'Machine')"));
      expect(windowsFactsScript, contains('override = \$override'));
    });
  });

  group('P5: the ready deadline counts from Restart-Service\'s return', () {
    test('the script reports its listener wait; the verification counts it', () async {
      // The listener wait already used the whole 5 s: one GetKioskInfo, then
      // the verdict (no further rounds), then the rollback.
      final ssh = _pc(restartAnswer: (port, nth) => _json({'listening': false, 'waited_ms': 5000}));
      var asked = 0;
      final counting = _WaitEngine(ssh, 50052, <String>[], checkServer: (_, port) async {
        if (port == 50052) asked++;
        return port == 50052 ? null : port;
      }, readyTimeout: const Duration(seconds: 5));

      expect(await counting.run(), isFalse);
      expect(asked, 1, reason: 'the 5 s were already spent in the listener wait');
      expect(counting.resultPort, 50051);
    });

    test('the clock starts after Restart-Service returns', () {
      final script = windowsStartScript(50052, 60);
      final restart = script.indexOf('Start-Service -Name FaceSnapServer');
      final started = script.indexOf(r'$started = Get-Date');
      expect(started, greaterThan(restart));
      expect(script, contains(r'$deadline = $started.AddSeconds(60)'));
      expect(script, contains('"waited_ms":'));
    });
  });

  test('P7: a server folder too long for one -Query command line → a clear refusal', () async {
    final long = 'C:\\${'x' * 2500}';
    final ssh = _pc(app: long);
    final r = _engine(ssh, 50052);
    expect(await r.engine.run(), isFalse);
    expect(_calls(ssh), isEmpty);
    expect(r.engine.summary.join('\n'),
        contains('the server folder on dell is too long for one command line'));
  });

  test('the inline scripts stay under the windowsPs limit', () {
    expect(windowsFactsScript.length, lessThan(kMaxPsScriptLength));
    expect(windowsStartScript(65535, 60).length, lessThan(kMaxPsScriptLength));
    expect(setServerPortScript(_app, '-Port 65535').length, lessThan(kMaxPsScriptLength));
  });

  test('psQuote doubles every quote PowerShell reads as a single quote', () {
    final typographic = String.fromCharCode(0x2019); // PowerShell's quote too
    expect(psQuote(r"D:\Kiosk's"), r"'D:\Kiosk''s'");
    expect(psQuote('D:\\Kiosk${typographic}s'), "'D:\\Kiosk$typographic${typographic}s'");
    expect(setServerPortCall(r'C:\', '-Query'), r"& 'C:\set_server_port.ps1' -Query");
  });

  test('a port file too large for one rollback command is refused before any write', () async {
    final big = '{"grpc_port": 50060, "pad": "${'x' * 2000}"}';
    final ssh = _pc(portFile: big);
    final r = _engine(ssh, 50052);

    expect(await r.engine.run(), isFalse);

    expect(_calls(ssh), ['-Query']);
    expect(r.engine.summary.join('\n'), contains('too large to keep for a rollback'));
    expect(r.engine.steps[2].status, StepStatus.fail);
    expect(r.engine.resultPort, 50060);
  });

  test('the inline scripts parse in Windows PowerShell', () async {
    final dir = await Directory.systemTemp.createTemp('port_ps_');
    try {
      final scripts = {
        'facts.ps1': windowsFactsScript,
        'stop.ps1': windowsStopScript,
        'start.ps1': windowsStartScript(50052, 60),
        'setport.ps1': setServerPortScript(r"D:\Kiosk's\FaceSnap", '-Restore eyJ9'),
      };
      for (final e in scripts.entries) {
        File('${dir.path}\\${e.key}').writeAsStringSync(e.value);
      }
      final check = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        "Get-ChildItem -LiteralPath '${dir.path}' -Filter *.ps1 | ForEach-Object { "
            r'$e = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$e); '
            r'if ($e) { "$($_.Name): $($e[0].Message)" } }',
      ]);
      expect(check.exitCode, 0, reason: '${check.stderr}');
      expect('${check.stdout}'.trim(), isEmpty, reason: 'parse errors');
    } finally {
      dir.deleteSync(recursive: true);
    }
  }, skip: !Platform.isWindows ? 'Windows PowerShell only' : false);
}

/// A runner that answers like [inner] and notes the timeout of each run.
class _TimeoutRecorder implements SshRunner {
  _TimeoutRecorder(this.inner);
  final ScriptedSsh inner;
  final limits = <String, Duration>{};

  @override
  Future<CmdResult> run(String command, {Duration timeout = const Duration(minutes: 3)}) {
    limits.putIfAbsent(command, () => timeout);
    return inner.run(command, timeout: timeout);
  }

  @override
  void close() => inner.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WaitEngine extends PortEngine {
  _WaitEngine(this.fake, int newPort, List<String> logs,
      {required super.checkServer, required super.readyTimeout})
      : super(
            host: 'dell',
            user: 'kioskadmin',
            password: 'x',
            newPort: newPort,
            pollInterval: Duration.zero,
            onChanged: () {},
            onLog: logs.add);
  final SshRunner fake;

  @override
  Future<SshRunner> openSsh() async => fake;
}
