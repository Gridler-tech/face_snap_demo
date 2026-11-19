// The Lighting page's glare-free light (spec 2026-10-09 section 5): the 3-way selector
// (Normal light / Glare-free for glasses / Glare-free for everyone) with the explanation of
// the chosen one, pushed with SetGlareFreeLight and into the shared settings snapshot; an
// older server's snapshot (no glare_free_light) shows its glasses switch, and its
// SetGlassesLightsOff still takes "off" and "glasses"; the Kelvin field pushes
// SetGlareFreeWhiteBalance. Talks to an in-process fake server over a real loopback
// connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/lighting_page.dart';
import 'package:operator_app/services/settings_state.dart';

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({this.oldServer = false});
  final bool oldServer;
  final List<GlareFreeLight> glareFree = [];
  final List<bool> glasses = [];
  final List<int> whiteBalance = [];

  @override
  Future<GlareFreeLightResponse> setGlareFreeLight(
      ServiceCall call, GlareFreeLightRequest request) async {
    if (oldServer) throw GrpcError.unimplemented('SetGlareFreeLight');
    glareFree.add(request.value);
    return GlareFreeLightResponse(message: request.value);
  }

  @override
  Future<GlassesLightsOffResponse> setGlassesLightsOff(
      ServiceCall call, GlassesLightsOffRequest request) async {
    glasses.add(request.value);
    return GlassesLightsOffResponse(message: request.value);
  }

  @override
  Future<GlareFreeWhiteBalanceResponse> setGlareFreeWhiteBalance(
      ServiceCall call, GlareFreeWhiteBalanceRequest request) async {
    if (oldServer) throw GrpcError.unimplemented('SetGlareFreeWhiteBalance');
    whiteBalance.add(request.value);
    return GlareFreeWhiteBalanceResponse(message: request.value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// No relay module here: every Lights call is unimplemented.
class _NoLights extends LightsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

Future<_FakeSettings> _pumpPage(WidgetTester tester, LoadSettingsResponse snapshot,
    {bool oldServer = false}) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = _FakeSettings(oldServer: oldServer);
  final server = Server.create(services: [_NoLights(), settings]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));

  SettingsState.current = snapshot;
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

Set<GlareFreeLight> _selected(WidgetTester tester) => tester
    .widget<SegmentedButton<GlareFreeLight>>(find.byType(SegmentedButton<GlareFreeLight>))
    .selected;

Future<void> _choose(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await _settle(tester);
}

void main() {
  testWidgets('the selector shows the loaded setting and its explanation', (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester,
          LoadSettingsResponse(glareFreeLight: GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE, glassesLightsOff: true));
      expect(_selected(tester), {GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE});
      expect(find.textContaining('one natural catchlight'), findsOneWidget);
    });
  });

  testWidgets("an older server's glasses switch shows as glare-free for glasses", (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, LoadSettingsResponse(glassesLightsOff: true));
      expect(_selected(tester), {GlareFreeLight.GLARE_FREE_LIGHT_GLASSES});
    });
  });

  testWidgets('choosing everyone is pushed and the snapshot follows', (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, LoadSettingsResponse());
      expect(_selected(tester), {GlareFreeLight.GLARE_FREE_LIGHT_OFF});

      await _choose(tester, 'Glare-free for everyone');

      expect(settings.glareFree, [GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE]);
      expect(_selected(tester), {GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE});
      expect(SettingsState.current!.glareFreeLight, GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE);
      expect(SettingsState.current!.glassesLightsOff, isTrue,
          reason: 'the old switch follows, as on the server');
    });
  });

  testWidgets('an older server takes glasses through its glasses switch', (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, LoadSettingsResponse(), oldServer: true);

      await _choose(tester, 'Glare-free for glasses');

      expect(settings.glasses, [true]);
      expect(_selected(tester), {GlareFreeLight.GLARE_FREE_LIGHT_GLASSES});
      expect(find.textContaining('Server call failed'), findsNothing);
    });
  });

  testWidgets('an older server refuses everyone and the selector springs back', (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, LoadSettingsResponse(), oldServer: true);

      await _choose(tester, 'Glare-free for everyone');

      expect(settings.glasses, isEmpty);
      expect(_selected(tester), {GlareFreeLight.GLARE_FREE_LIGHT_OFF});
      expect(find.textContaining('Server call failed'), findsOneWidget);
    });
  });

  testWidgets('the Kelvin field pushes the white balance', (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, LoadSettingsResponse(glareFreeWhiteBalance: 5300));
      final field = find.byKey(const ValueKey('glare-free-white-balance'));
      expect(tester.widget<TextField>(field).controller!.text, '5300');

      await tester.ensureVisible(field);
      await tester.enterText(field, '4800');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);

      expect(settings.whiteBalance, [4800]);
      expect(SettingsState.current!.glareFreeWhiteBalance, 4800);
    });
  });
}
