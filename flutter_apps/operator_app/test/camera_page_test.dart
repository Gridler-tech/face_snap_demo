// The Camera page's "Fast camera selection (Media Foundation)" switch: usable
// for a server on this PC (a Windows server), greyed out for a kiosk board
// (Linux ignores the setting), and rolled back when the server call fails.
// The page talks to an in-process fake server over a real loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/camera_page.dart';
import 'package:operator_app/services/settings_state.dart';

class _FakeCamera extends CameraServiceBase {
  @override
  Future<LoadCameraSettingsResponse> loadSettings(ServiceCall call, Empty request) async =>
      LoadCameraSettingsResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({required this.acceptMsmf});
  final bool acceptMsmf;
  final List<bool> msmfCalls = [];

  @override
  Future<MsmfSelectionResponse> setMsmfSelection(
      ServiceCall call, MsmfSelectionRequest request) async {
    msmfCalls.add(request.enabled);
    if (!acceptMsmf) throw GrpcError.internal('settings file is read-only');
    return MsmfSelectionResponse(enabled: request.enabled);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

Finder _msmfSwitch() => find.descendant(
    of: find.ancestor(
        of: find.text('Fast camera selection (Media Foundation)'),
        matching: find.byType(Row)),
    matching: find.byType(Switch));

/// Serves the fakes on [address] and opens the Camera page against it.
/// 127.0.0.1 is "this PC"; 127.0.0.2 is still loopback but counts as another
/// host, like a kiosk board.
Future<_FakeSettings> _pumpPage(WidgetTester tester, String address,
    {bool acceptMsmf = true}) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = _FakeSettings(acceptMsmf: acceptMsmf);
  final server = Server.create(services: [_FakeCamera(), settings]);
  await server.serve(address: InternetAddress(address), port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));

  SettingsState.current = LoadSettingsResponse(msmfSelection: true);
  await GrpcChannelProvider.setAddress(address, server.port!);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CameraPage())));
  for (var i = 0; i < 20 && _msmfSwitch().evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
  return settings;
}

Future<void> _settle(WidgetTester tester) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await tester.pump();
}

void main() {
  testWidgets('the switch works for a server on this PC', (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, '127.0.0.1');
      expect(tester.widget<Switch>(_msmfSwitch()).onChanged, isNotNull,
          reason: 'a server on this PC is a Windows server');
      expect(find.textContaining('Windows servers only'), findsNothing);

      await tester.ensureVisible(_msmfSwitch());
      await tester.pump();
      await tester.tap(_msmfSwitch());
      await _settle(tester);

      expect(settings.msmfCalls, [false]);
      expect(tester.widget<Switch>(_msmfSwitch()).value, isFalse);
      expect(SettingsState.current!.msmfSelection, isFalse,
          reason: 'the shared settings snapshot follows the server');
      expect(find.textContaining('Server call failed'), findsNothing);
    });
  });

  testWidgets('the switch is greyed out for a kiosk board', (tester) async {
    await tester.runAsync(() async {
      await _pumpPage(tester, '127.0.0.2');
      expect(tester.widget<Switch>(_msmfSwitch()).onChanged, isNull);
      expect(find.textContaining('Windows servers only'), findsOneWidget);
    });
  });

  testWidgets('a failed server call rolls the switch back and says why',
      (tester) async {
    await tester.runAsync(() async {
      final settings = await _pumpPage(tester, '127.0.0.1', acceptMsmf: false);
      expect(tester.widget<Switch>(_msmfSwitch()).value, isTrue);

      await tester.ensureVisible(_msmfSwitch());
      await tester.pump();
      await tester.tap(_msmfSwitch());
      await _settle(tester);

      expect(settings.msmfCalls, [false]);
      expect(tester.widget<Switch>(_msmfSwitch()).value, isTrue,
          reason: 'the server refused the change');
      expect(find.textContaining('Server call failed'), findsOneWidget);
      expect(SettingsState.current!.msmfSelection, isTrue);
    });
  });
}
