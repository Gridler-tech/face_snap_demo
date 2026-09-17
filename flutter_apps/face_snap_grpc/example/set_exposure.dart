import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  await GrpcChannelProvider.setAddress(args[0], 50051);
  final cam = CameraClient(GrpcChannelProvider.channel);
  await cam.setExposureAbsolute(ExposureAbsoluteRequest(value: int.parse(args[1])));
  final c = await cam.loadSettings(Empty());
  print('now: exposure=${c.exposureAbsolute} gain=${c.gain}');
  exit(0);
}
