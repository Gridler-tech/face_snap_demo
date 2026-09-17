// Calibration page — port of the MAUI CalibrationPage: the camera-positions
// table (physical camera -> calibrated position 1..N) and the one-button focus
// calibration (server selects the best camera, lets autofocus settle under the
// LEDs and stores the locked value as the fixed focus).
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
  bool _calibratingFocus = false;
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

  Future<void> _calibrateFocus() async {
    setState(() {
      _calibratingFocus = true;
      _message = null;
    });
    try {
      // camera_index 0 = the server runs its own best-camera selection first
      // (LEDs on, person at the marking), then lets autofocus settle.
      final response = await _camera.calibrateFocus(
          CalibrateFocusRequest(cameraIndex: 0),
          options: CallOptions(timeout: const Duration(seconds: 90)));
      final value = response.message;
      setState(() {
        if (value >= 0) {
          _currentFocus = value;
        } else {
          _message = 'Focus calibration did not reach a lock. '
              'Is someone standing at the marking?';
        }
      });
    } catch (e) {
      setState(() => _message = 'Focus calibration failed: ${operatorMessage(e)}');
    } finally {
      setState(() => _calibratingFocus = false);
    }
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
              'Have a person stand at the floor marking, then press the button. '
              'The server selects the best camera, lets autofocus settle under '
              'the LEDs and stores the locked value as the fixed focus.',
              style: TextStyle(color: T.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(children: [
              SizedBox(
                width: 220,
                child: GoButton(
                    text: _calibratingFocus ? 'Calibrating…' : 'Calibrate focus',
                    onPressed: _calibratingFocus ? null : _calibrateFocus),
              ),
              const SizedBox(width: 16),
              if (_calibratingFocus)
                const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator()),
              if (!_calibratingFocus)
                RowLabel(_currentFocus >= 0
                    ? 'Current focus: $_currentFocus'
                    : 'Current focus: unknown'),
            ]),
          ]),
        ),
        ErrorLine(_message),
      ]),
    );
  }
}
