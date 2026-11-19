// The LED-mix search (spec 2026-11-02 section 4.3, rulings R17 and R18): the
// brightness proxy, the candidates, the photo score and the pattern search,
// against the simulated camera of simulated_card.dart and against plain score
// functions where only the counting is under test.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/util/card_reference.dart';
import 'package:operator_app/util/colour_fit.dart';
import 'package:operator_app/util/led_mix_search.dart';

import 'simulated_card.dart';

// `flutter test` runs with the package root as the working directory.
CardReference _read(String card, [String version = '']) => CardReference.fromJson(
    jsonDecode(File('assets/colour_cards/$card.json').readAsStringSync()) as Map<String, dynamic>,
    version: version);

final _spyder = _read('spyder24');
final _classic = _read('classic', 'pre2014');

/// A neutral start: there the mix's gain is a plain scale, which the exposure
/// normalisation takes out, so with c = 0 every other mix scores worse or equal.
const _neutral = LedMix(200, 200, 200);

/// The c of the tests: a 4-step from the best raises S by more than 0.3 (each
/// test asserts it first); c = 1 would add under 0.01 dE there, and c = 3000
/// pushes far mixes out of the gamut until the fit has no patches left.
const double _c = 1000;

/// A plain score: the distance (levels) from [target], / 10.
Future<double> Function(LedMix) _towards(LedMix target, List<LedMix> calls) => (m) async {
      calls.add(m);
      final dr = m.red - target.red, dg = m.green - target.green, db = m.blue - target.blue;
      return math.sqrt(dr * dr + dg * dg + db * db) / 10;
    };

Future<void> _expectPremise(SimulatedCard card, LedMix best, double target) async {
  final at = await card.score(best);
  for (final m in mixCandidates(best, 4, target)) {
    expect(await card.score(m) - at, greaterThan(0.3), reason: 'a 4-step $m from the best $best');
  }
  card.photographed.clear();
}

void _expectWithin4(LedMix a, LedMix b) {
  expect((a.red - b.red).abs(), lessThanOrEqualTo(4), reason: '$a vs $b');
  expect((a.green - b.green).abs(), lessThanOrEqualTo(4), reason: '$a vs $b');
  expect((a.blue - b.blue).abs(), lessThanOrEqualTo(4), reason: '$a vs $b');
}

void main() {
  group('keepBrightness (R18)', () {
    test('table', () {
      final cases = <(List<num>, double, LedMix, String)>[
        ([200, 200, 200], 200, const LedMix(200, 200, 200), 'already at the brightness'),
        ([216, 200, 184], 200, const LedMix(214, 198, 182), 'scaled by 200 / 202.24'),
        ([-8, 200, 116], mixBrightness(8, 200, 100), const LedMix(0, 201, 116), 'a negative channel clamps to 0 first'),
        ([266, 230, 234], mixBrightness(250, 230, 250), const LedMix(255, 220, 224), 'over 255: all three cut'),
        ([300, 100, 100], mixBrightness(200, 100, 100), const LedMix(255, 85, 85), 'over 255 after the scale'),
        ([0, 0, 0], 100, const LedMix(0, 0, 0), 'black: no scale'),
        ([-5, -5, -5], 50, const LedMix(0, 0, 0), 'all negative: black'),
        ([2.5, 0, 0], mixBrightness(2.5, 0, 0), const LedMix(3, 0, 0), 'half rounds up'),
        ([0.5, 0, 0], mixBrightness(0.5, 0, 0), const LedMix(1, 0, 0), 'half rounds up near 0'),
        ([1.49, 0, 0], mixBrightness(1.49, 0, 0), const LedMix(1, 0, 0), 'below half rounds down'),
      ];
      for (final (raw, target, want, why) in cases) {
        expect(keepBrightness(raw, target), want, reason: why);
      }
      expect(() => keepBrightness([1, 2], 10), throwsArgumentError);
    });

    test('the brightness proxy is Rec. 709', () {
      expect(const LedMix(100, 0, 0).brightness, closeTo(21.26, 1e-12));
      expect(const LedMix(0, 100, 0).brightness, closeTo(71.52, 1e-12));
      expect(const LedMix(0, 0, 100).brightness, closeTo(7.22, 1e-12));
    });

    test('the candidates come in the spec order', () {
      // (R+s, G, B−s), (R−s, G, B+s), (R−s/2, G+s, B−s/2), (R+s/2, G−s, B+s/2), each at L
      final l = _neutral.brightness;
      expect(mixCandidates(_neutral, 16, l), [
        keepBrightness([216, 200, 184], l),
        keepBrightness([184, 200, 216], l),
        keepBrightness([192, 216, 192], l),
        keepBrightness([208, 184, 208], l),
      ]);
      expect(mixCandidates(_neutral, 4, l)[2], keepBrightness([198, 204, 198], l));
    });

    test('a zero channel clamps and keeps the brightness', () async {
      // Review Focus 5: a start mix with a channel at 0
      for (final start in const [LedMix(0, 200, 100), LedMix(8, 200, 100), LedMix(120, 180, 0)]) {
        final l = start.brightness;
        for (final step in mixSteps) {
          for (final m in mixCandidates(start, step, l)) {
            for (final v in [m.red, m.green, m.blue]) {
              expect(v, inInclusiveRange(0, 255), reason: '$start step $step: $m');
            }
            expect(m.brightness, closeTo(l, 0.5), reason: '$start step $step: $m');
          }
        }
        expect(mixCandidates(start, 16, l).any((m) => m.red == 0 || m.blue == 0), isTrue);
      }
      // and through a whole search: every photo at the start's brightness
      const start = LedMix(8, 200, 100);
      final card = SimulatedCard(reference: _spyder, best: bestFrom(start), c: _c);
      await searchLedMix(start: start, score: card.score);
      expect(card.photographed.length, greaterThan(2));
      for (final m in card.photographed) {
        expect(m.brightness, closeTo(start.brightness, 0.5), reason: '$m');
        expect([m.red, m.green, m.blue].every((v) => v >= 0 && v <= 255), isTrue, reason: '$m');
      }
    });
  });

  group('photoScore', () {
    test('the weighted dE after the photo\'s own matrix', () {
      final card = SimulatedCard(reference: _spyder, best: _neutral, c: _c);
      final p = card.photo(const LedMix(214, 198, 182));
      final fit = fitColourMatrix(p.srgb8, [for (final c in p.clipped) !c], reference: _spyder);
      expect(photoScore(p.srgb8, p.clipped, _spyder), fit.scoreAfter);
    });

    test('a clipped patch is left out of the score', () {
      // Review Focus 4: glare on the dark blue patch 6F
      const blue = 11;
      expect(_spyder.ids[blue], '6F');
      final card = SimulatedCard(reference: _spyder, best: _neutral, c: _c);
      final p = card.photo(const LedMix(214, 198, 182));
      final clipped = [...p.clipped]..[blue] = true;
      final glare = [for (final v in p.srgb8) List<double>.of(v)]..[blue] = [255.0, 255.0, 255.0];
      final kept = photoScore(p.srgb8, clipped, _spyder);
      expect(photoScore(glare, clipped, _spyder), closeTo(kept, 1e-12)); // its values do not count
      expect((photoScore(glare, p.clipped, _spyder) - kept).abs(), greaterThan(0.01)); // they would
    });
  });

  group('searchLedMix', () {
    test('it finds a known best mix within ±4', () async {
      for (final reference in [_spyder, _classic]) {
        for (final start in const [_neutral, LedMix(230, 200, 170), LedMix(180, 220, 200)]) {
          final best = bestFrom(start);
          final card = SimulatedCard(reference: reference, best: best, c: _c);
          await _expectPremise(card, best, start.brightness);
          final r = await searchLedMix(start: start, score: card.score);
          expect(r.changed, isTrue, reason: '${reference.card} $start');
          _expectWithin4(r.best, best);
          expect(r.message, isNull);
          expect(r.photos, card.photographed.length);
          expect(r.photos, lessThanOrEqualTo(16));
          expect(r.scoreBest, lessThan(r.scoreStart - r.margin));
          expect(r.margin, 0.15); // two identical start photos (no noise)
          expect(r.start, start);
          expect(r.brightnessChangePercent, brightnessChangePercent(start, r.best));
        }
      }
    });

    test('it keeps the start mix when the differences are only noise', () async {
      final card = SimulatedCard(reference: _spyder, best: bestFrom(_neutral), c: 0, sigma: 0.6);
      final r = await searchLedMix(start: _neutral, score: card.score);
      expect(r.changed, isFalse);
      expect(r.best, _neutral);
      expect(r.message, 'your LED mix is already the best');
      expect(r.message, mixAlreadyBest);
      expect(r.photos, lessThanOrEqualTo(16));
      expect(r.photos, 14); // 2 start photos + 4 per step, no confirm (R17)
      expect(r.brightnessChangePercent, 0);
      expect(r.scoreBest, r.scoreStart);
      expect(r.margin, greaterThanOrEqualTo(0.15));
    });

    test('a channel at 255 scales the others down and reports the brightness change', () async {
      const start = LedMix(250, 230, 250);
      final l = start.brightness;
      final cut = mixCandidates(start, 16, l)[0]; // red +16 needs the cut
      expect(cut, const LedMix(255, 220, 224));
      expect(cut.brightness, lessThan(l - 1));
      final card = SimulatedCard(reference: _spyder, best: cut, c: _c);
      await _expectPremise(card, cut, l);
      final r = await searchLedMix(start: start, score: card.score);
      for (final m in card.photographed) {
        expect([m.red, m.green, m.blue].every((v) => v <= 255), isTrue, reason: '$m');
        if (m.brightness < l - 0.5) expect([m.red, m.green, m.blue].contains(255), isTrue, reason: '$m');
      }
      expect(r.changed, isTrue);
      expect(r.best, cut);
      expect(r.brightnessChangePercent, lessThan(0));
      expect(r.brightnessChangePercent, (1000 * (cut.brightness / l - 1)).round() / 10);
      expect(r.brightnessChangePercent, -3.4);
    });

    test('it stops at 16 photos', () async {
      // the best far away: every round moves, so the photos run out
      final calls = <LedMix>[];
      final r = await searchLedMix(start: _neutral, score: _towards(const LedMix(255, 170, 0), calls));
      expect(calls, hasLength(16)); // the confirm included
      expect(r.photos, 16);
      expect(calls.last, r.best); // the last photo is the confirm of the best
      expect(calls.sublist(0, 15), contains(r.best)); // photographed before as a candidate
      expect(r.changed, isTrue);
      // a smaller budget is kept to as well
      final few = <LedMix>[];
      expect((await searchLedMix(start: _neutral, score: _towards(const LedMix(255, 170, 0), few), maxPhotos: 7)).photos,
          7);
      expect(few, hasLength(7));
    });

    test('no confirm photo when nothing moved', () async {
      final calls = <LedMix>[];
      final r = await searchLedMix(start: _neutral, score: _towards(_neutral, calls));
      expect(r.changed, isFalse);
      expect(calls, hasLength(14));
      expect(calls.where((m) => m == _neutral), hasLength(2)); // the two start photos only
      expect(calls.sublist(0, 2), [_neutral, _neutral]);
    });

    test('a repeated candidate is not photographed again', () async {
      // best = start + 16 red: the next round's "red down" is the start again
      final l = _neutral.brightness;
      final redder = mixCandidates(_neutral, 16, l)[0];
      expect(mixCandidates(redder, 16, l)[1], _neutral);
      final calls = <LedMix>[];
      final r = await searchLedMix(start: _neutral, score: _towards(redder, calls), maxPhotos: 20);
      expect(r.best, redder);
      expect(calls.where((m) => m == _neutral), hasLength(2));
      expect(calls.where((m) => m == redder), hasLength(2)); // as a candidate, then the confirm
      final others = calls.where((m) => m != _neutral && m != redder).toList();
      expect(others.toSet(), hasLength(others.length)); // no other mix twice
      // 2 start + 4 + 3 (the start reused) at 16, 4 at 8, 4 at 4, the confirm (room for all: 20)
      expect(calls, hasLength(2 + 4 + 3 + 4 + 4 + 1));
    });

    test('a search with a clipped patch still finds the best', () async {
      // Review Focus 4: glare on 6F in every photo; it is left out and the run goes on
      final best = bestFrom(_neutral);
      final card = SimulatedCard(reference: _spyder, best: best, c: _c, glare: {11});
      await _expectPremise(card, best, _neutral.brightness);
      final r = await searchLedMix(start: _neutral, score: card.score);
      expect(r.changed, isTrue);
      _expectWithin4(r.best, best);
    });

    test('the margin is twice the start photos\' difference, at least 0.15', () async {
      var n = 0;
      final r = await searchLedMix(
          start: _neutral,
          score: (m) async => m == _neutral ? (n++ == 0 ? 5.0 : 4.6) : 4.75); // 0.15 better than S_start
      expect(r.margin, closeTo(0.8, 1e-12));
      expect(r.scoreStart, closeTo(4.8, 1e-12));
      expect(r.changed, isFalse);
      expect(() => searchLedMix(start: _neutral, score: (m) async => 1, maxPhotos: 2), throwsArgumentError);
    });

    test('a winner that fails its confirm keeps the start mix', () async {
      final l = _neutral.brightness;
      final redder = mixCandidates(_neutral, 16, l)[0];
      var seen = 0;
      final r = await searchLedMix(
          start: _neutral,
          score: (m) async {
            if (m != redder) return 3.0;
            return ++seen == 1 ? 1.0 : 2.95; // a lucky photo, then the truth
          });
      expect(r.changed, isFalse);
      expect(r.best, _neutral);
      expect(r.message, mixAlreadyBest);
      expect(seen, 2);
    });
  });
}
