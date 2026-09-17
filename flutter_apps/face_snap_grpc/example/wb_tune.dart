// White-balance triage: report camera WB state + lighting intensities, then
// run the LED auto-tune (streams progress) and report the final white point.
import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  await GrpcChannelProvider.setAddress(args[0], 50051);
  final cam = CameraClient(GrpcChannelProvider.channel);
  final settings = SettingsClient(GrpcChannelProvider.channel);
  final lights = LightsClient(GrpcChannelProvider.channel);

  final c = await cam.loadSettings(Empty());
  print('camera: wb_auto=${c.whiteBalanceTemperatureAuto} '
      'wb_temp=${c.whiteBalanceTemperature} exposure_auto_priority=${c.exposureAutoPriority} '
      'exposure=${c.exposureAbsolute} gain=${c.gain}');
  final s = await settings.loadSettings(Empty());
  print('leds: R=${s.intensityRed} G=${s.intensityGreen} B=${s.intensityBlue} lighting=${s.lighting}');

  print('--- auto-tune white point ---');
  try {
    await for (final u in lights.autoTuneWhitePoint(Empty(),
        options: CallOptions(timeout: const Duration(seconds: 180)))) {
      print('${u.message}  R=${u.red} G=${u.green} B=${u.blue} '
          'lux=${u.stripLux.toStringAsFixed(1)} dist=${u.distance.toStringAsFixed(4)} '
          '${u.done ? (u.success ? "[DONE-OK]" : "[DONE-FAILED]") : ""}');
    }
  } catch (e) {
    print('auto-tune error: $e');
  }

  final s2 = await settings.loadSettings(Empty());
  print('leds after: R=${s2.intensityRed} G=${s2.intensityGreen} B=${s2.intensityBlue}');
  exit(0);
}
