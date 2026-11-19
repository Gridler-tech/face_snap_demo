// The colour card references (spec 2026-11-02 section 4.1, plan rulings R21,
// R22): the app's copies in assets/colour_cards/ (identical to
// tools/colorchecker/references/, server/tests/test_colour_card_references.py
// checks that) read into a CardReference.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/util/card_reference.dart';

// `flutter test` runs with the package root as the working directory.
Map<String, dynamic> _asset(String card) =>
    jsonDecode(File('assets/colour_cards/$card.json').readAsStringSync()) as Map<String, dynamic>;

CardReference _read(String card, [String version = '']) =>
    CardReference.fromJson(_asset(card), version: version);

void main() {
  test('the cards and the Classic versions', () {
    expect(kCards, ['spyder24', 'classic']);
    expect(kClassicVersions, ['pre2014', '2014']);
  });

  group('SpyderCheckr 24', () {
    final ref = _read('spyder24');

    test('ids, names, Lab and cells', () {
      expect(ref.card, 'spyder24');
      expect(ref.version, '');
      expect(ref.ids, [
        for (final col in 'EFGH'.split(''))
          for (var row = 1; row <= 6; row++) '$row$col',
      ]);
      expect(ref.names.first, 'Card White');
      expect(ref.names.last, 'Classic Dark Skin');
      expect(ref.lab, hasLength(24));
      expect(ref.lab.first, [96.04, 2.16, 2.60]);
      expect(ref.lab.last, [36.13, 14.15, 15.78]);
      for (var k = 0; k < 24; k++) {
        final id = ref.ids[k];
        expect(ref.cells[k], ('EFGH'.indexOf(id[1]), int.parse(id[0]) - 1), reason: id);
      }
      expect(ref.patchOfSpacing, 0.89);
    });

    test('greys, skin, weights, exposure grey and corners', () {
      expect(ref.greys, ['1E', '2E', '3E', '4E', '5E', '6E']);
      expect(ref.greyIndexes, [0, 1, 2, 3, 4, 5]);
      expect(ref.tintGreys, ['2E', '3E', '4E', '5E']);
      expect(ref.skin, ['5H', '6H']);
      expect(ref.exposureGrey, '3E');
      expect(ref.exposureGreyIndex, 2);
      expect(ref.indexOf('5H'), 22);
      expect(ref.weights, [for (var k = 0; k < 24; k++) k == 22 || k == 23 ? 3.0 : 1.0]);
      expect([for (final k in ref.cornerIndexes) ref.ids[k]], ['1E', '1H', '6H', '6E']);
    });

    test('a version is refused', () {
      expect(() => _read('spyder24', 'pre2014'), throwsArgumentError);
    });
  });

  group('ColorChecker Classic', () {
    for (final version in kClassicVersions) {
      test('$version: ids, weights, exposure grey and corners', () {
        final ref = _read('classic', version);
        expect(ref.card, 'classic');
        expect(ref.version, version);
        expect(ref.ids, [for (var n = 1; n <= 24; n++) '$n']);
        expect(ref.names.first, 'dark skin');
        expect(ref.lab, hasLength(24));
        for (var k = 0; k < 24; k++) {
          expect(ref.cells[k], (k ~/ 6, k % 6), reason: ref.ids[k]);
        }
        expect(ref.greys, ['19', '20', '21', '22', '23', '24']);
        expect(ref.greyIndexes, [18, 19, 20, 21, 22, 23]);
        expect(ref.tintGreys, ['20', '21', '22', '23']);
        expect(ref.skin, ['1', '2']);
        expect(ref.exposureGrey, '21');
        expect(ref.exposureGreyIndex, 20);
        expect(ref.weights, [for (var k = 0; k < 24; k++) k < 2 ? 3.0 : 1.0]);
        expect([for (final k in ref.cornerIndexes) ref.ids[k]], ['1', '19', '24', '6']);
        expect(ref.patchOfSpacing, closeTo(2.5 / 2.75, 1e-9));
      });
    }

    test('the two versions differ', () {
      expect(_read('classic', 'pre2014').lab.first, isNot(_read('classic', '2014').lab.first));
      expect(_read('classic', '2014').lab.first, [37.54, 14.37, 14.92]);
    });

    test('no or an unknown version is refused', () {
      expect(() => _read('classic'), throwsArgumentError);
      expect(() => _read('classic', '2015'), throwsArgumentError);
    });
  });

  group('loadCardReference (the app bundle)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('reads the assets', () async {
      final spyder = await loadCardReference('spyder24');
      expect(spyder.exposureGreyIndex, 2);
      final classic = await loadCardReference('classic', version: '2014');
      expect(classic.exposureGreyIndex, 20);
      expect(classic.lab, _read('classic', '2014').lab);
    });

    test('an unknown card is refused', () async {
      await expectLater(loadCardReference('macbeth'), throwsArgumentError);
    });
  });
}
