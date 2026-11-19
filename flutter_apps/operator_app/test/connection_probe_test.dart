// The connection strip must answer "reachable?" and "logged in?" separately
// and in plain words, and the image note must compare versions correctly
// (same / downgrade / upgrade) across both server generations' tags. A
// Windows PC is recognised (only its port can be changed) and the port in
// use is read from a board or a PC — over a scripted SSH connection; no board
// needed.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/updater/batch_runner.dart';
import 'package:operator_app/updater/connection_probe.dart';
import 'package:operator_app/updater/server_port.dart';

import 'scripted_ssh.dart';

CmdResult _json(Object json) => CmdResult(0, '${jsonEncode(json)}\r\n', '');

/// A Windows PC over SSH: cmd.exe has no uname; PowerShell names the
/// platform; the setup's facts and set_server_port.ps1 -Query answer.
ScriptedSsh _windowsPc({bool service = true, int port = 50052}) => ScriptedSsh()
  ..on(RegExp(r'^uname -s -m$'),
      CmdResult(1, '', "'uname' is not recognized as an internal or external command"))
  ..onPs(RegExp(r'OSVersion\.Platform'),
      (_) => CmdResult(0, 'Win32NT\r\nDELL-KIOSK\r\nAMD64\r\n', ''))
  ..onPs(RegExp(r'Win32_Service'), (_) => _json({
        'admin': true,
        'service': service,
        'app': service ? r'C:\Program Files\FaceSnap' : '',
        'script': service,
        'error': '',
      }))
  ..onPs(RegExp(r'set_server_port\.ps1. -Query$'), (_) => _json({
        'port': port,
        'source': port == kDefaultPort ? 'default' : 'file',
        'content': port == kDefaultPort
            ? ''
            : base64.encode(utf8.encode('{"grpc_port": $port}\r\n')),
      }));

/// A Linux board: [arch], a FaceSnap image, the port file when [portFile].
ScriptedSsh _board({String arch = 'aarch64', String? portFile}) => ScriptedSsh()
  ..on(RegExp(r'^uname -s -m$'), CmdResult(0, 'Linux $arch\n', ''))
  ..on(RegExp('device-tree/model'), CmdResult(0, 'Radxa Dragon Q6A', ''))
  ..on(RegExp('docker-compose'), CmdResult(0, 'facesnap2:2.0.28-arm64\n', ''))
  ..on(RegExp(r'^systemctl is-active'), CmdResult(0, 'active\n', ''))
  ..on(RegExp('^test -f ${RegExp.escape(kBoardPortFile)} && cat'),
      portFile == null ? CmdResult(1, '', '') : CmdResult(0, portFile, ''));

/// Records the timeout of each PowerShell call (by its decoded script).
class _TimedSsh extends ScriptedSsh {
  _TimedSsh(this._rules);
  final ScriptedSsh _rules;
  final timeouts = <String, Duration>{};

  @override
  Future<CmdResult> run(String command, {Duration timeout = const Duration(minutes: 3)}) {
    final script = decodedPowerShell(command);
    if (script != null) timeouts[script] = timeout;
    return _rules.run(command, timeout: timeout);
  }
}

Future<ProbeResult> _probeOver(ScriptedSsh ssh) => probeKiosk('kiosk', 'root', 'secret-pw',
    connect: (host, user, password) async => ssh);

void main() {
  group('probeHeadline / probeDetail', () {
    test('idle asks for the fields', () {
      expect(probeHeadline(ProbeResult.idle), contains('Enter a kiosk'));
      expect(probeDetail(ProbeResult.idle), isNull);
    });

    test('checking', () {
      expect(probeHeadline(ProbeResult.checking), 'Checking…');
      expect(ProbeResult.checking.settled, isFalse);
    });

    test('connected with a running server names board, user and version', () {
      const r = ProbeResult(ProbeState.connected,
          host: 'kiosk.local',
          user: 'root',
          model: 'Hardkernel ODROID-N2Plus',
          arch: 'aarch64',
          installedVersion: '2.0.11-arm64',
          serverRunning: true);
      expect(probeHeadline(r),
          'Connected — Hardkernel ODROID-N2Plus · logged in as root');
      expect(probeDetail(r), 'FaceSnap 2.0.11-arm64 installed, server running');
      expect(r.connected, isTrue);
      expect(r.settled, isTrue);
    });

    test('connected with a stopped server says so', () {
      const r = ProbeResult(ProbeState.connected,
          user: 'root', model: 'Radxa', installedVersion: '2.0.10-arm64');
      expect(probeDetail(r), endsWith('server stopped'));
    });

    test('connected clean board flags that Update will set it up', () {
      const r = ProbeResult(ProbeState.connected,
          user: 'root', model: 'Hardkernel ODROID-N2Plus');
      expect(probeDetail(r), contains('clean board'));
      expect(probeDetail(r), contains('Update will set it up'));
    });

    test('password rejected is distinct from unreachable', () {
      const auth =
          ProbeResult(ProbeState.authFailed, host: 'k.local', user: 'root');
      const down = ProbeResult(ProbeState.unreachable,
          host: 'k.local', user: 'root', error: 'timed out');
      expect(probeHeadline(auth), 'Password rejected for root on k.local');
      expect(probeHeadline(down), 'k.local not reachable (timed out)');
      expect(probeDetail(auth), isNull);
      expect(probeDetail(down), isNull);
      expect(auth.connected, isFalse);
      expect(auth.settled, isTrue);
    });

    test('unreachable without a reason has no empty parentheses', () {
      const r = ProbeResult(ProbeState.unreachable, host: 'k.local');
      expect(probeHeadline(r), 'k.local not reachable');
    });

    test('wrong architecture names the arch and doubts the machine', () {
      const r = ProbeResult(ProbeState.wrongArch,
          host: '10.0.0.5', arch: 'x86_64', model: 'x86_64');
      expect(probeHeadline(r), contains('x86_64'));
      expect(probeHeadline(r), contains('right machine'));
      expect(r.connected, isFalse);
      expect(r.portChangeable, isFalse);
    });

    test('an unknown system without an architecture has no empty parentheses', () {
      const r = ProbeResult(ProbeState.wrongArch, host: '10.0.0.5');
      expect(probeHeadline(r), 'Not an arm64 board — is 10.0.0.5 the right machine?');
    });
  });

  group('probeKiosk over a scripted SSH connection', () {
    test('a Windows PC is recognised, with the port its server uses', () async {
      final ssh = _windowsPc(port: 50052);
      final r = await _probeOver(ssh);
      expect(r.state, ProbeState.windowsPc);
      expect(r.currentPort, 50052);
      expect(r.model, 'DELL-KIOSK');
      expect(r.connected, isFalse, reason: 'update/backup/restore/remove stay off');
      expect(r.portChangeable, isTrue);
      expect(r.settled, isTrue);
      expect(ssh.closed, isTrue);
      expect(probeHeadline(r), 'Windows PC DELL-KIOSK · logged in as root');
    });

    test('a Windows PC without the FaceSnapServer service has no current port', () async {
      final r = await _probeOver(_windowsPc(service: false));
      expect(r.state, ProbeState.windowsPc);
      expect(r.currentPort, isNull);
      expect(r.portChangeable, isTrue, reason: 'Change port then says why it refuses');
      expect(probeDetail(r), contains('1.1.25'));
    });

    test('a connected board reports its port file, else the default', () async {
      final none = await _probeOver(_board());
      expect(none.state, ProbeState.connected);
      expect(none.currentPort, 50051);
      expect(none.installedVersion, '2.0.28-arm64');
      expect(none.portChangeable, isTrue);

      final file = await _probeOver(_board(portFile: '{"grpc_port": 50052}\n'));
      expect(file.currentPort, 50052);
    });

    test("a Windows PC's port is read with 30 s per call, not SshRunner's 3 minutes", () async {
      final ssh = _TimedSsh(_windowsPc());
      await probeKiosk('kiosk', 'root', 'secret-pw', connect: (h, u, p) async => ssh);
      final facts = ssh.timeouts.entries.where((e) => e.key.contains('Win32_Service'));
      final query = ssh.timeouts.entries.where((e) => e.key.contains('-Query'));
      expect(facts.single.value, const Duration(seconds: 30));
      expect(query.single.value, const Duration(seconds: 30));
    });

    test('a Linux PC that is no arm64 board stays wrongArch, without a port', () async {
      final r = await _probeOver(_board(arch: 'x86_64'));
      expect(r.state, ProbeState.wrongArch);
      expect(r.arch, 'x86_64');
      expect(r.currentPort, isNull);
      expect(r.portChangeable, isFalse);
    });
  });

  group('preflightResultOf', () {
    const target = BatchTarget(host: 'k', user: 'root', password: 'pw');

    test('a Windows PC is skipped as no kiosk board', () {
      final r = preflightResultOf(
          target, const ProbeResult(ProbeState.windowsPc, host: 'k', model: 'DELL', currentPort: 50051));
      expect(r.verdict, PreflightVerdict.wrongArch);
      expect(r.detail, 'Windows PC: not a kiosk board');
      expect(r.ok, isFalse);
    });

    test('a connected board is ok with its model and version', () {
      final r = preflightResultOf(target,
          const ProbeResult(ProbeState.connected, model: 'Radxa', installedVersion: '2.0.24-arm64'));
      expect(r.verdict, PreflightVerdict.ok);
      expect(r.detail, 'Radxa, 2.0.24-arm64');
      expect(r.installedVersion, '2.0.24-arm64');
    });

    test('the other states keep the probe headline', () {
      const auth = ProbeResult(ProbeState.authFailed, host: 'k', user: 'root');
      expect(preflightResultOf(target, auth).verdict, PreflightVerdict.authFailed);
      expect(preflightResultOf(target, auth).detail, probeHeadline(auth));
      const arm = ProbeResult(ProbeState.wrongArch, host: 'k', arch: 'x86_64');
      expect(preflightResultOf(target, arm).verdict, PreflightVerdict.wrongArch);
      expect(preflightResultOf(target, arm).detail, probeHeadline(arm));
      const down = ProbeResult(ProbeState.unreachable, host: 'k');
      expect(preflightResultOf(target, down).verdict, PreflightVerdict.unreachable);
    });
  });

  group('shortConnectionError', () {
    test('maps the common socket failures to plain words', () {
      expect(shortConnectionError('SocketException: Connection timed out'),
          'timed out');
      expect(shortConnectionError('TimeoutException after 0:00:15'),
          'timed out');
      expect(
          shortConnectionError(
              'SocketException: Connection refused (OS Error: errno = 10061)'),
          'connection refused');
      expect(
          shortConnectionError(
              'SocketException: Failed host lookup: nosuch.local'),
          'name not found');
      expect(shortConnectionError('No route to host'), 'no route');
    });

    test('anything else is a generic no-connection', () {
      expect(shortConnectionError('weird'), 'no SSH connection');
    });
  });

  group('imageVersionNote', () {
    test('same version is flagged as already installed', () {
      final n = imageVersionNote('2.0.11-arm64', 'face_snap-2.0.11-arm64.tar')!;
      expect(n.text, 'version 2.0.11 is already installed');
      expect(n.warn, isTrue);
    });

    test('older image is a downgrade (warn)', () {
      final n = imageVersionNote('2.0.11-arm64', 'face_snap-2.0.9-arm64.tar')!;
      expect(n.text, 'downgrade: 2.0.11 → 2.0.9');
      expect(n.warn, isTrue);
    });

    test('newer image is an upgrade (no warn)', () {
      final n = imageVersionNote('2.0.9-arm64', 'face_snap-2.0.11-arm64.tar')!;
      expect(n.text, 'upgrade: 2.0.9 → 2.0.11');
      expect(n.warn, isFalse);
    });

    test('compares numerically, not lexically', () {
      // "2.0.9" < "2.0.11" numerically; a string compare would say otherwise.
      expect(
          imageVersionNote('2.0.9-arm64', 'face_snap-2.0.11-arm64.tar')!.warn,
          isFalse);
      expect(imageVersionNote('1.4.0', 'face_snap-2.0.11-arm64.tar')!.text,
          startsWith('upgrade'));
    });

    test('first-generation tag (no arch suffix) works too', () {
      final n = imageVersionNote('1.4.0', 'face_snap-1.4.0.tar')!;
      expect(n.text, contains('already installed'));
    });

    test('nothing to say when either side is unknown', () {
      expect(imageVersionNote(null, 'face_snap-2.0.11-arm64.tar'), isNull);
      expect(imageVersionNote('2.0.11-arm64', null), isNull);
    });

    test('nothing to say for tags without a dotted version', () {
      expect(imageVersionNote('arm64', 'face_snap-2.0.11-arm64.tar'), isNull);
      expect(imageVersionNote('2.0.11-arm64', 'face_snap-latest.tar'), isNull);
      expect(imageVersionNote('2.0.11-arm64', 'random.tar'), isNull);
    });
  });
}
