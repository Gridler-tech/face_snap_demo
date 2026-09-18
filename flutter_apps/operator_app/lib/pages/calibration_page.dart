// Calibration page — port of the MAUI CalibrationPage: the camera-positions
// table (physical camera -> calibrated position 1..N) and focus calibration.
// Two focus methods: the server's autofocus-lock assistant, and a
// client-driven SHARPNESS SWEEP (tries a range of focus values, takes a real
// photo at each and keeps the one whose face is sharpest) for when the
// camera's autofocus will not lock.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import '../services/settings_state.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';

class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  List<CalibrateType>? _rows;
  int _currentFocus = -1;
  int _expectedCameras = 0;
  bool _sweeping = false;
  String? _sweepProgress;
  Uint8List? _bestPhoto; // the sharpest capture from the last sweep
  String? _message;

  CalibrationClient get _calibration =>
      CalibrationClient(GrpcChannelProvider.channel);
  CameraClient get _camera => CameraClient(GrpcChannelProvider.channel);

  @override
  void initState() {
    super.initState();
    _load();
    // Retry the load when the server comes up after app start.
    SettingsState.revision.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted && _rows == null) _load();
  }

  Future<void> _load() async {
    try {
      // Independent reads — one round-trip each, in parallel. The expected
      // camera count comes from the shared settings snapshot instead of a
      // third LoadSettings call.
      final (calibration, camera) = await (
        _calibration.getCalibration(Empty()),
        _camera.loadSettings(Empty()),
      ).wait;
      setState(() {
        _rows = calibration.calibrate.toList()
          ..sort((a, b) => a.linuxCameraIndex.compareTo(b.linuxCameraIndex));
        _currentFocus = camera.focusAbsolute;
        _expectedCameras = SettingsState.current?.expectedCameras ?? 0;
      });
    } catch (e) {
      setState(
          () => _message = 'Could not load calibration: ${operatorMessage(e)}');
    }
  }

  Future<void> _saveExpectedCameras(int value) async {
    final previous = _expectedCameras;
    setState(() => _expectedCameras = value);
    try {
      await SettingsState.client
          .setExpectedCameras(ExpectedCamerasRequest(value: value));
      // Write through to the shared snapshot so other readers stay current.
      SettingsState.current?.expectedCameras = value;
    } catch (e) {
      setState(() {
        _expectedCameras = previous;
        _message =
            'Could not save the expected camera count: ${operatorMessage(e)}';
      });
    }
  }

  Future<void> _savePositions() async {
    try {
      final response = await _calibration
          .setCalibration(CalibrateRequest(calibrate: _rows));
      setState(() => _message =
          response.success ? null : 'Save failed: ${response.message}');
      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera positions saved.')));
      }
    } catch (e) {
      setState(() => _message = 'Save failed: ${operatorMessage(e)}');
    }
  }

  // ---------- focus calibration (sharpness sweep) ----------

  /// Focus range to search. The manual-focus property is 0..120 on the ELP
  /// cameras (a coarse pass then a fine pass around the peak keeps it to a
  /// dozen or so captures).
  static const _focusMin = 0;
  static const _focusMax = 120;

  /// Run one automatic capture and return its JPEG (null if the flow ended
  /// without a photo). The automatic flow applies the manual focus and the LED
  /// lighting, so the frame reflects what a real capture at this focus looks
  /// like — that is why the sweep uses it rather than the raw preview.
  Future<Uint8List?> _captureOnce() async {
    Uint8List? photo;
    await for (final event in startAutomaticCapture()) {
      if (event is CapturePhoto) photo = event.bytes;
    }
    return photo;
  }

  /// Face-region sharpness of a JPEG: variance of the Laplacian over the centre
  /// crop, skipping the digitally-white background (>=245) so it cannot dominate
  /// the smooth, high-value area. Higher = sharper. Runs in Dart; no server or
  /// extra package needed.
  Future<double> _faceSharpness(Uint8List jpeg) async {
    final codec = await ui.instantiateImageCodec(jpeg);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width, h = image.height;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) return 0;
    final px = data.buffer.asUint8List();

    final x0 = (w * 0.25).floor(), x1 = (w * 0.75).floor();
    final y0 = (h * 0.20).floor(), y1 = (h * 0.80).floor();
    final cw = x1 - x0, chh = y1 - y0;
    if (cw < 8 || chh < 8) return 0;

    // Grayscale of the crop (BT.601 luma).
    final gray = Uint8List(cw * chh);
    for (var y = 0; y < chh; y++) {
      var src = ((y0 + y) * w + x0) * 4;
      var dst = y * cw;
      for (var x = 0; x < cw; x++) {
        gray[dst++] =
            (px[src] * 299 + px[src + 1] * 587 + px[src + 2] * 114) ~/ 1000;
        src += 4;
      }
    }

    // Variance of the 4-neighbour Laplacian over non-white pixels.
    var sum = 0.0, sumSq = 0.0, n = 0;
    for (var y = 1; y < chh - 1; y++) {
      for (var x = 1; x < cw - 1; x++) {
        final c = gray[y * cw + x];
        if (c >= 245) continue;
        final lap = 4 * c -
            gray[(y - 1) * cw + x] -
            gray[(y + 1) * cw + x] -
            gray[y * cw + x - 1] -
            gray[y * cw + x + 1];
        sum += lap;
        sumSq += lap * lap;
        n++;
      }
    }
    if (n < 1000) return 0;
    final mean = sum / n;
    return sumSq / n - mean * mean;
  }

  /// Focus-indicator colour for sweep progress `t` (0 = start, 1 = pinpoint):
  /// red -> amber -> green as a RRGGBB hex (hue 0°..120° at full saturation).
  static String _sweepHex(double t) {
    final h = 120.0 * t.clamp(0.0, 1.0) / 60.0; // 0..2
    final x = 1 - (h % 2 - 1).abs();
    final double r, g;
    if (h < 1) {
      r = 1;
      g = x;
    } else {
      r = x;
      g = 1;
    }
    String c(double v) =>
        (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '${c(r)}${c(g)}00'.toUpperCase();
  }

  Future<void> _focusSweep() async {
    setState(() {
      _sweeping = true;
      _message = null;
      _sweepProgress = 'Starting…';
      _bestPhoto = null;
    });
    final scores = <int, double>{};
    // The photo of the sharpest focus so far, shown when the sweep ends.
    Uint8List? bestBytes;
    var bestScore = -1.0;
    // Remember the focus-indicator colour so it can be restored afterwards;
    // during the sweep it is driven red -> green as the search converges.
    var origFocusColor = '00FF00';
    var focusIntensity = 100;
    try {
      try {
        final s = await SettingsState.client.loadSettings(Empty());
        if (s.focusColor.isNotEmpty) origFocusColor = s.focusColor;
        if (s.focusIntensity > 0) focusIntensity = s.focusIntensity;
      } catch (_) {/* keep defaults */}

      // The sweep is a manual-focus search: autofocus must be off for the
      // values to take effect.
      await _camera.setAutofocus(AutofocusRequest(value: false));

      int bestFocus() =>
          scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      // The colour reaches full green by the time the fine/pinpoint passes run
      // (roughly this many captures in).
      const shotsToGreen = 11;
      var shot = 0;

      // Capture + score one focus value (skips values already measured, so the
      // fine passes never re-shoot a point the coarse pass already covered).
      Future<void> measure(int focus, String phase) async {
        if (scores.containsKey(focus)) return;
        final soFar = scores.isEmpty ? null : bestFocus();
        setState(() => _sweepProgress = '$phase: testing focus $focus'
            '${soFar == null ? '' : ' · sharpest so far $soFar'}');
        // Drive the focus light toward green as the sweep progresses. The
        // capture below uses this focus_color for the per-camera indicator.
        try {
          await SettingsState.client.setFocusLight(FocusLightRequest(
              color: _sweepHex(shot / shotsToGreen), intensity: focusIntensity));
        } catch (_) {/* the sweep still works without the light cue */}
        shot++;
        await _camera.setFocusAbsolute(FocusAbsoluteRequest(value: focus));
        final bytes = await _captureOnce();
        if (bytes != null) {
          final s = await _faceSharpness(bytes);
          scores[focus] = s;
          if (s > bestScore) {
            bestScore = s;
            bestBytes = bytes;
          }
        }
      }

      // One pass: measure center±radius in `step` increments (clamped).
      Future<void> pass(String label, int center, int radius, int step) async {
        for (var f = center - radius; f <= center + radius; f += step) {
          if (f >= _focusMin && f <= _focusMax) await measure(f, label);
        }
      }

      // 1) Coarse pass over the whole range in steps of 20 (0,20,…,120).
      const coarseStep = 20;
      final mid = (_focusMin + _focusMax) ~/ 2;
      await pass('Coarse pass (step 20)', mid, (_focusMax - _focusMin) ~/ 2,
          coarseStep);
      if (scores.isEmpty) {
        setState(() => _message =
            'The sweep got no photos. Is someone standing at the marking?');
        return;
      }
      // 2) Fine pass: refine ±10 around the coarse best in steps of 5.
      await pass('Fine pass (step 5)', bestFocus(), coarseStep ~/ 2, 5);
      // 3) Pinpoint: ±4 around the fine best in steps of 2, for the exact value.
      await pass('Pinpoint (step 2)', bestFocus(), 4, 2);

      final best = bestFocus();
      await _camera.setFocusAbsolute(FocusAbsoluteRequest(value: best));
      setState(() {
        _currentFocus = best;
        _bestPhoto = bestBytes;
        _sweepProgress = 'Focus set to $best — signalling done';
      });
      // Success flourish on the light strip (green, then fade to dark).
      await _celebrateFocusFound();
    } catch (e) {
      setState(() => _message = 'Sharpness sweep failed: ${operatorMessage(e)}');
    } finally {
      // Restore the focus indicator to its configured colour.
      try {
        await SettingsState.client.setFocusLight(FocusLightRequest(
            color: origFocusColor, intensity: focusIntensity));
      } catch (_) {/* best effort */}
      setState(() {
        _sweeping = false;
        _sweepProgress = null;
      });
    }
  }

  /// Calibration-done flourish: the whole light strip turns green for a moment,
  /// then the green fades out (a clean wipe to dark) and the lights switch off.
  /// The real white-balance channels are restored afterwards so the next capture
  /// is unaffected. Best-effort — a light hiccup never fails the calibration.
  Future<void> _celebrateFocusFound() async {
    final lights = LightsClient(GrpcChannelProvider.channel);
    final settings = SettingsState.client;
    final s = SettingsState.current;
    final r0 = s?.intensityRed ?? 200;
    final g0 = s?.intensityGreen ?? 200;
    final b0 = s?.intensityBlue ?? 200;
    try {
      // Whole strip green.
      await settings.setIntensityRed(IntensityRequest(value: 0));
      await settings.setIntensityBlue(IntensityRequest(value: 0));
      await settings.setIntensityGreen(IntensityRequest(value: 220));
      await lights.setAllLights(AllLightsRequest(status: true));
      await Future.delayed(const Duration(milliseconds: 1300));
      // Fade the green down to dark, then off.
      for (final g in [150, 95, 45, 15]) {
        await settings.setIntensityGreen(IntensityRequest(value: g));
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await lights.setAllLights(AllLightsRequest(status: false));
    } catch (_) {/* best effort */
    } finally {
      // Restore the configured white-balance channels.
      try {
        await settings.setIntensityRed(IntensityRequest(value: r0));
        await settings.setIntensityGreen(IntensityRequest(value: g0));
        await settings.setIntensityBlue(IntensityRequest(value: b0));
      } catch (_) {/* best effort */}
    }
  }

  void _showBestPhoto(Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF101C26),
        insetPadding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          Flexible(
            child: InteractiveViewer(
              maxScale: 8,
              child: Image.memory(bytes),
            ),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        SectionCard(
          title: 'Camera positions',
          titleLeading: const DevInfoBadge('calibration-positions'),
          child: rows == null
              ? const Center(child: CircularProgressIndicator())
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text(
                    'Assign each physical camera to its position on the column '
                    '(1 = bottom). Save after changing.',
                    style: TextStyle(color: T.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        SizedBox(
                            width: 220,
                            child: RowLabel('Camera ${row.idModelId}')),
                        SizedBox(
                            width: 90,
                            child: Text('index ${row.linuxCameraIndex}',
                                style: const TextStyle(
                                    color: T.muted, fontSize: 13))),
                        DropdownMenu<int>(
                          initialSelection: row.calibratedCameraIndex,
                          width: 170,
                          dropdownMenuEntries: [
                            for (var i = 0; i <= rows.length; i++)
                              DropdownMenuEntry(
                                  value: i,
                                  label: i == 0 ? 'unset' : 'position $i'),
                          ],
                          onSelected: (v) {
                            if (v != null) {
                              setState(() => row.calibratedCameraIndex = v);
                            }
                          },
                        ),
                      ]),
                    ),
                  const SizedBox(height: 12),
                  GoButton(text: 'Save positions', onPressed: _savePositions),
                ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Expected cameras',
          titleLeading: const DevInfoBadge('expected-cameras'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'How many cameras this kiosk is built with. The server checks the '
              'attached count against this and power-cycles the camera hub when '
              'cameras are missing. "Automatic" derives the count from the '
              'calibration file.',
              style: TextStyle(color: T.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const SizedBox(width: 220, child: RowLabel('Camera count')),
              DropdownMenu<int>(
                // initialSelection only applies on first build; re-key so the
                // menu shows the loaded value once loadSettings returns.
                key: ValueKey('expected-$_expectedCameras'),
                initialSelection: _expectedCameras,
                width: 170,
                dropdownMenuEntries: [
                  for (var i = 0; i <= 6; i++)
                    DropdownMenuEntry(
                        value: i, label: i == 0 ? 'automatic' : '$i'),
                ],
                onSelected: (v) {
                  if (v != null) _saveExpectedCameras(v);
                },
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Focus calibration',
          titleLeading: const DevInfoBadge('calibrate-focus'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Sets the fixed focus so photos are sharp at the customer\'s '
              'distance. Have a person stand at the floor marking, then press '
              'Calibrate focus.',
              style: TextStyle(color: T.ink, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'The camera takes a photo at a range of focus settings and keeps '
              'the one where the face is sharpest — first a coarse pass in steps '
              'of 20 across the whole range, then a fine pass to pinpoint the '
              'exact value. The camera\'s focus ring runs from red to green as '
              'it homes in. It takes a minute or two; keep the person still at '
              'the marking until it finishes.',
              style: TextStyle(color: T.muted, fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 14),
            Row(children: [
              SizedBox(
                width: 220,
                child: GoButton(
                    text: _sweeping ? 'Calibrating…' : 'Calibrate focus',
                    onPressed: _sweeping ? null : _focusSweep),
              ),
              const SizedBox(width: 16),
              if (_sweeping) ...[
                const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator()),
                const SizedBox(width: 12),
                Expanded(
                    child: RowLabel(_sweepProgress ?? 'Calibrating…')),
              ] else
                RowLabel(_currentFocus >= 0
                    ? 'Current focus: $_currentFocus'
                    : 'Current focus: unknown'),
            ]),
            if (!_sweeping && _bestPhoto != null) ...[
              const SizedBox(height: 14),
              Text('Sharpest result (focus $_currentFocus):',
                  style: const TextStyle(
                      color: T.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showBestPhoto(_bestPhoto!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  // Decode at preview size, not the native crop resolution.
                  child: Image.memory(_bestPhoto!,
                      height: 260, cacheHeight: 520, fit: BoxFit.fitHeight),
                ),
              ),
              const SizedBox(height: 4),
              const Text('Click to enlarge',
                  style: TextStyle(color: T.muted, fontSize: 12)),
            ],
          ]),
        ),
        ErrorLine(_message),
      ]),
    );
  }
}
