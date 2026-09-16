// Regression: the background-color field must push its value on FOCUS LOSS,
// not only on Enter. Before the fix, typing a color and clicking elsewhere
// silently discarded it (the server kept the old value and the field snapped
// back on the next settings load).
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/photo_page.dart';
import 'package:operator_app/services/settings_state.dart';

LoadSettingsResponse _settings() => LoadSettingsResponse(
      crop: true,
      photoFormat: 'icao_35x45',
      cropWidth: 700,
      cropHeight: 900,
      backgroundMethod: 'mediapipe', // != none, so the color field is shown
      backgroundColor: 'FFFFFF',
      jpegQuality: 95,
    );

void main() {
  testWidgets('background color is pushed on focus loss (no Enter needed)',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SettingsState.current = _settings();
    // Unreachable server: the push itself will fail, but the attempt is
    // observable as the page's "Server call failed" message — which is the
    // proof that focus loss triggered the RPC.
    await GrpcChannelProvider.setAddress('127.0.0.1', 1);

    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PhotoPage())));
      await tester.pump();

      final colorField = find.widgetWithText(TextField, 'FFFFFF').first;

      // Type a new color WITHOUT pressing Enter…
      await tester.enterText(colorField, 'DDDDDD');
      await tester.pump();

      // …then move focus away (click elsewhere).
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Let the failed gRPC attempt land in the page's catch block.
      await Future<void>.delayed(const Duration(seconds: 3));
      await tester.pump();

      expect(find.textContaining('Server call failed'), findsOneWidget,
          reason: 'focus loss must attempt SetBackgroundColor');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('invalid hex is rejected with a message, not sent',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SettingsState.current = _settings();

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PhotoPage())));
    await tester.pump();

    await tester.enterText(
        find.widgetWithText(TextField, 'FFFFFF').first, 'GGG');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(find.textContaining('6 hex digits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
