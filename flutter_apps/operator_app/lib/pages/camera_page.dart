// Camera page — port of the MAUI CameraPage: resolution dropdown plus every
// camera property as a slider/switch, gated by the server's runtime probe
// (unsupported_properties hides controls; property_ranges sizes each slider to
// what this camera really accepts), plus a live single-camera preview.
import 'dart:async';
import 'dart:typed_data';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import '../services/settings_state.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';

class _SliderSpec {
  const _SliderSpec(this.name, this.label, this.fallbackMin, this.fallbackMax,
      this.read, this.write);

  final String name; // server property name (matches ranges/unsupported lists)
  final String label;
  final double fallbackMin;
  final double fallbackMax;

  /// Current value from the camera-settings response.
  final int Function(LoadCameraSettingsResponse) read;

  /// Push a new value to the server.
  final Future<dynamic> Function(CameraClient, int) write;
}

// One row per camera property: label, fallback range, and how to read/push
// it - _load and the slider callbacks iterate this instead of restating the
// property list per use.
final _sliderSpecs = [
  _SliderSpec('brightness', 'Brightness', 0, 255, (s) => s.brightness,
      (c, v) => c.setBrightness(BrightnessRequest(value: v))),
  _SliderSpec('contrast', 'Contrast', 0, 255, (s) => s.contrast,
      (c, v) => c.setContrast(ContrastRequest(value: v))),
  _SliderSpec('saturation', 'Saturation', 0, 255, (s) => s.saturation,
      (c, v) => c.setSaturation(SaturationRequest(value: v))),
  _SliderSpec('hue', 'Hue', -180, 180, (s) => s.hue,
      (c, v) => c.setHue(HueRequest(value: v))),
  _SliderSpec('gamma', 'Gamma', 64, 300, (s) => s.gamma,
      (c, v) => c.setGamma(GammaRequest(value: v))),
  _SliderSpec('gain', 'Gain', 0, 255, (s) => s.gain,
      (c, v) => c.setGain(GainRequest(value: v))),
  _SliderSpec(
      'white_balance_temperature',
      'White balance temperature',
      2800,
      6500,
      (s) => s.whiteBalanceTemperature,
      (c, v) => c.setWhiteBalanceTemperature(
          WhiteBalanceTemperatureRequest(value: v))),
  _SliderSpec('sharpness', 'Sharpness', 0, 6, (s) => s.sharpness,
      (c, v) => c.setSharpness(SharpnessRequest(value: v))),
  _SliderSpec(
      'backlight_compensation',
      'Backlight compensation',
      0,
      2,
      (s) => s.backlightCompensation,
      (c, v) =>
          c.setBacklightCompensation(BacklightCompensationRequest(value: v))),
  _SliderSpec('pan_absolute', 'Pan', -180, 180, (s) => s.panAbsolute,
      (c, v) => c.setPanAbsolute(PanAbsoluteRequest(value: v))),
  _SliderSpec('tilt_absolute', 'Tilt', -180, 180, (s) => s.tiltAbsolute,
      (c, v) => c.setTiltAbsolute(TiltAbsoluteRequest(value: v))),
  _SliderSpec('zoom_absolute', 'Zoom', -3, 3, (s) => s.zoomAbsolute,
      (c, v) => c.setZoomAbsolute(ZoomAbsoluteRequest(value: v))),
  _SliderSpec('exposure_absolute', 'Exposure', 10, 1250,
      (s) => s.exposureAbsolute,
      (c, v) => c.setExposureAbsolute(ExposureAbsoluteRequest(value: v))),
  _SliderSpec('focus_absolute', 'Focus', 0, 120, (s) => s.focusAbsolute,
      (c, v) => c.setFocusAbsolute(FocusAbsoluteRequest(value: v))),
];

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with ServerCallState {
  LoadCameraSettingsResponse? _settings;
  final Map<String, double> _values = {};
  // Lookup tables built once per _load (build() consults them per slider).
  final Map<String, CameraPropertyRange> _ranges = {};
  final Set<String> _unsupported = {};
  String? _resolution;

  // Camera distance + Windows camera options (moved here from the old Settings
  // page). These live in the kiosk settings snapshot and push via SettingsClient.
  double _distanceMin = 0;
  double _distanceMax = 200;
  bool _msmfSelection = true;
  bool _orderingAutomatic = false;

  SettingsClient get _settingsClient => SettingsState.client;

  // Live preview state: the active camera's stream and its latest JPEG frame.
  StreamSubscription<ProcessImageData>? _previewSubscription;
  int? _previewCamera;
  Uint8List? _previewFrame;

  CameraClient get _camera => CameraClient(GrpcChannelProvider.channel);

  @override
  void initState() {
    super.initState();
    _load();
    // Retry the load when the server comes up after app start (the first
    // _load then failed and left the error screen).
    SettingsState.revision.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    _previewSubscription?.cancel();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted && _settings == null) _load();
  }

  void _startPreview(int cameraIndex) {
    _previewSubscription?.cancel();
    setState(() {
      _previewCamera = cameraIndex;
      _previewFrame = null;
      message = null;
    });
    final client = KioskClient(GrpcChannelProvider.channel);
    _previewSubscription = client
        .streamPreview(PreviewRequest(cameraIndex: cameraIndex, maxSeconds: 300))
        .listen(
      (image) {
        if (mounted && image.chunkData.isNotEmpty) {
          // Protobuf bytes fields already arrive as Uint8List - no copy.
          final data = image.chunkData;
          setState(() => _previewFrame =
              data is Uint8List ? data : Uint8List.fromList(data));
        }
      },
      onError: (Object e) => setState(() {
        message = 'Preview failed: ${operatorMessage(e)}';
        _previewSubscription = null;
        _previewCamera = null;
      }),
      onDone: () => setState(() {
        _previewSubscription = null;
        _previewCamera = null;
      }),
    );
  }

  void _stopPreview() {
    // Cancelling the gRPC call makes the server release the camera.
    _previewSubscription?.cancel();
    setState(() {
      _previewSubscription = null;
      _previewCamera = null;
      _previewFrame = null;
    });
  }

  Future<void> _load() async {
    try {
      final s = await _camera.loadSettings(Empty());
      final kiosk = SettingsState.current;
      setState(() {
        _settings = s;
        for (final spec in _sliderSpecs) {
          _values[spec.name] = spec.read(s).toDouble();
        }
        _ranges
          ..clear()
          ..addEntries(s.propertyRanges.map((r) => MapEntry(r.name, r)));
        _unsupported
          ..clear()
          ..addAll(s.unsupportedProperties);
        if (kiosk != null) {
          _resolution = '${kiosk.width}x${kiosk.height}';
          _distanceMin = kiosk.distanceMin.toDouble();
          _distanceMax = kiosk.distanceMax.toDouble();
          _msmfSelection = kiosk.msmfSelection;
          _orderingAutomatic = kiosk.cameraOrderingAutomatic;
        }
      });
    } catch (e) {
      setState(() =>
          message = 'Could not load camera settings: ${operatorMessage(e)}');
    }
  }

  CameraPropertyRange? _range(String name) => _ranges[name];

  bool _supported(String name) {
    if (_unsupported.contains(name)) return false;
    final range = _range(name);
    return range == null || range.supported;
  }

  /// Annotation behind a resolution entry. The kiosk's ELP modules have a
  /// native 16:9 sensor; non-16:9 modes (e.g. 4000x3000) are synthesized by
  /// the camera firmware and are ANAMORPHIC — faces come out narrower, and
  /// the distance/head-size measurements shift with them (proven live
  /// 2026-07-23: same pose read 49 cm @3840x2160 vs 71 cm @4000x3000).
  static String _modeNote(CameraResolution r) {
    if (r.width == 3840 && r.height == 2160) return '  — native, recommended';
    if (r.width * 9 != r.height * 16) return '  — distorts, avoid';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return Center(
          child: message == null
              ? const CircularProgressIndicator()
              : Text(message!, style: const TextStyle(color: T.fail)));
    }
    final s = _settings!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        SectionCard(
          title: 'Resolution',
          titleLeading: const DevInfoBadge('camera-resolution'),
          child: Row(children: [
            const RowLabel('Photo resolution'),
            const SizedBox(width: 10),
            DropdownMenu<String>(
              initialSelection: _resolution,
              width: 370,
              dropdownMenuEntries: [
                for (final r in SettingsState.current?.cameraResolutions ??
                    <CameraResolution>[])
                  DropdownMenuEntry(
                      value: '${r.width}x${r.height}',
                      label: '${r.width} × ${r.height}${_modeNote(r)}'),
              ],
              onSelected: (value) {
                if (value == null) return;
                final parts = value.split('x');
                setState(() => _resolution = value);
                runServerCall(() => SettingsState.client.setResolution(ResolutionRequest(
                    width: int.parse(parts[0]), height: int.parse(parts[1]))));
              },
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
            title: 'Live preview',
            titleLeading: const DevInfoBadge('camera-preview'),
            child: _buildPreview()),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Camera properties',
          titleLeading: const DevInfoBadge('camera-properties'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _switchRow('Automatic white balance', s.whiteBalanceTemperatureAuto,
                  (v) {
                setState(() => _settings!.whiteBalanceTemperatureAuto = v);
                runServerCall(() => _camera.setWhiteBalanceTemperatureAuto(
                    WhiteBalanceTemperatureAutoRequest(value: v)));
              }),
              _switchRow('Exposure auto priority', s.exposureAutoPriority, (v) {
                setState(() => _settings!.exposureAutoPriority = v);
                runServerCall(() => _camera.setExposureAutoPriority(
                    ExposureAutoPriorityRequest(value: v)));
              }),
              _switchRow('Autofocus', s.autofocus, (v) {
                setState(() => _settings!.autofocus = v);
                runServerCall(() => _camera.setAutofocus(AutofocusRequest(value: v)));
              }),
              const SizedBox(height: 6),
              for (final spec in _sliderSpecs)
                if (_supported(spec.name)) _buildSlider(spec),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
            title: 'Camera distance',
            titleLeading: const DevInfoBadge('camera-distance'),
            child: _buildDistance()),
        const SizedBox(height: 14),
        SectionCard(
            title: 'Camera (Windows)',
            titleLeading: const DevInfoBadge('camera-windows'),
            child: _buildCameraOptions()),
        ErrorLine(message),
      ]),
    );
  }

  Widget _buildDistance() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RowLabel('Minimal distance ${_distanceMin.round()}'),
      Slider(
        value: _distanceMin,
        min: 0,
        max: 200,
        onChanged: (v) => setState(() => _distanceMin = v),
        onChangeEnd: (v) => runServerCall(() => _settingsClient
            .setDistanceMin(DistanceMinRequest(value: v.round()))),
      ),
      RowLabel('Maximal distance ${_distanceMax.round()}'),
      Slider(
        value: _distanceMax,
        min: 0,
        max: 200,
        onChanged: (v) => setState(() => _distanceMax = v),
        onChangeEnd: (v) => runServerCall(() => _settingsClient
            .setDistanceMax(DistanceMaxRequest(value: v.round()))),
      ),
    ]);
  }

  // Inactive for now (user request 2026-09-14): the switches are shown greyed
  // out (onChanged: null) and push nothing. Restore the callbacks to re-enable
  // — they call setMsmfSelection / setCameraOrderingMode.
  Widget _buildCameraOptions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Switch(value: _msmfSelection, onChanged: null),
        const SizedBox(width: 8),
        const RowLabel('Fast camera selection (Media Foundation)'),
      ]),
      Row(children: [
        Switch(value: _orderingAutomatic, onChanged: null),
        const SizedBox(width: 8),
        const RowLabel('Automatic camera ordering (USB positions)'),
      ]),
    ]);
  }

  Widget _buildPreview() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const RowLabel('Camera'),
        const SizedBox(width: 14),
        for (var i = 1; i <= 6; i++) ...[
          NumButton(
              number: i,
              onPressed: _previewCamera == i ? null : () => _startPreview(i)),
          const SizedBox(width: 8),
        ],
        const SizedBox(width: 16),
        QuietButton(
            text: 'Stop preview',
            width: 150,
            onPressed: _previewSubscription == null ? null : _stopPreview),
      ]),
      const SizedBox(height: 6),
      const Text(
        'Live view at preview quality (~13 fps). Stop the preview before running '
        'captures - the cameras share USB bandwidth.',
        style: TextStyle(color: T.muted, fontSize: 12),
      ),
      if (_previewCamera != null) ...[
        const SizedBox(height: 12),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: const Color(0xFF101C26),
              width: 640,
              height: 480,
              child: _previewFrame == null
                  ? const Center(child: CircularProgressIndicator())
                  : Image.memory(_previewFrame!,
                      gaplessPlayback: true, fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _switchRow(String label, bool value, void Function(bool) onChanged) {
    return Row(children: [
      SizedBox(
          width: 46,
          child: Switch(value: value, onChanged: onChanged)),
      const SizedBox(width: 12),
      RowLabel(label),
    ]);
  }

  Widget _buildSlider(_SliderSpec spec) {
    final range = _range(spec.name);
    final min = (range?.hasMin() ?? false) && range!.supported
        ? range.min.toDouble()
        : spec.fallbackMin;
    final max = (range?.hasMax() ?? false) && range!.supported && range.max > range.min
        ? range.max.toDouble()
        : spec.fallbackMax;
    final value = (_values[spec.name] ?? min).clamp(min, max);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RowLabel('${spec.label} ${value.round()}'),
      Slider(
        value: value,
        min: min,
        max: max,
        onChanged: (v) => setState(() => _values[spec.name] = v),
        onChangeEnd: (v) =>
            runServerCall(() => spec.write(_camera, v.round())),
      ),
    ]);
  }
}
