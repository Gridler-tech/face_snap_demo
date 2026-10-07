// RpcTrace against an in-process fake FaceSnap server: what a recorded call
// holds (unary OK / error, server streaming cancelled by the caller), that the
// caller's stream is untouched, that bytes are summarised, that recording off
// records nothing — and the "Copy as Dart / C#" text for representative calls.
//
// Set RPC_SNIPPETS_OUT=<dir> to also write the generated snippets there (the
// out-of-tree compile check reads them).
import 'dart:async';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall, StatusCode;
import 'package:test/test.dart';

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
  /// The photo chunks the automatic capture sends.
  static final chunk1 = List<int>.generate(262144, (i) => i % 251);
  static final chunk2 = List<int>.generate(1000, (i) => (i * 7) % 256);

  static List<ProcessAutomaticResponse> automatic() => [
        ProcessAutomaticResponse(
            processStatus: ProcessStepStatus(
                index: 2,
                description: 'Best Camera was determined',
                status: StatusType.OK)),
        ProcessAutomaticResponse(
            checkResult: CheckResult(
                index: 2,
                kind: CheckKind.GATE,
                name: 'distance',
                verdict: CheckVerdict.PASSED,
                value: 55,
                unit: 'cm')),
        ProcessAutomaticResponse(
            imageData: ProcessImageData(
                index: 2,
                width: 600,
                height: 800,
                format: 'jpeg',
                chunkData: chunk1)),
        ProcessAutomaticResponse(
            imageData: ProcessImageData(index: 2, chunkData: chunk2)),
        ProcessAutomaticResponse(
            processStatus: ProcessStepStatus(
                index: 2, description: 'ICAO compliance: 9 of 9')),
      ];

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
      ServiceCall call, Empty request) async* {
    for (final item in automatic()) {
      yield item;
    }
  }

  /// Endless preview: one frame every 10 ms until the client cancels.
  @override
  Stream<ProcessImageData> streamPreview(
      ServiceCall call, PreviewRequest request) async* {
    var n = 0;
    while (!call.isCanceled) {
      yield ProcessImageData(
          index: request.cameraIndex,
          width: 640,
          height: 480,
          chunkData: List<int>.filled(4000 + n++, 1));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  Future<KioskInfoResponse> getKioskInfo(
          ServiceCall call, Empty request) async =>
      KioskInfoResponse(
          kioskInfo: KioskInfo(serverIpAddress: '127.0.0.1', numberOfCameras: 4));

  @override
  Future<FaceRecognitionResponse> faceRecognition(
          ServiceCall call, FaceRecognitionRequest request) async =>
      FaceRecognitionResponse(
          verified: true,
          distance: 0.25,
          threshold: request.threshold,
          model: request.model);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Lights extends LightsServiceBase {
  @override
  Future<BacklightStatus> setBacklight(
          ServiceCall call, BacklightRequest request) async =>
      BacklightStatus(connected: true, backlightTop: request.on);

  @override
  Future<Empty> setLightAtCameraIndex(
          ServiceCall call, LightIndexRequest request) async =>
      Empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Calibration extends CalibrationServiceBase {
  @override
  Future<CalibrateResponse> setCalibration(
          ServiceCall call, CalibrateRequest request) async =>
      CalibrateResponse(success: true, message: '${request.calibrate.length}');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

late Server _server;

/// The newest recorded call for [method], once it finished.
Future<RpcCall> _finished(String method) async {
  for (var i = 0; i < 600; i++) {
    final calls = RpcTrace.calls.where((c) => c.method == method).toList();
    if (calls.isNotEmpty && calls.last.done) return calls.last;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('no finished $method call recorded '
      '(recorded: ${RpcTrace.calls.map((c) => c.method).toList()})');
}

/// True when no value anywhere in [json] is a list of ints (raw bytes).
bool _noRawBytes(Object? json) => switch (json) {
      final Map<dynamic, dynamic> m => m.values.every(_noRawBytes),
      final List<dynamic> l => !l.any((e) => e is int) && l.every(_noRawBytes),
      _ => true,
    };

void main() {
  setUpAll(() async {
    _server = Server.create(
        services: [_Settings(), _Kiosk(), _Lights(), _Calibration()]);
    await _server.serve(address: InternetAddress.loopbackIPv4, port: 0);
    await GrpcChannelProvider.setAddress('127.0.0.1', _server.port!);
  });

  tearDownAll(() async {
    RpcTrace.enabled = false;
    await GrpcChannelProvider.channel.shutdown();
    await _server.shutdown();
  });

  setUp(() {
    RpcTrace.clear();
    RpcTrace.enabled = true;
  });

  tearDown(() => RpcTrace.enabled = false);

  SettingsClient settings() => SettingsClient(GrpcChannelProvider.channel);
  KioskClient kiosk() => KioskClient(GrpcChannelProvider.channel);

  test('a unary call is recorded with request, reply, status and timing',
      () async {
    final reply = await settings().setCrop(CropRequest(value: true));
    expect(reply.message, isTrue);

    final call = await _finished('SetCrop');
    expect(call.kind, RpcKind.unary);
    expect(call.service, 'settings.Settings');
    expect(call.serviceName, 'Settings');
    expect(call.address, '127.0.0.1:${_server.port}');
    expect(call.requests.single.type, 'settings.CropRequest');
    expect(call.requests.single.json, {'value': true});
    expect(call.responses.single.json, {'message': true});
    expect(call.statusCode, 0);
    expect(call.statusName, 'OK');
    expect(call.isError, isFalse);
    expect(call.duration, isNotNull);
    expect(call.duration! > Duration.zero, isTrue);
  });

  test('a request also shows the fields the caller left at their default',
      () async {
    // An explicitly set default (value: false) was always kept; a field the
    // caller never set (height) is what proto3 JSON leaves out.
    await settings().setCrop(CropRequest(value: false));
    expect((await _finished('SetCrop')).requests.single.json, {'value': false});

    await expectLater(settings().setResolution(ResolutionRequest(width: 640)),
        throwsA(isA<GrpcError>()));
    final call = await _finished('SetResolution');
    expect(call.requests.single.json, {'width': 640, 'height': 0});
  });

  test('defaults: singular fields filled, oneof members only when set', () {
    expect(rpcMessageJson(ResolutionRequest(), null, true),
        {'width': 0, 'height': 0});
    expect(rpcMessageJson(ResolutionRequest()), <String, Object?>{});
    expect(rpcMessageJson(ProcessAutomaticResponse(), null, true),
        <String, Object?>{});
    expect(rpcMessageJson(PreviewRequest(cameraIndex: 2), null, true),
        {'cameraIndex': 2, 'maxSeconds': 0});
  });

  test('a unary error is recorded with its gRPC code and message', () async {
    await expectLater(
        settings().setResolution(ResolutionRequest()),
        throwsA(isA<GrpcError>().having(
            (e) => e.code, 'code', StatusCode.invalidArgument)));

    final call = await _finished('SetResolution');
    expect(call.isError, isTrue);
    expect(call.statusCode, StatusCode.invalidArgument);
    expect(call.statusName, 'INVALID_ARGUMENT');
    expect(call.statusMessage, 'resolution 1x1 is not supported');
    expect(call.responses, isEmpty);
    expect(call.requests.single.json, {'width': 0, 'height': 0});
  });

  test('a server stream cancelled by the caller: items in order, CANCELLED',
      () async {
    final received = <ProcessImageData>[];
    await for (final frame
        in kiosk().streamPreview(PreviewRequest(cameraIndex: 3))) {
      received.add(frame);
      if (received.length == 5) break; // leaving the loop cancels the call
    }

    final call = await _finished('StreamPreview');
    expect(call.kind, RpcKind.serverStreaming);
    expect(call.requests.single.json, {'cameraIndex': 3, 'maxSeconds': 0});
    expect(call.responseCount, greaterThanOrEqualTo(5));
    for (var i = 0; i < 5; i++) {
      expect(call.responses[i].json,
          {'index': 3, 'width': 640, 'height': 480, 'chunkData': '<${4000 + i} bytes>'});
      expect(call.responses[i].bytes, 4000 + i);
      expect(received[i].chunkData.length, 4000 + i);
    }
    expect(call.statusName, 'CANCELLED');
    expect(call.cancelledByCaller, isTrue);
  });

  test('cancel() on the response stream is the caller\'s cancel too', () async {
    final stream = kiosk().streamPreview(PreviewRequest(cameraIndex: 1));
    final first = Completer<void>();
    final sub = stream.listen((_) {
      if (!first.isCompleted) first.complete();
    }, onError: (_) {});
    await first.future;
    await stream.cancel();
    final call = await _finished('StreamPreview');
    expect(call.statusName, 'CANCELLED');
    expect(call.cancelledByCaller, isTrue);
    await sub.cancel();
  });

  test('the caller receives every item unchanged, the record keeps no bytes',
      () async {
    final received = await kiosk().startAutomaticProcess(Empty()).toList();
    expect(received, _Kiosk.automatic()); // protobuf == compares every field
    expect(received[2].imageData.chunkData, _Kiosk.chunk1);

    final call = await _finished('StartAutomaticProcess');
    expect(call.kind, RpcKind.serverStreaming);
    expect(call.requests.single.type, 'google.protobuf.Empty');
    expect(call.responseCount, 5);
    expect(call.statusName, 'OK');
    expect(call.cancelledByCaller, isFalse);
    expect(call.responses[1].json, {
      'checkResult': {
        'index': 2,
        'kind': 'GATE',
        'name': 'distance',
        'verdict': 'PASSED',
        'value': 55,
        'unit': 'cm',
      }
    });
    expect((call.responses[2].json as Map)['imageData'],
        containsPair('chunkData', '<262144 bytes>'));
    expect(call.responses[2].bytes, 262144);
    for (final r in call.responses) {
      expect(_noRawBytes(r.json), isTrue);
    }
  });

  test('bytes fields of a request are summarised', () async {
    final image = List<int>.filled(262144, 7);
    final reply = await kiosk().faceRecognition(FaceRecognitionRequest(
        image1: image,
        image2: List<int>.filled(1000, 1),
        threshold: 0.4,
        model: Model.SFACE,
        similarityMetric: DistanceMetric.EUCLIDEAN_L2));
    expect(reply.verified, isTrue);

    final call = await _finished('FaceRecognition');
    expect(call.requests.single.json, {
      'image1': '<262144 bytes>',
      'image2': '<1000 bytes>',
      'threshold': 0.4,
      'model': 'SFACE',
      'similarityMetric': 'EUCLIDEAN_L2',
    });
    expect(call.requests.single.bytes, 263144);
    expect(bytesMarkerLength('<262144 bytes>'), 262144);
  });

  test('recording off records nothing (and the calls still work)', () async {
    RpcTrace.enabled = false;
    final events = <RpcEvent>[];
    final sub = RpcTrace.events.listen(events.add);
    expect((await settings().setCrop(CropRequest(value: false))).message,
        isFalse);
    expect(await kiosk().startAutomaticProcess(Empty()).length, 5);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(RpcTrace.calls, isEmpty);
    expect(events, isEmpty);
    await sub.cancel();
  });

  test('events: started, request, response, finished — in that order',
      () async {
    final events = <RpcEvent>[];
    final sub = RpcTrace.events.listen(events.add);
    await settings().setCrop(CropRequest(value: true));
    await _finished('SetCrop');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();
    expect(events.map((e) => e.type), [
      RpcEventType.started,
      RpcEventType.request,
      RpcEventType.response,
      RpcEventType.finished,
    ]);
    expect(events.map((e) => e.call.id).toSet(), hasLength(1));
  });

  test('independent channels are recorded, and runTagged tags their calls',
      () async {
    final channel = GrpcChannelProvider.openChannel('127.0.0.1', _server.port!);
    try {
      await RpcTrace.runTagged('poll', () async {
        await Future<void>.delayed(Duration.zero); // tag survives an await
        await KioskClient(channel).getKioskInfo(Empty());
      });
    } finally {
      await channel.shutdown();
    }
    final call = await _finished('GetKioskInfo');
    expect(call.tag, 'poll');
    expect(call.responses.single.json, {
      'kioskInfo': {'serverIpAddress': '127.0.0.1', 'numberOfCameras': 4}
    });
  });

  test('a call that never reaches a server still shows its request', () async {
    final dead = GrpcChannelProvider.openChannel('127.0.0.1', 1);
    try {
      await expectLater(
          SettingsClient(dead).setCrop(CropRequest(value: true)),
          throwsA(isA<GrpcError>()));
    } finally {
      await dead.shutdown();
    }
    final call = await _finished('SetCrop');
    expect(call.statusName, 'UNAVAILABLE');
    expect(call.requests.single.json, {'value': true});
  });

  test('the ring buffer keeps the newest calls only', () async {
    for (var i = 0; i < 5; i++) {
      await settings().setCrop(CropRequest(value: i.isEven));
    }
    expect(RpcTrace.calls, hasLength(5));
    expect(RpcTrace.capacity, 2000);
    final ids = RpcTrace.calls.map((c) => c.id).toList();
    expect(ids, [...ids]..sort());
  });

  group('copy as code', () {
    final snippets = <String, (String, String)>{};

    Future<void> render(String name, String method,
        Future<void> Function() make) async {
      await make();
      final call = await _finished(method);
      snippets[name] = (rpcCallAsDart(call), rpcCallAsCSharp(call));
    }

    tearDownAll(() {
      final out = Platform.environment['RPC_SNIPPETS_OUT'];
      if (out == null) return;
      final dir = Directory(out)..createSync(recursive: true);
      final dart = StringBuffer();
      final cs = StringBuffer();
      snippets.forEach((name, s) {
        dart.writeln('// ---- $name\nFuture<void> $name() async {\n${s.$1}\n}\n');
        cs.writeln('// ---- $name\nstatic async Task $name()\n{\n${s.$2}\n}\n');
      });
      File('${dir.path}/snippets.dart.txt').writeAsStringSync('$dart');
      File('${dir.path}/snippets.cs.txt').writeAsStringSync('$cs');
    });

    test('unary with a scalar', () async {
      await render('scalar', 'SetCrop',
          () => settings().setCrop(CropRequest(value: true)));
      expect(snippets['scalar']!.$1,
          'final reply = await SettingsClient(GrpcChannelProvider.channel)'
          '.setCrop(CropRequest(value: true));');
      expect(snippets['scalar']!.$2.split('\n').last,
          'var reply = await new Settings.SettingsClient('
          'GrpcChannelProvider.Channel).SetCropAsync('
          'new CropRequest { Value = true });');
    });

    test('unary with an enum', () async {
      await render('enumValue', 'SetBacklight',
          () => LightsClient(GrpcChannelProvider.channel).setBacklight(
              BacklightRequest(backlight: Backlight.BACKLIGHT_TOP, on: true)));
      expect(snippets['enumValue']!.$1,
          'final reply = await LightsClient(GrpcChannelProvider.channel)'
          '.setBacklight(BacklightRequest(backlight: Backlight.BACKLIGHT_TOP, '
          'on: true));');
      expect(snippets['enumValue']!.$2.split('\n').last,
          'var reply = await new Lights.LightsClient(GrpcChannelProvider.Channel)'
          '.SetBacklightAsync(new BacklightRequest { '
          'Backlight = Backlight.Top, On = true });');
    });

    test('unary with a repeated message', () async {
      await render('repeated', 'SetCalibration',
          () => CalibrationClient(GrpcChannelProvider.channel).setCalibration(
                  CalibrateRequest(calibrate: [
                CalibrateType(
                    idModelId: '32e4:0298',
                    linuxCameraIndex: 0,
                    calibratedCameraIndex: 1),
                CalibrateType(
                    idModelId: '32e4:0298',
                    linuxCameraIndex: 2,
                    calibratedCameraIndex: 2),
              ])));
      expect(
          snippets['repeated']!.$1,
          'final reply = await CalibrationClient(GrpcChannelProvider.channel)'
          '.setCalibration(CalibrateRequest(calibrate: ['
          "CalibrateType(idModelId: '32e4:0298', linuxCameraIndex: 0, "
          'calibratedCameraIndex: 1), '
          "CalibrateType(idModelId: '32e4:0298', linuxCameraIndex: 2, "
          'calibratedCameraIndex: 2)]));');
      expect(snippets['repeated']!.$2, contains('Calibrate =\n'));
      expect(
          snippets['repeated']!.$2,
          contains('new CalibrateType { IdModelId = "32e4:0298", '
              'LinuxCameraIndex = 2, CalibratedCameraIndex = 2 }'));
    });

    test('unary with bytes: placeholder variables', () async {
      await render('bytes', 'FaceRecognition',
          () => kiosk().faceRecognition(FaceRecognitionRequest(
              image1: List<int>.filled(5000, 1),
              image2: List<int>.filled(6000, 2),
              threshold: 0.5,
              model: Model.FACENET512,
              similarityMetric: DistanceMetric.EUCLIDEAN_L2)));
      final (dart, cs) = snippets['bytes']!;
      expect(dart, contains('// image1Bytes: the bytes to send'));
      expect(
          dart.split('\n').last,
          'final reply = await KioskClient(GrpcChannelProvider.channel)'
          '.faceRecognition(FaceRecognitionRequest(image1: image1Bytes, '
          'image2: image2Bytes, threshold: 0.5, model: Model.FACENET512, '
          'similarityMetric: DistanceMetric.EUCLIDEAN_L2));');
      expect(
          cs.split('\n').last,
          'var reply = await new Kiosk.KioskClient(GrpcChannelProvider.Channel)'
          '.FaceRecognitionAsync(new FaceRecognitionRequest { '
          'Image1 = ByteString.CopyFrom(image1Bytes), '
          'Image2 = ByteString.CopyFrom(image2Bytes), Threshold = 0.5, '
          'Model = Model.Facenet512, '
          'SimilarityMetric = DistanceMetric.EuclideanL2 });');
    });

    test('server streaming', () async {
      await render('streaming', 'StreamPreview', () async {
        await for (final _
            in kiosk().streamPreview(PreviewRequest(cameraIndex: 2, maxSeconds: 30))) {
          break;
        }
      });
      final (dart, cs) = snippets['streaming']!;
      expect(
          dart,
          'await for (final reply in KioskClient(GrpcChannelProvider.channel)'
          '.streamPreview(PreviewRequest(cameraIndex: 2, maxSeconds: 30))) {\n'
          '  print(reply);\n'
          '}');
      expect(
          cs,
          endsWith('using var call = new Kiosk.KioskClient('
              'GrpcChannelProvider.Channel).StreamPreview('
              'new PreviewRequest { CameraIndex = 2, MaxSeconds = 30 });\n'
              'await foreach (var reply in call.ResponseStream.ReadAllAsync())\n'
              '{\n'
              '    Console.WriteLine(reply);\n'
              '}'));
    });

    test('Empty request (and a streaming Empty one)', () async {
      await render('emptyRequest', 'GetKioskInfo',
          () => kiosk().getKioskInfo(Empty()));
      expect(
          snippets['emptyRequest']!.$1,
          'final reply = await KioskClient(GrpcChannelProvider.channel)'
          '.getKioskInfo(Empty());');
      expect(
          snippets['emptyRequest']!.$2.split('\n').last,
          'var reply = await new Kiosk.KioskClient(GrpcChannelProvider.Channel)'
          '.GetKioskInfoAsync(new Empty());');

      await render('emptyStream', 'StartAutomaticProcess',
          () => kiosk().startAutomaticProcess(Empty()).drain<void>());
      expect(snippets['emptyStream']!.$1,
          startsWith('await for (final reply in KioskClient('
              'GrpcChannelProvider.channel).startAutomaticProcess(Empty())) {'));
    });

    test('a call returning Empty awaits without a reply variable', () async {
      await render('emptyReply', 'SetLightAtCameraIndex',
          () => LightsClient(GrpcChannelProvider.channel)
              .setLightAtCameraIndex(LightIndexRequest(index: 3)));
      expect(
          snippets['emptyReply']!.$1,
          'await LightsClient(GrpcChannelProvider.channel)'
          '.setLightAtCameraIndex(LightIndexRequest(index: 3));');
      expect(
          snippets['emptyReply']!.$2.split('\n').last,
          'await new Lights.LightsClient(GrpcChannelProvider.Channel)'
          '.SetLightAtCameraIndexAsync(new LightIndexRequest { Index = 3 });');
    });
  });

  group('C# naming', () {
    test('properties', () {
      expect(csPropertyName('cie_x'), 'CieX');
      expect(csPropertyName('image1'), 'Image1');
      expect(csPropertyName('timeoutInMs'), 'TimeoutInMs');
      expect(csPropertyName('id_model_id'), 'IdModelId');
    });
    test('enum values', () {
      expect(csEnumValueName('Backlight', 'BACKLIGHT_TOP'), 'Top');
      expect(csEnumValueName('CheckKind', 'CHECK_KIND_UNSPECIFIED'),
          'Unspecified');
      expect(csEnumValueName('CheckVerdict', 'VERDICT_UNSPECIFIED'),
          'VerdictUnspecified');
      expect(csEnumValueName('DistanceMetric', 'EUCLIDEAN_L2'), 'EuclideanL2');
      expect(csEnumValueName('Model', 'FACENET512'), 'Facenet512');
      expect(csEnumValueName('UsageType', 'CPU_COUNT'), 'CpuCount');
    });
  });
}
