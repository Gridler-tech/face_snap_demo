// Lighting page: the kiosk-lighting controls (on/off, R/G/B intensity,
// glasses mode) and the manual per-camera light buttons. Split out of the
// old Settings page.
import 'package:face_snap_grpc/face_snap_grpc.dart';
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
  late double _intensityRed, _intensityGreen, _intensityBlue;
  String _ledLayout = 'strip';
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

  @override
  void initState() {
    super.initState();
    // Leave "No server connected" the moment the snapshot lands after a
    // late server start (const IndexedStack pages never rebuild otherwise).
    SettingsState.revision.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _readFromState() {
    final s = SettingsState.current!;
    _lighting = s.lighting;
    _glassesLightsOff = s.glassesLightsOff;
    _intensityRed = s.intensityRed.toDouble();
    _intensityGreen = s.intensityGreen.toDouble();
    _intensityBlue = s.intensityBlue.toDouble();
    _ledLayout = s.ledLayout.isEmpty ? 'strip' : s.ledLayout;
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
            });
          },
        ),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        Switch(
            value: _glassesLightsOff,
            onChanged: (v) {
              setState(() => _glassesLightsOff = v);
              runServerCall(() => _client.setGlassesLightsOff(
                  GlassesLightsOffRequest(value: _glassesLightsOff)));
            }),
        const SizedBox(width: 10),
        const Expanded(
            child: RowLabel(
                'Glasses mode: photo with all lights off when glasses are detected')),
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

}
