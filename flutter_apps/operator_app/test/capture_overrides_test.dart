// The Capture page's "Only for this capture" panel (per-capture settings): only
// the changed fields are sent, Clear empties the panel and the badge, a manual
// capture sends only its five fields, the settings-used card marks the
// overrides, an older server's refusal keeps the panel, and nothing of it ever
// reaches a settings setter. Against in-process fake Kiosk and Settings servers
// over a real loopback connection.
import 'dart:async';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, ServiceCall;
import 'package:operator_app/pages/capture_overrides.dart';
import 'package:operator_app/pages/capture_page.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/ui/ui.dart';

import 'fake_server.dart';

const _gaveUp =
    'Could not take the photo with camera 4: the mouth was open in 30 of 30 frames, Please try again';

ProcessStepStatus _status(String text) =>
    ProcessStepStatus(index: 4, description: text, status: StatusType.OK);

class _FakeKiosk extends KioskServiceBase {
  _FakeKiosk({this.perCapture = true});

  /// false = a server from before per-capture settings: the new RPCs are
  /// UNIMPLEMENTED (noSuchMethod below).
  final bool perCapture;

  /// The INVALID_ARGUMENT text the new RPCs answer with; null = accepted.
  String? refusal;

  /// The settings-used message sent first by the new RPCs; null = none.
  CaptureSettingsUsed? used;

  /// One entry per capture: the request's settings, or null for the old RPCs.
  final List<CaptureSettings?> automatic = [];
  final List<CaptureSettings?> manual = [];

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
    ServiceCall call,
    Empty request,
  ) async* {
    automatic.add(null);
    yield ProcessAutomaticResponse(processStatus: _status(_gaveUp));
  }

  @override
  Stream<ProcessManualResponse> startManualProcess(
    ServiceCall call,
    Empty request,
  ) async* {
    manual.add(null);
    yield ProcessManualResponse(processStatus: _status('Manual done'));
  }

  @override
  Stream<ProcessAutomaticResponse> startAutomaticCapture(
    ServiceCall call,
    CaptureRequest request,
  ) async* {
    if (!perCapture) throw GrpcError.unimplemented('StartAutomaticCapture');
    if (refusal != null) throw GrpcError.invalidArgument(refusal);
    automatic.add(request.settings);
    if (used != null) yield ProcessAutomaticResponse(settingsUsed: used);
    yield ProcessAutomaticResponse(processStatus: _status(_gaveUp));
  }

  @override
  Stream<ProcessManualResponse> startManualCapture(
    ServiceCall call,
    CaptureRequest request,
  ) async* {
    if (!perCapture) throw GrpcError.unimplemented('StartManualCapture');
    if (refusal != null) throw GrpcError.invalidArgument(refusal);
    manual.add(request.settings);
    yield ProcessManualResponse(processStatus: _status('Manual done'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

LoadSettingsResponse _kioskSettings() => LoadSettingsResponse(
  photoFormat: 'icao_35x45',
  crop: true,
  cropWidth: 700,
  jpegQuality: 95,
  backgroundMethod: 'modnet',
  backgroundColor: 'FFFFFF',
  backgroundStrength: 3,
  photoLight: 'all',
  glareFreeLight: GlareFreeLight.GLARE_FREE_LIGHT_OFF,
  colourCorrection: true,
  colourCorrections: [ColourCorrectionState(light: 'all', source: 'shipped')],
  eyesCheck: true,
  lipsCheck: true,
  distanceMin: 40,
  distanceMax: 60,
);

/// Answers LoadSettings with the kiosk's settings and records every call by
/// its method name; any other call is UNIMPLEMENTED.
class _RecordingSettings extends SettingsServiceBase {
  final List<String> calls = [];

  @override
  Future<LoadSettingsResponse> loadSettings(
    ServiceCall call,
    Empty request,
  ) async {
    calls.add('loadSettings');
    return _kioskSettings();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Symbol("setJpegQuality") -> setJpegQuality
    final name = '${invocation.memberName}';
    calls.add(name.substring(8, name.length - 2));
    throw GrpcError.unimplemented(name);
  }
}

Future<_FakeKiosk> _openPage(
  WidgetTester tester, {
  bool perCapture = true,
  _RecordingSettings? settings,
  bool openPanel = true,
}) async {
  tester.view.physicalSize = const Size(1900, 1100);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final kiosk = _FakeKiosk(perCapture: perCapture);
  final server = await serveFakes([kiosk, ?settings]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  addTearDown(
    () => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()),
  );
  SettingsState.current = _kioskSettings();
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: CapturePage())),
  );
  await tester.pump();
  // The panel is collapsed while no override is set: open it to edit.
  if (openPanel) await _togglePanel(tester);
  return kiosk;
}

Finder get _toggle => find.byKey(const ValueKey('overrides-toggle'));

Future<void> _togglePanel(WidgetTester tester) async {
  await tester.tap(_toggle);
  await tester.pump();
}

int get _count => CaptureOverrides.count;

GoButton _goButton(WidgetTester tester, String text) =>
    tester.widget<GoButton>(find.widgetWithText(GoButton, text));

/// Real time for the loopback gRPC stream; call inside tester.runAsync.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Finder _field(String name) => find.byKey(ValueKey('override-$name'));

/// Picks [value] in a choice field's dropdown ('' = Kiosk).
Future<void> _choose(WidgetTester tester, String name, String value) async {
  tester.widget<DropdownButton<String>>(_field(name)).onChanged!(value);
  await tester.pump();
}

/// Taps 'Kiosk', 'On' or 'Off' of a yes/no field.
Future<void> _flag(WidgetTester tester, String name, String segment) async {
  final target = find.descendant(
    of: _field(name),
    matching: find.text(segment),
  );
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String name, String text) async {
  await tester.enterText(_field(name), text);
  await tester.pump();
}

Finder get _badge => find.byKey(const ValueKey('override-badge'));

String _badgeText(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: _badge, matching: find.byType(Text)))
    .data!;

/// Every per-capture field set, as an automatic capture's settings used.
CaptureSettings _allValues() => CaptureSettings(
  photoFormat: 'us_2x2',
  crop: true,
  cropWidth: 700,
  jpegQuality: 80,
  backgroundMethod: 'modnet',
  backgroundColor: 'FFFFFF',
  backgroundStrength: 3,
  glareFreeLight: 'off',
  photoLight: 'all',
  ledsOffForPhoto: false,
  eyesCheck: true,
  lipsCheck: true,
  eyeGlassesCheck: false,
  headPoseCheck: false,
  sharpnessCheck: false,
  redEyeDetectionCheck: false,
  headSizeCheck: false,
  expressionCheck: false,
  gazeCheck: false,
  lightingEvennessCheck: false,
  ofiqChecks: false,
  icaoReport: false,
  livenessCheck: true,
  livenessHeadTurnCheck: false,
  distanceMin: 40,
  distanceMax: 60,
  colourCorrection: true,
  lap: LapSubject.LAP_NONE,
);

void main() {
  setUp(CaptureOverrides.clear);
  tearDown(CaptureOverrides.clear);

  test(
    'the panel lists every per-capture field by its proto name and number',
    () {
      final info = CaptureSettings().info_;
      expect(overrideFields, hasLength(28));
      for (final f in overrideFields) {
        expect(info.fieldInfo[f.number]?.protoName, f.name, reason: f.name);
      }
      expect(
        [
          for (final f in overrideFields)
            if (f.manual) f.name,
        ],
        [
          'jpeg_quality',
          'glare_free_light',
          'photo_light',
          'leds_off_for_photo',
          'colour_correction',
        ],
      );
    },
  );

  testWidgets('the panel sends only what was changed', (tester) async {
    await tester.runAsync(() async {
      final kiosk = await _openPage(tester);
      expect(find.text('ONLY FOR THIS CAPTURE'), findsOneWidget);
      // Unset fields show the kiosk's value, greyed.
      expect(find.text('Kiosk: icao_35x45'), findsOneWidget);
      expect(_badge, findsNothing);

      await _choose(tester, 'photo_format', 'us_2x2');
      await _type(tester, 'jpeg_quality', '80');
      await _flag(tester, 'crop', 'Off');
      // A change taken back is not sent.
      await _choose(tester, 'background_method', 'withoutbg');
      await _choose(tester, 'background_method', '');
      expect(_badgeText(tester), '3 overrides');

      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      expect(kiosk.automatic, [
        CaptureSettings(photoFormat: 'us_2x2', jpegQuality: 80, crop: false),
      ]);
      // The panel stays for the next capture.
      expect(_badgeText(tester), '3 overrides');
    });
  });

  testWidgets('capture overrides offer gridler', (tester) async {
    // The Gridler eraser, the fourth eraser, is one of the per-capture choices.
    await tester.runAsync(() async {
      final kiosk = await _openPage(tester);
      final method = tester.widget<DropdownButton<String>>(
        _field('background_method'),
      );
      expect(
        [for (final i in method.items!) i.value],
        ['', 'none', 'mediapipe', 'modnet', 'withoutbg', 'gridler'],
      );

      await _choose(tester, 'background_method', 'gridler');
      expect(_badgeText(tester), '1 override');
      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      expect(kiosk.automatic, [CaptureSettings(backgroundMethod: 'gridler')]);
    });
  });

  testWidgets('the child-on-lap choice sends lap; none sends nothing', (
    tester,
  ) async {
    // A child on a parent's lap (spec 2026-10-19 section 3.5): none / child / baby.
    await tester.runAsync(() async {
      final kiosk = await _openPage(tester);
      final lap = tester.widget<DropdownButton<String>>(_field('lap'));
      expect([for (final item in lap.items!) item.value], ['', 'child', 'baby']);
      expect(lap.value, '');
      expect(
        find.descendant(of: _field('lap'), matching: find.text('none')),
        findsOneWidget,
      );

      await _choose(tester, 'lap', 'baby');
      expect(_badgeText(tester), '1 override');
      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      await _choose(tester, 'lap', 'child');
      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      // "none" is no field at all: the capture is the old call.
      await _choose(tester, 'lap', '');
      expect(_badge, findsNothing);
      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      expect(kiosk.automatic, [
        CaptureSettings(lap: LapSubject.LAP_BABY),
        CaptureSettings(lap: LapSubject.LAP_CHILD),
        null,
      ]);

      // A manual capture never sends it (automatic capture only).
      await _choose(tester, 'lap', 'child');
      await tester.tap(find.text('Manual'));
      await _settle(tester);
      expect(kiosk.manual.last, isNull);
    });
  });

  test('the settings used show the lap by its choice', () {
    expect(overrideValueText(LapSubject.LAP_NONE), 'none');
    expect(overrideValueText(LapSubject.LAP_CHILD), 'child');
    expect(overrideValueText(LapSubject.LAP_BABY), 'baby');
  });

  testWidgets('Clear empties the panel and the badge', (tester) async {
    await tester.runAsync(() async {
      final kiosk = await _openPage(tester);
      await _choose(tester, 'photo_light', 'neighbours');
      await _type(tester, 'distance_min', '35');
      expect(_badgeText(tester), '2 overrides');

      await tester.ensureVisible(find.byKey(const ValueKey('overrides-clear')));
      await tester.tap(find.byKey(const ValueKey('overrides-clear')));
      await tester.pump();
      expect(_badge, findsNothing);
      expect(CaptureOverrides.count, 0);
      expect(
        tester.widget<TextField>(_field('distance_min')).controller!.text,
        '',
      );
      expect(
        tester.widget<DropdownButton<String>>(_field('photo_light')).value,
        '',
      );

      // Without overrides the capture is the old call.
      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      expect(kiosk.automatic, [null]);
    });
  });

  testWidgets('a manual capture sends only the five manual fields', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final kiosk = await _openPage(tester);
      expect(
        find.text(
          'Manual captures use only JPEG quality, the glare-free '
          'light, the photo light, LEDs off and the colour correction',
        ),
        findsOneWidget,
      );
      await _choose(tester, 'photo_format', 'ca_50x70');
      await _type(tester, 'jpeg_quality', '70');
      await _choose(tester, 'glare_free_light', 'everyone');
      await _flag(tester, 'leds_off_for_photo', 'On');
      await _flag(tester, 'eyes_check', 'Off');
      expect(_badgeText(tester), '5 overrides');

      await tester.tap(find.text('Manual'));
      await _settle(tester);
      expect(kiosk.manual, [
        CaptureSettings(
          jpegQuality: 70,
          glareFreeLight: 'everyone',
          ledsOffForPhoto: true,
        ),
      ]);

      // An empty panel: no settings at all, the older StartManualProcess.
      CaptureOverrides.clear();
      await tester.pump();
      await tester.tap(find.text('Manual'));
      await _settle(tester);
      expect(kiosk.manual.last, isNull);
    });
  });

  testWidgets('the overrides panel offers colour correction for manual captures', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final kiosk = await _openPage(tester);
      // The kiosk's switch, greyed, among the fields a manual capture uses.
      expect(
        find.descendant(
          of: find
              .ancestor(
                of: _field('colour_correction'),
                matching: find.byType(Column),
              )
              .first,
          matching: find.text('kiosk: on'),
        ),
        findsOneWidget,
      );
      await _flag(tester, 'colour_correction', 'Off');
      await _choose(tester, 'photo_format', 'ca_50x70');
      expect(_badgeText(tester), '2 overrides');

      await tester.tap(find.text('Manual'));
      await _settle(tester);
      expect(kiosk.manual, [CaptureSettings(colourCorrection: false)]);

      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      expect(kiosk.automatic, [
        CaptureSettings(photoFormat: 'ca_50x70', colourCorrection: false),
      ]);
    });
  });

  test('an old server reports no colour correction: the kiosk value is a dash', () {
    expect(kioskValue(LoadSettingsResponse(), 'colour_correction'), isNull);
    expect(
      kioskValue(
        LoadSettingsResponse(
          colourCorrection: false,
          colourCorrections: [ColourCorrectionState(light: 'all')],
        ),
        'colour_correction',
      ),
      isFalse,
    );
  });

  testWidgets('the settings-used card marks the overrides', (tester) async {
    await tester.runAsync(() async {
      final kiosk = await _openPage(tester);
      kiosk.used = CaptureSettingsUsed(
        values: _allValues(),
        overridden: ['photo_format', 'jpeg_quality'],
      );
      expect(find.text('SETTINGS USED'), findsNothing);

      await _choose(tester, 'photo_format', 'us_2x2');
      await _type(tester, 'jpeg_quality', '80');
      await tester.tap(find.text('Automatic'));
      await _settle(tester);

      expect(find.text('SETTINGS USED'), findsOneWidget);
      for (final f in overrideFields) {
        final overridden = f.name == 'photo_format' || f.name == 'jpeg_quality';
        expect(
          find.byKey(ValueKey('override-mark-${f.name}')),
          overridden ? findsOneWidget : findsNothing,
          reason: f.name,
        );
      }
      final mark = tester.widget<Text>(
        find.byKey(const ValueKey('override-mark-photo_format')),
      );
      expect(mark.data, '◆');
      expect(mark.style!.color, T.titleBlue);
      // Every field of the report is listed, with its value.
      Finder inCard(String text) => find.descendant(
        of: find.byKey(const ValueKey('settings-used')),
        matching: find.text(text),
      );
      for (final f in overrideFields) {
        expect(inCard(f.label), findsOneWidget, reason: f.name);
      }
      expect(inCard('us_2x2'), findsOneWidget);
      expect(inCard('80'), findsOneWidget);

      // Clear (the page's) empties the card with the rest of the page.
      await tester.tap(find.byKey(const ValueKey('capture-clear')));
      await tester.pump();
      expect(find.text('SETTINGS USED'), findsNothing);
    });
  });

  testWidgets('an old server shows the message and keeps the panel', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await _openPage(tester, perCapture: false);
      await _choose(tester, 'photo_format', 'us_2x2');

      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      expect(
        find.text('This server does not support per-capture settings'),
        findsOneWidget,
      );
      expect(_badgeText(tester), '1 override');
      expect(
        tester.widget<DropdownButton<String>>(_field('photo_format')).value,
        'us_2x2',
      );
      // The refusal ended the capture: both buttons work again.
      expect(_goButton(tester, 'Automatic').onPressed, isNotNull);
      expect(_goButton(tester, 'Manual').onPressed, isNotNull);
    });
  });

  testWidgets('a refused value shows the server text and keeps the panel', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final kiosk = await _openPage(tester);
      kiosk.refusal =
          'per-capture setting jpeg_quality: jpeg quality should '
          'be between 50 and 100';
      await _type(tester, 'jpeg_quality', '20'); // no client-side rule check

      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      expect(find.textContaining(kiosk.refusal!), findsOneWidget);
      expect(
        tester.widget<TextField>(_field('jpeg_quality')).controller!.text,
        '20',
      );
      expect(_badgeText(tester), '1 override');
    });
  });

  testWidgets('nothing reaches a setter RPC', (tester) async {
    await tester.runAsync(() async {
      final settings = _RecordingSettings();
      final kiosk = await _openPage(tester, settings: settings);
      // The snapshot in force before the capture (the capture replaces
      // SettingsState.current by a fresh LoadSettings, so the check is on
      // this object).
      final snapshot = SettingsState.current!;
      await _choose(tester, 'photo_format', 'us_2x2');
      await _choose(tester, 'background_method', 'withoutbg');
      await _type(tester, 'background_color', '00FF00');
      await _type(tester, 'distance_max', '70');
      await _flag(tester, 'icao_report', 'On');
      await _choose(tester, 'glare_free_light', 'glasses');
      // Editing the panel wrote nothing into the kiosk's snapshot.
      expect(identical(SettingsState.current, snapshot), isTrue);
      expect(snapshot, _kioskSettings());

      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      await tester.tap(find.text('Manual'));
      await _settle(tester);

      expect(kiosk.automatic.single!.photoFormat, 'us_2x2');
      expect(kiosk.manual.single!.glareFreeLight, 'glasses');
      expect(settings.calls, contains('loadSettings'));
      expect(
        settings.calls.where((c) => c.startsWith('set')),
        isEmpty,
        reason: '${settings.calls}',
      );
      // The kiosk's snapshots, before and after, are untouched as well.
      expect(snapshot, _kioskSettings());
      expect(SettingsState.current, _kioskSettings());
    });
  });

  testWidgets(
    'a manual capture without manual fields uses the old call (T14-b)',
    (tester) async {
      await tester.runAsync(() async {
        final kiosk = await _openPage(tester);
        await _choose(tester, 'photo_format', 'us_2x2');
        expect(_badgeText(tester), '1 override');

        await tester.tap(find.text('Manual'));
        await _settle(tester);
        await tester.tap(find.text('Automatic'));
        await _settle(tester);
        expect(kiosk.manual, [null]); // StartManualProcess
        expect(kiosk.automatic, [CaptureSettings(photoFormat: 'us_2x2')]);
      });
    },
  );

  testWidgets('the panel is collapsible (T14-c)', (tester) async {
    await tester.runAsync(() async {
      await _openPage(tester, openPanel: false);
      // Collapsed while no override is set; Clear and the caption stay.
      expect(_field('photo_format'), findsNothing);
      expect(find.byKey(const ValueKey('overrides-clear')), findsOneWidget);

      // The count going from 0 to more opens it.
      CaptureOverrides.set(overrideFields.first, 'us_2x2');
      await tester.pump();
      expect(_field('photo_format'), findsOneWidget);

      // Collapsed by the operator, it stays collapsed on further changes;
      // the badge and Clear stay visible.
      await _togglePanel(tester);
      expect(_field('photo_format'), findsNothing);
      CaptureOverrides.set(
        overrideFields.firstWhere((f) => f.name == 'jpeg_quality'),
        80,
      );
      await tester.pump();
      expect(_field('photo_format'), findsNothing);
      expect(_badgeText(tester), '2 overrides');

      // Built again with overrides set (a page change): open.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CapturePage())),
      );
      await tester.pump();
      expect(_field('photo_format'), findsOneWidget);
      await _togglePanel(tester);

      // Clear works while collapsed.
      await tester.tap(find.byKey(const ValueKey('overrides-clear')));
      await tester.pump();
      expect(_count, 0);
      expect(_badge, findsNothing);
      expect(_field('photo_format'), findsNothing);
    });
  });

  testWidgets('emptying a field or picking Kiosk unsets it', (tester) async {
    await tester.runAsync(() async {
      await _openPage(tester);
      await _type(tester, 'jpeg_quality', '80');
      await _type(tester, 'background_color', 'AABBCC');
      await _flag(tester, 'crop', 'On');
      expect(_count, 3);
      expect(CaptureOverrides.current.crop, isTrue);

      await _type(tester, 'jpeg_quality', '');
      expect(_count, 2);
      expect(CaptureOverrides.current.hasJpegQuality(), isFalse);
      await _type(tester, 'background_color', '');
      expect(_count, 1);
      await _flag(tester, 'crop', 'Kiosk');
      expect(_count, 0);
      expect(CaptureOverrides.current.hasCrop(), isFalse);
      expect(_badge, findsNothing);
    });
  });

  testWidgets('a number the kiosk does not report shows a dash', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await _openPage(tester);
      // An older server reports no background_strength: 0.
      SettingsState.current = _kioskSettings()..clearBackgroundStrength();
      SettingsState.revision.value++;
      await tester.pump();
      final hint = tester
          .widget<TextField>(_field('background_strength'))
          .decoration!
          .hintText;
      expect(hint, '—');
      expect(
        tester.widget<TextField>(_field('jpeg_quality')).decoration!.hintText,
        '95',
      );
    });
  });
}
