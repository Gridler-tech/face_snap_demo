// Calibration page — port of the MAUI CalibrationPage: the camera-positions
// table (physical camera -> calibrated position 1..N), the expected camera count,
// focus calibration and the photo colour (photo_colour_card.dart). An overview of
// four tiles on top (calibration_tiles.dart, design 2026-10-16) shows what is done;
// only the selected tile's section is shown below them.
// Two focus methods: the server's autofocus-lock assistant, and a
// client-driven SHARPNESS SWEEP (tries a range of focus values, takes a real
// photo at each and keeps the one whose face is sharpest) for when the
// camera's autofocus will not lock.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import '../services/column_state.dart';
import '../services/settings_state.dart';
import '../ui/calibration_tiles.dart';
import '../ui/column_mark.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';
import '../util/sharpness.dart';
import '../util/sweep_color.dart';
import 'photo_colour_card.dart';

/// gRPC status UNIMPLEMENTED (`StatusCode.unimplemented`): `grpc` is only a dev dependency of
/// the operator app (face_snap_grpc exports `GrpcError`, not `StatusCode`).
const _unimplemented = 12;

/// gRPC status INVALID_ARGUMENT (`StatusCode.invalidArgument`).
const _invalidArgument = 3;

/// The explanation under the "Camera ordering" selector for each mode.
String orderingModeHelp(String mode) => switch (mode) {
      'automatic' =>
        'The column is ordered from its USB sockets when the wiring matches a '
            'known loom, and that wins over the positions below.',
      'person' =>
        'The server works out the positions from a person: stand straight in '
            'front of the column at the normal photo distance, look ahead and '
            'hold still, then start. The result fills the positions below; '
            'check it and save.',
      'surroundings' =>
        'The server works out the positions from what the cameras see, with '
            'nobody in front of the column. It needs a scene with detail (it '
            'fails on a plain backdrop); check the result and save.',
      _ => 'The positions saved below are used. Set each camera and save.',
    };

/// The help line under the "USB hub mounted upside down" switch (spec 2026-10-15 section 2).
const hubUpsideDownHelp =
    'Mirrors the automatic order for a column whose USB hub is mounted upside down.';

/// What an older server (no SetCameraHubUpsideDown, no "surroundings") is missing - the
/// one place this text lives. Server 2.0's image number is filled in at the release.
const needsNewerServer =
    'needs FaceSnap server 1.1.25 or newer (Server 2.0: the matching image)';

/// Under the hub switch while a proposal ("By a person", "From the surroundings") waits
/// in the position boxes: flipping the switch re-reads the rows, which would replace it.
const hubLockedByProposal =
    'Save the proposed positions before changing this switch.';

/// The selector's line when the server cannot take the "surroundings" mode.
const _noSurroundings = 'This server cannot work out the order from the '
    'surroundings yet ($needsNewerServer); the saved positions are used.';

/// The two ordering modes in which the server PROPOSES the positions (the start button,
/// the proposal in the position boxes, "Save positions" to keep it): the texts that
/// differ between them.
typedef _ProposalFlow = ({
  String start,
  String busy,
  String scanning,
  String proposed,
});

const _proposalFlows = <String, _ProposalFlow>{
  'person': (
    start: 'Start calibration by a person',
    busy: 'Calibrating - hold still…',
    scanning: 'Scanning the column three times (about 10 s)',
    proposed: 'Positions proposed from the person in front of the column. '
        'Check them below and press "Save positions" to keep them.',
  ),
  'surroundings': (
    start: 'Start calibration from the surroundings',
    busy: 'Calibrating - keep the column clear…',
    scanning: 'Comparing the cameras\' views twice (about 10-20 s)',
    proposed: 'Positions proposed from what the cameras see. '
        'Check them below and press "Save positions" to keep them.',
  ),
};

/// The deadline of both proposal calls: the person scan takes about 10 s, the
/// surroundings comparison 8-22 s for six cameras; a capture holding the gate first
/// adds its own time.
const _proposalTimeout = Duration(seconds: 180);

/// The tile the operator clicked last: remembered while the app runs (not on disk).
CalibrationSection? _rememberedSection;

class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});

  /// Tests: start without a remembered tile.
  @visibleForTesting
  static void forgetSelection() => _rememberedSection = null;

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  List<CalibrateType>? _rows;

  /// How the camera positions are decided: 'manual' (the positions saved below),
  /// 'automatic' (from the USB sockets when the wiring is a known loom),
  /// 'person' (the saved positions, worked out by the server from a person
  /// standing in front of the column) or 'surroundings' (the same, worked out from
  /// what the cameras see with nobody in front) - see [_propose].
  String _orderingMode = 'manual';

  /// True while the server works out a proposal (by a person or from the surroundings).
  bool _proposing = false;

  /// What the last proposal said, and whether it succeeded.
  String? _proposalNote;
  bool _proposalSucceeded = false;

  /// True while a successful proposal sits in the position boxes, not yet saved: the hub
  /// switch is locked then (its refresh would replace the rows), until "Save positions"
  /// or another ordering mode.
  bool _proposalUnsaved = false;

  /// The "USB hub mounted upside down" switch: the value the server applied.
  bool _hubUpsideDown = false;

  /// True while the switch's call runs.
  bool _settingHub = false;

  /// Under the switch: why it could not be set (an older server).
  String? _hubNote;
  int _currentFocus = -1;
  int _expectedCameras = 0;
  bool _sweeping = false;
  String? _sweepProgress;
  Uint8List? _bestPhoto; // the sharpest capture from the last sweep
  String? _message;

  /// The error line a failed [_load] put up; a later successful load removes
  /// it (and only it — a newer, different error stays).
  String? _loadError;

  /// The tile opened when the operator has not chosen one: the first that is not
  /// done, fixed at the first successful load (so the section does not jump away
  /// while the operator works in it).
  CalibrationSection? _defaultSection;

  /// True while "Refresh cameras" reads everything again.
  bool _refreshing = false;

  CalibrationClient get _calibration =>
      CalibrationClient(GrpcChannelProvider.channel);
  CameraClient get _camera => CameraClient(GrpcChannelProvider.channel);

  /// SettingsState.serverKey the rows were loaded for (see _onSettingsChanged).
  String? _loadedFor;

  @override
  void initState() {
    super.initState();
    _loadedFor = SettingsState.serverKey;
    _load();
    // Retry the load when the server comes up after app start, and reload
    // when the app switches to another server.
    SettingsState.revision.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final server = SettingsState.serverKey;
    if (_rows != null && _loadedFor == server) return; // loaded, same server
    // "Refresh cameras" reads the snapshot and then the rows itself.
    if (_refreshing && _loadedFor == server) return;
    if (_loadedFor != server) {
      // Switched servers: drop the previous server's rows at once so the
      // page shows "loading", never six cameras for a four-camera kiosk; the
      // default tile is worked out again from the new server's state.
      setState(() {
        _rows = null;
        _defaultSection = null;
      });
    }
    _loadedFor = server;
    _load();
  }

  /// Re-read the attached cameras and their positions from the server. The
  /// column can change under a CONNECTED server — a camera swapped, a whole
  /// new rig plugged in — and nothing else re-reads it: a reload only happens
  /// at start-up and on a server switch.
  Future<void> _refresh() async {
    setState(() {
      _rows = null;
      _message = null;
    });
    _loadedFor = SettingsState.serverKey;
    await _load();
  }

  /// "Refresh cameras" (top right): read the settings snapshot again (the expected
  /// count, the ordering mode, the photo colours; and the column profile), then the
  /// cameras and the focus - all four tiles. A snapshot that cannot be read keeps the
  /// last one; the rows' load reports the error. The rows go at once, so the spinner
  /// shows while a slow kiosk answers.
  Future<void> _refreshAll() async {
    setState(() {
      _refreshing = true;
      _rows = null;
      _message = null;
    });
    try {
      await SettingsState.refresh();
    } catch (_) {/* _load below reports an unreachable kiosk */}
    if (!mounted) return;
    await _refresh();
    if (mounted) setState(() => _refreshing = false);
  }

  /// The four tiles' value lines and statuses, from what the page holds.
  Map<CalibrationSection, TileState> _tiles() {
    final rows = _rows;
    final loaded = rows != null;
    return {
      CalibrationSection.cameraOrder: cameraOrderTile(
          mode: _orderingMode,
          positions: rows?.map((r) => r.calibratedCameraIndex).toList(),
          notSaved: _proposalUnsaved ||
              ColumnState.anyChanged(const ['calibration', 'hub_upside_down'])),
      CalibrationSection.expectedCameras: expectedCamerasTile(
          expected: _expectedCameras,
          found: rows?.length,
          notSaved: ColumnState.anyChanged(const ['expected_cameras'])),
      CalibrationSection.focus: focusTile(
          focus: loaded ? _currentFocus : null,
          notSaved: ColumnState.anyChanged(const ['focus_absolute'])),
      CalibrationSection.photoColour: photoColourTile(
          SettingsState.current?.colourCorrections,
          notSaved: ColumnState.anyChanged(const ['colour_correction'])),
    };
  }

  /// Refresh would reload the server state under work in progress: an unsaved
  /// proposal (replaced by the saved rows) or a focus sweep (its short-lived focus
  /// colour and focus values snapshotted as the settings).
  bool get _canRefresh =>
      !_refreshing && !_proposing && !_proposalUnsaved && !_sweeping;

  CalibrationSection get _selected =>
      _rememberedSection ?? _defaultSection ?? CalibrationSection.cameraOrder;

  void _select(CalibrationSection section) =>
      setState(() => _rememberedSection = section);

  /// Switch the ordering mode on the kiosk, then re-read the rows: the
  /// resolved positions change with the mode (the same resolver serves the
  /// capture flow and this page).
  Future<void> _setOrdering(String mode) async {
    final before = _orderingMode;
    if (mode == before) return;
    setState(() {
      _orderingMode = mode;
      _proposalNote = null;
      _proposalUnsaved = false;
    });
    try {
      final reply = await SettingsState.client.setCameraOrderingMode(
          CameraOrderingModeRequest(automatic: mode == 'automatic', mode: mode));
      // A server from before the mode field answers with the flag only.
      final set = reply.mode.isEmpty
          ? (reply.automatic ? 'automatic' : 'manual')
          : reply.mode;
      SettingsState.current
        ?..cameraOrderingAutomatic = set == 'automatic'
        ..cameraOrderingMode = set;
      await _refresh();
      if (mounted && set != mode) {
        setState(() => _message = switch (mode) {
              'person' =>
                'This server cannot calibrate by a person yet (needs server '
                    '1.1.15 / image 2.0.14); the saved positions are used.',
              'surroundings' => _noSurroundings,
              _ => 'The server set the ordering mode to "$set".',
            });
      }
    } catch (e) {
      // A server from before 1.1.25 (1.1.15-1.1.24, images 2.0.14-2.0.23) refuses the
      // unknown "surroundings" with INVALID_ARGUMENT; nothing was changed there.
      final older = mode == 'surroundings' &&
          e is GrpcError &&
          (e.code == _invalidArgument || e.code == _unimplemented);
      if (!mounted) return;
      setState(() {
        _orderingMode = before;
        _message = older
            ? _noSurroundings
            : 'Could not change the ordering mode: ${operatorMessage(e)}';
      });
    }
  }

  /// Ask the server to work out the positions: from the person standing in front
  /// of the column (CalibrateByPerson, three scans, about ten seconds) or from what
  /// the cameras see with nobody in front (CalibrateBySurroundings, two rounds,
  /// about 8-22 s). A successful result is put in the position boxes as a
  /// PROPOSAL; the operator checks it and saves it with "Save positions". A
  /// refused one shows the server's message and leaves the boxes alone.
  Future<void> _propose(String mode) async {
    final flow = _proposalFlows[mode];
    if (flow == null || _proposing) return;
    setState(() {
      _proposing = true;
      _proposalNote = null;
      _proposalUnsaved = false;
      _message = null;
    });
    final options = CallOptions(timeout: _proposalTimeout);
    try {
      final (bool success, String message, Map<int, int> proposed) =
          switch (mode) {
        'surroundings' => await _calibration
            .calibrateBySurroundings(Empty(), options: options)
            .then((r) => (
                  r.success,
                  r.message,
                  {for (final c in r.cameras) c.linuxCameraIndex: c.proposedPosition},
                )),
        _ => await _calibration
            .calibrateByPerson(Empty(), options: options)
            .then((r) => (
                  r.success,
                  r.message,
                  {for (final c in r.cameras) c.linuxCameraIndex: c.proposedPosition},
                )),
      };
      if (!mounted) return;
      setState(() {
        _proposalSucceeded = success;
        if (success) {
          for (final row in _rows ?? const <CalibrateType>[]) {
            final position = proposed[row.linuxCameraIndex];
            if (position != null) row.calibratedCameraIndex = position;
          }
          _proposalNote = flow.proposed;
          _proposalUnsaved = true;
        } else {
          _proposalNote = message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _proposalSucceeded = false;
        _proposalNote = mode == 'surroundings' &&
                e is GrpcError &&
                e.code == _unimplemented
            ? 'This server cannot work out the order from the surroundings '
                'yet ($needsNewerServer).'
            : 'The calibration could not run: ${operatorMessage(e)}';
      });
    } finally {
      if (mounted) setState(() => _proposing = false);
    }
  }

  /// The switch is locked while a proposal is being worked out or waits unsaved in the
  /// position boxes: the refresh after a flip would replace it.
  bool get _hubLocked => _proposing || _proposalUnsaved;

  /// The "USB hub mounted upside down" switch: send it, show the value the server
  /// applied, then re-read the camera rows: both servers' GetCalibration resolve them
  /// like a capture, so in automatic mode (and the loom fallback of an incomplete
  /// calibration) the rows show the mirrored order; a complete calibration stays as
  /// saved. A server from before 1.1.25 answers UNIMPLEMENTED: the switch stays off and
  /// says which server it needs. A column setting: the column profile is read again, so
  /// its "not saved" mark shows.
  Future<void> _setHubUpsideDown(bool on) async {
    final before = _hubUpsideDown;
    if (_settingHub || _hubLocked || on == before) return;
    setState(() {
      _hubUpsideDown = on;
      _settingHub = true;
      _hubNote = null;
    });
    try {
      final reply = await SettingsState.client
          .setCameraHubUpsideDown(CameraHubUpsideDownRequest(upsideDown: on));
      SettingsState.current?.cameraHubUpsideDown = reply.upsideDown;
      ColumnState.touch();
      if (!mounted) return;
      setState(() {
        _hubUpsideDown = reply.upsideDown;
        _settingHub = false;
      });
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      final older = e is GrpcError && e.code == _unimplemented;
      setState(() {
        _settingHub = false;
        if (older) {
          _hubUpsideDown = false;
          _hubNote = 'The USB hub switch $needsNewerServer.';
        } else {
          _hubUpsideDown = before;
          _message =
              'Could not change the USB hub setting: ${operatorMessage(e)}';
        }
      });
    }
  }

  Future<void> _load() async {
    try {
      // Independent reads — one round-trip each, in parallel. The expected
      // camera count comes from the shared settings snapshot instead of a
      // third LoadSettings call. Future.wait, not a record's .wait: that one
      // wraps a failure in a ParallelWaitError, which the error line then
      // showed raw instead of "kiosk not reachable".
      final calibrationCall = _calibration.getCalibration(Empty());
      final cameraCall = _camera.loadSettings(Empty());
      await Future.wait([calibrationCall, cameraCall]);
      final calibration = await calibrationCall;
      final camera = await cameraCall;
      if (!mounted) return; // the page went away while the calls ran
      setState(() {
        if (_message == _loadError) _message = null;
        _loadError = null;
        _rows = calibration.calibrate.toList()
          ..sort((a, b) => a.linuxCameraIndex.compareTo(b.linuxCameraIndex));
        _currentFocus = camera.focusAbsolute;
        _expectedCameras = SettingsState.current?.expectedCameras ?? 0;
        final settings = SettingsState.current;
        // A server from before the switch sends no field: off.
        _hubUpsideDown = settings?.cameraHubUpsideDown ?? false;
        final mode = settings?.cameraOrderingMode ?? '';
        // A server from before the mode field only reports the flag.
        _orderingMode = mode.isNotEmpty
            ? mode
            : ((settings?.cameraOrderingAutomatic ?? false)
                ? 'automatic'
                : 'manual');
        _defaultSection ??= defaultSection(_tiles());
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message =
          _loadError = 'Could not load calibration: ${operatorMessage(e)}');
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
      ColumnState.touch();
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
      setState(() {
        _message = response.success ? null : 'Save failed: ${response.message}';
        // The proposal is kept now: the hub switch is free again.
        if (response.success) _proposalUnsaved = false;
      });
      ColumnState.touch();
      if (response.success && mounted) {
        // With the column profile the positions are a session change until they are
        // saved on the Column page (spec 2026-10-10 section 4.5).
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ColumnState.available
                ? 'Camera positions set — save them on the Column page to keep them after a restart.'
                : 'Camera positions saved.')));
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

  /// Face-region sharpness of a JPEG: decodes the photo and measures the
  /// Laplacian variance over its centre crop (see [faceSharpnessFromRgba]).
  /// Higher = sharper. Runs in Dart; no server or extra package needed.
  Future<double> _faceSharpness(Uint8List jpeg) async {
    final codec = await ui.instantiateImageCodec(jpeg);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width, h = image.height;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) return 0;
    return faceSharpnessFromRgba(data.buffer.asUint8List(), w, h);
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
    // The live person check's head turn costs each capture a few seconds and
    // tells the sweep nothing: when it is on, it is off while the sweep runs
    // and back on afterwards (the master switch is sent as it is). Stored off,
    // the sweep sends nothing. head_turn_check is proto3 optional (unset keeps
    // the stored value), so both requests carry it explicitly. Null = nothing
    // to restore.
    LivenessChecksRequest? headTurnToRestore;
    try {
      try {
        final s = await SettingsState.client.loadSettings(Empty());
        if (s.focusColor.isNotEmpty) origFocusColor = s.focusColor;
        if (s.focusIntensity > 0) focusIntensity = s.focusIntensity;
        if (s.livenessHeadTurnCheck) {
          headTurnToRestore = LivenessChecksRequest(
              livenessCheck: s.livenessCheck, headTurnCheck: true);
          await SettingsState.client.setLivenessChecks(LivenessChecksRequest(
              livenessCheck: s.livenessCheck, headTurnCheck: false));
        }
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
              color: sweepHex(shot / shotsToGreen), intensity: focusIntensity));
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
      if (headTurnToRestore != null) {
        try {
          await SettingsState.client.setLivenessChecks(headTurnToRestore);
        } catch (_) {/* best effort */}
      }
      // The sweep moved the focus (also when it got no photos or failed): read the
      // column profile again, only now that the short-lived focus colour is put back.
      ColumnState.touch();
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

  /// The "USB hub mounted upside down" switch under the ordering selector, enabled in
  /// every mode (spec 2026-10-15 section 2) except while a proposal is worked out or
  /// waits unsaved ([_hubLocked], with a note), with its help line, the older-server
  /// note and the column setting's "not saved" mark.
  Widget _buildHubSwitch() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
            width: 46,
            child: Switch(
                key: const ValueKey('hub-upside-down'),
                value: _hubUpsideDown,
                onChanged:
                    _settingHub || _hubLocked ? null : _setHubUpsideDown),
          ),
          const SizedBox(width: 12),
          const RowLabel('USB hub mounted upside down'),
        ]),
        const Text(hubUpsideDownHelp,
            style: TextStyle(color: T.muted, fontSize: 12.5)),
        if (_proposalUnsaved)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(hubLockedByProposal,
                style: TextStyle(color: T.muted, fontSize: 13)),
          ),
        if (_hubNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_hubNote!,
                style: const TextStyle(color: T.warn, fontSize: 13)),
          ),
        const ColumnChangedMark(['hub_upside_down']),
      ]),
    );
  }

  /// The start button, its progress and the proposal's note of a proposing mode
  /// ("By a person", "From the surroundings"); the proposal itself lands in the
  /// position boxes below.
  List<Widget> _buildProposal(_ProposalFlow flow) => [
        const SizedBox(height: 6),
        Row(children: [
          SizedBox(
            width: 320,
            child: GoButton(
                text: _proposing ? flow.busy : flow.start,
                onPressed:
                    _proposing ? null : () => _propose(_orderingMode)),
          ),
          if (_proposing) ...[
            const SizedBox(width: 14),
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 10),
            // Flexible: in a narrow window the line wraps instead of overflowing.
            Flexible(
              child: Text(flow.scanning,
                  style: const TextStyle(color: T.muted, fontSize: 13)),
            ),
          ],
        ]),
        if (_proposalNote != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _proposalSucceeded ? T.passTint : T.warnTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_proposalNote!,
                style: TextStyle(
                    color: _proposalSucceeded ? T.pass : T.warn,
                    fontSize: 13.5)),
          ),
      ];

  /// Camera order: the ordering mode, the hub switch, a proposal, the positions and
  /// "Save positions".
  Widget _buildCameraOrder() {
    final rows = _rows;
    return SectionCard(
      title: 'Camera positions',
      titleLeading: const DevInfoBadge('calibration-positions'),
      child: rows == null
          ? const Center(child: CircularProgressIndicator())
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // A Wrap: with four options the selector goes under its label
              // in a narrow window instead of overflowing.
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const RowLabel('Camera ordering'),
                  SegmentedButton<String>(
                    segments: [
                      for (final MapEntry(key: mode, value: label)
                          in orderingModeLabels.entries)
                        ButtonSegment(value: mode, label: Text(label)),
                    ],
                    selected: {_orderingMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => _setOrdering(s.first),
                  ),
                ],
              ),
              // The section's one line: what the chosen mode does.
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(orderingModeHelp(_orderingMode),
                    style: const TextStyle(color: T.muted, fontSize: 12.5)),
              ),
              const HowItWorks([
                'Assign each physical camera to its position on the column '
                    '(1 = bottom). Save after changing.',
              ]),
              _buildHubSwitch(),
              if (_proposalFlows[_orderingMode] case final flow?)
                ..._buildProposal(flow),
              const SizedBox(height: 8),
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
                      // Keyed on the value: a proposal from the calibration
                      // by a person must show in the box.
                      key: ValueKey(
                          'position-${row.linuxCameraIndex}-${row.calibratedCameraIndex}'),
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
              const ColumnChangedMark(['calibration']),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: GoButton(
                        text: 'Save positions', onPressed: _savePositions)),
              ]),
            ]),
    );
  }

  Widget _buildExpectedCameras() {
    return SectionCard(
      title: 'Expected cameras',
      titleLeading: const DevInfoBadge('expected-cameras'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'How many cameras this kiosk is built with.',
          style: TextStyle(color: T.muted, fontSize: 13),
        ),
        const HowItWorks([
          'The server checks the attached count against this and power-cycles the '
              'camera hub when cameras are missing. "Automatic" derives the count '
              'from the calibration file.',
        ]),
        const SizedBox(height: 4),
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
        const ColumnChangedMark(['expected_cameras']),
      ]),
    );
  }

  Widget _buildFocus() {
    return SectionCard(
      title: 'Focus calibration',
      titleLeading: const DevInfoBadge('calibrate-focus'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Have a person stand at the floor marking, then press Calibrate focus.',
          style: TextStyle(color: T.ink, fontSize: 13.5, height: 1.4),
        ),
        const HowItWorks([
          'Sets the fixed focus so photos are sharp at the customer\'s distance.',
          'The camera takes a photo at a range of focus settings and keeps the one '
              'where the face is sharpest — first a coarse pass in steps of 20 across '
              'the whole range, then a fine pass to pinpoint the exact value. The '
              'camera\'s focus ring runs from red to green as it homes in. It takes a '
              'minute or two; keep the person still at the marking until it finishes.',
        ]),
        const SizedBox(height: 8),
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
            Expanded(child: RowLabel(_sweepProgress ?? 'Calibrating…')),
          ] else
            RowLabel(_currentFocus >= 0
                ? 'Current focus: $_currentFocus'
                : 'Current focus: unknown'),
        ]),
        const ColumnChangedMark(['focus_absolute']),
        if (!_sweeping && _bestPhoto != null) ...[
          const SizedBox(height: 14),
          Text('Sharpest result (focus $_currentFocus):',
              style: const TextStyle(
                  color: T.ink, fontSize: 13, fontWeight: FontWeight.w600)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // The column can change under a connected server (a camera swapped, a
        // whole new rig): re-read what is attached now, and every tile with it.
        Align(
          alignment: Alignment.centerRight,
          child: QuietButton(
              text: 'Refresh cameras',
              width: 160,
              onPressed: _canRefresh ? _refreshAll : null),
        ),
        const SizedBox(height: 10),
        // The column marks ("Not saved") and the photo colours change outside this
        // state: the tiles follow the column profile and the settings snapshot.
        ListenableBuilder(
          listenable:
              Listenable.merge([ColumnState.revision, SettingsState.revision]),
          builder: (context, _) => CalibrationTiles(
              tiles: _tiles(), selected: selected, onSelect: _select),
        ),
        const SizedBox(height: 14),
        // Every section stays mounted, the others hidden: work running in one (a photo
        // colour Measure waiting for its photos, its dialog) must survive a look at
        // another tile, and each section keeps its own "How it works" fold. Visibility
        // with maintainState = Offstage (the page is as tall as the shown section only,
        // unlike an IndexedStack) + TickerMode off + ExcludeFocus: Tab never walks into
        // a hidden section, so Enter or Space cannot start a sweep or a capture the
        // operator cannot see.
        for (final section in CalibrationSection.values)
          Visibility(
            visible: section == selected,
            maintainState: true,
            child: switch (section) {
              CalibrationSection.cameraOrder => _buildCameraOrder(),
              CalibrationSection.expectedCameras => _buildExpectedCameras(),
              CalibrationSection.focus => _buildFocus(),
              // A measurement saved while another tile is shown: back to this one, so
              // its "Saving…" line and any save error are seen.
              CalibrationSection.photoColour => PhotoColourCard(
                  onMeasured: () => _select(CalibrationSection.photoColour)),
            },
          ),
        ErrorLine(_message),
      ]),
    );
  }
}
