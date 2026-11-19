// Developer-mode popups: every </> badge on a page has a topic, and every
// topic's popup lays out (summary, every snippet tab) without an overflow at a
// small desktop window size.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/ui/dev_info.dart';

void main() {
  test('every DevInfoBadge on a page names a topic', () {
    final badge = RegExp(r"DevInfoBadge\('([^']+)'\)");
    final used = <String>{
      for (final file in Directory('lib/pages').listSync().whereType<File>())
        for (final m in badge.allMatches(file.readAsStringSync())) m.group(1)!,
    };
    expect(used, isNotEmpty);
    expect(
      used.difference(devTopicIds.toSet()),
      isEmpty,
      reason: 'badges without a topic render nothing',
    );
  });

  testWidgets('every topic popup renders all its tabs without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DevMode.enabled.value = true;
    addTearDown(() => DevMode.enabled.value = false);

    for (final id in devTopicIds) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: DevInfoBadge(id))),
        ),
      );
      await tester.tap(find.byType(DevInfoBadge));
      await tester.pumpAndSettle();
      expect(find.textContaining('Implementing: '), findsOneWidget, reason: id);
      expect(tester.takeException(), isNull, reason: '$id: first tab');

      // Every snippet tab: the labels are the only texts with these prefixes.
      final tabs = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            RegExp(r'^(C#|Dart|Shell|Protocol|Stream)').hasMatch(w.data ?? ''),
      );
      final count = tabs.evaluate().length;
      expect(count, greaterThanOrEqualTo(2), reason: id);
      for (var i = 0; i < count; i++) {
        await tester.tap(tabs.at(i));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$id: tab $i');
      }

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }
  });

  test('the capture topics name the face-angle row and its result', () {
    final source = File('lib/ui/dev_info.dart').readAsStringSync();
    expect(source, contains('Live person check (face angle)'));
    expect(source, contains('liveness_face_angle'));
  });

  test('no topic mentions the removed light checks', () {
    final source = File('lib/ui/dev_info.dart').readAsStringSync();
    for (final gone in ['shadingCheck', 'colourCheck', 'liveness_colour', 'livenessShadingCheck', 'light-check']) {
      expect(source, isNot(contains(gone)), reason: gone);
    }
  });

  test('the example capture stream carries the head-turn result row', () {
    final source = File('lib/ui/dev_info.dart').readAsStringSync();
    expect(source,
        matches(RegExp(r'Live person check \(head turn\): passed[^\n]*LIVENESS liveness_head_turn')));
  });

  test('the example capture stream shows the head turn after the photo frame and before the photo', () {
    // Task 10b: the photo frame is taken first, the head turn runs on the frames after it,
    // and the photo is sent after the head turn - so the client still sees the
    // instructions before the photo and the head-turn row after it.
    final source = File('lib/ui/dev_info.dart').readAsStringSync();
    final taking = source.indexOf('Taking a high res photo using camera 3');
    final turn = source.indexOf('Turn your head to the left ', taking);
    final done = source.indexOf('Instruction DONE', taking);
    final photo = source.indexOf('<the photo>', taking);
    final row = source.indexOf('Live person check (head turn): passed', taking);
    expect(taking, greaterThan(0));
    expect(turn, greaterThan(taking));
    expect(done, greaterThan(turn));
    expect(photo, greaterThan(done));
    expect(row, greaterThan(photo));
    expect(source, contains('the photo frame is taken first'));
  });

  test('the calibration topic shows the hub switch and the surroundings calls', () {
    // Spec 2026-10-15 sections 2 and 7: a badge snippet for each new call, C# and Dart.
    final source = File('lib/ui/dev_info.dart').readAsStringSync();
    for (final name in [
      'SetCameraHubUpsideDown(true)',
      'setCameraHubUpsideDown(',
      'CameraHubUpsideDownRequest(upsideDown: true)',
      'CalibrateBySurroundings()',
      'calibrateBySurroundings(',
      'SetCameraOrderingMode("surroundings")',
    ]) {
      expect(source, contains(name), reason: name);
    }
  });

  test('the lighting topic names the glare-free light and its white balance', () {
    final source = File('lib/ui/dev_info.dart').readAsStringSync();
    for (final name in [
      'SetGlareFreeLight',
      'SetGlareFreeWhiteBalance',
      'GlareFreeLight.Everyone',
      'GLARE_FREE_LIGHT_EVERYONE',
      'fades out for the photo',
    ]) {
      expect(source, contains(name), reason: name);
    }
    expect(source, isNot(contains('SetGlassesLightsOff(true)')));
    expect(source, isNot(contains('setGlassesLightsOff(')));
  });

  test('the backlights topic names both outputs, the dimming and the new calls', () {
    expect(devTopicIds, contains('backlights'));
    final source = File('lib/ui/dev_info.dart').readAsStringSync();
    for (final name in [
      'Lights.SetBacklight / GetBacklights / SetBacklightBrightness',
      'board_qwst',
      'board_header',
      'backlight_brightness',
      'SetBacklightBrightness("glare_free"',
      'SetBacklight(Backlight.Bottom, true, 60)',
      'setBacklightBrightness(BacklightBrightnessRequest(',
      'percent: 60',
      'Dimming needs backlights on the LED board',
    ]) {
      expect(source, contains(name), reason: name);
    }
    expect(source, isNot(contains("rpc: 'Lights.SetBacklight / GetBacklights',")));
  });

  test('the photo colour topic names the colour RPCs and the per-capture field', () {
    expect(devTopicIds, contains('photo-colour'));
    final source = File('lib/ui/dev_info.dart').readAsStringSync();
    for (final name in [
      'SetColourCorrection',
      'ClearColourCorrection',
      'SetColourCorrectionEnabled',
      'colour_correction = 27',
      'colourCorrection: false',
    ]) {
      expect(source, contains(name), reason: name);
    }
    expect(source, isNot(contains('26 fields')));
  });
}
