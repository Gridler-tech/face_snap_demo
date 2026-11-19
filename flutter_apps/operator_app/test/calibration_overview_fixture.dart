// A golden-free fixture for the Calibration page's overview (design 2026-10-16): the
// page against in-process fake Calibration, Camera, Settings and Kiosk servers over a
// real loopback connection, in one of four scenarios, so every tile state can be pumped
// and looked at without a kiosk. Used by calibration_overview_test.dart.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/calibration_page.dart';
import 'package:operator_app/services/column_state.dart';
import 'package:operator_app/services/settings_state.dart';

import 'fake_server.dart';

/// What the fake kiosk holds.
class OverviewData {
  const OverviewData({
    required this.positions,
    this.mode = 'manual',
    this.expected = 0,
    this.focus = 62,
    this.columnProfile = true,
    this.ownLights = const {},
    this.changed = const {},
    this.settingsDelay = Duration.zero,
  });

  /// The calibrated position of each listed camera (0 = unset).
  final List<int> positions;
  final String mode;

  /// 0 = automatic.
  final int expected;

  /// The focus in force (both servers answer 40 when none is stored).
  final int focus;

  /// false = a server from before the column profile (GetColumnProfile UNIMPLEMENTED).
  final bool columnProfile;

  /// The lights with this kiosk's own colour matrix; the others are shipped.
  final Set<String> ownLights;

  /// The column settings the column profile reports as changed.
  final Set<String> changed;

  /// How long LoadSettings takes to answer (a slow or dying kiosk).
  final Duration settingsDelay;
}

/// The four scenarios: one per tile status family.
enum OverviewScenario {
  /// Every tile done: Done, Done, Set (Focus is never judged), Own colours.
  allDone(OverviewData(
      positions: [1, 2, 3, 4, 5],
      mode: 'automatic',
      expected: 5,
      ownLights: {'all', 'neighbours', 'glare_free'})),

  /// Two cameras without a position, the focus never calibrated (the servers' default
  /// 40): To do, Done, Set, Shipped.
  toDo(OverviewData(positions: [1, 0, 3, 0, 5], focus: 40)),

  /// Six cameras expected, five found: Done, Check, Set, Shipped (one own light).
  check(OverviewData(positions: [1, 2, 3, 4, 5], expected: 6, ownLights: {'all'})),

  /// The focus and the colours changed and not saved on the column: Done, Done,
  /// Not saved, Not saved.
  notSaved(OverviewData(
      positions: [1, 2, 3, 4, 5],
      mode: 'person',
      changed: {'focus_absolute', 'colour_correction'}));

  const OverviewScenario(this.data);
  final OverviewData data;
}

class OverviewCalibration extends CalibrationServiceBase {
  OverviewCalibration(this.data);
  final OverviewData data;
  int loads = 0;

  @override
  Future<CalibrationSettingsResponse> getCalibration(
      ServiceCall call, Empty request) async {
    loads++;
    return CalibrationSettingsResponse(calibrate: [
      for (var i = 0; i < data.positions.length; i++)
        CalibrateType(
            idModelId: '02${80 + i}',
            linuxCameraIndex: i,
            calibratedCameraIndex: data.positions[i]),
    ]);
  }

  final List<List<int>> saved = [];

  @override
  Future<CalibrateResponse> setCalibration(
      ServiceCall call, CalibrateRequest request) async {
    saved.add([for (final c in request.calibrate) c.calibratedCameraIndex]);
    return CalibrateResponse(success: true);
  }

  /// Proposes the listed cameras in reverse order.
  @override
  Future<PersonCalibrationResponse> calibrateByPerson(
          ServiceCall call, Empty request) async =>
      PersonCalibrationResponse(success: true, rounds: 3, cameras: [
        for (var i = 0; i < data.positions.length; i++)
          PersonCalibrationCamera(
              linuxCameraIndex: i,
              proposedPosition: data.positions.length - i,
              roundsSeen: 3),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class OverviewCamera extends CameraServiceBase {
  OverviewCamera(this.data) : focus = data.focus;
  final OverviewData data;
  int focus;

  @override
  Future<LoadCameraSettingsResponse> loadSettings(
          ServiceCall call, Empty request) async =>
      LoadCameraSettingsResponse(focusAbsolute: focus);

  @override
  Future<AutofocusResponse> setAutofocus(
          ServiceCall call, AutofocusRequest request) async =>
      AutofocusResponse();

  @override
  Future<FocusAbsoluteResponse> setFocusAbsolute(
      ServiceCall call, FocusAbsoluteRequest request) async {
    focus = request.value;
    return FocusAbsoluteResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class OverviewSettings extends SettingsServiceBase {
  OverviewSettings(this.data) : changed = {...data.changed};
  final OverviewData data;
  final Set<String> changed;
  int loads = 0;

  @override
  Future<LoadSettingsResponse> loadSettings(ServiceCall call, Empty request) async {
    loads++;
    await Future<void>.delayed(data.settingsDelay);
    return overviewSettings(data);
  }

  @override
  Future<ColumnProfileResponse> getColumnProfile(
      ServiceCall call, Empty request) async {
    if (!data.columnProfile) throw GrpcError.unimplemented('GetColumnProfile');
    return ColumnProfileResponse(boardId: 'e6614c311b4a6f2a', settings: [
      for (final name in const [
        'calibration',
        'hub_upside_down',
        'expected_cameras',
        'focus_absolute',
        'colour_correction',
      ])
        ColumnSetting(
            name: name,
            // What an adopted column's standard holds: every setting in force at the
            // adoption, the focus the servers' default 40 (the Focus tile must not
            // read it as "calibrated").
            standardValue: name == 'focus_absolute' ? '40' : '',
            changed: changed.contains(name)),
    ]);
  }

  @override
  Future<ExpectedCamerasResponse> setExpectedCameras(
      ServiceCall call, ExpectedCamerasRequest request) async {
    changed.add('expected_cameras');
    return ExpectedCamerasResponse(message: request.value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// The captures: a manual capture (the Photo colour card's Measure) waits for
/// [releaseManual], then sends six photos; each automatic capture (the focus sweep)
/// takes [automaticDelay] and sends one photo.
class OverviewKiosk extends KioskServiceBase {
  OverviewKiosk(this.photo);
  final List<int> photo;
  final _manualGate = Completer<void>();
  Duration automaticDelay = const Duration(milliseconds: 150);
  int manualCaptures = 0;

  void releaseManual() {
    if (!_manualGate.isCompleted) _manualGate.complete();
  }

  @override
  Stream<ProcessManualResponse> startManualCapture(
      ServiceCall call, CaptureRequest request) async* {
    manualCaptures++;
    yield ProcessManualResponse(
        settingsUsed: CaptureSettingsUsed(
            values: request.settings.deepCopy(), overridden: ['colour_correction']));
    await _manualGate.future;
    for (var i = 1; i <= 6; i++) {
      yield ProcessManualResponse(
          processStatus: ProcessStepStatus(
              index: i, description: 'Taking a high res photo', status: StatusType.OK));
      yield ProcessManualResponse(
          imageData: ProcessImageData(
              index: i, width: 64, height: 64, format: 'png', chunkData: photo));
    }
  }

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
      ServiceCall call, Empty request) async* {
    await Future<void>.delayed(automaticDelay);
    yield ProcessAutomaticResponse(
        imageData: ProcessImageData(width: 64, height: 64, format: 'png', chunkData: photo));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// A small grey PNG both the sweep and the measure dialog can decode.
Future<List<int>> overviewPng() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 64, 64), Paint()..color = const Color(0xFF808080));
  final image = await recorder.endRecording().toImage(64, 64);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// The LoadSettings snapshot of [data].
LoadSettingsResponse overviewSettings(OverviewData data) => LoadSettingsResponse(
      cameraOrderingMode: data.mode,
      cameraOrderingAutomatic: data.mode == 'automatic',
      expectedCameras: data.expected,
      colourCorrections: [
        for (final light in const ['all', 'neighbours', 'glare_free'])
          ColourCorrectionState(
              light: light,
              matrix: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
              source: data.ownLights.contains(light) ? 'kiosk' : 'shipped'),
      ],
    );

class OverviewRig {
  OverviewRig(this.server, this.calibration, this.camera, this.settings, this.kiosk);
  final Server server;
  final OverviewCalibration calibration;
  final OverviewCamera camera;
  final OverviewSettings settings;
  final OverviewKiosk kiosk;
}

/// Serves fakes holding [data] at a free loopback port (shut down in the tear-down).
Future<OverviewRig> serveOverview(WidgetTester tester, OverviewData data) async {
  final calibration = OverviewCalibration(data);
  final camera = OverviewCamera(data);
  final settings = OverviewSettings(data);
  final kiosk = OverviewKiosk(await overviewPng());
  final server = await serveFakes([calibration, camera, settings, kiosk]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  return OverviewRig(server, calibration, camera, settings, kiosk);
}

/// Points the app at [rig]'s server with [data]'s settings snapshot and column profile
/// (what connecting to a kiosk does), without telling the pages.
Future<void> connectOverview(OverviewRig rig, OverviewData data) async {
  await GrpcChannelProvider.setAddress('127.0.0.1', rig.server.port!);
  SettingsState.current = overviewSettings(data);
  ColumnState.reset();
  await ColumnState.refresh();
}

/// Pumps the Calibration page against fakes holding [data] (or [scenario]'s data),
/// with the column profile read, and waits for the page's load. Call inside
/// `tester.runAsync`. [forget] = start without a remembered tile choice.
Future<OverviewRig> pumpCalibrationOverview(WidgetTester tester,
    {OverviewScenario? scenario,
    OverviewData? data,
    bool forget = true,
    Size size = const Size(1600, 2000)}) async {
  final d = data ?? (scenario ?? OverviewScenario.allDone).data;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final rig = await serveOverview(tester, d);
  await connectOverview(rig, d);
  addTearDown(() => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()));
  if (forget) CalibrationPage.forgetSelection();

  await tester
      .pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
  await settleOverview(tester);
  return rig;
}

Future<void> settleOverview(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

/// Pumps until [finder] matches (true) or gives up after [seconds] (false).
Future<bool> waitForOverview(WidgetTester tester, Finder finder, {int seconds = 15}) async {
  for (var i = 0; i < seconds * 10; i++) {
    if (finder.evaluate().isNotEmpty) return true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
  return finder.evaluate().isNotEmpty;
}

/// A tile, by its section name (`CalibrationSection.name`).
Finder overviewTile(String section) =>
    find.byKey(ValueKey('calibration-tile-$section'));

/// The status pill of a tile.
Finder overviewPill(String section, String label) => find.descendant(
    of: overviewTile(section), matching: find.text(label));

/// Clicks a tile and waits.
Future<void> openOverviewTile(WidgetTester tester, String section) async {
  await tester.ensureVisible(overviewTile(section));
  await tester.pump();
  await tester.tap(overviewTile(section));
  await settleOverview(tester, rounds: 3);
}
