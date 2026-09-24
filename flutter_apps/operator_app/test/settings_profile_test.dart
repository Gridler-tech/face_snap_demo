// Settings profiles: validation (what a profile may and may not contain), the
// per-kiosk review list, and the apply step. The "2025 kiosk" sample is the
// real kiosk_settings.json of a first-generation face_snap:1.4.0 board.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/settings_profile.dart';

const _kiosk2025 = '''
{"camera": {"width": 1280, "height": 720, "brightness": 128, "contrast": 128,
            "saturation": 128, "hue": 0},
 "kiosk": {"face_quality": {"eyes_check": true, "lips_check": true},
           "crop": true, "crop_width": 700, "crop_height": 900,
           "distance_min": 0, "distance_max": 200},
 "lighting": {"on": true, "color": "FFFFFF", "intensity_red": 200,
              "intensity_green": 200, "intensity_blue": 200}}
''';

String _profile(String kioskSettings) =>
    '{"profile": "t", "kiosk_settings": $kioskSettings}';

Matcher _rejects(String fragment) => throwsA(isA<FormatException>()
    .having((e) => e.message, 'message', contains(fragment)));

void main() {
  group('the recommended profile', () {
    test('is valid and matches the file shipped in profiles/', () {
      final builtIn = jsonDecode(kRecommendedProfileJson);
      final file = jsonDecode(
          File('profiles/recommended-server-2.0.json').readAsStringSync());
      expect(builtIn, file);
      expect(SettingsProfile.recommended().name, contains('Server 2.0'));
    });

    test('against a 2025 kiosk: resolution, checks, background change', () {
      final rows = SettingsProfile.recommended()
          .diff(parseKioskSettings(_kiosk2025));
      final byId = {for (final r in rows) r.id: r};

      final resolution = byId['camera.resolution']!;
      expect(resolution.currentText, '1280×720');
      expect(resolution.newText, '3840×2160');
      expect(resolution.differs, isTrue);

      // Already on in 2025: listed, but nothing to apply.
      expect(byId['kiosk.face_quality.eyes_check']!.differs, isFalse);
      // Did not exist in 2025.
      final sharpness = byId['kiosk.face_quality.sharpness_check']!;
      expect(sharpness.currentText, 'not set');
      expect(sharpness.newText, 'on');
      expect(byId['kiosk.background_method']!.newText, 'mediapipe');
      // width/height are ONE row.
      expect(byId.containsKey('camera.width'), isFalse);
    });

    test('against a kiosk that already has it: nothing differs', () {
      final profile = SettingsProfile.recommended();
      final applied = applyProfileChanges(
          parseKioskSettings(_kiosk2025), profile.diff(const {}));
      expect(profile.diff(applied).where((r) => r.differs), isEmpty);
    });
  });

  group('applyProfileChanges', () {
    test('writes only the ticked rows and leaves everything else alone', () {
      final current = parseKioskSettings(_kiosk2025);
      final rows = SettingsProfile.recommended().diff(current);
      final ticked = rows.where((r) => r.id == 'camera.resolution');
      final result = applyProfileChanges(current, ticked);

      expect(result['camera']['width'], 3840);
      expect(result['camera']['height'], 2160);
      expect(result['camera']['brightness'], 128); // untouched sibling
      expect(result['lighting'], current['lighting']); // kiosk-owned, untouched
      expect(result['kiosk']['crop_width'], 700);
      expect(result['kiosk'].containsKey('background_method'), isFalse);
      // The input is not mutated.
      expect(current['camera']['width'], 1280);
    });

    test('creates missing objects on a kiosk without settings', () {
      final rows = SettingsProfile.recommended().diff(const {});
      final result = applyProfileChanges(const {}, rows);
      expect(result['kiosk']['face_quality']['gaze_check'], isTrue);
      expect(result['kiosk']['jpeg_quality'], 95);
    });

    test('round-trips through the file encoding', () {
      final result = applyProfileChanges(parseKioskSettings(_kiosk2025),
          SettingsProfile.recommended().diff(parseKioskSettings(_kiosk2025)));
      expect(parseKioskSettings(encodeKioskSettings(result)), result);
    });
  });

  group('a profile is rejected when it', () {
    test('touches a setting that belongs to the kiosk', () {
      expect(
          () => SettingsProfile.parse(
              _profile('{"lighting": {"led_layout": "ring"}}')),
          _rejects('belongs to the individual kiosk'));
      expect(
          () => SettingsProfile.parse(
              _profile('{"kiosk": {"photo_format": "us_2x2"}}')),
          _rejects('belongs to the individual kiosk'));
      expect(
          () => SettingsProfile.parse(
              _profile('{"kiosk": {"expected_cameras": 4}}')),
          _rejects('belongs to the individual kiosk'));
    });

    test('tries to carry calibration or camera tuning', () {
      expect(
          () => SettingsProfile.parse('{"kiosk_settings": {"kiosk": '
              '{"ofiq_checks": true}}, "light_settings": []}'),
          _rejects('calibration'));
    });

    test('contains an unknown or misspelled setting', () {
      expect(
          () => SettingsProfile.parse(
              _profile('{"kiosk": {"background_methd": "mediapipe"}}')),
          _rejects('unknown setting'));
      expect(
          () => SettingsProfile.parse(_profile(
              '{"kiosk": {"face_quality": {"smile_check": true}}}')),
          _rejects('unknown quality check'));
    });

    test('has a wrong type, value or resolution', () {
      expect(
          () => SettingsProfile.parse(
              _profile('{"kiosk": {"jpeg_quality": 500}}')),
          _rejects('50 to 100'));
      expect(
          () => SettingsProfile.parse(
              _profile('{"kiosk": {"background_method": "magic"}}')),
          _rejects('must be one of'));
      expect(
          () => SettingsProfile.parse(
              _profile('{"kiosk": {"ofiq_checks": "yes"}}')),
          _rejects('true or false'));
      expect(
          () => SettingsProfile.parse(
              _profile('{"camera": {"width": 1234, "height": 567}}')),
          _rejects('is not one of'));
      expect(
          () => SettingsProfile.parse(_profile('{"camera": {"width": 3840}}')),
          _rejects('must be set together'));
    });

    test('is empty, not an object, or not JSON — and lists EVERY problem', () {
      expect(() => SettingsProfile.parse('nope'), _rejects('Not valid JSON'));
      expect(() => SettingsProfile.parse('[]'), _rejects('JSON object'));
      expect(() => SettingsProfile.parse(_profile('{}')),
          _rejects('at least one'));
      expect(
          () => SettingsProfile.parse(_profile(
              '{"kiosk": {"jpeg_quality": 5, "crop": false, "x": 1}}')),
          throwsA(isA<FormatException>().having(
              (e) => '- '.allMatches(e.message).length, 'problem count', 3)));
    });
  });

  test('unusable kiosk settings count as "no settings yet"', () {
    expect(parseKioskSettings(''), isEmpty);
    expect(parseKioskSettings('{broken'), isEmpty);
    expect(parseKioskSettings('[1, 2]'), isEmpty);
  });
}
