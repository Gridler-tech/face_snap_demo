// The Calibration page's overview (design 2026-10-16, proposal A): four status tiles
// (Camera order, Expected cameras, Focus, Photo colour) with only the selected tile's
// section below; the default selection (the first tile that is not done), the choice
// remembered while the app runs, "Not saved" after a column change, Refresh cameras at
// the top right reloading the tiles, the closed "How it works" folds and the tiles
// wrapping on a narrow window. Against the fakes of calibration_overview_fixture.dart.
import 'package:face_snap_grpc/face_snap_grpc.dart' show ColourMeasurement;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/calibration_page.dart';
import 'package:operator_app/pages/photo_colour_measure_dialog.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/ui/calibration_tiles.dart';
import 'package:operator_app/ui/ui.dart';
import 'package:operator_app/util/colour_fit.dart';

import 'calibration_overview_fixture.dart';

/// Each tile's section, by its card title.
const _sectionTitles = {
  'cameraOrder': 'CAMERA POSITIONS',
  'expectedCameras': 'EXPECTED CAMERAS',
  'focus': 'FOCUS CALIBRATION',
  'photoColour': 'PHOTO COLOUR',
};

bool _selected(WidgetTester tester, String section) =>
    tester.widget<CalibrationTileCard>(overviewTile(section)).selected;

/// The one section shown, by its card title; fails when not exactly one is.
String _shownSection() {
  final shown = [
    for (final e in _sectionTitles.entries)
      if (find.text(e.value).evaluate().isNotEmpty) e.key
  ];
  expect(shown, hasLength(1), reason: 'only the selected tile\'s section: $shown');
  return shown.single;
}

/// The Refresh cameras button's callback (null = disabled).
VoidCallback? _refreshButton(WidgetTester tester) => tester
    .widget<QuietButton>(find.widgetWithText(QuietButton, 'Refresh cameras'))
    .onPressed;

void main() {
  testWidgets('four tiles: icon, name, value line and status pill', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      for (final name in ['Camera order', 'Expected cameras', 'Focus', 'Photo colour']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.byType(CalibrationTileCard), findsNWidgets(4));
      for (final section in _sectionTitles.keys) {
        expect(find.descendant(of: overviewTile(section), matching: find.byType(Icon)),
            findsOneWidget, reason: section);
      }
      expect(find.text('Automatic (USB sockets) · 5 of 5 placed'), findsOneWidget);
      expect(find.descendant(of: overviewTile('expectedCameras'), matching: find.text('5')),
          findsOneWidget);
      expect(find.text('Focus 62'), findsOneWidget);
      expect(
          find.text('Own: Standard light (all LEDs), Standard light (neighbours), '
              'Glare-free light'),
          findsOneWidget);
      expect(overviewPill('cameraOrder', 'Done'), findsOneWidget);
      expect(overviewPill('expectedCameras', 'Done'), findsOneWidget);
      expect(overviewPill('focus', 'Set'), findsOneWidget);
      expect(overviewPill('photoColour', 'Own colours'), findsOneWidget);
    });
  });

  // Every scenario: the pills, and the default selection = the first tile not done.
  for (final (scenario, pills, selected) in [
    (OverviewScenario.allDone, ['Done', 'Done', 'Set', 'Own colours'], 'cameraOrder'),
    (OverviewScenario.toDo, ['To do', 'Done', 'Set', 'Shipped'], 'cameraOrder'),
    (OverviewScenario.check, ['Done', 'Check', 'Set', 'Shipped'], 'expectedCameras'),
    (OverviewScenario.notSaved, ['Done', 'Done', 'Not saved', 'Not saved'], 'focus'),
  ]) {
    testWidgets('${scenario.name}: the pills, and the first tile not done is selected',
        (tester) async {
      await tester.runAsync(() async {
        await pumpCalibrationOverview(tester, scenario: scenario);
        final sections = _sectionTitles.keys.toList();
        for (var i = 0; i < 4; i++) {
          expect(overviewPill(sections[i], pills[i]), findsOneWidget,
              reason: '${sections[i]}: ${pills[i]}');
        }
        for (final section in sections) {
          expect(_selected(tester, section), section == selected, reason: section);
        }
        expect(_shownSection(), selected);
      });
    });
  }

  testWidgets('the value lines of the To do scenario', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.toDo);
      expect(find.text('Manual · 3 of 5 placed'), findsOneWidget);
      expect(find.text('Automatic (5 found)'), findsOneWidget);
      expect(find.text('Focus 40'), findsOneWidget,
          reason: 'never calibrated: the servers\' default 40, still shown');
      expect(
          find.text('Shipped: Standard light (all LEDs), Standard light (neighbours), '
              'Glare-free light'),
          findsOneWidget);
    });
  });

  testWidgets('the value lines of the Check scenario', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.check);
      expect(find.text('6 · 5 found'), findsOneWidget);
      expect(
          find.text('Own: Standard light (all LEDs) · shipped: Standard light (neighbours), '
              'Glare-free light'),
          findsOneWidget);
    });
  });

  testWidgets('clicking a tile shows its section and hides the others', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      expect(_shownSection(), 'cameraOrder');
      for (final section in ['focus', 'photoColour', 'expectedCameras', 'cameraOrder']) {
        await openOverviewTile(tester, section);
        expect(_shownSection(), section);
        for (final other in _sectionTitles.keys) {
          expect(_selected(tester, other), other == section, reason: '$section: $other');
        }
      }
      // The controls of a hidden section are gone too.
      await openOverviewTile(tester, 'photoColour');
      expect(find.text('Calibrate focus'), findsNothing);
      expect(find.text('Save positions'), findsNothing);
      expect(find.text('Measure'), findsNWidgets(3));
    });
  });

  testWidgets('the choice is remembered while the app runs', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.toDo);
      expect(_shownSection(), 'cameraOrder');
      await openOverviewTile(tester, 'photoColour');

      // The page is built anew (another page, then back).
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
      await settleOverview(tester);
      expect(_selected(tester, 'photoColour'), isTrue);
      expect(_shownSection(), 'photoColour');
    });
  });

  testWidgets('"Not saved" appears on the tile after a column change', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      await openOverviewTile(tester, 'expectedCameras');
      expect(overviewPill('expectedCameras', 'Done'), findsOneWidget);
      expect(find.byKey(const ValueKey('column-changed-expected_cameras')), findsNothing);

      final menu = find.byWidgetPredicate((w) =>
          w is DropdownMenu<int> &&
          '${(w.key as ValueKey?)?.value}'.startsWith('expected-'));
      tester.widget<DropdownMenu<int>>(menu).onSelected!(4);
      await settleOverview(tester, rounds: 10); // the push, then the profile's re-read

      expect(overviewPill('expectedCameras', 'Not saved'), findsOneWidget);
      expect(find.descendant(of: overviewTile('expectedCameras'), matching: find.text('4 · 5 found')),
          findsOneWidget,
          reason: 'the value line follows');
      expect(find.byKey(const ValueKey('column-changed-expected_cameras')), findsOneWidget,
          reason: 'the mark stays inside the section');
    });
  });

  testWidgets('an unsaved proposal makes Camera order "Not saved" until it is saved',
      (tester) async {
    await tester.runAsync(() async {
      final rig = await pumpCalibrationOverview(tester,
          data: const OverviewData(positions: [1, 2, 3], mode: 'person'));
      expect(overviewPill('cameraOrder', 'Done'), findsOneWidget);
      await tester.tap(find.text('Start calibration by a person'));
      await settleOverview(tester);
      expect(overviewPill('cameraOrder', 'Not saved'), findsOneWidget);

      await tester.ensureVisible(find.text('Save positions'));
      await tester.tap(find.text('Save positions'));
      await settleOverview(tester);
      expect(rig.calibration.saved, [
        [3, 2, 1]
      ]);
      expect(overviewPill('cameraOrder', 'Done'), findsOneWidget);
    });
  });

  testWidgets('Refresh cameras sits at the top right and reloads the tiles', (tester) async {
    await tester.runAsync(() async {
      final rig = await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      final refresh = find.text('Refresh cameras');
      expect(refresh, findsOneWidget);
      expect(tester.getBottomLeft(refresh).dy,
          lessThan(tester.getTopLeft(overviewTile('cameraOrder')).dy),
          reason: 'above the tiles');
      expect(tester.getTopRight(refresh).dx,
          greaterThan(tester.getTopRight(overviewTile('focus')).dx),
          reason: 'at the right');

      // Shown on every tile, not only Camera order.
      await openOverviewTile(tester, 'focus');
      expect(refresh, findsOneWidget);

      final loads = rig.calibration.loads;
      final settingsLoads = rig.settings.loads;
      await tester.tap(refresh);
      await settleOverview(tester, rounds: 8);
      expect(rig.calibration.loads, greaterThan(loads));
      expect(rig.settings.loads, greaterThan(settingsLoads),
          reason: 'the settings (expected cameras, colours) are read again too');
      expect(overviewPill('focus', 'Set'), findsOneWidget);
    });
  });

  testWidgets('the longer explanations sit in a closed "How it works" fold', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      await openOverviewTile(tester, 'focus');
      final long = find.textContaining('The camera takes a photo at a range of focus');
      expect(long, findsNothing);
      expect(find.text('How it works'), findsOneWidget);
      await tester.tap(find.text('How it works'));
      await settleOverview(tester, rounds: 4);
      expect(long, findsOneWidget);

      await openOverviewTile(tester, 'expectedCameras');
      expect(find.textContaining('power-cycles the camera hub'), findsNothing);
      expect(find.text('How it works'), findsOneWidget);
    });
  });

  testWidgets('a narrow window wraps the tiles to two rows', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester,
          scenario: OverviewScenario.allDone, size: const Size(700, 2000));
      final first = tester.getTopLeft(overviewTile('cameraOrder'));
      expect(tester.getTopLeft(overviewTile('expectedCameras')).dy, first.dy);
      expect(tester.getTopLeft(overviewTile('focus')).dy, greaterThan(first.dy));
      expect(tester.getTopLeft(overviewTile('focus')).dx, first.dx);
      expect(tester.takeException(), isNull, reason: 'no overflow');
    });
  });

  testWidgets('a wide window keeps the four tiles in one row', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      final y = tester.getTopLeft(overviewTile('cameraOrder')).dy;
      for (final section in _sectionTitles.keys) {
        expect(tester.getTopLeft(overviewTile(section)).dy, y, reason: section);
      }
    });
  });

  // ---- Fix round 1 (review of c7027ee) ----

  testWidgets('a running Measure survives a tile switch: back on Photo colour the card is '
      'still busy and the measure dialog opens when the photos arrive', (tester) async {
    await tester.runAsync(() async {
      final rig = await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      // Runs before the server's shutdown (tear-downs run last-first): a failed check
      // must not leave the capture stream open.
      addTearDown(rig.kiosk.releaseManual);
      await openOverviewTile(tester, 'photoColour');
      await tester.tap(find.text('Measure').first);
      await settleOverview(tester, rounds: 3);
      expect(rig.kiosk.manualCaptures, 1);

      await openOverviewTile(tester, 'focus');
      await openOverviewTile(tester, 'photoColour');
      final measures =
          tester.widgetList<QuietButton>(find.widgetWithText(QuietButton, 'Measure'));
      expect(measures, hasLength(3));
      for (final button in measures) {
        expect(button.onPressed, isNull,
            reason: 'the first capture still runs: no second one can start');
      }

      rig.kiosk.releaseManual();
      expect(await waitForOverview(tester, find.byType(PhotoColourMeasureDialog), seconds: 5),
          isTrue,
          reason: 'the capture\'s photos reach the dialog');
      expect(rig.kiosk.manualCaptures, 1);
    });
  });

  testWidgets('a running focus sweep: away and back shows its progress, then the '
      'sharpest result', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      await openOverviewTile(tester, 'focus');
      await tester.tap(find.text('Calibrate focus'));
      await settleOverview(tester, rounds: 3);

      await openOverviewTile(tester, 'cameraOrder');
      expect(find.text('Calibrating…'), findsNothing, reason: 'the Focus section is hidden');
      await openOverviewTile(tester, 'focus');
      expect(find.text('Calibrating…'), findsOneWidget);
      expect(find.textContaining('testing focus'), findsOneWidget);

      expect(await waitForOverview(tester, find.textContaining('Sharpest result (focus')),
          isTrue);
      expect(find.text('Calibrate focus'), findsOneWidget);
    });
  });

  testWidgets('Refresh is off while a proposal waits unsaved, on again once it is saved',
      (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester,
          data: const OverviewData(positions: [1, 2, 3], mode: 'person'));
      expect(_refreshButton(tester), isNotNull);
      await tester.tap(find.text('Start calibration by a person'));
      await settleOverview(tester);
      expect(_refreshButton(tester), isNull,
          reason: 'a reload would replace the proposal');

      await tester.ensureVisible(find.text('Save positions'));
      await tester.tap(find.text('Save positions'));
      await settleOverview(tester);
      expect(_refreshButton(tester), isNotNull);
    });
  });

  testWidgets('Refresh is off during a focus sweep', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      await openOverviewTile(tester, 'focus');
      await tester.tap(find.text('Calibrate focus'));
      await settleOverview(tester, rounds: 3);
      expect(_refreshButton(tester), isNull,
          reason: 'a reload would snapshot the sweep\'s short-lived settings');
      expect(await waitForOverview(tester, find.textContaining('Sharpest result (focus')),
          isTrue);
      await settleOverview(tester, rounds: 3);
      expect(_refreshButton(tester), isNotNull);
    });
  });

  testWidgets('Refresh shows the loading spinner at once, even when the kiosk is slow',
      (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester,
          data: const OverviewData(
              positions: [1, 2, 3], settingsDelay: Duration(seconds: 2)));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Refresh cameras'));
      await settleOverview(tester, rounds: 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'feedback before the settings answer');
      // Let the slow reload finish before the tear-down.
      for (var i = 0; i < 40 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('after a server switch the default tile is worked out again', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      expect(_shownSection(), 'cameraOrder');

      final other = OverviewScenario.notSaved.data;
      final rig = await serveOverview(tester, other);
      await connectOverview(rig, other);
      SettingsState.revision.value++; // what a server switch tells the pages
      await settleOverview(tester, rounds: 8);

      expect(overviewPill('focus', 'Not saved'), findsOneWidget);
      expect(_shownSection(), 'focus', reason: 'the new server\'s first tile not done');
    });
  });

  for (final name in ['calibration', 'hub_upside_down']) {
    testWidgets('a changed "$name" column setting turns Camera order Not saved',
        (tester) async {
      await tester.runAsync(() async {
        await pumpCalibrationOverview(tester,
            data: OverviewData(positions: const [1, 2, 3], changed: {name}));
        expect(overviewPill('cameraOrder', 'Not saved'), findsOneWidget);
        expect(overviewPill('cameraOrder', 'Done'), findsNothing);
      });
    });
  }

  // ---- Fix round 2 (review of 263087d) ----

  // Ruling A: the server has no reliable "focus was calibrated" signal (an adopted
  // column's standard holds the default 40; "Restore factory (all)" deletes the
  // standard), so the Focus tile shows the value in force with the neutral "Set".
  for (final (label, data) in [
    ('the value in force 62, an adopted standard of 40',
        const OverviewData(positions: [1, 2, 3], focus: 62)),
    ('never calibrated (the servers\' default 40)',
        const OverviewData(positions: [1, 2, 3], focus: 40)),
    ('a server without the column profile',
        const OverviewData(positions: [1, 2, 3], columnProfile: false)),
  ]) {
    testWidgets('Focus, $label: the value in force with a neutral "Set"; it never '
        'opens by default', (tester) async {
      await tester.runAsync(() async {
        await pumpCalibrationOverview(tester, data: data);
        expect(
            find.descendant(
                of: overviewTile('focus'), matching: find.text('Focus ${data.focus}')),
            findsOneWidget);
        expect(overviewPill('focus', 'Set'), findsOneWidget);
        expect(overviewPill('focus', 'Done'), findsNothing);
        expect(overviewPill('focus', 'To do'), findsNothing);
        expect(_shownSection(), 'cameraOrder', reason: '"Set" asks nothing of the operator');
      });
    });
  }

  testWidgets('Tab never reaches a control of a hidden section', (tester) async {
    await tester.runAsync(() async {
      await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      expect(_shownSection(), 'cameraOrder');

      /// The focused element sits under a hidden (offstage) subtree.
      bool focusIsHidden() {
        final context = FocusManager.instance.primaryFocus?.context;
        if (context == null) return false;
        var hidden = false;
        context.visitAncestorElements((element) {
          final widget = element.widget;
          if (widget is Offstage && widget.offstage) hidden = true;
          return !hidden;
        });
        return hidden;
      }

      final focusedLabels = <String>{};
      for (var i = 0; i < 80; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final context = FocusManager.instance.primaryFocus?.context;
        final texts = context == null
            ? const <String>[]
            : [
                for (final t in tester.widgetList<Text>(
                    find.descendant(
                        of: find.byElementPredicate((e) => e == context, skipOffstage: false),
                        matching: find.byType(Text),
                        skipOffstage: false)))
                  t.data ?? ''
              ];
        focusedLabels.addAll(texts);
        expect(focusIsHidden(), isFalse,
            reason: 'Tab $i reached a hidden section: $texts');
      }
      expect(focusedLabels, contains('Save positions'),
          reason: 'Tab does walk the shown section');
      expect(focusedLabels, isNot(contains('Calibrate focus')));
      expect(focusedLabels, isNot(contains('Measure')));
    });
  });

  testWidgets('a Measure saved while another tile is shown brings Photo colour back, '
      'so its "Saving…" line and any error are seen', (tester) async {
    await tester.runAsync(() async {
      final rig = await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      addTearDown(rig.kiosk.releaseManual);
      await openOverviewTile(tester, 'photoColour');
      await tester.tap(find.text('Measure').first);
      await settleOverview(tester, rounds: 3);
      await openOverviewTile(tester, 'focus');

      rig.kiosk.releaseManual();
      expect(await waitForOverview(tester, find.byType(PhotoColourMeasureDialog), seconds: 5),
          isTrue);
      expect(_shownSection(), 'focus', reason: 'the dialog alone changes nothing yet');

      // The dialog closes with a result (what its Save does).
      Navigator.of(tester.element(find.byType(PhotoColourMeasureDialog))).pop(
          PhotoColourResult(
              matrix: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
              measurement: ColourMeasurement(
                  measured: '2026-10-16T12:00:00Z',
                  camera: 3,
                  chart: 'spyder24',
                  meanDeBefore: 6,
                  meanDeAfter: 2),
              fit: ColourFit(
                  matrix: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
                  meanDeBefore: 6,
                  meanDeAfter: 2,
                  worstBefore: 9,
                  worstAfter: 3,
                  scoreBefore: 6,
                  scoreAfter: 2,
                  deBefore: const [],
                  deAfter: const [],
                  labAfter: const [])));
      await settleOverview(tester, rounds: 4);

      expect(find.byType(PhotoColourMeasureDialog), findsNothing);
      expect(_shownSection(), 'photoColour');
      expect(_selected(tester, 'photoColour'), isTrue);
    });
  });

  testWidgets('a Measure dialog closed without a result (Discard) leaves the tile alone',
      (tester) async {
    await tester.runAsync(() async {
      final rig = await pumpCalibrationOverview(tester, scenario: OverviewScenario.allDone);
      addTearDown(rig.kiosk.releaseManual);
      await openOverviewTile(tester, 'photoColour');
      await tester.tap(find.text('Measure').first);
      await settleOverview(tester, rounds: 3);
      await openOverviewTile(tester, 'focus');
      rig.kiosk.releaseManual();
      expect(await waitForOverview(tester, find.byType(PhotoColourMeasureDialog), seconds: 5),
          isTrue);
      Navigator.of(tester.element(find.byType(PhotoColourMeasureDialog))).pop();
      await settleOverview(tester, rounds: 4);
      expect(_shownSection(), 'focus');
    });
  });
}
