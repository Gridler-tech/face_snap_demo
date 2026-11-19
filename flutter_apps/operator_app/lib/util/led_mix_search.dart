// The LED-mix search of the colour calibration (spec 2026-11-02 section 4.3,
// plan rulings R17 and R18): a pattern search over the standard light's LED mix
// at constant brightness, judged by the weighted colour score each photo's own
// matrix leaves. Pure Dart: the photos come through the caller's [score]
// function (the run of Task 12; a simulated camera in the tests).
import 'dart:math' as math;

import 'card_reference.dart';
import 'colour_fit.dart';

/// The text of a search that keeps the start mix.
const String mixAlreadyBest = 'your LED mix is already the best';

/// The pattern-search steps, largest first (spec 4.3).
const List<int> mixSteps = [16, 8, 4];

/// An LED mix: red, green, blue, each 0..255.
class LedMix {
  const LedMix(this.red, this.green, this.blue);

  final int red, green, blue;

  /// The brightness proxy `L = 0.2126 R + 0.7152 G + 0.0722 B` (spec 4.3).
  double get brightness => mixBrightness(red, green, blue);

  @override
  bool operator ==(Object other) =>
      other is LedMix && other.red == red && other.green == green && other.blue == blue;

  @override
  int get hashCode => Object.hash(red, green, blue);

  @override
  String toString() => '($red, $green, $blue)';
}

/// [LedMix.brightness] of any three channel values.
double mixBrightness(num red, num green, num blue) => 0.2126 * red + 0.7152 * green + 0.0722 * blue;

/// A raw candidate brought to the brightness [target] (ruling R18): each channel
/// clamped to >= 0; all three scaled by `target / L(raw)` (not when `L(raw)` is
/// 0); when a channel is then above 255, all three scaled by `255 / max`; each
/// rounded half up (`floor(x + 0.5)`) and clamped to 0..255. A cut above 255
/// leaves the mix darker than [target].
LedMix keepBrightness(List<num> raw, double target) {
  if (raw.length != 3) throw ArgumentError('keepBrightness: a mix has 3 channels, not ${raw.length}');
  var c = [for (final v in raw) math.max(0.0, v.toDouble())];
  final l = mixBrightness(c[0], c[1], c[2]);
  if (l != 0) c = [for (final v in c) v * target / l];
  final top = c.reduce(math.max);
  if (top > 255) c = [for (final v in c) v * 255 / top];
  int level(double v) => (v + 0.5).floor().clamp(0, 255);
  return LedMix(level(c[0]), level(c[1]), level(c[2]));
}

/// The four candidates around [best] with step [step], in the spec's order:
/// red up / blue down, red down / blue up, green up, green down (magenta), each
/// brought to the brightness [target] by [keepBrightness].
List<LedMix> mixCandidates(LedMix best, int step, double target) {
  final r = best.red, g = best.green, b = best.blue;
  final s = step.toDouble(), h = step / 2;
  return [
    keepBrightness([r + s, g, b - s], target),
    keepBrightness([r - s, g, b + s], target),
    keepBrightness([r - h, g + s, b - h], target),
    keepBrightness([r + h, g - s, b + h], target),
  ];
}

/// One photo's score (spec 4.3): the photo's own matrix fitted to its patches
/// ([srgb8], JSON order, sRGB 0..255), then the weighted mean dE2000 after it
/// over the patches not [clipped] (skin 3, the others 1). Throws
/// [ArgumentError] when the photo cannot be fitted (see [fitColourMatrix]).
double photoScore(List<List<double>> srgb8, List<bool> clipped, CardReference reference) =>
    fitColourMatrix(srgb8, [for (final c in clipped) !c], reference: reference).scoreAfter;

class MixSearchResult {
  MixSearchResult({
    required this.start,
    required this.best,
    required this.changed,
    required this.brightnessChangePercent,
    required this.scoreStart,
    required this.scoreBest,
    required this.margin,
    required this.photos,
    this.message,
  });

  /// The mix the search began at, and the one it settled on ([start] when kept).
  final LedMix start, best;

  /// [best] differs from [start] (the confirm photo upheld the move).
  final bool changed;

  /// `100 × (L(best) / L(start) − 1)`, one decimal (R18); 0 when kept.
  final double brightnessChangePercent;

  /// The mean of the two start photos' scores, and [best]'s score: its confirm
  /// photo when [changed], else [scoreStart].
  final double scoreStart, scoreBest;

  /// `max(0.15, 2 × |S₁ − S₂|)`: what a candidate must beat the best by.
  final double margin;

  /// The photos taken, the two start photos and the confirm included.
  final int photos;

  /// [mixAlreadyBest] when the start mix is kept, else null.
  final String? message;
}

/// The LED-mix pattern search (spec 4.3, ruling R17). [score] takes one photo
/// with a mix and returns its [photoScore]; it is called at most [maxPhotos]
/// times in all:
///
/// 1. the start twice: `margin = max(0.15, 2 × |S₁ − S₂|)`, `S_start = (S₁ + S₂) / 2`;
/// 2. per step 16 → 8 → 4: the four [mixCandidates] around the best; the lowest
///    (the first on a tie) becomes the best when it beats the best's score by more
///    than the margin, and the same step goes on; else the step halves; the search
///    ends after step 4 finds no move;
/// 3. a candidate equal to the best or to a mix already photographed reuses that
///    score (no photo); a candidate photo is taken only while one photo is left
///    after it for the confirm, else the search ends (the round so far still decides);
/// 4. the confirm: a moved best is photographed once more and kept only when that
///    score beats `S_start` by more than the margin; no confirm when nothing moved.
Future<MixSearchResult> searchLedMix({
  required LedMix start,
  required Future<double> Function(LedMix) score,
  int maxPhotos = 16,
}) async {
  if (maxPhotos < 3) throw ArgumentError.value(maxPhotos, 'maxPhotos', 'the search needs at least 3 photos');
  final target = start.brightness;
  var photos = 0;
  Future<double> photo(LedMix mix) {
    photos++;
    return score(mix);
  }

  final s1 = await photo(start);
  final s2 = await photo(start);
  final margin = math.max(0.15, 2 * (s1 - s2).abs());
  final scoreStart = (s1 + s2) / 2;
  final measured = <LedMix, double>{start: scoreStart};
  var best = start;
  var bestScore = scoreStart;
  var outOfPhotos = false;

  for (final step in mixSteps) {
    while (!outOfPhotos) {
      LedMix? roundBest;
      var roundScore = double.infinity;
      for (final candidate in mixCandidates(best, step, target)) {
        var s = measured[candidate];
        if (s == null) {
          if (photos + 1 >= maxPhotos) {
            outOfPhotos = true; // the last photo is the confirm's
            break;
          }
          s = await photo(candidate);
          measured[candidate] = s;
        }
        if (s < roundScore) {
          roundBest = candidate;
          roundScore = s;
        }
      }
      if (roundBest == null || !(roundScore < bestScore - margin)) break;
      best = roundBest;
      bestScore = roundScore;
    }
    if (outOfPhotos) break;
  }

  if (best != start) {
    final confirm = await photo(best);
    if (confirm < scoreStart - margin) {
      return MixSearchResult(
        start: start,
        best: best,
        changed: true,
        brightnessChangePercent: brightnessChangePercent(start, best),
        scoreStart: scoreStart,
        scoreBest: confirm,
        margin: margin,
        photos: photos,
      );
    }
  }
  return MixSearchResult(
    start: start,
    best: start,
    changed: false,
    brightnessChangePercent: 0,
    scoreStart: scoreStart,
    scoreBest: scoreStart,
    margin: margin,
    photos: photos,
    message: mixAlreadyBest,
  );
}

/// `100 × (L(to) / L(from) − 1)` rounded to one decimal (R18); 0 when [from] is black.
double brightnessChangePercent(LedMix from, LedMix to) {
  final l = from.brightness;
  if (l == 0) return 0;
  return (1000 * (to.brightness / l - 1)).round() / 10;
}
