// The Lighting page's Backlights card (the two LED backlights on the USB
// relay module, switched by hand for testing) and the local-server stop
// switching them off first. Talks to an in-process fake server over a real
// loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, Service, ServiceCall;
import 'package:operator_app/pages/lighting_page.dart';
import 'package:operator_app/services/server_manager.dart';
import 'package:operator_app/services/settings_state.dart';

/// A relay module behind the Lights service: [connected] = attached.
class _FakeLights extends LightsServiceBase {
  _FakeLights({this.connected = true});
  bool connected;
  bool bottom = false, top = false;
  final List<String> calls = [];

  BacklightStatus get _status => BacklightStatus(
      connected: connected,
      backlightBottom: connected && bottom,
      backlightTop: connected && top);

  @override
  Future<BacklightStatus> getBacklights(ServiceCall call, Empty request) async =>
      _status;

  @override
  Future<BacklightStatus> setBacklight(
      ServiceCall call, BacklightRequest request) async {
    calls.add('${request.backlight.name} ${request.on ? 'on' : 'off'}');
    if (!connected) {
      throw GrpcError.failedPrecondition('USB relay module not connected');
    }
    if (request.backlight == Backlight.BACKLIGHT_BOTTOM) bottom = request.on;
    if (request.backlight == Backlight.BACKLIGHT_TOP) top = request.on;
    return _status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// A server from before the backlights: every Lights call is unimplemented.
class _OldLights extends LightsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

Finder _switch(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
    matching: find.byType(Switch));

const _bottom = 'Bottom backlight (relay 1)';
const _top = 'Top backlight (relay 2)';

Future<Server> _serve(Service lights) async {
  final server = Server.create(services: [lights]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  return server;
}

Future<void> _pumpPage(WidgetTester tester, Service lights) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final server = await _serve(lights);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  SettingsState.current = LoadSettingsResponse();
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  testWidgets('each backlight switches on and off by hand', (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights();
      await _pumpPage(tester, lights);
      expect(find.text('USB relay module connected'), findsOneWidget);
      expect(tester.widget<Switch>(_switch(_bottom)).value, isFalse);

      await _tap(tester, _switch(_top));
      expect(lights.calls, ['BACKLIGHT_TOP on']);
      expect(tester.widget<Switch>(_switch(_top)).value, isTrue);
      expect(tester.widget<Switch>(_switch(_bottom)).value, isFalse,
          reason: 'the two backlights are switched separately');

      await _tap(tester, _switch(_bottom));
      await _tap(tester, _switch(_top));
      expect(lights.calls,
          ['BACKLIGHT_TOP on', 'BACKLIGHT_BOTTOM on', 'BACKLIGHT_TOP off']);
      expect(tester.widget<Switch>(_switch(_bottom)).value, isTrue);
      expect(tester.widget<Switch>(_switch(_top)).value, isFalse);
    });
  });

  testWidgets('without the relay module the switches are greyed out',
      (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, _FakeLights(connected: false));
      expect(tester.widget<Switch>(_switch(_bottom)).onChanged, isNull);
      expect(tester.widget<Switch>(_switch(_top)).onChanged, isNull);
      expect(find.textContaining('USB relay module not connected'), findsOneWidget);
    });
  });

  testWidgets('a module unplugged meanwhile: the switch springs back and says why',
      (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights();
      await _pumpPage(tester, lights);
      lights.connected = false; // unplugged after the page read it
      await _tap(tester, _switch(_bottom));
      expect(tester.widget<Switch>(_switch(_bottom)).value, isFalse);
      expect(find.textContaining('Could not switch the backlight'), findsOneWidget);
      // The card read the module again: the switches are greyed out now.
      expect(tester.widget<Switch>(_switch(_bottom)).onChanged, isNull);
      expect(tester.widget<Switch>(_switch(_top)).onChanged, isNull);
    });
  });

  testWidgets('an older server: the card says to update it', (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, _OldLights());
      expect(tester.widget<Switch>(_switch(_bottom)).onChanged, isNull);
      expect(find.textContaining('too old for that call'), findsOneWidget);
    });
  });

  test('stopping the local server switches both backlights off first', () async {
    final lights = _FakeLights()..bottom = true..top = true;
    final server = await _serve(lights);
    addTearDown(server.shutdown);
    await ServerManager.backlightsOff(server.port!);
    expect(lights.calls, ['BACKLIGHT_BOTTOM off', 'BACKLIGHT_TOP off']);
    expect(lights.bottom || lights.top, isFalse);
  });

  test('switching off before a stop never fails the stop', () async {
    final server = await _serve(_OldLights());
    addTearDown(server.shutdown);
    await ServerManager.backlightsOff(server.port!); // unimplemented: ignored
    final free = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = free.port;
    await free.close();
    await ServerManager.backlightsOff(port); // nothing listening: ignored
  });
}
