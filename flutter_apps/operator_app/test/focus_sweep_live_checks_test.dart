// The Calibration page's focus sweep and the live person check's head turn
// (spec 2026-10-08 section 2.1): the head turn would run in every one of the
// sweep's automatic captures, so the sweep switches it off and restores the
// saved value afterwards; the master switch is left as it is. With the head
// turn stored off the sweep sends no SetLivenessChecks at all. head_turn_check
// is proto3 optional: both requests must carry it as a PRESENT value, because
// an unset field keeps the stored one. Against in-process fake Calibration, Camera,
// Settings and Kiosk servers; the fake Kiosk sends no photo, so the sweep stops
// after its coarse pass and restores.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, ServiceCall;
import 'package:operator_app/pages/calibration_page.dart';
import 'package:operator_app/services/settings_state.dart';

import 'fake_server.dart';

const _noPhotos = 'The sweep got no photos. Is someone standing at the marking?';

class _FakeCalibration extends CalibrationServiceBase {
  @override
  Future<CalibrationSettingsResponse> getCalibration(
          ServiceCall call, Empty request) async =>
      CalibrationSettingsResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _FakeCamera extends CameraServiceBase {
  @override
  Future<LoadCameraSettingsResponse> loadSettings(
          ServiceCall call, Empty request) async =>
      LoadCameraSettingsResponse(focusAbsolute: 67);

  @override
  Future<AutofocusResponse> setAutofocus(
          ServiceCall call, AutofocusRequest request) async =>
      AutofocusResponse();

  @override
  Future<FocusAbsoluteResponse> setFocusAbsolute(
          ServiceCall call, FocusAbsoluteRequest request) async =>
      FocusAbsoluteResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings(this.stored);

  final LoadSettingsResponse stored;
  final List<LivenessChecksRequest> livenessCalls = [];

  @override
  Future<LoadSettingsResponse> loadSettings(
          ServiceCall call, Empty request) async =>
      stored;

  @override
  Future<LivenessChecksResponse> setLivenessChecks(
      ServiceCall call, LivenessChecksRequest request) async {
    livenessCalls.add(request);
    return LivenessChecksResponse(
        livenessCheck: request.livenessCheck,
        headTurnCheck: request.headTurnCheck);
  }

  @override
  Future<FocusLightResponse> setFocusLight(
          ServiceCall call, FocusLightRequest request) async =>
      FocusLightResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// An automatic capture that ends without a photo.
class _FakeKiosk extends KioskServiceBase {
  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
      ServiceCall call, Empty request) async* {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// Shows the Calibration page against [stored] settings, runs the focus sweep
/// to its end and answers the SetLivenessChecks calls it made.
Future<List<LivenessChecksRequest>> _sweep(
    WidgetTester tester, LoadSettingsResponse stored) async {
  tester.view.physicalSize = const Size(1900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = _FakeSettings(stored);
  final server = await serveFakes([_FakeCalibration(), _FakeCamera(), settings, _FakeKiosk()]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  addTearDown(() => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()));
  SettingsState.current = LoadSettingsResponse(cameraOrderingMode: 'manual');

  await tester
      .pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
  // The overview (design 2026-10-16): open the Focus tile first.
  await tester.tap(find.byKey(const ValueKey('calibration-tile-focus')));
  await tester.pump();
  await tester.ensureVisible(find.text('Calibrate focus'));
  await tester.pump();
  await tester.tap(find.text('Calibrate focus'));
  // Until the sweep has ended (its button is back), so every call it made has
  // finished before the teardown shuts the channel and the server down.
  for (var i = 0;
      i < 50 &&
          (find.text('Calibrate focus').evaluate().isEmpty ||
              find.text(_noPhotos).evaluate().isEmpty);
      i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
  expect(find.text(_noPhotos), findsOneWidget, reason: 'the sweep ran to its end');
  return settings.livenessCalls;
}

void main() {
  testWidgets('a stored head turn is switched off for the sweep and restored',
      (tester) async {
    await tester.runAsync(() async {
      final calls = await _sweep(
          tester,
          LoadSettingsResponse(
              livenessCheck: true, livenessHeadTurnCheck: true));

      expect(calls, hasLength(2), reason: 'one off request, one restore');
      final off = calls.first;
      expect(off.hasHeadTurnCheck(), isTrue,
          reason: 'unset would keep the stored head turn on');
      expect((off.livenessCheck, off.headTurnCheck), (true, false));
      final restore = calls.last;
      expect(restore.hasHeadTurnCheck(), isTrue);
      expect((restore.livenessCheck, restore.headTurnCheck), (true, true));
    });
  });

  testWidgets('a stored head turn OFF: the sweep leaves the live checks alone',
      (tester) async {
    await tester.runAsync(() async {
      final calls = await _sweep(
          tester,
          LoadSettingsResponse(
              livenessCheck: true, livenessHeadTurnCheck: false));

      expect(calls, isEmpty,
          reason: 'nothing to switch off, so nothing to restore');
    });
  });
}
