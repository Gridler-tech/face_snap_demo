import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/foundation.dart';

/// The kiosk settings snapshot, loaded at connect and refreshed on demand —
/// the Flutter counterpart of the MAUI app's KioskSettings globals.
class SettingsState {
  SettingsState._();

  static LoadSettingsResponse? current;

  /// Bumped whenever [current] is replaced. Pages sitting const in the nav's
  /// IndexedStack never rebuild on a page switch, so without this listener a
  /// server that comes up AFTER app start leaves them on "No server
  /// connected" forever (same pattern as PhotoStore.revision).
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static SettingsClient get client => SettingsClient(GrpcChannelProvider.channel);

  /// Load the snapshot. Always under a deadline: without one, a call to a
  /// dead/absent host never completes (gRPC keeps retrying the connection),
  /// which froze the server picker on "Connecting…" indefinitely.
  static Future<LoadSettingsResponse> refresh(
      {Duration timeout = const Duration(seconds: 10)}) async {
    final response = await client.loadSettings(Empty(),
        options: CallOptions(timeout: timeout));
    current = response;
    revision.value++;
    return response;
  }
}
