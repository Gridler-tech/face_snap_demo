// Layout smoke tests for the server picker + Kiosk server row. These catch the
// build/layout exceptions that read as a "crash" at runtime (e.g. a Flexible in
// a mainAxisSize.min Column) — the framework records them via takeException().
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/lighting_page.dart';
import 'package:operator_app/pages/photo_page.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/ui/server_picker.dart';

void main() {
  // Regression: the app now boots straight into the shell (IndexedStack builds
  // every page) before a server is connected, so SettingsState.current is null.
  // These pages used to read `SettingsState.current!` in initState and crashed
  // at startup; they must now render a placeholder instead.
  testWidgets('LightingPage builds with no server connected', (tester) async {
    SettingsState.current = null;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
    expect(tester.takeException(), isNull);
    expect(find.byType(LightingPage), findsOneWidget);
  });

  testWidgets('PhotoPage builds with no server connected', (tester) async {
    SettingsState.current = null;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PhotoPage())));
    expect(tester.takeException(), isNull);
    expect(find.byType(PhotoPage), findsOneWidget);
  });

  testWidgets('ServerPicker dialog builds without a layout exception',
      (tester) async {
    // A generous surface so the dialog is never squeezed by the test viewport.
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showServerPicker(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump(); // build the dialog (initState kicks off discovery)

    expect(find.text('Connect to a FaceSnap kiosk'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Let the (real) discovery future settle so the async gap doesn't leak
    // into the next test; it just times out to an empty list here.
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
