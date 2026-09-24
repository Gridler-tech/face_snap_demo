// Read a JPEG's pixel size from its SOF marker without decoding the image.
// Used by the Capture page to label the delivered (cropped) photo's resolution.
// Kept as a pure, dependency-free library so it can be unit-tested directly
// (the Capture page's widget code cannot).
import 'dart:typed_data';

/// Pixel size of a JPEG read from its SOF (Start Of Frame) marker — the actual
/// resolution of the delivered photo, without decoding the pixels. Returns null
/// if the bytes are not a JPEG we can parse.
(int width, int height)? jpegDimensions(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;
  var i = 2;
  while (i + 1 < b.length) {
    if (b[i] != 0xFF) {
      i++;
      continue;
    }
    // Skip fill bytes (runs of 0xFF).
    while (i < b.length && b[i] == 0xFF) {
      i++;
    }
    if (i >= b.length) break;
    final marker = b[i++];
    // Standalone markers (SOI/EOI/RSTn/TEM) carry no length segment.
    if (marker == 0xD8 ||
        marker == 0xD9 ||
        marker == 0x01 ||
        (marker >= 0xD0 && marker <= 0xD7)) {
      continue;
    }
    if (i + 1 >= b.length) break;
    final segLen = (b[i] << 8) | b[i + 1];
    // SOF0..SOF15 (except DHT 0xC4, JPG 0xC8, DAC 0xCC) hold the frame size.
    final isSof = marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (isSof) {
      if (i + 6 >= b.length) return null;
      final height = (b[i + 3] << 8) | b[i + 4];
      final width = (b[i + 5] << 8) | b[i + 6];
      return (width, height);
    }
    if (segLen < 2) return null; // malformed
    i += segLen;
  }
  return null;
}

/// "700 × 900 px" for a JPEG, or null when the size can't be read.
String? resolutionLabel(Uint8List bytes) {
  final size = jpegDimensions(bytes);
  return size == null ? null : '${size.$1} × ${size.$2} px';
}
