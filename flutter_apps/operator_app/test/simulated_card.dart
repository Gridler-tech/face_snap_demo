// A simulated camera photographing a colour card under an LED mix, for the
// LED-mix search and the glare-free bisection tests (plan Task 11; spec
// 2026-11-02 section 7.1). The model (fixed by the plan):
//
//   linear RGB of patch i = exposure × (ref_lin_i ∘ (mix / 255))
//                           + c × ‖mix − best‖² / 255² × d_i
//
// with d_i fixed per-patch vectors in ±0.05 from Random(7); then sRGB-encoded
// × 255, Gaussian noise of [sigma] levels (seeded), clipped to 0..255, a patch
// flagged clipped when a channel is >= 254. The c term marks [best] out. The
// mix's per-channel gain is NOT fully undone by a photo's matrix (its rows sum
// to 1, so a non-grey gain leaves a residual: with c = 0 the start (200, 200,
// 200) scores 0.31 and (205, 201, 174) 2.39 on the SpyderCheckr): a neutral mix
// scores best at c = 0, and the tests take c large enough (1000) that [best]
// stays the best, which each asserts first.
import 'dart:math' as math;

import 'package:operator_app/util/card_reference.dart';
import 'package:operator_app/util/colour_fit.dart';
import 'package:operator_app/util/led_mix_search.dart';

class SimulatedCard {
  SimulatedCard({
    required this.reference,
    required this.best,
    this.c = 1,
    this.sigma = 0,
    this.exposure = 0.8,
    int noiseSeed = 11,
    this.glare = const {},
  })  : _noise = math.Random(noiseSeed),
        _refLin = [for (final lab in reference.lab) labD50ToLinearSrgb(lab)],
        _d = _offsets(reference.lab.length);

  final CardReference reference;

  /// The mix whose photos score best (the c term is 0 there).
  final LedMix best;

  /// The weight of the term that grows with the distance from [best].
  final double c;

  /// The Gaussian noise on each channel of each patch, in levels (0..255).
  final double sigma;

  /// The scale of the whole photo (taken out again by the fit).
  final double exposure;

  /// Patches seen through glare: every channel at 255 (clipped) in every photo.
  final Set<int> glare;

  final math.Random _noise;
  final List<List<double>> _refLin;
  final List<List<double>> _d;

  /// The [mix]es photographed, in order.
  final List<LedMix> photographed = [];

  static List<List<double>> _offsets(int n) {
    final r = math.Random(7);
    return [
      for (var i = 0; i < n; i++) [for (var ch = 0; ch < 3; ch++) (2 * r.nextDouble() - 1) * 0.05],
    ];
  }

  double _gaussian() {
    // Box-Muller; 1 - nextDouble() is in (0, 1]
    final u1 = 1 - _noise.nextDouble(), u2 = _noise.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  /// One photo of the card under [mix]: the 24 patch means (sRGB 0..255, JSON
  /// order) and their clipped flags.
  ({List<List<double>> srgb8, List<bool> clipped}) photo(LedMix mix) {
    photographed.add(mix);
    final m = [mix.red / 255, mix.green / 255, mix.blue / 255];
    final dr = mix.red - best.red, dg = mix.green - best.green, db = mix.blue - best.blue;
    final away = c * (dr * dr + dg * dg + db * db) / (255 * 255);
    final srgb8 = <List<double>>[];
    final clipped = <bool>[];
    for (var i = 0; i < _refLin.length; i++) {
      final patch = <double>[];
      for (var ch = 0; ch < 3; ch++) {
        final lin = exposure * _refLin[i][ch] * m[ch] + away * _d[i][ch];
        var v = 255 * linearToSrgb(lin);
        if (sigma > 0) v += sigma * _gaussian();
        if (glare.contains(i)) v = 255;
        patch.add(v.clamp(0, 255).toDouble());
      }
      srgb8.add(patch);
      clipped.add(patch.any((v) => v >= 254));
    }
    return (srgb8: srgb8, clipped: clipped);
  }

  /// [photo] scored as the search scores it ([photoScore]).
  Future<double> score(LedMix mix) async {
    final p = photo(mix);
    return photoScore(p.srgb8, p.clipped, reference);
  }
}

/// The best mix of the tests: [start] moved on the search's lattice by +16
/// red↔blue (step 16, first direction), then +8 green (step 8, third direction),
/// each at [start]'s brightness.
LedMix bestFrom(LedMix start) {
  final target = start.brightness;
  final redder = mixCandidates(start, 16, target)[0];
  return mixCandidates(redder, 8, target)[2];
}
