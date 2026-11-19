// The Photo page's "Load at server start" card (kiosk setting capture_warm_up):
// a chip sends the whole list, the server's answer is what the card keeps, and
// a refused change rolls the chip back. The chips: None (not a server item: the
// empty list), withoutBG, MODNet, the Gridler eraser and OFIQ (1.1.27). Against an in-process fake Settings
// server over a real loopback connection.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, ServiceCall;
import 'package:operator_app/pages/photo_page.dart';
import 'package:operator_app/services/settings_state.dart';

import 'fake_server.dart';

class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({required this.accept});

  /// false = a server from before the setting: SetCaptureWarmUp is UNIMPLEMENTED.
  final bool accept;
  final List<List<String>> calls = [];

  @override
  Future<CaptureWarmUpResponse> setCaptureWarmUp(
    ServiceCall call,
    CaptureWarmUpRequest request,
  ) async {
    calls.add(request.items.toList());
    if (!accept) throw GrpcError.unimplemented('SetCaptureWarmUp');
    // The server stores the list in its own order, without duplicates.
    const order = ['modnet', 'withoutbg', 'gridler', 'ofiq'];
    return CaptureWarmUpResponse(
      items: [
        for (final i in order)
          if (request.items.contains(i)) i,
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

Future<_FakeSettings> _pump(
  WidgetTester tester,
  List<String> warmUp, {
  bool accept = true,
}) async {
  tester.view.physicalSize = const Size(1600, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final fake = _FakeSettings(accept: accept);
  final server = await serveFakes([fake]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);

  SettingsState.current = LoadSettingsResponse(
    crop: true,
    photoFormat: 'icao_35x45',
    cropWidth: 700,
    cropHeight: 900,
    backgroundMethod: 'modnet',
    backgroundColor: 'FFFFFF',
    backgroundStrength: 3,
    jpegQuality: 95,
    captureWarmUp: warmUp,
  );
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PhotoPage())));
  await tester.pump();
  return fake;
}

FilterChip _chip(WidgetTester tester, String item) =>
    tester.widget<FilterChip>(find.byKey(ValueKey('warm-up-$item')));

Future<void> _tap(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(ValueKey('warm-up-$item')));
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await tester.pump();
}

void main() {
  testWidgets('a chip sends the list', (tester) async {
    await tester.runAsync(() async {
      final fake = await _pump(tester, ['modnet']);
      expect(find.text('LOAD AT SERVER START'), findsOneWidget);
      expect(_chip(tester, 'modnet').selected, isTrue);
      expect(_chip(tester, 'withoutbg').selected, isFalse);
      expect(_chip(tester, 'ofiq').selected, isFalse);

      await _tap(tester, 'ofiq');
      await _tap(tester, 'withoutbg');
      expect(fake.calls, [
        ['modnet', 'ofiq'],
        ['modnet', 'withoutbg', 'ofiq'],
      ]);
      expect(_chip(tester, 'withoutbg').selected, isTrue);
      expect(SettingsState.current!.captureWarmUp, [
        'modnet',
        'withoutbg',
        'ofiq',
      ]);

      await _tap(tester, 'modnet');
      expect(fake.calls.last, ['withoutbg', 'ofiq']);
      expect(_chip(tester, 'modnet').selected, isFalse);
    });
  });

  testWidgets('a refusal rolls the chip back', (tester) async {
    await tester.runAsync(() async {
      final fake = await _pump(tester, const [], accept: false);
      await _tap(tester, 'withoutbg');
      expect(fake.calls, [
        ['withoutbg'],
      ]);
      expect(_chip(tester, 'withoutbg').selected, isFalse);
      expect(SettingsState.current!.captureWarmUp, isEmpty);
      expect(find.textContaining('Server call failed'), findsOneWidget);
    });
  });

  testWidgets('the chips: None, withoutBG, MODNet, Gridler eraser, OFIQ',
      (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, const []);
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      expect([for (final c in chips) (c.key as ValueKey<String>).value], [
        'warm-up-none',
        'warm-up-withoutbg',
        'warm-up-modnet',
        'warm-up-gridler',
        'warm-up-ofiq',
      ]);
      expect([for (final c in chips) (c.label as Text).data],
          ['None', 'withoutBG', 'MODNet', 'Gridler eraser', 'OFIQ']);
    });
  });

  testWidgets('None is selected exactly when the list is empty',
      (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, const []);
      expect(_chip(tester, 'none').selected, isTrue);
      for (final item in ['withoutbg', 'modnet', 'gridler', 'ofiq']) {
        expect(_chip(tester, item).selected, isFalse, reason: item);
      }
    });
  });

  testWidgets('None is not selected while a model is listed', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, ['gridler']);
      expect(_chip(tester, 'none').selected, isFalse);
      expect(_chip(tester, 'gridler').selected, isTrue);
    });
  });

  testWidgets('tapping None sends an empty list and unticks every model',
      (tester) async {
    await tester.runAsync(() async {
      final fake = await _pump(tester, ['modnet', 'gridler', 'ofiq']);
      await _tap(tester, 'none');
      expect(fake.calls, [<String>[]]);
      expect(_chip(tester, 'none').selected, isTrue);
      for (final item in ['withoutbg', 'modnet', 'gridler', 'ofiq']) {
        expect(_chip(tester, item).selected, isFalse, reason: item);
      }
      expect(SettingsState.current!.captureWarmUp, isEmpty);

      // Tapped again while the list is empty: nothing to send, None stays.
      await _tap(tester, 'none');
      expect(fake.calls, [<String>[]]);
      expect(_chip(tester, 'none').selected, isTrue);
    });
  });

  testWidgets('ticking a model unselects None', (tester) async {
    await tester.runAsync(() async {
      final fake = await _pump(tester, const []);
      await _tap(tester, 'withoutbg');
      expect(fake.calls, [
        ['withoutbg'],
      ]);
      expect(_chip(tester, 'none').selected, isFalse);
      expect(_chip(tester, 'withoutbg').selected, isTrue);

      // Unticking the last model selects None again.
      await _tap(tester, 'withoutbg');
      expect(fake.calls.last, isEmpty);
      expect(_chip(tester, 'none').selected, isTrue);
    });
  });

  testWidgets('the Gridler chip sends gridler in the server order',
      (tester) async {
    await tester.runAsync(() async {
      final fake = await _pump(tester, ['modnet', 'ofiq']);
      expect(_chip(tester, 'gridler').selected, isFalse);
      await _tap(tester, 'gridler');
      expect(fake.calls, [
        ['modnet', 'gridler', 'ofiq'],
      ]);
      expect(_chip(tester, 'gridler').selected, isTrue);
      expect(SettingsState.current!.captureWarmUp, ['modnet', 'gridler', 'ofiq']);

      await _tap(tester, 'withoutbg');
      expect(fake.calls.last, ['modnet', 'withoutbg', 'gridler', 'ofiq']);

      await _tap(tester, 'gridler');
      expect(fake.calls.last, ['modnet', 'withoutbg', 'ofiq']);
      expect(_chip(tester, 'gridler').selected, isFalse);
    });
  });
}
