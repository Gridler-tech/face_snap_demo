// The Capture page labels each delivered photo with its pixel size, read
// straight from the JPEG's SOF marker (no decode). The parser is hand-rolled
// byte scanning, so it must survive the shapes a real camera JPEG takes —
// EXIF/APP segments before the frame, 0xFF fill bytes, standalone markers —
// and refuse anything that is not a frame it can measure rather than returning
// a bogus size.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/util/jpeg_size.dart';

/// A length-prefixed JPEG segment: 0xFF, [marker], 2-byte length, payload.
/// The length field counts itself + the payload (JPEG convention).
List<int> _segment(int marker, List<int> payload) {
  final len = payload.length + 2;
  return [0xFF, marker, (len >> 8) & 0xFF, len & 0xFF, ...payload];
}

/// An SOF segment (marker 0xC0..0xCF) declaring [width] x [height]. Layout:
/// precision(1), height(2 BE), width(2 BE), then component bytes we don't read.
List<int> _sof(int marker, int width, int height) => _segment(marker, [
      8, // sample precision
      (height >> 8) & 0xFF, height & 0xFF,
      (width >> 8) & 0xFF, width & 0xFF,
      1, 0x11, 0, // one component (ignored by the parser)
    ]);

const _soi = [0xFF, 0xD8];

Uint8List _bytes(List<int> parts) => Uint8List.fromList(parts);

void main() {
  group('jpegDimensions', () {
    test('reads a plain baseline JPEG (SOF0)', () {
      final jpeg = _bytes([..._soi, ..._sof(0xC0, 700, 900)]);
      expect(jpegDimensions(jpeg), (700, 900));
    });

    test('width and height are not transposed', () {
      // The delivered crop is portrait; a transposition bug would read 900x700.
      final jpeg = _bytes([..._soi, ..._sof(0xC0, 700, 900)]);
      final size = jpegDimensions(jpeg)!;
      expect(size.$1, 700, reason: 'width from bytes 5-6 of the SOF payload');
      expect(size.$2, 900, reason: 'height from bytes 3-4 of the SOF payload');
    });

    test('skips APP0 (JFIF) and APP1 (EXIF) segments before the frame', () {
      final jpeg = _bytes([
        ..._soi,
        ..._segment(0xE0, List.filled(14, 0)), // APP0/JFIF
        ..._segment(0xE1, List.filled(120, 0x7F)), // APP1/EXIF blob
        ..._segment(0xDB, List.filled(65, 0)), // DQT
        ..._sof(0xC0, 4000, 3000),
      ]);
      expect(jpegDimensions(jpeg), (4000, 3000));
    });

    test('reads a progressive JPEG (SOF2)', () {
      final jpeg = _bytes([..._soi, ..._sof(0xC2, 1024, 768)]);
      expect(jpegDimensions(jpeg), (1024, 768));
    });

    test('does not mistake DHT (0xC4) for a frame', () {
      // 0xC4 is inside the 0xC0..0xCF range but is a Huffman table, not an SOF.
      // A naive range check would read its bytes as a size.
      final jpeg = _bytes([
        ..._soi,
        ..._segment(0xC4, List.filled(30, 0)), // DHT
        ..._sof(0xC1, 640, 480), // real frame (extended sequential)
      ]);
      expect(jpegDimensions(jpeg), (640, 480));
    });

    test('tolerates 0xFF fill bytes before a marker', () {
      final jpeg = _bytes([
        ..._soi,
        ..._segment(0xE0, [0, 0]),
        0xFF, 0xFF, 0xFF, // fill run
        ..._sof(0xC0, 320, 240),
      ]);
      expect(jpegDimensions(jpeg), (320, 240));
    });

    test('steps over standalone RSTn markers with no length', () {
      final jpeg = _bytes([
        ..._soi,
        0xFF, 0xD0, // RST0 — no length segment follows
        ..._sof(0xC0, 100, 200),
      ]);
      expect(jpegDimensions(jpeg), (100, 200));
    });
  });

  group('jpegDimensions rejects non-frames', () {
    test('empty input', () {
      expect(jpegDimensions(_bytes([])), isNull);
    });

    test('too short to be a JPEG', () {
      expect(jpegDimensions(_bytes([0xFF, 0xD8])), isNull);
    });

    test('not a JPEG (wrong SOI)', () {
      expect(jpegDimensions(_bytes([0x89, 0x50, 0x4E, 0x47])), isNull); // PNG
    });

    test('SOI only, no frame', () {
      final jpeg = _bytes([
        ..._soi,
        ..._segment(0xE0, List.filled(14, 0)),
        ..._segment(0xDB, List.filled(65, 0)),
      ]);
      expect(jpegDimensions(jpeg), isNull);
    });

    test('truncated inside the SOF segment', () {
      // SOF marker present but the height/width bytes are cut off.
      final jpeg = _bytes([..._soi, 0xFF, 0xC0, 0x00, 0x11, 8, 0x03]);
      expect(jpegDimensions(jpeg), isNull);
    });

    test('malformed segment length (< 2) is not an infinite loop', () {
      final jpeg = _bytes([..._soi, 0xFF, 0xE0, 0x00, 0x00, 0xFF, 0xC0]);
      expect(jpegDimensions(jpeg), isNull);
    });
  });

  group('resolutionLabel', () {
    test('formats a parseable JPEG', () {
      final jpeg = _bytes([..._soi, ..._sof(0xC0, 700, 900)]);
      expect(resolutionLabel(jpeg), '700 × 900 px');
    });

    test('null when the size cannot be read', () {
      expect(resolutionLabel(_bytes([0x00, 0x01, 0x02, 0x03])), isNull);
    });
  });
}
