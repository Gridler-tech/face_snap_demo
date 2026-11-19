// The Lighting page's Backlights card (spec 2026-10-15 section 5): the output the server
// drives (LED board on Qw/ST or the header, USB relay, none), the Bottom / Top switches by
// hand for testing, and per light (Standard, Glare-free) a Bottom and a Top brightness
// slider: dragging previews the level live while that backlight is on, releasing stores it
// (SetBacklightBrightness, a column setting: its ● mark); on a relay or none the sliders are
// greyed out, on an old server hidden. Also the local-server stop switching them off first,
// and the Monitoring page's light sensor line naming the backlights on Qw/ST. Talks to an
// in-process fake server over a real loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, Service, ServiceCall;
import 'package:operator_app/pages/lighting_page.dart';
import 'package:operator_app/pages/monitoring_page.dart';
import 'package:operator_app/services/column_state.dart';
import 'package:operator_app/services/server_manager.dart';
import 'package:operator_app/services/settings_state.dart';

import 'fake_server.dart';

const _lightsOrder = ['standard', 'glare_free'];

/// The backlights behind the Lights service: [source] = the output the server drives
/// (`none` = nothing attached). [oldServer]: a server from before the dimming (no source,
/// no brightness, SetBacklightBrightness UNIMPLEMENTED); [storeUnimplemented]: only
/// SetBacklightBrightness is missing. [storeError]: the server refuses the store with it.
/// [previewError]: SetBacklight with a percent fails with it (the board stops answering).
/// [reads] counts GetBacklights.
class _FakeLights extends LightsServiceBase {
  _FakeLights(
      {this.source = 'relay', this.oldServer = false, this.storeUnimplemented = false, this.storeError,
      this.previewError});
  String source;
  final bool oldServer;
  bool storeUnimplemented;
  final GrpcError? storeError;
  final GrpcError? previewError;
  int reads = 0;
  bool bottom = false, top = false;
  final stored = <String, (int, int)>{'standard': (100, 100), 'glare_free': (100, 100)};
  final List<String> calls = [];

  bool get connected => source != 'none';

  BacklightStatus get _status => BacklightStatus(
      connected: connected,
      backlightBottom: connected && bottom,
      backlightTop: connected && top,
      source: oldServer ? null : source,
      brightness: oldServer
          ? null
          : [
              for (final light in _lightsOrder)
                BacklightBrightness(light: light, bottom: stored[light]!.$1, top: stored[light]!.$2),
            ]);

  @override
  Future<BacklightStatus> getBacklights(ServiceCall call, Empty request) async {
    reads++;
    return _status;
  }

  @override
  Future<BacklightStatus> setBacklight(ServiceCall call, BacklightRequest request) async {
    calls.add('${request.backlight.name} ${request.on ? 'on' : 'off'}'
        '${request.hasPercent() ? ' ${request.percent}' : ''}');
    if (!connected) {
      throw GrpcError.failedPrecondition('USB relay module not connected');
    }
    final failure = previewError;
    if (failure != null && request.hasPercent()) throw failure;
    // As the servers report it: on = a level above 0 (a preview at 0 % reads as off).
    final on = request.on && (!request.hasPercent() || request.percent > 0);
    if (request.backlight == Backlight.BACKLIGHT_BOTTOM) bottom = on;
    if (request.backlight == Backlight.BACKLIGHT_TOP) top = on;
    return _status;
  }

  @override
  Future<BacklightBrightnessResponse> setBacklightBrightness(
      ServiceCall call, BacklightBrightnessRequest request) async {
    calls.add('store ${request.light} ${request.bottom} ${request.top}');
    if (oldServer || storeUnimplemented) throw GrpcError.unimplemented('SetBacklightBrightness');
    final refusal = storeError;
    if (refusal != null) throw refusal;
    stored[request.light] = (request.bottom, request.top);
    return BacklightBrightnessResponse(
        brightness: BacklightBrightness(light: request.light, bottom: request.bottom, top: request.top));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// A server from before the backlights: every Lights call is unimplemented.
class _OldLights extends LightsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// The column profile: backlight_brightness is changed once [lights] stored a brightness.
class _FakeSettings extends SettingsServiceBase {
  _FakeSettings(this.lights);
  final _FakeLights lights;

  @override
  Future<ColumnProfileResponse> getColumnProfile(ServiceCall call, Empty request) async =>
      ColumnProfileResponse(boardId: 'e6614c311b4a6f2a', settings: [
        ColumnSetting(name: 'led_colour'),
        ColumnSetting(
            name: 'backlight_brightness', changed: lights.calls.any((c) => c.startsWith('store '))),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// The light sensor on Qw/ST while the backlights use those pins.
class _QwstMonitoring extends MonitoringServiceBase {
  @override
  Future<LightMeasurementResponse> getLightMeasurement(ServiceCall call, Empty request) async =>
      LightMeasurementResponse(available: false, error: 'Qw/ST is used by the backlights');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

Finder _switch(String which) => find.byKey(ValueKey('backlight-switch-$which'));
Finder _slider(String light, String which) => find.byKey(ValueKey('backlight-slider-$light-$which'));
Finder _mark() => find.byKey(const ValueKey('column-changed-backlight_brightness'));
const _dimmingNote = 'Dimming needs backlights on the LED board';

Future<Server> _serve(List<Service> services) => serveFakes(services);

Future<void> _pumpPage(WidgetTester tester, Service lights, {Service? settings}) async {
  tester.view.physicalSize = const Size(1600, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final server = await _serve([lights, ?settings]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await tester.pumpWidget(const SizedBox()); // a fresh page per call (a loop pumps several)
  SettingsState.current = LoadSettingsResponse();
  ColumnState.reset();
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  if (settings != null) await ColumnState.refresh();
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

/// Presses [slider] in its middle (50 %) and drags it to the left in 16 small steps: about
/// ten values in a burst of onChanged; lets go and returns the value it was released at.
Future<int> _drag(WidgetTester tester, Finder slider) async {
  await tester.ensureVisible(slider);
  await tester.pump();
  final gesture = await tester.startGesture(tester.getCenter(slider));
  for (var i = 0; i < 16; i++) {
    await gesture.moveBy(const Offset(-40, 0));
  }
  await tester.pump();
  final released = tester.widget<Slider>(slider).value.round();
  await gesture.up();
  await _settle(tester);
  return released;
}

double _value(WidgetTester tester, Finder slider) => tester.widget<Slider>(slider).value;

void main() {
  // The real gRPC loopback needs real time (runAsync), so the preview throttle's interval is
  // made longer than any test: a drag then previews exactly its first value (at once) and the
  // released one, whatever the machine's speed. The 100 ms timing itself is tested on a fake
  // clock in preview_throttle_test.dart.
  setUp(() => backlightPreviewInterval = const Duration(hours: 1));
  tearDown(() => backlightPreviewInterval = const Duration(milliseconds: 100));

  testWidgets('each backlight switches on and off by hand', (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights();
      await _pumpPage(tester, lights);
      expect(tester.widget<Switch>(_switch('bottom')).value, isFalse);

      await _tap(tester, _switch('top'));
      expect(lights.calls, ['BACKLIGHT_TOP on']);
      expect(tester.widget<Switch>(_switch('top')).value, isTrue);
      expect(tester.widget<Switch>(_switch('bottom')).value, isFalse,
          reason: 'the two backlights are switched separately');

      await _tap(tester, _switch('bottom'));
      await _tap(tester, _switch('top'));
      expect(lights.calls,
          ['BACKLIGHT_TOP on', 'BACKLIGHT_BOTTOM on', 'BACKLIGHT_TOP off']);
      expect(tester.widget<Switch>(_switch('bottom')).value, isTrue);
      expect(tester.widget<Switch>(_switch('top')).value, isFalse);
    });
  });

  testWidgets('switches are labelled Bottom and Top', (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, _FakeLights(source: 'board_qwst'));
      for (final (which, label) in [('bottom', 'Bottom'), ('top', 'Top')]) {
        final row = find.ancestor(of: _switch(which), matching: find.byType(Row)).first;
        expect(find.descendant(of: row, matching: find.text(label)), findsOneWidget, reason: which);
      }
      expect(find.textContaining('relay 1'), findsNothing);
      expect(find.textContaining('relay 2'), findsNothing);
    });
  });

  testWidgets('the card shows the source line', (tester) async {
    for (final (source, label) in [
      ('board_qwst', 'LED board (Qw/ST)'),
      ('board_header', 'LED board (header A0/A1)'),
      ('relay', 'USB relay'),
      ('none', 'not connected'),
    ]) {
      await tester.runAsync(() async {
        await _pumpPage(tester, _FakeLights(source: source));
        expect(find.text('Output: $label'), findsOneWidget, reason: source);
      });
    }
  });

  testWidgets('sliders show the stored brightness per light', (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights(source: 'board_header')
        ..stored['standard'] = (80, 60)
        ..stored['glare_free'] = (40, 100);
      await _pumpPage(tester, lights);
      final sliders = find.byKey(const ValueKey('backlight-sliders'));
      expect(find.descendant(of: sliders, matching: find.text('Standard light')), findsOneWidget);
      expect(find.descendant(of: sliders, matching: find.text('Glare-free light')), findsOneWidget);
      expect(find.descendant(of: sliders, matching: find.text('Bottom')), findsNWidgets(2));
      expect(find.descendant(of: sliders, matching: find.text('Top')), findsNWidgets(2));
      expect(_value(tester, _slider('standard', 'bottom')), 80);
      expect(_value(tester, _slider('standard', 'top')), 60);
      expect(_value(tester, _slider('glare_free', 'bottom')), 40);
      expect(_value(tester, _slider('glare_free', 'top')), 100);
      final standardBottom = tester.widget<Slider>(_slider('standard', 'bottom'));
      expect((standardBottom.min, standardBottom.max, standardBottom.divisions), (0, 100, 20),
          reason: '0-100 % in steps of 5');
      expect(standardBottom.onChanged, isNotNull);
      expect(find.text(_dimmingNote), findsNothing);
    });
  });

  testWidgets('dragging previews while the switch is on and stores on release', (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights(source: 'board_qwst')
        ..bottom = true
        ..stored['standard'] = (100, 70);
      await _pumpPage(tester, lights, settings: _FakeSettings(lights));
      expect(_mark(), findsNothing);

      final released = await _drag(tester, _slider('standard', 'bottom'));
      expect(released, lessThan(100));
      expect(released % 5, 0, reason: 'steps of 5');

      final previews = lights.calls.where((c) => c.startsWith('BACKLIGHT_')).toList();
      final stores = lights.calls.where((c) => c.startsWith('store ')).toList();
      expect(previews, ['BACKLIGHT_BOTTOM on 50', 'BACKLIGHT_BOTTOM on $released'],
          reason: 'throttled: the first value at once, then the released one (the panel stays at '
              'it), not one call per value');
      expect(stores, ['store standard $released 70'],
          reason: 'stored once, on release, with the released value and the top as stored');
      expect(lights.calls.last, stores.single, reason: 'stored after the last preview');
      expect(lights.stored['standard'], (released, 70));
      expect(_value(tester, _slider('standard', 'bottom')), released);

      await _settle(tester, rounds: 10); // ColumnState.touch's 400 ms re-read
      expect(_mark(), findsOneWidget);
    });
  });

  testWidgets('a drag through 0 % keeps previewing until it is let go', (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights(source: 'board_qwst')..bottom = true;
      await _pumpPage(tester, lights);
      final slider = _slider('standard', 'bottom');
      await tester.ensureVisible(slider);
      await tester.pump();
      // Pressed at the left end: 0 %, previewed at once.
      final left = tester.getCenter(slider) - Offset(tester.getSize(slider).width / 2 - 2, 0);
      final gesture = await tester.startGesture(left);
      await tester.pump();
      expect(tester.widget<Slider>(slider).value, 0);
      // Wait for the reply (network, not a timer): the server reads 0 % as off.
      for (var i = 0; i < 200 && tester.widget<Switch>(_switch('bottom')).value; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
      expect(lights.calls, ['BACKLIGHT_BOTTOM on 0']);
      expect(tester.widget<Switch>(_switch('bottom')).value, isFalse);
      await gesture.moveBy(const Offset(300, 0)); // back up
      await tester.pump();
      final released = tester.widget<Slider>(slider).value.round();
      expect(released, greaterThan(0));
      await gesture.up();
      await _settle(tester);
      expect(lights.calls.where((c) => c.startsWith('BACKLIGHT_')).last, 'BACKLIGHT_BOTTOM on $released',
          reason: 'the switch was on when the drag began: the panel follows to the end');
      expect(lights.calls.last, 'store standard $released 100');
    });
  });

  testWidgets('a failed preview stays on the card after the store and the backlights are read again',
      (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights(
          source: 'board_qwst',
          previewError: GrpcError.unavailable('LED board backlight command failed: no reply'))
        ..bottom = true;
      await _pumpPage(tester, lights);
      final readsBefore = lights.reads;
      final released = await _drag(tester, _slider('standard', 'bottom'));
      await _settle(tester);
      expect(lights.calls.last, 'store standard $released 100', reason: 'the store itself succeeds');
      expect(find.textContaining('LED board backlight command failed: no reply'), findsOneWidget,
          reason: 'the store does not wipe the preview error');
      expect(find.textContaining('not reachable'), findsNothing);
      expect(lights.reads, greaterThan(readsBefore), reason: 'the backlights were read again');
    });
  });

  testWidgets('dragging while the switch is off stores without preview', (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights(source: 'board_header')..top = true;
      await _pumpPage(tester, lights);
      final released = await _drag(tester, _slider('glare_free', 'bottom'));
      expect(released, lessThan(100));
      expect(lights.calls, ['store glare_free $released 100'],
          reason: 'the bottom backlight is off: no preview, only the store');
      expect(_value(tester, _slider('glare_free', 'bottom')), released);
    });
  });

  testWidgets('a glare-free slider previews on the live panel like a standard one', (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights(source: 'board_qwst')..top = true;
      await _pumpPage(tester, lights);
      final released = await _drag(tester, _slider('glare_free', 'top'));
      expect(lights.calls.where((c) => c.startsWith('BACKLIGHT_')).last, 'BACKLIGHT_TOP on $released');
      expect(lights.calls.last, 'store glare_free 100 $released');
    });
  });

  for (final (refusal, text) in [
    (GrpcError.invalidArgument('backlight brightness must be 0-100, got 150'),
        'backlight brightness must be 0-100, got 150'),
    (GrpcError.unavailable('LED board backlight command failed: no reply'),
        'LED board backlight command failed: no reply'),
  ]) {
    testWidgets('a refused store shows the server\'s message and puts the slider back (${refusal.codeName})',
        (tester) async {
      await tester.runAsync(() async {
        final lights = _FakeLights(source: 'board_qwst', storeError: refusal)..stored['standard'] = (85, 100);
        await _pumpPage(tester, lights);
        await _drag(tester, _slider('standard', 'bottom'));
        expect(lights.calls.where((c) => c.startsWith('store ')), hasLength(1));
        expect(find.textContaining(text), findsOneWidget);
        expect(find.textContaining('not reachable'), findsNothing);
        expect(_value(tester, _slider('standard', 'bottom')), 85, reason: 'back to the stored value');
      });
    });
  }

  testWidgets('relay or none greys the sliders out with the note', (tester) async {
    for (final source in ['relay', 'none']) {
      await tester.runAsync(() async {
        await _pumpPage(tester, _FakeLights(source: source));
        for (final light in _lightsOrder) {
          for (final which in ['bottom', 'top']) {
            expect(_slider(light, which), findsOneWidget, reason: '$source $light $which');
            expect(tester.widget<Slider>(_slider(light, which)).onChanged, isNull,
                reason: '$source $light $which');
          }
        }
        expect(find.text(_dimmingNote), findsOneWidget, reason: source);
      });
    }
  });

  testWidgets('an old server hides the sliders', (tester) async {
    // A server from before the dimming: no brightness in the status; the switches still work.
    await tester.runAsync(() async {
      final lights = _FakeLights(oldServer: true);
      await _pumpPage(tester, lights);
      expect(find.byKey(const ValueKey('backlight-sliders')), findsNothing);
      expect(find.byType(Slider), findsNWidgets(4), reason: 'only the kiosk-lighting sliders');
      expect(find.text('Output: USB relay'), findsOneWidget);
      await _tap(tester, _switch('bottom'));
      expect(lights.calls, ['BACKLIGHT_BOTTOM on']);
    });
    // A status with brightness but no SetBacklightBrightness: hidden once it answers UNIMPLEMENTED.
    await tester.runAsync(() async {
      final lights = _FakeLights(source: 'board_qwst', storeUnimplemented: true);
      await _pumpPage(tester, lights);
      expect(find.byKey(const ValueKey('backlight-sliders')), findsOneWidget);
      await _drag(tester, _slider('standard', 'top'));
      expect(find.byKey(const ValueKey('backlight-sliders')), findsNothing);
      expect(find.textContaining('too old'), findsNothing, reason: 'hidden, not an error');

      // The server is updated: a fresh status with the brightness brings the sliders back.
      lights.storeUnimplemented = false;
      await _tap(tester, find.text('Refresh'));
      expect(find.byKey(const ValueKey('backlight-sliders')), findsOneWidget,
          reason: 'the UNIMPLEMENTED answer is forgotten on a fresh status with brightness');
    });
  });

  testWidgets('without any backlights the switches are greyed out', (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, _FakeLights(source: 'none'));
      expect(tester.widget<Switch>(_switch('bottom')).onChanged, isNull);
      expect(tester.widget<Switch>(_switch('top')).onChanged, isNull);
      expect(find.textContaining('No backlights found'), findsOneWidget);
    });
  });

  testWidgets('a module unplugged meanwhile: the switch springs back and says why',
      (tester) async {
    await tester.runAsync(() async {
      final lights = _FakeLights();
      await _pumpPage(tester, lights);
      lights.source = 'none'; // unplugged after the page read it
      await _tap(tester, _switch('bottom'));
      expect(tester.widget<Switch>(_switch('bottom')).value, isFalse);
      expect(find.textContaining('Could not switch the backlight'), findsOneWidget);
      // The card read the module again: the switches are greyed out now.
      expect(tester.widget<Switch>(_switch('bottom')).onChanged, isNull);
      expect(tester.widget<Switch>(_switch('top')).onChanged, isNull);
    });
  });

  testWidgets('an older server: the card says to update it', (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, _OldLights());
      expect(tester.widget<Switch>(_switch('bottom')).onChanged, isNull);
      expect(find.textContaining('too old for that call'), findsOneWidget);
      expect(find.byKey(const ValueKey('backlight-sliders')), findsNothing);
    });
  });

  testWidgets('the monitoring page shows the Qw/ST message', (tester) async {
    await tester.runAsync(() async {
      final server = await _serve([_QwstMonitoring()]);
      addTearDown(() => tester.runAsync(() => server.shutdown()));
      SettingsState.current = LoadSettingsResponse();
      await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MonitoringPage())));
      await _settle(tester);
      expect(find.text('Light sensor unavailable: Qw/ST is used by the backlights'), findsOneWidget);
    });
  });

  test('stopping the local server switches both backlights off first', () async {
    final lights = _FakeLights()..bottom = true..top = true;
    final server = await _serve([lights]);
    addTearDown(server.shutdown);
    await ServerManager.backlightsOff(server.port!);
    expect(lights.calls, ['BACKLIGHT_BOTTOM off', 'BACKLIGHT_TOP off']);
    expect(lights.bottom || lights.top, isFalse);
  });

  test('switching off before a stop never fails the stop', () async {
    final server = await _serve([_OldLights()]);
    addTearDown(server.shutdown);
    await ServerManager.backlightsOff(server.port!); // unimplemented: ignored
    final free = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = free.port;
    await free.close();
    await ServerManager.backlightsOff(port); // nothing listening: ignored
  });
}
