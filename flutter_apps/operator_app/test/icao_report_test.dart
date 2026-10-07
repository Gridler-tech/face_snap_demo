// The ICAO compliance report (kiosk.icao_report) in the operator app: the Photo
// page's switch pushes SetIcaoReport and the shared settings snapshot, and the
// Capture page shows the server's "ICAO ..." rows with their verdict - passed
// green, attention amber, and an incomplete report amber, never green. Against
// in-process fake servers over a real loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/capture_page.dart';
import 'package:operator_app/pages/photo_page.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/updater/settings_profile.dart';

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
  final List<bool> calls = [];

  @override
  Future<IcaoReportResponse> setIcaoReport(
      ServiceCall call, IcaoReportRequest request) async {
    calls.add(request.value);
    return IcaoReportResponse(message: request.value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

// ONE server and ONE client connection for the whole file, never shut down (the
// test process ends with the file): closing a connection between tests trips an
// http2 assertion ("_stream2messageQueue.isEmpty") in the NEXT test whenever the
// machine is busy - it failed about one full-suite run in three.
final _kiosk = _FakeKiosk();
final _settings = _FakeSettings();

void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _settle(WidgetTester tester, [int ticks = 20]) async {
  for (var i = 0; i < ticks; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Future<void> _capture(WidgetTester tester, List<String> lines,
    {bool icaoReport = true}) async {
  _bigWindow(tester);
  _kiosk.lines = lines;
  SettingsState.current = LoadSettingsResponse(icaoReport: icaoReport);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CapturePage())));
  await tester.pump();
  await tester.tap(find.text('Automatic'));
  // Until the last line is on screen (every test ends on an ICAO row, shown
  // verbatim), not a fixed wait: tearing the connection down while the stream
  // still has queued messages trips an http2 assertion on a busy machine.
  for (var i = 0; i < 100 && find.text(lines.last).evaluate().isEmpty; i++) {
    await _settle(tester, 1);
  }
  await _settle(tester, 5);
}

/// The badge glyph of the result row that shows [text].
String _glyphOf(WidgetTester tester, String text) {
  final row = find.ancestor(of: find.text(text), matching: find.byType(Row)).first;
  for (final glyph in const ['!', 'i', '✓', '✕', '•']) {
    if (find.descendant(of: row, matching: find.text(glyph)).evaluate().isNotEmpty) {
      return glyph;
    }
  }
  return '?';
}

Finder _icaoSwitch() => find.descendant(
    of: find
        .ancestor(
            of: find.textContaining('ICAO compliance report'),
            matching: find.byType(Row))
        .first,
    matching: find.byType(Switch));

void main() {
  setUpAll(() async {
    final server = Server.create(services: [_kiosk, _settings]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
    await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  });

  test('icaoRowPassed reads the verdict of an ICAO row', () {
    expect(icaoRowPassed('ICAO compliance: passed (19 requirements)'), isTrue);
    expect(icaoRowPassed('ICAO Sharp focus: passed (Sharpness 87/100)'), isTrue);
    expect(
        icaoRowPassed(
            'ICAO compliance: attention (1 of 19 requirements: glasses)'),
        isFalse);
    expect(
        icaoRowPassed(
            'ICAO compliance: incomplete (14 of 19 requirements not checked)'),
        isFalse);
    expect(icaoRowPassed('ICAO Sharp focus: not checked'), isNull);
    // "passed" inside the detail does not make an attention row pass.
    expect(
        icaoRowPassed('ICAO Exposure: attention (Luminance mean 27/100, min 50)'),
        isFalse);
    expect(icaoRowPassed('OFIQ Sharpness: 87/100 - passed (min 50)'), isNull);
  });

  testWidgets('ICAO rows show their verdict; the overall row is keyed',
      (tester) async {
    const overall =
        'ICAO compliance: attention (1 of 19 requirements: glasses)';
    const sharp = 'ICAO Sharp focus: passed (Sharpness 87/100)';
    const glasses = 'ICAO Glasses: attention (glasses detected, certainty 93% '
        '- check for tinted lenses and reflections)';
    const gaze = 'ICAO Looking at the camera: not checked';
    await tester.runAsync(() async {
      await _capture(tester, [
        'Taking a high res photo using camera 4',
        'Distance in cm: 61',
        'Scoring the photo with OFIQ (ISO/IEC 29794-5)...',
        overall,
        sharp,
        glasses,
        gaze,
      ]);
      expect(_glyphOf(tester, overall), '!');
      expect(_glyphOf(tester, sharp), '✓');
      expect(_glyphOf(tester, glasses), '!');
      expect(_glyphOf(tester, gaze), 'i');
      // The overall verdict replaced the pending checklist row.
      expect(find.text('ICAO compliance report'), findsNothing);
      expect(find.textContaining('OFIQ quality report'), findsNothing);
    });
  });

  testWidgets('a passed report is green; an incomplete one is amber',
      (tester) async {
    const unavailable = 'OFIQ scoring unavailable - the OFIQ installation was '
        'not found on the server machine';
    const incomplete =
        'ICAO compliance: incomplete (14 of 19 requirements not checked)';
    await tester.runAsync(() async {
      await _capture(tester, [
        'Distance in cm: 61',
        unavailable,
        incomplete,
        'ICAO Sharp focus: not checked',
      ]);
      expect(_glyphOf(tester, incomplete), '!');
      expect(_glyphOf(tester, unavailable), '!');
    });
  });

  testWidgets('a fully compliant photo gets a green overall row', (tester) async {
    const passed = 'ICAO compliance: passed (19 requirements)';
    await tester.runAsync(() async {
      await _capture(tester, [
        'Distance in cm: 61',
        'Scoring the photo with OFIQ (ISO/IEC 29794-5)...',
        passed,
      ]);
      expect(_glyphOf(tester, passed), '✓');
    });
  });

  testWidgets('the Photo page switch pushes SetIcaoReport and the snapshot',
      (tester) async {
    await tester.runAsync(() async {
      _bigWindow(tester);
      SettingsState.current = LoadSettingsResponse(
          crop: true,
          photoFormat: 'icao_35x45',
          cropWidth: 700,
          cropHeight: 900,
          backgroundMethod: 'none',
          backgroundColor: 'FFFFFF',
          jpegQuality: 95);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PhotoPage())));
      await _settle(tester, 5);
      expect(tester.widget<Switch>(_icaoSwitch()).value, isFalse);

      await tester.ensureVisible(_icaoSwitch());
      await tester.pump();
      await tester.tap(_icaoSwitch());
      await _settle(tester, 5);

      expect(_settings.calls, [true]);
      expect(SettingsState.current!.icaoReport, isTrue);
      expect(tester.widget<Switch>(_icaoSwitch()).value, isTrue);
      expect(find.textContaining('replaces the OFIQ report'), findsOneWidget);
    });
  });

  test('a fleet profile may carry icao_report', () {
    final profile = SettingsProfile.parse(
        '{"profile": "t", "kiosk_settings": {"kiosk": {"icao_report": true}}}');
    final row = profile.diff(const {}).single;
    expect(row.id, 'kiosk.icao_report');
    expect(row.label, 'ICAO compliance report');
    expect(
        applyProfileChanges(const {}, [row])['kiosk']['icao_report'], isTrue);
    expect(
        () => SettingsProfile.parse('{"profile": "t", "kiosk_settings": '
            '{"kiosk": {"icao_report": "yes"}}}'),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'message', contains('true or false'))));
  });
}
