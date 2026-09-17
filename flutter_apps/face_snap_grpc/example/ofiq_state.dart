import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  await GrpcChannelProvider.setAddress(args[0], 50051);
  final s = await SettingsClient(GrpcChannelProvider.channel).loadSettings(Empty());
  print('ofiq_checks: ${s.ofiqChecks}');
  print('sharpness_check: ${s.sharpnessCheck}  head_pose: ${s.headPoseCheck}  '
      'gaze: ${s.gazeCheck}  lighting_even: ${s.lightingEvennessCheck}');
  exit(0);
}
