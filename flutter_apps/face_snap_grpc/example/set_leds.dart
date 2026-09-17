import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  await GrpcChannelProvider.setAddress(args[0], 50051);
  final s = SettingsClient(GrpcChannelProvider.channel);
  final v = int.parse(args[1]);
  await s.setIntensityRed(IntensityRequest(value: v));
  await s.setIntensityGreen(IntensityRequest(value: v));
  await s.setIntensityBlue(IntensityRequest(value: v));
  final r = await s.loadSettings(Empty());
  print('leds: R=${r.intensityRed} G=${r.intensityGreen} B=${r.intensityBlue}');
  exit(0);
}
