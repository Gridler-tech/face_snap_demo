// The in-process gRPC server the widget tests talk to over a real loopback
// connection: the test's fake services plus a stand-in for every other FaceSnap
// service, so the server knows every service the app may call.
//
// Why the stand-ins: the pages call more services than a test fakes (the
// Capture page loads the settings before every capture, for instance). A call
// to a service the server does not have at all is answered UNIMPLEMENTED by
// grpc 5.1.0 without ever resuming that call's paused request stream. When the
// request's END_STREAM then reaches the server after that answer (separate TCP
// reads, on a busy machine), the call stays queued in the http2 connection, and
// the server's shutdown in the tear-down fails the test with the http2
// assertion "'_stream2messageQueue.isEmpty': is not true". A stand-in answers
// UNIMPLEMENTED through the normal handler path, which reads the request to
// its end.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:grpc/grpc.dart' show Server, Service;

/// Serves [services] on [address] (loopback by default) at a free port, with a
/// stand-in for every FaceSnap service not among them. The caller shuts the
/// server down.
Future<Server> serveFakes(List<Service> services, {InternetAddress? address}) async {
  final served = {for (final service in services) service.$name};
  final server = Server.create(services: [
    ...services,
    for (final standIn in _standIns())
      if (!served.contains(standIn.$name)) standIn,
  ]);
  await server.serve(address: address ?? InternetAddress.loopbackIPv4, port: 0);
  return server;
}

List<Service> _standIns() => [
      _Calibration(),
      _Camera(),
      _Kiosk(),
      _Lights(),
      _Monitoring(),
      _Settings(),
    ];

// Every call answers UNIMPLEMENTED, like a server without the feature.
class _Calibration extends CalibrationServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Camera extends CameraServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Kiosk extends KioskServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Lights extends LightsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Monitoring extends MonitoringServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

class _Settings extends SettingsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}
