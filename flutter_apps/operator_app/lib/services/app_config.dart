import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../util/card_reference.dart' show kCards, kClassicVersions;

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

  // The factory key of the column profile (spec 2026-10-10 section 5.4): the
  // updater's factory actions send it to WriteColumnFactory. Set once in
  // config.json (factory_key); never shown, logged or put in a message.
  static String factoryKey = '';

  // The board the Updater page last worked on. Kept apart from [host]: [host]
  // is the server the app is CONNECTED to (the shared gRPC channel follows it
  // at startup and connectTo sets both together). Until 2026-10-08 the
  // Updater saved its board into [host], so after updating a kiosk the Kiosk
  // page marked that kiosk "Connected" while every call (a capture included)
  // still went to the old server.
  static String updaterHost = '';

  // Developer mode: shows the </> badges that explain how to implement each
  // control with the FaceSnap SDKs (see ui/dev_info.dart).
  static bool devMode = false;

  // The colour card of the photo colour calibration (spec 2026-11-02 section
  // 2): spyder24 or classic, and the Classic's version (pre2014 or 2014).
  static String colourCard = 'spyder24';
  static String colourCardVersion = 'pre2014';

  /// Tests point the data folder somewhere harmless; null = the real one.
  static String? appDataDirOverride;

  /// The app's data folder (%APPDATA%\FaceSnapOperator) — also the parent of
  /// PhotoStore's captures directory.
  static String get appDataDir {
    if (appDataDirOverride != null) return appDataDirOverride!;
    final appData = Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        '.';
    return '$appData${Platform.pathSeparator}FaceSnapOperator';
  }

  static File get _file => File('$appDataDir${Platform.pathSeparator}config.json');

  static Future<void> load() async {
    try {
      final file = _file;
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      host = json['host'] as String? ?? host;
      port = json['port'] as int? ?? port;
      boardUser = json['board_user'] as String? ?? boardUser;
      boardPassword = json['board_password'] as String? ?? boardPassword;
      factoryKey = json['factory_key'] as String? ?? factoryKey;
      updaterHost = json['updater_host'] as String? ?? updaterHost;
      devMode = json['dev_mode'] as bool? ?? devMode;
      // A card or version the app does not know is not taken.
      final card = json['colour_card'];
      if (kCards.contains(card)) colourCard = card as String;
      final version = json['colour_card_version'];
      if (kClassicVersions.contains(version)) colourCardVersion = version as String;
    } catch (_) {
      // Corrupt/missing config falls back to defaults.
    }
  }

  /// What the Updater page remembers when a run starts: its board and the
  /// SSH credentials. Never the connected server ([host]).
  static void rememberUpdaterBoard(
      String board, String user, String password) {
    updaterHost = board;
    boardUser = user;
    boardPassword = password;
  }

  /// After "Change port" on the Updater page: when the app's saved server
  /// ([host]) is the machine changed — [changedHost] spelled the same,
  /// ignoring case — [port] becomes [newPort] and is saved; returns true.
  /// Another spelling (an IP for a .local name, a name without .local) may
  /// be another machine and is left alone: false.
  static bool followPortChange(String changedHost, int newPort) {
    if (host.trim().toLowerCase() != changedHost.trim().toLowerCase()) {
      return false;
    }
    port = newPort;
    unawaited(save());
    return true;
  }

  static Future<void> save() async {
    final file = _file;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({
      'host': host,
      'port': port,
      'board_user': boardUser,
      'board_password': boardPassword,
      'factory_key': factoryKey,
      'updater_host': updaterHost,
      'dev_mode': devMode,
      'colour_card': colourCard,
      'colour_card_version': colourCardVersion,
    }));
  }
}
