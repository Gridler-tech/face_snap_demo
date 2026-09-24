// The focus sweep picks the lens position with the highest face sharpness, so
// the metric must (1) rank a crisp image above a smooth/blurred one, (2) read
// zero on a flat field, (3) ignore the digitally-white background, and (4)
// refuse crops too small or too sparse to be meaningful. These drive the pure
// pixel maths directly with synthetic RGBA — no JPEG decode, fully
// deterministic.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/util/sharpness.dart';

/// Build a tightly-packed RGBA buffer whose every channel is `gray(x, y)`
/// (so BT.601 luma == that value exactly), alpha opaque.
Uint8List _rgba(int w, int h, int Function(int x, int y) gray) {
  final b = Uint8List(w * h * 4);
  var i = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final g = gray(x, y);
      b[i++] = g;
      b[i++] = g;
      b[i++] = g;
      b[i++] = 255;
    }
  }
  return b;
}

/// A checkerboard alternating [lo]/[hi] every pixel — maximum spatial
/// frequency. Over the centre crop (dimensions even) its Laplacian is exactly
/// +/-4*(hi-lo) with a zero mean, so the variance is 16*(hi-lo)^2.
int Function(int, int) _checker(int lo, int hi) =>
    (x, y) => (x + y).isEven ? lo : hi;

void main() {
  // 100x100 -> centre crop 50x60, interior 48x58 = 2784 samples (> 1000).
  const w = 100, h = 100;

  group('faceSharpnessFromRgba — ranking', () {
    test('flat field has zero sharpness', () {
      expect(faceSharpnessFromRgba(_rgba(w, h, (_, _) => 128), w, h), 0);
    });

    test('a linear ramp (smooth/blurred) reads ~zero', () {
      // Second difference of a linear gradient is 0, so a smoothly varying
      // image scores far below a crisp one — the blurred-photo case.
      final ramp = faceSharpnessFromRgba(_rgba(w, h, (x, _) => x * 2), w, h);
      expect(ramp, lessThan(1));
    });

    test('a crisp checkerboard scores far above a smooth ramp', () {
      final sharp = faceSharpnessFromRgba(_rgba(w, h, _checker(100, 140)), w, h);
      final ramp = faceSharpnessFromRgba(_rgba(w, h, (x, _) => x * 2), w, h);
      expect(sharp, greaterThan(ramp));
      expect(sharp, greaterThan(1000));
    });

    test('higher contrast (sharper edges) scores higher', () {
      final strong = faceSharpnessFromRgba(_rgba(w, h, _checker(100, 140)), w, h);
      final weak = faceSharpnessFromRgba(_rgba(w, h, _checker(120, 130)), w, h);
      expect(strong, greaterThan(weak));
    });

    test('matches the analytic Laplacian variance 16*(hi-lo)^2', () {
      // hi-lo = 40 -> 16 * 1600 = 25600, exactly (balanced checkerboard).
      expect(faceSharpnessFromRgba(_rgba(w, h, _checker(100, 140)), w, h),
          closeTo(25600, 1e-6));
      // hi-lo = 10 -> 16 * 100 = 1600.
      expect(faceSharpnessFromRgba(_rgba(w, h, _checker(120, 130)), w, h),
          closeTo(1600, 1e-6));
    });
  });

  group('faceSharpnessFromRgba — white background is ignored', () {
    test('an all-white crop scores zero even when textured', () {
      // Every pixel >= 245 is skipped, so no samples remain -> 0, regardless of
      // how much high-frequency detail sits in the white area.
      expect(faceSharpnessFromRgba(_rgba(w, h, _checker(248, 255)), w, h), 0);
    });

    test('texture in the non-white region still registers', () {
      // Left 70% of each row is a crisp non-white checkerboard, the rest is the
      // white background; the face texture must still produce a positive score.
      int gray(int x, int y) =>
          x < (w * 0.7) ? ((x + y).isEven ? 100 : 140) : 255;
      expect(faceSharpnessFromRgba(_rgba(w, h, gray), w, h), greaterThan(0));
    });
  });

  group('faceSharpnessFromRgba — guards', () {
    test('a crop under 8px returns zero', () {
      // 10x10 -> crop 5x6, below the 8px floor.
      expect(faceSharpnessFromRgba(_rgba(10, 10, _checker(0, 200)), 10, 10), 0);
    });

    test('fewer than 1000 usable samples returns zero', () {
      // 60x60 -> interior 28x34 = 952 samples, just under the floor, so even a
      // full checkerboard is rejected as too sparse to trust.
      expect(faceSharpnessFromRgba(_rgba(60, 60, _checker(0, 200)), 60, 60), 0);
    });
  });
}
