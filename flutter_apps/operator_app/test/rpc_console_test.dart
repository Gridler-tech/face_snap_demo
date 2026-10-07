// The RPC console against an in-process fake FaceSnap server: recorded calls
// show up as lines (errors in red), expand to JSON, filter (service, errors
// only, search), polling is hidden by default, pause stops appending, a stream
// lists its items, a preview is summarised, Copy / Save work, and the shell's
// button (developer mode only) opens the dock and switches recording.
import 'dart:convert';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall;
import 'package:operator_app/home_shell.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/ui/dev_info.dart';
import 'package:operator_app/ui/rpc_console.dart';
import 'package:operator_app/ui/ui.dart';

class _Settings extends SettingsServiceBase {
  @override
  Future<CropResponse> setCrop(ServiceCall call, CropRequest request) async =>
      CropResponse(message: request.value);

  @override
  Future<ResolutionResponse> setResolution(
          ServiceCall call, ResolutionRequest request) async =>
      throw GrpcError.invalidArgument('resolution 1x1 is not supported');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Kiosk extends KioskServiceBase {
  @override
  Future<KioskInfoResponse> getKioskInfo(
          ServiceCall call, Empty request) async =>
      KioskInfoResponse(kioskInfo: KioskInfo(numberOfCameras: 4));

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
      ServiceCall call, Empty request) async* {
    yield ProcessAutomaticResponse(
        processStatus: ProcessStepStatus(
            index: 2, description: 'Best Camera was determined'));
    yield ProcessAutomaticResponse(
        imageData: ProcessImageData(
            index: 2, width: 600, height: 800, chunkData: List.filled(70000, 1)));
    yield ProcessAutomaticResponse(
        processStatus: ProcessStepStatus(
            index: 2, description: 'ICAO compliance: 9 of 9'));
  }

  @override
  Stream<ProcessImageData> streamPreview(
      ServiceCall call, PreviewRequest request) async* {
    for (var i = 0; i < 10; i++) {
      yield ProcessImageData(
          index: request.cameraIndex,
          width: 640,
          height: 480,
          chunkData: List.filled(4000 + i, 1));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// Serves the fakes and points the shared channel at them.
Future<void> _serve(WidgetTester tester) async {
  final server = Server.create(services: [_Settings(), _Kiosk()]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  addTearDown(
      () => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()));
}

/// The panel alone, with its own controller (opened = recording).
Future<RpcConsoleController> _panel(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1700, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  RpcTrace.clear();
  final c = RpcConsoleController(repaintEvery: const Duration(milliseconds: 10));
  c.setOpen(true);
  addTearDown(() {
    c.setOpen(false);
    RpcTrace.clear();
  });
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Column(children: [
        const Expanded(child: SizedBox()),
        SizedBox(height: 700, child: RpcConsolePanel(controller: c)),
      ]),
    ),
  ));
  return c;
}

/// Let the calls land and the console repaint.
Future<void> _settle(WidgetTester tester) async {
  await Future<void>.delayed(const Duration(milliseconds: 80));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

SettingsClient get _settings => SettingsClient(GrpcChannelProvider.channel);
KioskClient get _kiosk => KioskClient(GrpcChannelProvider.channel);

Color? _outcomeColor(WidgetTester tester, RpcCall call) => tester
    .widget<Text>(find.byKey(ValueKey('rpc-outcome-${call.id}')))
    .style
    ?.color;

RpcCall _call(RpcConsoleController c, String method) =>
    c.calls.lastWhere((call) => call.method == method);

void main() {
  testWidgets('a unary call and an error (in red); expanding shows the JSON',
      (tester) async {
    await tester.runAsync(() async {
      await _serve(tester);
      final c = await _panel(tester);
      await _settings.setCrop(CropRequest(value: true));
      await expectLater(_settings.setResolution(ResolutionRequest()),
          throwsA(isA<GrpcError>()));
      await _settle(tester);

      expect(find.text('Settings.SetCrop'), findsOneWidget);
      expect(find.text('Settings.SetResolution'), findsOneWidget);
      expect(find.text('value: true'), findsOneWidget); // request summary
      expect(find.text('message: true'), findsOneWidget); // reply summary
      final error = find.text(
          'INVALID_ARGUMENT: resolution 1x1 is not supported');
      expect(error, findsOneWidget);
      expect(_outcomeColor(tester, _call(c, 'SetResolution')), T.fail);
      expect(_outcomeColor(tester, _call(c, 'SetCrop')), isNot(T.fail));
      expect(find.textContaining(RegExp(r'^\d\d:\d\d:\d\d\.\d\d\d$')),
          findsNWidgets(2));

      // Expand: the request and reply as pretty JSON.
      await tester.tap(find.text('Settings.SetCrop'));
      await tester.pump();
      expect(find.text('REQUEST'), findsOneWidget);
      expect(find.text('{\n  "value": true\n}'), findsOneWidget);
      expect(find.text('{\n  "message": true\n}'), findsOneWidget);
      expect(find.textContaining('OK after'), findsOneWidget);
    });
  });

  testWidgets('service filter, errors only and search', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester);
      final c = await _panel(tester);
      await _settings.setCrop(CropRequest(value: false));
      await expectLater(_settings.setResolution(ResolutionRequest()),
          throwsA(isA<GrpcError>()));
      await _kiosk.getKioskInfo(Empty());
      await _settle(tester);
      expect(c.visible, hasLength(3));

      // Service: Kiosk only.
      await tester.tap(find.byKey(const ValueKey('rpc-service-filter')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Kiosk').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Kiosk.GetKioskInfo'), findsOneWidget);
      expect(find.text('Settings.SetCrop'), findsNothing);
      c.setService(null);
      await tester.pump();

      // Errors only.
      await tester.tap(find.text('Errors only'));
      await tester.pump();
      expect(find.text('Settings.SetResolution'), findsOneWidget);
      expect(find.text('Settings.SetCrop'), findsNothing);
      expect(find.text('Kiosk.GetKioskInfo'), findsNothing);
      await tester.tap(find.text('Errors only'));
      await tester.pump();

      // Search.
      await tester.enterText(find.byKey(const ValueKey('rpc-search')), 'crop');
      await tester.pump();
      expect(find.text('Settings.SetCrop'), findsOneWidget);
      expect(find.text('Settings.SetResolution'), findsNothing);
      expect(find.text('1 of 3 calls'), findsOneWidget);
    });
  });

  testWidgets('the status poll is hidden by default, shown on request',
      (tester) async {
    await tester.runAsync(() async {
      await _serve(tester);
      final c = await _panel(tester);
      await RpcTrace.runTagged('poll', () => _kiosk.getKioskInfo(Empty()));
      await _settings.setCrop(CropRequest(value: true));
      await _settle(tester);

      expect(c.calls, hasLength(2));
      expect(find.text('Kiosk.GetKioskInfo'), findsNothing);
      expect(find.text('Settings.SetCrop'), findsOneWidget);

      await tester.tap(find.text('Show polling'));
      await tester.pump();
      expect(find.text('Kiosk.GetKioskInfo'), findsOneWidget);
      expect(find.text('poll'), findsOneWidget); // the badge
    });
  });

  testWidgets('pause stops appending; resume appends again', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester);
      final c = await _panel(tester);
      await _settings.setCrop(CropRequest(value: true));
      await _settle(tester);
      expect(find.text('Settings.SetCrop'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rpc-pause')));
      await tester.pump();
      expect(find.text('1 of 1 calls · paused'), findsOneWidget);
      await _kiosk.getKioskInfo(Empty());
      await _settle(tester);
      expect(find.text('Kiosk.GetKioskInfo'), findsNothing);
      expect(c.calls, hasLength(1));

      await tester.tap(find.byKey(const ValueKey('rpc-pause')));
      await tester.pump();
      await expectLater(_settings.setResolution(ResolutionRequest()),
          throwsA(isA<GrpcError>()));
      await _settle(tester);
      expect(find.text('Settings.SetResolution'), findsOneWidget);
      expect(find.text('Kiosk.GetKioskInfo'), findsNothing); // stays skipped
    });
  });

  testWidgets('a stream is one group listing its items in order',
      (tester) async {
    await tester.runAsync(() async {
      await _serve(tester);
      final c = await _panel(tester);
      await _kiosk.startAutomaticProcess(Empty()).drain<void>();
      await _settle(tester);

      expect(find.text('Kiosk.StartAutomaticProcess'), findsOneWidget);
      expect(find.text('stream'), findsOneWidget);
      expect(find.text('3 items · OK'), findsOneWidget);

      await tester.tap(find.text('Kiosk.StartAutomaticProcess'));
      await tester.pump();
      expect(find.text('STREAM — 3 ITEMS'), findsOneWidget);
      final id = _call(c, 'StartAutomaticProcess').id;
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('rpc-item-$id-$i')), findsOneWidget);
      }
      expect(
          find.text('processStatus: {index: 2, description: '
              '"Best Camera was determined"}'),
          findsOneWidget);
      // The photo chunk is a size, never data.
      expect(
          find.text('imageData: {index: 2, width: 600, height: 800, '
              'chunkData: <70000 bytes>}'),
          findsOneWidget);
      expect(
          tester.getTopLeft(find.byKey(ValueKey('rpc-item-$id-0'))).dy,
          lessThan(
              tester.getTopLeft(find.byKey(ValueKey('rpc-item-$id-2'))).dy));

      // An item expands to its JSON.
      await tester.tap(find.byKey(ValueKey('rpc-item-$id-1')));
      await tester.pump();
      expect(find.textContaining('"chunkData": "<70000 bytes>"'),
          findsOneWidget);
    });
  });

  testWidgets('a camera preview is summarised, not listed frame by frame',
      (tester) async {
    await tester.runAsync(() async {
      await _serve(tester);
      final c = await _panel(tester);
      await _kiosk
          .streamPreview(PreviewRequest(cameraIndex: 3, maxSeconds: 300))
          .drain<void>();
      await _settle(tester);

      final call = _call(c, 'StreamPreview');
      final line = find.byKey(ValueKey('rpc-outcome-${call.id}'));
      final text = tester.widget<Text>(line).data!;
      expect(text, startsWith('10 frames · '));
      expect(text, contains(' fps · last 4,009 bytes (640×480)'));

      await tester.tap(find.text('Kiosk.StreamPreview'));
      await tester.pump();
      expect(find.text('PREVIEW'), findsOneWidget);
      expect(find.byKey(ValueKey('rpc-preview-${call.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('rpc-item-${call.id}-0')), findsNothing);
    });
  });

  testWidgets('Copy as Dart / C# and Save… (.jsonl)', (tester) async {
    await tester.runAsync(() async {
      await _serve(tester);
      final c = await _panel(tester);
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await _settings.setCrop(CropRequest(value: true));
      await _kiosk.getKioskInfo(Empty());
      await _settle(tester);

      await tester.tap(find.text('Dart').first);
      await tester.pump();
      expect(clipboard,
          'final reply = await SettingsClient(GrpcChannelProvider.channel)'
          '.setCrop(CropRequest(value: true));');
      await tester.tap(find.text('C#').first);
      await tester.pump();
      expect(clipboard, endsWith('.SetCropAsync(new CropRequest { Value = true });'));

      final dir = await Directory.systemTemp.createTemp('rpc_console_test');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}${Platform.pathSeparator}log.jsonl';
      final previous = RpcConsoleController.pickSaveLocation;
      RpcConsoleController.pickSaveLocation = (
              {String? suggestedName,
              List<XTypeGroup> acceptedTypeGroups = const []}) async =>
          FileSaveLocation(path);
      addTearDown(() => RpcConsoleController.pickSaveLocation = previous);
      await tester.tap(find.byKey(const ValueKey('rpc-save')));
      for (var i = 0; i < 20 && !File(path).existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final lines = File(path).readAsLinesSync();
      expect(lines, hasLength(2));
      final first = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(first['method'], 'SetCrop');
      expect(first['service'], 'settings.Settings');
      expect((first['requests'] as List).single['message'], {'value': true});
      expect(first['status'], 'OK');
      expect(c.calls, hasLength(2));
    });
  });

  testWidgets('the shell button: developer mode only, opens the dock, records',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SettingsState.current = null;
    final console = RpcConsoleController.instance;
    addTearDown(() {
      console.setOpen(false);
      DevMode.enabled.value = false;
      RpcTrace.clear();
    });

    await tester.runAsync(() async {
      DevMode.enabled.value = false;
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      await tester.pump();
      expect(find.byKey(const ValueKey('rpc-console-button')), findsNothing);

      DevMode.enabled.value = true;
      await tester.pump();
      final button = find.byKey(const ValueKey('rpc-console-button'));
      expect(button, findsOneWidget);
      expect(RpcTrace.enabled, isFalse);

      await tester.tap(button);
      await tester.pump();
      expect(find.byType(RpcConsolePanel), findsOneWidget);
      expect(RpcTrace.enabled, isTrue);

      // Stays open across page switches.
      await tester.tap(find.text('Capture'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(RpcConsolePanel), findsOneWidget);

      await tester.tap(button);
      await tester.pump();
      expect(find.byType(RpcConsolePanel), findsNothing);
      expect(RpcTrace.enabled, isFalse);

      // Leaving developer mode closes it too.
      await tester.tap(button);
      await tester.pump();
      expect(RpcTrace.enabled, isTrue);
      DevMode.enabled.value = false;
      await tester.pump();
      expect(find.byType(RpcConsolePanel), findsNothing);
      expect(RpcTrace.enabled, isFalse);

      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pump();
    });
  });
}
