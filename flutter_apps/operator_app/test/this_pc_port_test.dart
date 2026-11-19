// The startup rule for the saved server (spec 2026-10-15 section 2, "Operator
// app"): config.json keeps the host and port the app was connected to, but the
// port of the server on THIS PC is the one in %ProgramData%\FaceSnap\
// server_config.json (the setup's choice). A saved local host therefore uses
// that port, not the saved one, so a port change in the setup never leaves the
// app pointing at the old port; a saved remote host keeps its own port.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/server_connector.dart';

void main() {
  test('a saved local host uses the port of the server on this PC', () {
    for (final host in ['localhost', '127.0.0.1', '::1']) {
      expect(effectivePort(host, 50051, 50099), 50099, reason: host);
      expect(effectivePort(host, 50099, 50051), 50051, reason: host);
    }
  });

  test('a saved remote host keeps its saved port', () {
    for (final host in [
      'facesnap-001e0644278f.local',
      '192.168.3.198',
      'odroid',
    ]) {
      expect(effectivePort(host, 50051, 50099), 50051, reason: host);
      expect(effectivePort(host, 50077, 50099), 50077, reason: host);
    }
  });
}
