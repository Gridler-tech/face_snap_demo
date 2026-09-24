// The connection strip must answer "reachable?" and "logged in?" separately
// and in plain words, and the image note must compare versions correctly
// (same / downgrade / upgrade) across both server generations' tags. All pure;
// no board needed.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/connection_probe.dart';

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
