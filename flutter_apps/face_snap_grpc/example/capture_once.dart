// Run one automatic capture, print every status line, save the photo.
//
//   dart run example/capture_once.dart <host> <out.jpg> [port] [photo_format]
//
// With a photo_format (e.g. us_2x2) the capture runs with that format as a per-capture
// setting: the kiosk's own format is unchanged afterwards.
import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  final port = args.length > 2 ? int.parse(args[2]) : 50051;
  await GrpcChannelProvider.setAddress(args[0], port);
  final out = args[1];
  final settings = args.length > 3 ? CaptureSettings(photoFormat: args[3]) : null;
  var photos = 0;
  try {
    await for (final event in startAutomaticCapture(settings: settings)) {
      switch (event) {
        case CaptureSettingsReport(:final values, :final overridden):
          print('SETTINGS: format ${values.photoFormat}, '
              'overridden: ${overridden.isEmpty ? '-' : overridden.join(', ')}');
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
        case CaptureCheck(:final result):
          print('CHECK: ${result.name} ${result.verdict.name}');
        case CaptureInstruction(:final kind, :final progress, :final text):
          print('INSTRUCTION: ${kind.name} ${(progress * 100).round()} % $text');
      }
    }
  } on PerCaptureSettingsNotSupported catch (e) {
    print('REFUSED: $e');
    exit(2);
  } on GrpcError catch (e) {
    print('REFUSED: ${e.codeName} ${e.message}'); // e.g. a value outside its rule
    exit(2);
  }
  print(photos > 0 ? 'CAPTURE-OK' : 'NO-PHOTO');
  exit(0);
}
