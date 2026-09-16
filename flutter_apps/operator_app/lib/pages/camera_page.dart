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
  const _SliderSpec(this.name, this.label, this.fallbackMin, this.fallbackMax);

  final String name; // server property name (matches ranges/unsupported lists)
  final String label;
  final double fallbackMin;
  final double fallbackMax;
}

const _sliderSpecs = [
  _SliderSpec('brightness', 'Brightness', 0, 255),
  _SliderSpec('contrast', 'Contrast', 0, 255),
  _SliderSpec('saturation', 'Saturation', 0, 255),
  _SliderSpec('hue', 'Hue', -180, 180),
  _SliderSpec('gamma', 'Gamma', 64, 300),
  _SliderSpec('gain', 'Gain', 0, 255),
  _SliderSpec('white_balance_temperature', 'White balance temperature', 2800, 6500),
  _SliderSpec('sharpness', 'Sharpness', 0, 6),
  _SliderSpec('backlight_compensation', 'Backlight compensation', 0, 2),
  _SliderSpec('pan_absolute', 'Pan', -180, 180),
  _SliderSpec('tilt_absolute', 'Tilt', -180, 180),
  _SliderSpec('zoom_absolute', 'Zoom', -3, 3),
  _SliderSpec('exposure_absolute', 'Exposure', 10, 1250),
  _SliderSpec('focus_absolute', 'Focus', 0, 120),
];

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  LoadCameraSettingsResponse? _settings;
  final Map<String, double> _values = {};
  String? _resolution;
  String? _message;

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
  }

  @override
  void dispose() {
    _previewSubscription?.cancel();
    super.dispose();
  }

  void _startPreview(int cameraIndex) {
    _previewSubscription?.cancel();
    setState(() {
      _previewCamera = cameraIndex;
      _previewFrame = null;
      _message = null;
    });
    final client = KioskClient(GrpcChannelProvider.channel);
    _previewSubscription = client
        .streamPreview(PreviewRequest(cameraIndex: cameraIndex, maxSeconds: 300))
        .listen(
      (image) {
        if (mounted && image.chunkData.isNotEmpty) {
          setState(() => _previewFrame = Uint8List.fromList(image.chunkData));
        }
      },
      onError: (Object e) => setState(() {
        _message = 'Preview failed: $e';
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
        _values['brightness'] = s.brightness.toDouble();
        _values['contrast'] = s.contrast.toDouble();
        _values['saturation'] = s.saturation.toDouble();
        _values['hue'] = s.hue.toDouble();
        _values['gamma'] = s.gamma.toDouble();
        _values['gain'] = s.gain.toDouble();
        _values['white_balance_temperature'] =
            s.whiteBalanceTemperature.toDouble();
        _values['sharpness'] = s.sharpness.toDouble();
        _values['backlight_compensation'] =
            s.backlightCompensation.toDouble();
        _values['pan_absolute'] = s.panAbsolute.toDouble();
        _values['tilt_absolute'] = s.tiltAbsolute.toDouble();
        _values['zoom_absolute'] = s.zoomAbsolute.toDouble();
        _values['exposure_absolute'] = s.exposureAbsolute.toDouble();
        _values['focus_absolute'] = s.focusAbsolute.toDouble();
        if (kiosk != null) {
          _resolution = '${kiosk.width}x${kiosk.height}';
          _distanceMin = kiosk.distanceMin.toDouble();
          _distanceMax = kiosk.distanceMax.toDouble();
          _msmfSelection = kiosk.msmfSelection;
          _orderingAutomatic = kiosk.cameraOrderingAutomatic;
        }
      });
    } catch (e) {
      setState(() => _message = 'Could not load camera settings: $e');
    }
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    try {
      await action();
      if (mounted) setState(() => _message = null);
    } catch (e) {
      if (mounted) setState(() => _message = 'Server call failed: $e');
    }
  }

  Future<void> _push(String name, int value) {
    final c = _camera;
    return _run(() => switch (name) {
          'brightness' => c.setBrightness(BrightnessRequest(value: value)),
          'contrast' => c.setContrast(ContrastRequest(value: value)),
          'saturation' => c.setSaturation(SaturationRequest(value: value)),
          'hue' => c.setHue(HueRequest(value: value)),
          'gamma' => c.setGamma(GammaRequest(value: value)),
          'gain' => c.setGain(GainRequest(value: value)),
          'white_balance_temperature' => c.setWhiteBalanceTemperature(
              WhiteBalanceTemperatureRequest(value: value)),
          'sharpness' => c.setSharpness(SharpnessRequest(value: value)),
          'backlight_compensation' => c.setBacklightCompensation(
              BacklightCompensationRequest(value: value)),
          'pan_absolute' => c.setPanAbsolute(PanAbsoluteRequest(value: value)),
          'tilt_absolute' =>
            c.setTiltAbsolute(TiltAbsoluteRequest(value: value)),
          'zoom_absolute' =>
            c.setZoomAbsolute(ZoomAbsoluteRequest(value: value)),
          'exposure_absolute' =>
            c.setExposureAbsolute(ExposureAbsoluteRequest(value: value)),
          'focus_absolute' =>
            c.setFocusAbsolute(FocusAbsoluteRequest(value: value)),
          _ => throw ArgumentError('unknown property $name'),
        });
  }

  CameraPropertyRange? _range(String name) {
    final ranges = _settings?.propertyRanges;
    if (ranges == null) return null;
    for (final range in ranges) {
      if (range.name == name) return range;
    }
    return null;
  }

  bool _supported(String name) {
    if (_settings?.unsupportedProperties.contains(name) ?? false) return false;
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
          child: _message == null
              ? const CircularProgressIndicator()
              : Text(_message!, style: const TextStyle(color: T.fail)));
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
                _run(() => SettingsState.client.setResolution(ResolutionRequest(
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
                _run(() => _camera.setWhiteBalanceTemperatureAuto(
                    WhiteBalanceTemperatureAutoRequest(value: v)));
              }),
              _switchRow('Exposure auto priority', s.exposureAutoPriority, (v) {
                setState(() => _settings!.exposureAutoPriority = v);
                _run(() => _camera.setExposureAutoPriority(
                    ExposureAutoPriorityRequest(value: v)));
              }),
              _switchRow('Autofocus', s.autofocus, (v) {
                setState(() => _settings!.autofocus = v);
                _run(() => _camera.setAutofocus(AutofocusRequest(value: v)));
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
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, style: const TextStyle(color: T.fail, fontSize: 13)),
        ],
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
        onChangeEnd: (v) => _run(() => _settingsClient
            .setDistanceMin(DistanceMinRequest(value: v.round()))),
      ),
      RowLabel('Maximal distance ${_distanceMax.round()}'),
      Slider(
        value: _distanceMax,
        min: 0,
        max: 200,
        onChanged: (v) => setState(() => _distanceMax = v),
        onChangeEnd: (v) => _run(() => _settingsClient
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
        onChangeEnd: (v) => _push(spec.name, v.round()),
      ),
    ]);
  }
}
