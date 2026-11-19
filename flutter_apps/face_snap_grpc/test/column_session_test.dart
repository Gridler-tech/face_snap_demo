// The column-session header (spec 2026-10-10 section 4.12): off by default; switched on
// (the operator app), every channel GrpcChannelProvider hands out sends
// facesnap-column-session: 1 - the shared one with the trace off and on, every openChannel,
// and the untraced openPlainChannel (the updater's factory write and its SSH forward). An
// in-process fake server records the header of each call.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:grpc/grpc.dart' show Server, ServiceCall;
import 'package:test/test.dart';

class _Settings extends SettingsServiceBase {
  final headers = <String?>[];

  @override
  Future<CropResponse> setCrop(ServiceCall call, CropRequest request) async {
    headers.add(call.clientMetadata?[GrpcChannelProvider.columnSessionHeader]);
    return CropResponse(message: request.value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

void main() {
  late Server server;
  final settings = _Settings();

  setUpAll(() async {
    server = Server.create(services: [settings]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
    await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  });

  tearDownAll(() async {
    GrpcChannelProvider.useColumnSession = false;
    RpcTrace.enabled = false;
    await GrpcChannelProvider.channel.shutdown();
    await server.shutdown();
  });

  setUp(() {
    settings.headers.clear();
    GrpcChannelProvider.useColumnSession = false;
    RpcTrace.enabled = false;
    RpcTrace.clear();
  });

  Future<void> crop(ClientChannel channel, {CallOptions? options}) =>
      SettingsClient(channel).setCrop(CropRequest(value: true), options: options);

  Future<void> cropOn(ClientChannel channel) async {
    await crop(channel);
    await channel.shutdown();
  }

  test('off by default: no channel sends the column-session header', () async {
    expect(GrpcChannelProvider.useColumnSession, isFalse);
    await crop(GrpcChannelProvider.channel);
    await cropOn(GrpcChannelProvider.openChannel('127.0.0.1', server.port!));
    await cropOn(GrpcChannelProvider.openPlainChannel('127.0.0.1', server.port!));
    expect(settings.headers, [null, null, null]);
  });

  test('switched on: every channel sends facesnap-column-session: 1, traced or not', () async {
    GrpcChannelProvider.useColumnSession = true;
    await crop(GrpcChannelProvider.channel);
    RpcTrace.enabled = true;
    await crop(GrpcChannelProvider.channel);
    await cropOn(GrpcChannelProvider.openChannel('127.0.0.1', server.port!));
    await cropOn(GrpcChannelProvider.openPlainChannel('127.0.0.1', server.port!));
    expect(settings.headers, ['1', '1', '1', '1']);
    expect(GrpcChannelProvider.columnSessionHeader, 'facesnap-column-session');
  });

  test('switched on: a call with its own metadata keeps it and gets the header too', () async {
    GrpcChannelProvider.useColumnSession = true;
    final own = CallOptions(metadata: {'x-caller': 'a'});
    expect(withColumnSession(own).metadata,
        {'x-caller': 'a', GrpcChannelProvider.columnSessionHeader: '1'});
    await crop(GrpcChannelProvider.channel, options: own);
    expect(settings.headers, ['1']);
    expect(own.metadata, {'x-caller': 'a'}, reason: "the caller's options are not changed");
  });

  test("switched on: a header the caller set itself is kept, as in the C# SDK", () async {
    GrpcChannelProvider.useColumnSession = true;
    final own = CallOptions(
        metadata: {GrpcChannelProvider.columnSessionHeader: '0'},
        timeout: const Duration(seconds: 7));
    final merged = withColumnSession(own);
    expect(merged.metadata, {GrpcChannelProvider.columnSessionHeader: '0'});
    expect(merged.timeout, const Duration(seconds: 7), reason: "the caller's other options are kept");
    await crop(GrpcChannelProvider.channel, options: own);
    expect(settings.headers, ['0']);
  });

  test('the plain channel is not traced; the shared one is', () async {
    RpcTrace.enabled = true;
    await cropOn(GrpcChannelProvider.openPlainChannel('127.0.0.1', server.port!));
    expect(RpcTrace.calls.where((c) => c.method == 'SetCrop'), isEmpty);
    await crop(GrpcChannelProvider.channel);
    expect(RpcTrace.calls.where((c) => c.method == 'SetCrop').length, 1);
  });
}
