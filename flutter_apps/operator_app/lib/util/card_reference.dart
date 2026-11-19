// The colour card references (spec 2026-11-02 section 4.1, plan rulings R21,
// R22): the SpyderCheckr 24 and the ColorChecker Classic, read from the app's
// copies in assets/colour_cards/ (of tools/colorchecker/references/, kept
// identical by server/tests/test_colour_card_references.py). The servers read
// the same files (Python colour_card.py, Server 2.0 ColourCards/).
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The cards, as the servers name them.
const kCards = ['spyder24', 'classic'];

/// The ColorChecker Classic versions: cards made before November 2014, and from then on.
const kClassicVersions = ['pre2014', '2014'];

/// The versions each card's file holds ('' for the one SpyderCheckr table).
const _versions = {
  'spyder24': [''],
  'classic': kClassicVersions,
};

/// The skin patches count this much in the fit and the score (spec 4.1).
const double skinWeight = 3;

/// The tap corners as cells (across, along): 1E, 1H, 6H, 6E / 1, 19, 24, 6.
const _cornerCells = [(0, 0), (3, 0), (3, 5), (0, 5)];

/// One card's reference in one version. Patch order = the JSON's.
class CardReference {
  CardReference._({
    required this.card,
    required this.version,
    required this.ids,
    required this.names,
    required this.lab,
    required this.cells,
    required this.greys,
    required this.tintGreys,
    required this.skin,
    required this.exposureGrey,
    required this.patchOfSpacing,
  });

  /// Reads a card's JSON in [version] ('' for the SpyderCheckr, `pre2014` or
  /// `2014` for the Classic). Throws [ArgumentError] for an unknown card or version.
  factory CardReference.fromJson(Map<String, dynamic> json, {String version = ''}) {
    final card = json['card'];
    final known = _versions[card];
    if (known == null) throw ArgumentError.value(card, 'card', 'not a colour card');
    if (!known.contains(version) || !(json['versions'] as List).contains(version)) {
      throw ArgumentError.value(version, 'version', 'not a version of the $card');
    }
    final patches = (json['patches'] as List).cast<Map<String, dynamic>>();
    if (patches.length != 24) throw ArgumentError('$card: ${patches.length} patches, not 24');
    List<String> strings(dynamic list) => List.unmodifiable((list as List).cast<String>());
    return CardReference._(
      card: card as String,
      version: version,
      ids: List.unmodifiable([for (final p in patches) p['id'] as String]),
      names: List.unmodifiable([for (final p in patches) p['name'] as String]),
      lab: List.unmodifiable([
        for (final p in patches)
          List<double>.unmodifiable([
            for (final v in (p['lab'] as Map<String, dynamic>)[version] as List) (v as num).toDouble(),
          ]),
      ]),
      cells: List.unmodifiable([
        for (final p in patches) ((p['cell'] as List)[0] as int, (p['cell'] as List)[1] as int),
      ]),
      greys: strings(json['greys']),
      tintGreys: strings(json['tint_greys']),
      skin: strings(json['skin']),
      exposureGrey: json['exposure_grey'] as String,
      patchOfSpacing: (json['patch_of_spacing'] as num).toDouble(),
    );
  }

  final String card;
  final String version;
  final List<String> ids;
  final List<String> names;

  /// The reference L*, a*, b* (D50) of each patch.
  final List<List<double>> lab;

  /// Each patch's cell (across 0..3, along 0..5).
  final List<(int, int)> cells;

  /// The grey patches, white to black.
  final List<String> greys;

  /// The greys whose cast the glare-free tint step reads (spec 4.4).
  final List<String> tintGreys;
  final List<String> skin;

  /// The grey the exposure is taken out on.
  final String exposureGrey;

  /// Patch side / centre spacing.
  final double patchOfSpacing;

  /// The index of patch [id]; -1 for an unknown id.
  int indexOf(String id) => ids.indexOf(id);

  /// [skinWeight] for the skin patches, 1 for the others.
  List<double> get weights => [for (final id in ids) skin.contains(id) ? skinWeight : 1.0];

  int get exposureGreyIndex => indexOf(exposureGrey);

  /// The greys' indexes, white to black.
  List<int> get greyIndexes => [for (final g in greys) indexOf(g)];

  /// The indexes of the patches in the cells (0,0), (3,0), (3,5), (0,5).
  List<int> get cornerIndexes => [for (final c in _cornerCells) cells.indexOf(c)];
}

/// Reads [card]'s reference in [version] from the app bundle
/// (`assets/colour_cards/<card>.json`). Throws [ArgumentError] for an unknown
/// card or version.
Future<CardReference> loadCardReference(String card, {String version = ''}) async {
  if (!kCards.contains(card)) throw ArgumentError.value(card, 'card', 'not a colour card');
  final text = await rootBundle.loadString('assets/colour_cards/$card.json');
  return CardReference.fromJson(jsonDecode(text) as Map<String, dynamic>, version: version);
}

/// Reads a card's reference as the operator chose it: the Classic in [version],
/// the SpyderCheckr's one table (the version is then not used).
typedef CardReferenceLoader = Future<CardReference> Function(String card, String version);

/// The app's [CardReferenceLoader] (from the bundle, [loadCardReference]).
Future<CardReference> loadChosenCardReference(String card, String version) =>
    loadCardReference(card, version: card == 'classic' ? version : '');
