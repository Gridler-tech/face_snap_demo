// The Capture page shows the line with which the server ends a capture without a
// photo as an amber "!" row, not as a grey information row: "Could not take the
// photo with camera 4: the mouth was open in 30 of 30 frames, Please try again"
// was easy to overlook (2026-10-04). Against an in-process fake Kiosk server over
// a real loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/capture_page.dart';
import 'package:operator_app/services/settings_state.dart';

class _FakeKiosk extends KioskServiceBase {
  _FakeKiosk(this.lines);
  final List<String> lines;

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

Future<void> _capture(WidgetTester tester, List<String> lines) async {
  tester.view.physicalSize = const Size(1900, 1100);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final server = Server.create(services: [_FakeKiosk(lines)]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  // Close the client side first (tear-downs run last-in first-out): shutting the
  // server down under an open client connection trips an http2 assertion.
  addTearDown(() => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()));

  SettingsState.current = LoadSettingsResponse();
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CapturePage())));
  await tester.pump();
  await tester.tap(find.text('Automatic'));
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
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

void main() {
  test('captureGaveUp recognises every line that ends a capture without a photo', () {
    for (final line in const [
      'Could not take the photo with camera 4: the mouth was open in 30 of 30 frames, Please try again',
      'Could not take the photo with camera 4: the eyes were closed in 29 of 30 frames, Please try again',
      'Could not find landmarks with index 4, Please try again',
      'Camera 4 stopped delivering frames, Please try again',
      'Camera detection failed, Please try again',
      'Capture failed, Please try again',
    ]) {
      expect(captureGaveUp(line), isTrue, reason: line);
    }
    for (final line in const [
      'Taking a high res photo using camera 4',
      'Glasses detected - taking the photo with the lights off',
      'Live person check: passed (3D face confirmed by 3 cameras, depth 0.21)',
      'Lips are closed: True (certainty 90%)',
      'Distance in cm: 55',
    ]) {
      expect(captureGaveUp(line), isFalse, reason: line);
    }
  });

  testWidgets('the give-up line is an amber "!" row, other lines keep their style',
      (tester) async {
    const gaveUp =
        'Could not take the photo with camera 4: the mouth was open in 30 of 30 frames, Please try again';
    await tester.runAsync(() async {
      await _capture(tester, [
        'Taking a high res photo using camera 4',
        'Glasses detected - taking the photo with the lights off',
        gaveUp,
      ]);
      expect(find.text(gaveUp), findsOneWidget);
      expect(_glyphOf(tester, gaveUp), '!');
      expect(_glyphOf(tester, 'Camera 4 selected — taking a high res photo'), 'i');
    });
  });
}
