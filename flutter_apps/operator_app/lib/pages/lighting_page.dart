// Lighting page: the kiosk-lighting controls (on/off, R/G/B intensity,
// glasses mode), the manual per-camera light buttons and the two LED
// backlights on the USB relay module. Split out of the old Settings page.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
// hide colorToHex: the picker package exports a util with the same name as
// our ui.dart helper.
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide colorToHex;

import '../services/settings_state.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';

class LightingPage extends StatefulWidget {
  const LightingPage({super.key});

  @override
  State<LightingPage> createState() => _LightingPageState();
}

class _LightingPageState extends State<LightingPage> with ServerCallState {
  late bool _lighting;
  late bool _glassesLightsOff;
  late bool _ledsOffForPhoto;
  late double _intensityRed, _intensityGreen, _intensityBlue;
  String _ledLayout = 'strip';
  // The strip layout's gbl.py on the Plasma board: null until read, true when
  // the operator's own file is in force (GetBoardGbl; an older server has no
  // such RPC and the row then only says so).
  bool? _stripGblCustom;
  String? _stripGblNote;
  // Which LEDs light the photo: 'all', or the 'neighbours' of the selected camera.
  String _photoLight = 'all';
  Color _focusColor = const Color(0xFF00FF00);
  double _focusIntensity = 78;
  // Latest-wins push for the focus light: the picker fires continuously while
  // dragging, and one serial push takes ~0.3s — so at most one RPC is in
  // flight and the newest value always lands last.
  bool _focusPushBusy = false, _focusPushPending = false;
  int? _focusPreviewCamera;

  // The snapshot the local fields were read from; re-read when the shared
  // snapshot is replaced (connect after boot, server change).
  LoadSettingsResponse? _source;

  // Auto-tune white point: hidden since 2026-09-14 (user request); the
  // implementation was removed with it — recover both from git (grep
  // autoTuneWhitePoint) if the feature returns.

  SettingsClient get _client => SettingsState.client;

  // The two LED backlights, as read back from the USB relay module (null
  // until the first read). _backlightsNote says why they can't be switched
  // (module not connected, older server, failed call); _backlightsFor is the
  // server they were read from, so a server switch re-reads them.
  BacklightStatus? _backlights;
  String? _backlightsNote;
  bool _backlightsNoteIsError = false;
  bool _backlightsBusy = false;
  String? _backlightsFor;

  LightsClient get _lights => LightsClient(GrpcChannelProvider.channel);

  @override
  void initState() {
    super.initState();
    // Leave "No server connected" the moment the snapshot lands after a
    // late server start (const IndexedStack pages never rebuild otherwise).
    SettingsState.revision.addListener(_onSettingsChanged);
    if (SettingsState.current != null) {
      _loadBacklights();
      _loadStripGbl();
    }
  }

  /// Whether the operator's own gbl.py is in force for the strip layout. Only
  /// asked of a server that reports the photo light (1.1.19+): older servers
  /// have neither that field nor this RPC, and the row then says so.
  Future<void> _loadStripGbl() async {
    if ((SettingsState.current?.photoLight ?? '').isEmpty) {
      if (mounted) setState(() { _stripGblCustom = null; _stripGblNote = 'older server'; });
      return;
    }
    try {
      final r = await _client.getBoardGbl(BoardGblLayoutRequest(layout: 'strip'));
      if (mounted) setState(() { _stripGblCustom = r.custom; _stripGblNote = null; });
    } catch (e) {
      if (mounted) setState(() { _stripGblCustom = null; _stripGblNote = operatorMessage(e); });
    }
  }

  /// Send a gbl.py for the strip layout (empty = back to the default file) and
  /// show what the server made of it.
  Future<void> _sendStripGbl(String content) async {
    try {
      final r = await _client.setBoardGbl(BoardGblRequest(layout: 'strip', content: content));
      if (!mounted) return;
      final rejected = r.message.startsWith('rejected');
      setState(() {
        _stripGblCustom = r.custom;
        _stripGblNote = r.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(rejected ? 'gbl.py not stored - ${r.message}' : 'gbl.py ${r.message}'),
          backgroundColor: rejected ? T.fail : null));
    } catch (e) {
      if (mounted) setState(() => message = 'Server call failed: ${operatorMessage(e)}');
    }
  }

  /// The strip gbl.py in an editor: the file in force, changed by hand, written
  /// to the board with the button.
  Future<void> _editStripGbl() async {
    BoardGblResponse current;
    try {
      current = await _client.getBoardGbl(BoardGblLayoutRequest(layout: 'strip'));
    } catch (e) {
      if (mounted) setState(() => message = 'Server call failed: ${operatorMessage(e)}');
      return;
    }
    if (!mounted) return;
    final controller = TextEditingController(text: current.content);
    final content = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(current.custom
            ? 'Strip file (gbl.py) - your own file'
            : 'Strip file (gbl.py) - the default file'),
        content: SizedBox(
          width: 720,
          height: 480,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                helperText: 'LED_COUNT, the CENTERCAM positions and the spans describe this '
                    'column; the server checks the names main.py needs before writing.'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Write to the board')),
        ],
      ),
    );
    controller.dispose();
    if (content == null || content == current.content) return;
    await _sendStripGbl(content);
  }

  /// A gbl.py from disk for the strip layout.
  Future<void> _loadStripGblFile() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Python file', extensions: ['py']),
    ]);
    if (file == null) return; // dialog cancelled
    final content = await file.readAsString();
    await _sendStripGbl(content);
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
    if (_backlights == null || _backlightsFor != SettingsState.serverKey) {
      _loadBacklights();
      _loadStripGbl();
    }
  }

  bool _backlightsLoading = false;

  /// Reads the module state once at a time; a reply that arrives after the
  /// server changed is dropped and the read repeated for the new server. With
  /// [keepNote] an existing error note survives a "not connected" answer.
  Future<void> _loadBacklights({bool keepNote = false}) async {
    if (_backlightsLoading) return;
    _backlightsLoading = true;
    final key = SettingsState.serverKey;
    _backlightsFor = key;
    try {
      final state = await _lights.getBacklights(Empty(),
          options: CallOptions(timeout: const Duration(seconds: 5)));
      if (!mounted || key != SettingsState.serverKey) return;
      setState(() {
        _backlights = state;
        if (!keepNote || state.connected) {
          _backlightsNoteIsError = false;
          _backlightsNote = state.connected
              ? null
              : 'USB relay module not connected — plug it in, then press Refresh.';
        }
      });
    } catch (e) {
      if (!mounted || key != SettingsState.serverKey) return;
      setState(() {
        _backlights = null;
        _backlightsNoteIsError = true;
        _backlightsNote = 'Could not read the backlights: ${operatorMessage(e)}';
      });
    } finally {
      _backlightsLoading = false;
      if (mounted && SettingsState.serverKey != key) _loadBacklights();
    }
  }

  Future<void> _setBacklight(Backlight backlight, bool on) async {
    setState(() => _backlightsBusy = true);
    try {
      final state = await _lights
          .setBacklight(BacklightRequest(backlight: backlight, on: on));
      if (!mounted) return;
      setState(() {
        _backlights = state;
        _backlightsNote = null;
      });
    } catch (e) {
      if (!mounted) return;
      // The switch shows the last read-back state, so it springs back; the
      // module may have gone meanwhile, so read it again (the switches then
      // grey out) while this note stays.
      setState(() {
        _backlightsNoteIsError = true;
        _backlightsNote = 'Could not switch the backlight: ${operatorMessage(e)}';
      });
      _loadBacklights(keepNote: true);
    } finally {
      if (mounted) setState(() => _backlightsBusy = false);
    }
  }

  /// A kiosk-mode switch: shows the new value at once, pushes it, and springs
  /// back when the server refuses (an older server answers UNIMPLEMENTED). On
  /// success the settings snapshot the other pages read follows.
  Future<void> _pushMode(bool on,
      {required void Function(bool) show,
      required void Function(LoadSettingsResponse, bool) store,
      required Future<dynamic> Function(bool) call}) async {
    setState(() => show(on));
    try {
      await call(on);
      final s = SettingsState.current;
      if (s != null) store(s, on);
      if (mounted) setState(() => message = null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        show(!on);
        message = 'Server call failed: ${operatorMessage(e)}';
      });
    }
  }

  void _readFromState() {
    final s = SettingsState.current!;
    _lighting = s.lighting;
    _glassesLightsOff = s.glassesLightsOff;
    _ledsOffForPhoto = s.ledsOffForPhoto;
    _intensityRed = s.intensityRed.toDouble();
    _intensityGreen = s.intensityGreen.toDouble();
    _intensityBlue = s.intensityBlue.toDouble();
    _ledLayout = s.ledLayout.isEmpty ? 'strip' : s.ledLayout;
    _photoLight = s.photoLight.isEmpty ? 'all' : s.photoLight;
    _focusColor = hexToColor(s.focusColor, fallback: const Color(0xFF00FF00));
    _focusIntensity = (s.focusIntensity == 0 && s.focusColor.isEmpty)
        ? 78 // pre-upgrade server without the field
        : s.focusIntensity.toDouble().clamp(0, 100);
    _source = s;
  }

  @override
  Widget build(BuildContext context) {
    if (SettingsState.current == null) return const NotConnectedNotice();
    // Fresh snapshot (connect after boot, server change): pick up its values.
    if (!identical(_source, SettingsState.current)) _readFromState();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        SectionCard(
            title: 'Kiosk lighting',
            titleLeading: const DevInfoBadge('kiosk-lighting'),
            child: _buildLighting()),
        const SizedBox(height: 14),
        SectionCard(
            title: 'Lights',
            titleLeading: const DevInfoBadge('lights'),
            child: _buildLightsCard()),
        const SizedBox(height: 14),
        SectionCard(
            title: 'Backlights',
            titleLeading: const DevInfoBadge('backlights'),
            child: _buildBacklightsCard()),
        ErrorLine(message),
      ]),
    );
  }

  Widget _buildLighting() {
    Widget intensity(String label, double value, void Function(double) set,
        Future<dynamic> Function(int) rpc) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RowLabel('$label ${value.round()}'),
        Slider(
          value: value,
          min: 0,
          max: 255,
          onChanged: (v) => setState(() => set(v)),
          onChangeEnd: (v) => runServerCall(() => rpc(v.round())),
        ),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Switch(
            value: _lighting,
            onChanged: (v) {
              setState(() => _lighting = v);
              runServerCall(() => _client.setLighting(LightingRequest(value: _lighting)));
            }),
        const SizedBox(width: 10),
        const RowLabel('Lighting'),
      ]),
      intensity('Intensity Red', _intensityRed, (v) => _intensityRed = v,
          (v) => _client.setIntensityRed(IntensityRequest(value: v))),
      intensity('Intensity Green', _intensityGreen, (v) => _intensityGreen = v,
          (v) => _client.setIntensityGreen(IntensityRequest(value: v))),
      intensity('Intensity Blue', _intensityBlue, (v) => _intensityBlue = v,
          (v) => _client.setIntensityBlue(IntensityRequest(value: v))),
      const SizedBox(height: 8),
      Row(children: [
        const RowLabel('Focus light'),
        const SizedBox(width: 14),
        InkWell(
          onTap: _pickFocusColor,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 46,
            height: 28,
            decoration: BoxDecoration(
              color: _focusColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black26),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('#${colorToHex(_focusColor)}',
            style: const TextStyle(fontSize: 13, color: T.muted)),
      ]),
      RowLabel('Focus intensity ${_focusIntensity.round()}%'),
      Slider(
        value: _focusIntensity,
        min: 0,
        max: 100,
        onChangeStart: (_) => _focusPreview(true),
        onChanged: (v) {
          setState(() => _focusIntensity = v);
          _pushFocusLight();
        },
        onChangeEnd: (_) async {
          await _pushFocusLight();
          await _focusPreview(false);
        },
      ),
      const SizedBox(height: 8),
      Row(children: [
        const RowLabel('LED hardware'),
        const SizedBox(width: 14),
        DropdownMenu<String>(
          initialSelection: _ledLayout,
          width: 370,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 'strip', label: 'LED strips (vertical, next to the cameras)'),
            DropdownMenuEntry(value: 'ring', label: 'LED rings (one ring per camera)'),
          ],
          onSelected: (v) {
            if (v == null || v == _ledLayout) return;
            setState(() => _ledLayout = v);
            SettingsState.current?.ledLayout = v;
            runServerCall(() async {
              await _client.setLedLayout(LedLayoutRequest(value: v));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('LED layout saved — the server is writing the '
                        'matching files to the Plasma board (takes ~10 s, the '
                        'board reboots).')));
              }
              if (v == 'strip') _loadStripGbl();
            });
          },
        ),
      ]),
      // The strip column's geometry (LED count, camera positions, spans) is the
      // column's own: the operator can put a gbl.py of their own on the board.
      if (_ledLayout == 'strip') ...[
        const SizedBox(height: 6),
        Row(children: [
          const RowLabel('Strip file (gbl.py)'),
          const SizedBox(width: 14),
          Text(
              _stripGblCustom == null
                  ? (_stripGblNote == null ? '…' : 'not available on this server')
                  : (_stripGblCustom! ? 'your own file is on the board' : 'the default file is on the board'),
              style: TextStyle(
                  color: _stripGblCustom == null && _stripGblNote != null ? T.muted : T.ink,
                  fontSize: 14)),
          const SizedBox(width: 14),
          QuietButton(text: 'Edit…', onPressed: _stripGblCustom == null ? null : _editStripGbl),
          const SizedBox(width: 8),
          QuietButton(text: 'Load file…', onPressed: _stripGblCustom == null ? null : _loadStripGblFile),
          if (_stripGblCustom == true) ...[
            const SizedBox(width: 8),
            QuietButton(text: 'Restore default', onPressed: () => _sendStripGbl('')),
          ],
        ]),
        if (_stripGblNote != null && _stripGblCustom != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(_stripGblNote!,
                style: TextStyle(
                    color: _stripGblNote!.startsWith('rejected') ? T.fail : T.muted, fontSize: 12)),
          ),
      ],
      const SizedBox(height: 4),
      Row(children: [
        const RowLabel('Photo light'),
        const SizedBox(width: 14),
        DropdownMenu<String>(
          initialSelection: _photoLight,
          width: 370,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 'all', label: 'All LEDs of the column'),
            DropdownMenuEntry(
                value: 'neighbours',
                label: 'The selected camera\'s ring and its two neighbours'),
          ],
          onSelected: (v) {
            if (v == null || v == _photoLight) return;
            setState(() => _photoLight = v);
            SettingsState.current?.photoLight = v;
            runServerCall(() => _client.setPhotoLight(PhotoLightRequest(value: v)));
          },
        ),
      ]),
      if (_photoLight == 'neighbours')
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
              'Three rings whatever the column has: the current for a photo does '
              'not grow with the number of cameras. The camera scan runs the whole '
              'column at half intensity.',
              style: TextStyle(color: T.muted, fontSize: 12)),
        ),
      const SizedBox(height: 4),
      Row(children: [
        Switch(
            value: _glassesLightsOff,
            onChanged: (v) => _pushMode(v,
                show: (on) => _glassesLightsOff = on,
                store: (s, on) => s.glassesLightsOff = on,
                call: (on) => _client
                    .setGlassesLightsOff(GlassesLightsOffRequest(value: on)))),
        const SizedBox(width: 10),
        const Expanded(
            child: RowLabel(
                'Glasses mode: lights off for the photo only when glasses are '
                'detected (the chosen camera\'s ring stays on until then)')),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        Switch(
            value: _ledsOffForPhoto,
            onChanged: (v) => _pushMode(v,
                show: (on) => _ledsOffForPhoto = on,
                store: (s, on) => s.ledsOffForPhoto = on,
                call: (on) => _client
                    .setLedsOffForPhoto(LedsOffForPhotoRequest(value: on)))),
        const SizedBox(width: 10),
        const Expanded(
            child: RowLabel(
                'Lights off for the photo: the chosen camera\'s ring shows for a '
                'second, then all LEDs go off and the backlights light the photo')),
      ]),
    ]);
  }

  /// Manual light controls (moved here from the Kiosk page).
  Widget _buildLightsCard() {
    final lights = LightsClient(GrpcChannelProvider.channel);
    Widget cameraRow(String label, void Function(int) onTap) {
      return Row(children: [
        SizedBox(width: 96, child: RowLabel(label)),
        for (var i = 1; i <= 6; i++) ...[
          NumButton(number: i, onPressed: () => onTap(i)),
          const SizedBox(width: 8),
        ],
      ]);
    }

    return Column(children: [
      Row(children: [
        Expanded(
            child: QuietButton(
                text: 'All lights on',
                onPressed: () => runServerCall(() =>
                    lights.setAllLights(AllLightsRequest(status: true))))),
        const SizedBox(width: 12),
        Expanded(
            child: QuietButton(
                text: 'All lights off',
                onPressed: () => runServerCall(() =>
                    lights.setAllLights(AllLightsRequest(status: false))))),
      ]),
      const SizedBox(height: 14),
      cameraRow(
          'Focus light on',
          (i) => runServerCall(
              () => lights.setLightAtCameraIndex(LightIndexRequest(index: i)))),
      const SizedBox(height: 10),
      cameraRow(
          'Focus light off',
          (i) => runServerCall(() =>
              lights.setLightOffAtCameraIndex(LightIndexRequest(index: i)))),
    ]);
  }

  /// Focus-light colour picker with LIVE preview: while it is open the TOP
  /// camera's focus light is on (ring layout: the top ring), and every change
  /// is pushed to the server, which updates the board's focus channels — the
  /// focus step redraws each tick, so the light follows the picker.
  Future<void> _pickFocusColor() async {
    final original = _focusColor;
    await _focusPreview(true);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Focus light colour'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _focusColor,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
            onColorChanged: (c) {
              setState(() => _focusColor = c);
              _pushFocusLight();
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Use this colour')),
        ],
      ),
    );
    if (confirmed != true) {
      setState(() => _focusColor = original);
    }
    await _pushFocusLight();
    await _focusPreview(false);
  }

  /// Latest-wins push of colour + intensity (see the field comment).
  Future<void> _pushFocusLight() async {
    if (_focusPushBusy) {
      _focusPushPending = true;
      return;
    }
    _focusPushBusy = true;
    try {
      do {
        _focusPushPending = false;
        final hex = colorToHex(_focusColor);
        final percent = _focusIntensity.round();
        await _client
            .setFocusLight(FocusLightRequest(color: hex, intensity: percent));
        SettingsState.current
          ?..focusColor = hex
          ..focusIntensity = percent;
      } while (_focusPushPending);
      if (mounted) setState(() => message = null);
    } catch (e) {
      if (mounted) {
        setState(() => message = 'Server call failed: ${operatorMessage(e)}');
      }
    } finally {
      _focusPushBusy = false;
    }
  }

  /// Turn the top camera's focus light on/off for the live preview. Best
  /// effort — a failure only means no preview, the picker still works.
  Future<void> _focusPreview(bool on) async {
    try {
      final lights = LightsClient(GrpcChannelProvider.channel);
      if (on) {
        _focusPreviewCamera ??= await _topCameraIndex();
        await lights
            .setLightAtCameraIndex(LightIndexRequest(index: _focusPreviewCamera!));
      } else if (_focusPreviewCamera != null) {
        await lights.setLightOffAtCameraIndex(
            LightIndexRequest(index: _focusPreviewCamera!));
      }
    } catch (_) {/* preview only */}
  }

  /// Highest calibrated camera position = the top of the column.
  Future<int> _topCameraIndex() async {
    try {
      final resp = await CalibrationClient(GrpcChannelProvider.channel)
          .getCalibration(Empty());
      var top = 0;
      for (final entry in resp.calibrate) {
        if (entry.calibratedCameraIndex > top) top = entry.calibratedCameraIndex;
      }
      return top > 0 ? top : 6;
    } catch (_) {
      return 6;
    }
  }

  /// The two LED backlights on the USB relay module, switched by hand for
  /// testing (captures switch them themselves).
  Widget _buildBacklightsCard() {
    final state = _backlights;
    final enabled = state != null && state.connected && !_backlightsBusy;
    Widget row(String label, Backlight backlight, bool value) => Row(children: [
          Switch(
              value: value,
              onChanged: enabled ? (v) => _setBacklight(backlight, v) : null),
          const SizedBox(width: 10),
          Expanded(child: RowLabel(label)),
        ]);
    final note = _backlightsNote ??
        (state == null ? 'Reading the relay module…' : 'USB relay module connected');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
          'For testing: switch each backlight by hand. During a capture both '
          'go on for the high-resolution photo and off as soon as it is '
          'taken; starting or stopping the server switches them off.',
          style: TextStyle(color: T.muted, fontSize: 13)),
      const SizedBox(height: 8),
      row('Bottom backlight (relay 1)', Backlight.BACKLIGHT_BOTTOM,
          state?.backlightBottom ?? false),
      row('Top backlight (relay 2)', Backlight.BACKLIGHT_TOP,
          state?.backlightTop ?? false),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
            child: Text(note,
                style: TextStyle(
                    color: _backlightsNoteIsError && _backlightsNote != null
                        ? T.fail
                        : T.muted,
                    fontSize: 13))),
        const SizedBox(width: 12),
        QuietButton(text: 'Refresh', onPressed: _loadBacklights),
      ]),
    ]);
  }
}
