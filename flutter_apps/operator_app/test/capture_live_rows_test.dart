// The three live person check rows (depth before the photo, shading and colour
// after it) stay together on the Capture page, and one amber verdict among them
// lifts the whole block (2026-10-06). Against an in-process fake Kiosk server.
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

double _top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

const depth = 'Live person check: passed (3D face confirmed by 4 cameras, depth 0.18)';
const shading = 'Live person check (shading): failed - flat picture suspected (chin relief -0.03, nose -0.02, min 0.10)';
const colour = 'Live person check (colour): passed (skin follows the light 3.66, min 2.00)';

void main() {
  testWidgets('the light rows sit under the depth row, and an amber one lifts the block',
      (tester) async {
    await tester.runAsync(() async {
      await _capture(tester, [
        depth,
        'Taking a high res photo using camera 4',
        'Distance in cm: 55',
        'Lips are closed: True (certainty 90%)',
        shading,
        colour,
      ]);
      // depth, shading, colour: consecutive, in the order they arrived
      final rows = [depth, shading, colour].map((t) => _top(tester, t)).toList();
      expect(rows[1], greaterThan(rows[0]));
      expect(rows[2], greaterThan(rows[1]));
      // the shading failure is amber, so the block leads the checks - but the
      // camera row stays on top of everything (2026-10-06)
      expect(rows[0], greaterThan(_top(tester, 'Camera 4 selected — taking a high res photo')));
      expect(_top(tester, 'Camera 4 selected — taking a high res photo'),
          lessThan(_top(tester, 'Distance in cm: 55')));
    });
  });

  testWidgets('all green: the block keeps its place below the newer rows', (tester) async {
    await tester.runAsync(() async {
      const shadingOk = 'Live person check (shading): passed (3D face, chin relief 0.21, nose 0.50, min 0.10)';
      await _capture(tester, [
        depth,
        'Taking a high res photo using camera 4',
        'Distance in cm: 55',
        shadingOk,
        colour,
      ]);
      expect(_top(tester, shadingOk), greaterThan(_top(tester, depth)));
      expect(_top(tester, colour), greaterThan(_top(tester, shadingOk)));
      // the camera row came after the depth row and leads the list
      expect(_top(tester, depth),
          greaterThan(_top(tester, 'Camera 4 selected — taking a high res photo')));
    });
  });
}
