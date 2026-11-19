// Regression sweep: boot the shell with no server connected and switch through
// every navigation destination — the "crashed while changing pages" scenario.
// Any build/layout/null exception in any page fails the test.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/home_shell.dart';
import 'package:operator_app/pages/column_page.dart';
import 'package:operator_app/pages/kiosk_page.dart';
import 'package:operator_app/pages/monitoring_page.dart';
import 'package:operator_app/services/column_state.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/ui/page_nav.dart';

int _railIndex(WidgetTester tester) =>
    tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex!;

/// Whether the page of [type] is the one shown: onstage (IndexedStack puts the others
/// offstage) and one of its texts takes a tap.
void _expectShown(WidgetTester tester, Type type) {
  expect(find.byType(type), findsOneWidget, reason: '$type onstage');
  expect(find.descendant(of: find.byType(type), matching: find.byType(RichText)).hitTestable(),
      findsWidgets, reason: '$type takes a tap');
}

/// The pages' state object of [type], offstage or not.
State _stateOf(WidgetTester tester, Type type) =>
    tester.state(find.byType(type, skipOffstage: false));

void main() {
  // The pages' initState calls go over the shared channel. Its default is
  // localhost:50051, where a real FaceSnap server may be running (LoadSettings can
  // open a camera): every test points it at a loopback port that was just closed,
  // so each call fails at once. Not put back afterwards on purpose: a late call of
  // a disposed page must not reach 50051 either (each test file is its own isolate).
  setUp(() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    await GrpcChannelProvider.setAddress('127.0.0.1', port);
  });

  testWidgets('HomeShell survives switching through all pages with no server',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SettingsState.current = null;

    // Real async so the pages' initState gRPC calls (against the closed port
    // set up above) run and fail through their own catch blocks
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

  // The column profile (spec 2026-10-10 section 5.5): the Column page is on the rail only
  // while the server has the profile (ColumnState.available), after Calibration; PageNav
  // opens it (the ● marks' link); when it goes, the shell falls back to the Kiosk page.
  testWidgets('the Column page comes and goes with the server and PageNav opens it',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SettingsState.current = null;
    ColumnState.reset();
    ColumnState.available = true;

    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      expect(find.text('Column'), findsOneWidget);
      final monitoring = _stateOf(tester, MonitoringPage);

      PageNav.open('Column');
      await tester.pump();
      expect(_railIndex(tester), 7, reason: 'right after Calibration');
      _expectShown(tester, ColumnPage);
      expect(find.byType(KioskPage), findsNothing);

      ColumnState.reset(); // an older server
      await tester.pump();
      expect(find.text('Column'), findsNothing);
      expect(_railIndex(tester), 0);
      _expectShown(tester, KioskPage);
      expect(find.byType(ColumnPage), findsNothing);
      expect(identical(_stateOf(tester, MonitoringPage), monitoring), isTrue,
          reason: 'a page after the Column page keeps its state when it goes');

      ColumnState.available = true; // the server has it again
      ColumnState.revision.value++;
      await tester.pump();
      expect(find.text('Column'), findsOneWidget);
      expect(identical(_stateOf(tester, MonitoringPage), monitoring), isTrue,
          reason: 'and when it comes back');

      // Give in-flight gRPC failures a moment to land in their catch blocks.
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // The fallback to the Kiosk page sticks: the Column page that was hidden while it was
  // selected, or asked for (PageNav) while hidden, does not open by itself later when the
  // server has the profile again.
  testWidgets('a hidden Column page is not opened later by itself', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SettingsState.current = null;
    ColumnState.reset();
    ColumnState.available = true;

    Future<void> columnComesBack() async {
      ColumnState.available = true;
      ColumnState.revision.value++;
      await tester.pump();
      expect(find.text('Column'), findsOneWidget);
    }

    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();

      PageNav.open('Column');
      await tester.pump();
      expect(_railIndex(tester), 7);
      ColumnState.reset(); // hidden while selected
      await tester.pump();
      expect(_railIndex(tester), 0);
      await columnComesBack();
      expect(_railIndex(tester), 0, reason: 'the Kiosk page stays');

      ColumnState.reset();
      await tester.pump();
      PageNav.open('Column'); // asked for while hidden
      await tester.pump();
      expect(_railIndex(tester), 0);
      await columnComesBack();
      expect(_railIndex(tester), 0, reason: 'the Kiosk page stays');
      _expectShown(tester, KioskPage);
      expect(find.byType(ColumnPage), findsNothing);

      // Give in-flight gRPC failures a moment to land in their catch blocks.
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // FL-2: switching dev mode off while the Updater runs must not dispose the page
  // under the running pipeline. While UpdaterRun.busy it stays in the page stack
  // (hidden: the rail drops it and the shell falls back to the Kiosk page).
  test('the Updater stays in the stack while a run is busy, the rail follows dev mode', () {
    List<String> labels(List<(String, IconData, Widget)> pages) => [for (final p in pages) p.$1];

    final busy = shellPages(dev: false, busy: true, column: false);
    expect(labels(busy.stack).last, 'Updater', reason: 'kept mounted while busy');
    expect(labels(busy.rail), isNot(contains('Updater')));

    final idle = shellPages(dev: false, busy: false, column: false);
    expect(labels(idle.stack), isNot(contains('Updater')));

    final dev = shellPages(dev: true, busy: false, column: true);
    expect(labels(dev.stack).last, 'Updater');
    expect(labels(dev.rail).last, 'Updater');
    expect(labels(dev.stack).sublist(0, labels(dev.stack).length - 1), labels(busy.stack)
        .sublist(0, labels(busy.stack).length - 1), reason: 'the Updater only adds itself last');
  });
}
