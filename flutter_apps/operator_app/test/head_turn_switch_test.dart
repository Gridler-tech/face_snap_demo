// The Photo page's head-turn switch (kiosk.liveness_head_turn_check, spec
// 2026-10-08 section 3.2): it shows the loaded setting, is greyed out without
// the live person check's master switch, and a change is pushed in the ONE
// SetLivenessChecks call with the other switches and to the settings snapshot.
// Against an in-process fake Settings server.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, ServiceCall;
import 'package:operator_app/pages/photo_page.dart';
import 'package:operator_app/services/settings_state.dart';

import 'fake_server.dart';

class _FakeSettings extends SettingsServiceBase {
  final List<LivenessChecksRequest> calls = [];

  @override
  Future<LivenessChecksResponse> setLivenessChecks(
      ServiceCall call, LivenessChecksRequest request) async {
    calls.add(request);
    return LivenessChecksResponse(
        livenessCheck: request.livenessCheck,
        headTurnCheck: request.headTurnCheck);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

Finder _switch() => find.descendant(
    of: find
        .ancestor(of: find.textContaining('Head turn:'), matching: find.byType(Row))
        .last,
    matching: find.byType(Switch));

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Future<_FakeSettings> _pumpPage(WidgetTester tester,
    {required bool master, required bool headTurn}) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = _FakeSettings();
  final server = await serveFakes([settings]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  SettingsState.current = LoadSettingsResponse(
      photoFormat: 'icao_35x45',
      backgroundMethod: 'none',
      jpegQuality: 95,
      livenessCheck: master,
      livenessHeadTurnCheck: headTurn);
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PhotoPage())));
  await _settle(tester);
  return settings;
}

void main() {
  testWidgets('the switch shows the loaded setting', (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, master: true, headTurn: true);
      expect(tester.widget<Switch>(_switch()).value, isTrue);
    });
  });

  testWidgets('switching it on is ONE SetLivenessChecks with the other switches',
      (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, master: true, headTurn: false);
      await tester.ensureVisible(_switch());
      await tester.pump();
      await tester.tap(_switch());
      await _settle(tester);

      expect(settings.calls, hasLength(1));
      final sent = settings.calls.single;
      expect((sent.livenessCheck, sent.headTurnCheck), (true, true));
      expect(SettingsState.current!.livenessHeadTurnCheck, isTrue,
          reason: 'the other pages read the snapshot');
    });
  });

  testWidgets('switching it off sends a PRESENT false, not an unset field',
      (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, master: true, headTurn: true);
      await tester.ensureVisible(_switch());
      await tester.pump();
      await tester.tap(_switch());
      await _settle(tester);

      expect(settings.calls, hasLength(1));
      final sent = settings.calls.single;
      // head_turn_check is proto3 optional: an UNSET field keeps the stored
      // value on the server, so switching off must arrive as a present false.
      expect(sent.hasHeadTurnCheck(), isTrue,
          reason: 'unset would keep a stored true on the server');
      expect(sent.headTurnCheck, isFalse);
      expect(SettingsState.current!.livenessHeadTurnCheck, isFalse);
    });
  });

  testWidgets('without the master switch it cannot be changed', (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, master: false, headTurn: false);
      expect(tester.widget<Switch>(_switch()).onChanged, isNull);
    });
  });
}
