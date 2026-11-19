// The glare-free tint (spec 2026-11-02 section 4.4, ruling R19): the grey cast
// of a photo and the bisection of the glare-free white balance over
// 2800..6500 K, against simulated casts.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/util/card_reference.dart';
import 'package:operator_app/util/colour_fit.dart';
import 'package:operator_app/util/glare_free_tint.dart';

CardReference _read(String card, [String version = '']) => CardReference.fromJson(
    jsonDecode(File('assets/colour_cards/$card.json').readAsStringSync()) as Map<String, dynamic>,
    version: version);

/// The card's patches as sRGB 0..255 (not rounded), each linear value × [gain].
List<List<double>> _photo(CardReference ref, {List<double> gain = const [1, 1, 1], double scale = 0.7}) => [
      for (final lab in ref.lab)
        () {
          final lin = labD50ToLinearSrgb(lab);
          return [for (var ch = 0; ch < 3; ch++) 255 * linearToSrgb(scale * gain[ch] * lin[ch])];
        }(),
    ];

/// A cast linear in the setting, as the bisection sees it.
Future<({double b, double a})> Function(int) _linear(double perKelvin, int neutralAt, List<int> calls,
        {double offset = 0, double a = 0.4}) =>
    (k) async {
      calls.add(k);
      return (b: perKelvin * (k - neutralAt) + offset, a: a);
    };

void main() {
  group('tintCast', () {
    for (final (card, version) in const [('spyder24', ''), ('classic', 'pre2014'), ('classic', '2014')]) {
      final ref = _read(card, version);

      test('$card $version: the reference itself has no cast, at any exposure', () {
        for (final scale in const [0.5, 0.7, 0.9]) {
          final c = tintCast(_photo(ref, scale: scale), ref);
          expect(c.b, closeTo(0, 0.05), reason: 'scale $scale');
          expect(c.a, closeTo(0, 0.05), reason: 'scale $scale');
        }
      });

      test('$card $version: the tint greys\' mean b* and a* minus the reference\'s', () {
        final photo = _photo(ref, gain: const [1.04, 1.0, 0.9]); // warm: b* up
        final lab = normalisedLab(photo, ref);
        final tint = [for (final id in ref.tintGreys) ref.indexOf(id)];
        double mean(Iterable<double> v) => v.reduce((x, y) => x + y) / v.length;
        final c = tintCast(photo, ref);
        expect(c.b, closeTo(mean(tint.map((k) => lab[k][2])) - mean(tint.map((k) => ref.lab[k][2])), 1e-12));
        expect(c.a, closeTo(mean(tint.map((k) => lab[k][1])) - mean(tint.map((k) => ref.lab[k][1])), 1e-12));
        expect(c.b, greaterThan(2));
        // the white and the black do not count
        final other = [for (final p in photo) List<double>.of(p)];
        for (final k in [ref.greyIndexes.first, ref.greyIndexes.last]) {
          other[k] = [200.0, 120.0, 40.0];
        }
        expect(tintCast(other, ref).b, closeTo(c.b, 1e-12));
      });
    }
  });

  group('roundTo50', () {
    test('half up', () {
      expect(roundTo50(4643), 4650);
      expect(roundTo50(4624.9), 4600);
      expect(roundTo50(4625), 4650);
      expect(roundTo50(4675), 4700);
      expect(roundTo50(2800), 2800);
      expect(roundTo50(6499), 6500);
    });
  });

  group('searchWhiteBalance', () {
    test('it reaches |Δb*| <= 1 within 5 photos and rounds to 50 K', () async {
      final calls = <int>[];
      final r = await searchWhiteBalance(start: 5750, cast: _linear(0.004, 4630, calls));
      expect(r.start, 5750);
      expect(r.kelvin, 4650);
      expect(r.kelvin % 50, 0);
      expect(r.deltaB.abs(), lessThanOrEqualTo(1.0));
      expect(r.deltaA, 0.4); // reported only
      expect(r.photos, lessThanOrEqualTo(5));
      expect(r.photos, calls.length);
      expect(calls.first, 5750);
      // 5750 (+4.48) → 4275 (−1.42) → 5012 (+1.53) → 4643 (+0.05)
      expect(calls, [5750, 4275, 5012, 4643]);
    });

    test('a start already within 1 takes one photo', () async {
      final calls = <int>[];
      final r = await searchWhiteBalance(start: 4700, cast: _linear(0.004, 4630, calls));
      expect(calls, [4700]);
      expect(r.kelvin, 4700);
      expect(r.photos, 1);
    });

    test('it stops at 5 photos and keeps the best', () async {
      // a cast no setting can bring within 1: always warm, least at the coolest
      final calls = <int>[];
      final r = await searchWhiteBalance(start: 5750, cast: _linear(0.0001, 4630, calls, offset: 3));
      expect(calls, hasLength(5));
      expect(r.photos, 5);
      final best = calls.reduce((x, y) => x < y ? x : y); // the smallest |Δb*| is the coolest k
      expect(r.kelvin, roundTo50(best.toDouble()));
      expect(r.deltaB, closeTo(0.0001 * (best - 4630) + 3, 1e-12));
      // ties keep the first: a flat cast stays at the start
      final flat = <int>[];
      final f = await searchWhiteBalance(start: 5750, cast: (k) async {
        flat.add(k);
        return (b: 2.0, a: 0.0);
      });
      expect(flat, hasLength(5));
      expect(f.kelvin, 5750);
      // a different budget is kept to
      final three = <int>[];
      expect((await searchWhiteBalance(start: 5750, cast: _linear(0.0001, 4630, three, offset: 3), maxPhotos: 3)).photos,
          3);
      expect(three, hasLength(3));
    });

    test('warmer means a higher kelvin', () async {
      // a positive cast (too warm) lowers k, a negative one raises it
      final warm = <int>[];
      await searchWhiteBalance(start: 5000, cast: _linear(0, 0, warm, offset: 2));
      expect(warm[1], lessThan(5000));
      for (var i = 1; i < warm.length; i++) {
        expect(warm[i], lessThan(warm[i - 1]));
      }
      final cool = <int>[];
      await searchWhiteBalance(start: 5000, cast: _linear(0, 0, cool, offset: -2));
      expect(cool[1], greaterThan(5000));
    });

    test('the result stays in 2800..6500 K', () async {
      final low = await searchWhiteBalance(start: 2810, cast: (k) async => (b: 0.5, a: 0.0));
      expect(low.kelvin, 2800);
      final high = await searchWhiteBalance(start: 6490, cast: (k) async => (b: 0.5, a: 0.0));
      expect(high.kelvin, 6500);
      // a start outside the range is brought into it before the first photo
      final calls = <int>[];
      await searchWhiteBalance(start: 9000, cast: _linear(0.004, 4630, calls));
      expect(calls.first, 6500);
      expect(kWhiteBalanceMin, 2800);
      expect(kWhiteBalanceMax, 6500);
    });

    test('a bound reached is not photographed twice', () async {
      final calls = <int>[];
      await searchWhiteBalance(start: 2800, cast: _linear(0, 0, calls, offset: 3));
      expect(calls.toSet(), hasLength(calls.length));
    });
  });
}
