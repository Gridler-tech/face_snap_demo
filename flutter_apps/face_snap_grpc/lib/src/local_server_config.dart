import 'dart:convert';
import 'dart:io';

/// The port of the FaceSnap server on THIS PC, from the server's own
/// configuration file `%ProgramData%\FaceSnap\server_config.json`
/// (`{"grpc_port": N}`, written by the setup).
///
/// Read exactly as the server (server/server_config.py) and its stop scripts
/// read it: UTF-8 with or without a BOM (invalid UTF-8 counts as invalid), a
/// JSON object with the exact key `grpc_port`, an integer 1024-65535. A
/// missing file, or anything else, means [defaultPort] — silently.
///
/// Only the local server's port: a kiosk board's server has its own.
class LocalServerConfig {
  LocalServerConfig._();

  static const defaultPort = 50051;
  static const fileName = 'server_config.json';

  static const _portKey = 'grpc_port';
  static const _minPort = 1024;
  static const _maxPort = 65535;

  /// The port read by the last [load]; [defaultPort] until then.
  static int port = defaultPort;

  /// `%ProgramData%\FaceSnap\server_config.json` on Windows (the server's data
  /// folder). On other systems no FaceSnap server runs on this machine: an
  /// empty path, which never exists, so [load] keeps the default.
  static String get defaultPath {
    if (!Platform.isWindows) return '';
    final programData = Platform.environment['PROGRAMDATA'] ?? r'C:\ProgramData';
    return '$programData\\FaceSnap\\$fileName';
  }

  /// The port in a config file's text: the default for anything but a JSON
  /// object whose `grpc_port` is an integer 1024-65535. One leading BOM is
  /// allowed (Notepad and PowerShell 5.1 write one).
  ///
  /// Pass the raw text with any BOM intact; to read the file use [load].
  /// `utf8.decode` and `File.readAsString` already drop one leading BOM, so
  /// their text here would let a two-BOM file through that the server rejects.
  static int parsePort(String json) =>
      _portIn(json.startsWith('\uFEFF') ? json.substring(1) : json);

  /// [parsePort] after the BOM: [text] must be the JSON itself.
  static int _portIn(String text) {
    final Object? config;
    try {
      config = jsonDecode(text);
    } on FormatException {
      return defaultPort;
    }
    final value = config is Map ? config[_portKey] : null;
    // `is int` rejects a bool and a double (50052.0 decodes to a double).
    return value is int && value >= _minPort && value <= _maxPort ? value : defaultPort;
  }

  /// Reads [path] (default [defaultPath]) into [port].
  static Future<void> load({String? path}) async {
    port = await _read(path ?? defaultPath);
  }

  static Future<int> _read(String path) async {
    if (path.isEmpty) return defaultPort;
    try {
      // Strict decode: a file that is not valid UTF-8 (UTF-16, an ANSI byte)
      // throws, as it does in the server. utf8.decode already drops one
      // leading BOM (as Python's utf-8-sig does), so the text goes to _portIn,
      // not to parsePort: a second BOM must stay and make the file invalid.
      return _portIn(utf8.decode(await File(path).readAsBytes()));
    } catch (_) {
      return defaultPort; // missing or unreadable
    }
  }

  /// Whether [host] names this PC: `localhost`, `127.0.0.1` or `::1`.
  static bool isLocalHost(String host) => const {'localhost', '127.0.0.1', '::1'}.contains(host);
}
