// The Capture page's "Only for this capture" panel: per-capture settings
// (Kiosk.StartAutomaticCapture / StartManualCapture). A field set here applies
// to the next captures of this app only; an unset field keeps the kiosk's value,
// shown greyed. Nothing here is persisted: no settings RPC, no config file — the
// values live only while the app runs, and Clear empties them.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_state.dart';
import '../ui/ui.dart';

enum OverrideKind { flag, choice, number, text }

/// One CaptureSettings field: its proto name and number, the label shown, and
/// whether a manual capture uses it.
class OverrideField {
  const OverrideField(
    this.name,
    this.number,
    this.label,
    this.kind, {
    this.choices = const [],
    this.enumChoices = const {},
    this.manual = false,
  });

  final String name;
  final int number;
  final String label;
  final OverrideKind kind;

  /// The fixed values of a choice field (no other value can be picked).
  final List<String> choices;

  /// An enum choice field's values by the name shown (lap): its unset entry is
  /// "none", not the kiosk's value (the field is per capture only).
  final Map<String, Object> enumChoices;

  /// Used by a manual capture (the others are automatic-capture only).
  final bool manual;
}

/// The child-on-lap choices (CaptureSettings.lap, spec 2026-10-19): "none" is
/// the field unset, "child" the lower face as the subject, "baby" (under 1) the
/// lower face with relaxed checks.
const lapChoices = <String, Object>{
  'child': LapSubject.LAP_CHILD,
  'baby': LapSubject.LAP_BABY,
};

/// Every CaptureSettings field, in field order.
const overrideFields = [
  OverrideField(
    'photo_format',
    1,
    'Photo format',
    OverrideKind.choice,
    choices: ['icao_35x45', 'us_2x2', 'ca_50x70', 'iso_enrolment'],
  ),
  OverrideField('crop', 2, 'Crop photo', OverrideKind.flag),
  OverrideField('crop_width', 3, 'Crop width (px)', OverrideKind.number),
  OverrideField(
    'jpeg_quality',
    4,
    'JPEG quality',
    OverrideKind.number,
    manual: true,
  ),
  OverrideField(
    'background_method',
    5,
    'Background erasing',
    OverrideKind.choice,
    choices: ['none', 'mediapipe', 'modnet', 'withoutbg', 'gridler'],
  ),
  OverrideField(
    'background_color',
    6,
    'Background colour (hex)',
    OverrideKind.text,
  ),
  OverrideField(
    'background_strength',
    7,
    'Erasing strength (1-5)',
    OverrideKind.number,
  ),
  OverrideField(
    'glare_free_light',
    8,
    'Glare-free light',
    OverrideKind.choice,
    choices: ['off', 'glasses', 'everyone'],
    manual: true,
  ),
  OverrideField(
    'photo_light',
    9,
    'Photo light',
    OverrideKind.choice,
    choices: ['all', 'neighbours'],
    manual: true,
  ),
  OverrideField(
    'leds_off_for_photo',
    10,
    'LEDs off for the photo',
    OverrideKind.flag,
    manual: true,
  ),
  OverrideField('eyes_check', 11, 'Eyes check', OverrideKind.flag),
  OverrideField('lips_check', 12, 'Lips check', OverrideKind.flag),
  OverrideField('eye_glasses_check', 13, 'Glasses check', OverrideKind.flag),
  OverrideField('head_pose_check', 14, 'Head pose check', OverrideKind.flag),
  OverrideField('sharpness_check', 15, 'Sharpness check', OverrideKind.flag),
  OverrideField(
    'red_eye_detection_check',
    16,
    'Red eye check',
    OverrideKind.flag,
  ),
  OverrideField('head_size_check', 17, 'Head size check', OverrideKind.flag),
  OverrideField('expression_check', 18, 'Expression check', OverrideKind.flag),
  OverrideField('gaze_check', 19, 'Gaze check', OverrideKind.flag),
  OverrideField(
    'lighting_evenness_check',
    20,
    'Lighting evenness check',
    OverrideKind.flag,
  ),
  OverrideField('ofiq_checks', 21, 'OFIQ report', OverrideKind.flag),
  OverrideField('icao_report', 22, 'ICAO report', OverrideKind.flag),
  OverrideField('liveness_check', 23, 'Live person check', OverrideKind.flag),
  OverrideField(
    'liveness_head_turn_check',
    24,
    'Head turn check',
    OverrideKind.flag,
  ),
  OverrideField('distance_min', 25, 'Distance min (cm)', OverrideKind.number),
  OverrideField('distance_max', 26, 'Distance max (cm)', OverrideKind.number),
  OverrideField(
    'colour_correction',
    27,
    'Colour correction',
    OverrideKind.flag,
    manual: true,
  ),
  OverrideField(
    'lap',
    28,
    'Child on lap',
    OverrideKind.choice,
    enumChoices: lapChoices,
  ),
];

/// A field value as shown: on/off for a yes/no, the value itself otherwise,
/// '—' for nothing (an older server's empty value).
String overrideValueText(Object? value) => switch (value) {
  null || '' => '—',
  true => 'on',
  false => 'off',
  LapSubject.LAP_CHILD => 'child',
  LapSubject.LAP_BABY => 'baby',
  LapSubject() => 'none',
  _ => '$value',
};

/// The kiosk's value in force for [field], from the settings snapshot.
Object? kioskValue(LoadSettingsResponse? s, String field) {
  if (s == null) return null;
  return switch (field) {
    'photo_format' => s.photoFormat,
    'crop' => s.crop,
    'crop_width' => s.cropWidth,
    'jpeg_quality' => s.jpegQuality,
    'background_method' => s.backgroundMethod,
    'background_color' => s.backgroundColor,
    'background_strength' => s.backgroundStrength,
    'glare_free_light' => switch (s.glareFreeLight) {
      GlareFreeLight.GLARE_FREE_LIGHT_GLASSES => 'glasses',
      GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE => 'everyone',
      _ => 'off',
    },
    'photo_light' => s.photoLight,
    'leds_off_for_photo' => s.ledsOffForPhoto,
    'eyes_check' => s.eyesCheck,
    'lips_check' => s.lipsCheck,
    'eye_glasses_check' => s.eyeGlassesCheck,
    'head_pose_check' => s.headPoseCheck,
    'sharpness_check' => s.sharpnessCheck,
    'red_eye_detection_check' => s.redEyeDetectionCheck,
    'head_size_check' => s.headSizeCheck,
    'expression_check' => s.expressionCheck,
    'gaze_check' => s.gazeCheck,
    'lighting_evenness_check' => s.lightingEvennessCheck,
    'ofiq_checks' => s.ofiqChecks,
    'icao_report' => s.icaoReport,
    'liveness_check' => s.livenessCheck,
    'liveness_head_turn_check' => s.livenessHeadTurnCheck,
    'distance_min' => s.distanceMin,
    'distance_max' => s.distanceMax,
    // A server without the correction sends no colour_corrections: nothing to show.
    'colour_correction' =>
      s.colourCorrections.isEmpty ? null : s.colourCorrection,
    _ => null,
  };
}

/// The panel's values: the CaptureSettings the next capture sends. In memory
/// only, for the app's lifetime.
class CaptureOverrides {
  CaptureOverrides._();

  static CaptureSettings current = CaptureSettings();

  /// Bumped on every change (the badge and the panel listen).
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// The number of fields set.
  static int get count => fieldsSet(current);

  /// The number of per-capture fields set in [settings].
  static int fieldsSet(CaptureSettings settings) =>
      overrideFields.where((f) => settings.hasField(f.number)).length;

  /// Sets [field] to [value]; null unsets it (back to the kiosk's value).
  static void set(OverrideField field, Object? value) {
    if (value == null) {
      if (!current.hasField(field.number)) return;
      current.clearField(field.number);
    } else {
      if (current.hasField(field.number) &&
          current.getField(field.number) == value) {
        return;
      }
      current.setField(field.number, value);
    }
    revision.value++;
  }

  static void clear() {
    current = CaptureSettings();
    revision.value++;
  }

  /// Only the five fields a manual capture uses (jpeg quality, glare-free
  /// light, photo light, LEDs off, colour correction); a manual capture
  /// refuses any other.
  static CaptureSettings forManual() {
    final manual = CaptureSettings();
    for (final f in overrideFields.where((f) => f.manual)) {
      if (current.hasField(f.number)) {
        manual.setField(f.number, current.getField(f.number));
      }
    }
    return manual;
  }
}

/// The "Only for this capture" panel: every per-capture field, the kiosk's
/// value greyed until it is changed, and Clear.
class OverridesPanel extends StatefulWidget {
  const OverridesPanel({super.key, this.fieldsMaxHeight = 220});

  /// The fields scroll inside this height, so the panel leaves the Capture
  /// page room for the photo in a small window.
  final double fieldsMaxHeight;

  @override
  State<OverridesPanel> createState() => _OverridesPanelState();
}

class _OverridesPanelState extends State<OverridesPanel> {
  static const _kiosk = 'kiosk';
  static const _on = 'on';
  static const _off = 'off';
  static const _style = TextStyle(color: T.ink, fontSize: 13);
  static const _mutedStyle = TextStyle(color: T.muted, fontSize: 13);

  final Map<String, TextEditingController> _texts = {
    for (final f in overrideFields)
      if (f.kind == OverrideKind.number || f.kind == OverrideKind.text)
        f.name: TextEditingController(),
  };

  /// The fields are shown. Collapsed while no override is set; opened when
  /// built with overrides (they survive a page change) and when the count
  /// goes from 0 to more — not on every change, so the operator can collapse
  /// the panel while overrides are set.
  late bool _open;
  late int _lastCount;

  @override
  void initState() {
    super.initState();
    // Read now (a late initializer would read it lazily, after a change).
    _lastCount = CaptureOverrides.count;
    _open = _lastCount > 0;
    _syncTexts();
    CaptureOverrides.revision.addListener(_onChanged);
    SettingsState.revision.addListener(_onChanged);
  }

  @override
  void dispose() {
    CaptureOverrides.revision.removeListener(_onChanged);
    SettingsState.revision.removeListener(_onChanged);
    for (final c in _texts.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    _syncTexts();
    final count = CaptureOverrides.count;
    setState(() {
      if (_lastCount == 0 && count > 0) _open = true;
      _lastCount = count;
    });
  }

  /// The text fields follow the values (Clear empties them); a field whose
  /// text already means its value is left alone, so typing keeps its cursor.
  void _syncTexts() {
    for (final f in overrideFields) {
      final controller = _texts[f.name];
      if (controller == null) continue;
      final has = CaptureOverrides.current.hasField(f.number);
      if (has &&
          _parse(f, controller.text) ==
              CaptureOverrides.current.getField(f.number)) {
        continue;
      }
      final text = has ? '${CaptureOverrides.current.getField(f.number)}' : '';
      if (controller.text != text) controller.text = text;
    }
  }

  /// A typed value as the field's type; null = empty (unset) or not a number.
  static Object? _parse(OverrideField f, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return f.kind == OverrideKind.number ? int.tryParse(trimmed) : trimmed;
  }

  /// The kiosk's value as shown greyed. A number of 0 is an older server's
  /// missing value (no per-capture number field is 0 on a current kiosk
  /// unless set so), shown as '—' like the other missing values.
  String _kioskText(OverrideField f) {
    final value = kioskValue(SettingsState.current, f.name);
    if (f.kind == OverrideKind.number && value == 0) return '—';
    return overrideValueText(value);
  }

  Widget _control(OverrideField f) {
    final current = CaptureOverrides.current;
    final has = current.hasField(f.number);
    final key = ValueKey('override-${f.name}');
    switch (f.kind) {
      case OverrideKind.flag:
        final value = !has
            ? _kiosk
            : current.getField(f.number) == true
            ? _on
            : _off;
        return SegmentedButton<String>(
          key: key,
          segments: const [
            ButtonSegment(value: _kiosk, label: Text('Kiosk')),
            ButtonSegment(value: _on, label: Text('On')),
            ButtonSegment(value: _off, label: Text('Off')),
          ],
          selected: {value},
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          onSelectionChanged: (s) => CaptureOverrides.set(
            f,
            s.first == _kiosk ? null : s.first == _on,
          ),
        );
      case OverrideKind.choice when f.enumChoices.isNotEmpty:
        // The shown name of the value set ('' = none, the field unset).
        final name = !has
            ? ''
            : f.enumChoices.entries
                      .where((e) => e.value == current.getField(f.number))
                      .firstOrNull
                      ?.key ??
                  '';
        return DropdownButton<String>(
          key: key,
          value: name,
          isExpanded: true,
          isDense: true,
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('none', style: _mutedStyle),
            ),
            for (final choice in f.enumChoices.keys)
              DropdownMenuItem(
                value: choice,
                child: Text(choice, style: _style),
              ),
          ],
          onChanged: (v) => CaptureOverrides.set(
            f,
            v == null || v.isEmpty ? null : f.enumChoices[v],
          ),
        );
      case OverrideKind.choice:
        return DropdownButton<String>(
          key: key,
          value: has ? current.getField(f.number) as String : '',
          isExpanded: true,
          isDense: true,
          items: [
            DropdownMenuItem(
              value: '',
              child: Text('Kiosk: ${_kioskText(f)}', style: _mutedStyle),
            ),
            for (final choice in f.choices)
              DropdownMenuItem(
                value: choice,
                child: Text(choice, style: _style),
              ),
          ],
          onChanged: (v) =>
              CaptureOverrides.set(f, v == null || v.isEmpty ? null : v),
        );
      case OverrideKind.number:
      case OverrideKind.text:
        final number = f.kind == OverrideKind.number;
        return TextField(
          key: key,
          controller: _texts[f.name],
          style: _style,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          inputFormatters: number
              // An int32 field: digits, at most nine of them.
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ]
              : null,
          decoration: InputDecoration(
            isDense: true,
            // The kiosk's value, greyed, until a value is typed.
            hintText: _kioskText(f),
            hintStyle: _mutedStyle,
          ),
          onChanged: (text) => CaptureOverrides.set(f, _parse(f, text)),
        );
    }
  }

  Widget _fieldTile(OverrideField f) {
    final unsetFlag =
        f.kind == OverrideKind.flag &&
        !CaptureOverrides.current.hasField(f.number);
    return SizedBox(
      width: 258,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  f.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: T.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (unsetFlag) ...[
                const SizedBox(width: 6),
                Text(
                  'kiosk: ${_kioskText(f)}',
                  style: const TextStyle(color: T.muted, fontSize: 12),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          _control(f),
        ],
      ),
    );
  }

  Widget _group(String title, Iterable<OverrideField> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            title,
            style: const TextStyle(
              color: T.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [for (final f in fields) _fieldTile(f)],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = CaptureOverrides.count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // What the panel is: the card's title says "only for this capture";
        // nothing is saved on the kiosk (see the developer-info topic).
        Row(
          children: [
            IconButton(
              key: const ValueKey('overrides-toggle'),
              tooltip: _open ? 'Hide the fields' : 'Show the fields',
              visualDensity: VisualDensity.compact,
              icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _open = !_open),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Manual captures use only JPEG quality, the glare-free light, '
                'the photo light, LEDs off and the colour correction',
                style: TextStyle(color: T.muted, fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 12),
            QuietButton(
              key: const ValueKey('overrides-clear'),
              text: 'Clear',
              width: 96,
              onPressed: count == 0 ? null : CaptureOverrides.clear,
            ),
          ],
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.fieldsMaxHeight),
            child: SingleChildScrollView(
              primary: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _group(
                    'Automatic and manual capture',
                    overrideFields.where((f) => f.manual),
                  ),
                  const SizedBox(height: 14),
                  _group(
                    'Automatic capture only',
                    overrideFields.where((f) => !f.manual),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
