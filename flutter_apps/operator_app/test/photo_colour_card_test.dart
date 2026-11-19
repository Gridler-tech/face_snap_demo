// The Calibration page's Photo colour card (spec 2026-10-13 section 4.1) and the
// Lighting page's correction switch: the status per light, an old server, Measure
// (a manual capture with that light and the correction off, then the dialog),
// Save (SetColourCorrection with the fit and the measurement), Discard (nothing
// sent), Back to shipped (clear), a capture the server corrected anyway, and the
// switch (SetColourCorrectionEnabled, rolled back on a failure). Against
// in-process fake Settings and Kiosk servers over a real loopback connection; the
// photos decode to a synthetic chart through the decode seam.
import 'dart:convert';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, ServiceCall;
import 'package:operator_app/pages/calibration_page.dart';
import 'package:operator_app/pages/lighting_page.dart';
import 'package:operator_app/pages/photo_colour_card.dart';
import 'package:operator_app/services/app_config.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/util/card_reference.dart';

import 'fake_server.dart';
import 'photo_colour_chart.dart';

const _kioskMatrix = [1.2, -0.1, -0.1, -0.05, 1.1, -0.05, 0.0, -0.2, 1.2];

ColourMeasurement _measured() => ColourMeasurement(
    measured: '2026-10-20T14:05:00Z',
    camera: 3,
    chart: 'spyder24',
    meanDeBefore: 6.04,
    meanDeAfter: 1.96);

/// A server with the feature: "all" measured on this kiosk, the other two shipped.
LoadSettingsResponse _settings({bool enabled = true}) => LoadSettingsResponse(
      colourCorrection: enabled,
      colourCorrections: [
        ColourCorrectionState(
            light: 'all', matrix: _kioskMatrix, source: 'kiosk', measurement: _measured()),
        ColourCorrectionState(
            light: 'neighbours', matrix: [1, 0, 0, 0, 1, 0, 0, 0, 1], source: 'shipped'),
        ColourCorrectionState(
            light: 'glare_free', matrix: [1, 0, 0, 0, 1, 0, 0, 0, 1], source: 'shipped'),
      ],
    );

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({this.refuse = false});

  /// true = the colour calls fail (UNIMPLEMENTED, an older server).
  final bool refuse;
  final List<ColourCorrectionRequest> colour = [];
  final List<bool> enabled = [];

  @override
  Future<LoadSettingsResponse> loadSettings(ServiceCall call, Empty request) async =>
      _settings();

  @override
  Future<ColourCorrectionResponse> setColourCorrection(
      ServiceCall call, ColourCorrectionRequest request) async {
    colour.add(request);
    if (refuse) throw GrpcError.unimplemented('SetColourCorrection');
    return ColourCorrectionResponse(
        state: request.clear_4
            ? ColourCorrectionState(
                light: request.light, matrix: [1, 0, 0, 0, 1, 0, 0, 0, 1], source: 'shipped')
            : ColourCorrectionState(
                light: request.light,
                matrix: request.matrix,
                source: 'kiosk',
                measurement: request.measurement));
  }

  @override
  Future<ColourCorrectionEnabledResponse> setColourCorrectionEnabled(
      ServiceCall call, ColourCorrectionEnabledRequest request) async {
    enabled.add(request.value);
    if (refuse) throw GrpcError.unimplemented('SetColourCorrectionEnabled');
    return ColourCorrectionEnabledResponse(value: request.value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// A manual capture: the settings used first, then one photo per camera 1..6
/// (each photo's bytes = [its camera index]).
class _FakeKiosk extends KioskServiceBase {
  _FakeKiosk({this.corrected = false});

  /// true = the settings used report the correction on (a server that ignored 27).
  final bool corrected;
  final List<CaptureSettings> manual = [];

  @override
  Stream<ProcessManualResponse> startManualCapture(
      ServiceCall call, CaptureRequest request) async* {
    manual.add(request.settings);
    final used = request.settings.deepCopy();
    if (corrected) used.colourCorrection = true;
    yield ProcessManualResponse(
        settingsUsed: CaptureSettingsUsed(values: used, overridden: ['colour_correction']));
    for (var i = 1; i <= 6; i++) {
      yield ProcessManualResponse(
          processStatus: ProcessStepStatus(
              index: i, description: 'Taking a high res photo', status: StatusType.OK));
      yield ProcessManualResponse(
          imageData: ProcessImageData(index: i, width: 320, height: 400, chunkData: [i]));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Served {
  _Served(this.settings, this.kiosk);
  final _FakeSettings settings;
  final _FakeKiosk kiosk;
}

Future<_Served> _serve(WidgetTester tester,
    {LoadSettingsResponse? stored, bool refuse = false, bool corrected = false}) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final settings = _FakeSettings(refuse: refuse);
  final kiosk = _FakeKiosk(corrected: corrected);
  final server = await serveFakes([settings, kiosk]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  addTearDown(() => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()));
  SettingsState.current = stored ?? _settings();
  return _Served(settings, kiosk);
}

/// The card references from the app's files (no rootBundle under the test clock).
Future<CardReference> _load(String card, String version) async => CardReference.fromJson(
    jsonDecode(File('assets/colour_cards/$card.json').readAsStringSync()) as Map<String, dynamic>,
    version: card == 'classic' ? version : '');

/// The card alone, its photos decoding to [chart].
Future<_Served> _pumpCard(WidgetTester tester, TestChart chart,
    {LoadSettingsResponse? stored, bool refuse = false, bool corrected = false}) async {
  final served = await _serve(tester, stored: stored, refuse: refuse, corrected: corrected);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: PhotoColourCard(decode: (_) async => chart.image, loadReference: _load),
      ),
    ),
  ));
  await _settle(tester);
  return served;
}

Future<void> _settle(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

/// The row of [label] (a Row holding the label text).
Finder _row(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Row)).first;

Finder _inRow(String label, String text) =>
    find.descendant(of: _row(label), matching: find.text(text));

Future<void> _tap(WidgetTester tester, Finder finder, {int rounds = 10}) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester, rounds: rounds);
}

/// Measure on [label]'s row, until the dialog shows the photo.
Future<void> _measure(WidgetTester tester, String label) async {
  await _tap(tester, _inRow(label, 'Measure'));
  for (var i = 0; i < 30 && find.byKey(const ValueKey('photo-colour-photo')).evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Finder _colourSwitch() => find.descendant(
    of: find.ancestor(of: find.text('Photo colour correction'), matching: find.byType(Row)).first,
    matching: find.byType(Switch));

Future<_FakeSettings> _pumpLighting(WidgetTester tester, {required bool refuse}) async {
  final served = await _serve(tester, stored: _settings(enabled: true), refuse: refuse);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
  await _settle(tester);
  return served.settings;
}

void main() {
  testWidgets('the card shows shipped and kiosk rows', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CalibrationPage())));
      await _settle(tester);
      // The overview (design 2026-10-16): open the Photo colour tile first.
      await tester.tap(find.byKey(const ValueKey('calibration-tile-photoColour')));
      await _settle(tester);
      expect(find.text('PHOTO COLOUR'), findsOneWidget);
      expect(find.text('Standard light (all LEDs)'), findsOneWidget);
      expect(find.text('Standard light (neighbours)'), findsOneWidget);
      expect(find.text('Glare-free light'), findsOneWidget);
      expect(_inRow('Standard light (all LEDs)', 'this kiosk · 2026-10-20 · ΔE 6.0 → 2.0'),
          findsOneWidget);
      expect(_inRow('Standard light (neighbours)', 'shipped'), findsOneWidget);
      expect(_inRow('Glare-free light', 'shipped'), findsOneWidget);
      expect(find.text('Measure'), findsNWidgets(3));
      // Only the light with this kiosk's own matrix can go back.
      expect(find.text('Back to shipped'), findsOneWidget);
      expect(_inRow('Standard light (all LEDs)', 'Back to shipped'), findsOneWidget);
      expect(
          find.text('Hold the SpyderCheckr 24 at face height, flat to the middle camera, '
              'fingers off the patches. Then tap the centres of the four corner patches.'),
          findsOneWidget);
    });
  });

  testWidgets('an old server shows not available', (tester) async {
    await tester.runAsync(() async {
      // LoadSettings without the colour fields.
      await _pumpCard(tester, testChart(), stored: LoadSettingsResponse(jpegQuality: 95));
      expect(find.text('Not available on this server'), findsOneWidget);
      expect(find.text('Measure'), findsNothing);
      expect(find.text('Back to shipped'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
    await tester.runAsync(() async {
      // The fields there, but SetColourCorrection answers UNIMPLEMENTED.
      final served = await _pumpCard(tester, testChart(), refuse: true);
      await _tap(tester, find.text('Back to shipped'));
      expect(served.settings.colour, hasLength(1));
      expect(find.text('Not available on this server'), findsOneWidget);
      expect(find.text('Measure'), findsNothing);
    });
  });

  testWidgets('measure runs a manual capture with the light and correction off', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, testChart());
      await _measure(tester, 'Glare-free light');
      expect(find.text('Camera 3'), findsOneWidget, reason: 'six photos: the middle camera');
      await _tap(tester, find.text('Discard'));

      await _measure(tester, 'Standard light (neighbours)');
      await _tap(tester, find.text('Discard'));
      await _measure(tester, 'Standard light (all LEDs)');
      await _tap(tester, find.text('Discard'));

      expect(served.kiosk.manual, [
        CaptureSettings(colourCorrection: false, glareFreeLight: 'everyone'),
        CaptureSettings(colourCorrection: false, photoLight: 'neighbours', glareFreeLight: 'off'),
        CaptureSettings(colourCorrection: false, photoLight: 'all', glareFreeLight: 'off'),
      ]);
    });
  });

  testWidgets('save sends SetColourCorrection with the fit and the measurement', (tester) async {
    await tester.runAsync(() async {
      final chart = testChart();
      final served = await _pumpCard(tester, chart);
      await _measure(tester, 'Glare-free light');
      for (final p in chart.corners) {
        await tapPhotoAt(tester, chart.image, p);
      }
      await tester.pump();
      await _tap(tester, find.text('Save'));

      final request = served.settings.colour.single;
      expect(request.light, 'glare_free');
      expect(request.clear_4, isFalse);
      expect(request.matrix, hasLength(9));
      expect(request.matrix.every((v) => v.isFinite), isTrue);
      expect(request.measurement.camera, 3);
      expect(request.measurement.chart, 'spyder24');
      expect(request.measurement.meanDeAfter, lessThan(request.measurement.meanDeBefore));
      final date = request.measurement.measured.substring(0, 10);
      final before = request.measurement.meanDeBefore.toStringAsFixed(1);
      final after = request.measurement.meanDeAfter.toStringAsFixed(1);
      expect(_inRow('Glare-free light', 'this kiosk · $date · ΔE $before → $after'),
          findsOneWidget);
      expect(_inRow('Glare-free light', 'Back to shipped'), findsOneWidget);
      // The shared snapshot follows.
      expect(SettingsState.current!.colourCorrections[2].source, 'kiosk');
    });
  });

  testWidgets('Measure manually reads a Classic and records method taps', (tester) async {
    final card = AppConfig.colourCard, version = AppConfig.colourCardVersion;
    addTearDown(() {
      AppConfig.colourCard = card;
      AppConfig.colourCardVersion = version;
    });
    AppConfig.colourCard = 'classic';
    AppConfig.colourCardVersion = '2014';
    await tester.runAsync(() async {
      final chart = testChart(colours: castColours(classicReference('2014')));
      final stored = _settings()
        ..intensityRed = 210
        ..intensityGreen = 190
        ..intensityBlue = 180
        ..glareFreeWhiteBalance = 4600;
      final served = await _pumpCard(tester, chart, stored: stored);
      expect(find.text('Measure manually'), findsOneWidget);
      expect(
          find.text('Hold the ColorChecker Classic at face height, flat to the middle camera, '
              'fingers off the patches. Then tap the centres of the four corner patches.'),
          findsOneWidget);
      for (final (label, light) in [('Standard light (all LEDs)', 'all'), ('Glare-free light', 'glare_free')]) {
        await _measure(tester, label);
        for (final p in chart.corners) {
          await tapPhotoAt(tester, chart.image, p);
        }
        await tester.pump();
        expect(find.text('Save'), findsOneWidget, reason: 'the Classic is read');
        await _tap(tester, find.text('Save'));
        final m = served.settings.colour.last.measurement;
        expect(served.settings.colour.last.light, light);
        expect(m.chart, 'classic');
        expect(m.cardVersion, '2014');
        expect(m.method, 'taps');
        expect(m.camera, 3);
        expect(m.scoreAfter, greaterThan(0));
        expect([m.ledRed, m.ledGreen, m.ledBlue], [210, 190, 180], reason: 'the mix the photo was taken with');
        expect(m.whiteBalance, light == 'glare_free' ? 4600 : 0);
      }
    });
  });

  testWidgets('back to shipped sends clear', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, testChart());
      await _tap(tester, find.text('Back to shipped'));
      final request = served.settings.colour.single;
      expect(request.light, 'all');
      expect(request.clear_4, isTrue);
      expect(_inRow('Standard light (all LEDs)', 'shipped'), findsOneWidget);
      expect(find.text('Back to shipped'), findsNothing);
      expect(SettingsState.current!.colourCorrections[0].source, 'shipped');
    });
  });

  testWidgets('discard sends nothing', (tester) async {
    await tester.runAsync(() async {
      final chart = testChart();
      final served = await _pumpCard(tester, chart);
      await _measure(tester, 'Standard light (neighbours)');
      for (final p in chart.corners) {
        await tapPhotoAt(tester, chart.image, p);
      }
      await tester.pump();
      expect(find.text('Save'), findsOneWidget);
      await _tap(tester, find.text('Discard'));
      expect(served.kiosk.manual, hasLength(1));
      expect(served.settings.colour, isEmpty);
      expect(_inRow('Standard light (neighbours)', 'shipped'), findsOneWidget);
    });
  });

  testWidgets('a capture the server corrected anyway is refused', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, testChart(), corrected: true);
      await _tap(tester, _inRow('Standard light (all LEDs)', 'Measure'));
      expect(find.text(colourMeasurementCorrected), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-colour-photo')), findsNothing);
      expect(served.settings.colour, isEmpty);
    });
  });

  testWidgets('the Lighting switch calls SetColourCorrectionEnabled and rolls back on failure',
      (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpLighting(tester, refuse: false);
      expect(tester.widget<Switch>(_colourSwitch()).value, isTrue);
      await _tap(tester, _colourSwitch());
      expect(settings.enabled, [false]);
      expect(tester.widget<Switch>(_colourSwitch()).value, isFalse);
      expect(SettingsState.current!.colourCorrection, isFalse);
      await tester.pumpWidget(const SizedBox());
    });
    await tester.runAsync(() async {
      final settings = await _pumpLighting(tester, refuse: true);
      await _tap(tester, _colourSwitch());
      expect(settings.enabled, [false]);
      expect(tester.widget<Switch>(_colourSwitch()).value, isTrue, reason: 'rolled back');
      expect(SettingsState.current!.colourCorrection, isTrue);
      expect(find.textContaining('Server call failed'), findsOneWidget);
    });
  });

  testWidgets('an old server greys the switch out', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester, stored: LoadSettingsResponse(lighting: true));
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LightingPage())));
      await _settle(tester);
      expect(tester.widget<Switch>(_colourSwitch()).onChanged, isNull);
      // No colour_corrections: the proto default false is not the server's value; the switch
      // reads as on, as the C# SDK does.
      expect(tester.widget<Switch>(_colourSwitch()).value, isTrue);
    });
  });
}
