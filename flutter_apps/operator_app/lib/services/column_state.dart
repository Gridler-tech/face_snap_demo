import 'dart:async';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/foundation.dart';

import 'settings_state.dart';

/// gRPC status UNIMPLEMENTED (`StatusCode.unimplemented`; `grpc` is only a dev dependency).
const _unimplemented = 12;

/// The connected server's column profile (GetColumnProfile; spec 2026-10-10 section 5.5):
/// what the Column page shows and what the ● marks on the Lighting, Calibration and Camera
/// pages read. A server from before the column profile answers UNIMPLEMENTED: [available]
/// stays false and the Column page is hidden.
class ColumnState {
  ColumnState._();

  static ColumnProfileResponse? current;

  /// The server (SettingsState.serverKey) [current] was read from.
  static String? _currentFor;

  /// The server answered GetColumnProfile (the Column page is shown).
  static bool available = false;

  /// Bumped whenever [current] or [available] changes.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Timer? _touch;

  /// Read the profile again (connect, a server switch, after a column action). Never
  /// throws: a server that cannot be reached keeps the last answer, when that answer is
  /// its own; another server's answer is dropped (a switch to a server that does not
  /// answer).
  static Future<void> refresh() async {
    final server = SettingsState.serverKey;
    try {
      final response = await SettingsState.client.getColumnProfile(Empty(),
          options: CallOptions(timeout: const Duration(seconds: 10)));
      if (server != SettingsState.serverKey) return;
      current = response;
      _currentFor = server;
      available = true;
    } catch (e) {
      if (server != SettingsState.serverKey) return;
      final unimplemented = e is GrpcError && e.code == _unimplemented;
      if (!unimplemented && (current == null || _currentFor == server)) return;
      current = null;
      _currentFor = null;
      available = false;
    }
    revision.value++;
  }

  /// A setting may have changed on the server: read the profile again shortly after (a
  /// slider sends a burst of calls). Nothing on a server without the column profile.
  static void touch() {
    if (!available) return;
    _touch?.cancel();
    _touch = Timer(const Duration(milliseconds: 400), refresh);
  }

  /// Whether one of [names] differs from the column's standard on the server.
  static bool anyChanged(Iterable<String> names) {
    final settings = current?.settings;
    if (settings == null) return false;
    return settings.any((s) => s.changed && names.contains(s.name));
  }

  /// Tests: forget the server's answer.
  static void reset() {
    _touch?.cancel();
    current = null;
    _currentFor = null;
    available = false;
    revision.value++;
  }
}
