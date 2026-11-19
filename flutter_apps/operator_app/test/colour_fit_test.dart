// The operator app measures a kiosk's colour correction itself (spec 2026-10-13
// sections 4.1 and 4.3): four taps on the corner patches of a SpyderCheckr 24,
// the 24 patch centres by a homography, the card's orientation from the grey
// column E, and a 3x3 matrix in linear light. The fit must equal cc_probe's
// fit_ccm, held together by tools/colorchecker/fixtures/colour_fit_cases.json;
// the chart reading runs on synthetic RGBA charts drawn here (no JPEG decode).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/util/card_reference.dart';
import 'package:operator_app/util/colour_fit.dart';
import 'colorchecker_files.dart';

// `flutter test` runs with the package root as the working directory.
final _toolDir = colorcheckerDir;

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

final _reference = _json('$_toolDir/references/spyder24.json');
final _classicJson = _json('$_toolDir/references/classic.json');
final _fixture = _json('$_toolDir/fixtures/colour_fit_cases.json');

List<Map<String, dynamic>> get _patches =>
    (_reference['patches'] as List).cast<Map<String, dynamic>>();

/// The SpyderCheckr 24 as the app reads it (the tool's file; the app's copy is
/// the same, test/card_reference_test.dart).
final _spyder = CardReference.fromJson(_reference);

List<double> _doubles(dynamic list) =>
    (list as List).map((v) => (v as num).toDouble()).toList();

/// The reference a fixture case is fitted against: its card, in its version.
CardReference _referenceOf(Map<String, dynamic> c) => CardReference.fromJson(
    c['card'] == 'classic' ? _classicJson : _reference,
    version: c['version'] as String);

/// The ColorChecker Classic (before November 2014), the version the server orients with.
final _classic = CardReference.fromJson(_classicJson, version: 'pre2014');

/// The Classic's reference as sRGB 0..255 (rounded, clipped to the gamut), JSON order.
List<List<int>> get _classicSrgb => [
      for (final lab in _classic.lab)
        [for (final v in labD50ToLinearSrgb(lab)) (255 * linearToSrgb(v).clamp(0.0, 1.0)).round()],
    ];

/// The sheet's sRGB value of each patch, JSON order.
List<List<int>> get _sheetSrgb => [
      for (final p in _patches) (p['srgb'] as List).cast<int>(),
    ];

double _median(List<double> v) {
  final s = [...v]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

// ---------------------------------------------------------------------------
// A synthetic SpyderCheckr 24: 24 squares in the sheet's sRGB colours on a dark
// background, centre spacing [spacing] px, patch side 25/28 of it, rotated by
// [angleDeg] about the image centre, optionally seen mirrored.
// ---------------------------------------------------------------------------
class _Chart {
  _Chart(this.rgba, this.width, this.height, this.truth);
  final Uint8List rgba;
  final int width, height;

  /// The true patch centres, JSON order (1E..6E, 1F..6F, 1G..6G, 1H..6H).
  final List<Offset> truth;

  /// The true centres of the corner patches 1E, 1H, 6H, 6E.
  List<Offset> get corners => [truth[0], truth[18], truth[23], truth[5]];

  /// The card's outer corners (at 1E, 1H, 6H, 6E) for a frame [mu] centre
  /// spacings wide beyond the corner patches' centres across the card (E..H)
  /// and [mv] along it (1..6): where an operator taps the card's own corners.
  List<Offset> cardCorners(double mu, double mv) {
    // Each corner moves away from the opposite sides: build the four from the
    // two grid axes at the corner patches.
    final e1 = truth[0], h1 = truth[18], h6 = truth[23], e6 = truth[5];
    final u = (h1 - e1) / 3.0, v = (e6 - e1) / 5.0;
    return [
      e1 - u * mu - v * mv,
      h1 + u * mu - v * mv,
      h6 + u * mu + v * mv,
      e6 - u * mu + v * mv,
    ];
  }
}

_Chart _chart({
  double spacing = 60,
  double angleDeg = 20,
  bool mirrored = false,
  int width = 640,
  int height = 640,
  List<int>? white,
  List<List<int>>? colours,
  double? patchOfSpacing,
}) {
  // [colours]: another card's patches in JSON order (cell (k ~/ 6, k % 6)), its patch
  // side [patchOfSpacing] of the spacing; the SpyderCheckr's sheet by default.
  colours ??= _sheetSrgb;
  if (white != null) colours[0] = white;
  final cx = width / 2, cy = height / 2;
  final t = angleDeg * math.pi / 180;
  final cosT = math.cos(t), sinT = math.sin(t);
  final half = patchOfSpacing == null ? spacing * 25 / 28 / 2 : spacing * patchOfSpacing / 2;

  // card (x right, y down; column E left, row 1 top) -> image
  Offset toImage(double x, double y) {
    if (mirrored) x = -x;
    return Offset(cx + x * cosT - y * sinT, cy + x * sinT + y * cosT);
  }

  final truth = <Offset>[
    for (var k = 0; k < 24; k++)
      toImage((k ~/ 6 - 1.5) * spacing, (k % 6 - 2.5) * spacing),
  ];
  final rgba = Uint8List(width * height * 4);
  var i = 0;
  for (var py = 0; py < height; py++) {
    for (var px = 0; px < width; px++) {
      final dx = px + 0.5 - cx, dy = py + 0.5 - cy;
      var x = dx * cosT + dy * sinT;
      final y = -dx * sinT + dy * cosT;
      if (mirrored) x = -x;
      final c = (x / spacing + 1.5).round(), r = (y / spacing + 2.5).round();
      var rgb = const [20, 20, 22];
      if (c >= 0 &&
          c < 4 &&
          r >= 0 &&
          r < 6 &&
          (x - (c - 1.5) * spacing).abs() <= half &&
          (y - (r - 2.5) * spacing).abs() <= half) {
        rgb = colours[c * 6 + r];
      }
      rgba[i++] = rgb[0];
      rgba[i++] = rgb[1];
      rgba[i++] = rgb[2];
      rgba[i++] = 255;
    }
  }
  return _Chart(rgba, width, height, truth);
}

/// The operator's taps are a pixel or two off the true centres.
const _jitter = [Offset(1.2, -0.8), Offset(-1.5, 1.0), Offset(0.7, 1.4), Offset(-1.1, -1.3)];

List<Offset> _tapsNear(List<Offset> points) =>
    [for (var i = 0; i < 4; i++) points[i] + _jitter[i]];

/// The L* (D50) of an sRGB 0..255 colour.
double _lightness(List<int> srgb) => linearSrgbToLabD50([for (final v in srgb) srgbToLinear(v / 255)])[0];

/// [srgb] made [dL] L* lighter (the same a*, b*), as sRGB 0..255: a black that
/// reflects the lights.
List<int> _greyAbove(List<int> srgb, double dL) {
  final lab = linearSrgbToLabD50([for (final v in srgb) srgbToLinear(v / 255)]);
  return [
    for (final v in labD50ToLinearSrgb([lab[0] + dL, lab[1], lab[2]]))
      (255 * linearToSrgb(v).clamp(0.0, 1.0)).round(),
  ];
}

void _expectOriented(ChartReading reading, _Chart chart,
    {double tol = 3, List<List<int>>? colours, CardReference? reference}) {
  colours ??= _sheetSrgb;
  reference ??= _spyder;
  expect(reading.refusal, isNull);
  expect(reading.centres, hasLength(24));
  for (var k = 0; k < 24; k++) {
    expect((reading.centres[k] - chart.truth[k]).distance, lessThan(tol),
        reason: '${reference.ids[k]}: ${reading.centres[k]} vs ${chart.truth[k]}');
  }
  final means = reading.sample!.means;
  for (var k = 0; k < 24; k++) {
    for (var ch = 0; ch < 3; ch++) {
      expect(means[k][ch], closeTo(colours[k][ch], 1e-9),
          reason: '${reference.ids[k]} channel $ch');
    }
  }
}

void main() {
  group('reference and constants', () {
    test('the reference read equals the JSON', () {
      expect(_spyder.ids, [for (final p in _patches) p['id']]);
      expect(_spyder.names, [for (final p in _patches) p['name']]);
      expect(_spyder.lab.length, 24);
      for (var k = 0; k < 24; k++) {
        expect(_spyder.lab[k], _doubles(_patches[k]['lab']['']), reason: _spyder.ids[k]);
      }
    });

    test('the colour constants and refusal texts equal the fixture', () {
      final k = _fixture['colour_constants'] as Map<String, dynamic>;
      expect(srgbA, k['srgb_a']);
      expect(srgbGamma, k['srgb_gamma']);
      expect((srgbK0 - k['srgb_k0']).abs(), lessThan(1e-15));
      expect((srgbPhi - k['srgb_phi']).abs(), lessThan(1e-12));
      expect((srgbBeta - k['srgb_beta']).abs(), lessThan(1e-15));
      expect((labDelta - k['lab_delta']).abs(), lessThan(1e-15));
      expect(whiteD65, _doubles(k['white_d65']));
      expect(whiteD50, _doubles(k['white_d50']));
      expect(srgbPrimariesXy, [for (final p in k['srgb_primaries_xy']) _doubles(p)]);
      expect(bradfordCone, [for (final r in k['bradford_cone']) _doubles(r)]);
      for (final c in (_fixture['cases'] as List).cast<Map<String, dynamic>>()) {
        final ref = _referenceOf(c);
        expect(ref.exposureGreyIndex, c['grey_index'], reason: c['name']);
        expect(ref.weights, _doubles(c['weights']), reason: c['name']);
      }
      expect(colourFitRefusals, (_fixture['refusals'] as List).cast<String>());
      expect(colourFitRefusals, [
        refusalWhiteClipped,
        refusalTooSmall,
        refusalTaps,
        refusalNoImprovement,
        refusalSkinWorse,
      ]);
      expect(refusalSkinWorse, 'this correction would make the skin colours worse');
      expect(skinWorseTolerance, 0.5);
      expect(skinWeightSteps, [3, 6, 12, 24, 48]);
    });

    test('greysDarken: strictly darker to the last grey, the black at most 3.0 L* lighter', () {
      expect(blackToleranceL, 3.0);
      expect(greysDarken([95, 80, 60, 40, 20, 10]), isTrue);
      expect(greysDarken([95, 80, 60, 40, 20, 20]), isTrue); // the black as light as 5E
      expect(greysDarken([95, 80, 60, 40, 20, 23.0]), isTrue); // exactly 3.0 lighter: passes
      expect(greysDarken([95, 80, 60, 40, 20, 23.01]), isFalse); // 3.01: fails
      expect(greysDarken([95, 80, 60, 40, 40, 10]), isFalse); // an equal step before the last
      expect(greysDarken([95, 80, 60, 41, 40, 43]), isTrue);
      // a card upside down: the reversed ramp fails on its first steps
      expect(greysDarken([10, 20, 40, 60, 80, 95]), isFalse);
      expect(greysDarken([21, 20, 40, 60, 80, 95]), isFalse);
      expect(greysDarken([95, 80, 60, 40, 20, double.nan]), isFalse);
      expect(greysDarken([95, double.nan, 60, 40, 20, 10]), isFalse);
      expect(greysDarken([20, 23]), isTrue); // two greys: only the black's step
      expect(greysDarken([20, 23.5]), isFalse);
      expect(greysDarken([50]), isTrue);
      expect(greysDarken(const []), isTrue);
    });
  });

  group('colour maths', () {
    test('lab maths matches the reference sRGB', () {
      final de = <double>[];
      for (var k = 0; k < 24; k++) {
        final lin = [for (final v in _sheetSrgb[k]) srgbToLinear(v / 255)];
        de.add(deltaE2000(linearSrgbToLabD50(lin), _spyder.lab[k]));
        // the inverse pair is exact
        final back = linearSrgbToLabD50(labD50ToLinearSrgb(_spyder.lab[k]));
        for (var c = 0; c < 3; c++) {
          expect(back[c], closeTo(_spyder.lab[k][c], 1e-9), reason: _spyder.ids[k]);
        }
      }
      final median = _median(de);
      // ignore: avoid_print
      print('sheet sRGB vs sheet Lab: median dE00 ${median.toStringAsFixed(4)} '
          '(cc_probe 0.2886), max ${de.reduce(math.max).toStringAsFixed(3)}');
      expect(median, lessThan(0.6));
      expect(median, closeTo(0.28859730048289695, 1e-6)); // cc_probe's value
      // D65 sRGB white is Lab D50 (100, 0, 0) through Bradford
      final w = linearSrgbToLabD50([1, 1, 1]);
      expect(w[0], closeTo(100, 1e-6));
      expect(w[1], closeTo(0, 1e-6));
      expect(w[2], closeTo(0, 1e-6));
      // the curve is cc_probe's (continuous linear segment), not the textbook one
      expect(srgbToLinear(srgbK0), closeTo(srgbK0 / srgbPhi, 1e-15));
      expect(srgbToLinear(-0.5), closeTo(-srgbToLinear(0.5), 1e-15));
      for (final v in [-0.3, -0.01, 0.0, 0.002, 0.04, 0.5, 1.0, 1.2]) {
        expect(linearToSrgb(srgbToLinear(v)), closeTo(v, 1e-12));
      }
    });

    test('deltaE2000 matches Sharma', () {
      // Sharma, Wu, Dalal 2005, the first 10 pairs of ciede2000testdata.txt
      const pairs = [
        [50.0000, 2.6772, -79.7751, 50.0000, 0.0000, -82.7485, 2.0425],
        [50.0000, 3.1571, -77.2803, 50.0000, 0.0000, -82.7485, 2.8615],
        [50.0000, 2.8361, -74.0200, 50.0000, 0.0000, -82.7485, 3.4412],
        [50.0000, -1.3802, -84.2814, 50.0000, 0.0000, -82.7485, 1.0000],
        [50.0000, -1.1848, -84.8006, 50.0000, 0.0000, -82.7485, 1.0000],
        [50.0000, -0.9009, -85.5211, 50.0000, 0.0000, -82.7485, 1.0000],
        [50.0000, 0.0000, 0.0000, 50.0000, -1.0000, 2.0000, 2.3669],
        [50.0000, -1.0000, 2.0000, 50.0000, 0.0000, 0.0000, 2.3669],
        [50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0009, 7.1792],
        [50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0010, 7.1792],
      ];
      for (final p in pairs) {
        final a = p.sublist(0, 3), b = p.sublist(3, 6);
        expect(deltaE2000(a, b), closeTo(p[6], 1e-4), reason: '$p');
        expect(deltaE2000(b, a), closeTo(p[6], 1e-4), reason: 'swapped $p');
      }
      expect(deltaE2000(_spyder.lab[3], _spyder.lab[3]), 0);
    });
  });

  group('the fit', () {
    final cases = (_fixture['cases'] as List).cast<Map<String, dynamic>>();

    List<List<double>> measuredOf(Map<String, dynamic> c) =>
        [for (final row in c['measured_srgb8']) _doubles(row)];
    List<bool> usableOf(Map<String, dynamic> c) => (c['usable'] as List).cast<bool>();

    test('the fixture cases', () {
      expect(cases.map((c) => c['name']), [
        'exact',
        'quantised',
        'white clipped',
        'weighted spyder',
        'classic pre2014',
        'classic clipped white',
        'skin made worse',
        'skin kept at weight 6',
        'skin worse at every weight',
        'the score improves only at weight 24',
      ]);
      for (final c in cases) {
        final fit = fitColourMatrix(measuredOf(c), usableOf(c), reference: _referenceOf(c));
        final want = _doubles(c['expected_matrix']);
        var err = 0.0;
        for (var i = 0; i < 9; i++) {
          err = math.max(err, (fit.matrix[i] - want[i]).abs());
        }
        // ignore: avoid_print
        print('${c['name']}: max |matrix - expected| ${err.toStringAsExponential(2)}, '
            'dE ${fit.meanDeBefore.toStringAsFixed(4)} -> ${fit.meanDeAfter.toStringAsFixed(4)}, '
            'score ${fit.scoreBefore.toStringAsFixed(4)} -> ${fit.scoreAfter.toStringAsFixed(4)}');
        expect(err, lessThan(1e-6), reason: c['name']);
        expect(fit.meanDeBefore, closeTo(c['expected_mean_de_before'], 1e-6), reason: c['name']);
        expect(fit.meanDeAfter, closeTo(c['expected_mean_de_after'], 1e-6), reason: c['name']);
        expect(fit.worstBefore, closeTo(c['expected_worst_before'], 1e-6), reason: c['name']);
        expect(fit.worstAfter, closeTo(c['expected_worst_after'], 1e-6), reason: c['name']);
        expect(fit.scoreBefore, closeTo(c['expected_score_before'], 1e-6), reason: c['name']);
        expect(fit.scoreAfter, closeTo(c['expected_score_after'], 1e-6), reason: c['name']);
        expect(!(fit.scoreAfter < fit.scoreBefore), c['expected_refused'], reason: c['name']);
        for (var r = 0; r < 3; r++) {
          final sum = fit.matrix[3 * r] + fit.matrix[3 * r + 1] + fit.matrix[3 * r + 2];
          expect(sum, closeTo(1, 1e-12), reason: 'row $r sums to 1 (white stays white)');
        }
        expect(fit.deAfter, hasLength(24));
        expect(fit.labAfter, hasLength(24));
      }
    });

    test('weights of 1 give the unweighted matrix', () {
      for (final c in cases) {
        final ref = _referenceOf(c);
        final unweighted = _doubles(c['expected_matrix_unweighted']);
        final fit = fitColourMatrix(measuredOf(c), usableOf(c),
            reference: ref, weights: List<double>.filled(24, 1));
        for (var i = 0; i < 9; i++) {
          expect(fit.matrix[i], closeTo(unweighted[i], 1e-12), reason: '${c['name']} [$i]');
        }
        // the skin weight really changes the matrix (not a vacuous comparison)
        final weighted = fitColourMatrix(measuredOf(c), usableOf(c), reference: ref);
        var diff = 0.0;
        for (var i = 0; i < 9; i++) {
          diff = math.max(diff, (weighted.matrix[i] - unweighted[i]).abs());
        }
        expect(diff, greaterThan(1e-5), reason: c['name']);
        if (usableOf(c).every((u) => u)) {
          expect(fit.scoreBefore, closeTo(fit.meanDeBefore, 1e-12), reason: c['name']);
          expect(fit.scoreAfter, closeTo(fit.meanDeAfter, 1e-12), reason: c['name']);
        }
      }
    });

    test("exposure is taken out on the card's grey", () {
      for (final name in ['exact', 'quantised', 'weighted spyder', 'classic pre2014']) {
        final c = cases.firstWhere((c) => c['name'] == name);
        final ref = _referenceOf(c);
        final base = fitColourMatrix(measuredOf(c), usableOf(c), reference: ref);
        for (final factor in [0.5, 1.3]) {
          final scaled = [
            for (final row in measuredOf(c))
              [for (final v in row) linearToSrgb(srgbToLinear(v / 255) * factor) * 255],
          ];
          final fit = fitColourMatrix(scaled, usableOf(c), reference: ref);
          for (var i = 0; i < 9; i++) {
            expect(fit.matrix[i], closeTo(base.matrix[i], 1e-9), reason: '$name x$factor [$i]');
          }
          expect(fit.meanDeBefore, closeTo(base.meanDeBefore, 1e-9)); // R3: exposure out first
          expect(fit.meanDeAfter, closeTo(base.meanDeAfter, 1e-9));
          expect(fit.scoreBefore, closeTo(base.scoreBefore, 1e-9), reason: '$name x$factor');
          expect(fit.scoreAfter, closeTo(base.scoreAfter, 1e-9), reason: '$name x$factor');
        }
      }
    });

    test('normalisedLab is the exposure-normalised Lab of the fit', () {
      for (final name in ['quantised', 'classic pre2014']) {
        final c = cases.firstWhere((c) => c['name'] == name);
        final ref = _referenceOf(c);
        final lab = normalisedLab(measuredOf(c), ref);
        final fit = fitColourMatrix(measuredOf(c), usableOf(c), reference: ref);
        expect(lab, hasLength(24));
        for (var k = 0; k < 24; k++) {
          expect(deltaE2000(lab[k], ref.lab[k]), closeTo(fit.deBefore[k], 1e-9), reason: '$name $k');
        }
        // the grey the exposure is taken out on has (about) its reference lightness: its
        // Rec. 709 Y is scaled to the reference's, Lab's L follows the Bradford-adapted Y
        expect(lab[ref.exposureGreyIndex][0], closeTo(ref.lab[ref.exposureGreyIndex][0], 0.05));
        // and the light level does not enter
        final dim = [
          for (final row in measuredOf(c))
            [for (final v in row) linearToSrgb(srgbToLinear(v / 255) * 0.5) * 255],
        ];
        final dimLab = normalisedLab(dim, ref);
        for (var k = 0; k < 24; k++) {
          for (var i = 0; i < 3; i++) {
            expect(dimLab[k][i], closeTo(lab[k][i], 1e-9), reason: '$name $k');
          }
        }
      }
      final black = [for (var k = 0; k < 24; k++) [0.0, 0.0, 0.0]];
      expect(() => normalisedLab(black, _spyder), throwsArgumentError);
    });

    test('a clipped patch is left out of the score', () {
      final c = cases.firstWhere((c) => c['name'] == 'quantised');
      final usable = List<bool>.filled(24, true)..[11] = false;
      final results = <ColourFit>[];
      for (final value in [
        [255.0, 255.0, 255.0],
        [0.0, 0.0, 0.0],
      ]) {
        final measured = measuredOf(c)..[11] = value;
        results.add(fitColourMatrix(measured, usable, reference: _spyder));
      }
      final (a, b) = (results[0], results[1]);
      for (var i = 0; i < 9; i++) {
        expect(a.matrix[i], closeTo(b.matrix[i], 1e-12));
      }
      expect(a.scoreBefore, closeTo(b.scoreBefore, 1e-12));
      expect(a.scoreAfter, closeTo(b.scoreAfter, 1e-12));
      expect((a.meanDeAfter - b.meanDeAfter).abs(), greaterThan(0.01)); // the mean sees it
      // exactly the weighted mean over the other 23 patches
      final w = _spyder.weights;
      var sum = 0.0, total = 0.0;
      for (var k = 0; k < 24; k++) {
        if (k == 11) continue;
        sum += w[k] * b.deAfter[k];
        total += w[k];
      }
      expect(b.scoreAfter, closeTo(sum / total, 1e-12));
      expect(weightedScore(b.deAfter, w, usable), closeTo(b.scoreAfter, 1e-12));
      expect(weightedScore(b.deAfter, List<double>.filled(24, 1), List<bool>.filled(24, true)),
          closeTo(b.meanDeAfter, 1e-12));
      expect(() => weightedScore(b.deAfter, w, List<bool>.filled(24, false)), throwsArgumentError);
    });

    test('skin weight 3', () {
      expect(skinWeight, 3);
      for (final c in cases) {
        final ref = _referenceOf(c);
        final want = [for (final id in ref.ids) ref.skin.contains(id) ? 3.0 : 1.0];
        expect(_doubles(c['weights']), want, reason: c['name']);
        expect(ref.weights, want, reason: c['name']);
      }
      // the weights pull the fit towards the skin: the 'weighted spyder' case's
      // skin patches (5H, 6H) have the lower dE with the weighted fit
      final c = cases.firstWhere((c) => c['name'] == 'weighted spyder');
      final skin = [for (final id in _spyder.skin) _spyder.indexOf(id)];
      expect(skin, [22, 23]);
      final weighted = fitColourMatrix(measuredOf(c), usableOf(c), reference: _spyder);
      final plain = fitColourMatrix(measuredOf(c), usableOf(c),
          reference: _spyder, weights: List<double>.filled(24, 1));
      double skinDe(ColourFit f) => skin.map((k) => f.deAfter[k]).reduce((a, b) => a + b) / skin.length;
      expect(skinDe(weighted), lessThan(skinDe(plain) - 0.2));
    });

    test('weights of the wrong length or a negative weight are rejected', () {
      final c = cases.first;
      expect(() => fitColourMatrix(measuredOf(c), usableOf(c), reference: _spyder, weights: [1, 1]),
          throwsArgumentError);
      expect(
          () => fitColourMatrix(measuredOf(c), usableOf(c),
              reference: _spyder, weights: List<double>.filled(24, 1)..[3] = -1),
          throwsArgumentError);
    });

    test('a fit with too few usable patches is rejected', () {
      final c = cases.first;
      final usable = List<bool>.filled(24, false)..[0] = true..[1] = true;
      expect(() => fitColourMatrix(measuredOf(c), usable, reference: _spyder), throwsArgumentError);
    });

    test('the skin guard on the fixture cases (the same numbers as cc_probe.fit_patches)', () {
      for (final c in cases) {
        final ref = _referenceOf(c);
        final fit = fitColourMatrixGuarded(measuredOf(c), usableOf(c), reference: ref);
        final refusal = colourFitRefusal(fit, reference: ref);
        // ignore: avoid_print
        print('${c['name']}: skin weight ${fit.skinWeight}, score ${fit.scoreBefore.toStringAsFixed(4)} '
            '-> ${fit.scoreAfter.toStringAsFixed(4)}, refusal $refusal');
        expect(fit.skinWeight, c['expected_skin_weight'], reason: c['name']);
        final want = _doubles(c['expected_guarded_matrix']);
        for (var i = 0; i < 9; i++) {
          expect(fit.matrix[i], closeTo(want[i], 1e-6), reason: '${c['name']} [$i]');
        }
        expect(fit.scoreBefore, closeTo(c['expected_guarded_score_before'], 1e-6), reason: c['name']);
        expect(fit.scoreAfter, closeTo(c['expected_guarded_score_after'], 1e-6), reason: c['name']);
        expect(refusal, c['expected_refusal'], reason: c['name']);
        expect(c['expected_refusal'] == null || colourFitRefusals.contains(c['expected_refusal']), isTrue);
      }
    });

    test('the skin guard raises the skin weight to 6 and keeps the standard scores', () {
      final c = cases.firstWhere((c) => c['name'] == 'skin kept at weight 6');
      final k5h = _spyder.indexOf('5H');
      // weight 3 lowers the score (the old rule saved it) but gives 5H away
      final at3 = fitColourMatrix(measuredOf(c), usableOf(c), reference: _spyder);
      expect(at3.scoreAfter, lessThan(at3.scoreBefore));
      expect(at3.deAfter[k5h], greaterThan(at3.deBefore[k5h] + skinWorseTolerance));
      final fit = fitColourMatrixGuarded(measuredOf(c), usableOf(c), reference: _spyder);
      expect(fit.skinWeight, 6);
      final w6 = [for (final id in _spyder.ids) _spyder.skin.contains(id) ? 6.0 : 1.0];
      final at6 = fitColourMatrix(measuredOf(c), usableOf(c), reference: _spyder, weights: w6);
      expect(fit.matrix, at6.matrix);
      for (final id in _spyder.skin) {
        final k = _spyder.indexOf(id);
        expect(fit.deAfter[k], lessThanOrEqualTo(fit.deBefore[k] + skinWorseTolerance), reason: id);
      }
      // the scores at the standard weights (skin 3), not the weight-6 fit's own
      expect(fit.scoreAfter, weightedScore(fit.deAfter, _spyder.weights, usableOf(c)));
      expect(fit.scoreBefore, at3.scoreBefore);
      expect((fit.scoreAfter - at6.scoreAfter).abs(), greaterThan(1e-3));
      expect(colourFitRefusal(fit, reference: _spyder), isNull);
    });

    test('ruling F6: a weight that keeps the skin but does not lower the score is passed over', () {
      final c = cases.firstWhere((c) => c['name'] == 'the score improves only at weight 24');
      List<double> weightsOf(double w) => [for (final id in _spyder.ids) _spyder.skin.contains(id) ? w : 1.0];
      bool skinKept(ColourFit f) => _spyder.skin.every((id) {
            final k = _spyder.indexOf(id);
            return f.deAfter[k] <= f.deBefore[k] + skinWorseTolerance;
          });
      double standardAfter(ColourFit f) => weightedScore(f.deAfter, _spyder.weights, usableOf(c));
      final at = {
        for (final w in skinWeightSteps)
          w: fitColourMatrix(measuredOf(c), usableOf(c), reference: _spyder, weights: weightsOf(w)),
      };
      final before = weightedScore(at[3.0]!.deBefore, _spyder.weights, usableOf(c));
      expect(skinKept(at[3.0]!), isFalse);
      expect(skinKept(at[6.0]!), isFalse);
      // weight 12 is the first that keeps the skin, but the standard score does not go down
      expect(skinKept(at[12.0]!), isTrue);
      expect(standardAfter(at[12.0]!), greaterThanOrEqualTo(before));
      expect(skinKept(at[24.0]!), isTrue);
      expect(standardAfter(at[24.0]!), lessThan(before));
      final fit = fitColourMatrixGuarded(measuredOf(c), usableOf(c), reference: _spyder);
      expect(fit.skinWeight, 24);
      expect(fit.matrix, at[24.0]!.matrix);
      expect(colourFitRefusal(fit, reference: _spyder), isNull);
    });

    test('no skin weight helps: the skin refusal, not a matrix to save', () {
      final c = cases.firstWhere((c) => c['name'] == 'skin worse at every weight');
      final fit = fitColourMatrixGuarded(measuredOf(c), usableOf(c), reference: _spyder);
      expect(fit.skinWeight, 48);
      expect(fit.scoreAfter, lessThan(fit.scoreBefore)); // it would improve the score
      expect(colourFitRefusal(fit, reference: _spyder), refusalSkinWorse);
      // the plain weight-3 fit passed the old check
      final at3 = fitColourMatrix(measuredOf(c), usableOf(c), reference: _spyder);
      expect(at3.scoreAfter, lessThan(at3.scoreBefore));
    });

    test('the skin refusal: after "would not improve", a usable skin patch worse by more than 0.5', () {
      final k5h = _spyder.indexOf('5H');
      ColourFit fit({double scoreAfter = 1, double worse = 0, List<bool>? usable, int patches = 24}) {
        final deBefore = List<double>.filled(patches, 2);
        final deAfter = List<double>.filled(patches, 1);
        if (k5h < patches) deAfter[k5h] = 2 + worse;
        return ColourFit(
          matrix: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
          meanDeBefore: 2,
          meanDeAfter: 1,
          worstBefore: 2,
          worstAfter: 2,
          scoreBefore: 2,
          scoreAfter: scoreAfter,
          deBefore: deBefore,
          deAfter: deAfter,
          labAfter: const [],
          usable: usable,
        );
      }

      expect(colourFitRefusal(fit(worse: 0.5), reference: _spyder), isNull); // exactly 0.5 passes
      expect(colourFitRefusal(fit(worse: 0.51), reference: _spyder), refusalSkinWorse);
      expect(colourFitRefusal(fit(worse: 0.51, scoreAfter: 2), reference: _spyder), refusalNoImprovement);
      expect(colourFitRefusal(fit(worse: double.nan), reference: _spyder), refusalSkinWorse);
      // a clipped skin patch is out of the fit and of the guard
      final clipped = List<bool>.filled(24, true)..[k5h] = false;
      expect(colourFitRefusal(fit(worse: 5, usable: clipped), reference: _spyder), isNull);
      // per-patch dE that do not cover the card cannot be checked: refused
      expect(colourFitRefusal(fit(patches: 0), reference: _spyder), refusalNoImprovement);
    });
  });

  group('the chart reading from four taps', () {
    test('taps in all eight orders give the same centres', () {
      final chart = _chart();
      final taps = _tapsNear(chart.corners);
      final orders = <List<Offset>>[];
      for (var start = 0; start < 4; start++) {
        orders.add([for (var i = 0; i < 4; i++) taps[(start + i) % 4]]);
        orders.add([for (var i = 0; i < 4; i++) taps[(start - i + 4) % 4]]);
      }
      orders.add([taps[0], taps[2], taps[1], taps[3]]); // not even cyclic
      for (final order in orders) {
        final reading = readChart(chart.rgba, chart.width, chart.height, order, reference: _spyder);
        _expectOriented(reading, chart);
        expect(reading.sample!.whiteClipped, isFalse);
        expect(reading.sample!.patchSizePx, closeTo(0.89 * 60, 1.5));
      }
    });

    test('exactly one of the eight assignments gives the card in JSON order', () {
      final chart = _chart(angleDeg: 0);
      var hits = 0;
      for (var rotation = 0; rotation < 4; rotation++) {
        for (final mirrored in [false, true]) {
          final c = gridCentres(chart.corners, reference: _spyder, rotation: rotation, mirrored: mirrored);
          expect(c, hasLength(24));
          var worst = 0.0;
          for (var k = 0; k < 24; k++) {
            worst = math.max(worst, (c[k] - chart.truth[k]).distance);
          }
          if (worst < 1e-6) hits++;
        }
      }
      expect(hits, 1);
    });

    test('a mirrored card is oriented', () {
      final chart = _chart(mirrored: true, angleDeg: -30);
      _expectOriented(readChart(chart.rgba, chart.width, chart.height, _tapsNear(chart.corners), reference: _spyder), chart);
    });

    test('an upside-down card is oriented', () {
      final chart = _chart(angleDeg: 200);
      _expectOriented(readChart(chart.rgba, chart.width, chart.height, _tapsNear(chart.corners), reference: _spyder), chart);
    });

    test('taps on the wrong patches are refused', () {
      final chart = _chart();
      final t = chart.truth;
      final wrong = <String, List<Offset>>{
        'the inner patches 2F 2G 5G 5F': [t[7], t[13], t[16], t[10]],
        'the middle columns 1F 1G 6G 6F': [t[6], t[12], t[17], t[11]],
        'the background': const [Offset(10, 10), Offset(630, 10), Offset(630, 630), Offset(10, 630)],
        'three taps': [t[0], t[18], t[23]],
        'three on one line': [t[0], t[6], t[12], t[23]],
      };
      wrong.forEach((name, taps) {
        final reading = readChart(chart.rgba, chart.width, chart.height, taps, reference: _spyder);
        expect(reading.refusal, refusalTaps, reason: name);
        expect(reading.centres, isEmpty, reason: name);
      });
    });

    test("taps on the card's own corners are read too (any frame width, any order)", () {
      // The card's frame seen on the bench: 0.3 to 0.9 centre spacings beyond the
      // corner patches, not always the same across and along the card.
      for (final (mu, mv) in const [(0.35, 0.35), (0.5, 0.5), (0.4, 0.7), (0.8, 0.6), (0.9, 0.9)]) {
        for (final card in [_chart(spacing: 50), _chart(spacing: 50, mirrored: true, angleDeg: 200)]) {
          final taps = _tapsNear(card.cardCorners(mu, mv));
          final reading = readChart(card.rgba, card.width, card.height,
              [taps[2], taps[0], taps[3], taps[1]], reference: _spyder);
          _expectOriented(reading, card, tol: 6);
        }
      }
    });

    test('taps on the corner patches still win over the card-corner reading', () {
      final chart = _chart();
      final reading = readChart(chart.rgba, chart.width, chart.height, _tapsNear(chart.corners), reference: _spyder);
      _expectOriented(reading, chart);
    });

    test('taps on a busy image with no card are refused (it only looks like a card by chance)', () {
      const w = 640, h = 640;
      final rgba = Uint8List(w * h * 4);
      final random = math.Random(7);
      for (var i = 0; i < rgba.length; i += 4) {
        rgba[i] = random.nextInt(256);
        rgba[i + 1] = random.nextInt(256);
        rgba[i + 2] = random.nextInt(256);
        rgba[i + 3] = 255;
      }
      final reading = readChart(rgba, w, h,
          const [Offset(160, 120), Offset(480, 120), Offset(480, 540), Offset(160, 540)], reference: _spyder);
      expect(reading.refusal, refusalTaps);
      expect(reading.centres, isEmpty);
    });

    test('small patches are refused', () {
      // spacing 18 px: patch 0.89 x 18 = 16.0 px, under MIN_RELIABLE_PATCH_PX (17)
      final chart = _chart(spacing: 18, width: 200, height: 200);
      final reading = readChart(chart.rgba, chart.width, chart.height, chart.corners, reference: _spyder);
      expect(reading.refusal, refusalTooSmall);
      expect(reading.centres, hasLength(24)); // oriented first
      expect(reading.sample!.patchSizePx, lessThan(minReliablePatchPx));
      // 20 px spacing (17.8 px patches) is read
      final ok = _chart(spacing: 20, width: 200, height: 200);
      expect(readChart(ok.rgba, ok.width, ok.height, ok.corners, reference: _spyder).refusal, isNull);
    });

    test('a clipped white patch is refused', () {
      final chart = _chart(white: const [255, 254, 251]);
      final reading = readChart(chart.rgba, chart.width, chart.height, _tapsNear(chart.corners), reference: _spyder);
      expect(reading.refusal, refusalWhiteClipped);
      expect(reading.sample!.whiteClipped, isTrue);
      expect(reading.sample!.clipped, [true, ...List.filled(23, false)]);
      // one channel at 253 is not clipped
      final fine = _chart(white: const [253, 250, 248]);
      expect(readChart(fine.rgba, fine.width, fine.height, fine.corners, reference: _spyder).refusal, isNull);
    });

    test('a black that reads up to 3 L* lighter than 5E is still read (it reflects the lights)', () {
      // 6E drawn about 1 L* above 5E: the greys no longer darken strictly at the last
      // step, which the black tolerance (blackToleranceL) allows; 4 L* above is refused.
      final colours = _sheetSrgb;
      final lighter = _greyAbove(colours[4], 1);
      expect(_lightness(lighter) - _lightness(colours[4]), inInclusiveRange(0.5, 1.5));
      colours[5] = lighter;
      for (final angle in const [20.0, 200.0]) {
        // upright and upside down: the tolerance is on the last step only
        final chart = _chart(angleDeg: angle, colours: [...colours]);
        _expectOriented(
            readChart(chart.rgba, chart.width, chart.height, _tapsNear(chart.corners), reference: _spyder), chart,
            colours: colours);
      }
      final far = _sheetSrgb;
      far[5] = _greyAbove(far[4], 4);
      expect(_lightness(far[5]) - _lightness(far[4]), greaterThan(3));
      final chart = _chart(colours: far);
      final reading = readChart(chart.rgba, chart.width, chart.height, _tapsNear(chart.corners), reference: _spyder);
      expect(reading.refusal, refusalTaps);
    });

    test('the sample square is half the smallest centre spacing, clipped to the image', () {
      // a 10x10 image, R = x, G = y; centres 8 px apart -> a 4 px square
      const w = 10, h = 10;
      final rgba = Uint8List(w * h * 4);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final i = (y * w + x) * 4;
          rgba[i] = x;
          rgba[i + 1] = y;
          rgba[i + 2] = 254;
          rgba[i + 3] = 255;
        }
      }
      final s = samplePatches(
          rgba, w, h, const [Offset(2, 2), Offset(2, 10), Offset(2, 18)]);
      expect(s.sampleSidePx, 4);
      expect(s.patchSizePx, closeTo(0.89 * 8, 1e-12));
      expect(s.means[0], [1.5, 1.5, 254]); // pixels 0..3 in both directions
      expect(s.means[1], [1.5, 8.5, 254]); // rows 8..11 clipped to 8..9
      expect(s.means[2], [0, 0, 0]); // rows 16..19: wholly outside
      expect(s.clipped, [true, true, false]);
      expect(s.whiteClipped, isTrue); // blue all at 254
    });
  });

  group('the chart reading from four taps on a ColorChecker Classic', () {
    // The Classic's corner patches 1, 19, 24, 6 are the cells (0,0), (3,0), (3,5),
    // (0,5), as the SpyderCheckr's 1E, 1H, 6H, 6E; its greys are 19..24 (white
    // first), its patches 2.50 wide at a 2.75 pitch.
    _Chart classicChart({double angleDeg = 20, bool mirrored = false, List<int>? white}) {
      final colours = _classicSrgb;
      if (white != null) colours[18] = white;
      return _chart(
          angleDeg: angleDeg, mirrored: mirrored, colours: colours, patchOfSpacing: _classic.patchOfSpacing);
    }

    test("the Classic's four corner patches give its 24 centres in any order and rotation", () {
      expect([for (final k in _classic.cornerIndexes) _classic.ids[k]], ['1', '19', '24', '6']);
      for (final angle in const [0.0, 20.0, 110.0, 200.0, 290.0]) {
        final chart = classicChart(angleDeg: angle);
        final taps = _tapsNear(chart.corners);
        for (var start = 0; start < 4; start++) {
          for (final order in [
            [for (var i = 0; i < 4; i++) taps[(start + i) % 4]],
            [for (var i = 0; i < 4; i++) taps[(start - i + 4) % 4]],
          ]) {
            final reading = readChart(chart.rgba, chart.width, chart.height, order, reference: _classic);
            _expectOriented(reading, chart, colours: _classicSrgb, reference: _classic);
            expect(reading.sample!.whiteClipped, isFalse);
            expect(reading.sample!.patchSizePx, closeTo(2.5 / 2.75 * 60, 1.5), reason: 'angle $angle');
          }
        }
      }
    });

    test('a mirrored Classic is oriented', () {
      for (final angle in const [-30.0, 110.0]) {
        final chart = classicChart(mirrored: true, angleDeg: angle);
        _expectOriented(
            readChart(chart.rgba, chart.width, chart.height, _tapsNear(chart.corners), reference: _classic), chart,
            colours: _classicSrgb, reference: _classic);
      }
    });

    test("the Classic's centres are its cells: one assignment of the eight gives them", () {
      final chart = classicChart(angleDeg: 0);
      var hits = 0;
      for (var rotation = 0; rotation < 4; rotation++) {
        for (final mirrored in [false, true]) {
          final c = gridCentres(chart.corners, reference: _classic, rotation: rotation, mirrored: mirrored);
          expect(c, hasLength(24));
          var worst = 0.0;
          for (var k = 0; k < 24; k++) {
            worst = math.max(worst, (c[k] - chart.truth[k]).distance);
          }
          if (worst < 1e-6) hits++;
        }
      }
      expect(hits, 1);
    });

    test("a Classic's clipped white (patch 19) is refused", () {
      final chart = classicChart(white: const [255, 254, 251]);
      final reading = readChart(chart.rgba, chart.width, chart.height, _tapsNear(chart.corners), reference: _classic);
      expect(reading.refusal, refusalWhiteClipped);
      expect(reading.sample!.whiteClipped, isTrue);
      expect(reading.sample!.clipped, [for (var k = 0; k < 24; k++) k == 18]);
      final fine = classicChart(white: const [253, 250, 248]);
      expect(readChart(fine.rgba, fine.width, fine.height, fine.corners, reference: _classic).refusal, isNull);
    });

    test("a Classic's black (24) 1 L* lighter than patch 23 is still read, the right way up", () {
      final colours = _classicSrgb;
      colours[23] = _greyAbove(colours[22], 1);
      expect(_lightness(colours[23]) - _lightness(colours[22]), inInclusiveRange(0.5, 1.5));
      for (final angle in const [20.0, 200.0]) {
        final chart = _chart(angleDeg: angle, colours: [...colours], patchOfSpacing: _classic.patchOfSpacing);
        _expectOriented(
            readChart(chart.rgba, chart.width, chart.height, _tapsNear(chart.corners), reference: _classic), chart,
            colours: colours, reference: _classic);
      }
    });
  });
}
