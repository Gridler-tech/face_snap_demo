// The Capture page's Clear button puts the page back as it was before the first
// capture: no result lines of the last capture, no message, no timing, and the
// checklist back to its pending rows. Against an in-process fake Kiosk server
// over a real loopback connection.
import 'dart:async';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/capture_page.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/ui/ui.dart';

const _gaveUp =
    'Could not take the photo with camera 4: the mouth was open in 30 of 30 frames, Please try again';
const _timingHint =
    'Run a capture to see how long each step takes '
    '(measured at this app, so network time is included).';

class _FakeKiosk extends KioskServiceBase {
  /// Completed by the test to let a capture end; null = ends at once.
  Completer<void>? hold;

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
    ServiceCall call,
    Empty request,
  ) async* {
    yield ProcessAutomaticResponse(
      processStatus: ProcessStepStatus(
        index: 4,
        description: _gaveUp,
        status: StatusType.OK,
      ),
    );
    if (hold != null) await hold!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

Future<_FakeKiosk> _openPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1900, 1100);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final kiosk = _FakeKiosk();
  final server = Server.create(services: [kiosk]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  // Close the client side first (tear-downs run last-in first-out).
  addTearDown(
    () => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()),
  );
  SettingsState.current = LoadSettingsResponse();
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: CapturePage())),
  );
  await tester.pump();
  return kiosk;
}

/// Real time for the loopback gRPC stream; call inside tester.runAsync.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

QuietButton _clearButton(WidgetTester tester) =>
    tester.widget<QuietButton>(find.widgetWithText(QuietButton, 'Clear'));

void main() {
  testWidgets('Clear empties the results, the message and the timing', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await _openPage(tester);
      expect(find.text(_timingHint), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);

      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      expect(find.text(_gaveUp), findsOneWidget);
      expect(find.text('The capture ended without a photo.'), findsOneWidget);
      expect(find.text(_timingHint), findsNothing);

      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(find.text(_gaveUp), findsNothing);
      expect(find.text('The capture ended without a photo.'), findsNothing);
      expect(find.text(_timingHint), findsOneWidget);
      expect(
        find.text('Distance'),
        findsOneWidget,
      ); // the pending checklist is back
    });
  });

  testWidgets('Clear is switched off while a capture is running', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final kiosk = await _openPage(tester);
      kiosk.hold = Completer<void>();
      expect(_clearButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Automatic'));
      await _settle(tester);
      expect(find.text(_gaveUp), findsOneWidget); // the capture is under way
      expect(_clearButton(tester).onPressed, isNull);

      kiosk.hold!.complete();
      await _settle(tester);
      expect(_clearButton(tester).onPressed, isNotNull);
    });
  });
}
