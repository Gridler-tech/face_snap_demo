// The glare-free tint of the colour calibration (spec 2026-11-02 section 4.4,
// ruling R19): the grey cast of a photo of the card, and the bisection of the
// glare-free white balance that brings its b* to the reference's. Pure Dart:
// the photos come through the caller's [cast] function (the run of Task 12; a
// simulated cast in the tests).
import 'card_reference.dart';
import 'colour_fit.dart';

/// The white balance range both servers accept (K).
const int kWhiteBalanceMin = 2800;
const int kWhiteBalanceMax = 6500;

/// The bisection stops once the b* cast is this small.
const double tintTolerance = 1.0;

/// The cast of a photo's tint greys (patches [srgb8], JSON order, sRGB 0..255):
/// their mean b* and a* after the exposure is taken out ([normalisedLab]) minus
/// the reference's mean b* and a* of the same greys. b* > 0: too warm (yellow).
({double b, double a}) tintCast(List<List<double>> srgb8, CardReference reference) {
  final lab = normalisedLab(srgb8, reference);
  final tint = [for (final id in reference.tintGreys) reference.indexOf(id)];
  double mean(List<double> Function(int) of, int ch) =>
      tint.fold(0.0, (s, k) => s + of(k)[ch]) / tint.length;
  return (
    b: mean((k) => lab[k], 2) - mean((k) => reference.lab[k], 2),
    a: mean((k) => lab[k], 1) - mean((k) => reference.lab[k], 1),
  );
}

/// [kelvin] rounded to a multiple of 50, half up.
int roundTo50(double kelvin) => (kelvin / 50 + 0.5).floor() * 50;

class TintResult {
  TintResult({
    required this.start,
    required this.kelvin,
    required this.deltaB,
    required this.deltaA,
    required this.photos,
  });

  /// The setting the bisection began at (brought into 2800..6500), and its result:
  /// the measured setting with the smallest |Δb*|, rounded to 50 K and kept in range.
  final int start, kelvin;

  /// The cast measured at the chosen setting: b* (what the white balance moves)
  /// and a* (green ↔ magenta, reported only).
  final double deltaB, deltaA;

  /// The photos taken.
  final int photos;
}

/// The bisection of the glare-free white balance (spec 4.4, R19) over
/// 2800..6500 K, starting at [start]. [cast] takes one photo at a setting and
/// returns its [tintCast]. A higher setting makes the photo warmer (b* up), so
/// a positive cast lowers the setting: the measured setting becomes the upper
/// bound, a negative cast the lower bound, and the next setting is the middle
/// (integer). Stops at |Δb*| <= 1.0, after [maxPhotos] photos, or when the next
/// setting was measured already. The result is the measured setting with the
/// smallest |Δb*| (ties: the first), rounded to 50 K half up, kept in range.
Future<TintResult> searchWhiteBalance({
  required int start,
  required Future<({double b, double a})> Function(int kelvin) cast,
  int maxPhotos = 5,
}) async {
  if (maxPhotos < 1) throw ArgumentError.value(maxPhotos, 'maxPhotos', 'the search needs a photo');
  final first = start.clamp(kWhiteBalanceMin, kWhiteBalanceMax);
  var low = kWhiteBalanceMin, high = kWhiteBalanceMax;
  final measured = <int>{};
  var k = first;
  int? bestK;
  late ({double b, double a}) bestCast;
  while (measured.length < maxPhotos && measured.add(k)) {
    final c = await cast(k);
    if (bestK == null || c.b.abs() < bestCast.b.abs()) {
      bestK = k;
      bestCast = c;
    }
    if (c.b.abs() <= tintTolerance) break;
    if (c.b > 0) {
      high = k;
    } else {
      low = k;
    }
    k = (low + high) ~/ 2;
  }
  return TintResult(
    start: first,
    kelvin: roundTo50(bestK!.toDouble()).clamp(kWhiteBalanceMin, kWhiteBalanceMax),
    deltaB: bestCast.b,
    deltaA: bestCast.a,
    photos: measured.length,
  );
}
