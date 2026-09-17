import 'dart:convert';
import 'dart:io';

/// Persists the operator app's own bits of config (server host/port) as JSON
/// under %APPDATA%\FaceSnapOperator, mirroring the MAUI app's saved address.
class AppConfig {
  AppConfig._();

  static String host = 'localhost';
  static int port = 50051;

  // SSH credentials for the kiosk-board server card. No password ships in
  // the app: the operator sets board_user / board_password once in
  // config.json — no rebuild needed.
  static String boardUser = 'root';
  static String boardPassword = '';

  // Developer mode: shows the </> badges that explain how to implement each
  // control with the FaceSnap SDKs (see ui/dev_info.dart).
  static bool devMode = false;

  /// The app's data folder (%APPDATA%\FaceSnapOperator) — also the parent of
  /// PhotoStore's captures directory.
  static String get appDataDir {
    final appData = Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        '.';
    return '$appData\\FaceSnapOperator';
  }

  static File get _file => File('$appDataDir\\config.json');

  static Future<void> load() async {
    try {
      final file = _file;
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      host = json['host'] as String? ?? host;
      port = json['port'] as int? ?? port;
      boardUser = json['board_user'] as String? ?? boardUser;
      boardPassword = json['board_password'] as String? ?? boardPassword;
      devMode = json['dev_mode'] as bool? ?? devMode;
    } catch (_) {
      // Corrupt/missing config falls back to defaults.
    }
  }

  static Future<void> save() async {
    final file = _file;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({
      'host': host,
      'port': port,
      'board_user': boardUser,
      'board_password': boardPassword,
      'dev_mode': devMode,
    }));
  }
}
