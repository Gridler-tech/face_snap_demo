// The Photo page's "Background erasing" dropdown after withoutBG replaced rembg:
// the new method is offered, the retired one only while an older server reports
// it, the server's answer is what the page keeps, and a refused change rolls back.
// Against an in-process fake Settings server over a real loopback connection.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/photo_page.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/updater/settings_profile.dart';

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({required this.knowsWithoutBg});

  /// false = a server from before the change: it refuses 'withoutbg'.
  final bool knowsWithoutBg;
  final List<String> methodCalls = [];

  @override
  Future<BackgroundMethodResponse> setBackgroundMethod(
      ServiceCall call, BackgroundMethodRequest request) async {
    methodCalls.add(request.method);
    if (!knowsWithoutBg && request.method == 'withoutbg') {
      throw GrpcError.invalidArgument(
          'background method should be one of none, mediapipe, modnet, rembg');
    }
    // A current server stores and reports the retired name as its replacement.
    final set = knowsWithoutBg && request.method == 'rembg'
        ? 'withoutbg'
        : request.method;
    return BackgroundMethodResponse(method: set);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

LoadSettingsResponse _settings(String method) => LoadSettingsResponse(
      crop: true,
      photoFormat: 'icao_35x45',
      cropWidth: 700,
      cropHeight: 900,
      backgroundMethod: method,
      backgroundColor: 'FFFFFF',
      backgroundStrength: 3,
      jpegQuality: 95,
    );

DropdownMenu<String> _dropdown(WidgetTester tester) =>
    tester.widget<DropdownMenu<String>>(find.byType(DropdownMenu<String>).last);

List<String> _values(WidgetTester tester) =>
    [for (final e in _dropdown(tester).dropdownMenuEntries) e.value];

Future<_FakeSettings> _pump(WidgetTester tester, String method,
    {bool knowsWithoutBg = true}) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final fake = _FakeSettings(knowsWithoutBg: knowsWithoutBg);
  final server = Server.create(services: [fake]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);

  SettingsState.current = _settings(method);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PhotoPage())));
  await tester.pump();
  return fake;
}

Future<void> _select(WidgetTester tester, String code) async {
  _dropdown(tester).onSelected!(code);
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await tester.pump();
}

void main() {
  test('entries: withoutBG replaces rembg, rembg only for an older server', () {
    expect([for (final e in backgroundMethodEntries('modnet')) e.$1],
        ['none', 'mediapipe', 'modnet', 'withoutbg']);
    expect([for (final e in backgroundMethodEntries('rembg')) e.$1],
        ['none', 'mediapipe', 'modnet', 'withoutbg', 'rembg']);
    expect(backgroundMethodEntries('modnet').last.$2,
        'withoutBG (best quality, slower)');
  });

  testWidgets('a current server: withoutBG is offered and selected',
      (tester) async {
    await tester.runAsync(() async {
      final fake = await _pump(tester, 'withoutbg');
      expect(_dropdown(tester).initialSelection, 'withoutbg');
      expect(_values(tester), ['none', 'mediapipe', 'modnet', 'withoutbg']);

      await _select(tester, 'modnet');
      expect(fake.methodCalls, ['modnet']);
      expect(_dropdown(tester).initialSelection, 'modnet');
      expect(SettingsState.current!.backgroundMethod, 'modnet');

      await _select(tester, 'withoutbg');
      expect(fake.methodCalls, ['modnet', 'withoutbg']);
      expect(_dropdown(tester).initialSelection, 'withoutbg');
      expect(SettingsState.current!.backgroundMethod, 'withoutbg');
    });
  });

  testWidgets('an older server: rembg stays listed, withoutBG is refused and '
      'the dropdown rolls back', (tester) async {
    await tester.runAsync(() async {
      final fake = await _pump(tester, 'rembg', knowsWithoutBg: false);
      expect(_dropdown(tester).initialSelection, 'rembg');
      expect(_values(tester), contains('rembg'));

      await _select(tester, 'withoutbg');

      expect(fake.methodCalls, ['withoutbg']);
      expect(_dropdown(tester).initialSelection, 'rembg');
      expect(SettingsState.current!.backgroundMethod, 'rembg');
      expect(find.textContaining('Server call failed'), findsOneWidget);
    });
  });

  test('settings profile accepts withoutbg and the retired rembg', () {
    String profile(String method) => '{"profile": "t", "kiosk_settings": '
        '{"kiosk": {"background_method": "$method"}}}';
    expect(SettingsProfile.parse(profile('withoutbg')).name, 't');
    expect(SettingsProfile.parse(profile('rembg')).name, 't');
    expect(
        () => SettingsProfile.parse(profile('isnet')),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('none, mediapipe, modnet, withoutbg'))));
  });
}
