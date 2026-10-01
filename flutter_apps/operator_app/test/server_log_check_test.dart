import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/kiosk.dart';

// The updater's verification reads the new server's log: real errors fail the
// update (and roll it back), missing kiosk hardware must not.
void main() {
  // Verbatim from a downgrade 2.0.11 -> 1.1.0-ofiq of an Odroid with no Plasma
  // board attached (2026-10-01), which was rolled back on exactly these lines.
  const firstGenNoLedBoard = '''
2026-10-01 12:00:15,990 [INFO] server.py:120 - gRPC server started
2026-10-01 12:00:16,055 [ERROR] server.py:187 - Plasma LED board not connected on startup; will retry on first LED command
2026-10-01 12:00:16,385 [ERROR] mpremote.py:484 - Error executing command, cmd: ['/usr/local/bin/python', '-m', 'mpremote', 'resume', 'exec', '\\nimport gbl; gbl.LED_BRIGHTNESS_RED=200\\ngbl.LED_BRIGHTNESS_GREEN=200\\ngbl.LED_BRIGHTNESS_BLUE=200'], exit code: 1, stderr: mpremote: no device found
2026-10-01 12:00:17,376 [ERROR] mpremote.py:484 - Error executing command, cmd: ['/usr/local/bin/python', '-m', 'mpremote', 'resume', 'exec', 'import gbl; gbl.CURRENT_STEP=1'], exit code: 1, stderr: mpremote: no device found
''';

  // Server 2.0 (.NET console logger): level on its own line, message indented.
  const server20NoLedBoard = '''
info: FaceSnap.Server[0]
      FaceSnap Server 2.0 bound to port 50051
fail: FaceSnap.Server[0]
      Plasma LED board not connected on startup; the hardware watcher keeps looking for it
''';

  test('a board without its LED board passes (first generation)', () {
    expect(serverLogErrors(firstGenNoLedBoard), isEmpty);
    expect(firstGenNoLedBoard.split('\n').where(kHardwareAbsentRe.hasMatch), hasLength(3));
  });

  test('a board without its LED board passes (Server 2.0)', () {
    expect(serverLogErrors(server20NoLedBoard), isEmpty);
  });

  test('no cameras at boot is not a failure', () {
    expect(
        serverLogErrors('2026-10-01 12:00:16,500 [ERROR] camera_group.py:231 - '
            'No cameras available to probe resolutions'),
        isEmpty);
  });

  test('real errors still fail, also next to missing hardware', () {
    const log = '''
$firstGenNoLedBoard
2026-10-01 12:00:18,000 [ERROR] server.py:99 - Could not bind gRPC server to [::]:50051
Traceback (most recent call last):
2026-10-01 12:00:19,000 [ERROR] mpremote.py:484 - Error executing command, cmd: ['mpremote', 'cp'], exit code: 1, stderr: could not enter raw repl
2026-10-01 12:00:20,000 [CRITICAL] camera.py:10 - Failed to open camera with index: 0
System.InvalidOperationException: Sequence contains no elements
''';
    expect(serverLogErrors(log), [
      '2026-10-01 12:00:18,000 [ERROR] server.py:99 - Could not bind gRPC server to [::]:50051',
      'Traceback (most recent call last):',
      "2026-10-01 12:00:19,000 [ERROR] mpremote.py:484 - Error executing command, cmd: ['mpremote', 'cp'], "
          'exit code: 1, stderr: could not enter raw repl',
      '2026-10-01 12:00:20,000 [CRITICAL] camera.py:10 - Failed to open camera with index: 0',
      'System.InvalidOperationException: Sequence contains no elements',
    ]);
  });

  test('informational lines and known board noise are not failures', () {
    const log = '''
2026-10-01 12:00:15,000 [INFO] settings_manager.py:30 - No settings yet, or JSONDecodeError: starting from defaults
warn: FaceSnap.Server[0]
      Camera calibration holds no positions
2026-10-01 12:00:15,500 [ERROR] onnxruntime - PR_SVE_GET_VL failed on this kernel
''';
    expect(serverLogErrors(log), isEmpty);
  });
}
