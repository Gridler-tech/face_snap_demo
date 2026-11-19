// The updater's settings profiles carry the capture warm-up (kiosk.capture_warm_up, spec
// 2026-10-11 section 4.7; final review M3): a list of names from modnet, withoutbg, gridler
// (1.1.27) and ofiq, stored as the servers store it (no duplicates, in that order); any other
// shape is refused.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/settings_profile.dart';

String _profile(String kioskSettings) =>
    '{"profile": "t", "kiosk_settings": $kioskSettings}';

Matcher _rejects(String fragment) => throwsA(isA<FormatException>()
    .having((e) => e.message, 'message', contains(fragment)));

const _refusal = 'must be a list of names from modnet, withoutbg, gridler, ofiq';

void main() {
  test('the warm-up list is a valid profile setting with its own label', () {
    final profile = SettingsProfile.parse(
        _profile('{"kiosk": {"capture_warm_up": ["ofiq", "withoutbg", "ofiq"]}}'));
    final row = profile.diff(parseKioskSettings('{"kiosk": {}}')).single;
    expect(row.id, 'kiosk.capture_warm_up');
    expect(row.label, 'Capture warm-up');
    expect((row.currentText, row.newText, row.differs), ('not set', 'withoutbg, ofiq', true));
    // Written as the servers store it: no duplicates, in the order modnet, withoutbg, ofiq.
    final applied = applyProfileChanges(parseKioskSettings('{"kiosk": {}}'), [row]);
    expect(applied['kiosk']['capture_warm_up'], ['withoutbg', 'ofiq']);
  });

  test('the Gridler eraser is a warm-up name, stored at its server position', () {
    final profile = SettingsProfile.parse(
        _profile('{"kiosk": {"capture_warm_up": ["ofiq", "gridler", "modnet"]}}'));
    final row = profile.diff(parseKioskSettings('{"kiosk": {"capture_warm_up": []}}')).single;
    expect((row.currentText, row.newText, row.differs), ('none', 'modnet, gridler, ofiq', true));
    final applied = applyProfileChanges(parseKioskSettings('{"kiosk": {}}'), [row]);
    expect(applied['kiosk']['capture_warm_up'], ['modnet', 'gridler', 'ofiq']);
  });

  test('the same names in another order are no change; an empty list is "none"', () {
    final same = SettingsProfile.parse(
        _profile('{"kiosk": {"capture_warm_up": ["withoutbg", "modnet"]}}'));
    final row = same
        .diff(parseKioskSettings('{"kiosk": {"capture_warm_up": ["modnet", "withoutbg"]}}'))
        .single;
    expect((row.currentText, row.newText, row.differs), ('modnet, withoutbg', 'modnet, withoutbg', false));

    final empty = SettingsProfile.parse(_profile('{"kiosk": {"capture_warm_up": []}}'));
    final cleared = empty
        .diff(parseKioskSettings('{"kiosk": {"capture_warm_up": ["modnet"]}}'))
        .single;
    expect((cleared.currentText, cleared.newText, cleared.differs), ('modnet', 'none', true));
  });

  test('an unknown name, a name that is not text, or no list at all is refused', () {
    for (final value in ['["rembg"]', '["modnet", 1]', '"modnet"', 'true', '{"a": "modnet"}']) {
      expect(() => SettingsProfile.parse(_profile('{"kiosk": {"capture_warm_up": $value}}')),
          _rejects(_refusal), reason: value);
    }
  });
}
