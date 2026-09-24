// Colour of the focus indicator ring while the Calibration page runs its
// sharpness sweep: it drives red -> amber -> green as the search converges, so
// the operator reads progress off the light itself. Pure maths, kept out of the
// page so it can be unit-tested directly.

/// Focus-indicator colour for sweep progress `t` (0 = start, 1 = pinpoint):
/// red -> amber -> green as a RRGGBB hex (hue 0deg..120deg at full saturation).
/// `t` is clamped to 0..1, so callers may pass a raw shot/total ratio.
String sweepHex(double t) {
  final h = 120.0 * t.clamp(0.0, 1.0) / 60.0; // 0..2
  final x = 1 - (h % 2 - 1).abs();
  final double r, g;
  if (h < 1) {
    r = 1;
    g = x;
  } else {
    r = x;
    g = 1;
  }
  String c(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '${c(r)}${c(g)}00'.toUpperCase();
}
