// All LEDs off, then light a single camera's LED band. args: host index
import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';
Future<void> main(List<String> args) async {
  await GrpcChannelProvider.setAddress(args[0], 50051);
  final l = LightsClient(GrpcChannelProvider.channel);
  await l.setAllLights(AllLightsRequest(status: false));
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final idx = int.parse(args[1]);
  await l.setLightAtCameraIndex(LightIndexRequest(index: idx));
  print('lit camera index $idx (all others off)');
  exit(0);
}
