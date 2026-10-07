// "Stop server" on this PC kills whoever listens on the configured port. That
// must be the FaceSnap server exe and nothing else: the script resolves the
// owning process to its executable path and kills only on a match; any other
// owner is reported back and the stop refuses.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/server_manager.dart';

void main() {
  group('stopCommand', () {
    final cmd = ServerManager.stopCommand(50051);

    test('looks up listeners on the configured port only', () {
      expect(cmd, contains('Get-NetTCPConnection -LocalPort 50051 -State Listen'));
    });

    test('kills only a process whose exe is the server, case-insensitively',
        () {
      expect(cmd, contains('Get-Process -Id'));
      expect(cmd, contains("\$p.Path -ieq '${ServerManager.exePath}'"));
      // The kill sits inside the path check, never before it.
      expect(cmd.indexOf('Stop-Process'), greaterThan(cmd.indexOf('-ieq')));
      expect('Stop-Process'.allMatches(cmd), hasLength(1));
    });

    test('reports any other owner instead of killing it', () {
      expect(cmd, contains('elseif (\$p) { "OTHER:" + \$p.ProcessName'));
    });
  });

  group('portOwnerConflict', () {
    test('no output (nothing listening, or the server was killed) is fine', () {
      expect(ServerManager.portOwnerConflict(''), isNull);
      expect(ServerManager.portOwnerConflict('\n  \n'), isNull);
    });

    test('an OTHER line names the squatter and its pid', () {
      expect(ServerManager.portOwnerConflict('OTHER:python:4321'),
          'python (PID 4321)');
    });

    test('finds the line among other output', () {
      expect(ServerManager.portOwnerConflict('\r\nOTHER:node:77\r\n'),
          'node (PID 77)');
    });
  });
}
