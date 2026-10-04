// The Calibration page's three ordering options (manual / automatic from the USB
// sockets / by a person) and the calibration by a person: the start button, the
// proposal that fills the position boxes, a refused calibration, and an older
// server that knows neither. Against in-process fake Calibration, Camera and
// Settings servers over a real loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/calibration_page.dart';
import 'package:operator_app/services/settings_state.dart';

class _FakeCalibration extends CalibrationServiceBase {
  _FakeCalibration(this.person);

  /// What CalibrateByPerson answers; null = an older server without the call.
  final PersonCalibrationResponse? person;
  int personCalls = 0;
  final List<List<int>> saved = [];

  @override
  Future<CalibrationSettingsResponse> getCalibration(
          ServiceCall call, Empty request) async =>
      CalibrationSettingsResponse(calibrate: [
        // An unknown wiring that was never calibrated: every position unset.
        CalibrateType(idModelId: '0282', linuxCameraIndex: 2),
        CalibrateType(idModelId: '0288', linuxCameraIndex: 3),
        CalibrateType(idModelId: '0283', linuxCameraIndex: 4),
      ]);

  @override
  Future<CalibrateResponse> setCalibration(
      ServiceCall call, CalibrateRequest request) async {
    saved.add([for (final c in request.calibrate) c.calibratedCameraIndex]);
    return CalibrateResponse(success: true);
  }

  @override
  Future<PersonCalibrationResponse> calibrateByPerson(
      ServiceCall call, Empty request) async {
    personCalls++;
    final answer = person;
    if (answer == null) throw GrpcError.unimplemented('CalibrateByPerson');
    return answer;
  }
}

class _FakeCamera extends CameraServiceBase {
  @override
  Future<LoadCameraSettingsResponse> loadSettings(
          ServiceCall call, Empty request) async =>
      LoadCameraSettingsResponse(focusAbsolute: 67);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({required this.knowsModes});

  /// false = a server from before the mode field: it only echoes the flag.
  final bool knowsModes;
  final List<String> modeCalls = [];

  @override
  Future<CameraOrderingModeResponse> setCameraOrderingMode(
      ServiceCall call, CameraOrderingModeRequest request) async {
    modeCalls.add(request.mode);
    return knowsModes
        ? CameraOrderingModeResponse(
            automatic: request.mode == 'automatic', mode: request.mode)
        : CameraOrderingModeResponse(automatic: request.automatic);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Rig {
  _Rig(this.calibration, this.settings);
  final _FakeCalibration calibration;
  final _FakeSettings settings;
}

Future<_Rig> _pump(WidgetTester tester,
    {PersonCalibrationResponse? person,
    bool knowsModes = true,
    String mode = 'manual'}) async {
  tester.view.physicalSize = const Size(1900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final calibration = _FakeCalibration(person);
  final settings = _FakeSettings(knowsModes: knowsModes);
  final server =
      Server.create(services: [calibration, _FakeCamera(), settings]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  addTearDown(() => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()));

  SettingsState.current = LoadSettingsResponse(
      cameraOrderingAutomatic: mode == 'automatic',
      cameraOrderingMode: knowsModes ? mode : '');
  await tester
      .pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
  await _settle(tester);
  return _Rig(calibration, settings);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

String _mode(WidgetTester tester) => tester
    .widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>))
    .selected
    .single;

/// The value shown in each camera's position box, in row order.
List<int?> _positions(WidgetTester tester) => [
      for (final box in tester.widgetList<DropdownMenu<int>>(
          find.byType(DropdownMenu<int>)))
        box.initialSelection,
    ].take(3).toList();

Future<void> _pick(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await _settle(tester);
}

final _proposal = PersonCalibrationResponse(
  success: true,
  message: 'Positions worked out from 3 rounds. Check them and save.',
  rounds: 3,
  cameras: [
    PersonCalibrationCamera(
        linuxCameraIndex: 2, proposedPosition: 1, faceHeight: 0.1, roundsSeen: 3),
    PersonCalibrationCamera(
        linuxCameraIndex: 3, proposedPosition: 3, faceHeight: 0.7, roundsSeen: 3),
    PersonCalibrationCamera(
        linuxCameraIndex: 4, proposedPosition: 2, faceHeight: 0.4, roundsSeen: 3),
  ],
);

void main() {
  test('each ordering mode explains itself', () {
    expect(orderingModeHelp('manual'), contains('saved below'));
    expect(orderingModeHelp('automatic'), contains('USB sockets'));
    expect(orderingModeHelp('person'), contains('hold still'));
  });

  testWidgets('three options; the start button only shows for "By a person"',
      (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester, person: _proposal);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Automatic (USB sockets)'), findsOneWidget);
      expect(find.text('By a person'), findsOneWidget);
      expect(_mode(tester), 'manual');
      expect(find.text('Start calibration by a person'), findsNothing);

      await _pick(tester, 'By a person');
      expect(rig.settings.modeCalls, ['person']);
      expect(_mode(tester), 'person');
      expect(SettingsState.current!.cameraOrderingMode, 'person');
      expect(find.text('Start calibration by a person'), findsOneWidget);

      await _pick(tester, 'Automatic (USB sockets)');
      expect(rig.settings.modeCalls, ['person', 'automatic']);
      expect(SettingsState.current!.cameraOrderingAutomatic, isTrue);
      expect(find.text('Start calibration by a person'), findsNothing);
    });
  });

  testWidgets('a successful calibration fills the positions as a proposal and '
      'saves only when asked', (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester, person: _proposal, mode: 'person');
      expect(_mode(tester), 'person');
      expect(_positions(tester), [0, 0, 0]);

      await _pick(tester, 'Start calibration by a person');

      expect(rig.calibration.personCalls, 1);
      expect(_positions(tester), [1, 3, 2]);
      expect(find.textContaining('Positions proposed from the person'),
          findsOneWidget);
      expect(rig.calibration.saved, isEmpty, reason: 'a proposal is not saved');

      await _pick(tester, 'Save positions');
      expect(rig.calibration.saved, [
        [1, 3, 2]
      ]);
    });
  });

  testWidgets('a refused calibration shows why and leaves the positions alone',
      (tester) async {
    await tester.runAsync(() async {
      final refused = PersonCalibrationResponse(
        success: false,
        message: 'The camera(s) with index 4 did not see the face. Stand straight '
            'in front of the column at the normal photo distance, look ahead and '
            'hold still until it is done.',
        cameras: [
          PersonCalibrationCamera(linuxCameraIndex: 2, faceHeight: 0.1),
          PersonCalibrationCamera(linuxCameraIndex: 3, faceHeight: 0.7),
          PersonCalibrationCamera(linuxCameraIndex: 4, faceHeight: -1),
        ],
      );
      final rig = await _pump(tester, person: refused, mode: 'person');

      await _pick(tester, 'Start calibration by a person');

      expect(rig.calibration.personCalls, 1);
      expect(find.textContaining('index 4 did not see the face'), findsOneWidget);
      expect(_positions(tester), [0, 0, 0]);
    });
  });

  testWidgets('an older server: choosing "By a person" falls back to manual and '
      'says why', (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester, knowsModes: false);
      expect(_mode(tester), 'manual');

      await _pick(tester, 'By a person');

      expect(rig.settings.modeCalls, ['person']);
      expect(_mode(tester), 'manual');
      expect(find.textContaining('cannot calibrate by a person yet'),
          findsOneWidget);
    });
  });
}
