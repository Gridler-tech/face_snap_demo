// Run one automatic capture, print every status line, save the photo.
import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  final port = args.length > 2 ? int.parse(args[2]) : 50051;
  await GrpcChannelProvider.setAddress(args[0], port);
  final out = args[1];
  var photos = 0;
  await for (final event in startAutomaticCapture()) {
    switch (event) {
      case CaptureStatus(:final description):
        print('STATUS: $description');
      case CapturePhoto(:final bytes):
        photos++;
        File(out).writeAsBytesSync(bytes);
        print('PHOTO: ${bytes.length} bytes -> $out');
      case CameraPhoto(:final cameraIndex, :final bytes):
        photos++;
        File(out).writeAsBytesSync(bytes);
        print('PHOTO(cam $cameraIndex): ${bytes.length} bytes -> $out');
    }
  }
  print(photos > 0 ? 'CAPTURE-OK' : 'NO-PHOTO');
  exit(0);
}
