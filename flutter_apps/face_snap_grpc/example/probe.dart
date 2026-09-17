// Walking-skeleton probe: connect to the FaceSnap server and load the kiosk
// settings, proving protos -> Dart stubs -> channel -> live server end to end.
//
// Run (server must be listening on localhost:50051):
//   dart run example/probe.dart [host] [port]
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  final host = args.isNotEmpty ? args[0] : 'localhost';
  final port = args.length > 1 ? int.parse(args[1]) : 50051;
  await GrpcChannelProvider.setAddress(host, port);

  final settings = SettingsClient(GrpcChannelProvider.channel);
  final response = await settings.loadSettings(Empty());

  print('Connected to $host:$port');
  print('  resolution        : ${response.width}x${response.height}');
  print('  crop              : ${response.crop} '
      '(${response.cropWidth}x${response.cropHeight})');
  print('  photo format      : ${response.photoFormat}');
  print('  background method : ${response.backgroundMethod}');
  print('  background color  : ${response.backgroundColor}');
  print('  jpeg quality      : ${response.jpegQuality}');

  await GrpcChannelProvider.channel.shutdown();
  exit(0);
}
