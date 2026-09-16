// Regression sweep: boot the shell with no server connected and switch through
// every navigation destination — the "crashed while changing pages" scenario.
// Any build/layout/null exception in any page fails the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/home_shell.dart';
import 'package:operator_app/services/settings_state.dart';

void main() {
  testWidgets('HomeShell survives switching through all pages with no server',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SettingsState.current = null;

    // Real async so the pages' initState gRPC calls (against the default
    // unreachable channel) run and fail through their own catch blocks
    // instead of tripping the fake-async pending-timer check.
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'boot: building all pages in the IndexedStack threw');

      const labels = [
        'Capture',
        'Face recognition',
        'Photo',
        'Lighting',
        'Camera',
        'Calibration',
        'Monitoring',
        'About',
        'Kiosk', // and back to the start
      ];
      for (final label in labels) {
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull,
            reason: 'switching to "$label" threw');
      }

      // Give in-flight gRPC failures a moment to land in their catch blocks.
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
