// The Updater's "Server port" card (spec 2026-10-15 §6): its states (before a
// connection, a connected board, a Windows PC, busy while a change runs),
// the board-only actions switched off for a Windows PC, the confirmation, the
// notice after a change, the saved server following only when it IS the
// machine changed (Review Focus 1) and never for a Windows PC, whose server
// accepts local connections only (R14), and the factory-defaults link forwarding
// to the machine's real port. The probe, the engine and the factory link are
// injected: no SSH, no hardware.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/updater_page.dart';
import 'package:operator_app/services/app_config.dart';
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/ui/ui.dart';
import 'package:operator_app/updater/column_factory.dart';
import 'package:operator_app/updater/connection_probe.dart';
import 'package:operator_app/updater/kiosk.dart';
import 'package:operator_app/updater/port_engine.dart';
import 'package:operator_app/updater/server_port.dart';

import 'scripted_ssh.dart';

const _password = 'secret-pw';
const _windowsHint = 'Windows PC: only the server port can be changed here.';

CmdResult _json(Object json) => CmdResult(0, '${jsonEncode(json)}\r\n', '');

/// A Windows PC whose server uses [port] (no server_config.json) and whose
/// set_server_port.ps1 does what it is asked; [admin] false = a plain account.
ScriptedSsh _pc({int port = 50051, bool admin = true}) => ScriptedSsh()
  ..on(RegExp(r'^uname -s -m$'),
      CmdResult(1, '', "'uname' is not recognized as an internal or external command"))
  ..onPs(RegExp(r'OSVersion\.Platform'),
      (_) => CmdResult(0, 'Win32NT\r\nDELL-KIOSK\r\nAMD64\r\n', ''))
  ..onPs(RegExp(r'Win32_Service'), (_) => _json({
        'admin': admin,
        'service': true,
        'app': r'C:\Program Files\FaceSnap',
        'script': true,
        'error': '',
      }))
  ..onPs(RegExp(r'set_server_port\.ps1. -Query$'),
      (_) => _json({'port': port, 'source': 'default', 'content': ''}))
  ..onPs(RegExp(r'set_server_port\.ps1. -Port (\d+)$'), (s) => _json({
        'ok': true,
        'port': int.parse(RegExp(r'-Port (\d+)$').firstMatch(s)!.group(1)!),
      }))
  ..onPs(RegExp(r'Stop-Service -Name FaceSnapServer'), (_) => _json({'stopped': true}))
  ..onPs(RegExp(r'Start-Service -Name FaceSnapServer'), (_) => _json({'listening': true}));

/// A Radxa board on facesnap2 2.0.28 whose server uses 50051 (no port file):
/// the reads, copies, writes (into .tmp, then mv) and restarts all succeed.
ScriptedSsh _boardSsh() {
  final ssh = ScriptedSsh();
  ssh
    ..on(RegExp(r'^uname -s -m$'), CmdResult(0, 'Linux aarch64\n', ''))
    ..on(RegExp('device-tree/model'), CmdResult(0, 'Radxa Dragon Q6A', ''))
    ..on(RegExp('^test -f ${RegExp.escape(kBoardPortFile)}'), CmdResult(1, '', ''))
    ..on(RegExp(RegExp.escape(composeImageCmd(kCompose))),
        CmdResult(0, 'facesnap2:2.0.28-arm64\n', ''))
    ..on(RegExp('^cat ${RegExp.escape(kCompose)}\$'),
        CmdResult(0, composeTemplate('facesnap2:2.0.28-arm64'), ''))
    ..on(RegExp(r'^docker inspect '), CmdResult(0, '["FACE_SNAP_DATA_DIR=/data"]\n', ''))
    ..on(RegExp(r'^ss -ltn'), CmdResult(0, '', ''))
    ..on(RegExp('^test -f ${RegExp.escape(kAvahiServiceFile)}\$'), CmdResult(0, '', ''))
    ..on(RegExp(r'^(cp|mv -f|rm -f|systemctl restart) '), CmdResult(0, '', ''));
  return ssh;
}

/// The real engine over a scripted connection; the server answers on any port.
class _ScriptedEngine extends PortEngine {
  _ScriptedEngine(
    this.fake, {
    required super.host,
    required super.user,
    required super.password,
    required super.newPort,
    required super.onChanged,
    required super.onLog,
  }) : super(
          checkServer: (_, port) async => port,
          pollInterval: Duration.zero,
          readyTimeout: Duration.zero,
        );

  final SshRunner fake;

  @override
  Future<SshRunner> openSsh() async => fake;
}

/// An engine whose run ends when the test says so.
class _GatedEngine extends PortEngine {
  _GatedEngine(
    this.gate, {
    required super.host,
    required super.user,
    required super.password,
    required super.newPort,
    required super.onChanged,
    required super.onLog,
  });

  final Completer<bool> gate;

  @override
  Future<bool> run() => gate.future;
}

ProbeResult _board(String host, int? port) => ProbeResult(ProbeState.connected,
    host: host,
    user: 'root',
    model: 'Radxa Dragon Q6A',
    arch: 'aarch64',
    installedVersion: '2.0.28-arm64',
    serverRunning: true,
    currentPort: port);

ProbeResult _windows(String host, int? port) => ProbeResult(ProbeState.windowsPc,
    host: host, user: 'kioskadmin', model: 'DELL-KIOSK', arch: 'AMD64', currentPort: port);

void main() {
  late String savedHost, savedUpdaterHost, savedUser, savedPassword, savedKey;
  late int savedPort;
  late Directory dir;

  // What the injected probe answers (it may change between probes), the
  // engine the page gets, what was made, and the factory link's ports.
  late ProbeResult Function(String host) probeAnswer;
  late PortEngine Function(String host, String user, String password, int newPort,
      void Function() onChanged, void Function(String) onLog) makeEngine;
  late List<PortEngine> engines;
  late List<int> factoryPorts;
  // The app's reconnect (R11): the calls, and what it throws (null: none).
  late List<(String, int)> connects;
  Object? connectError;
  // A probe held open by the test (null: answer at once).
  Completer<ProbeResult>? heldProbe;

  setUp(() {
    savedHost = AppConfig.host;
    savedPort = AppConfig.port;
    savedUpdaterHost = AppConfig.updaterHost;
    savedUser = AppConfig.boardUser;
    savedPassword = AppConfig.boardPassword;
    savedKey = AppConfig.factoryKey;
    dir = Directory.systemTemp.createTempSync('updater_port_card_test');
    AppConfig.appDataDirOverride = dir.path;
    AppConfig.host = 'localhost';
    AppConfig.port = 50051;
    AppConfig.updaterHost = '192.168.3.169';
    AppConfig.boardUser = 'root';
    AppConfig.boardPassword = _password;
    AppConfig.factoryKey = '';
    probeAnswer = (host) => _board(host, 50051);
    makeEngine = (host, user, password, newPort, onChanged, onLog) => _ScriptedEngine(_boardSsh(),
        host: host,
        user: user,
        password: password,
        newPort: newPort,
        onChanged: onChanged,
        onLog: onLog);
    engines = [];
    factoryPorts = [];
    connects = [];
    connectError = null;
    heldProbe = null;
  });

  tearDown(() {
    AppConfig.host = savedHost;
    AppConfig.port = savedPort;
    AppConfig.updaterHost = savedUpdaterHost;
    AppConfig.boardUser = savedUser;
    AppConfig.boardPassword = savedPassword;
    AppConfig.factoryKey = savedKey;
    AppConfig.appDataDirOverride = null;
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {
      // A background config save may still hold the folder: left in temp.
    }
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: UpdaterPage(
      probe: (host, user, password) => heldProbe?.future ?? Future.value(probeAnswer(host)),
      connect: (host, port) async {
        connects.add((host, port));
        if (connectError != null) throw connectError!;
      },
      portEngine: ({
        required String host,
        required String user,
        required String password,
        required int newPort,
        required void Function() onChanged,
        required void Function(String) onLog,
      }) {
        final engine = makeEngine(host, user, password, newPort, onChanged, onLog);
        engines.add(engine);
        return engine;
      },
      openKioskServer: (host, user, password, {int remotePort = kServerPort}) async {
        factoryPorts.add(remotePort);
        throw const SocketException('test: no server');
      },
    ))));
    await tester.pump(); // the post-frame probe starts
    await tester.pump(); // and answers
  }

  VoidCallback? changePort(WidgetTester tester) =>
      tester.widget<QuietButton>(find.widgetWithText(QuietButton, 'Change port')).onPressed;
  TextField newPortField(WidgetTester tester) =>
      tester.widget<TextField>(find.byKey(const ValueKey('port-new')));
  VoidCallback? quiet(WidgetTester tester, String text) =>
      tester.widget<QuietButton>(find.widgetWithText(QuietButton, text)).onPressed;
  VoidCallback? update(WidgetTester tester) =>
      tester.widget<GoButton>(find.byType(GoButton)).onPressed;
  VoidCallback? remove(WidgetTester tester) => tester
      .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Remove server installation'))
      .onPressed;
  VoidCallback? factoryWrite(WidgetTester tester) => tester
      .widget<OutlinedButton>(find.descendant(
          of: find.byKey(const ValueKey('factory-write')), matching: find.byType(OutlinedButton)))
      .onPressed;
  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.textContaining(text));

  /// Every Text on the page (log, notice, result, dialog) holding [s].
  Finder textHolding(String s) => find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? w.textSpan?.toPlainText() ?? '').contains(s),
      skipOffstage: false);

  Future<void> askForPort(WidgetTester tester, int port) async {
    await tester.enterText(find.byKey(const ValueKey('port-new')), '$port');
    await tester.pump();
    await tester.tap(find.widgetWithText(QuietButton, 'Change port'));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Change port')));
    await tester.pumpAndSettle();
  }

  testWidgets('before a connection the card asks for one', (tester) async {
    AppConfig.boardPassword = ''; // nothing to probe: the strip stays idle
    await pumpPage(tester);
    expect(find.widgetWithText(SectionCard, 'SERVER PORT'), findsOneWidget);
    expect(find.text('Connect to a kiosk first.'), findsOneWidget);
    expect(find.widgetWithText(QuietButton, 'Change port'), findsNothing);
    expect(find.byKey(const ValueKey('port-new')), findsNothing);
  });

  testWidgets('an unreachable kiosk still asks for a connection', (tester) async {
    probeAnswer = (host) => ProbeResult(ProbeState.unreachable, host: host, error: 'timed out');
    await pumpPage(tester);
    expect(find.text('Connect to a kiosk first.'), findsOneWidget);
    expect(find.widgetWithText(QuietButton, 'Change port'), findsNothing);
  });

  testWidgets('a connected board: Current port 50051 (default), New port, Change port',
      (tester) async {
    await pumpPage(tester);
    expect(find.text('Current port: 50051 (default)'), findsOneWidget);
    expect(find.text('New port'), findsOneWidget);
    expect(changePort(tester), isNull, reason: 'no port typed yet');
    await tester.enterText(find.byKey(const ValueKey('port-new')), '80');
    await tester.pump();
    expect(changePort(tester), isNull, reason: 'outside 1024–65535');
    await tester.enterText(find.byKey(const ValueKey('port-new')), '50051');
    await tester.pump();
    expect(changePort(tester), isNull, reason: 'the port it already uses');
    await tester.enterText(find.byKey(const ValueKey('port-new')), '50052');
    await tester.pump();
    expect(changePort(tester), isNotNull);
    // A board keeps every other action.
    expect(find.text(_windowsHint), findsNothing);
    expect(quiet(tester, 'Backup configuration files…'), isNotNull);
    expect(remove(tester), isNotNull);
  });

  testWidgets('a board with a port file shows that port', (tester) async {
    probeAnswer = (host) => _board(host, 50052);
    await pumpPage(tester);
    expect(find.text('Current port: 50052'), findsOneWidget);
  });

  testWidgets('a Windows PC: only the port card; update/backup/restore/remove off with the hint',
      (tester) async {
    AppConfig.factoryKey = 'a-factory-key';
    probeAnswer = (host) => _windows(host, 50052);
    await pumpPage(tester);
    expect(find.text('Current port: 50052'), findsOneWidget);
    expect(find.text(_windowsHint), findsOneWidget);
    expect(update(tester), isNull);
    expect(quiet(tester, 'Get server info'), isNull);
    expect(quiet(tester, 'Backup configuration files…'), isNull);
    expect(quiet(tester, 'Restore configuration files'), isNull);
    expect(remove(tester), isNull);
    expect(factoryWrite(tester), isNull, reason: 'the column factory link is for boards');
    await tester.enterText(find.byKey(const ValueKey('port-new')), '50051');
    await tester.pump();
    expect(changePort(tester), isNotNull, reason: 'the port card works on a Windows PC');
  });

  testWidgets('the confirmation names the machine, both ports and the restart; Cancel changes nothing',
      (tester) async {
    await pumpPage(tester);
    await askForPort(tester, 50052);
    expect(find.text('Change the server port?'), findsOneWidget);
    expect(inDialog('192.168.3.169: port 50051 → 50052.'), findsOneWidget);
    expect(inDialog('The server restarts; a capture in progress is interrupted.'), findsOneWidget);
    expect(inDialog('Programs that use this kiosk must use 192.168.3.169:50052 afterwards.'),
        findsOneWidget);
    expect(inDialog('local connections only'), findsNothing, reason: 'a board keeps the old line');
    expect(textHolding(_password), findsNothing);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Cancel')));
    await tester.pumpAndSettle();
    expect(engines, isEmpty);
  });

  testWidgets('R14: on a Windows PC the confirmation says local connections only', (tester) async {
    probeAnswer = (host) => _windows(host, 50051);
    await pumpPage(tester);
    await askForPort(tester, 50052);
    expect(inDialog('192.168.3.169: port 50051 → 50052.'), findsOneWidget);
    expect(
        inDialog('The server accepts local connections only: other programs on that PC '
            'must use 127.0.0.1:50052 afterwards.'),
        findsOneWidget);
    expect(inDialog('Programs that use this kiosk'), findsNothing);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Cancel')));
    await tester.pumpAndSettle();
    expect(engines, isEmpty);
  });

  testWidgets('busy while the port changes: the card and the other actions are off',
      (tester) async {
    AppConfig.factoryKey = 'a-factory-key';
    final gate = Completer<bool>();
    makeEngine = (host, user, password, newPort, onChanged, onLog) => _GatedEngine(gate,
        host: host,
        user: user,
        password: password,
        newPort: newPort,
        onChanged: onChanged,
        onLog: onLog);
    await pumpPage(tester);
    expect(factoryWrite(tester), isNotNull);
    await askForPort(tester, 50052);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Change port')));
    await tester.pump();
    await tester.pump();

    expect(engines, hasLength(1));
    expect(engines.single.newPort, 50052);
    expect(engines.single.host, '192.168.3.169');
    expect(changePort(tester), isNull);
    expect(newPortField(tester).enabled, isFalse);
    expect(quiet(tester, 'Backup configuration files…'), isNull);
    expect(remove(tester), isNull);
    expect(factoryWrite(tester), isNull);

    gate.complete(false);
    await tester.pumpAndSettle();
    expect(newPortField(tester).enabled, isTrue);
    expect(changePort(tester), isNotNull);
    expect(find.text('Port change failed'), findsOneWidget);
  });

  testWidgets('a change shows the new address, the saved server follows, Current port refreshes',
      (tester) async {
    AppConfig.updaterHost = 'facesnap-1a2b.local';
    AppConfig.host = 'FACESNAP-1A2B.local'; // the same machine, other case
    AppConfig.port = 50051;
    probeAnswer = (host) => _board(host, 50051);
    await pumpPage(tester);
    await askForPort(tester, 50052);
    probeAnswer = (host) => _board(host, 50052); // what the machine says afterwards
    await confirm(tester);

    expect(find.text('Port change successful'), findsOneWidget);
    expect(find.text('New address: facesnap-1a2b.local:50052'), findsOneWidget);
    expect(find.text('If this machine runs a firewall, open port 50052.'), findsOneWidget);
    expect(textHolding('saved server is'), findsNothing);
    expect(AppConfig.port, 50052);
    expect(AppConfig.host, 'FACESNAP-1A2B.local');
    // The engine's own lines in the log.
    expect(textHolding('Port file, docker-compose.yml and the avahi service now say 50052.'),
        findsOneWidget);
    expect(textHolding('facesnap-1a2b.local now serves on port 50052.'), findsOneWidget);
    // The probe ran again: the card shows the machine as it is now.
    expect(find.text('Current port: 50052'), findsOneWidget);
    expect(textHolding(_password), findsNothing);
    // R11: the app's live connection follows, to the saved spelling.
    expect(connects, [('FACESNAP-1A2B.local', 50052)]);
    expect(textHolding('could not reconnect'), findsNothing);

    // Another machine typed in: the notice named the old one, so it goes.
    await tester.enterText(find.widgetWithText(TextField, 'facesnap-1a2b.local'), '192.168.3.198');
    await tester.pump(const Duration(seconds: 1)); // the debounced probe
    await tester.pump();
    expect(find.textContaining('New address'), findsNothing);
  });

  // Review Focus 1: the Updater reaches the kiosk by IP, the app saved it by
  // its .local name — not provably the same machine, so the saved port stays
  // and the notice says which server the app keeps.
  testWidgets('another saved server keeps its port; the notice names it', (tester) async {
    AppConfig.host = 'facesnap-1a2b.local';
    AppConfig.port = 50051;
    AppConfig.updaterHost = '192.168.3.169';
    probeAnswer = (host) => _board(host, 50051);
    await pumpPage(tester);
    await askForPort(tester, 50052);
    await confirm(tester);

    expect(find.text('Port change successful'), findsOneWidget);
    expect(AppConfig.port, 50051);
    expect(AppConfig.host, 'facesnap-1a2b.local');
    expect(find.text('New address: 192.168.3.169:50052'), findsOneWidget);
    expect(
        find.text("The operator app's saved server is facesnap-1a2b.local:50051; "
            'change it if that is this kiosk.'),
        findsOneWidget);
    expect(connects, isEmpty, reason: 'the app stays connected to its own server');
  });

  // R11: the app's live connection follows with the saved port; a reconnect
  // that fails is said in the log and leaves the page usable.
  testWidgets('a reconnect that fails is logged; the page stays usable', (tester) async {
    AppConfig.updaterHost = 'facesnap-1a2b.local';
    AppConfig.host = 'FACESNAP-1A2B.local';
    AppConfig.port = 50051;
    connectError = Exception('Connection refused');
    probeAnswer = (host) => _board(host, 50051);
    await pumpPage(tester);
    await askForPort(tester, 50052);
    probeAnswer = (host) => _board(host, 50052);
    await confirm(tester);

    expect(connects, [('FACESNAP-1A2B.local', 50052)]);
    expect(find.text('Port change successful'), findsOneWidget);
    expect(
        textHolding('The operator app could not reconnect to FACESNAP-1A2B.local:50052 ('),
        findsOneWidget);
    expect(textHolding('Connection refused); reconnect on the Kiosk page.'), findsOneWidget);
    expect(find.text('New address: facesnap-1a2b.local:50052'), findsOneWidget);
    expect(AppConfig.port, 50052);
    expect(newPortField(tester).enabled, isTrue);
    await tester.enterText(find.byKey(const ValueKey('port-new')), '50053');
    await tester.pump();
    expect(changePort(tester), isNotNull);
  });

  // R14: the Windows server listens on that PC only. The notice says so and
  // who follows; the app's saved server and live connection are left alone,
  // even when the saved server names that PC.
  testWidgets('a Windows PC: the local-only notice; nothing follows or reconnects',
      (tester) async {
    AppConfig.updaterHost = 'dell-kiosk.local';
    AppConfig.host = 'DELL-KIOSK.local'; // would follow on a board
    AppConfig.port = 50051;
    makeEngine = (host, user, password, newPort, onChanged, onLog) => _ScriptedEngine(_pc(),
        host: host,
        user: user,
        password: password,
        newPort: newPort,
        onChanged: onChanged,
        onLog: onLog);
    probeAnswer = (host) => _windows(host, 50051);
    await pumpPage(tester);
    await askForPort(tester, 50052);
    probeAnswer = (host) => _windows(host, 50052);
    await confirm(tester);

    expect(find.text('Port change successful'), findsOneWidget);
    expect(
        find.text('New port on dell-kiosk.local: 50052 (the server accepts local connections only).'),
        findsOneWidget);
    expect(
        find.text('The FaceSnap apps on that PC follow after they restart; '
            'other programs on that PC must use 127.0.0.1:50052.'),
        findsOneWidget);
    expect(textHolding('New address'), findsNothing);
    expect(textHolding('firewall'), findsNothing);
    expect(textHolding('saved server is'), findsNothing);
    expect(textHolding("The operator app's saved server"), findsNothing);
    expect(connects, isEmpty, reason: 'no reconnect for a Windows PC');
    expect(AppConfig.port, 50051, reason: 'no followPortChange for a Windows PC');
    expect(AppConfig.host, 'DELL-KIOSK.local');
    expect(textHolding('server_config.json now says 50052.'), findsOneWidget);
    expect(find.text('Current port: 50052'), findsOneWidget);
  });

  testWidgets('the notice stays while the machine is probed again, and if that probe fails',
      (tester) async {
    AppConfig.host = 'facesnap-1a2b.local';
    probeAnswer = (host) => _board(host, 50051);
    await pumpPage(tester);
    await askForPort(tester, 50052);
    final reprobe = Completer<ProbeResult>();
    heldProbe = reprobe;
    // No pumpAndSettle: the "Checking…" spinner never settles.
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Change port')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Checking…'), findsOneWidget);
    expect(find.text('New address: 192.168.3.169:50052'), findsOneWidget);
    reprobe.complete(const ProbeResult(ProbeState.unreachable, host: '192.168.3.169'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Connect to a kiosk first.'), findsOneWidget);
    expect(find.text('New address: 192.168.3.169:50052'), findsOneWidget);
  });

  testWidgets('a refused change: red result, no notice, the saved port untouched', (tester) async {
    AppConfig.host = '192.168.3.169';
    AppConfig.port = 50051;
    makeEngine = (host, user, password, newPort, onChanged, onLog) => _ScriptedEngine(
        _pc(admin: false),
        host: host,
        user: user,
        password: password,
        newPort: newPort,
        onChanged: onChanged,
        onLog: onLog);
    await pumpPage(tester);
    await askForPort(tester, 50052);
    await confirm(tester);

    expect(find.text('Port change failed'), findsOneWidget);
    expect(textHolding('not an administrator'), findsWidgets);
    expect(textHolding('New address'), findsNothing);
    expect(AppConfig.port, 50051);
  });

  testWidgets("the factory link forwards to the kiosk's current port", (tester) async {
    AppConfig.factoryKey = 'a-factory-key';
    probeAnswer = (host) => _board(host, 50052);
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('factory-write')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Write')));
    await tester.pumpAndSettle();
    expect(factoryPorts, [50052]);
  });
}
