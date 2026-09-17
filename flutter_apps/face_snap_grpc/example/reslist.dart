import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';
Future<void> main(List<String> args) async {
  await GrpcChannelProvider.setAddress(args[0], 50051);
  final s = await SettingsClient(GrpcChannelProvider.channel).loadSettings(Empty());
  print('resolutions: ${s.cameraResolutions.map((r) => "${r.width}x${r.height}").join(", ")}');
  print('wb_auto? checking camera...');
  final c = await CameraClient(GrpcChannelProvider.channel).loadSettings(Empty());
  print('camera: wb_auto=${c.whiteBalanceTemperatureAuto} wb_temp=${c.whiteBalanceTemperature} exposure=${c.exposureAbsolute}');
  print('leds: R=${s.intensityRed} G=${s.intensityGreen} B=${s.intensityBlue}');
  exit(0);
}
