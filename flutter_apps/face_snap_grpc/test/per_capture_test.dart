// Per-capture settings (spec 2026-10-11) against in-process fake servers: settings go to
// the new RPCs (StartAutomaticCapture / StartManualCapture), no settings keep the old ones
// (StartAutomaticProcess / StartManualProcess), the settings used become the first event,
// and an older server — one without the new RPCs, which answers UNIMPLEMENTED — gives
// PerCaptureSettingsNotSupported. An UNIMPLEMENTED after the first event is not that, nor is
// a refusal (INVALID_ARGUMENT); cancelling the subscription cancels the server call.
import 'dart:async';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall, StatusCode;
import 'package:test/test.dart';

/// The jpeg quality that makes [_NewKiosk] fail with UNIMPLEMENTED after the settings used.
const _failLater = 77;

/// The jpeg quality [_NewKiosk] refuses before anything is streamed (the servers' rule text).
const _refused = 20;
const _refusal = 'per-capture setting jpeg_quality: jpeg quality should be between 50 and 100';

/// The photo format that makes [_NewKiosk] stream status rows until the caller cancels.
const _endless = 'endless';

const _notSupported =
    'this FaceSnap server does not support per-capture settings; update the server';

ProcessStepStatus _status(String text) =>
    ProcessStepStatus(index: 2, description: text, status: StatusType.OK);

/// A server with per-capture settings: every capture stream starts with the settings used.
class _NewKiosk extends KioskServiceBase {
  /// The RPCs called, in order, with the settings of the new ones.
  final calls = <String>[];
  final requests = <CaptureRequest>[];

  /// Completed when an endless capture sees the call cancelled.
  Completer<void> cancelled = Completer<void>();

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
      ServiceCall call, Empty request) async* {
    calls.add('StartAutomaticProcess');
    yield ProcessAutomaticResponse(
        settingsUsed: CaptureSettingsUsed(values: CaptureSettings(photoFormat: 'icao_35x45')));
    yield ProcessAutomaticResponse(processStatus: _status('Best Camera was determined'));
    yield ProcessAutomaticResponse(
        imageData: ProcessImageData(index: 2, width: 2, height: 3, chunkData: [1, 2]));
  }

  @override
  Stream<ProcessAutomaticResponse> startAutomaticCapture(
      ServiceCall call, CaptureRequest request) async* {
    calls.add('StartAutomaticCapture');
    requests.add(request);
    if (request.settings.jpegQuality == _refused) throw GrpcError.invalidArgument(_refusal);
    if (request.settings.photoFormat == _endless) {
      yield ProcessAutomaticResponse(settingsUsed: CaptureSettingsUsed());
      while (!call.isCanceled) {
        yield ProcessAutomaticResponse(processStatus: _status('Searching'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      cancelled.complete();
      return;
    }
    final values = CaptureSettings(photoFormat: 'icao_35x45', jpegQuality: 95)
      ..mergeFromMessage(request.settings);
    yield ProcessAutomaticResponse(
        settingsUsed: CaptureSettingsUsed(
            values: values,
            overridden: [
              if (request.settings.hasPhotoFormat()) 'photo_format',
              if (request.settings.hasJpegQuality()) 'jpeg_quality',
              if (request.settings.hasBackgroundStrength()) 'background_strength',
            ]));
    if (request.settings.jpegQuality == _failLater) {
      throw GrpcError.unimplemented('something later is not implemented');
    }
    yield ProcessAutomaticResponse(processStatus: _status('Best Camera was determined'));
    yield ProcessAutomaticResponse(
        imageData: ProcessImageData(index: 2, width: 2, height: 3, chunkData: [1, 2]));
  }

  @override
  Stream<ProcessManualResponse> startManualProcess(
      ServiceCall call, Empty request) async* {
    calls.add('StartManualProcess');
    yield ProcessManualResponse(
        settingsUsed: CaptureSettingsUsed(values: CaptureSettings(jpegQuality: 95)));
    yield ProcessManualResponse(
        imageData: ProcessImageData(index: 1, width: 2, height: 3, chunkData: [5]));
  }

  @override
  Stream<ProcessManualResponse> startManualCapture(
      ServiceCall call, CaptureRequest request) async* {
    calls.add('StartManualCapture');
    requests.add(request);
    if (request.settings.jpegQuality == _refused) throw GrpcError.invalidArgument(_refusal);
    yield ProcessManualResponse(
        settingsUsed: CaptureSettingsUsed(
            values: CaptureSettings(jpegQuality: 95)..mergeFromMessage(request.settings),
            overridden: [if (request.settings.hasJpegQuality()) 'jpeg_quality']));
    if (request.settings.jpegQuality == _failLater) {
      throw GrpcError.unimplemented('something later is not implemented');
    }
    yield ProcessManualResponse(
        imageData: ProcessImageData(index: 1, width: 2, height: 3, chunkData: [5]));
    yield ProcessManualResponse(
        imageData: ProcessImageData(index: 2, width: 2, height: 3, chunkData: [6]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

/// A server from before per-capture settings: no new RPCs (noSuchMethod answers them
/// UNIMPLEMENTED), no settings used.
class _OldKiosk extends KioskServiceBase {
  final calls = <String>[];

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
      ServiceCall call, Empty request) async* {
    calls.add('StartAutomaticProcess');
    yield ProcessAutomaticResponse(processStatus: _status('Best Camera was determined'));
  }

  @override
  Stream<ProcessManualResponse> startManualProcess(
      ServiceCall call, Empty request) async* {
    calls.add('StartManualProcess');
    yield ProcessManualResponse(
        imageData: ProcessImageData(index: 1, width: 2, height: 3, chunkData: [5]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

final _newKiosk = _NewKiosk();
final _oldKiosk = _OldKiosk();
late Server _newServer;
late Server _oldServer;

Future<void> _useNewServer() => GrpcChannelProvider.setAddress('127.0.0.1', _newServer.port!);
Future<void> _useOldServer() => GrpcChannelProvider.setAddress('127.0.0.1', _oldServer.port!);

String _kind(CaptureEvent e) => e.runtimeType.toString();

void main() {
  setUpAll(() async {
    _newServer = Server.create(services: [_newKiosk]);
    await _newServer.serve(address: InternetAddress.loopbackIPv4, port: 0);
    _oldServer = Server.create(services: [_oldKiosk]);
    await _oldServer.serve(address: InternetAddress.loopbackIPv4, port: 0);
  });

  tearDownAll(() async {
    await GrpcChannelProvider.channel.shutdown();
    await _newServer.shutdown();
    await _oldServer.shutdown();
  });

  setUp(() {
    _newKiosk.calls.clear();
    _newKiosk.requests.clear();
    _newKiosk.cancelled = Completer<void>();
    _oldKiosk.calls.clear();
  });

  group('automatic', () {
    test('the settings reach the new RPC', () async {
      await _useNewServer();
      final settings = CaptureSettings(photoFormat: 'us_2x2', backgroundStrength: 2);
      final events = await startAutomaticCapture(settings: settings).toList();

      expect(_newKiosk.calls, ['StartAutomaticCapture']);
      expect(_newKiosk.requests.single.settings, settings);
      expect(events.map(_kind), ['CaptureSettingsReport', 'CaptureStatus', 'CapturePhoto']);
      final report = events.first as CaptureSettingsReport;
      expect(report.values.photoFormat, 'us_2x2');
      expect(report.values.backgroundStrength, 2);
      expect(report.values.jpegQuality, 95); // the kiosk's own value, in force
      expect(report.overridden, ['photo_format', 'background_strength']);
    });

    test('an empty CaptureSettings still uses the new RPC', () async {
      await _useNewServer();
      final events = await startAutomaticCapture(settings: CaptureSettings()).toList();
      expect(_newKiosk.calls, ['StartAutomaticCapture']);
      expect((events.first as CaptureSettingsReport).overridden, isEmpty);
    });

    test('no settings use the old RPC', () async {
      await _useNewServer();
      final events = await startAutomaticCapture().toList();
      expect(_newKiosk.calls, ['StartAutomaticProcess']);
      expect(events.map(_kind), ['CaptureSettingsReport', 'CaptureStatus', 'CapturePhoto']);

      // An older server: as before, and no settings report is made up.
      await _useOldServer();
      final old = await startAutomaticCapture().toList();
      expect(_oldKiosk.calls, ['StartAutomaticProcess']);
      expect(old.map(_kind), ['CaptureStatus']);
    });

    test('an old server gives PerCaptureSettingsNotSupported', () async {
      await _useOldServer();
      await expectLater(
          startAutomaticCapture(settings: CaptureSettings(jpegQuality: 90)).toList(),
          throwsA(isA<PerCaptureSettingsNotSupported>()
              .having((e) => e.toString(), 'toString()', _notSupported)
              .having((e) => e.cause?.code, 'cause.code', StatusCode.unimplemented)));
      expect(_oldKiosk.calls, isEmpty);
    });

    test('an UNIMPLEMENTED after the first event stays a GrpcError', () async {
      await _useNewServer();
      final events = <CaptureEvent>[];
      await expectLater(
          startAutomaticCapture(settings: CaptureSettings(jpegQuality: _failLater))
              .forEach(events.add),
          throwsA(isA<GrpcError>()
              .having((e) => e.code, 'code', StatusCode.unimplemented)
              .having((e) => e.message, 'message', 'something later is not implemented')));
      expect(events.map(_kind), ['CaptureSettingsReport']);
    });

    test('a refusal before the first event stays a GrpcError', () async {
      await _useNewServer();
      await expectLater(
          startAutomaticCapture(settings: CaptureSettings(jpegQuality: _refused)).toList(),
          throwsA(isA<GrpcError>()
              .having((e) => e.code, 'code', StatusCode.invalidArgument)
              .having((e) => e.message, 'message', _refusal)));
    });

    test('cancelling the subscription cancels the server call', () async {
      await _useNewServer();
      final events = <CaptureEvent>[];
      await for (final event
          in startAutomaticCapture(settings: CaptureSettings(photoFormat: _endless))) {
        events.add(event);
        if (events.length == 3) break; // leaving the loop cancels the subscription
      }
      expect(events.map(_kind), ['CaptureSettingsReport', 'CaptureStatus', 'CaptureStatus']);
      await _newKiosk.cancelled.future.timeout(const Duration(seconds: 5));
    });
  });

  group('manual', () {
    test('the settings reach the new RPC', () async {
      await _useNewServer();
      final settings = CaptureSettings(jpegQuality: 80);
      final events = await startManualCapture(settings: settings).toList();

      expect(_newKiosk.calls, ['StartManualCapture']);
      expect(_newKiosk.requests.single.settings, settings);
      expect(events.map(_kind), ['CaptureSettingsReport', 'CameraPhoto', 'CameraPhoto']);
      final report = events.first as CaptureSettingsReport;
      expect(report.values.jpegQuality, 80);
      expect(report.overridden, ['jpeg_quality']);
      expect([for (final e in events.skip(1)) (e as CameraPhoto).cameraIndex], [1, 2]);
    });

    test('no settings use the old RPC', () async {
      await _useNewServer();
      final events = await startManualCapture().toList();
      expect(_newKiosk.calls, ['StartManualProcess']);
      expect(events.map(_kind), ['CaptureSettingsReport', 'CameraPhoto']);

      await _useOldServer();
      final old = await startManualCapture().toList();
      expect(_oldKiosk.calls, ['StartManualProcess']);
      expect(old.map(_kind), ['CameraPhoto']);
    });

    test('an old server gives PerCaptureSettingsNotSupported', () async {
      await _useOldServer();
      await expectLater(
          startManualCapture(settings: CaptureSettings(jpegQuality: 90)).toList(),
          throwsA(isA<PerCaptureSettingsNotSupported>()
              .having((e) => e.toString(), 'toString()', _notSupported)
              .having((e) => e.cause?.code, 'cause.code', StatusCode.unimplemented)));
      expect(_oldKiosk.calls, isEmpty);
    });

    test('an UNIMPLEMENTED after the first event stays a GrpcError', () async {
      await _useNewServer();
      final events = <CaptureEvent>[];
      await expectLater(
          startManualCapture(settings: CaptureSettings(jpegQuality: _failLater))
              .forEach(events.add),
          throwsA(isA<GrpcError>()
              .having((e) => e.code, 'code', StatusCode.unimplemented)));
      expect(events.map(_kind), ['CaptureSettingsReport']);
    });

    test('a refusal before the first event stays a GrpcError', () async {
      await _useNewServer();
      await expectLater(
          startManualCapture(settings: CaptureSettings(jpegQuality: _refused)).toList(),
          throwsA(isA<GrpcError>()
              .having((e) => e.code, 'code', StatusCode.invalidArgument)
              .having((e) => e.message, 'message', _refusal)));
    });
  });
}
