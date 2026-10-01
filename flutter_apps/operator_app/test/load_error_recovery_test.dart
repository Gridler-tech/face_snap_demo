// A page whose first load failed (server not answering yet — e.g. while a
// camera column is still coming up) must drop that error line once a later
// load succeeds. It used to stay, so a correctly loaded page still said
// "kiosk not reachable — is the server running?". The pages talk to an
// in-process fake server that refuses the first load and answers after that.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, Service, ServiceCall;
import 'package:operator_app/pages/calibration_page.dart';
import 'package:operator_app/pages/camera_page.dart';
import 'package:operator_app/services/settings_state.dart';

/// Fails the first [failures] calls of each load with UNAVAILABLE, the code a
/// server that is not answering produces.
class _FlakyCamera extends CameraServiceBase {
  _FlakyCamera(this.failures);
  int failures;

  @override
  Future<LoadCameraSettingsResponse> loadSettings(
      ServiceCall call, Empty request) async {
    if (failures-- > 0) throw GrpcError.unavailable('not answering yet');
    return LoadCameraSettingsResponse(brightness: 20);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _FlakyCalibration extends CalibrationServiceBase {
  _FlakyCalibration(this.failures);
  int failures;

  @override
  Future<CalibrationSettingsResponse> getCalibration(
      ServiceCall call, Empty request) async {
    if (failures-- > 0) throw GrpcError.unavailable('not answering yet');
    return CalibrationSettingsResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

const _notReachable = 'kiosk not reachable — is the server running?';

Future<void> _serve(WidgetTester tester, List<Service> services) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final server = Server.create(services: services);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  SettingsState.current = LoadSettingsResponse();
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
}

/// Pumps until [finder] matches (true) or gives up after ~3 s (false).
Future<bool> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// The settings snapshot was refreshed (what reconnecting to the server
/// does): pages whose load failed retry it.
Future<void> _serverAnswersAgain(WidgetTester tester) async {
  SettingsState.revision.value++;
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  testWidgets('Camera page: the load error goes once the settings load',
      (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, [_FlakyCamera(1)]);
      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: CameraPage())));
      expect(await _waitFor(tester, find.textContaining(_notReachable)), isTrue,
          reason: 'the first load is refused');

      await _serverAnswersAgain(tester);

      expect(find.text('Brightness 20'), findsOneWidget,
          reason: 'the retry loaded the settings');
      expect(find.textContaining('Could not load camera settings'), findsNothing);
    });
  });

  testWidgets('Calibration page: the load error goes once the rows load',
      (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, [_FlakyCalibration(1), _FlakyCamera(0)]);
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: CalibrationPage())));
      expect(await _waitFor(tester, find.textContaining(_notReachable)), isTrue,
          reason: 'the first load is refused');

      await _serverAnswersAgain(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'the retry loaded the rows');
      expect(find.textContaining('Could not load calibration'), findsNothing);
    });
  });
}
