import 'package:face_snap_grpc/face_snap_grpc.dart';

/// The kiosk settings snapshot, loaded at connect and refreshed on demand —
/// the Flutter counterpart of the MAUI app's KioskSettings globals.
class SettingsState {
  SettingsState._();

  static LoadSettingsResponse? current;

  static SettingsClient get client => SettingsClient(GrpcChannelProvider.channel);

  static Future<LoadSettingsResponse> refresh() async {
    final response = await client.loadSettings(Empty());
    current = response;
    return response;
  }
}
