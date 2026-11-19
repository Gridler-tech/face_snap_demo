// The updater's factory actions (spec 2026-10-10 section 5.4) against a fake server: "Write
// factory defaults" sends the values in force, "Save this column's standard as factory
// defaults" the standard, both with the factory key from config.json; a refused key, an older
// server and a server that cannot be reached are one line each; the key never shows - not in
// the answer, the page, the log, nor the RPC console's trace; without a key the actions are
// off. The SSH path's tunnel runs here over a fake forwarder (no SSH server here); the real
// SSH connection is exercised in the gated hardware task. No test dials port 50051.
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart' show SSHSocket;
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/updater_page.dart';
import 'package:operator_app/services/app_config.dart';
import 'package:operator_app/updater/column_factory.dart';

// Made-up keys: never the real one.
const _key = 'the-factory-key-0123456789abcdef';

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({this.oldServer = false, this.refusal});
  final bool oldServer;

  /// Refuse every write with this error (built from the request: a server could echo it).
  final GrpcError Function(WriteColumnFactoryRequest request)? refusal;
  final requests = <WriteColumnFactoryRequest>[];
  final sessionHeaders = <String?>[];

  @override
  Future<ColumnSaveResponse> writeColumnFactory(ServiceCall call, WriteColumnFactoryRequest request) async {
    if (oldServer) throw GrpcError.unimplemented('WriteColumnFactory');
    requests.add(request);
    sessionHeaders.add(call.clientMetadata?[GrpcChannelProvider.columnSessionHeader]);
    if (refusal != null) throw refusal!(request);
    if (request.key != _key) throw GrpcError.permissionDenied('the factory key was refused');
    return ColumnSaveResponse(
        outcome: ColumnSaveOutcome.COLUMN_SAVE_OUTCOME_WRITTEN,
        names: ['led_layout', 'led_geometry', 'led_colour'],
        profile: ColumnProfileResponse(boardId: 'e6614c311b4a6f2a', hasFactory: true));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

Future<int> _serve(_FakeSettings settings) async {
  final server = Server.create(services: [settings]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => server.shutdown());
  return server.port!;
}

/// A loopback port that was just closed: a call there fails at once.
Future<int> _closedPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// Whether any recorded call of the RPC console holds [text]: its path, every request and
/// response (proto3 JSON) and its status message.
bool _traceHolds(String text) => RpcTrace.calls.any((call) => jsonEncode({
      'path': call.path,
      'requests': [for (final m in call.requests) m.toJson()],
      'responses': [for (final m in call.responses) m.toJson()],
      'status': call.statusMessage,
    }).contains(text));

void _recordTrace() {
  RpcTrace.enabled = true;
  addTearDown(() {
    RpcTrace.enabled = false;
    RpcTrace.clear();
  });
  RpcTrace.clear();
}

/// Whether [port] on [address] takes a connection.
Future<bool> _accepts(InternetAddress address, int port) async {
  try {
    final socket = await Socket.connect(address, port, timeout: const Duration(seconds: 2));
    socket.destroy();
    return true;
  } on SocketException {
    return false;
  }
}

/// A fake SSH connection for [openTunnel]: each forwarded connection goes to [serverPort] on
/// this machine instead of the kiosk; it records what the tunnel asked for and its close.
class _FakeSsh {
  _FakeSsh(this.serverPort, {this.refuse = false});
  final int serverPort;
  final bool refuse;
  final forwards = <(String, int)>[];
  int closes = 0;

  Future<SSHSocket> forward(String host, int port) async {
    forwards.add((host, port));
    if (refuse) throw const SocketException('the kiosk refused the forward');
    return SSHSocket.connect('127.0.0.1', serverPort);
  }

  Future<void> close() async => closes++;
}

void main() {
  test('the factory write sends the key and the source, and says what happened', () async {
    final settings = _FakeSettings();
    final port = await _serve(settings);
    _recordTrace();

    final written = await writeColumnFactory(() => openThisPc(port: port), _key, FactorySource.valuesInForce);
    expect(written.ok, isTrue);
    expect(written.text, 'Factory defaults written to column e6614c311b4a6f2a (3 settings, from the values in force).');
    final fromStandard = await writeColumnFactory(() => openThisPc(port: port), _key, FactorySource.currentStandard);
    expect(fromStandard.text, contains("from the column's standard"));
    expect(settings.requests.map((r) => (r.key == _key, r.source)), [
      (true, ColumnFactorySource.COLUMN_FACTORY_SOURCE_VALUES_IN_FORCE),
      (true, ColumnFactorySource.COLUMN_FACTORY_SOURCE_STANDARD),
    ]);
    expect(RpcTrace.calls, isEmpty, reason: 'the key never reaches the RPC console');
    expect(_traceHolds(_key), isFalse);
  });

  // R17: the check above can fail. The same write over a traced channel (the one every other
  // call of the app uses) lands in the RPC console with the key in its request.
  test('the trace check can fail: over a traced channel the key would show', () async {
    final port = await _serve(_FakeSettings());
    _recordTrace();

    final traced = await writeColumnFactory(() async {
      final channel = GrpcChannelProvider.openChannel('127.0.0.1', port);
      return ServerLink(channel, () => channel.shutdown());
    }, _key, FactorySource.valuesInForce);
    expect(traced.ok, isTrue);
    expect(RpcTrace.calls.map((c) => c.path), ['/settings.Settings/WriteColumnFactory']);
    expect(_traceHolds(_key), isTrue, reason: 'a traced channel records the request, key included');
  });

  test('a refused key, an older server and no server are one line each, without the key', () async {
    final refused = await writeColumnFactory(
        () async => openThisPc(port: await _serve(_FakeSettings())), 'wrong-key', FactorySource.valuesInForce);
    expect((refused.ok, refused.text), (false, 'The server refused the factory key (config.json, factory_key).'));
    final old = await writeColumnFactory(
        () async => openThisPc(port: await _serve(_FakeSettings(oldServer: true))), _key, FactorySource.valuesInForce);
    expect(old.text, 'This server has no column profile (an older server version).');
    final closed = await _closedPort();
    final none = await writeColumnFactory(() => openThisPc(port: closed), _key, FactorySource.valuesInForce);
    expect(none.ok, isFalse);
    for (final answer in [refused.text, old.text, none.text]) {
      expect(answer, isNot(contains(_key)));
      expect(answer, isNot(contains('wrong-key')));
    }
    expect((await writeColumnFactory(() => openThisPc(port: closed), '', FactorySource.valuesInForce)).text,
        'No factory key in config.json (factory_key): the factory actions are off.');
  });

  test("the server's own refusal is shown, and a server that echoes the key never shows it", () async {
    final noStandard = await writeColumnFactory(
        () async => openThisPc(
            port: await _serve(_FakeSettings(
                refusal: (_) => GrpcError.failedPrecondition('the column has no standard to copy')))),
        _key,
        FactorySource.currentStandard);
    expect((noStandard.ok, noStandard.text),
        (false, 'The factory defaults were not written: the column has no standard to copy'));

    final echo = await writeColumnFactory(
        () async => openThisPc(
            port: await _serve(_FakeSettings(refusal: (r) => GrpcError.unavailable('bad write for ${r.key}')))),
        _key,
        FactorySource.valuesInForce);
    expect(echo.ok, isFalse);
    expect(echo.text, isNot(contains(_key)));
    expect(echo.text, startsWith('The factory defaults were not written: bad write for '));
  });

  test("the kiosk's tunnel: 127.0.0.1 only, forwarded to the kiosk's 127.0.0.1:50051, closed after", () async {
    final settings = _FakeSettings();
    final ssh = _FakeSsh(await _serve(settings));
    _recordTrace();
    late int tunnelPort;
    bool? reachableFromLan;

    final written = await writeColumnFactory(() async {
      final link = await openTunnel(ssh.forward, ssh.close);
      tunnelPort = link.channel.port;
      expect(link.channel.host, '127.0.0.1');
      // The local end listens on the loopback only: this PC's own network address is refused.
      final lan = [
        for (final nic in await NetworkInterface.list(type: InternetAddressType.IPv4))
          ...nic.addresses.where((a) => !a.isLoopback)
      ];
      if (lan.isNotEmpty) reachableFromLan = await _accepts(lan.first, tunnelPort);
      return link;
    }, _key, FactorySource.valuesInForce);

    expect(written.ok, isTrue);
    expect(settings.requests.single.key, _key);
    expect(ssh.forwards, isNotEmpty);
    expect(ssh.forwards.toSet(), {('127.0.0.1', kServerPort)});
    expect(reachableFromLan, anyOf(isNull, isFalse));
    expect(ssh.closes, 1, reason: 'the SSH connection closes when the action ends');
    expect(await _accepts(InternetAddress.loopbackIPv4, tunnelPort), isFalse,
        reason: 'the local port closes when the action ends');
    expect(_traceHolds(_key), isFalse);
  });

  test("the kiosk's tunnel closes on an error too", () async {
    // The kiosk's server does not listen: the forward is refused at once, the SSH connection
    // closes, and the operator gets one line (not a 30 s wait).
    final refusedSsh = _FakeSsh(await _closedPort(), refuse: true);
    final unreachable = await writeColumnFactory(
        () => openTunnel(refusedSsh.forward, refusedSsh.close), _key, FactorySource.valuesInForce);
    expect((unreachable.ok, unreachable.text), (false, 'The server could not be reached: SocketException'));
    expect(refusedSsh.forwards, [('127.0.0.1', kServerPort)]);
    expect(refusedSsh.closes, 1);

    // The server refuses the call: the tunnel still closes when the action ends.
    final ssh = _FakeSsh(await _serve(_FakeSettings()));
    late int tunnelPort;
    final refused = await writeColumnFactory(() async {
      final link = await openTunnel(ssh.forward, ssh.close);
      tunnelPort = link.channel.port;
      return link;
    }, 'wrong-key', FactorySource.valuesInForce);
    expect(refused.text, 'The server refused the factory key (config.json, factory_key).');
    expect(ssh.closes, 1);
    expect(await _accepts(InternetAddress.loopbackIPv4, tunnelPort), isFalse);
  });

  testWidgets('the updater card is off without a factory key and on with one for this PC', (tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final saved = AppConfig.factoryKey;
    addTearDown(() => AppConfig.factoryKey = saved);

    AppConfig.factoryKey = '';
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: UpdaterPage())));
    expect(find.text('No factory key in config.json (factory_key): the factory actions are off.'), findsOneWidget);
    OutlinedButton button(String key) => tester.widget<OutlinedButton>(
        find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(OutlinedButton)));
    expect(button('factory-write').onPressed, isNull);

    AppConfig.factoryKey = _key;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: UpdaterPage())));
    expect(button('factory-write').onPressed, isNull, reason: 'the kiosk above is not connected');
    await tester.tap(find.byKey(const ValueKey('factory-target')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This PC').last);
    await tester.pumpAndSettle();
    expect(button('factory-write').onPressed, isNotNull);
    expect(button('factory-from-standard').onPressed, isNotNull);
    expect(find.textContaining(_key), findsNothing, reason: 'the key is never shown');
  });

  // R17 through the app's real code path: the page's button, its confirmation and its
  // This-PC link (pointed at the fake server instead of 127.0.0.1:50051), with the RPC
  // console recording and the column-session header on as main() sets it.
  testWidgets('the page writes the factory defaults on this PC; the key shows nowhere', (tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final saved = AppConfig.factoryKey;
    addTearDown(() => AppConfig.factoryKey = saved);
    final session = GrpcChannelProvider.useColumnSession;
    addTearDown(() => GrpcChannelProvider.useColumnSession = session);

    await tester.runAsync(() async {
      final settings = _FakeSettings();
      final server = Server.create(services: [settings]);
      await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => tester.runAsync(() => server.shutdown()));
      final port = server.port!;
      AppConfig.factoryKey = _key;
      GrpcChannelProvider.useColumnSession = true;
      RpcTrace.enabled = true;
      RpcTrace.clear();
      addTearDown(() {
        RpcTrace.enabled = false;
        RpcTrace.clear();
      });

      Future<void> settle() async {
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: UpdaterPage(openThisPcServer: () => openThisPc(port: port)))));
      await settle();
      await tester.tap(find.byKey(const ValueKey('factory-target')));
      await settle();
      await tester.tap(find.text('This PC').last);
      await settle();
      await tester.tap(find.byKey(const ValueKey('factory-write')));
      await settle();
      expect(find.text('Write factory defaults?'), findsOneWidget);
      expect(settings.requests, isEmpty, reason: 'nothing before the confirmation');
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Write')));
      await settle();

      expect(settings.requests.map((r) => (r.key == _key, r.source)),
          [(true, ColumnFactorySource.COLUMN_FACTORY_SOURCE_VALUES_IN_FORCE)]);
      expect(settings.sessionHeaders, ['1'], reason: 'the untraced channel still sends the session header');
      const answer = 'Factory defaults written to column e6614c311b4a6f2a (3 settings, from the values in force).';
      expect(find.text(answer), findsOneWidget);
      expect(find.text('Factory defaults (this PC): $answer'), findsOneWidget, reason: 'the log line');
      expect(find.textContaining(_key), findsNothing, reason: 'not on the page, not in the log');
      expect(RpcTrace.calls, isEmpty);
      expect(_traceHolds(_key), isFalse, reason: 'not in the RPC console');
    });
  });
}
