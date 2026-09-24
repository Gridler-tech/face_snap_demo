// Face-region sharpness metric used by the Calibration page's focus sweep to
// pick the sharpest lens position. The image decode (dart:ui) stays in the
// page; this is the pure pixel maths, kept separate so it can be unit-tested
// with synthetic buffers instead of real JPEGs.
import 'dart:typed_data';

/// Variance of the Laplacian over the centre crop of a raw RGBA image, skipping
/// the digitally-white background (luma >= 245) so the smooth, high-value area
/// cannot dominate. Higher = sharper. Returns 0 when the crop is too small or
/// has too few non-white pixels to be meaningful (matching the sweep's "no
/// usable face" case).
///
/// [rgba] is tightly-packed RGBA (4 bytes/pixel, [width] * [height] pixels),
/// exactly as `ui.Image.toByteData(rawRgba)` produces.
double faceSharpnessFromRgba(Uint8List rgba, int width, int height) {
  final w = width, h = height;
  final x0 = (w * 0.25).floor(), x1 = (w * 0.75).floor();
  final y0 = (h * 0.20).floor(), y1 = (h * 0.80).floor();
  final cw = x1 - x0, chh = y1 - y0;
  if (cw < 8 || chh < 8) return 0;

  // Grayscale of the crop (BT.601 luma).
  final gray = Uint8List(cw * chh);
  for (var y = 0; y < chh; y++) {
    var src = ((y0 + y) * w + x0) * 4;
    var dst = y * cw;
    for (var x = 0; x < cw; x++) {
      gray[dst++] =
          (rgba[src] * 299 + rgba[src + 1] * 587 + rgba[src + 2] * 114) ~/ 1000;
      src += 4;
    }
  }

  // Variance of the 4-neighbour Laplacian over non-white pixels.
  var sum = 0.0, sumSq = 0.0, n = 0;
  for (var y = 1; y < chh - 1; y++) {
    for (var x = 1; x < cw - 1; x++) {
      final c = gray[y * cw + x];
      if (c >= 245) continue;
      final lap = 4 * c -
          gray[(y - 1) * cw + x] -
          gray[(y + 1) * cw + x] -
          gray[y * cw + x - 1] -
          gray[y * cw + x + 1];
      sum += lap;
      sumSq += lap * lap;
      n++;
    }
  }
  if (n < 1000) return 0;
  final mean = sum / n;
  return sumSq / n - mean * mean;
}
