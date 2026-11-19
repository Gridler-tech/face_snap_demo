// FL-12: a unary call made without a timeout gets a default deadline on every
// channel GrpcChannelProvider hands out (traced or not, the shared one and the
// independent ones), so a vanished server fails the call instead of freezing
// the page that waits for it. Long RPCs and streams are exempt; a timeout the
// caller set always wins. An in-process fake server records the deadline each
// call arrived with.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall;
import 'package:test/test.dart';

/// The deadline each call arrived with, as time left at arrival (null = none).
final arrived = <String, Duration?>{};

void note(String name, ServiceCall call) =>
    arrived[name] = call.deadline?.difference(DateTime.now());

class _Settings extends SettingsServiceBase {
  @override
  Future<CropResponse> setCrop(ServiceCall call, CropRequest request) async {
    note('SetCrop', call);
    return CropResponse(message: request.value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Calibration extends CalibrationServiceBase {
  @override
  Future<PersonCalibrationResponse> calibrateByPerson(
      ServiceCall call, Empty request) async {
    note('CalibrateByPerson', call);
    return PersonCalibrationResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Monitoring extends MonitoringServiceBase {
  @override
  Stream<KioskStatusResponse> getKioskStatus(ServiceCall call, Empty request) async* {
    note('GetKioskStatus', call);
    yield KioskStatusResponse(status: 'OK');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

void main() {
  late Server server;

  setUpAll(() async {
    server = Server.create(services: [_Settings(), _Calibration(), _Monitoring()]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
    await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  });

  tearDownAll(() async {
    RpcTrace.enabled = false;
    await GrpcChannelProvider.channel.shutdown();
    await server.shutdown();
  });

  setUp(() {
    arrived.clear();
    RpcTrace.enabled = false;
    RpcTrace.clear();
  });

  // Every kind of channel the provider hands out, each with the trace off and on.
  final channels = <String, ClientChannel Function()>{
    'the shared channel': () => GrpcChannelProvider.channel,
    'an openChannel': () => GrpcChannelProvider.openChannel('127.0.0.1', server.port!),
    'an openPlainChannel': () =>
        GrpcChannelProvider.openPlainChannel('127.0.0.1', server.port!),
  };

  for (final MapEntry(key: name, value: open) in channels.entries) {
    for (final traced in [false, true]) {
      final label = '$name, trace ${traced ? 'on' : 'off'}';

      test('$label: a unary call without a timeout gets a deadline', () async {
        RpcTrace.enabled = traced;
        final channel = open();
        await SettingsClient(channel).setCrop(CropRequest(value: true));
        if (channel != GrpcChannelProvider.channel) await channel.shutdown();
        final left = arrived['SetCrop'];
        expect(left, isNotNull, reason: 'no deadline reached the server');
        expect(left!.inSeconds, greaterThan(0));
        expect(left.inSeconds, lessThanOrEqualTo(60));
      });

      test('$label: an explicit timeout wins', () async {
        RpcTrace.enabled = traced;
        final channel = open();
        await SettingsClient(channel).setCrop(CropRequest(value: true),
            options: CallOptions(timeout: const Duration(minutes: 10)));
        if (channel != GrpcChannelProvider.channel) await channel.shutdown();
        expect(arrived['SetCrop']!.inMinutes, 9, reason: '10 min less the trip');
      });

      test('$label: a long RPC (a calibration scan) is exempt', () async {
        RpcTrace.enabled = traced;
        final channel = open();
        await CalibrationClient(channel).calibrateByPerson(Empty());
        if (channel != GrpcChannelProvider.channel) await channel.shutdown();
        expect(arrived.containsKey('CalibrateByPerson'), isTrue);
        expect(arrived['CalibrateByPerson'], isNull);
      });

      test('$label: a stream is exempt', () async {
        RpcTrace.enabled = traced;
        final channel = open();
        await MonitoringClient(channel).getKioskStatus(Empty()).toList();
        if (channel != GrpcChannelProvider.channel) await channel.shutdown();
        expect(arrived.containsKey('GetKioskStatus'), isTrue);
        expect(arrived['GetKioskStatus'], isNull);
      });
    }
  }

  group('the table', () {
    test('every exempt name is a unary RPC the services have (a rename trips this)', () {
      for (final path in kNoDefaultDeadline) {
        expect(RpcTrace.kindOf(path), RpcKind.unary, reason: path);
      }
    });

    test('the default is the table value', () {
      final o = withDefaultDeadline('/settings.Settings/SetCrop', CallOptions());
      expect(o.timeout, kDefaultUnaryDeadline);
      expect(kDefaultUnaryDeadline, const Duration(seconds: 30));
    });

    test('an unknown path and a stream are left alone; the options are not changed', () {
      final own = CallOptions(metadata: {'x-caller': 'a'});
      expect(withDefaultDeadline('/nope.Nope/Nothing', own).timeout, isNull);
      expect(withDefaultDeadline('/kiosk.Kiosk/StartAutomaticProcess', own).timeout, isNull);
      final merged = withDefaultDeadline('/settings.Settings/SetCrop', own);
      expect(merged.metadata, {'x-caller': 'a'});
      expect(own.timeout, isNull);
    });
  });
}
