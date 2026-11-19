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

  // On a service install (1.1.25+) the card drives the FaceSnapServer service:
  // a Stop goes through Stop-Service, whose pre-stop hook sets the stop event
  // (an event-only exit would be restarted by NSSM). It never kills a process
  // there. Without the service the app sets the event itself first.
  group('service commands', () {
    test('start and stop address the service by name, never a process', () {
      expect(ServerManager.serviceStartCommand, 'Start-Service -Name FaceSnapServer');
      expect(ServerManager.serviceStopCommand, 'Stop-Service -Name FaceSnapServer');
      expect(ServerManager.serviceStopCommand, isNot(contains('Stop-Process')));
      expect(ServerManager.signalStopCommand, isNot(contains('Stop-Process')));
    });
    test('the stop signal opens the global event and tolerates its absence', () {
      expect(ServerManager.signalStopCommand, contains(r"OpenExisting('Global\FaceSnapServerStop')"));
      expect(ServerManager.signalStopCommand, contains('catch'));
    });
  });
  group('parseServiceState', () {
    test('maps the Get-Service words', () {
      expect(ServerManager.parseServiceState('Running\r\n'), ServiceState.running);
      expect(ServerManager.parseServiceState('stopped'), ServiceState.stopped);
      expect(ServerManager.parseServiceState('StartPending'), ServiceState.startPending);
      expect(ServerManager.parseServiceState('StopPending'), ServiceState.stopPending);
      expect(ServerManager.parseServiceState(''), ServiceState.unknown);
    });
  });
  group('serverStatusText', () {
    test('a service that is up but not yet listening is not "not running"', () {
      expect(ServerManager.serverStatusText(false, ServiceState.startPending), 'Service is starting, port not open yet');
      expect(ServerManager.serverStatusText(false, ServiceState.running), 'Service is starting, port not open yet');
      expect(ServerManager.serverStatusText(true, ServiceState.running), 'Server is running');
      expect(ServerManager.serverStatusText(false, ServiceState.stopped), 'Server is not running');
      expect(ServerManager.serverStatusText(false, ServiceState.stopPending), 'Service is stopping…');
      expect(ServerManager.serverStatusText(null, null), 'Checking…');
      expect(ServerManager.serverStatusText(true, null), 'Server is running');
    });

    test('an open port is running whatever the service says, except stopping',
        () {
      // A server on the port that the service did not start (one run from
      // source while the service is stopped) is still running.
      expect(ServerManager.serverStatusText(true, ServiceState.stopped), 'Server is running');
      expect(ServerManager.serverStatusText(true, ServiceState.unknown), 'Server is running');
      // While the service stops, the port is still open until the server exits.
      expect(ServerManager.serverStatusText(true, ServiceState.stopPending), 'Service is stopping…');
    });
  });

  // A per-user logon shortcut (the old autostart switch) would start a second
  // server at logon next to the service: the app removes it once it finds
  // the service, and only then.
  group('shouldRemoveLogonShortcut', () {
    test('only a service install with a logon shortcut removes it', () {
      expect(ServerManager.shouldRemoveLogonShortcut(true, true), isTrue);
      expect(ServerManager.shouldRemoveLogonShortcut(true, false), isFalse);
      expect(ServerManager.shouldRemoveLogonShortcut(false, true), isFalse);
      expect(ServerManager.shouldRemoveLogonShortcut(false, false), isFalse);
    });
  });

  // A port still listening after Stop-Service is reported with its owner,
  // never killed.
  group('portOwnerCommand', () {
    final cmd = ServerManager.portOwnerCommand(50051);

    test('looks up the listeners on the port without killing anything', () {
      expect(cmd, contains('Get-NetTCPConnection -LocalPort 50051 -State Listen'));
      expect(cmd, contains('Get-Process -Id'));
      expect(cmd, isNot(contains('Stop-Process')));
    });

    test('prints every owner in the form portOwnerConflict reads', () {
      expect(cmd, contains('"OTHER:" + \$p.ProcessName + ":" + \$_'));
      expect(ServerManager.portOwnerConflict('OTHER:face_snap_server:812\r\n'),
          'face_snap_server (PID 812)');
    });
  });
}
