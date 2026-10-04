// Settings profiles: a small JSON file that travels with a server update and
// moves a kiosk's settings to known-good values for the new server generation.
//
// WHY: an update carries the kiosk's own settings across, which is right for
// everything that belongs to the kiosk (calibration, per-camera tuning, LED
// layout, photo format …) and wrong for values that were merely the DEFAULT
// of their time — a 2025 board keeps 1280x720 and two quality checks forever,
// because the server only adds missing keys and never changes existing ones.
// The settings file cannot tell the two kinds apart; a profile can.
//
// A profile therefore
//   * addresses kiosk_settings.json ONLY — the calibration
//     (light_settings.json) and the per-camera tuning (camera_settings.json)
//     cannot be expressed in one at all;
//   * may only contain the generation-level settings whitelisted below; keys
//     that belong to the individual kiosk are rejected by name, unknown keys
//     and out-of-range values are rejected too, so a typo cannot damage a
//     kiosk;
//   * is never applied blindly: the operator reviews a before/after list per
//     kiosk and can untick rows (the headless CLI applies every row).
//
// Format:
//   {
//     "profile": "Recommended settings for FaceSnap Server 2.0",
//     "description": "…",
//     "kiosk_settings": { "camera": {"width": 3840, "height": 2160},
//                         "kiosk": {"background_method": "mediapipe", …} }
//   }
import 'dart:convert';

/// The profile the updater offers out of the box. The same content lives as a
/// file in profiles/recommended-server-2.0.json (a test keeps them identical)
/// so it can be copied and adapted into a custom profile.
const kRecommendedProfileJson = '''
{
  "profile": "Recommended settings for FaceSnap Server 2.0",
  "description": "4K photos, every quality check on, fast mediapipe background. OFIQ scoring stays off: it adds about 2.4 s per capture on the kiosk boards.",
  "kiosk_settings": {
    "camera": {
      "width": 3840,
      "height": 2160
    },
    "kiosk": {
      "face_quality": {
        "eyes_check": true,
        "lips_check": true,
        "eye_glasses_check": true,
        "head_pose_check": true,
        "sharpness_check": true,
        "red_eye_detection_check": true,
        "head_size_check": true,
        "expression_check": true,
        "gaze_check": true,
        "lighting_evenness_check": true
      },
      "background_method": "mediapipe",
      "jpeg_quality": 95,
      "ofiq_checks": false
    }
  }
}
''';

const _resolutions = ['1280x720', '1920x1080', '3840x2160', '4000x3000'];

const _qualityChecks = {
  'eyes_check': 'Eyes open check',
  'lips_check': 'Lips closed check',
  'eye_glasses_check': 'Glasses check',
  'head_pose_check': 'Head pose check',
  'sharpness_check': 'Sharpness check',
  'red_eye_detection_check': 'Red eye check',
  'head_size_check': 'Head size/position check',
  'expression_check': 'Expression check',
  'gaze_check': 'Gaze check',
  'lighting_evenness_check': 'Lighting evenness check',
};

/// Settings a profile must never touch, with the reason shown to the author.
const _protected = {
  'camera.rotate_frames': 'depends on how the cameras are mounted',
  'kiosk.crop': 'part of the kiosk\'s photo product',
  'kiosk.crop_width': 'part of the kiosk\'s photo product',
  'kiosk.crop_height': 'part of the kiosk\'s photo product',
  'kiosk.photo_format': 'part of the kiosk\'s photo product',
  'kiosk.background_color': 'part of the kiosk\'s photo product',
  'kiosk.distance_min': 'depends on the kiosk\'s build',
  'kiosk.distance_max': 'depends on the kiosk\'s build',
  'kiosk.expected_cameras': 'depends on the kiosk\'s hardware',
  'lighting.on': 'depends on the kiosk\'s hardware',
  'lighting.color': 'tuned per kiosk',
  'lighting.intensity_red': 'tuned per kiosk',
  'lighting.intensity_green': 'tuned per kiosk',
  'lighting.intensity_blue': 'tuned per kiosk',
  'lighting.led_layout': 'depends on the kiosk\'s LED hardware',
  'lighting.focus_color': 'tuned per kiosk',
  'lighting.focus_intensity': 'tuned per kiosk',
};

/// One reviewable row: a setting, what the kiosk has now, what the profile
/// wants. [writes] are the dotted-path assignments the row stands for (the
/// resolution row writes width AND height).
class ProfileChange {
  ProfileChange({
    required this.id,
    required this.label,
    required this.currentText,
    required this.newText,
    required this.differs,
    required this.writes,
  });

  final String id;
  final String label;
  final String currentText;
  final String newText;

  /// false = the kiosk already has this value; nothing to apply.
  final bool differs;
  final Map<String, Object> writes;
}

class SettingsProfile {
  SettingsProfile._(this.name, this.description, this._values);

  final String name;
  final String description;

  /// Validated dotted path -> value (e.g. "kiosk.jpeg_quality" -> 95).
  final Map<String, Object> _values;

  static SettingsProfile recommended() => parse(kRecommendedProfileJson);

  /// Parses and validates; throws a [FormatException] listing EVERY problem.
  static SettingsProfile parse(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException catch (e) {
      throw FormatException('Not valid JSON: ${e.message}');
    }
    if (root is! Map<String, dynamic>) {
      throw const FormatException('A profile must be a JSON object.');
    }

    final problems = <String>[];
    for (final key in root.keys) {
      if (key == 'light_settings' || key == 'camera_settings') {
        problems.add('"$key": the calibration and the per-camera tuning '
            'belong to the individual kiosk and cannot be part of a profile.');
      } else if (!const {'profile', 'description', 'kiosk_settings'}
          .contains(key)) {
        problems.add('"$key": unknown top-level entry.');
      }
    }

    final values = <String, Object>{};
    final settings = root['kiosk_settings'];
    if (settings is! Map<String, dynamic> || settings.isEmpty) {
      problems.add('"kiosk_settings" must be an object with at least one '
          'setting.');
    } else {
      _flatten(settings, '', values);
      for (final entry in values.entries) {
        final problem = _validate(entry.key, entry.value);
        if (problem != null) problems.add('"${entry.key}": $problem');
      }
      final hasWidth = values.containsKey('camera.width');
      final hasHeight = values.containsKey('camera.height');
      if (hasWidth != hasHeight) {
        problems.add('"camera.width" and "camera.height" must be set '
            'together.');
      } else if (hasWidth &&
          values['camera.width'] is int &&
          values['camera.height'] is int) {
        final resolution =
            '${values['camera.width']}x${values['camera.height']}';
        if (!_resolutions.contains(resolution)) {
          problems.add('camera resolution $resolution is not one of '
              '${_resolutions.join(', ')}.');
        }
      }
    }

    if (problems.isNotEmpty) {
      throw FormatException(
          'The settings profile cannot be used:\n- ${problems.join('\n- ')}');
    }
    final name = root['profile'];
    final description = root['description'];
    return SettingsProfile._(
        name is String && name.trim().isNotEmpty ? name : 'Settings profile',
        description is String ? description : '',
        values);
  }

  static void _flatten(
      Map<String, dynamic> node, String prefix, Map<String, Object> out) {
    for (final entry in node.entries) {
      final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        _flatten(value, path, out);
      } else {
        out[path] = value ?? 'null';
      }
    }
  }

  /// null = fine, otherwise what is wrong with this path/value.
  static String? _validate(String path, Object value) {
    final protectedReason = _protected[path];
    if (protectedReason != null) {
      return 'belongs to the individual kiosk ($protectedReason) and cannot '
          'be set by a profile.';
    }
    if (path == 'camera.width' || path == 'camera.height') {
      return value is int ? null : 'must be a whole number.';
    }
    if (path.startsWith('kiosk.face_quality.')) {
      final check = path.substring('kiosk.face_quality.'.length);
      if (!_qualityChecks.containsKey(check)) return 'unknown quality check.';
      return value is bool ? null : 'must be true or false.';
    }
    switch (path) {
      case 'kiosk.background_method':
        const methods = ['none', 'mediapipe', 'modnet', 'withoutbg'];
        // 'rembg' (retired, now withoutBG) stays valid: a profile saved from an
        // older server may carry it, and a current server takes it as withoutbg.
        return methods.contains(value) || value == 'rembg'
            ? null
            : 'must be one of ${methods.join(', ')}.';
      case 'kiosk.background_strength':
        return value is int && value >= 1 && value <= 5
            ? null
            : 'must be a whole number from 1 (mild) to 5 (heavy).';
      case 'kiosk.jpeg_quality':
        return value is int && value >= 50 && value <= 100
            ? null
            : 'must be a whole number from 50 to 100.';
      case 'kiosk.ofiq_checks':
      case 'kiosk.glasses_lights_off':
      case 'kiosk.leds_off_for_photo':
        return value is bool ? null : 'must be true or false.';
      case 'kiosk.camera_ordering_mode':
        return value == 'manual' || value == 'automatic'
            ? null
            : 'must be "manual" or "automatic".';
    }
    return 'unknown setting — a profile may only contain the camera '
        'resolution, the quality checks, background_method, '
        'background_strength, jpeg_quality, '
        'ofiq_checks, glasses_lights_off, leds_off_for_photo and '
        'camera_ordering_mode.';
  }

  static const _labels = {
    'kiosk.background_method': 'Background removal',
    'kiosk.background_strength': 'Background erasing strength',
    'kiosk.jpeg_quality': 'JPEG quality',
    'kiosk.ofiq_checks': 'OFIQ quality report',
    'kiosk.glasses_lights_off': 'Lights off for glasses',
    'kiosk.leds_off_for_photo': 'Lights off for the photo',
    'kiosk.camera_ordering_mode': 'Camera ordering',
  };

  static String _show(Object? value) => switch (value) {
        null => 'not set',
        true => 'on',
        false => 'off',
        _ => '$value',
      };

  static Object? _lookup(Map<String, dynamic> settings, String path) {
    Object? node = settings;
    for (final part in path.split('.')) {
      if (node is! Map<String, dynamic>) return null;
      node = node[part];
    }
    return node;
  }

  /// The review list for one kiosk: every setting of the profile against the
  /// kiosk's [current] kiosk_settings.json content ({} when it has none).
  List<ProfileChange> diff(Map<String, dynamic> current) {
    final rows = <ProfileChange>[];
    if (_values.containsKey('camera.width')) {
      final width = _values['camera.width']!;
      final height = _values['camera.height']!;
      final nowWidth = _lookup(current, 'camera.width');
      final nowHeight = _lookup(current, 'camera.height');
      rows.add(ProfileChange(
        id: 'camera.resolution',
        label: 'Camera resolution',
        currentText: nowWidth == null || nowHeight == null
            ? 'not set'
            : '$nowWidth×$nowHeight',
        newText: '$width×$height',
        differs: nowWidth != width || nowHeight != height,
        writes: {'camera.width': width, 'camera.height': height},
      ));
    }
    for (final entry in _values.entries) {
      final path = entry.key;
      if (path == 'camera.width' || path == 'camera.height') continue;
      final now = _lookup(current, path);
      rows.add(ProfileChange(
        id: path,
        label: _labels[path] ??
            _qualityChecks[path.split('.').last] ??
            path,
        currentText: _show(now),
        newText: _show(entry.value),
        differs: now != entry.value,
        writes: {path: entry.value},
      ));
    }
    return rows;
  }
}

/// [current] with the [changes] written into it (a deep copy; intermediate
/// objects are created as needed, everything else is left untouched).
Map<String, dynamic> applyProfileChanges(
    Map<String, dynamic> current, Iterable<ProfileChange> changes) {
  final result = jsonDecode(jsonEncode(current)) as Map<String, dynamic>;
  for (final change in changes) {
    for (final write in change.writes.entries) {
      final parts = write.key.split('.');
      var node = result;
      for (final part in parts.take(parts.length - 1)) {
        final next = node[part];
        if (next is Map<String, dynamic>) {
          node = next;
        } else {
          node = node[part] = <String, dynamic>{};
        }
      }
      node[parts.last] = write.value;
    }
  }
  return result;
}

/// Parses a kiosk_settings.json as read from a kiosk; anything unusable (no
/// file, empty, broken JSON, not an object) counts as "no settings yet".
Map<String, dynamic> parseKioskSettings(String text) {
  try {
    final decoded = jsonDecode(text);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

/// kiosk_settings.json text as the servers write it (4-space indent).
String encodeKioskSettings(Map<String, dynamic> settings) =>
    '${const JsonEncoder.withIndent('    ').convert(settings)}\n';
