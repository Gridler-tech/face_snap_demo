// Rebuild light_settings.json with CURRENT native indexes + correct positions.
// SetCalibration attaches stable device_key/port_path from live enumeration.
import 'dart:io';
import 'package:face_snap_grpc/face_snap_grpc.dart';

// Odroid live enumeration (video# -> idProduct) x correct idProduct -> position.
// video0=0078->2, video1=0045->3, video2=0062->1, video3=0068->5, video4=0057->6, video5=0049->4
const entries = [
  ('0078', 0, 2),
  ('0045', 1, 3),
  ('0062', 2, 1),
  ('0068', 3, 5),
  ('0057', 4, 6),
  ('0049', 5, 4),
];

Future<void> main(List<String> args) async {
  await GrpcChannelProvider.setAddress(args[0], 50051);
  final c = CalibrationClient(GrpcChannelProvider.channel);
  final req = CalibrateRequest();
  for (final (pid, linux, calib) in entries) {
    req.calibrate.add(CalibrateType(
      idModelId: pid, linuxCameraIndex: linux, calibratedCameraIndex: calib));
  }
  final resp = await c.setCalibration(req);
  print('SetCalibration: success=${resp.success} msg=${resp.message}');
  exit(0);
}
