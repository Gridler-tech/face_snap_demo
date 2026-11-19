// The ● marks and the "Not saved — open the Column page" links (spec 2026-10-10 section 5.5):
// shown next to a column setting that is changed and not saved, on the Lighting page (colour,
// focus light, LED hardware, glare-free white balance), the Calibration page (positions,
// expected cameras, focus, the USB hub switch) and the Camera page (focus); the link asks the shell for the
// Column page; a setting pushed from the page makes the mark appear; the strip gbl.py editor
// is not on the Lighting page any more; a server without the column profile shows no marks,
// no links and no pointer to the Column page, and keeps the strip gbl.py editor on Lighting
// (spec 5.6, final review I-3). Every push that can change a column setting
// (the focus colour, the Kelvin field, the expected cameras, the positions, the focus sweep)
// reads the profile again; the sweep reads it only after it has put its short-lived focus
// colour back. In-process fake servers over a real loopback connection.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/calibration_page.dart';
import 'package:operator_app/pages/camera_page.dart';
import 'package:operator_app/pages/lighting_page.dart';
import 'package:operator_app/services/column_state.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/ui/page_nav.dart';

const _allTen = ['led_layout', 'led_geometry', 'led_colour', 'focus_light', 'expected_cameras',
                 'calibration', 'glare_free_white_balance', 'focus_absolute', 'rotate_frames', 'hub_upside_down'];

/// A server whose column profile says which settings are changed; a pushed setting changes
/// it. [columnProfile] false: a server from before the column profile (GetColumnProfile is
/// UNIMPLEMENTED).
class _FakeSettings extends SettingsServiceBase {
  _FakeSettings(this.changed, {this.columnProfile = true});
  final Set<String> changed;
  final bool columnProfile;
  final reds = <int>[];
  final gbls = <String>[];

  @override
  Future<BoardGblResponse> getBoardGbl(ServiceCall call, BoardGblLayoutRequest request) async =>
      BoardGblResponse(layout: 'strip', content: gbls.isEmpty ? 'LED_COUNT = 184\n' : gbls.last,
          custom: gbls.isNotEmpty && gbls.last.isNotEmpty);

  @override
  Future<BoardGblResponse> setBoardGbl(ServiceCall call, BoardGblRequest request) async {
    gbls.add(request.content);
    return BoardGblResponse(layout: 'strip', content: request.content, custom: request.content.isNotEmpty,
        message: 'stored; the board is being updated (~10 s, it reboots)');
  }

  @override
  Future<ColumnProfileResponse> getColumnProfile(ServiceCall call, Empty request) async {
    if (!columnProfile) throw GrpcError.unimplemented('GetColumnProfile');
    return ColumnProfileResponse(
      boardId: 'e6614c311b4a6f2a',
      settings: [for (final name in _allTen) ColumnSetting(name: name, changed: changed.contains(name))],
    );
  }

  @override
  Future<IntensityResponse> setIntensityRed(ServiceCall call, IntensityRequest request) async {
    reds.add(request.value);
    changed.add('led_colour');
    return IntensityResponse(message: request.value);
  }

  @override
  Future<FocusLightResponse> setFocusLight(ServiceCall call, FocusLightRequest request) async {
    changed.add('focus_light');
    return FocusLightResponse(color: request.color, intensity: request.intensity);
  }

  @override
  Future<GlareFreeWhiteBalanceResponse> setGlareFreeWhiteBalance(
      ServiceCall call, GlareFreeWhiteBalanceRequest request) async {
    changed.add('glare_free_white_balance');
    return GlareFreeWhiteBalanceResponse(message: request.value);
  }

  @override
  Future<ExpectedCamerasResponse> setExpectedCameras(ServiceCall call, ExpectedCamerasRequest request) async {
    changed.add('expected_cameras');
    return ExpectedCamerasResponse(message: request.value);
  }

  @override
  Future<CameraHubUpsideDownResponse> setCameraHubUpsideDown(
      ServiceCall call, CameraHubUpsideDownRequest request) async {
    changed.add('hub_upside_down');
    return CameraHubUpsideDownResponse(upsideDown: request.upsideDown);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

class _FakeCalibration extends CalibrationServiceBase {
  _FakeCalibration(this.changed);
  final Set<String> changed;

  @override
  Future<CalibrationSettingsResponse> getCalibration(ServiceCall call, Empty request) async =>
      CalibrationSettingsResponse(calibrate: [CalibrateType(idModelId: '0242', linuxCameraIndex: 0, calibratedCameraIndex: 1)]);

  @override
  Future<CalibrateResponse> setCalibration(ServiceCall call, CalibrateRequest request) async {
    changed.add('calibration');
    return CalibrateResponse(success: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

class _FakeCamera extends CameraServiceBase {
  @override
  Future<LoadCameraSettingsResponse> loadSettings(ServiceCall call, Empty request) async =>
      LoadCameraSettingsResponse(focusAbsolute: 40);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

class _NoLights extends LightsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

Future<_FakeSettings> _serve(WidgetTester tester, Set<String> changed, {bool columnProfile = true}) async {
  tester.view.physicalSize = const Size(1600, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final settings = _FakeSettings(changed, columnProfile: columnProfile);
  final server = Server.create(services: [settings, _FakeCalibration(changed), _FakeCamera(), _NoLights()]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  SettingsState.current = LoadSettingsResponse(ledLayout: 'strip', intensityRed: 200);
  ColumnState.reset();
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  await ColumnState.refresh();
  return settings;
}

Future<void> _settle(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Finder _mark(String names) => find.byKey(ValueKey('column-changed-$names'));

/// The Calibration page's overview (design 2026-10-16): open a tile (its section) first.
Future<void> _openTile(WidgetTester tester, String section) async {
  await tester.tap(find.byKey(ValueKey('calibration-tile-$section')));
  await _settle(tester, rounds: 2);
}

const _link = 'Not saved — open the Column page';
const _pointer = 'The LED geometry (gbl.py) of the column is on the Column page.';

// ---- The focus sweep ----------------------------------------------------------------------

/// What the sweep's server holds. The column's standard is focus colour 00FF00 and focus 40.
class _SweepState {
  String focusColor = '00FF00';
  int focus = 40;
}

/// The sweep's settings: the profile says what differs from the standard. The sweep's
/// restore of the focus colour (back to 00FF00) answers 800 ms late, so a profile read
/// before the restore has finished sees the sweep's short-lived red-to-green cue.
class _SweepSettings extends SettingsServiceBase {
  _SweepSettings(this.state);
  final _SweepState state;

  @override
  Future<ColumnProfileResponse> getColumnProfile(ServiceCall call, Empty request) async => ColumnProfileResponse(
        boardId: 'e6614c311b4a6f2a',
        settings: [
          ColumnSetting(name: 'focus_light', changed: state.focusColor != '00FF00'),
          ColumnSetting(name: 'focus_absolute', changed: state.focus != 40),
        ],
      );

  @override
  Future<LoadSettingsResponse> loadSettings(ServiceCall call, Empty request) async =>
      LoadSettingsResponse(focusColor: '00FF00', focusIntensity: 100);

  @override
  Future<FocusLightResponse> setFocusLight(ServiceCall call, FocusLightRequest request) async {
    if (request.color == '00FF00') await Future<void>.delayed(const Duration(milliseconds: 800));
    state.focusColor = request.color;
    return FocusLightResponse(color: request.color, intensity: request.intensity);
  }

  @override
  Future<IntensityResponse> setIntensityRed(ServiceCall call, IntensityRequest request) async =>
      IntensityResponse(message: request.value);

  @override
  Future<IntensityResponse> setIntensityGreen(ServiceCall call, IntensityRequest request) async =>
      IntensityResponse(message: request.value);

  @override
  Future<IntensityResponse> setIntensityBlue(ServiceCall call, IntensityRequest request) async =>
      IntensityResponse(message: request.value);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

class _SweepCamera extends CameraServiceBase {
  _SweepCamera(this.state);
  final _SweepState state;

  @override
  Future<LoadCameraSettingsResponse> loadSettings(ServiceCall call, Empty request) async =>
      LoadCameraSettingsResponse(focusAbsolute: state.focus);

  @override
  Future<AutofocusResponse> setAutofocus(ServiceCall call, AutofocusRequest request) async => AutofocusResponse();

  @override
  Future<FocusAbsoluteResponse> setFocusAbsolute(ServiceCall call, FocusAbsoluteRequest request) async {
    state.focus = request.value;
    return FocusAbsoluteResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

class _SweepCalibration extends CalibrationServiceBase {
  @override
  Future<CalibrationSettingsResponse> getCalibration(ServiceCall call, Empty request) async =>
      CalibrationSettingsResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

enum _Capture { photo, none, fails }

/// Each automatic capture: a photo, no photo (the sweep stops after its coarse pass) or a
/// failed call (the sweep's catch).
class _SweepKiosk extends KioskServiceBase {
  _SweepKiosk(this.capture, this.photo);
  final _Capture capture;
  final List<int> photo;

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(ServiceCall call, Empty request) async* {
    switch (capture) {
      case _Capture.photo:
        yield ProcessAutomaticResponse(
            imageData: ProcessImageData(width: 64, height: 64, format: 'png', chunkData: photo));
      case _Capture.none:
        break;
      case _Capture.fails:
        throw GrpcError.internal('the camera did not answer');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

/// A small grey PNG the sweep can decode and score.
Future<List<int>> _png() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 64, 64), Paint()..color = const Color(0xFF808080));
  final image = await recorder.endRecording().toImage(64, 64);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Shows the Calibration page, runs the focus sweep to its end, then waits past the
/// profile's re-read.
Future<_SweepState> _sweep(WidgetTester tester, _Capture capture) async {
  tester.view.physicalSize = const Size(1900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final state = _SweepState();
  final server = Server.create(services: [
    _SweepSettings(state), _SweepCamera(state), _SweepCalibration(), _SweepKiosk(capture, await _png()), _NoLights()]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  SettingsState.current = LoadSettingsResponse(
      cameraOrderingMode: 'manual', intensityRed: 160, intensityGreen: 230, intensityBlue: 200);
  ColumnState.reset();
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  await ColumnState.refresh();

  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
  await _settle(tester);
  expect(ColumnState.anyChanged(['focus_light', 'focus_absolute']), isFalse, reason: 'nothing changed yet');
  await _openTile(tester, 'focus');
  await tester.ensureVisible(find.text('Calibrate focus'));
  await tester.pump();
  await tester.tap(find.text('Calibrate focus'));
  await tester.pump();
  for (var i = 0; i < 100 && find.text('Calibrate focus').evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
  expect(find.text('Calibrate focus'), findsOneWidget, reason: 'the sweep ran to its end');
  await _settle(tester, rounds: 12); // ColumnState.touch's 400 ms re-read
  return state;
}

void main() {
  testWidgets('the Lighting page marks its changed column settings and links to the Column page', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, {'led_colour', 'glare_free_white_balance'});
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
      await _settle(tester);
      expect(_mark('led_colour'), findsOneWidget);
      expect(_mark('glare_free_white_balance'), findsOneWidget);
      expect(_mark('focus_light'), findsNothing);
      expect(_mark('led_layout+led_geometry'), findsNothing);
      expect(find.text('Strip file (gbl.py)'), findsNothing, reason: 'the geometry editor is on the Column page');
      expect(find.text(_pointer), findsOneWidget);

      String? asked;
      void listener() => asked ??= PageNav.request.value;
      PageNav.request.addListener(listener);
      addTearDown(() => PageNav.request.removeListener(listener));
      await tester.tap(find.descendant(of: _mark('led_colour'), matching: find.text(_link)));
      await tester.pump();
      expect(asked, 'Column');
    });
  });

  testWidgets('a colour pushed from the Lighting page shows its mark', (tester) async {
    await tester.runAsync(() async {
      final settings = await _serve(tester, {});
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
      await _settle(tester);
      expect(_mark('led_colour'), findsNothing);
      final red = find.byType(Slider).first;
      await tester.drag(red, const Offset(-200, 0));
      await _settle(tester, rounds: 10);      // the push, then ColumnState.touch's 400 ms re-read
      expect(settings.reds, isNotEmpty);
      expect(_mark('led_colour'), findsOneWidget);
    });
  });

  testWidgets('the Calibration page marks positions, expected cameras, focus and the hub switch', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, {'calibration', 'expected_cameras', 'focus_absolute', 'hub_upside_down'});
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
      await _settle(tester);
      await _openTile(tester, 'cameraOrder');
      expect(_mark('calibration'), findsOneWidget);
      await _openTile(tester, 'expectedCameras');
      expect(_mark('expected_cameras'), findsOneWidget);
      await _openTile(tester, 'focus');
      expect(_mark('focus_absolute'), findsOneWidget);
      await _openTile(tester, 'cameraOrder');
      expect(_mark('hub_upside_down'), findsOneWidget);
    });
  });

  testWidgets('the hub switch set on the Calibration page shows its mark (a working change)', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, {});
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
      await _settle(tester);
      await _openTile(tester, 'cameraOrder');
      expect(_mark('hub_upside_down'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('hub-upside-down')));
      await _settle(tester, rounds: 10); // the push, then ColumnState.touch's 400 ms re-read
      expect(_mark('hub_upside_down'), findsOneWidget);
    });
  });

  testWidgets('the Camera page marks the focus', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, {'focus_absolute'});
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CameraPage())));
      await _settle(tester);
      expect(_mark('focus_absolute'), findsOneWidget);
    });
  });

  testWidgets('a focus colour picked on the Lighting page shows its mark', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, {});
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
      await _settle(tester);
      expect(_mark('focus_light'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('focus-light-colour')));
      await _settle(tester);
      await tester.tap(find.text('Use this colour'));
      await _settle(tester, rounds: 10);
      expect(_mark('focus_light'), findsOneWidget);
    });
  });

  testWidgets('a white balance pushed from the Kelvin field shows its mark', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, {});
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
      await _settle(tester);
      expect(_mark('glare_free_white_balance'), findsNothing);
      final field = find.byKey(const ValueKey('glare-free-white-balance'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '4800');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester, rounds: 10);
      expect(_mark('glare_free_white_balance'), findsOneWidget);
    });
  });

  testWidgets('expected cameras and positions saved on the Calibration page show their marks', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, {});
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
      await _settle(tester);
      await _openTile(tester, 'cameraOrder');
      expect(_mark('calibration'), findsNothing);
      await _openTile(tester, 'expectedCameras');
      expect(_mark('expected_cameras'), findsNothing);

      final expected = find.byWidgetPredicate((w) =>
          w is DropdownMenu<int> && w.key is ValueKey && '${(w.key! as ValueKey).value}'.startsWith('expected-'));
      tester.widget<DropdownMenu<int>>(expected).onSelected!(4);
      await _settle(tester, rounds: 10);
      expect(_mark('expected_cameras'), findsOneWidget);

      await _openTile(tester, 'cameraOrder');
      await tester.ensureVisible(find.text('Save positions'));
      await tester.tap(find.text('Save positions'));
      await _settle(tester, rounds: 10);
      expect(_mark('calibration'), findsOneWidget);
      expect(find.text('Camera positions set — save them on the Column page to keep them after a restart.'),
          findsOneWidget, reason: 'a session change is not "saved" (final review M-2)');
    });
  });

  testWidgets('the focus sweep marks the focus it set, not its short-lived colour cue', (tester) async {
    await tester.runAsync(() async {
      final state = await _sweep(tester, _Capture.photo);
      expect(find.textContaining('The sweep got no photos'), findsNothing, reason: 'the success path');
      expect(find.textContaining('Sharpness sweep failed'), findsNothing, reason: 'the success path');
      expect(state.focus, isNot(40), reason: 'the sweep set its sharpest focus');
      expect(state.focusColor, '00FF00', reason: 'the colour cue was put back');
      expect(_mark('focus_absolute'), findsOneWidget);
      expect(ColumnState.anyChanged(['focus_light']), isFalse,
          reason: 'the profile is read after the colour is put back');
    });
  });

  testWidgets('a sweep that got no photos still shows the focus it moved', (tester) async {
    await tester.runAsync(() async {
      await _sweep(tester, _Capture.none);
      expect(find.text('The sweep got no photos. Is someone standing at the marking?'), findsOneWidget);
      expect(_mark('focus_absolute'), findsOneWidget);
      expect(ColumnState.anyChanged(['focus_light']), isFalse);
    });
  });

  testWidgets('a sweep that failed still shows the focus it moved', (tester) async {
    await tester.runAsync(() async {
      await _sweep(tester, _Capture.fails);
      expect(find.textContaining('Sharpness sweep failed'), findsOneWidget);
      expect(_mark('focus_absolute'), findsOneWidget);
      expect(ColumnState.anyChanged(['focus_light']), isFalse);
    });
  });

  testWidgets('a server without the column profile: no marks, no links, no Column page pointer', (tester) async {
    await tester.runAsync(() async {
      final changed = <String>{..._allTen};
      final settings = await _serve(tester, changed, columnProfile: false);
      expect(ColumnState.available, isFalse);

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
      await _settle(tester);
      await tester.drag(find.byType(Slider).first, const Offset(-200, 0));
      await _settle(tester, rounds: 10);
      expect(settings.reds, isNotEmpty);
      expect(find.text(_link), findsNothing);
      expect(find.text('●'), findsNothing);
      expect(find.text(_pointer), findsNothing, reason: 'an older server has no Column page');

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
      await _settle(tester);
      expect(find.text(_link), findsNothing);

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CameraPage())));
      await _settle(tester);
      expect(find.text(_link), findsNothing);
    });
  });

  testWidgets('a server from before the column profile keeps the strip gbl.py editor on Lighting', (tester) async {
    await tester.runAsync(() async {
      final settings = await _serve(tester, {}, columnProfile: false);
      // 1.1.19+ / 2.0.x before the column profile: it reports the photo light and has SetBoardGbl.
      SettingsState.current = LoadSettingsResponse(ledLayout: 'strip', intensityRed: 200, photoLight: 'all');
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
      await _settle(tester);
      expect(find.text('Strip file (gbl.py)'), findsOneWidget);
      expect(find.text('the default file is on the board'), findsOneWidget);
      expect(find.text(_pointer), findsNothing);

      await tester.ensureVisible(find.text('Edit…'));
      await tester.tap(find.text('Edit…'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField).last, 'LED_COUNT = 120\n');
      await tester.tap(find.text('Write to the board'));
      await _settle(tester);
      expect(settings.gbls, ['LED_COUNT = 120\n']);
      expect(find.text('your own file is on the board'), findsOneWidget);
    });
  });
}
