// The Capture page and a quality report: what is wrong leads the list. An OFIQ
// measure that needs attention turns the report's own row amber (the overall score
// alone can be high for a dark or discoloured photo), the failing rows and the
// server's advice sit directly under that row, and the rows that passed follow.
// Against an in-process fake server over a real loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/capture_page.dart';
import 'package:operator_app/services/settings_state.dart';

class _FakeKiosk extends KioskServiceBase {
  List<String> lines = const [];

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
      ServiceCall call, Empty request) async* {
    for (final line in lines) {
      yield ProcessAutomaticResponse(
          processStatus: ProcessStepStatus(
              index: 4, description: line, status: StatusType.OK));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _FakeSettings extends SettingsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

// One server and one client connection for the whole file, never shut down: see
// icao_report_test.dart for the http2 assertion that closing one triggers.
final _kiosk = _FakeKiosk();

Future<void> _settle(WidgetTester tester, [int ticks = 20]) async {
  for (var i = 0; i < ticks; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Future<void> _capture(WidgetTester tester, List<String> lines,
    {bool icaoReport = false, bool report = true}) async {
  tester.view.physicalSize = const Size(1900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  _kiosk.lines = lines;
  SettingsState.current =
      LoadSettingsResponse(
          icaoReport: report && icaoReport,
          ofiqChecks: report && !icaoReport,
          headPoseCheck: true,
          lipsCheck: true);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CapturePage())));
  await tester.pump();
  await tester.tap(find.text('Automatic'));
  for (var i = 0; i < 100 && find.text(lines.last).evaluate().isEmpty; i++) {
    await _settle(tester, 1);
  }
  await _settle(tester, 5);
}

String _glyphOf(WidgetTester tester, String text) {
  final row = find.ancestor(of: find.text(text), matching: find.byType(Row)).first;
  for (final glyph in const ['!', 'i', '✓', '✕', '•', '→']) {
    if (find.descendant(of: row, matching: find.text(glyph)).evaluate().isNotEmpty) {
      return glyph;
    }
  }
  return '?';
}

double _top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

const _overall = 'OFIQ overall quality: 61/100 - passed (min 30)';
const _sharp = 'OFIQ Sharpness: 90/100 - passed (min 70)';
const _dark = 'OFIQ Luminance mean: 5/100 - attention (min 50)';
const _colour = 'OFIQ Natural colour: 0/100 - attention (min 50)';
const _eyes = 'OFIQ Eyes open: 100/100 - passed (min 85)';
const _adviceColour = 'Advice: skin colour too blue - raise the white balance '
    'temperature (now 4275) towards 6500 (Camera page)';
const _adviceDark = 'Advice: face too dark with the exposure at its limit - raise '
    'the LED intensity (Lighting page) or add light in front of the person';

void main() {
  setUpAll(() async {
    final server = Server.create(services: [_kiosk, _FakeSettings()]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
    await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  });

  test('the headline names how many measures need attention', () {
    expect(ofiqHeadline(_overall, 0), _overall);
    expect(ofiqHeadline(_overall, 1), '$_overall - 1 measure needs attention');
    expect(ofiqHeadline(_overall, 3), '$_overall - 3 measures need attention');
    expect(isAdviceRow(_adviceDark), isTrue);
    expect(isAdviceRow(_dark), isFalse);
  });

  testWidgets('a failing measure turns the OFIQ row amber and leads the list',
      (tester) async {
    const headline = '$_overall - 2 measures need attention';
    await tester.runAsync(() async {
      await _capture(tester, [
        'Distance in cm: 61',
        'Scoring the photo with OFIQ (ISO/IEC 29794-5)...',
        _overall,
        _sharp,
        _dark,
        _eyes,
        _colour,
        _adviceColour,
        _adviceDark,
      ]);
      // The overall score passed, but two measures did not: amber, with the count.
      expect(find.text(_overall), findsNothing);
      expect(_glyphOf(tester, headline), '!');
      expect(_glyphOf(tester, _dark), '!');
      expect(_glyphOf(tester, _sharp), '✓');
      expect(_glyphOf(tester, _adviceColour), '→');

      // Under the report's row: the advice (server order), the failing measures
      // (server order), and only then the measures that passed.
      final order = [headline, _adviceColour, _adviceDark, _dark, _colour, _sharp, _eyes]
          .map((text) => _top(tester, text))
          .toList();
      expect(order, List.of(order)..sort(), reason: 'rows are not in that order');
    });
  });

  testWidgets('a photo that passes every measure keeps a green OFIQ row',
      (tester) async {
    await tester.runAsync(() async {
      await _capture(tester, [
        'Distance in cm: 61',
        'Scoring the photo with OFIQ (ISO/IEC 29794-5)...',
        _overall,
        _sharp,
        _eyes,
      ]);
      expect(_glyphOf(tester, _overall), '✓');
    });
  });

  testWidgets('without a report, a failed check leads the checks under the camera row',
      (tester) async {
    const camera = 'Camera 4 selected — taking a high res photo';
    const distance = 'Distance in cm: 61';
    const lips = 'Lips are closed (certainty 97%)';
    const pose = 'Head pose frontal: False (yaw 20, pitch 0, roll 0)';
    await tester.runAsync(() async {
      await _capture(tester, [
        'Taking a high res photo using camera 4',
        distance,
        lips,
        pose,
      ], report: false);
      expect(_glyphOf(tester, pose), '✕');
      // the camera row stays on top of everything (2026-10-06); the failed
      // check leads the rows under it
      final order =
          [camera, pose, distance, lips].map((text) => _top(tester, text)).toList();
      expect(order, List.of(order)..sort(), reason: 'rows are not in that order');
    });
  });

  testWidgets('the ICAO report puts its attention rows and the advice first',
      (tester) async {
    const compliance = 'ICAO compliance: attention (1 of 19 requirements: exposure)';
    const focus = 'ICAO Sharp focus: passed (Sharpness 90/100)';
    const exposure = 'ICAO Exposure: attention (Luminance mean 5/100, min 50)';
    const gaze = 'ICAO Looking at the camera: passed (gaze offset 4%)';
    await tester.runAsync(() async {
      await _capture(tester, [
        'Distance in cm: 61',
        'Scoring the photo with OFIQ (ISO/IEC 29794-5)...',
        compliance,
        focus,
        exposure,
        gaze,
        _adviceDark,
      ], icaoReport: true);
      expect(_glyphOf(tester, _adviceDark), '→');
      final order = [compliance, _adviceDark, exposure, focus, gaze]
          .map((text) => _top(tester, text))
          .toList();
      expect(order, List.of(order)..sort(), reason: 'rows are not in that order');
    });
  });
}
