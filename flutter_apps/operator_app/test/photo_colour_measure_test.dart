// The Photo colour measurement dialog (spec 2026-10-13 section 4.1, ruling R1):
// the middle camera's photo first, four taps on the corner patches' centres,
// the fit's before -> after with Save / Discard, Undo tap, the refused readings
// with their text and no Save, and "would not improve" with only Discard. The
// photo comes through the decode seam as a synthetic chart (no JPEG decode).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/photo_colour_measure_dialog.dart';
import 'package:operator_app/util/card_reference.dart';
import 'package:operator_app/util/colour_fit.dart';

import 'photo_colour_chart.dart';
import 'colorchecker_files.dart';

/// One photo per camera 1..[count]; each photo's bytes are [its camera index].
List<CameraPhoto> _photos(int count) => [
      for (var i = 1; i <= count; i++)
        CameraPhoto(i, Uint8List.fromList([i]), 320, 400),
    ];

class _Opened {
  PhotoColourResult? result;
  bool closed = false;

  /// The cameras whose photo the dialog decoded, in order.
  final List<int> decoded = [];
}

/// Opens the dialog on [photos]; every photo decodes to [chart].
Future<_Opened> _open(WidgetTester tester, TestChart chart,
    {List<CameraPhoto>? photos, String light = 'all'}) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final opened = _Opened();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            opened.result = await showDialog<PhotoColourResult>(
              context: context,
              builder: (_) => PhotoColourMeasureDialog(
                photos: photos ?? _photos(6),
                light: light,
                decode: (bytes) async {
                  opened.decoded.add(bytes.first);
                  return chart.image;
                },
                // the bundle read (rootBundle) does not finish under the test clock
                reference: spyderReference,
              ),
            );
            opened.closed = true;
          },
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return opened;
}

Future<void> _tapAll(WidgetTester tester, TestChart chart, List<Offset> points) async {
  for (final p in points) {
    await tapPhotoAt(tester, chart.image, p);
  }
  await tester.pump();
}

void main() {
  testWidgets('the middle camera is shown first and the dropdown switches', (tester) async {
    final chart = testChart();
    final opened = await _open(tester, chart);
    expect(opened.decoded, [3], reason: 'six photos: the middle camera is (6 + 1) ~/ 2 = 3');
    expect(find.text('Camera 3'), findsOneWidget);
    await _tapAll(tester, chart, chart.corners.sublist(0, 2));
    expect(find.textContaining('2 of 4'), findsOneWidget);

    tester
        .widget<DropdownButton<int>>(find.byKey(const ValueKey('photo-colour-camera')))
        .onChanged!(1);
    await tester.pumpAndSettle();
    expect(opened.decoded, [3, 1]);
    expect(find.textContaining('0 of 4'), findsOneWidget, reason: 'another photo, new taps');
  });

  testWidgets('four taps show the result; undo removes the last tap', (tester) async {
    final chart = testChart();
    final opened = await _open(tester, chart);
    expect(find.textContaining('0 of 4'), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    // Any order (R1): 6H, 1E, 6E, 1H.
    final c = chart.corners;
    await _tapAll(tester, chart, [c[2], c[0], c[3], c[1]]);
    expect(find.textContaining('Mean ΔE'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);

    await tester.tap(find.text('Undo tap'));
    await tester.pump();
    expect(find.textContaining('3 of 4'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(find.textContaining('Mean ΔE'), findsNothing);

    await _tapAll(tester, chart, [c[1]]);
    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final result = opened.result!;
    expect(result.matrix, hasLength(9));
    for (var r = 0; r < 3; r++) {
      final sum = result.matrix[3 * r] + result.matrix[3 * r + 1] + result.matrix[3 * r + 2];
      expect(sum, closeTo(1, 1e-9), reason: 'row $r keeps white white');
    }
    final m = result.measurement;
    expect(m.camera, 3);
    expect(m.chart, 'spyder24');
    expect(m.cardVersion, '');
    expect(m.method, 'taps', reason: 'spec 4.6: a matrix fitted from taps');
    expect(m.scoreAfter, result.fit.scoreAfter);
    expect(m.measured, matches(RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$')));
    expect(m.meanDeAfter, lessThan(m.meanDeBefore));
    expect(m.meanDeBefore, closeTo(result.fit.meanDeBefore, 1e-12));
  });

  testWidgets('as the taps fallback it reads one photo and returns the patches', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final chart = testChart(colours: castColours(classicReference()));
    PhotoColourTaps? taps;
    var closed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              taps = await showDialog<PhotoColourTaps>(
                context: context,
                builder: (_) => PhotoColourMeasureDialog(
                  photos: [CameraPhoto(4, Uint8List.fromList([4]), 0, 0)],
                  light: 'neighbours',
                  decode: (_) async => chart.image,
                  reference: classicReference(),
                  tapsOnly: true,
                ),
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Camera 4'), findsOneWidget);
    expect(find.text('Use the taps'), findsNothing);
    await _tapAll(tester, chart, chart.corners);
    expect(find.text('Save'), findsNothing, reason: 'the run fits, not the dialog');
    await tester.tap(find.text('Use the taps'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(taps!.sample.means, hasLength(24));
    expect(taps!.centres, hasLength(24));
    for (var k = 0; k < 24; k++) {
      expect((taps!.centres[k] - chart.centres[k]).distance, lessThan(2), reason: 'patch $k');
    }
  });

  testWidgets('a refused reading shows its text and no Save', (tester) async {
    final colours = castColours()..[0] = [255, 255, 255];
    final chart = testChart(colours: colours);
    await _open(tester, chart);
    await _tapAll(tester, chart, chart.corners);
    expect(find.text(refusalWhiteClipped), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Undo tap'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);

    // Four taps that are not the card's corner patches.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Undo tap'));
      await tester.pump();
    }
    await _tapAll(tester, chart,
        const [Offset(10, 10), Offset(60, 12), Offset(58, 70), Offset(12, 66)]);
    expect(find.text(refusalTaps), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('a fit that would not improve the colours offers only Discard', (tester) async {
    // A neutral ramp and every colour patch clipped: only the greys are usable, and
    // they cannot fit a matrix.
    final colours = [
      for (var k = 0; k < 24; k++)
        k < 6 ? List.filled(3, 240 - 40 * k) : const [255, 255, 255],
    ];
    final chart = testChart(colours: colours);
    final opened = await _open(tester, chart);
    await _tapAll(tester, chart, chart.corners);
    expect(find.text(refusalNoImprovement), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Undo tap'), findsNothing);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(opened.closed, isTrue);
    expect(opened.result, isNull);
  });

  testWidgets('a fit that would make the skin colours worse offers only Discard', (tester) async {
    // The fixture's 'skin worse at every weight' patches drawn as the chart: every skin
    // weight up to 48 gives 5H or 6H away, so the taps' fit is refused after the fit.
    final fixture = jsonDecode(File('$colorcheckerDir/fixtures/colour_fit_cases.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final c = (fixture['cases'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((c) => c['name'] == 'skin worse at every weight');
    final colours = [
      for (final row in c['measured_srgb8'] as List) [for (final v in row as List) (v as num).round()],
    ];
    final chart = testChart(colours: colours);
    final opened = await _open(tester, chart);
    await _tapAll(tester, chart, chart.corners);
    expect(find.text(refusalSkinWorse), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Undo tap'), findsNothing);
    expect(find.text('Discard'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(opened.closed, isTrue);
    expect(opened.result, isNull);
  });

  test('a fit is refused when it does not lower the weighted score or is not finite', () {
    ColourFit fit(double before, double after, [double m0 = 1, double? scoreBefore, double? scoreAfter]) =>
        ColourFit(
          matrix: [m0, 0, 0, 0, 1, 0, 0, 0, 1],
          meanDeBefore: before,
          meanDeAfter: after,
          worstBefore: before,
          worstAfter: after,
          scoreBefore: scoreBefore ?? before,
          scoreAfter: scoreAfter ?? after,
          // the skin patches unchanged: only the score decides here
          deBefore: List<double>.filled(24, 1),
          deAfter: List<double>.filled(24, 1),
          labAfter: const [],
        );
    expect(colourFitRefusal(fit(5, 2), reference: spyderReference), isNull);
    expect(colourFitRefusal(fit(5, 5), reference: spyderReference), refusalNoImprovement);
    expect(colourFitRefusal(fit(5, 6), reference: spyderReference), refusalNoImprovement);
    expect(colourFitRefusal(fit(double.nan, 2), reference: spyderReference), refusalNoImprovement);
    expect(colourFitRefusal(fit(5, double.nan), reference: spyderReference), refusalNoImprovement);
    expect(colourFitRefusal(fit(5, 2, double.infinity), reference: spyderReference), refusalNoImprovement);
    expect(colourFitRefusal(fit(5, 2, double.nan), reference: spyderReference), refusalNoImprovement);
    // the weighted score decides, not the mean: the mean improves, the score does not
    expect(colourFitRefusal(fit(5, 2, 1, 3, 3), reference: spyderReference), refusalNoImprovement);
    expect(colourFitRefusal(fit(5, 2, 1, 3, 3.5), reference: spyderReference), refusalNoImprovement);
    expect(colourFitRefusal(fit(5, 2, 1, 3, double.nan), reference: spyderReference), refusalNoImprovement);
    // and the other way round: the score improves, the mean does not
    expect(colourFitRefusal(fit(5, 6, 1, 3, 2), reference: spyderReference), isNull);
  });

  PatchSample fixtureSample(String name) {
    final fixture = jsonDecode(File('$colorcheckerDir/fixtures/colour_fit_cases.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final c = (fixture['cases'] as List).cast<Map<String, dynamic>>().firstWhere((c) => c['name'] == name);
    return PatchSample(
      means: [
        for (final row in c['measured_srgb8'] as List) [for (final v in row as List) (v as num).toDouble()],
      ],
      clipped: List<bool>.filled(24, false),
      patchSizePx: 60,
      sampleSidePx: 30,
    );
  }

  final reference = CardReference.fromJson(
      jsonDecode(File('$colorcheckerDir/references/spyder24.json').readAsStringSync())
          as Map<String, dynamic>);

  test('the refusal uses the weighted score (the fixture case where the skin gets worse)', () {
    final sample = fixtureSample('skin made worse');
    final raw = fitColourMatrix(sample.means, List<bool>.filled(24, true), reference: reference);
    expect(raw.meanDeAfter, lessThan(raw.meanDeBefore)); // the plain mean says: better
    expect(raw.scoreAfter, greaterThanOrEqualTo(raw.scoreBefore)); // the weighted score: not
    expect(colourFitRefusal(raw, reference: reference), refusalNoImprovement);
    // the taps' fit raises the skin weight: at 48 the skin is no longer given away and the
    // score at the standard weights improves, so that fit is offered
    final outcome = fitPatches(sample, reference);
    expect(outcome.refusal, isNull);
    expect(outcome.fit!.skinWeight, 48);
    expect(outcome.fit!.scoreAfter, lessThan(outcome.fit!.scoreBefore));
  });

  test('the taps keep a correction only when no skin patch gets worse (skin weight 3, 6, 12, 24, 48)', () {
    final kept = fitPatches(fixtureSample('skin kept at weight 6'), reference);
    expect(kept.refusal, isNull);
    expect(kept.fit!.skinWeight, 6);
    final none = fitPatches(fixtureSample('skin worse at every weight'), reference);
    expect(none.refusal, refusalSkinWorse);
    expect(none.fit, isNull);
    final plain = fitPatches(fixtureSample('quantised'), reference);
    expect(plain.refusal, isNull);
    expect(plain.fit!.skinWeight, 3);
  });
}
