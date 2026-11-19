// Lighting page: the kiosk-lighting controls (on/off, R/G/B intensity, the
// glare-free light, the photo colour correction switch), the manual per-camera
// light buttons and the two LED backlights (on the LED board, dimmable, or on a USB relay
// module) with their brightness per light (spec 2026-10-15 section 5). Split out of
// the old Settings page. The column settings among them show the ● mark while
// changed and not saved (the LED geometry editor moved to the Column page, spec
// 2026-10-10 section 5.5; a server from before the column profile keeps the strip
// gbl.py row here, 5.6).
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
// hide colorToHex: the picker package exports a util with the same name as
// our ui.dart helper.
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide colorToHex;

import '../services/column_state.dart';
import '../services/preview_throttle.dart';
import '../services/settings_state.dart';
import '../ui/column_mark.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';

/// gRPC status UNIMPLEMENTED (`StatusCode.unimplemented`): `grpc` is only a dev dependency of
/// the operator app (face_snap_grpc exports `GrpcError`, not `StatusCode`).
const _unimplemented = 12;

/// gRPC status UNAVAILABLE.
const _unavailable = 14;

/// The servers' own backlight failures (lights.py / LightsService.cs SetBacklight): an
/// UNAVAILABLE that starts with one of them is the LED board or the relay module failing, not
/// an unreachable kiosk, so the card shows the server's words.
const _backlightFailureTexts = ['LED board backlight command failed', 'USB relay module write failed'];

/// A failed backlight call as the card shows it.
String _backlightFailure(Object e) {
  if (e is GrpcError &&
      e.code == _unavailable &&
      _backlightFailureTexts.any((text) => (e.message ?? '').startsWith(text))) {
    return e.message!;
  }
  return operatorMessage(e);
}

/// The backlight output a BacklightStatus names (its source) as the card shows it. A server
/// from before the LED-board backlights sends no source: it only knows the relay.
String backlightOutputLabel(BacklightStatus s) => switch (s.source) {
      'board_qwst' => 'LED board (Qw/ST)',
      'board_header' => 'LED board (header A0/A1)',
      'relay' => 'USB relay',
      'none' => 'not connected',
      _ => s.connected ? 'USB relay' : 'not connected',
    };

/// At most one live preview per this interval while a backlight slider is dragged. Tests set a
/// long one, so a drag's preview calls do not depend on how fast the machine runs (the
/// throttle's own timing is tested on a fake clock in preview_throttle_test.dart).
@visibleForTesting
Duration backlightPreviewInterval = const Duration(milliseconds: 100);

/// The light scenes with a backlight brightness of their own (the column setting
/// backlight_brightness), as the server names them, and their titles on the card.
const _backlightLights = [('standard', 'Standard light'), ('glare_free', 'Glare-free light')];

/// The glare-free light in a settings snapshot: a server from before the setting sends no
/// glare_free_light (it reads as off), and its glasses switch then decides.
GlareFreeLight glareFreeLightOf(LoadSettingsResponse s) =>
    s.glareFreeLight != GlareFreeLight.GLARE_FREE_LIGHT_OFF
        ? s.glareFreeLight
        : (s.glassesLightsOff
            ? GlareFreeLight.GLARE_FREE_LIGHT_GLASSES
            : GlareFreeLight.GLARE_FREE_LIGHT_OFF);

/// The glare-free light's choices: the value, its label and the explanation shown under the
/// selector for the chosen one (spec 2026-10-09 section 5).
const glareFreeChoices = <(GlareFreeLight, String, String)>[
  (
    GlareFreeLight.GLARE_FREE_LIGHT_OFF,
    'Normal light',
    'The photo light. The chosen camera\'s ring fades out for the photo and back in after '
        'it, so there is no green dot in the eyes.'
  ),
  (
    GlareFreeLight.GLARE_FREE_LIGHT_GLASSES,
    'Glare-free for glasses',
    'When the first good frame shows glasses, only the rings above the next camera up and '
        'the backlights light the photo, so nothing mirrors in the lenses.'
  ),
  (
    GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE,
    'Glare-free for everyone',
    'That light for every photo: one natural catchlight instead of a row of LED dots. A '
        'face that stays too dark gets the normal light for that photo.'
  ),
];

class LightingPage extends StatefulWidget {
  const LightingPage({super.key});

  @override
  State<LightingPage> createState() => _LightingPageState();
}

class _LightingPageState extends State<LightingPage> with ServerCallState {
  late bool _lighting;
  late GlareFreeLight _glareFree;
  // The glare-free light's white balance, Kelvin (0 = the camera's own value).
  final _whiteBalance = TextEditingController();
  // The value being pushed: Enter also takes the focus away, so both triggers fire before
  // the reply; the second one is skipped.
  int? _whiteBalanceInFlight;
  late bool _ledsOffForPhoto;
  // The photo colour correction, kiosk-wide (kiosk.colour_correction); the matrices are
  // measured on the Calibration page.
  late bool _colourCorrection;
  late double _intensityRed, _intensityGreen, _intensityBlue;
  String _ledLayout = 'strip';
  // The strip layout's gbl.py on a server from before the column profile (which has no
  // Column page): null until read, true when the server's own file is in force
  // (GetBoardGbl; a server older still has no such RPC and the row then only says so).
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

  // The two LED backlights, as read back from the server (null until the first read).
  // _backlightsNote says why they can't be switched (nothing connected, older server,
  // failed call); _backlightsFor is the server they were read from, so a server switch
  // re-reads them.
  BacklightStatus? _backlights;
  String? _backlightsNote;
  bool _backlightsNoteIsError = false;
  bool _backlightsBusy = false;
  String? _backlightsFor;

  // The stored brightness per light ('standard', 'glare_free'): (bottom, top) in %, from the
  // status (empty from a server without the dimming: the sliders are hidden).
  final Map<String, (int, int)> _brightness = {};
  // A slider's level while it is dragged and until its store is answered ('<light>-bottom'
  // or '<light>-top'); the slider shows the stored level otherwise.
  final Map<String, int> _sliding = {};
  // The server that answered SetBacklightBrightness with UNIMPLEMENTED: no sliders for it
  // (until a fresh status brings a brightness list again).
  String? _brightnessMissingFor;
  // The last live preview failed (the board stopped answering): its note stays through the
  // store that follows (which never touches the board) until a preview or a switch works, or
  // Refresh.
  bool _previewFailed = false;
  // The live preview per backlight while its slider moves (at most one call per 100 ms), and
  // the backlights whose switch was on when their drag began: they preview until let go (a
  // preview at 0 % reads back as off, and must not end the preview mid-drag).
  final Set<Backlight> _previewing = {};
  late final Map<Backlight, PreviewThrottle<int>> _previews = {
    for (final backlight in [Backlight.BACKLIGHT_BOTTOM, Backlight.BACKLIGHT_TOP])
      backlight: PreviewThrottle<int>((percent) => _preview(backlight, percent),
          interval: backlightPreviewInterval),
  };

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

  /// Whether the server's own gbl.py is in force for the strip layout (the row shown on a
  /// server without the column profile). Only asked of a server that reports the photo
  /// light (1.1.19+): older servers have neither that field nor this RPC, and the row then
  /// says so.
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

  /// The strip gbl.py row of a server from before the column profile.
  List<Widget> _stripGblRow() => [
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
      ];

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    _whiteBalance.dispose();
    for (final preview in _previews.values) {
      preview.dispose();
    }
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
  /// [keepNote] an existing error note survives the answer (the failed call it
  /// reports is not undone by a status that still names the output).
  Future<void> _loadBacklights({bool keepNote = false}) async {
    if (_backlightsLoading) return;
    _backlightsLoading = true;
    final key = SettingsState.serverKey;
    if (_backlightsFor != key) _sliding.clear();
    _backlightsFor = key;
    try {
      final state = await _lights.getBacklights(Empty(),
          options: CallOptions(timeout: const Duration(seconds: 5)));
      if (!mounted || key != SettingsState.serverKey) return;
      setState(() {
        _showBacklights(state);
        if (state.brightness.isNotEmpty) _brightnessMissingFor = null;
        if (!keepNote) _previewFailed = false;
        if (!keepNote || !_backlightsNoteIsError || _backlightsNote == null) {
          _backlightsNoteIsError = false;
          _backlightsNote = state.connected
              ? null
              : 'No backlights found — connect them to the LED board or plug in the USB '
                  'relay module, then press Refresh.';
        }
      });
    } catch (e) {
      if (!mounted || key != SettingsState.serverKey) return;
      setState(() {
        _backlights = null;
        _brightness.clear();
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
        _showBacklights(state);
        _backlightsNote = null;
        _previewFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      // The switch shows the last read-back state, so it springs back; the
      // module may have gone meanwhile, so read it again (the switches then
      // grey out) while this note stays.
      setState(() {
        _backlightsNoteIsError = true;
        _backlightsNote = 'Could not switch the backlight: ${_backlightFailure(e)}';
      });
      _loadBacklights(keepNote: true);
    } finally {
      if (mounted) setState(() => _backlightsBusy = false);
    }
  }

  /// A status read back from the server: the switches, the output and the stored brightness
  /// per light (call inside setState).
  void _showBacklights(BacklightStatus state) {
    _backlights = state;
    _brightness
      ..clear()
      ..addAll({for (final b in state.brightness) b.light: (b.bottom, b.top)});
  }

  bool _isOn(Backlight backlight) => backlight == Backlight.BACKLIGHT_BOTTOM
      ? _backlights?.backlightBottom ?? false
      : _backlights?.backlightTop ?? false;

  /// A slider's level: while dragged (or its store unanswered) the dragged one, otherwise
  /// the stored one (100 % = the server's default when the light is missing).
  int _level(String light, Backlight backlight) {
    final dragged = _sliding[_slideKey(light, backlight)];
    if (dragged != null) return dragged;
    final stored = _brightness[light] ?? (100, 100);
    return backlight == Backlight.BACKLIGHT_BOTTOM ? stored.$1 : stored.$2;
  }

  static String _slideKey(String light, Backlight backlight) =>
      '$light-${backlight == Backlight.BACKLIGHT_BOTTOM ? 'bottom' : 'top'}';

  /// One live preview: the backlight on at [percent] (the throttle sends it).
  Future<void> _preview(Backlight backlight, int percent) async {
    try {
      final state = await _lights.setBacklight(
          BacklightRequest(backlight: backlight, on: true, percent: percent));
      if (!mounted) return;
      setState(() {
        _showBacklights(state);
        if (_previewFailed) _backlightsNote = null;
        _previewFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewFailed = true;
        _backlightsNoteIsError = true;
        _backlightsNote = 'Could not preview the backlight: ${_backlightFailure(e)}';
      });
      // The board may have gone: read the backlights again (the source line follows) while
      // this note stays.
      _loadBacklights(keepNote: true);
    }
  }

  /// A drag begins: it previews when that backlight is switched on now.
  void _slideStart(Backlight backlight) {
    _previews[backlight]!.forget();
    if (_isOn(backlight)) {
      _previewing.add(backlight);
    } else {
      _previewing.remove(backlight);
    }
  }

  /// A slider moves: shown at once; previewed live when the drag began with that backlight
  /// on (throttled).
  void _slide(String light, Backlight backlight, double value) {
    final percent = value.round();
    setState(() => _sliding[_slideKey(light, backlight)] = percent);
    if (_previewing.contains(backlight)) _previews[backlight]!.add(percent);
  }

  /// A slider is let go: when the drag previewed, the panel goes to the released level (after
  /// every preview before it); then the light's brightness is stored with that level. A drag
  /// that began with the backlight off: stored only.
  Future<void> _release(String light, Backlight backlight, double value) async {
    final percent = value.round();
    final key = _slideKey(light, backlight);
    setState(() => _sliding[key] = percent);
    final preview = _previewing.remove(backlight);
    await _previews[backlight]!.flush(preview ? percent : null);
    if (!mounted) return;
    await _storeBrightness(light, key, percent);
  }

  /// SetBacklightBrightness for [light] with both its levels as shown. A column setting: the
  /// profile is read again for its ● mark. Refused: the server's words and the slider back
  /// at the stored level; a server without it (UNIMPLEMENTED): the sliders go.
  Future<void> _storeBrightness(String light, String key, int percent) async {
    final server = SettingsState.serverKey;
    try {
      final r = await _lights.setBacklightBrightness(BacklightBrightnessRequest(
          light: light,
          bottom: _level(light, Backlight.BACKLIGHT_BOTTOM),
          top: _level(light, Backlight.BACKLIGHT_TOP)));
      if (!mounted || server != SettingsState.serverKey) return;
      ColumnState.touch();
      setState(() {
        _brightness[light] = (r.brightness.bottom, r.brightness.top);
        if (_sliding[key] == percent) _sliding.remove(key);
        if (!_previewFailed) _backlightsNote = null;
      });
    } catch (e) {
      if (!mounted || server != SettingsState.serverKey) return;
      setState(() {
        if (_sliding[key] == percent) _sliding.remove(key);
        if (e is GrpcError && e.code == _unimplemented) {
          _brightnessMissingFor = server;
        } else {
          _backlightsNoteIsError = true;
          _backlightsNote = 'Could not store the backlight brightness: ${_backlightFailure(e)}';
        }
      });
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

  /// The glare-free light: shown at once, pushed, and back to the old choice when the server
  /// refuses. A server from before the setting (UNIMPLEMENTED) still takes "off" and
  /// "glasses" through its glasses switch; "everyone" it cannot do.
  Future<void> _pushGlareFree(GlareFreeLight value) async {
    final previous = _glareFree;
    if (value == previous) return;
    setState(() => _glareFree = value);
    try {
      try {
        await _client.setGlareFreeLight(GlareFreeLightRequest(value: value));
      } on GrpcError catch (e) {
        if (e.code != _unimplemented ||
            value == GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE) {
          rethrow;
        }
        await _client.setGlassesLightsOff(GlassesLightsOffRequest(
            value: value == GlareFreeLight.GLARE_FREE_LIGHT_GLASSES));
      }
      SettingsState.current
        ?..glareFreeLight = value
        ..glassesLightsOff = value != GlareFreeLight.GLARE_FREE_LIGHT_OFF;
      if (mounted) setState(() => message = null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _glareFree = previous;
        message = 'Server call failed: ${operatorMessage(e)}';
      });
    }
  }

  /// The glare-free white balance from the Kelvin field, pushed when it changed; a refused
  /// value (not 0 or 2800-6500, or an older server) puts the value in force back.
  Future<void> _pushWhiteBalance() async {
    final current = SettingsState.current?.glareFreeWhiteBalance ?? 0;
    final value = int.tryParse(_whiteBalance.text.trim());
    if (value == null) {
      setState(() => _whiteBalance.text = '$current');
      return;
    }
    if (value == current || value == _whiteBalanceInFlight) return;
    _whiteBalanceInFlight = value;
    try {
      final r = await _client.setGlareFreeWhiteBalance(GlareFreeWhiteBalanceRequest(value: value));
      SettingsState.current?.glareFreeWhiteBalance = r.message;
      ColumnState.touch();
      if (mounted) {
        setState(() {
          _whiteBalance.text = '${r.message}';
          message = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _whiteBalance.text = '$current';
        message = 'Server call failed: ${operatorMessage(e)}';
      });
    } finally {
      _whiteBalanceInFlight = null;
    }
  }

  void _readFromState() {
    final s = SettingsState.current!;
    _lighting = s.lighting;
    _glareFree = glareFreeLightOf(s);
    _whiteBalance.text = '${s.glareFreeWhiteBalance}';
    _ledsOffForPhoto = s.ledsOffForPhoto;
    // A server without the correction sends no colour_corrections; its colourCorrection is
    // the proto default false, not a value: read it as on (as the C# SDK does).
    _colourCorrection = s.colourCorrections.isEmpty || s.colourCorrection;
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
      const ColumnChangedMark(['led_colour']),
      const SizedBox(height: 8),
      Row(children: [
        const RowLabel('Focus light'),
        const SizedBox(width: 14),
        InkWell(
          key: const ValueKey('focus-light-colour'),
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
      const ColumnChangedMark(['focus_light']),
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
                // With the column profile the layout is a session change until it is
                // saved on the Column page (spec 2026-10-10 section 4.5).
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${ColumnState.available ? 'LED layout set (save it on the '
                            'Column page to keep it after a restart)' : 'LED layout saved'} — the '
                        'server is writing the matching files to the Plasma board (takes '
                        '~10 s, the board reboots).')));
              }
              if (v == 'strip') _loadStripGbl();
            });
          },
        ),
      ]),
      const ColumnChangedMark(['led_layout', 'led_geometry']),
      // The column's LED geometry (gbl.py) is edited on the Column page, which only a
      // server with the column profile has; a server from before it keeps the strip
      // gbl.py row here (spec 2026-10-10 section 5.6).
      ValueListenableBuilder<int>(
        valueListenable: ColumnState.revision,
        builder: (context, _, _) => !ColumnState.available
            ? Column(
                key: const ValueKey('strip-gbl-row'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _ledLayout == 'strip' ? _stripGblRow() : const [])
            : const Padding(
                padding: EdgeInsets.only(left: 4, top: 2),
                child: Text('The LED geometry (gbl.py) of the column is on the Column page.',
                    style: TextStyle(color: T.muted, fontSize: 12)),
              ),
      ),
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
      // A Wrap, not a Row: on a narrow window the three choices go under the label.
      Wrap(spacing: 14, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        const RowLabel('Glare-free light'),
        SegmentedButton<GlareFreeLight>(
          showSelectedIcon: false,
          segments: [
            for (final (value, label, _) in glareFreeChoices)
              ButtonSegment(value: value, label: Text(label)),
          ],
          selected: {_glareFree},
          onSelectionChanged: (chosen) => _pushGlareFree(chosen.first),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 6),
        child: Text(glareFreeChoices.firstWhere((c) => c.$1 == _glareFree).$3,
            style: const TextStyle(color: T.muted, fontSize: 12)),
      ),
      Row(children: [
        const RowLabel('Glare-free white balance'),
        const SizedBox(width: 14),
        SizedBox(
          width: 110,
          // Pushed on focus loss as well as Enter (typed values were lost when the operator
          // clicked elsewhere: the background colour field had the same trap).
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) _pushWhiteBalance();
            },
            child: TextField(
              key: const ValueKey('glare-free-white-balance'),
              controller: _whiteBalance,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(suffixText: 'K'),
              onSubmitted: (_) => _pushWhiteBalance(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
            child: Text(
                'Kelvin, 0 = the camera\'s own value. The camera uses it whenever the '
                'glare-free light lights the photo (the backlights are warmer than the rings).',
                style: TextStyle(color: T.muted, fontSize: 12))),
      ]),
      const ColumnChangedMark(['glare_free_white_balance']),
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
      _colourCorrectionRow(),
    ]);
  }

  /// The photo colour correction, kiosk-wide (SetColourCorrectionEnabled). A server without
  /// it sends no colour_corrections: the switch is greyed out.
  Widget _colourCorrectionRow() {
    final supported = SettingsState.current?.colourCorrections.isNotEmpty ?? false;
    return Row(children: [
      Switch(
          value: _colourCorrection,
          onChanged: !supported
              ? null
              : (v) => _pushMode(v,
                  show: (on) => _colourCorrection = on,
                  store: (s, on) => s.colourCorrection = on,
                  call: (on) => _client.setColourCorrectionEnabled(
                      ColourCorrectionEnabledRequest(value: on)))),
      const SizedBox(width: 10),
      const RowLabel('Photo colour correction'),
      const SizedBox(width: 10),
      Expanded(
          child: Text(
              supported
                  ? 'Each photo\'s colours corrected for its light, with this kiosk\'s '
                      'measured matrix or the shipped one (Calibration page, Photo colour)'
                  : 'Not available on this server',
              style: const TextStyle(color: T.muted, fontSize: 12))),
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
      // The focus light is a column setting: read the profile again (debounced).
      ColumnState.touch();
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

  /// The two LED backlights, switched by hand for testing (captures switch them
  /// themselves), with the output the server drives and, per light, their brightness:
  /// dimmable on the LED board only (greyed out on a relay or none, hidden on a server
  /// without the dimming).
  Widget _buildBacklightsCard() {
    final state = _backlights;
    final enabled = state != null && state.connected && !_backlightsBusy;
    Widget row(String label, String which, Backlight backlight, bool value) => Row(children: [
          Switch(
              key: ValueKey('backlight-switch-$which'),
              value: value,
              onChanged: enabled ? (v) => _setBacklight(backlight, v) : null),
          const SizedBox(width: 10),
          Expanded(child: RowLabel(label)),
        ]);
    final note = _backlightsNote ?? (state == null ? 'Reading the backlights…' : null);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
          'For testing: switch each backlight by hand. During a capture both '
          'go on for the high-resolution photo, at the brightness of its light, and off '
          'as soon as it is taken; starting or stopping the server switches them off.',
          style: TextStyle(color: T.muted, fontSize: 13)),
      if (state != null) ...[
        const SizedBox(height: 8),
        RowLabel('Output: ${backlightOutputLabel(state)}'),
      ],
      const SizedBox(height: 8),
      row('Bottom', 'bottom', Backlight.BACKLIGHT_BOTTOM, state?.backlightBottom ?? false),
      row('Top', 'top', Backlight.BACKLIGHT_TOP, state?.backlightTop ?? false),
      if (state != null &&
          _brightness.isNotEmpty &&
          _brightnessMissingFor != SettingsState.serverKey)
        _buildBrightnessSliders(state),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
            child: Text(note ?? '',
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

  /// Per light a Bottom and a Top slider, 0-100 % in steps of 5. Moving one previews the
  /// level live while that backlight is on; letting go stores it (SetBacklightBrightness).
  Widget _buildBrightnessSliders(BacklightStatus state) {
    final dimmable = state.source.startsWith('board_');
    Widget slider(String light, String label, Backlight backlight) {
      final key = _slideKey(light, backlight);
      final level = _level(light, backlight).clamp(0, 100);
      return Row(children: [
        SizedBox(width: 70, child: RowLabel(label)),
        Expanded(
          child: Slider(
            key: ValueKey('backlight-slider-$key'),
            value: level.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            onChangeStart: dimmable ? (_) => _slideStart(backlight) : null,
            onChanged: dimmable ? (v) => _slide(light, backlight, v) : null,
            onChangeEnd: dimmable ? (v) => _release(light, backlight, v) : null,
          ),
        ),
        SizedBox(
            width: 52,
            child: Text('$level %', style: const TextStyle(color: T.muted, fontSize: 13))),
      ]);
    }

    return Column(
      key: const ValueKey('backlight-sliders'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
            'Brightness for the photo, per light. While a backlight is on, moving its '
            'slider shows the level live; letting go stores it.',
            style: TextStyle(color: T.muted, fontSize: 13)),
        for (final (light, title) in _backlightLights) ...[
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: T.ink, fontSize: 14, fontWeight: FontWeight.w600)),
          slider(light, 'Bottom', Backlight.BACKLIGHT_BOTTOM),
          slider(light, 'Top', Backlight.BACKLIGHT_TOP),
        ],
        if (!dimmable)
          const Text('Dimming needs backlights on the LED board',
              style: TextStyle(color: T.muted, fontSize: 13)),
        const ColumnChangedMark(['backlight_brightness']),
      ],
    );
  }
}
