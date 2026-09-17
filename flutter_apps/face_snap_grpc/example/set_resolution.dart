import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  await GrpcChannelProvider.setAddress(args[0], 50051);
  final s = SettingsClient(GrpcChannelProvider.channel);
  final r = await s.setResolution(ResolutionRequest(
      width: int.parse(args[1]), height: int.parse(args[2])));
  print('resolution now: ${r.width}x${r.height}');
  exit(0);
}
