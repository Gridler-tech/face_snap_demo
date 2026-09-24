// The focus-ring colour communicates sweep progress to the operator: it must
// start red, end green, and move monotonically between the two so the light
// reads as "getting warmer". These lock that contract, and the clamp that lets
// callers hand it a raw shot/total ratio without bounds-checking first.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/util/sweep_color.dart';

/// Red and green channels of a "RRGGBB" hex, for monotonicity checks.
(int r, int g) _rg(String hex) =>
    (int.parse(hex.substring(0, 2), radix: 16),
        int.parse(hex.substring(2, 4), radix: 16));

void main() {
  group('sweepHex', () {
    test('starts fully red', () {
      expect(sweepHex(0), 'FF0000');
    });

    test('ends fully green', () {
      expect(sweepHex(1), '00FF00');
    });

    test('midpoint is amber (both channels high, blue off)', () {
      final (r, g) = _rg(sweepHex(0.5));
      expect(r, 255);
      expect(g, 255);
      expect(sweepHex(0.5).endsWith('00'), isTrue, reason: 'blue stays off');
    });

    test('blue channel is always off', () {
      for (final t in [0.0, 0.1, 0.37, 0.5, 0.8, 1.0]) {
        expect(sweepHex(t).substring(4), '00');
      }
    });

    test('red falls and green rises monotonically across the sweep', () {
      var lastR = 256, lastG = -1;
      for (var i = 0; i <= 20; i++) {
        final (r, g) = _rg(sweepHex(i / 20));
        expect(r, lessThanOrEqualTo(lastR), reason: 'red never increases');
        expect(g, greaterThanOrEqualTo(lastG), reason: 'green never decreases');
        lastR = r;
        lastG = g;
      }
    });

    test('clamps out-of-range progress instead of overshooting', () {
      expect(sweepHex(-0.5), 'FF0000', reason: 'below 0 pins to the start');
      expect(sweepHex(1.5), '00FF00', reason: 'above 1 pins to the end');
    });

    test('output is always six uppercase hex digits', () {
      final re = RegExp(r'^[0-9A-F]{6}$');
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(re.hasMatch(sweepHex(t)), isTrue, reason: 'bad hex for t=$t');
      }
    });
  });
}
