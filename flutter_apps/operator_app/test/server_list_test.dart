// The Kiosk page's server list, driven with fakes: rows from discovery, the
// current host marked Connected, other answering servers clickable, a clean
// board shown but inert, and a row click going through the connect routine
// then the page callback. No network, no timer.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/app_config.dart';
import 'package:operator_app/services/discovery.dart';
import 'package:operator_app/services/server_probe.dart';
import 'package:operator_app/ui/server_list.dart';

DiscoveredKiosk kiosk(String name, String ip) =>
    DiscoveredKiosk(hostName: name, ip: ip, port: 50051);

const _up = ServerSnapshot(
    answering: true, cameras: 6, version: '2.0.11', running: true, model: 'ODROID-N2Plus');
const _down = ServerSnapshot(answering: false, running: false, error: 'timed out');

Widget host(ServerList list) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: list)));

void main() {
  final savedHost = AppConfig.host;
  final savedPort = AppConfig.port;
  setUp(() {
    AppConfig.host = 'facesnap-a.local';
    AppConfig.port = 50051;
  });
  tearDown(() {
    AppConfig.host = savedHost;
    AppConfig.port = savedPort;
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(); // post-frame: scan starts
    await tester.pump(); // discovery resolved, rows shown
    await tester.pump(); // probes resolved
  }

  testWidgets('lists every discovered board by name and marks the current one',
      (tester) async {
    await tester.pumpWidget(host(ServerList(
      onConnected: () async {},
      onAddAddress: () async {},
      refreshEvery: null,
      discover: () async => [
        kiosk('facesnap-a.local', '192.168.3.167'),
        kiosk('facesnap-b.local', '192.168.3.181'),
      ],
      probe: (h, p, {bool sshDetails = true}) async => _up,
      connect: (h, p) async {},
    )));
    await settle(tester);
    expect(find.text('facesnap-a'), findsOneWidget);
    expect(find.text('facesnap-b'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Answering'), findsOneWidget);
    expect(find.text('2 servers found'), findsOneWidget);
    expect(find.textContaining('2.0.11 · 6 cameras · ODROID-N2Plus'),
        findsNWidgets(2));
  });

  testWidgets('a not-answering server says why and is not clickable',
      (tester) async {
    AppConfig.host = 'localhost'; // no saved-server row in this one
    await tester.pumpWidget(host(ServerList(
      onConnected: () async {},
      onAddAddress: () async {},
      refreshEvery: null,
      discover: () async => [kiosk('facesnap-b.local', '192.168.3.181')],
      probe: (h, p, {bool sshDetails = true}) async => _down,
      connect: (h, p) async => fail('must not connect to a dead server'),
    )));
    await settle(tester);
    expect(find.text('Not answering'), findsOneWidget);
    expect(find.textContaining('server stopped'), findsOneWidget);
    await tester.tap(find.text('facesnap-b'));
    await tester.pump();
  });

  testWidgets('a clean board is listed but inert', (tester) async {
    AppConfig.host = 'localhost'; // so the probe-never-called check is real
    await tester.pumpWidget(host(ServerList(
      onConnected: () async {},
      onAddAddress: () async {},
      refreshEvery: null,
      discover: () async => [
        DiscoveredKiosk(hostName: 'odroid', ip: '10.0.0.9', kind: BoardKind.clean),
      ],
      probe: (h, p, {bool sshDetails = true}) async =>
          fail('a clean board is never probed'),
      connect: (h, p) async => fail('a clean board cannot be connected to'),
    )));
    await settle(tester);
    expect(find.text('odroid'), findsOneWidget);
    expect(find.text('No FaceSnap server'), findsOneWidget);
    expect(find.textContaining('Updater'), findsOneWidget);
    await tester.tap(find.text('odroid'));
    await tester.pump();
  });

  testWidgets('clicking an answering row connects by NAME, then refreshes the page',
      (tester) async {
    String? connectedTo;
    var refreshed = false;
    await tester.pumpWidget(host(ServerList(
      onConnected: () async => refreshed = true,
      onAddAddress: () async {},
      refreshEvery: null,
      discover: () async => [
        kiosk('facesnap-a.local', '192.168.3.167'),
        kiosk('facesnap-b.local', '192.168.3.181'),
      ],
      probe: (h, p, {bool sshDetails = true}) async => _up,
      connect: (h, p) async {
        connectedTo = '$h:$p';
        AppConfig.host = h; // what the real connectTo persists
      },
    )));
    await settle(tester);
    await tester.tap(find.text('facesnap-b'));
    await tester.pump();
    await tester.pump();
    // By .local name — the address moves with DHCP, the name does not.
    expect(connectedTo, 'facesnap-b.local:50051');
    expect(refreshed, isTrue);
    // The clicked row is now the connected one.
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('a connect failure is reported, not swallowed', (tester) async {
    await tester.pumpWidget(host(ServerList(
      onConnected: () async => fail('must not refresh after a failed connect'),
      onAddAddress: () async {},
      refreshEvery: null,
      discover: () async => [kiosk('facesnap-b.local', '192.168.3.181')],
      probe: (h, p, {bool sshDetails = true}) async => _up,
      connect: (h, p) async => throw Exception('refused'),
    )));
    await settle(tester);
    await tester.tap(find.text('facesnap-b'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Could not connect to facesnap-b.local:50051'),
        findsOneWidget);
  });

  testWidgets('the saved server is listed even when discovery misses it',
      (tester) async {
    AppConfig.host = '192.168.3.180'; // an older config saved the IP
    await tester.pumpWidget(host(ServerList(
      onConnected: () async {},
      onAddAddress: () async {},
      refreshEvery: null,
      discover: () async => [kiosk('facesnap-b.local', '192.168.3.181')],
      probe: (h, p, {bool sshDetails = true}) async =>
          h == '192.168.3.180' ? _down : _up,
      connect: (h, p) async {},
    )));
    await settle(tester);
    expect(find.text('192.168.3.180  (saved)'), findsOneWidget);
    expect(find.text('Not answering'), findsOneWidget);
    expect(find.text('2 servers found'), findsOneWidget);
  });

  testWidgets('nothing found: explains and offers the manual path',
      (tester) async {
    var addAsked = false;
    // Before pumping: pumpWidget's own async gap already lets the scan read
    // the saved host, and a remembered server would get a row.
    AppConfig.host = 'localhost';
    await tester.pumpWidget(host(ServerList(
      onConnected: () async {},
      onAddAddress: () async => addAsked = true,
      refreshEvery: null,
      discover: () async => [],
      probe: (h, p, {bool sshDetails = true}) async => _up,
      connect: (h, p) async {},
    )));
    await settle(tester);
    expect(find.text('No servers found yet'), findsOneWidget);
    expect(find.textContaining('add an address'), findsOneWidget);
    await tester.tap(find.text('Add an address…'));
    await tester.pump();
    expect(addAsked, isTrue);
  });

  testWidgets('"Search again" works while a scan is still running and supersedes it',
      (tester) async {
    // A kiosk renamed or unplugged mid-probe can leave the first scan hanging
    // on "Checking…" for seconds; the operator must be able to search again
    // right then, and the fresh scan's result must win.
    AppConfig.host = 'facesnap-b.local';
    var calls = 0;
    final stuck = Completer<List<DiscoveredKiosk>>(); // never completes
    await tester.pumpWidget(host(ServerList(
      onConnected: () async {},
      onAddAddress: () async {},
      refreshEvery: null,
      discover: () => ++calls == 1
          ? stuck.future
          : Future.value([kiosk('facesnap-b.local', '192.168.3.181')]),
      probe: (h, p, {bool sshDetails = true}) async => _up,
      connect: (h, p) async {},
    )));
    await tester.pump(); // first scan started, stuck in discovery
    expect(find.text('Searching the network…'), findsOneWidget);

    await tester.tap(find.text('Search again'));
    await settle(tester);
    expect(calls, 2);
    expect(find.text('facesnap-b'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('1 server found'), findsOneWidget);
    expect(find.text('Searching the network…'), findsNothing);
  });
}
