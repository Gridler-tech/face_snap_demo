// Calibrate on the Photo colour card (spec 2026-11-02 sections 2, 5 and 6; plan
// Task 13): the R2 probe decides whether Calibrate is offered (an older server
// shows only Measure manually; a failed probe is sent again at the next settings
// change), the dialog's setup (the card, the lights and
// their pre-ticks, Start disabled while the column's lights are off: Review
// Focus 1), a full run to the result and its Save, a lost card that falls back
// to the taps, Cancel, a Save whose write fails and its Retry, a stop, the
// skipped tint, a run that changes nothing, two taps in one frame, the dialog
// removed mid-run and Cancel's pop value after a failed Save. Against in-process fake Kiosk
// (MeasureColourCard answered from simulated_card.dart), Settings and Camera
// servers over a real loopback connection; photos decode to a synthetic chart
// through the decode seam and the card references are read from the files.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart' hide LedMix;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, Service, ServiceCall;
import 'package:operator_app/pages/colour_calibrate_dialog.dart';
import 'package:operator_app/pages/photo_colour_card.dart';
import 'package:operator_app/services/app_config.dart';
import 'package:operator_app/services/colour_calibration.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/ui/ui.dart' show GoButton;
import 'package:operator_app/util/card_reference.dart';
import 'package:operator_app/util/colour_fit.dart';
import 'package:operator_app/util/led_mix_search.dart';

import 'fake_server.dart';
import 'photo_colour_chart.dart';
import 'simulated_card.dart';

const _kioskMix = LedMix(200, 200, 200);
const _middleCamera = 3;
const _cardExposure = 24;
const _notFoundNote = 'the card was not found in the photo';
const _greysNote =
    'the card was seen, but its dark patches read too light: tilt it 10-15° away from the lights or dim the room lights';

/// The card references from the app's files (no rootBundle under the test clock).
Future<CardReference> _load(String card, String version) async => CardReference.fromJson(
    jsonDecode(File('assets/colour_cards/$card.json').readAsStringSync()) as Map<String, dynamic>,
    version: card == 'classic' ? version : '');

LoadSettingsResponse _settings({
  bool lighting = true,
  String photoLight = 'all',
  GlareFreeLight glareFree = GlareFreeLight.GLARE_FREE_LIGHT_OFF,
  int whiteBalance = 5000,
}) =>
    LoadSettingsResponse(
      lighting: lighting,
      intensityRed: _kioskMix.red,
      intensityGreen: _kioskMix.green,
      intensityBlue: _kioskMix.blue,
      photoLight: photoLight,
      glareFreeLight: glareFree,
      glareFreeWhiteBalance: whiteBalance,
      colourCorrection: true,
      colourCorrections: [
        for (final light in ['all', 'neighbours', 'glare_free'])
          ColourCorrectionState(light: light, matrix: [1, 0, 0, 0, 1, 0, 0, 0, 1], source: 'shipped'),
      ],
    );

/// A kiosk with the card finder: MeasureColourCard answered from [sim]; the
/// probe (light "") refused as the servers do. [lose] answers "not found",
/// [perfect] answers the reference itself (a photo no matrix improves), the
/// call [holdAt] waits for [hold], and the first probes fail with [probeErrors].
class _Kiosk extends KioskServiceBase {
  _Kiosk(this.sim,
      {this.lose, this.perfect = false, this.holdAt, List<GrpcError>? probeErrors, this.loseNote = _notFoundNote})
      : probeErrors = [...?probeErrors];

  /// The note a lost photo carries (the servers' "not found" or their greys note).
  final String loseNote;

  final SimulatedCard sim;
  final bool Function(ColourCardRequest request)? lose;
  final bool perfect;
  final int? holdAt;
  final Completer<void> hold = Completer<void>();
  final List<GrpcError> probeErrors;

  /// The probes (light "") received.
  int probes = 0;

  /// The measurement calls (the probe not counted).
  final List<ColourCardRequest> requests = [];

  /// Where the fake puts the patches: on the synthetic chart's centres.
  final List<Offset> centres = testChart().centres;

  @override
  Future<ColourCardResponse> measureColourCard(ServiceCall call, ColourCardRequest request) async {
    if (request.light.isEmpty) {
      probes++;
      if (probeErrors.isNotEmpty) throw probeErrors.removeAt(0);
      throw GrpcError.invalidArgument("colour card light must be all, neighbours or glare_free, not ''");
    }
    final n = requests.length;
    requests.add(request.deepCopy());
    if (n == holdAt) await hold.future;
    final camera = request.camera == 0 ? _middleCamera : request.camera;
    final exposure = request.hasExposure() ? request.exposure : _cardExposure;
    final photo = [n & 0xff];
    if (lose?.call(request) ?? false) {
      return ColourCardResponse(
          found: false, exposure: exposure, camera: camera, photo: photo, note: loseNote);
    }
    final reference = sim.reference;
    final mix = request.hasLedMix() ? LedMix(request.ledMix.red, request.ledMix.green, request.ledMix.blue) : _kioskMix;
    var p = sim.photo(mix);
    if (perfect) {
      final srgb8 = [
        for (final lab in reference.lab)
          [for (final v in labD50ToLinearSrgb(lab)) (255 * linearToSrgb(v)).clamp(0, 255).toDouble()],
      ];
      p = (srgb8: srgb8, clipped: List.filled(srgb8.length, false));
    }
    return ColourCardResponse(
      found: true,
      patches: [
        for (var i = 0; i < p.srgb8.length; i++)
          ColourPatch(
              id: reference.ids[i],
              r: p.srgb8[i][0],
              g: p.srgb8[i][1],
              b: p.srgb8[i][2],
              clipped: p.clipped[i],
              x: centres[i].dx,
              y: centres[i].dy),
      ],
      patchSizePx: 60,
      exposure: exposure,
      camera: camera,
      photo: photo,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

/// Save's writes, in order; [failColour] SetColourCorrection calls fail first.
class _Settings extends SettingsServiceBase {
  _Settings(this.stored);

  final LoadSettingsResponse stored;
  final List<String> calls = [];
  final List<ColourCorrectionRequest> colour = [];
  int failColour = 0;

  /// The next writes of any kind that fail.
  int failWrites = 0;

  void _write(String call) {
    calls.add(call);
    if (failWrites > 0) {
      failWrites--;
      throw GrpcError.internal('the board did not answer');
    }
  }

  @override
  Future<LoadSettingsResponse> loadSettings(ServiceCall call, Empty request) async => stored;

  Future<IntensityResponse> _intensity(String name, IntensityRequest request) async {
    _write('$name ${request.value}');
    return IntensityResponse(message: request.value);
  }

  @override
  Future<IntensityResponse> setIntensityRed(ServiceCall call, IntensityRequest request) =>
      _intensity('SetIntensityRed', request);

  @override
  Future<IntensityResponse> setIntensityGreen(ServiceCall call, IntensityRequest request) =>
      _intensity('SetIntensityGreen', request);

  @override
  Future<IntensityResponse> setIntensityBlue(ServiceCall call, IntensityRequest request) =>
      _intensity('SetIntensityBlue', request);

  @override
  Future<GlareFreeWhiteBalanceResponse> setGlareFreeWhiteBalance(
      ServiceCall call, GlareFreeWhiteBalanceRequest request) async {
    _write('SetGlareFreeWhiteBalance ${request.value}');
    return GlareFreeWhiteBalanceResponse(message: request.value);
  }

  @override
  Future<ColourCorrectionResponse> setColourCorrection(ServiceCall call, ColourCorrectionRequest request) async {
    _write('SetColourCorrection ${request.light}');
    if (failColour > 0) {
      failColour--;
      throw GrpcError.internal('the board did not answer');
    }
    colour.add(request);
    return ColourCorrectionResponse(
        state: ColourCorrectionState(
            light: request.light, matrix: request.matrix, source: 'kiosk', measurement: request.measurement));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

/// The camera settings: the automatic white balance (R19) and the automatic
/// exposure (the fixed-exposure warning) matter here.
class _Camera extends CameraServiceBase {
  _Camera({this.autoWhiteBalance = false, this.autoExposure = false, this.fails = false});

  final bool autoWhiteBalance, autoExposure;

  /// Every LoadSettings fails (a camera that cannot be read).
  final bool fails;
  int loads = 0;

  @override
  Future<LoadCameraSettingsResponse> loadSettings(ServiceCall call, Empty request) async {
    loads++;
    if (fails) throw GrpcError.unavailable('the camera did not answer');
    return LoadCameraSettingsResponse(
        whiteBalanceTemperatureAuto: autoWhiteBalance, exposureAutoPriority: autoExposure);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Served {
  _Served(this.settings, this.kiosk, this.camera);
  final _Settings settings;
  final _Kiosk? kiosk;
  final _Camera camera;
}

/// The Photo colour card against [kiosk] (null: a kiosk without MeasureColourCard).
/// [home] replaces the card (a host that opens the dialog itself).
Future<_Served> _pumpCard(WidgetTester tester, LoadSettingsResponse stored,
    {_Kiosk? kiosk,
    bool autoWhiteBalance = false,
    bool autoExposure = false,
    bool cameraFails = false,
    Widget? home}) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final dir = Directory.systemTemp.createTempSync('operator_calibrate_test');
  final card = AppConfig.colourCard, version = AppConfig.colourCardVersion;
  AppConfig.appDataDirOverride = dir.path;
  addTearDown(() {
    AppConfig.colourCard = card;
    AppConfig.colourCardVersion = version;
    AppConfig.appDataDirOverride = null;
    dir.deleteSync(recursive: true);
  });
  final settings = _Settings(stored);
  final camera = _Camera(autoWhiteBalance: autoWhiteBalance, autoExposure: autoExposure, fails: cameraFails);
  final Server server = await serveFakes(<Service>[settings, camera, ?kiosk]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  addTearDown(() => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()));
  SettingsState.current = stored;
  final chart = testChart();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: home ?? PhotoColourCard(decode: (_) async => chart.image, loadReference: _load),
      ),
    ),
  ));
  await _settle(tester);
  return _Served(settings, kiosk, camera);
}

Future<void> _settle(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
}

/// Pumps (in real time) until [finder] finds something, for at most [seconds].
Future<void> _until(WidgetTester tester, Finder finder, {int seconds = 30}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) fail('timed out waiting for $finder');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
}

/// Pumps (in real time) until [finder] finds nothing, for at most [seconds].
Future<void> _untilGone(WidgetTester tester, Finder finder, {int seconds = 30}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (finder.evaluate().isNotEmpty) {
    if (DateTime.now().isAfter(end)) fail('timed out waiting for $finder to go');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

/// The dialog open from the card's Calibrate.
Future<void> _openCalibrate(WidgetTester tester) async {
  await _until(tester, find.text('Calibrate'));
  await _tap(tester, find.text('Calibrate'));
  await _until(tester, find.text('Start'));
}

Finder _dialog() => find.byType(ColourCalibrateDialog);

Finder _inDialog(Finder finder) => find.descendant(of: _dialog(), matching: finder);

Checkbox _lightBox(WidgetTester tester, String light) =>
    tester.widget<Checkbox>(find.byKey(ValueKey('calibrate-light-$light')));

VoidCallback? _onPressed(WidgetTester tester, String text) =>
    tester.widget<GoButton>(find.widgetWithText(GoButton, text)).onPressed;

/// Opens the dialog on "Open" and adds what it pops to [popped].
Widget _host(List<bool?> popped) {
  final chart = testChart();
  return Builder(
    builder: (context) => TextButton(
      onPressed: () async => popped.add(await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ColourCalibrateDialog(decode: (_) async => chart.image, loadReference: _load),
      )),
      child: const Text('Open'),
    ),
  );
}

SimulatedCard _sim([CardReference? reference]) =>
    SimulatedCard(reference: reference ?? spyderReference, best: bestFrom(_kioskMix), c: 1000);

void main() {
  testWidgets('an older server shows only Measure manually', (tester) async {
    await tester.runAsync(() async {
      // The stand-in kiosk answers MeasureColourCard UNIMPLEMENTED (R2).
      await _pumpCard(tester, _settings());
      await _settle(tester, rounds: 10);
      expect(find.text('Measure manually'), findsOneWidget);
      expect(find.text('Measure'), findsNWidgets(3));
      expect(find.text('Calibrate'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
    await tester.runAsync(() async {
      // A server with the card finder: Calibrate next to Measure manually.
      final served = await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim()));
      await _until(tester, find.text('Calibrate'));
      expect(find.text('Measure manually'), findsOneWidget);
      expect(find.text('Measure'), findsNWidgets(3));
      expect(served.kiosk!.requests, isEmpty, reason: 'the probe takes no photo');
    });
  });

  testWidgets('a failed probe is sent again at the next settings change; UNIMPLEMENTED is kept', (tester) async {
    await tester.runAsync(() async {
      // the first probe times out, the second finds the kiosk unreachable, the third answers
      final kiosk = _Kiosk(_sim(), probeErrors: [
        GrpcError.deadlineExceeded('Deadline exceeded'),
        GrpcError.unavailable('the kiosk did not answer'),
      ]);
      await _pumpCard(tester, _settings(), kiosk: kiosk);
      await _settle(tester, rounds: 10);
      expect(kiosk.probes, 1);
      expect(find.text('Calibrate'), findsNothing);
      expect(find.text('Measure manually'), findsOneWidget);
      SettingsState.revision.value++;
      await _settle(tester, rounds: 10);
      expect(kiosk.probes, 2);
      expect(find.text('Calibrate'), findsNothing);
      SettingsState.revision.value++;
      await _until(tester, find.text('Calibrate'));
      expect(kiosk.probes, 3);
      // once known, a settings change sends no probe
      SettingsState.revision.value++;
      await _settle(tester, rounds: 10);
      expect(kiosk.probes, 3);
      expect(find.text('Calibrate'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
    await tester.runAsync(() async {
      // UNIMPLEMENTED: the server has no card finder, no probe again
      final kiosk = _Kiosk(_sim(),
          probeErrors: [GrpcError.unimplemented('colour card finding is not available on this server')]);
      await _pumpCard(tester, _settings(), kiosk: kiosk);
      await _settle(tester, rounds: 10);
      SettingsState.revision.value++;
      await _settle(tester, rounds: 10);
      expect(kiosk.probes, 1);
      expect(find.text('Calibrate'), findsNothing);
      expect(find.text('Measure manually'), findsOneWidget);
    });
  });

  testWidgets('start is disabled while the lights are off', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, _settings(lighting: false), kiosk: _Kiosk(_sim()));
      await _openCalibrate(tester);
      expect(find.text("The column's lights are off (Lighting page): switch them on to calibrate"), findsOneWidget);
      expect(_onPressed(tester, 'Start'), isNull);
      await tester.tap(find.text('Start'));
      await _settle(tester);
      expect(served.kiosk!.requests, isEmpty);
      expect(find.text('Start'), findsOneWidget);
    });
  });

  testWidgets("the pre-ticks follow the kiosk's photo light and glare-free light", (tester) async {
    await tester.runAsync(() async {
      await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim()));
      await _openCalibrate(tester);
      expect(_inDialog(find.text('SpyderCheckr 24')), findsOneWidget);
      expect(find.text('Standard (all LEDs)'), findsOneWidget);
      expect(find.text('Standard (neighbours)'), findsOneWidget);
      expect(find.text('Glare-free'), findsOneWidget);
      expect(_lightBox(tester, 'all').value, isTrue);
      expect(_lightBox(tester, 'all').onChanged, isNull, reason: 'Standard (all LEDs) is always on');
      expect(_lightBox(tester, 'neighbours').value, isFalse);
      expect(_lightBox(tester, 'glare_free').value, isFalse);
      expect(_onPressed(tester, 'Start'), isNotNull);
      // the boxes can be ticked
      await _tap(tester, find.byKey(const ValueKey('calibrate-light-neighbours')));
      expect(_lightBox(tester, 'neighbours').value, isTrue);
      await tester.pumpWidget(const SizedBox());
    });
    for (final glareFree in [GlareFreeLight.GLARE_FREE_LIGHT_GLASSES, GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE]) {
      await tester.runAsync(() async {
        await _pumpCard(tester, _settings(photoLight: 'neighbours', glareFree: glareFree), kiosk: _Kiosk(_sim()));
        await _openCalibrate(tester);
        expect(_lightBox(tester, 'all').value, isTrue);
        expect(_lightBox(tester, 'neighbours').value, isTrue);
        expect(_lightBox(tester, 'glare_free').value, isTrue, reason: '$glareFree');
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  testWidgets('a full run shows the result and Save writes it', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(
          tester, _settings(photoLight: 'neighbours', glareFree: GlareFreeLight.GLARE_FREE_LIGHT_GLASSES),
          kiosk: _Kiosk(_sim()));
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      await _until(tester, find.text('Save'), seconds: 60);

      final kiosk = served.kiosk!;
      expect(kiosk.requests.first.light, 'all');
      expect(kiosk.requests.first.camera, 0);
      expect(kiosk.requests.first.card, 'spyder24');
      // R19: the white balance mode is read at Start (the setup read the exposure once before)
      expect(served.camera.loads, 2);
      // the result (spec 2 step 4)
      expect(find.textContaining('LED mix (200, 200, 200) → '), findsOneWidget);
      expect(find.textContaining('brightness'), findsOneWidget);
      expect(find.textContaining('Glare-free white balance 5000 K → '), findsOneWidget);
      // spec 4.4 step 3: the residual a* the white balance cannot move, signed, one decimal
      expect(
          find.byWidgetPredicate((w) =>
              w is Text &&
              RegExp(r'^Glare-free white balance 5000 K → \d+ K( \(unchanged\))? · residual a\* [+-]\d+\.\d$')
                  .hasMatch(w.data ?? '')),
          findsOneWidget);
      for (final label in ['Standard (all LEDs)', 'Standard (neighbours)', 'Glare-free']) {
        expect(find.textContaining('$label: mean ΔE '), findsOneWidget, reason: label);
      }
      expect(find.textContaining('skin'), findsNWidgets(3));
      expect(find.textContaining('worst'), findsNWidgets(3));
      expect(find.textContaining('score'), findsNWidgets(3));
      await _until(tester, find.byKey(const ValueKey('calibrate-result-photo')));
      expect(served.settings.calls, isEmpty, reason: 'nothing is written before Save');

      await _tap(tester, find.text('Save'));
      await _untilGone(tester, _dialog());
      expect(_dialog(), findsNothing);

      final calls = served.settings.calls;
      final colourCalls = calls.where((c) => c.startsWith('SetColourCorrection')).toList();
      expect(colourCalls, ['SetColourCorrection all', 'SetColourCorrection neighbours', 'SetColourCorrection glare_free']);
      expect(calls.indexOf(colourCalls.first), calls.length - 3, reason: 'the mix first, then the matrices');
      expect(calls.where((c) => c.startsWith('SetIntensity')), isNotEmpty, reason: 'the simulated best is a move');
      final winner = served.settings.colour.first.measurement;
      for (final r in served.settings.colour) {
        expect(r.measurement.method, 'auto');
        expect(r.measurement.chart, 'spyder24');
        expect(r.measurement.camera, _middleCamera);
      }
      // the snapshot and the card follow
      final s = SettingsState.current!;
      expect([s.intensityRed, s.intensityGreen, s.intensityBlue], [winner.ledRed, winner.ledGreen, winner.ledBlue]);
      expect(s.colourCorrections.every((c) => c.source == 'kiosk'), isTrue);
      expect(find.text('shipped'), findsNothing);
    });
  });

  testWidgets('a lost card falls back to the taps', (tester) async {
    await tester.runAsync(() async {
      final chart = testChart();
      final served = await _pumpCard(tester, _settings(photoLight: 'neighbours'),
          kiosk: _Kiosk(_sim(), lose: (r) => r.light == 'neighbours'));
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      // three attempts, then the four taps on the last photo
      await _until(tester, find.byKey(const ValueKey('photo-colour-photo')), seconds: 60);
      expect(served.kiosk!.requests.where((r) => r.light == 'neighbours'), hasLength(cardAttempts));
      for (final p in chart.corners) {
        await tapPhotoAt(tester, chart.image, p);
      }
      await _settle(tester);
      await _tap(tester, find.text('Use the taps'));
      await _until(tester, find.text('Save'), seconds: 30);
      expect(find.textContaining('Standard (neighbours): mean ΔE '), findsOneWidget);
      expect(find.textContaining('(taps)'), findsOneWidget);

      await _tap(tester, find.text('Save'));
      await _untilGone(tester, _dialog());
      final byLight = {for (final r in served.settings.colour) r.light: r.measurement};
      expect(byLight.keys, ['all', 'neighbours']);
      expect(byLight['all']!.method, 'auto');
      expect(byLight['neighbours']!.method, 'taps');
    });
  });

  testWidgets('a later photo refused by its greys stops the run with the note and opens no taps', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, _settings(photoLight: 'neighbours'),
          kiosk: _Kiosk(_sim(), lose: (r) => r.light == 'neighbours', loseNote: greysNote));
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      await _until(tester, find.text('$_greysNote, then press Retry'), seconds: 60);
      // the taps would read the same photo with the same grey check: none are offered
      expect(find.byKey(const ValueKey('photo-colour-photo')), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(served.kiosk!.requests.where((r) => r.light == 'neighbours'), hasLength(cardAttempts));
      expect(served.settings.calls, isEmpty);
    });
  });

  testWidgets('a card not found keeps the taps title as it was', (tester) async {
    await tester.runAsync(() async {
      await _pumpCard(tester, _settings(photoLight: 'neighbours'),
          kiosk: _Kiosk(_sim(), lose: (r) => r.light == 'neighbours'));
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      await _until(tester, find.byKey(const ValueKey('photo-colour-photo')), seconds: 60);
      expect(find.text('Colour correction · the card was not found: tap its four corner patches'), findsOneWidget);
      expect(find.textContaining('seen'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('a first photo refused by its greys stops the run with the note', (tester) async {
    await tester.runAsync(() async {
      await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim(), lose: (_) => true, loseNote: greysNote));
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      await _until(tester, find.text('$_greysNote, then press Retry'), seconds: 30);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  testWidgets('the fixed-exposure warning shows with automatic exposure off and never blocks Start', (tester) async {
    await tester.runAsync(() async {
      await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim()), autoExposure: false);
      await _openCalibrate(tester);
      await _until(tester, find.text(fixedExposureWarning));
      expect(find.text(fixedExposureWarning), findsOneWidget);
      expect(_onPressed(tester, 'Start'), isNotNull, reason: 'a warning only');
      await tester.pumpWidget(const SizedBox());
    });
    await tester.runAsync(() async {
      await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim()), autoExposure: true);
      await _openCalibrate(tester);
      await _settle(tester, rounds: 10);
      expect(find.text(fixedExposureWarning), findsNothing);
      expect(_onPressed(tester, 'Start'), isNotNull);
    });
  });

  testWidgets('the fixed-exposure warning reads as the plan says', (tester) async {
    await tester.runAsync(() async {
      await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim()), autoExposure: false);
      await _openCalibrate(tester);
      await _until(tester, find.textContaining('Automatic exposure is off'));
      expect(
          find.text('Automatic exposure is off: the card photos use the fixed exposure and can be too dark under '
              'the glare-free light. Turn it on in Camera for the calibration.'),
          findsOneWidget);
    });
  });

  testWidgets('a camera that cannot be read shows no warning and leaves Start enabled', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim()), cameraFails: true);
      await _openCalibrate(tester);
      await _settle(tester, rounds: 10);
      expect(served.camera.loads, greaterThan(0), reason: 'the read was tried');
      expect(find.text(fixedExposureWarning), findsNothing);
      expect(find.textContaining('Automatic exposure'), findsNothing);
      expect(_onPressed(tester, 'Start'), isNotNull);
    });
  });

  testWidgets('Cancel during the run stores nothing', (tester) async {
    await tester.runAsync(() async {
      final kiosk = _Kiosk(_sim(), holdAt: 2);
      final served = await _pumpCard(tester, _settings(), kiosk: kiosk);
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      final end = DateTime.now().add(const Duration(seconds: 30));
      while (kiosk.requests.length < 3) {
        if (DateTime.now().isAfter(end)) fail('the run did not reach the third photo');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
      expect(find.text('LED mix'), findsOneWidget, reason: 'the progress names the step');
      await _tap(tester, find.text('Cancel'));
      kiosk.hold.complete();
      await _untilGone(tester, _dialog());
      await _settle(tester, rounds: 10);
      expect(_dialog(), findsNothing);
      expect(kiosk.requests, hasLength(3), reason: 'no photo after Cancel');
      expect(served.settings.calls, isEmpty);
      expect(SettingsState.current!.intensityRed, _kioskMix.red);
    });
  });

  testWidgets('a Save with a write failure offers Retry', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim()));
      served.settings.failColour = 1;
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      await _until(tester, find.text('Save'), seconds: 60);
      await _tap(tester, find.text('Save'));
      await _until(tester, find.text('Retry'));
      expect(find.textContaining('colour correction Standard (all LEDs) failed'), findsOneWidget);
      expect(find.textContaining('the board did not answer'), findsOneWidget);
      final intensities = served.settings.calls.where((c) => c.startsWith('SetIntensity')).toList();
      expect(intensities, isNotEmpty);
      expect(find.textContaining('Already stored: LED'), findsOneWidget);

      await _tap(tester, find.text('Retry'));
      await _untilGone(tester, _dialog());
      // the stored writes are not sent again
      expect(served.settings.calls, [...intensities, 'SetColourCorrection all', 'SetColourCorrection all']);
      expect(served.settings.colour.single.light, 'all');
    });
  });

  testWidgets('a card the finder cannot find stops the run with its text and Retry', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim(), lose: (_) => true));
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      await _until(tester, find.text(cardNotFoundAutomatically), seconds: 30);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(served.kiosk!.requests, hasLength(cardAttempts));
      await _tap(tester, find.text('Retry'));
      await _until(tester, find.text(cardNotFoundAutomatically), seconds: 30);
      expect(served.kiosk!.requests, hasLength(2 * cardAttempts), reason: 'Retry runs again');
      await _tap(tester, find.text('Cancel'));
      expect(_dialog(), findsNothing);
      expect(served.settings.calls, isEmpty);
    });
  });

  testWidgets("the camera's automatic white balance skips the tint", (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, _settings(glareFree: GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE),
          kiosk: _Kiosk(_sim()), autoWhiteBalance: true);
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      await _until(tester, find.text('Save'), seconds: 60);
      expect(find.text(tintSkippedAuto), findsOneWidget);
      expect(served.kiosk!.requests.where((r) => r.hasWhiteBalance()), isEmpty);
      expect(find.textContaining('Glare-free: mean ΔE '), findsOneWidget);
    });
  });

  testWidgets('a run that changes nothing says so and offers no Save', (tester) async {
    await tester.runAsync(() async {
      await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim(), perfect: true));
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      await _until(tester, find.text('Discard'), seconds: 60);
      expect(find.textContaining(mixAlreadyBest), findsOneWidget);
      expect(find.textContaining('Standard (all LEDs): not changed: $refusalNoImprovement'), findsOneWidget);
      expect(find.text(nothingToSave), findsOneWidget);
      expect(_onPressed(tester, 'Save'), isNull);
      await _tap(tester, find.text('Discard'));
      expect(_dialog(), findsNothing);
    });
  });

  testWidgets('two taps in one frame start one run and send one Save', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim()));
      await _openCalibrate(tester);
      final start = find.text('Start');
      await tester.tap(start);
      await tester.tap(start);
      await _until(tester, find.text('Save'), seconds: 60);
      await _settle(tester, rounds: 10);
      final kiosk = served.kiosk!;
      expect(kiosk.requests.where((r) => r.camera == 0), hasLength(1), reason: 'one Find the card');
      final save = find.text('Save');
      await tester.tap(save);
      await tester.tap(save);
      await _untilGone(tester, _dialog());
      await _settle(tester, rounds: 10);
      expect(served.settings.calls.where((c) => c == 'SetColourCorrection all'), hasLength(1));
      expect(served.settings.calls.toSet(), hasLength(served.settings.calls.length), reason: 'no write sent twice');
    });
  });

  testWidgets('the dialog removed mid-run takes no further photo', (tester) async {
    await tester.runAsync(() async {
      final kiosk = _Kiosk(_sim(), holdAt: 2);
      final served = await _pumpCard(tester, _settings(), kiosk: kiosk);
      await _openCalibrate(tester);
      await _tap(tester, find.text('Start'));
      final end = DateTime.now().add(const Duration(seconds: 30));
      while (kiosk.requests.length < 3) {
        if (DateTime.now().isAfter(end)) fail('the run did not reach the third photo');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox());
      kiosk.hold.complete();
      await _settle(tester, rounds: 20);
      expect(kiosk.requests, hasLength(3), reason: 'no photo after the dialog is gone');
      expect(served.settings.calls, isEmpty);
    });
  });

  testWidgets('Cancel after a failed Save pops null when nothing was stored, false when a part was',
      (tester) async {
    for (final (failFirst, expected) in [(true, null), (false, false)]) {
      await tester.runAsync(() async {
        final popped = <bool?>[];
        final served = await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim()), home: _host(popped));
        if (failFirst) {
          served.settings.failWrites = 1; // the first LED write fails: nothing stored
        } else {
          served.settings.failColour = 1; // the LED mix stored, the matrix not
        }
        await _tap(tester, find.text('Open'));
        await _until(tester, find.text('Start'));
        await _tap(tester, find.text('Start'));
        await _until(tester, find.text('Save'), seconds: 60);
        await _tap(tester, find.text('Save'));
        await _until(tester, find.text('Retry'));
        expect(failFirst ? find.text('Nothing was stored.') : find.textContaining('Already stored: LED'),
            findsOneWidget);
        await _tap(tester, find.text('Cancel'));
        await _untilGone(tester, _dialog());
        expect(popped, [expected], reason: failFirst ? 'nothing stored' : 'a part stored');
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  testWidgets('the card choice is remembered and the Classic run records its version', (tester) async {
    await tester.runAsync(() async {
      final served = await _pumpCard(tester, _settings(), kiosk: _Kiosk(_sim(classicReference('2014'))));
      await _openCalibrate(tester);
      await _tap(tester, _inDialog(find.byKey(const ValueKey('colour-card'))));
      await _tap(tester, find.text('ColorChecker Classic').last);
      expect(AppConfig.colourCard, 'classic');
      await _tap(tester, _inDialog(find.byKey(const ValueKey('colour-card-version'))));
      await _tap(tester, find.text('November 2014 or later').last);
      expect(AppConfig.colourCardVersion, '2014');
      await _tap(tester, find.text('Start'));
      await _until(tester, find.text('Save'), seconds: 60);
      expect(served.kiosk!.requests.every((r) => r.card == 'classic'), isTrue);
      await _tap(tester, find.text('Save'));
      await _untilGone(tester, _dialog());
      final m = served.settings.colour.single.measurement;
      expect(m.chart, 'classic');
      expect(m.cardVersion, '2014');
    });
  });
}
