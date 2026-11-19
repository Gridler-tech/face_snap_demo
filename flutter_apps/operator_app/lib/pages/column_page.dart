// The Column page (spec 2026-10-10 section 5.5): the column profile on the LED board - the
// column-bound settings with their factory defaults, the customer's standard and the
// value now (● = changed and not saved), "Save changes as standard" (the changes listed
// first), back to the standard or to the factory defaults per setting, the whole column back
// to factory, and the LED geometry (gbl.py) editor that used to sit on the Lighting page.
import 'dart:convert';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../services/column_state.dart';
import '../services/settings_state.dart';
import '../ui/ui.dart';

/// The column settings' labels, in the profile's order (GetColumnProfile names).
const columnSettingLabels = <String, String>{
  'led_layout': 'LED hardware',
  'led_geometry': 'LED geometry',
  'led_colour': 'LED colour mix',
  'focus_light': 'Focus light',
  'expected_cameras': 'Number of cameras',
  'calibration': 'Camera positions',
  'glare_free_white_balance': 'Glare-free white balance',
  'focus_absolute': 'Camera focus',
  'rotate_frames': 'Frame rotation',
  'colour_correction': 'Photo colour correction (matrices)',
  'hub_upside_down': 'USB hub mounted upside down',
  'backlight_brightness': 'Backlight brightness',
};

/// The colour_correction value's light keys as the table names them.
const _colourLightNames = {'all': 'all LEDs', 'neighbours': 'neighbours', 'glare_free': 'glare-free'};

/// The backlight_brightness value's light scenes as the table names them.
const _backlightLightNames = {'standard': 'standard', 'glare_free': 'glare-free'};

/// The column RPCs' own refusals (server column_profile.py), shown as the server words
/// them. "The LED board did not take the file" is UNAVAILABLE, which [operatorMessage]
/// would otherwise read as an unreachable kiosk. These must stay byte-identical to the
/// servers' shared texts (column_profile.py NO_COLUMN_YET, BOARD_NOT_CONNECTED, NO_FACTORY,
/// WRITE_FAILED and their ColumnProfile.cs twins, pinned equal by the plan): a text that
/// drifts falls back to the generic message.
const _columnRefusals = {
  'no column has been connected to this server yet',
  "the column's LED board is not connected",
  'this column has no factory defaults yet',
  "the column's LED board did not take the file",
};

/// A failed column call as the operator reads it.
String _failureText(Object e) {
  if (e is GrpcError && _columnRefusals.contains(e.message)) return e.message!;
  return operatorMessage(e);
}

/// A setting's value (JSON text, as GetColumnProfile sends it) as the table shows it; "—"
/// when it is not set in that layer. A value present in a settings file but invalid comes
/// as the marker `{"invalid": <the file's value as JSON text>}` (ruling R14).
String columnValueText(String name, String json) {
  if (json.isEmpty) return '—';
  try {
    final value = jsonDecode(json);
    if (value is Map && value.length == 1 && value.containsKey('invalid')) {
      return 'invalid in the settings file: ${value['invalid']}';
    }
    switch (name) {
      case 'led_layout':
        return value == 'ring' ? 'LED rings' : value == 'strip' ? 'LED strips' : '$value';
      case 'led_geometry':
        final geometry = value as Map<String, dynamic>;
        final cameras = [
          for (var i = 1; i <= 6; i++)
            if (geometry['CENTERCAM$i'] != null) '${geometry['CENTERCAM$i']}'
        ];
        return [
          if (geometry['LED_COUNT'] != null) '${geometry['LED_COUNT']} LEDs',
          if (geometry['NUM_LED_RINGS'] != null) '${geometry['NUM_LED_RINGS']} rings',
          if (cameras.isNotEmpty) 'cameras at ${cameras.join('/')}',
        ].join(', ');
      case 'led_colour':
        final colour = value as Map<String, dynamic>;
        return '${colour['red']} / ${colour['green']} / ${colour['blue']}';
      case 'focus_light':
        final focus = value as Map<String, dynamic>;
        return '#${focus['color']} at ${focus['intensity']} %';
      case 'expected_cameras':
        return value == 0 ? 'automatic' : '$value';
      case 'calibration':
        final positions = value as Map<String, dynamic>;
        return positions.isEmpty ? 'none' : '${positions.length} cameras';
      case 'glare_free_white_balance':
        return value == 0 ? "the camera's own" : '$value K';
      case 'rotate_frames':
        return value == true ? 'rotated (portrait)' : 'not rotated';
      case 'colour_correction':
        // {light: {matrix, measured, ...}}; {} = the shipped matrices for every light.
        final lights = (value as Map<String, dynamic>).keys;
        return lights.isEmpty
            ? 'shipped matrices'
            : 'measured here: ${lights.map((l) => _colourLightNames[l] ?? l).join(', ')}';
      case 'hub_upside_down':
        return value == true ? 'yes (camera order mirrored)' : 'no';
      case 'backlight_brightness':
        // {light: {bottom, top}} in %, per light scene.
        final scenes = value as Map<String, dynamic>;
        return [
          for (final MapEntry(key: light, value: level) in scenes.entries)
            '${_backlightLightNames[light] ?? light}: bottom ${level['bottom']} %, top ${level['top']} %',
        ].join(' · ');
      default:
        return '$value';
    }
  } catch (_) {
    return json;
  }
}

class ColumnPage extends StatefulWidget {
  const ColumnPage({super.key});

  @override
  State<ColumnPage> createState() => _ColumnPageState();
}

class _ColumnPageState extends State<ColumnPage> with ServerCallState {
  bool _busy = false;

  SettingsClient get _client => SettingsState.client;

  @override
  void initState() {
    super.initState();
    ColumnState.revision.addListener(_onColumnChanged);
    if (SettingsState.current != null) ColumnState.refresh();
  }

  @override
  void dispose() {
    ColumnState.revision.removeListener(_onColumnChanged);
    super.dispose();
  }

  void _onColumnChanged() {
    if (mounted) setState(() {});
  }

  /// A column action: the error line on failure (prefixed with [failure]), the profile read
  /// again afterwards.
  Future<void> _run(Future<void> Function() action, {String failure = 'Server call failed'}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) setState(() => message = null);
    } catch (e) {
      if (mounted) setState(() => message = '$failure: ${_failureText(e)}');
    } finally {
      await ColumnState.refresh();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? T.fail : null));
  }

  Future<bool> _confirm(String title, Widget body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: body,
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    final changed = [for (final s in ColumnState.current!.settings) if (s.changed) s];
    final ok = await _confirm(
        "Save the changes as the column's standard?",
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final s in changed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                  '${columnSettingLabels[s.name] ?? s.name}: ${columnValueText(s.name, s.standardValue)} '
                  '→ ${columnValueText(s.name, s.currentValue)}',
                  key: ValueKey('save-change-${s.name}')),
            ),
          const SizedBox(height: 10),
          const Text(
              "They are written to the column's LED board and go with the column when it moves to "
              'another server.',
              style: TextStyle(color: T.muted, fontSize: 12.5)),
        ]),
        'Save');
    if (!ok) return;
    await _run(() async {
      final r = await _client.saveColumnStandard(ColumnSettingsRequest());
      if (r.outcome == ColumnSaveOutcome.COLUMN_SAVE_OUTCOME_PENDING) {
        _say('Saved here; written to the column when its LED board is back.');
      } else if (r.outcome == ColumnSaveOutcome.COLUMN_SAVE_OUTCOME_NOTHING) {
        _say('Nothing to save.');
      } else {
        _say('Saved on the column.');
      }
    }, failure: 'Not saved');
  }

  Future<void> _backToStandard(String name) =>
      _run(() => _client.discardColumnChanges(ColumnSettingsRequest(names: [name])));

  Future<void> _backToFactory(String name) =>
      _run(() => _client.restoreColumnFactory(ColumnSettingsRequest(names: [name])));

  Future<void> _wholeColumnToFactory() async {
    final ok = await _confirm(
        'Put the whole column back to its factory defaults?',
        const Text("The column's standard is removed from its LED board; every setting takes its "
            'factory value. This cannot be undone.'),
        'Back to factory');
    if (!ok) return;
    await _run(() => _client.restoreColumnFactory(ColumnSettingsRequest()));
  }

  /// The layout the geometry belongs to: the column's LED hardware now.
  String get _layout {
    final row = ColumnState.current?.settings.where((s) => s.name == 'led_layout').firstOrNull;
    try {
      final value = row == null ? null : jsonDecode(row.currentValue);
      if (value is String && value.isNotEmpty) return value;
    } catch (_) {}
    final layout = SettingsState.current?.ledLayout ?? '';
    return layout.isEmpty ? 'strip' : layout;
  }

  /// Send a gbl.py (empty = the shipped geometry) and say what the server made of it.
  Future<void> _sendGeometry(String content) async {
    final layout = _layout;
    await _run(() async {
      final r = await _client.setBoardGbl(BoardGblRequest(layout: layout, content: content));
      final rejected = r.message.startsWith('rejected');
      _say(rejected ? 'LED geometry not taken - ${r.message}' : 'LED geometry ${r.message}. Not saved yet.',
          error: rejected);
    });
  }

  /// The LED geometry as the gbl.py in force, in an editor.
  Future<void> _editGeometry() async {
    final layout = _layout;
    BoardGblResponse current;
    try {
      current = await _client.getBoardGbl(BoardGblLayoutRequest(layout: layout));
    } catch (e) {
      if (mounted) setState(() => message = 'Server call failed: ${_failureText(e)}');
      return;
    }
    if (!mounted) return;
    final controller = TextEditingController(text: current.content);
    final content = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('LED geometry ($layout layout, gbl.py)'),
        content: SizedBox(
          width: 720,
          height: 480,
          child: TextField(
            key: const ValueKey('column-geometry-text'),
            controller: controller,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                helperText: 'The CENTERCAM positions, the LED count and the spans describe this column; '
                    'the server checks the names main.py needs.'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Use this geometry')),
        ],
      ),
    );
    controller.dispose();
    if (content == null || content == current.content) return;
    await _sendGeometry(content);
  }

  Future<void> _loadGeometryFile() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Python file', extensions: ['py']),
    ]);
    if (file == null) return;
    await _sendGeometry(await file.readAsString());
  }

  String _header(ColumnProfileResponse p) {
    if (p.boardId.isEmpty) return 'No column has been connected to this server yet.';
    return [
      'Column ${p.boardId}',
      p.boardConnected ? 'LED board connected' : 'LED board not connected',
      p.revision == 0 ? 'no standard (follows the factory defaults)' : 'standard revision ${p.revision}',
      if (p.adoptedFrom.isNotEmpty) 'adopted from ${p.adoptedFrom}',
      if (p.savePending) 'a save waits for the board',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    if (SettingsState.current == null) return const NotConnectedNotice();
    final profile = ColumnState.current;
    if (profile == null) return const Center(child: CircularProgressIndicator());
    final anyChanged = profile.settings.any((s) => s.changed);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        SectionCard(
          title: 'Column profile',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_header(profile), key: const ValueKey('column-header'), style: const TextStyle(color: T.ink, fontSize: 14)),
            if (profile.notice.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(profile.notice,
                    key: const ValueKey('column-notice'), style: const TextStyle(color: T.warn, fontSize: 13)),
              ),
            if (!profile.hasFactory)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('This column has no factory defaults yet.',
                    key: ValueKey('column-no-factory'), style: TextStyle(color: T.muted, fontSize: 13)),
              ),
            const SizedBox(height: 10),
            _table(profile),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: GoButton(
                    key: const ValueKey('column-save'),
                    text: 'Save changes as standard',
                    onPressed: anyChanged && !_busy ? _save : null),
              ),
              const SizedBox(width: 10),
              QuietButton(
                  key: const ValueKey('column-factory-all'),
                  text: 'Whole column back to factory',
                  onPressed: profile.hasFactory && !_busy ? _wholeColumnToFactory : null),
            ]),
          ]),
        ),
        ErrorLine(message),
      ]),
    );
  }

  Widget _table(ColumnProfileResponse profile) {
    const head = TextStyle(color: T.muted, fontSize: 12, fontWeight: FontWeight.w700);
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(190),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
        4: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(children: [
          Text('Setting', style: head),
          Text('Factory', style: head),
          Text('Standard', style: head),
          Text('Now', style: head),
          SizedBox.shrink(),
        ]),
        for (final s in profile.settings) _row(profile, s),
      ],
    );
  }

  TableRow _row(ColumnProfileResponse profile, ColumnSetting s) {
    final canFactory = profile.hasFactory && s.factoryValue.isNotEmpty && !_busy;
    const value = TextStyle(color: T.ink, fontSize: 13);
    return TableRow(key: ValueKey('column-row-${s.name}'), children: [
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: RowLabel(columnSettingLabels[s.name] ?? s.name)),
      Text(columnValueText(s.name, s.factoryValue),
          style: TextStyle(color: profile.hasFactory ? T.ink : T.muted, fontSize: 13)),
      Text(columnValueText(s.name, s.standardValue), style: value),
      Row(children: [
        if (s.changed)
          Text('● ', key: ValueKey('column-mark-${s.name}'), style: const TextStyle(color: T.warn, fontSize: 14)),
        Flexible(child: Text(columnValueText(s.name, s.currentValue), style: value)),
      ]),
      Wrap(spacing: 4, children: [
        if (s.name == 'led_geometry') ...[
          TextButton(
              key: const ValueKey('column-geometry-edit'),
              onPressed: _busy ? null : _editGeometry,
              child: const Text('Edit…')),
          TextButton(onPressed: _busy ? null : _loadGeometryFile, child: const Text('Load file…')),
        ],
        TextButton(
            key: ValueKey('column-back-standard-${s.name}'),
            onPressed: s.changed && !_busy ? () => _backToStandard(s.name) : null,
            child: const Text('Back to standard')),
        TextButton(
            key: ValueKey('column-back-factory-${s.name}'),
            onPressed: canFactory ? () => _backToFactory(s.name) : null,
            child: const Text('Back to factory')),
      ]),
    ]);
  }
}
