// The updater's settings profiles carry the glare-free light (spec 2026-10-09 section 5):
// kiosk.glare_free_light off / glasses / everyone and kiosk.glare_free_white_balance. A
// profile from before it, with only the glasses switch, loads as "glasses" (or "off"), and
// the row writes both keys, as the server does.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/settings_profile.dart';

String _profile(String kioskSettings) => '{"profile": "t", "kiosk_settings": $kioskSettings}';

void main() {
  test('an old profile with only the glasses switch loads as the glare-free light', () {
    final profile = SettingsProfile.parse(_profile('{"kiosk": {"glasses_lights_off": true}}'));
    final row = profile.diff(parseKioskSettings('{"kiosk": {"glasses_lights_off": false}}')).single;
    expect(row.id, 'kiosk.glare_free_light');
    expect(row.label, 'Glare-free light');
    expect((row.currentText, row.newText, row.differs), ('off', 'glasses', true));
    expect(row.writes, {'kiosk.glare_free_light': 'glasses', 'kiosk.glasses_lights_off': true});
  });

  test('a consistent pair in a profile reads as its new key', () {
    final profile = SettingsProfile.parse(
        _profile('{"kiosk": {"glare_free_light": "everyone", "glasses_lights_off": true}}'));
    final row = profile.diff(parseKioskSettings('{"kiosk": {}}')).single;
    expect((row.id, row.newText), ('kiosk.glare_free_light', 'everyone'));
    expect(row.writes, {'kiosk.glare_free_light': 'everyone', 'kiosk.glasses_lights_off': true});
  });

  // Ruling R26, as both servers read kiosk_settings.json: a pair that disagrees came from an old
  // writer (a downgraded server, an operator 1.1.23/1.1.24 profile apply) that changed only the
  // old switch, so the old switch wins - true with "off" is "glasses", false with "glasses" or
  // "everyone" is "off".
  for (final (pair, mode) in [
    ('"glare_free_light": "everyone", "glasses_lights_off": false', 'off'),
    ('"glare_free_light": "glasses", "glasses_lights_off": false', 'off'),
    ('"glare_free_light": "off", "glasses_lights_off": true', 'glasses'),
  ]) {
    test('the old switch wins over a disagreeing new key in a profile: {$pair}', () {
      final profile = SettingsProfile.parse(_profile('{"kiosk": {$pair}}'));
      final row = profile.diff(parseKioskSettings('{"kiosk": {}}')).single;
      expect((row.id, row.newText), ('kiosk.glare_free_light', mode));
      expect(row.writes, {'kiosk.glare_free_light': mode, 'kiosk.glasses_lights_off': mode != 'off'});
    });

    test('the old switch wins over a disagreeing new key on the kiosk: {$pair}', () {
      final profile = SettingsProfile.parse(_profile('{"kiosk": {"glare_free_light": "$mode"}}'));
      final row = profile.diff(parseKioskSettings('{"kiosk": {$pair}}')).single;
      expect((row.currentText, row.differs), (mode, false));
    });
  }

  test('a kiosk without the new key shows its glasses switch as the current value', () {
    final profile = SettingsProfile.parse(_profile('{"kiosk": {"glare_free_light": "glasses"}}'));
    final row = profile.diff(parseKioskSettings('{"kiosk": {"glasses_lights_off": true}}')).single;
    expect((row.currentText, row.differs), ('glasses', false));
  });

  test('off, glasses or everyone only; the white balance 0 or 2800-6500', () {
    expect(
        () => SettingsProfile.parse(_profile('{"kiosk": {"glare_free_light": "Everyone"}}')),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('"off", "glasses" or "everyone"'))));
    for (final bad in ['9000', '2799', '"5300"', 'true']) {
      expect(
          () => SettingsProfile.parse(_profile('{"kiosk": {"glare_free_white_balance": $bad}}')),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('2800 to 6500'))),
          reason: bad);
    }
    final row = SettingsProfile.parse(_profile('{"kiosk": {"glare_free_white_balance": 4800}}'))
        .diff(parseKioskSettings('{"kiosk": {"glare_free_white_balance": 5300}}'))
        .single;
    expect((row.label, row.currentText, row.newText), ('Glare-free white balance (K)', '5300', '4800'));
    expect(SettingsProfile.parse(_profile('{"kiosk": {"glare_free_white_balance": 0}}')), isNotNull);
  });
}
