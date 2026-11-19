// The updater's settings profiles carry the head-turn switch
// (kiosk.liveness_head_turn_check, spec 2026-10-08 section 3.2): a valid
// profile setting with its own label, true or false only.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/settings_profile.dart';

String _profile(String kioskSettings) =>
    '{"profile": "t", "kiosk_settings": $kioskSettings}';

void main() {
  test('the head-turn switch is a valid profile setting with its own label', () {
    final profile = SettingsProfile.parse(
        _profile('{"kiosk": {"liveness_head_turn_check": true}}'));
    final row = profile.diff(parseKioskSettings('{"kiosk": {}}')).single;
    expect(row.id, 'kiosk.liveness_head_turn_check');
    expect(row.label, 'Live person check: head turn');
    expect((row.currentText, row.newText, row.differs), ('not set', 'on', true));
  });

  test('anything but true or false is refused', () {
    expect(
        () => SettingsProfile.parse(
            _profile('{"kiosk": {"liveness_head_turn_check": 1}}')),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'message', contains('must be true or false'))));
  });
}
