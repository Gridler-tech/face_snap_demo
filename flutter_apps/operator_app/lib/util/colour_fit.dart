// Photo colour correction, measured by the operator app (spec 2026-10-13
// sections 4.1 and 4.3): the colour maths, the 3x3 fit and the reading of a
// SpyderCheckr 24 or a ColorChecker Classic from four taps on its corner
// patches (spec 2026-11-02 section 4.6). Pure maths (dart:ui
// only for Offset), the same as tools/colorchecker/cc_probe.py: the fit is
// held to cc_probe's fit_ccm by tools/colorchecker/fixtures/colour_fit_cases.json.
//
// Every matrix is BUILT here in double precision from the fixture's constants
// (sRGB primaries, the two whites, the Bradford cone matrix), never pasted
// from a rounded published table: those miss the shared 1e-6 tolerance.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'card_reference.dart';

// ---------------------------------------------------------------------------
// Constants (cc_probe.py's, from OpenCV's ccm module)
// ---------------------------------------------------------------------------

/// sRGB curve: cc_probe's (OpenCV ccm sRGBBase_), with a continuous linear
/// segment; NOT the textbook 0.04045 / 12.92 pair.
const double srgbA = 0.055;
const double srgbGamma = 2.4;
const double _srgbAlpha = srgbA + 1.0;
final double srgbK0 = srgbA / (srgbGamma - 1.0);
final double srgbPhi = (math.pow(_srgbAlpha, srgbGamma) *
        math.pow(srgbGamma - 1.0, srgbGamma - 1.0)) /
    (math.pow(srgbA, srgbGamma - 1.0) * math.pow(srgbGamma, srgbGamma));
final double srgbBeta = srgbK0 / srgbPhi;

const List<double> whiteD65 = [0.95047, 1.0, 1.08883];
const List<double> whiteD50 = [0.9642119944211994, 1.0, 0.8251882845188288];
const List<List<double>> bradfordCone = [
  [0.8951, 0.2664, -0.1614],
  [-0.7502, 1.7135, 0.0367],
  [0.0389, -0.0685, 1.0296],
];
const List<List<double>> srgbPrimariesXy = [
  [0.64, 0.33],
  [0.30, 0.60],
  [0.15, 0.06],
];
const double labDelta = 6.0 / 29.0;

/// Rec. 709 luminance weights of linear RGB (the exposure reference).
const List<double> _rec709Y = [0.2126, 0.7152, 0.0722];

/// The tap flow's floor (px) for a tapped photo: its whole-patch estimate
/// ([PatchSample.patchSizePx], about 0.9 of the centre spacing) under this
/// refuses with [refusalTooSmall], so the sample square read at each centre
/// (half the centre spacing) keeps enough pixels. The value is cc_probe's
/// MIN_RELIABLE_PATCH_PX; it is not the card detector's limit any more:
/// Calibrate's floor is `minPatchSizePx` (34 px per whole patch, ruling P5)
/// in services/colour_calibration.dart.
const double minReliablePatchPx = 17;

/// The SpyderCheckr white rule: a channel is clipped when more than 25 % of
/// its values are 254 or above.
const int spyderClipValue = 254;
const double spyderClipChannelShare = 0.25;

/// Patch side / centre spacing (25 mm patches, 28 mm pitch; ruling R1: the
/// only use of the assumed card geometry).
const double patchSizeOfSpacing = 0.89;

// The refusal texts of the app and the tool (byte-identical with cc_probe's
// FIT_REFUSALS), in the fixture's order.
const String refusalWhiteClipped =
    'the white patch is clipped: tilt the card 10-15° away from the lights';
const String refusalTooSmall = 'the patches are too small: hold the card closer';
const String refusalTaps =
    'the taps do not match the card: tap the four corner patches again';
const String refusalNoImprovement = 'this correction would not improve the colours';
const String refusalSkinWorse = 'this correction would make the skin colours worse';
const List<String> colourFitRefusals = [
  refusalWhiteClipped,
  refusalTooSmall,
  refusalTaps,
  refusalNoImprovement,
  refusalSkinWorse,
];

/// The skin guard (spec 2026-11-02 section 10, cc_probe's SKIN_WORSE_TOLERANCE and
/// SKIN_WEIGHT_STEPS): a correction is kept only when no usable skin patch gets more
/// than this (dE2000) worse; the skin weight of the fit is raised through
/// [skinWeightSteps] while the fit makes a skin patch worse or does not lower the
/// score at the standard weights (ruling F6), then the weight-48 fit is refused.
const double skinWorseTolerance = 0.5;
const List<double> skinWeightSteps = [3, 6, 12, 24, 48];

/// The darkest grey (the black, 6E / 24) may read at most this much (L*) lighter
/// than the grey before it: a black that reflects the lights (the servers'
/// BLACK_TOLERANCE_L).
const double blackToleranceL = 3.0;

/// The greys' L* darken white -> black: every step but the last strictly, the
/// last (the black) at most [blackToleranceL] lighter than the grey before it
/// (the servers' greys_darken). A card turned 180° still fails on its first
/// steps; NaN fails.
bool greysDarken(List<double> lightness) {
  final n = lightness.length;
  if (n < 2) return true;
  for (var i = 0; i + 2 < n; i++) {
    if (!(lightness[i] > lightness[i + 1])) return false;
  }
  return lightness[n - 1] <= lightness[n - 2] + blackToleranceL;
}

// ---------------------------------------------------------------------------
// Small linear algebra (row-major List<List<double>>)
// ---------------------------------------------------------------------------

/// Solves a x = b by Gaussian elimination with partial pivoting. Returns null
/// when a pivot is (relatively) zero: the system is singular.
List<double>? _solve(List<List<double>> a, List<double> b) {
  final n = b.length;
  final m = [
    for (var i = 0; i < n; i++) [...a[i], b[i]],
  ];
  var scale = 0.0;
  for (final row in a) {
    for (final v in row) {
      scale = math.max(scale, v.abs());
    }
  }
  if (scale == 0) return null;
  for (var col = 0; col < n; col++) {
    var piv = col;
    for (var r = col + 1; r < n; r++) {
      if (m[r][col].abs() > m[piv][col].abs()) piv = r;
    }
    if (m[piv][col].abs() <= scale * 1e-12) return null;
    if (piv != col) {
      final t = m[piv];
      m[piv] = m[col];
      m[col] = t;
    }
    for (var r = col + 1; r < n; r++) {
      final f = m[r][col] / m[col][col];
      if (f == 0) continue;
      for (var c = col; c <= n; c++) {
        m[r][c] -= f * m[col][c];
      }
    }
  }
  final x = List<double>.filled(n, 0);
  for (var r = n - 1; r >= 0; r--) {
    var s = m[r][n];
    for (var c = r + 1; c < n; c++) {
      s -= m[r][c] * x[c];
    }
    x[r] = s / m[r][r];
  }
  return x;
}

List<List<double>> _inverse(List<List<double>> a) {
  final n = a.length;
  final cols = [
    for (var j = 0; j < n; j++)
      _solve(a, [for (var i = 0; i < n; i++) i == j ? 1.0 : 0.0])!,
  ];
  return [
    for (var i = 0; i < n; i++) [for (var j = 0; j < n; j++) cols[j][i]],
  ];
}

List<List<double>> _matMul(List<List<double>> a, List<List<double>> b) => [
      for (var i = 0; i < a.length; i++)
        [
          for (var j = 0; j < b[0].length; j++)
            [for (var k = 0; k < b.length; k++) a[i][k] * b[k][j]]
                .fold(0.0, (s, v) => s + v),
        ],
    ];

List<double> _matVec(List<List<double>> m, List<double> v) => [
      for (final row in m) row[0] * v[0] + row[1] * v[1] + row[2] * v[2],
    ];

List<List<double>> _diag(List<double> d) => [
      for (var i = 0; i < d.length; i++)
        [for (var j = 0; j < d.length; j++) i == j ? d[i] : 0.0],
    ];

// ---------------------------------------------------------------------------
// The colour space matrices, built from the constants
// ---------------------------------------------------------------------------

List<List<double>> _rgbToXyzMatrix() {
  // columns (x/y, 1, (1-x-y)/y) per primary, each scaled so R=G=B=1 is white
  final cols = [
    for (final p in srgbPrimariesXy) [p[0] / p[1], 1.0, (1.0 - p[0] - p[1]) / p[1]],
  ];
  final m = [
    for (var i = 0; i < 3; i++) [for (var j = 0; j < 3; j++) cols[j][i]],
  ];
  final s = _solve(m, whiteD65)!;
  return [
    for (var i = 0; i < 3; i++) [for (var j = 0; j < 3; j++) m[i][j] * s[j]],
  ];
}

final List<List<double>> _mRgbToXyz65 = _rgbToXyzMatrix();
final List<List<double>> _mXyz65ToRgb = _inverse(_mRgbToXyz65);
final List<List<double>> _mD65ToD50 = () {
  final bw50 = _matVec(bradfordCone, whiteD50);
  final bw65 = _matVec(bradfordCone, whiteD65);
  return _matMul(
      _matMul(_inverse(bradfordCone), _diag([for (var i = 0; i < 3; i++) bw50[i] / bw65[i]])),
      bradfordCone);
}();
final List<List<double>> _mD50ToD65 = _inverse(_mD65ToD50);

// ---------------------------------------------------------------------------
// Curves and conversions
// ---------------------------------------------------------------------------

/// sRGB (0..1, may be outside) -> linear light, cc_probe's srgb_to_linear.
double srgbToLinear(double v) {
  final curve = math.pow((v.abs() + _srgbAlpha - 1.0) / _srgbAlpha, srgbGamma).toDouble();
  if (v > srgbK0) return curve;
  if (v < -srgbK0) return -curve;
  return v / srgbPhi;
}

/// Linear light -> sRGB (0..1, not clipped), cc_probe's linear_to_srgb.
double linearToSrgb(double v) {
  final pos = _srgbAlpha * math.pow(v.abs(), 1.0 / srgbGamma) - (_srgbAlpha - 1.0);
  if (v > srgbBeta) return pos;
  if (v < -srgbBeta) return -pos;
  return v * srgbPhi;
}

double _labF(double t) => t > labDelta * labDelta * labDelta
    ? math.pow(t, 1.0 / 3.0).toDouble()
    : t / (3 * labDelta * labDelta) + 4.0 / 29.0;

double _labFInv(double f) =>
    f > labDelta ? f * f * f : 3 * labDelta * labDelta * (f - 4.0 / 29.0);

/// Linear sRGB (D65) -> XYZ D65 -> Bradford -> XYZ D50 -> Lab D50.
List<double> linearSrgbToLabD50(List<double> lin) {
  final xyz = _matVec(_mD65ToD50, _matVec(_mRgbToXyz65, lin));
  final fx = _labF(xyz[0] / whiteD50[0]);
  final fy = _labF(xyz[1] / whiteD50[1]);
  final fz = _labF(xyz[2] / whiteD50[2]);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

/// Lab D50 -> XYZ D50 -> Bradford -> XYZ D65 -> linear sRGB.
List<double> labD50ToLinearSrgb(List<double> lab) {
  final fy = (lab[0] + 16) / 116;
  final fx = fy + lab[1] / 500;
  final fz = fy - lab[2] / 200;
  final xyz50 = [
    _labFInv(fx) * whiteD50[0],
    _labFInv(fy) * whiteD50[1],
    _labFInv(fz) * whiteD50[2],
  ];
  return _matVec(_mXyz65ToRgb, _matVec(_mD50ToD65, xyz50));
}

double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;

/// CIEDE2000 (Sharma, Wu, Dalal 2005), kL = kC = kH = 1.
double deltaE2000(List<double> lab1, List<double> lab2) {
  final l1 = lab1[0], a1 = lab1[1], b1 = lab1[2];
  final l2 = lab2[0], a2 = lab2[1], b2 = lab2[2];
  final c1 = math.sqrt(a1 * a1 + b1 * b1);
  final c2 = math.sqrt(a2 * a2 + b2 * b2);
  final cBar7 = math.pow((c1 + c2) / 2, 7);
  final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + math.pow(25.0, 7))));
  final a1p = (1 + g) * a1, a2p = (1 + g) * a2;
  final c1p = math.sqrt(a1p * a1p + b1 * b1);
  final c2p = math.sqrt(a2p * a2p + b2 * b2);
  final h1p = (a1p == 0 && b1 == 0) ? 0.0 : _deg(math.atan2(b1, a1p)) % 360;
  final h2p = (a2p == 0 && b2 == 0) ? 0.0 : _deg(math.atan2(b2, a2p)) % 360;
  final dLp = l2 - l1;
  final dCp = c2p - c1p;
  final zeroChroma = c1p * c2p == 0;
  var dh = h2p - h1p;
  if (dh > 180) {
    dh -= 360;
  } else if (dh < -180) {
    dh += 360;
  }
  if (zeroChroma) dh = 0;
  final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(_rad(dh / 2));
  final lBarP = (l1 + l2) / 2;
  final cBarP = (c1p + c2p) / 2;
  final hSum = h1p + h2p;
  final double hBarP;
  if (zeroChroma) {
    hBarP = hSum;
  } else if ((h1p - h2p).abs() > 180) {
    hBarP = hSum < 360 ? (hSum + 360) / 2 : (hSum - 360) / 2;
  } else {
    hBarP = hSum / 2;
  }
  final t = 1 -
      0.17 * math.cos(_rad(hBarP - 30)) +
      0.24 * math.cos(_rad(2 * hBarP)) +
      0.32 * math.cos(_rad(3 * hBarP + 6)) -
      0.20 * math.cos(_rad(4 * hBarP - 63));
  final dTheta = 30 * math.exp(-math.pow((hBarP - 275) / 25, 2));
  final cBarP7 = math.pow(cBarP, 7);
  final rc = 2 * math.sqrt(cBarP7 / (cBarP7 + math.pow(25.0, 7)));
  final lm50 = (lBarP - 50) * (lBarP - 50);
  final sl = 1 + 0.015 * lm50 / math.sqrt(20 + lm50);
  final sc = 1 + 0.045 * cBarP;
  final sh = 1 + 0.015 * cBarP * t;
  final rt = -math.sin(_rad(2 * dTheta)) * rc;
  final x = dLp / sl, y = dCp / sc, z = dHp / sh;
  return math.sqrt(x * x + y * y + z * z + rt * y * z);
}

double _median(List<double> v) {
  final s = [...v]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

// ---------------------------------------------------------------------------
// The fit (spec 4.3; cc_probe.fit_ccm)
// ---------------------------------------------------------------------------

class ColourFit {
  ColourFit({
    required this.matrix,
    required this.meanDeBefore,
    required this.meanDeAfter,
    required this.worstBefore,
    required this.worstAfter,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.deBefore,
    required this.deAfter,
    required this.labAfter,
    this.usable,
    this.skinWeight,
  });

  /// 3x3, row-major, R,G,B, linear light; corrected = M . measured. Each row
  /// sums to 1 (white stays white).
  final List<double> matrix;

  /// dE2000 mean / worst over all 24 patches (unweighted); "before" on the
  /// exposure-normalised measurement (ruling R3), so both compare colour only.
  final double meanDeBefore, meanDeAfter, worstBefore, worstAfter;

  /// The weighted mean dE2000 over the usable patches ([weightedScore]), before (on
  /// the exposure-normalised measurement) and after: what a correction is judged by.
  final double scoreBefore, scoreAfter;

  /// dE2000 per patch (JSON order), before and after.
  final List<double> deBefore, deAfter;

  /// The corrected patches' Lab D50 (JSON order): the skin patches and the grey
  /// row's a*/b* the app shows.
  final List<List<double>> labAfter;

  /// The patches in the fit and the score (null = all of them).
  final List<bool>? usable;

  /// The skin weight the fit used ([fitColourMatrixGuarded]: 3, 6, 12, 24 or 48); null for a
  /// plain [fitColourMatrix].
  final double? skinWeight;
}

/// Why [fit] cannot be saved, null when it can: [refusalNoImprovement] when it does not
/// lower the weighted score (NaN included; the skin patches count 3 times, so the plain
/// mean does not decide) or its matrix is not 9 finite numbers; then [refusalSkinWorse]
/// when a usable skin patch of [reference] is more than [skinWorseTolerance] worse after
/// it (cc_probe's fit_refusal_of, the same order). A fit whose per-patch dE do not cover
/// [reference] cannot be checked and is refused as not improving.
String? colourFitRefusal(ColourFit fit, {required CardReference reference}) {
  if (fit.matrix.length != 9 || fit.matrix.any((v) => !v.isFinite)) return refusalNoImprovement;
  if (!(fit.scoreAfter < fit.scoreBefore)) return refusalNoImprovement;
  final n = reference.ids.length;
  if (fit.deBefore.length != n || fit.deAfter.length != n || (fit.usable != null && fit.usable!.length != n)) {
    return refusalNoImprovement;
  }
  if (!_skinKept(fit.deBefore, fit.deAfter, fit.usable, reference)) return refusalSkinWorse;
  return null;
}

/// No usable skin patch of [reference] is more than [skinWorseTolerance] worse
/// ([usable] null = all usable; NaN counts as worse).
bool _skinKept(List<double> deBefore, List<double> deAfter, List<bool>? usable, CardReference reference) {
  for (final id in reference.skin) {
    final k = reference.indexOf(id);
    if (usable != null && !usable[k]) continue;
    if (!(deAfter[k] <= deBefore[k] + skinWorseTolerance)) return false;
  }
  return true;
}

/// ISO 8601 UTC to the second ("2026-10-20T14:05:00Z"), a measurement's time.
String measuredAt(DateTime time) => '${time.toUtc().toIso8601String().substring(0, 19)}Z';

/// The weighted mean of [de] over the usable patches, sum(w dE) / sum(w): the
/// score a fit is judged by (spec 2026-11-02 section 4.1). Throws [ArgumentError]
/// on mismatched lengths or when no usable patch has a weight.
double weightedScore(List<double> de, List<double> weights, List<bool> usable) {
  if (weights.length != de.length || usable.length != de.length) {
    throw ArgumentError('weightedScore: dE, weights and usable must cover the same patches');
  }
  var sum = 0.0, total = 0.0;
  for (var i = 0; i < de.length; i++) {
    if (!usable[i]) continue;
    sum += weights[i] * de[i];
    total += weights[i];
  }
  if (!(total > 0)) throw ArgumentError('weightedScore: no usable patch has a weight');
  return sum / total;
}

/// The measured patches in linear light with the exposure taken out on the
/// reference's exposure grey (steps 1 and 2 of the fit), and the reference in
/// linear light. Throws [ArgumentError] on mismatched lengths or a black grey.
({List<List<double>> lin, List<List<double>> refLin}) _exposureNormalised(
    List<List<double>> measuredSrgb8, CardReference reference) {
  final ref = reference.lab;
  final greyIndex = reference.exposureGreyIndex;
  if (measuredSrgb8.length != ref.length) {
    throw ArgumentError('fitColourMatrix: measured and reference must cover the same patches');
  }
  var lin = [
    for (final p in measuredSrgb8) [for (final v in p) srgbToLinear(v / 255.0)],
  ];
  final refLin = [for (final lab in ref) labD50ToLinearSrgb(lab)];
  double y(List<double> v) => v[0] * _rec709Y[0] + v[1] * _rec709Y[1] + v[2] * _rec709Y[2];
  final greyY = y(lin[greyIndex]);
  if (!(greyY > 0)) {
    throw ArgumentError('fitColourMatrix: the grey patch is black, no exposure to take out');
  }
  final gain = y(refLin[greyIndex]) / greyY;
  lin = [
    for (final p in lin) [for (final v in p) v * gain],
  ];
  return (lin: lin, refLin: refLin);
}

/// The measured patches as Lab D50 with the exposure taken out on the
/// reference's exposure grey (steps 1 and 2 of the fit, then Lab): what the
/// glare-free tint step reads the grey casts from. JSON order.
List<List<double>> normalisedLab(List<List<double>> measuredSrgb8, CardReference reference) =>
    [for (final p in _exposureNormalised(measuredSrgb8, reference).lin) linearSrgbToLabD50(p)];

/// The 3x3 colour matrix that brings the measured card patches closest to
/// [reference]'s Lab in linear light, each row summing to 1; the exposure is
/// taken out on the reference's exposure grey first.
///
/// [measuredSrgb8]: 24 x 3 R,G,B sRGB 0..255 patch means, JSON order;
/// [usable]: the patches that enter the least squares and the score (clipped
/// ones left out); [weights]: one per patch, default [CardReference.weights]
/// (skin 3, the others 1). The mean and the worst dE stay unweighted over all
/// 24; the score ([ColourFit.scoreBefore]) is the weighted mean over the usable
/// patches. Throws [ArgumentError] on mismatched lengths, fewer than 3 usable
/// patches, a negative or non-finite weight, no weight on the usable patches,
/// or a black grey patch.
ColourFit fitColourMatrix(List<List<double>> measuredSrgb8, List<bool> usable,
    {required CardReference reference, List<double>? weights}) {
  final ref = reference.lab;
  final w = weights ?? reference.weights;
  if (measuredSrgb8.length != ref.length || usable.length != ref.length || w.length != ref.length) {
    throw ArgumentError('fitColourMatrix: measured, reference, usable and weights must cover the same patches');
  }
  if (usable.where((u) => u).length < 3) {
    throw ArgumentError('fitColourMatrix: fewer than 3 usable patches');
  }
  if (w.any((v) => !v.isFinite || v < 0)) {
    throw ArgumentError('fitColourMatrix: a weight is negative or not finite');
  }
  final (:lin, :refLin) = _exposureNormalised(measuredSrgb8, reference);

  // [[2 A'WA, 1], [1', 0]] [m_k; lambda] = [2 A'W t_k; 1] per output channel k
  final ata = List.generate(3, (_) => List<double>.filled(3, 0));
  final att = List.generate(3, (_) => List<double>.filled(3, 0)); // [k][i] = sum w a_i t_k
  for (var p = 0; p < lin.length; p++) {
    if (!usable[p]) continue;
    final a = lin[p], t = refLin[p];
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        ata[i][j] += w[p] * a[i] * a[j];
      }
      for (var k = 0; k < 3; k++) {
        att[k][i] += w[p] * a[i] * t[k];
      }
    }
  }
  final kkt = [
    for (var i = 0; i < 3; i++) [for (var j = 0; j < 3; j++) 2.0 * ata[i][j], 1.0],
    [1.0, 1.0, 1.0, 0.0],
  ];
  final matrix = <double>[];
  for (var k = 0; k < 3; k++) {
    final x = _solve(kkt, [for (var i = 0; i < 3; i++) 2.0 * att[k][i], 1.0]);
    if (x == null) {
      throw ArgumentError('fitColourMatrix: the usable patches do not span the colours');
    }
    matrix.addAll(x.sublist(0, 3));
  }
  final m = [
    for (var r = 0; r < 3; r++) matrix.sublist(3 * r, 3 * r + 3),
  ];
  final deBefore = <double>[], deAfter = <double>[];
  final labAfter = <List<double>>[];
  for (var p = 0; p < lin.length; p++) {
    deBefore.add(deltaE2000(linearSrgbToLabD50(lin[p]), ref[p]));
    final lab = linearSrgbToLabD50(_matVec(m, lin[p]));
    labAfter.add(lab);
    deAfter.add(deltaE2000(lab, ref[p]));
  }
  double mean(List<double> v) => v.fold(0.0, (s, x) => s + x) / v.length;
  return ColourFit(
    matrix: matrix,
    meanDeBefore: mean(deBefore),
    meanDeAfter: mean(deAfter),
    worstBefore: deBefore.reduce(math.max),
    worstAfter: deAfter.reduce(math.max),
    scoreBefore: weightedScore(deBefore, w, usable),
    scoreAfter: weightedScore(deAfter, w, usable),
    deBefore: deBefore,
    deAfter: deAfter,
    labAfter: labAfter,
    usable: List.unmodifiable(usable),
  );
}

/// The fit that is saved (spec 2026-11-02 section 10; cc_probe's fit_guarded):
/// [fitColourMatrix] with [reference]'s skin patches weighted 3, then 6, 12, 24, 48
/// ([skinWeightSteps], the others 1); the first fit where every usable skin patch
/// has dE after <= dE before + [skinWorseTolerance] AND the score at the standard
/// weights goes down (ruling F6) is returned, else the weight-48 fit (which
/// [colourFitRefusal] then refuses). Its scores are recomputed with
/// [CardReference.weights] (skin 3) whatever weight the fit used, so runs compare;
/// [ColourFit.skinWeight] says which. Throws as [fitColourMatrix]. The LED mix
/// search keeps the plain fit: the guard only decides what is saved.
ColourFit fitColourMatrixGuarded(List<List<double>> measuredSrgb8, List<bool> usable,
    {required CardReference reference}) {
  final standard = reference.weights;
  late ColourFit guarded;
  for (final w in skinWeightSteps) {
    final fit = fitColourMatrix(measuredSrgb8, usable,
        reference: reference, weights: [for (final id in reference.ids) reference.skin.contains(id) ? w : 1.0]);
    guarded = ColourFit(
      matrix: fit.matrix,
      meanDeBefore: fit.meanDeBefore,
      meanDeAfter: fit.meanDeAfter,
      worstBefore: fit.worstBefore,
      worstAfter: fit.worstAfter,
      scoreBefore: weightedScore(fit.deBefore, standard, usable),
      scoreAfter: weightedScore(fit.deAfter, standard, usable),
      deBefore: fit.deBefore,
      deAfter: fit.deAfter,
      labAfter: fit.labAfter,
      usable: fit.usable,
      skinWeight: w,
    );
    if (_skinKept(fit.deBefore, fit.deAfter, usable, reference) && guarded.scoreAfter < guarded.scoreBefore) break;
  }
  return guarded;
}

// ---------------------------------------------------------------------------
// The chart from four taps (spec 4.1; ruling R1: taps on the corner patches'
// CENTRES, 1E, 1H, 6H, 6E in any order; the Classic's 1, 19, 24, 6, spec
// 2026-11-02 section 4.6)
// ---------------------------------------------------------------------------

/// The taps in cyclic order around their centroid (by angle, image y down).
List<Offset> _cyclic(List<Offset> taps) {
  final cx = taps.fold(0.0, (s, p) => s + p.dx) / taps.length;
  final cy = taps.fold(0.0, (s, p) => s + p.dy) / taps.length;
  final sorted = [...taps];
  sorted.sort((a, b) =>
      math.atan2(a.dy - cy, a.dx - cx).compareTo(math.atan2(b.dy - cy, b.dx - cx)));
  return sorted;
}

/// The homography (h0..h7, h8 = 1) mapping the unit square's corners (0,0),
/// (1,0), (1,1), (0,1) onto [quad]; null when the quad is degenerate.
List<double>? _homography(List<Offset> quad) {
  const unit = [
    [0.0, 0.0],
    [1.0, 0.0],
    [1.0, 1.0],
    [0.0, 1.0],
  ];
  final a = <List<double>>[];
  final b = <double>[];
  for (var i = 0; i < 4; i++) {
    final u = unit[i][0], v = unit[i][1];
    final x = quad[i].dx, y = quad[i].dy;
    a.add([u, v, 1, 0, 0, 0, -u * x, -v * x]);
    b.add(x);
    a.add([0, 0, 0, u, v, 1, -u * y, -v * y]);
    b.add(y);
  }
  return _solve(a, b);
}

/// [reference]'s patch centres in its JSON order from the four corner-patch
/// taps: the taps are put in cyclic order around their centroid, then assigned
/// to the corner cells (0,0), (3,0), (3,5), (0,5) ([CardReference.cornerIndexes]:
/// 1E, 1H, 6H, 6E on the SpyderCheckr, 1, 19, 24, 6 on the Classic) starting at
/// [rotation] (0..3) and going the other way round when [mirrored]; each patch
/// sits at its cell (across, along). Empty when the taps are not four corners of
/// a convex quadrilateral.
///
/// [frameAcross] and [frameAlong] (in centre spacings, default 0) read the taps
/// as the card's own corners instead: the corner patches' centres lie that far
/// inside them, across the card (cells 0..3) and along it (0..5).
List<Offset> gridCentres(List<Offset> cornerTaps,
    {required CardReference reference,
    int rotation = 0,
    bool mirrored = false,
    double frameAcross = 0,
    double frameAlong = 0}) {
  if (cornerTaps.length != 4) return const [];
  var s = _cyclic(cornerTaps);
  if (!_convex(s)) return const [];
  if (mirrored) s = [s[0], s[3], s[2], s[1]];
  final quad = [for (var i = 0; i < 4; i++) s[(rotation + i) % 4]];
  final h = _homography(quad);
  if (h == null) return const [];
  final cells = reference.cells;
  final lastAcross = cells.fold(0, (m, c) => math.max(m, c.$1));
  final lastAlong = cells.fold(0, (m, c) => math.max(m, c.$2));
  return [
    for (final (across, along) in cells)
      () {
        // the cell inside a frame of the given width
        final u = (across + frameAcross) / (lastAcross + 2 * frameAcross);
        final v = (along + frameAlong) / (lastAlong + 2 * frameAlong);
        final w = h[6] * u + h[7] * v + 1;
        return Offset((h[0] * u + h[1] * v + h[2]) / w, (h[3] * u + h[4] * v + h[5]) / w);
      }(),
  ];
}

/// A strictly convex quadrilateral (vertices in cyclic order) whose corners
/// are not nearly straight: each corner's cross product is at least 1 % of the
/// mean squared side.
bool _convex(List<Offset> q) {
  var sideSq = 0.0;
  for (var i = 0; i < 4; i++) {
    sideSq += (q[(i + 1) % 4] - q[i]).distanceSquared;
  }
  final minCross = 0.01 * sideSq / 4;
  if (!(minCross > 0)) return false;
  int? sign;
  for (var i = 0; i < 4; i++) {
    final e1 = q[(i + 1) % 4] - q[i], e2 = q[(i + 2) % 4] - q[(i + 1) % 4];
    final cross = e1.dx * e2.dy - e1.dy * e2.dx;
    if (cross.abs() < minCross) return false;
    final s = cross > 0 ? 1 : -1;
    if (sign != null && s != sign) return false;
    sign = s;
  }
  return true;
}

class PatchSample {
  PatchSample({
    required this.means,
    required this.clipped,
    required this.patchSizePx,
    required this.sampleSidePx,
    this.whiteIndex = 0,
  });

  /// Mean R, G, B (0..255) over each centre's sample square, in the order of
  /// the centres; 0, 0, 0 for a square wholly outside the image.
  final List<List<double>> means;

  /// Per centre: a channel with more than 25 % of its values >= 254.
  final List<bool> clipped;

  /// The card's patch side / centre spacing (0.89 on the SpyderCheckr, ruling R1)
  /// x the smallest centre spacing, for the 17 px rule.
  final double patchSizePx;

  /// The sample square's side: half the smallest centre spacing.
  final double sampleSidePx;

  /// The centre of the card's white patch (1E, the first, on the SpyderCheckr;
  /// 19 on the Classic).
  final int whiteIndex;

  /// The white patch is clipped.
  bool get whiteClipped => whiteIndex < clipped.length && clipped[whiteIndex];
}

/// Samples [centres] in a tightly-packed RGBA image ([width] x [height], as
/// `ui.Image.toByteData(rawRgba)` gives): the mean R, G, B over a square of
/// side half the smallest centre spacing, centred on each centre (pixel i
/// covers [i, i+1)), clipped to the image. [patchOfSpacing] and [whiteIndex]
/// are the card's ([CardReference.patchOfSpacing], its first grey); the
/// SpyderCheckr's by default.
PatchSample samplePatches(Uint8List rgba, int width, int height, List<Offset> centres,
    {double patchOfSpacing = patchSizeOfSpacing, int whiteIndex = 0}) {
  var spacing = double.infinity;
  for (var i = 0; i < centres.length; i++) {
    for (var j = i + 1; j < centres.length; j++) {
      spacing = math.min(spacing, (centres[i] - centres[j]).distance);
    }
  }
  if (!spacing.isFinite) spacing = 0;
  final side = spacing / 2;
  final means = <List<double>>[];
  final clipped = <bool>[];
  for (final c in centres) {
    // pixels whose centre (i + 0.5) lies in [c - side/2, c + side/2)
    final x0 = math.max(0, (c.dx - side / 2 - 0.5).ceil());
    final x1 = math.min(width - 1, (c.dx + side / 2 - 0.5).ceil() - 1);
    final y0 = math.max(0, (c.dy - side / 2 - 0.5).ceil());
    final y1 = math.min(height - 1, (c.dy + side / 2 - 0.5).ceil() - 1);
    final sum = [0.0, 0.0, 0.0];
    final high = [0, 0, 0];
    var n = 0;
    for (var y = y0; y <= y1; y++) {
      var i = (y * width + x0) * 4;
      for (var x = x0; x <= x1; x++) {
        for (var ch = 0; ch < 3; ch++) {
          final v = rgba[i + ch];
          sum[ch] += v;
          if (v >= spyderClipValue) high[ch]++;
        }
        n++;
        i += 4;
      }
    }
    means.add(n == 0 ? [0.0, 0.0, 0.0] : [for (final s in sum) s / n]);
    clipped.add(n > 0 && high.any((h) => h / n > spyderClipChannelShare));
  }
  return PatchSample(
    means: means,
    clipped: clipped,
    patchSizePx: patchOfSpacing * spacing,
    sampleSidePx: side,
    whiteIndex: whiteIndex,
  );
}

/// How well a grid sits inside its patches: the mean, over the 24 centres, of
/// the RGB standard deviation in a square of 0.7 x the centre spacing (larger
/// than the sample square, smaller than a patch, 0.89 x the spacing). Only a
/// grid centred on the patches keeps every such square inside one colour; for
/// the card-corner reading, where several frame widths fit the colours alike.
double gridSpread(Uint8List rgba, int width, int height, List<Offset> centres) {
  var spacing = double.infinity;
  for (var i = 0; i < centres.length; i++) {
    for (var j = i + 1; j < centres.length; j++) {
      spacing = math.min(spacing, (centres[i] - centres[j]).distance);
    }
  }
  if (!spacing.isFinite || centres.isEmpty) return double.infinity;
  final half = 0.35 * spacing;
  var total = 0.0;
  for (final c in centres) {
    final x0 = math.max(0, (c.dx - half - 0.5).ceil());
    final x1 = math.min(width - 1, (c.dx + half - 0.5).ceil() - 1);
    final y0 = math.max(0, (c.dy - half - 0.5).ceil());
    final y1 = math.min(height - 1, (c.dy + half - 0.5).ceil() - 1);
    final sum = [0.0, 0.0, 0.0], sumSq = [0.0, 0.0, 0.0];
    var n = 0;
    for (var y = y0; y <= y1; y++) {
      var i = (y * width + x0) * 4;
      for (var x = x0; x <= x1; x++) {
        for (var ch = 0; ch < 3; ch++) {
          final v = rgba[i + ch].toDouble();
          sum[ch] += v;
          sumSq[ch] += v * v;
        }
        n++;
        i += 4;
      }
    }
    if (n == 0) return double.infinity; // a square wholly outside the image
    var variance = 0.0;
    for (var ch = 0; ch < 3; ch++) {
      variance += math.max(0, sumSq[ch] / n - (sum[ch] / n) * (sum[ch] / n));
    }
    total += math.sqrt(variance / 3);
  }
  return total / centres.length;
}

/// [gridSpread] over the contrast between the patches (the standard deviation of
/// their mean grey): small when the grid sits inside the patches of a card
/// (0.04-0.09 on the 2026-10-09 trial photos), large on anything else.
double gridFit(Uint8List rgba, int width, int height, ChartReading reading) {
  final means = reading.sample?.means;
  if (means == null || means.isEmpty) return double.infinity;
  final grey = [for (final m in means) (m[0] + m[1] + m[2]) / 3];
  final mean = grey.reduce((a, b) => a + b) / grey.length;
  final contrast = math.sqrt(
      grey.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / grey.length);
  if (contrast <= 0) return double.infinity;
  return gridSpread(rgba, width, height, reading.centres) / contrast;
}

/// A reading whose [gridFit] is above this is no card: refused as the taps.
const double cardLikeLimit = 0.3;

/// A patch-centre reading this well-seated is taken without trying the card's
/// corners (keeps the usual taps as fast as before).
const double onPatchesLimit = 0.15;

class ChartReading {
  ChartReading({
    required this.centres,
    required this.sample,
    required this.refusal,
    this.rotation,
    this.mirrored,
    this.medianDe,
  });

  /// The 24 patch centres, JSON order; empty when the taps are refused.
  final List<Offset> centres;

  /// The patches sampled at [centres] (null when the taps are refused).
  final PatchSample? sample;

  /// One of [colourFitRefusals] (taps, too small, white clipped) or null.
  final String? refusal;

  /// The chosen orientation (see [gridCentres]) and its median dE2000 against
  /// the reference, before any fit.
  final int? rotation;
  final bool? mirrored;
  final double? medianDe;
}

/// The frame widths tried when the taps are read as the card's own corners, in
/// centre spacings beyond the corner patches' centres (0.33 to 0.9 seen on the
/// bench, 2026-10-16, not always the same across and along the card). A step of
/// 0.1 keeps every sample square inside its patch.
const List<double> cardFrameWidths = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];

/// Reads [reference]'s card (the SpyderCheckr 24 or the ColorChecker Classic)
/// from four taps on the centres of its corner patches (1E, 1H, 6H, 6E / 1, 19,
/// 24, 6, any order) or on the card's own corners (operators tap those: the
/// bench, 2026-10-16; the frame widths [cardFrameWidths] across and along the
/// card are tried). Per reading, of the 8 orientations those whose greys darken
/// from the white to the black ([greysDarken]: strictly, the black up to
/// [blackToleranceL] lighter than the grey before it) are kept and the one with the lowest
/// median dE2000 (against the reference, before any fit) is chosen, as
/// cc_probe.spyder_orient; of the readings that look like a card ([gridFit] at
/// most [cardLikeLimit]), the one whose grid sits best inside the patches; the
/// card-corner readings are tried only when the patch-centre one does not sit
/// well ([onPatchesLimit]). Refusals, in this order: the taps (nothing
/// qualifies), the patches too small (the card's patch side,
/// [CardReference.patchOfSpacing]), the white patch clipped. "Would not
/// improve" is the caller's, after the fit.
ChartReading readChart(Uint8List rgba, int width, int height, List<Offset> taps,
    {required CardReference reference}) {
  // The taps as the corner patches' centres (frame 0) first; when that grid does
  // not sit well inside the patches, also as the card's own corners (every frame
  // width). Per reading the best orientation by colour; of the readings that look
  // like a card ([cardLikeLimit]), the one whose grid sits best. Colour alone
  // cannot decide: a grid half a patch off still sees the greys darken, and frame
  // widths that keep the sample squares inside tie.
  ChartReading? best;
  var bestFit = double.infinity;
  void consider(double across, double along) {
    final reading = _readChart(rgba, width, height, taps, across, along, reference);
    if (reading.refusal == refusalTaps) return;
    final fit = gridFit(rgba, width, height, reading);
    if (fit > cardLikeLimit) return;
    if (best == null || fit < bestFit || (fit == bestFit && reading.medianDe! < best!.medianDe!)) {
      best = reading;
      bestFit = fit;
    }
  }

  consider(0, 0);
  if (bestFit > onPatchesLimit) {
    for (final across in cardFrameWidths) {
      for (final along in cardFrameWidths) {
        consider(across, along);
      }
    }
  }
  return best ?? ChartReading(centres: const [], sample: null, refusal: refusalTaps);
}

ChartReading _readChart(Uint8List rgba, int width, int height, List<Offset> taps,
    double frameAcross, double frameAlong, CardReference reference) {
  final greys = reference.greyIndexes;
  List<Offset>? bestCentres;
  PatchSample? bestSample;
  int? bestRotation;
  bool? bestMirrored;
  var bestMedian = double.infinity;
  {
    for (var rotation = 0; rotation < 4; rotation++) {
      for (final mirrored in [false, true]) {
        final centres = gridCentres(taps,
            reference: reference,
            rotation: rotation,
            mirrored: mirrored,
            frameAcross: frameAcross,
            frameAlong: frameAlong);
        if (centres.length != reference.cells.length) continue;
        final sample = samplePatches(rgba, width, height, centres,
            patchOfSpacing: reference.patchOfSpacing, whiteIndex: greys.first);
        final lab = [
          for (final m in sample.means)
            linearSrgbToLabD50([for (final v in m) srgbToLinear(v / 255.0)]),
        ];
        if (!greysDarken([for (final g in greys) lab[g][0]])) continue;
        final median = _median([for (var k = 0; k < lab.length; k++) deltaE2000(lab[k], reference.lab[k])]);
        if (median < bestMedian) {
          bestMedian = median;
          bestCentres = centres;
          bestSample = sample;
          bestRotation = rotation;
          bestMirrored = mirrored;
        }
      }
    }
  }
  if (bestCentres == null || bestSample == null) {
    return ChartReading(centres: const [], sample: null, refusal: refusalTaps);
  }
  String? refusal;
  if (bestSample.patchSizePx < minReliablePatchPx) {
    refusal = refusalTooSmall;
  } else if (bestSample.whiteClipped) {
    refusal = refusalWhiteClipped;
  }
  return ChartReading(
    centres: bestCentres,
    sample: bestSample,
    refusal: refusal,
    rotation: bestRotation,
    mirrored: bestMirrored,
    medianDe: bestMedian,
  );
}
