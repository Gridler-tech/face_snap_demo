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
//                         "kiosk": {"background_method": "none", …} }
//   }
import 'dart:convert';

/// The profile the updater offers out of the box. The same content lives as a
/// file in profiles/recommended-server-2.0.json (a test keeps them identical)
/// so it can be copied and adapted into a custom profile.
const kRecommendedProfileJson = '''
{
  "profile": "Recommended settings for FaceSnap Server 2.0",
  "description": "4K photos and every quality check on, with the 1.1.27 defaults: no background erasing, the ICAO report, OFIQ scoring and the live person check off, nothing loaded at server start. Automatic white balance, exposure and focus are camera settings of each kiosk: a profile leaves them alone.",
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
      "background_method": "none",
      "jpeg_quality": 95,
      "ofiq_checks": false,
      "icao_report": false,
      "liveness_check": false,
      "capture_warm_up": []
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
  'kiosk.camera_hub_upside_down': 'depends on how the USB hub is mounted',
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

  /// Settings a profile may still carry from an older app version; dropped on load
  /// (the light checks were removed in 2026-10).
  static const _retired = {'kiosk.liveness_shading_check', 'kiosk.liveness_colour_check'};

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
      values.removeWhere((key, _) => _retired.contains(key));
      // A profile from before the glare-free light carries the glasses switch only: it reads
      // as the 3-way setting (true = "glasses", false = "off"); with both, as the servers read
      // them (glareFreeModeOf). An invalid new value stays for the validation's message.
      final oldGlasses = values['kiosk.glasses_lights_off'];
      if (oldGlasses is bool) {
        values.remove('kiosk.glasses_lights_off');
        final stored = values['kiosk.glare_free_light'];
        if (stored == null || _glareFreeModes.contains(stored)) {
          values['kiosk.glare_free_light'] = glareFreeModeOf(stored, oldGlasses)!;
        }
      }
      if (values.isEmpty) {
        // Only retired keys: nothing left to set.
        problems.add('"kiosk_settings" must be an object with at least one '
            'setting.');
      }
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
    if (path.startsWith('kiosk.capture_warm_up.')) return _warmUpRefusal;   // an object, flattened
    // The colour matrices are measured on each kiosk and travel with its column (the
    // column profile's colour_correction): an object, flattened.
    if (path == 'kiosk.colour_matrices' || path.startsWith('kiosk.colour_matrices.')) {
      return 'belongs to the individual kiosk (measured on its column) and cannot be set '
          'by a profile.';
    }
    if (path.startsWith('kiosk.face_quality.')) {
      final check = path.substring('kiosk.face_quality.'.length);
      if (!_qualityChecks.containsKey(check)) return 'unknown quality check.';
      return value is bool ? null : 'must be true or false.';
    }
    switch (path) {
      case 'kiosk.background_method':
        const methods = ['none', 'mediapipe', 'modnet', 'withoutbg', 'gridler'];
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
      case 'kiosk.icao_report':
      case 'kiosk.liveness_check':
      case 'kiosk.liveness_head_turn_check':
      case 'kiosk.glasses_lights_off':
      case 'kiosk.leds_off_for_photo':
      case 'kiosk.colour_correction':
        return value is bool ? null : 'must be true or false.';
      case 'kiosk.glare_free_light':
        return const ['off', 'glasses', 'everyone'].contains(value)
            ? null
            : 'must be "off", "glasses" or "everyone".';
      case 'kiosk.glare_free_white_balance':
        return value is int && (value == 0 || (value >= 2800 && value <= 6500))
            ? null
            : 'must be 0 (the camera\'s own value) or a whole number of kelvin from 2800 to 6500.';
      case 'kiosk.camera_ordering_mode':
        return value == 'manual' || value == 'automatic'
            ? null
            : 'must be "manual" or "automatic".';
      case 'kiosk.capture_warm_up':
        return _warmUpList(value) != null ? null : _warmUpRefusal;
    }
    return 'unknown setting — a profile may only contain the camera '
        'resolution, the quality checks, background_method, '
        'background_strength, jpeg_quality, '
        'ofiq_checks, icao_report, liveness_check, liveness_head_turn_check, '
        'glare_free_light, glare_free_white_balance, glasses_lights_off, '
        'leds_off_for_photo, colour_correction, capture_warm_up and '
        'camera_ordering_mode.';
  }

  /// The capture warm-up's names (kiosk.capture_warm_up, spec 2026-10-11 section 4.7), in the
  /// order both servers store them.
  static const _warmUpItems = ['modnet', 'withoutbg', 'gridler', 'ofiq'];
  static const _warmUpRefusal = 'must be a list of names from modnet, withoutbg, gridler, ofiq.';

  /// A profile's warm-up list as the servers store it (no duplicates, in [_warmUpItems] order),
  /// or null when it is not a list of those names (SetCaptureWarmUp refuses it all).
  static List<String>? _warmUpList(Object? value) {
    if (value is! List || value.any((item) => !_warmUpItems.contains(item))) return null;
    return _warmUpItems.where(value.contains).toList();
  }

  /// A kiosk's stored list as the servers read it: unknown names skipped; null when it is not
  /// a list.
  static List<String>? _storedWarmUp(Object? value) =>
      value is List ? _warmUpItems.where(value.contains).toList() : null;

  static String _warmUpText(List<String> items) => items.isEmpty ? 'none' : items.join(', ');

  static const _labels = {
    'kiosk.background_method': 'Background removal',
    'kiosk.background_strength': 'Background erasing strength',
    'kiosk.jpeg_quality': 'JPEG quality',
    'kiosk.ofiq_checks': 'OFIQ quality report',
    'kiosk.icao_report': 'ICAO compliance report',
    'kiosk.liveness_check': 'Live person check',
    'kiosk.liveness_head_turn_check': 'Live person check: head turn',
    'kiosk.glasses_lights_off': 'Lights off for glasses',
    'kiosk.glare_free_light': 'Glare-free light',
    'kiosk.glare_free_white_balance': 'Glare-free white balance (K)',
    'kiosk.leds_off_for_photo': 'Lights off for the photo',
    'kiosk.colour_correction': 'Photo colour correction',
    'kiosk.camera_ordering_mode': 'Camera ordering',
    'kiosk.capture_warm_up': 'Capture warm-up',
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
      if (path == 'kiosk.glare_free_light') {
        rows.add(_glareFreeRow(current, entry.value));
        continue;
      }
      if (path == 'kiosk.capture_warm_up') {
        rows.add(_warmUpRow(current, entry.value));
        continue;
      }
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

  /// The capture warm-up's row: the lists compared as the servers store them (the same names
  /// in another order are no change); it writes the stored form.
  ProfileChange _warmUpRow(Map<String, dynamic> current, Object wanted) {
    final items = _warmUpList(wanted)!;
    final now = _lookup(current, 'kiosk.capture_warm_up');
    final stored = _storedWarmUp(now);
    return ProfileChange(
      id: 'kiosk.capture_warm_up',
      label: _labels['kiosk.capture_warm_up']!,
      currentText: stored == null ? _show(now) : _warmUpText(stored),
      newText: _warmUpText(items),
      differs: stored == null || _warmUpText(stored) != _warmUpText(items),
      writes: {'kiosk.capture_warm_up': items},
    );
  }

  /// The glare-free light's row: the kiosk's value from its glare_free_light, or - a kiosk
  /// from before the setting - from its glasses switch; it writes both keys, as the server
  /// does (glasses_lights_off true unless "off").
  ProfileChange _glareFreeRow(Map<String, dynamic> current, Object wanted) {
    final now = glareFreeModeOf(
        _lookup(current, 'kiosk.glare_free_light'), _lookup(current, 'kiosk.glasses_lights_off'));
    return ProfileChange(
      id: 'kiosk.glare_free_light',
      label: _labels['kiosk.glare_free_light']!,
      currentText: _show(now),
      newText: _show(wanted),
      differs: now != wanted,
      writes: {'kiosk.glare_free_light': wanted, 'kiosk.glasses_lights_off': wanted != 'off'},
    );
  }
}

const _glareFreeModes = ['off', 'glasses', 'everyone'];

/// The glare-free light of a stored pair, as both servers read kiosk_settings.json
/// (glare_free_light.py stored_mode / GlareFreeLights.Stored): the new key when it is one of
/// the modes - unless the old switch is a bool that disagrees with it, then the old switch wins
/// (ruling R26: only an old writer changes it alone; true with "off" is "glasses", false with
/// "glasses" or "everyone" is "off"). Without a valid new key the old switch (true = "glasses",
/// false = "off"); null without either.
String? glareFreeModeOf(Object? stored, Object? oldSwitch) {
  if (stored is! String || !_glareFreeModes.contains(stored)) {
    return oldSwitch is bool ? (oldSwitch ? 'glasses' : 'off') : null;
  }
  if (oldSwitch == true && stored == 'off') return 'glasses';
  if (oldSwitch == false && stored != 'off') return 'off';
  return stored;
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
