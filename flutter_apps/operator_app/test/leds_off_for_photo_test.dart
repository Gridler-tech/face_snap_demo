// The Lighting page's "Lights off for the photo" switch (kiosk.leds_off_for_photo):
// it shows the loaded setting, pushes a change to the Settings service and the
// shared settings snapshot, and springs back when the server refuses (an older
// server answers UNIMPLEMENTED). Talks to an in-process fake server over a real
// loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/lighting_page.dart';
import 'package:operator_app/services/settings_state.dart';

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({this.refuse = false});
  final bool refuse;
  final List<bool> calls = [];

  @override
  Future<LedsOffForPhotoResponse> setLedsOffForPhoto(
      ServiceCall call, LedsOffForPhotoRequest request) async {
    calls.add(request.value);
    if (refuse) throw GrpcError.unimplemented('SetLedsOffForPhoto');
    return LedsOffForPhotoResponse(message: request.value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// No relay module here: every Lights call is unimplemented (the Backlights
/// card then just shows its older-server note).
class _NoLights extends LightsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

Finder _switch() => find.descendant(
    of: find
        .ancestor(
            of: find.textContaining('Lights off for the photo'),
            matching: find.byType(Row))
        .first,
    matching: find.byType(Switch));

Future<_FakeSettings> _pumpPage(WidgetTester tester,
    {required bool ledsOffForPhoto, bool refuse = false}) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = _FakeSettings(refuse: refuse);
  final server = Server.create(services: [_NoLights(), settings]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));

  SettingsState.current = LoadSettingsResponse(ledsOffForPhoto: ledsOffForPhoto);
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
  await _settle(tester);
  return settings;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Future<void> _tap(WidgetTester tester) async {
  await tester.ensureVisible(_switch());
  await tester.pump();
  await tester.tap(_switch());
  await _settle(tester);
}

void main() {
  testWidgets('the switch shows the loaded setting', (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, ledsOffForPhoto: true);
      expect(tester.widget<Switch>(_switch()).value, isTrue);
    });
  });

  testWidgets('switching it on is pushed to the server and the snapshot',
      (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, ledsOffForPhoto: false);
      expect(tester.widget<Switch>(_switch()).value, isFalse);

      await _tap(tester);

      expect(settings.calls, [true]);
      expect(tester.widget<Switch>(_switch()).value, isTrue);
      expect(SettingsState.current!.ledsOffForPhoto, isTrue,
          reason: 'the other pages read the snapshot');
    });
  });

  testWidgets('a refused change springs the switch back and says why',
      (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, ledsOffForPhoto: false, refuse: true);

      await _tap(tester);

      expect(settings.calls, [true]);
      expect(tester.widget<Switch>(_switch()).value, isFalse,
          reason: 'the server does not have the mode');
      expect(SettingsState.current!.ledsOffForPhoto, isFalse);
      expect(find.textContaining('Server call failed'), findsOneWidget);
    });
  });
}
