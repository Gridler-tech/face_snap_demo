// The Calibration page's four ordering options (manual / automatic from the USB
// sockets / by a person / from the surroundings), the two proposal flows (by a
// person, from the surroundings: the start button, the proposal that fills the
// position boxes, a refused calibration, the call's deadline) and the "USB hub
// mounted upside down" switch under the selector (spec 2026-10-15 sections 2 and
// 7), and older servers that know none of it. Against in-process fake
// Calibration, Camera and Settings servers over a real loopback connection.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, ServiceCall;
import 'package:operator_app/pages/calibration_page.dart';
import 'package:operator_app/services/settings_state.dart';

import 'fake_server.dart';

class _FakeCalibration extends CalibrationServiceBase {
  _FakeCalibration(this.person, this.surroundings);

  /// What CalibrateByPerson answers; null = an older server without the call.
  final PersonCalibrationResponse? person;

  /// What CalibrateBySurroundings answers; null = a server from before 1.1.25.
  final SurroundingsCalibrationResponse? surroundings;
  int personCalls = 0;
  int surroundingsCalls = 0;
  int loads = 0;

  /// The deadline each proposal call carried, as time left when it arrived.
  final Map<String, Duration?> deadlines = {};
  final List<List<int>> saved = [];

  @override
  Future<CalibrationSettingsResponse> getCalibration(
      ServiceCall call, Empty request) async {
    loads++;
    return CalibrationSettingsResponse(calibrate: [
      // An unknown wiring that was never calibrated: every position unset.
      CalibrateType(idModelId: '0282', linuxCameraIndex: 2),
      CalibrateType(idModelId: '0288', linuxCameraIndex: 3),
      CalibrateType(idModelId: '0283', linuxCameraIndex: 4),
    ]);
  }

  @override
  Future<CalibrateResponse> setCalibration(
      ServiceCall call, CalibrateRequest request) async {
    saved.add([for (final c in request.calibrate) c.calibratedCameraIndex]);
    return CalibrateResponse(success: true);
  }

  Duration? _left(ServiceCall call) =>
      call.deadline?.difference(DateTime.now());

  @override
  Future<PersonCalibrationResponse> calibrateByPerson(
      ServiceCall call, Empty request) async {
    personCalls++;
    deadlines['person'] = _left(call);
    final answer = person;
    if (answer == null) throw GrpcError.unimplemented('CalibrateByPerson');
    return answer;
  }

  @override
  Future<SurroundingsCalibrationResponse> calibrateBySurroundings(
      ServiceCall call, Empty request) async {
    surroundingsCalls++;
    deadlines['surroundings'] = _left(call);
    final answer = surroundings;
    if (answer == null) {
      throw GrpcError.unimplemented('CalibrateBySurroundings');
    }
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
  _FakeSettings(
      {required this.knowsModes,
      required this.knowsHub,
      this.hubApplied,
      this.setsInstead});

  /// false = a server from before the mode field: it only echoes the flag.
  final bool knowsModes;

  /// false = a server from before 1.1.25 (1.1.15-1.1.24, images 2.0.14-2.0.23):
  /// SetCameraHubUpsideDown is UNIMPLEMENTED, and the unknown "surroundings" mode is
  /// refused with INVALID_ARGUMENT, as those servers do.
  final bool knowsHub;

  /// A server that sets this mode whatever is asked and echoes it; null = none.
  final String? setsInstead;

  /// The value the server applies whatever is asked; null = what is asked.
  final bool? hubApplied;
  final List<String> modeCalls = [];
  final List<bool> hubCalls = [];

  @override
  Future<CameraOrderingModeResponse> setCameraOrderingMode(
      ServiceCall call, CameraOrderingModeRequest request) async {
    modeCalls.add(request.mode);
    if (!knowsModes) {
      return CameraOrderingModeResponse(automatic: request.automatic);
    }
    if (request.mode == 'surroundings' && !knowsHub) {
      throw GrpcError.invalidArgument(
          'camera ordering mode should be one of manual, automatic, person');
    }
    final set = setsInstead ?? request.mode;
    return CameraOrderingModeResponse(
        automatic: set == 'automatic', mode: set);
  }

  @override
  Future<CameraHubUpsideDownResponse> setCameraHubUpsideDown(
      ServiceCall call, CameraHubUpsideDownRequest request) async {
    hubCalls.add(request.upsideDown);
    if (!knowsHub) throw GrpcError.unimplemented('SetCameraHubUpsideDown');
    return CameraHubUpsideDownResponse(
        upsideDown: hubApplied ?? request.upsideDown);
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
    SurroundingsCalibrationResponse? surroundings,
    bool knowsModes = true,
    bool knowsHub = true,
    bool? hubApplied,
    String? setsInstead,
    bool hubUpsideDown = false,
    String mode = 'manual'}) async {
  tester.view.physicalSize = const Size(1900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final calibration = _FakeCalibration(person, surroundings);
  final settings = _FakeSettings(
      knowsModes: knowsModes,
      knowsHub: knowsHub,
      hubApplied: hubApplied,
      setsInstead: setsInstead);
  final server =
      await serveFakes([calibration, _FakeCamera(), settings]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  addTearDown(() => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()));

  SettingsState.current = LoadSettingsResponse(
      cameraOrderingAutomatic: mode == 'automatic',
      cameraOrderingMode: knowsModes ? mode : '',
      cameraHubUpsideDown: hubUpsideDown);
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

final _hubSwitch = find.byKey(const ValueKey('hub-upside-down'));

Switch _hub(WidgetTester tester) => tester.widget<Switch>(_hubSwitch);

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

final _surroundingsProposal = SurroundingsCalibrationResponse(
  success: true,
  message: 'Positions worked out from 2 rounds. Check them and save.',
  rounds: 2,
  cameras: [
    SurroundingsCalibrationCamera(
        idModelId: '0282', linuxCameraIndex: 2, proposedPosition: 2, offset: 1.5),
    SurroundingsCalibrationCamera(
        idModelId: '0288', linuxCameraIndex: 3, proposedPosition: 1, offset: -40.2),
    SurroundingsCalibrationCamera(
        idModelId: '0283', linuxCameraIndex: 4, proposedPosition: 3, offset: 38.7),
  ],
);

const _surroundingsHelp =
    'The server works out the positions from what the cameras see, with nobody '
    'in front of the column. It needs a scene with detail (it fails on a plain '
    'backdrop); check the result and save.';

const _hubHelp =
    'Mirrors the automatic order for a column whose USB hub is mounted upside down.';

void main() {
  test('each ordering mode explains itself', () {
    expect(orderingModeHelp('manual'), contains('saved below'));
    expect(orderingModeHelp('automatic'), contains('USB sockets'));
    expect(orderingModeHelp('person'), contains('hold still'));
    expect(orderingModeHelp('surroundings'), _surroundingsHelp);
    expect(hubUpsideDownHelp, _hubHelp);
  });

  test('the older-server text names both servers, from one constant', () {
    expect(needsNewerServer,
        'needs FaceSnap server 1.1.25 or newer (Server 2.0: the matching image)');
    expect(hubLockedByProposal,
        'Save the proposed positions before changing this switch.');
  });

  testWidgets('four options; each start button only shows for its own mode',
      (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester, person: _proposal);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Automatic (USB sockets)'), findsOneWidget);
      expect(find.text('By a person'), findsOneWidget);
      expect(find.text('From the surroundings'), findsOneWidget);
      expect(_mode(tester), 'manual');
      expect(find.text('Start calibration by a person'), findsNothing);
      expect(find.text('Start calibration from the surroundings'), findsNothing);

      await _pick(tester, 'By a person');
      expect(rig.settings.modeCalls, ['person']);
      expect(_mode(tester), 'person');
      expect(SettingsState.current!.cameraOrderingMode, 'person');
      expect(find.text('Start calibration by a person'), findsOneWidget);
      expect(find.text('Start calibration from the surroundings'), findsNothing);

      await _pick(tester, 'From the surroundings');
      expect(rig.settings.modeCalls, ['person', 'surroundings']);
      expect(_mode(tester), 'surroundings');
      expect(SettingsState.current!.cameraOrderingMode, 'surroundings');
      expect(find.text(_surroundingsHelp), findsOneWidget);
      expect(find.text('Start calibration from the surroundings'), findsOneWidget);
      expect(find.text('Start calibration by a person'), findsNothing);

      await _pick(tester, 'Automatic (USB sockets)');
      expect(rig.settings.modeCalls, ['person', 'surroundings', 'automatic']);
      expect(SettingsState.current!.cameraOrderingAutomatic, isTrue);
      expect(find.text('Start calibration by a person'), findsNothing);
      expect(find.text('Start calibration from the surroundings'), findsNothing);
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

  // ---- From the surroundings (spec 2026-10-15 section 7) ----

  testWidgets('from the surroundings: the proposal fills the positions like the '
      'person flow and saves only when asked', (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester,
          surroundings: _surroundingsProposal, mode: 'surroundings');
      expect(_mode(tester), 'surroundings');
      expect(_positions(tester), [0, 0, 0]);

      await _pick(tester, 'Start calibration from the surroundings');

      expect(rig.calibration.surroundingsCalls, 1);
      expect(rig.calibration.personCalls, 0);
      expect(_positions(tester), [2, 1, 3]);
      expect(find.textContaining('Positions proposed from what the cameras see'),
          findsOneWidget);
      expect(rig.calibration.saved, isEmpty, reason: 'a proposal is not saved');

      await _pick(tester, 'Save positions');
      expect(rig.calibration.saved, [
        [2, 1, 3]
      ]);
    });
  });

  testWidgets('from the surroundings: a failure shows the server\'s message and '
      'leaves the positions alone', (tester) async {
    await tester.runAsync(() async {
      const text = 'The cameras see too little detail to compare (a plain '
          "backdrop?). Use 'By a person' instead.";
      final rig = await _pump(tester,
          surroundings: SurroundingsCalibrationResponse(
              success: false, message: text, rounds: 2),
          mode: 'surroundings');

      await _pick(tester, 'Start calibration from the surroundings');

      expect(rig.calibration.surroundingsCalls, 1);
      expect(find.text(text), findsOneWidget);
      expect(_positions(tester), [0, 0, 0]);
    });
  });

  testWidgets('both proposal calls carry a deadline of at least 170 s (a '
      'six-camera surroundings run takes up to ~22 s)', (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester,
          person: _proposal,
          surroundings: _surroundingsProposal,
          mode: 'person');
      await _pick(tester, 'Start calibration by a person');
      await _pick(tester, 'From the surroundings');
      await _pick(tester, 'Start calibration from the surroundings');

      final person = rig.calibration.deadlines['person'];
      final surroundings = rig.calibration.deadlines['surroundings'];
      expect(person, isNotNull);
      expect(surroundings, isNotNull);
      expect(surroundings!.inSeconds, greaterThanOrEqualTo(170));
      expect(surroundings.inSeconds,
          greaterThanOrEqualTo(person!.inSeconds - 2),
          reason: 'at least as long as the person calibration\'s');
    });
  });

  testWidgets('a server from before 1.1.25 refuses "From the surroundings" '
      '(INVALID_ARGUMENT): back to the mode before, naming the version',
      (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester, knowsHub: false);

      await _pick(tester, 'From the surroundings');

      expect(rig.settings.modeCalls, ['surroundings']);
      expect(_mode(tester), 'manual');
      expect(
          find.text('This server cannot work out the order from the '
              'surroundings yet (needs FaceSnap server 1.1.25 or newer '
              '(Server 2.0: the matching image)); the saved positions are used.'),
          findsOneWidget);
      expect(find.textContaining('Could not change the ordering mode'),
          findsNothing);
      expect(find.text('Start calibration from the surroundings'), findsNothing);
    });
  });

  testWidgets('a server that sets another mode than "surroundings" names the '
      'version too', (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester, setsInstead: 'manual');

      await _pick(tester, 'From the surroundings');

      expect(rig.settings.modeCalls, ['surroundings']);
      expect(_mode(tester), 'manual');
      expect(find.textContaining(needsNewerServer), findsOneWidget);
    });
  });

  // ---- The USB hub switch (spec 2026-10-15 section 2) ----

  testWidgets('the hub switch sits directly under the selector with its help '
      'line, in every ordering mode', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, mode: 'automatic');
      expect(find.text('USB hub mounted upside down'), findsOneWidget);
      expect(find.text(_hubHelp), findsOneWidget);
      expect(_hub(tester).value, isFalse, reason: 'off by default');
      expect(_hub(tester).onChanged, isNotNull);

      final selector = tester.getBottomLeft(find.byType(SegmentedButton<String>));
      final hub = tester.getTopLeft(_hubSwitch);
      final firstRow = tester.getTopLeft(find.text('Camera 0282'));
      expect(hub.dy, greaterThan(selector.dy), reason: 'under the selector');
      expect(hub.dy, lessThan(firstRow.dy), reason: 'above the camera rows');

      for (final mode in ['Manual', 'By a person', 'From the surroundings']) {
        await _pick(tester, mode);
        expect(_hub(tester).onChanged, isNotNull, reason: mode);
      }
    });
  });

  testWidgets('the hub switch shows the stored value', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, hubUpsideDown: true);
      expect(_hub(tester).value, isTrue);
    });
  });

  testWidgets('turning the hub switch on sends the setter, keeps the applied '
      'value and reads the camera rows again', (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester, mode: 'automatic');
      final loads = rig.calibration.loads;

      await tester.tap(_hubSwitch);
      await _settle(tester);

      expect(rig.settings.hubCalls, [true]);
      expect(_hub(tester).value, isTrue);
      expect(SettingsState.current!.cameraHubUpsideDown, isTrue);
      expect(rig.calibration.loads, greaterThan(loads),
          reason: 'the camera rows refresh after a change');

      await tester.tap(_hubSwitch);
      await _settle(tester);
      expect(rig.settings.hubCalls, [true, false]);
      expect(_hub(tester).value, isFalse);
    });
  });

  testWidgets('the hub switch shows what the server applied, not what was '
      'asked', (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester, hubApplied: false);

      await tester.tap(_hubSwitch);
      await _settle(tester);

      expect(rig.settings.hubCalls, [true]);
      expect(_hub(tester).value, isFalse);
      expect(SettingsState.current!.cameraHubUpsideDown, isFalse);
    });
  });

  testWidgets('a server from before 1.1.25: the hub switch names the version '
      'and stays off', (tester) async {
    await tester.runAsync(() async {
      final rig = await _pump(tester, knowsHub: false);

      await tester.tap(_hubSwitch);
      await _settle(tester);

      expect(rig.settings.hubCalls, [true]);
      expect(_hub(tester).value, isFalse);
      expect(find.text('The USB hub switch $needsNewerServer.'), findsOneWidget);
      expect(SettingsState.current!.cameraHubUpsideDown, isFalse);
    });
  });

  // ---- A proposal on the page locks the hub switch (final review M1) ----
  // Flipping the switch re-reads the camera rows, which would silently replace an
  // unsaved proposal; the switch waits until the proposal is saved or dropped.

  for (final (mode, start) in [
    ('person', 'Start calibration by a person'),
    ('surroundings', 'Start calibration from the surroundings'),
  ]) {
    testWidgets('$mode: while its proposal is unsaved the hub switch is '
        'disabled with a note; saving frees it', (tester) async {
      await tester.runAsync(() async {
        final rig = await _pump(tester,
            person: _proposal, surroundings: _surroundingsProposal, mode: mode);
        expect(_hub(tester).onChanged, isNotNull);
        expect(find.text(hubLockedByProposal), findsNothing);

        await _pick(tester, start);
        final proposed = _positions(tester);
        expect(proposed, isNot([0, 0, 0]));
        expect(_hub(tester).onChanged, isNull,
            reason: 'a flip would re-read the rows over the proposal');
        expect(find.text(hubLockedByProposal), findsOneWidget);

        final loads = rig.calibration.loads;
        await tester.tap(_hubSwitch);
        await _settle(tester);
        expect(rig.settings.hubCalls, isEmpty);
        expect(rig.calibration.loads, loads);
        expect(_positions(tester), proposed, reason: 'the proposal stays');

        await _pick(tester, 'Save positions');
        expect(rig.calibration.saved, [proposed]);
        expect(_hub(tester).onChanged, isNotNull);
        expect(find.text(hubLockedByProposal), findsNothing);
      });
    });
  }

  testWidgets('picking another ordering mode drops the proposal and frees the '
      'hub switch', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, surroundings: _surroundingsProposal, mode: 'surroundings');
      await _pick(tester, 'Start calibration from the surroundings');
      expect(_hub(tester).onChanged, isNull);

      await _pick(tester, 'Automatic (USB sockets)');
      expect(_hub(tester).onChanged, isNotNull);
      expect(find.text(hubLockedByProposal), findsNothing);
    });
  });

  testWidgets('a refused proposal does not lock the hub switch', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester,
          surroundings: SurroundingsCalibrationResponse(
              success: false, message: 'too little detail', rounds: 2),
          mode: 'surroundings');
      await _pick(tester, 'Start calibration from the surroundings');
      expect(find.text('too little detail'), findsOneWidget);
      expect(_hub(tester).onChanged, isNotNull);
    });
  });
}
