// The Photo page's background "Erasing strength" selector (1 mild - 5 heavy),
// against an in-process fake Settings server over a real loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/photo_page.dart';
import 'package:operator_app/services/settings_state.dart';

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({required this.accept});
  final bool accept;
  final List<int> strengthCalls = [];

  @override
  Future<BackgroundStrengthResponse> setBackgroundStrength(
      ServiceCall call, BackgroundStrengthRequest request) async {
    strengthCalls.add(request.value);
    if (!accept) throw GrpcError.unimplemented('SetBackgroundStrength');
    return BackgroundStrengthResponse(message: request.value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

LoadSettingsResponse _settings({String method = 'modnet', int strength = 3}) =>
    LoadSettingsResponse(
      crop: true,
      photoFormat: 'icao_35x45',
      cropWidth: 700,
      cropHeight: 900,
      backgroundMethod: method,
      backgroundColor: 'FFFFFF',
      backgroundStrength: strength,
      jpegQuality: 95,
    );

SegmentedButton<int> _selector(WidgetTester tester) =>
    tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>));

Future<_FakeSettings> _pump(WidgetTester tester, LoadSettingsResponse settings,
    {bool accept = true}) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final fake = _FakeSettings(accept: accept);
  final server = Server.create(services: [fake]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);

  SettingsState.current = settings;
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PhotoPage())));
  await tester.pump();
  return fake;
}

Future<void> _pick(WidgetTester tester, int level) async {
  await tester.tap(find.descendant(
      of: find.byType(SegmentedButton<int>), matching: find.text('$level')));
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await tester.pump();
}

void main() {
  testWidgets('shows the strength next to an active method', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, _settings(strength: 4));
      expect(_selector(tester).selected, {4});
      expect(find.text('heavy: cleaner edges'), findsOneWidget);
    });
  });

  testWidgets('hides the strength when the background is kept', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, _settings(method: 'none'));
      expect(find.byType(SegmentedButton<int>), findsNothing);
      expect(find.text('Erasing strength'), findsNothing);
    });
  });

  testWidgets('an older server (no strength) shows the standard 3',
      (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, _settings(strength: 0));
      expect(_selector(tester).selected, {3});
      expect(find.text('standard'), findsOneWidget);
    });
  });

  testWidgets('picking a strength sends it and updates the snapshot',
      (tester) async {
    await tester.runAsync(() async {
      final fake = await _pump(tester, _settings());
      await _pick(tester, 5);
      expect(fake.strengthCalls, [5]);
      expect(_selector(tester).selected, {5});
      expect(SettingsState.current!.backgroundStrength, 5);
      expect(find.textContaining('Server call failed'), findsNothing);
    });
  });

  testWidgets('a refused strength rolls back and says why', (tester) async {
    await tester.runAsync(() async {
      final fake = await _pump(tester, _settings(strength: 2), accept: false);
      await _pick(tester, 5);
      expect(fake.strengthCalls, [5]);
      expect(_selector(tester).selected, {2});
      expect(SettingsState.current!.backgroundStrength, 2);
      expect(find.textContaining('Server call failed'), findsOneWidget);
    });
  });
}
