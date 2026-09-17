import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  await GrpcChannelProvider.setAddress(args[0], 50051);
  final cam = CameraClient(GrpcChannelProvider.channel);
  await cam.setWhiteBalanceTemperatureAuto(
      WhiteBalanceTemperatureAutoRequest(value: false));
  await cam.setWhiteBalanceTemperature(
      WhiteBalanceTemperatureRequest(value: int.parse(args[1])));
  final c = await cam.loadSettings(Empty());
  print('now: wb_auto=${c.whiteBalanceTemperatureAuto} wb_temp=${c.whiteBalanceTemperature}');
  exit(0);
}
