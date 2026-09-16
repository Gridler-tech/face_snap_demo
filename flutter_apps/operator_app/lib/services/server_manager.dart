import 'dart:io';

/// Local FaceSnap server control (Windows): status, start/stop and the
/// start-at-logon shortcut — the Dart port of the C# ServerProcessManager +
/// ServerAutostart helpers. Only meaningful when the app runs on the kiosk
/// machine itself (server on localhost).
class ServerManager {
  ServerManager._();

  static const exePath = r'C:\Program Files\FaceSnapServer\face_snap_server.exe';
  static const _shortcutName = 'FaceSnap Server.lnk';

  static bool get applicable => Platform.isWindows && File(exePath).existsSync();

  static Future<String> _powershell(String command) async {
    final result = await Process.run(
        'powershell', ['-NoProfile', '-NonInteractive', '-Command', command]);
    return (result.stdout as String).trim();
  }

  static Future<bool> isRunning(int port) async {
    // if/else instead of `-ne $null`: the server listens on IPv4 AND IPv6, so
    // Get-NetTCPConnection returns an array and the null-comparison would
    // print one "True" per listener ("True True") instead of a single value.
    final out = await _powershell(
        'if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) { "True" } else { "False" }');
    return out.toLowerCase() == 'true';
  }

  static Future<void> start() async {
    await _powershell(
        "Start-Process -FilePath '$exePath' -WindowStyle Minimized");
  }

  /// Stops whoever owns the port (the server may have been started elsewhere).
  static Future<void> stop(int port) async {
    await _powershell(
        '\$c = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue; '
        'if (\$c) { \$c.OwningProcess | Sort-Object -Unique | ForEach-Object { Stop-Process -Id \$_ -Force -ErrorAction SilentlyContinue } }');
  }

  static Future<bool> isAutostartEnabled() async {
    final out = await _powershell(
        'Test-Path (Join-Path ([Environment]::GetFolderPath("Startup")) "$_shortcutName")');
    if (out.toLowerCase() == 'true') return true;
    final common = await _powershell(
        'Test-Path (Join-Path ([Environment]::GetFolderPath("CommonStartup")) "$_shortcutName")');
    return common.toLowerCase() == 'true';
  }

  static Future<void> setAutostart(bool enabled) async {
    if (enabled) {
      await _powershell(
          '\$s = (New-Object -ComObject WScript.Shell).CreateShortcut('
          '(Join-Path ([Environment]::GetFolderPath("Startup")) "$_shortcutName")); '
          "\$s.TargetPath = '$exePath'; \$s.WindowStyle = 7; \$s.Save()");
    } else {
      // Best effort: the all-users shortcut (from the installer) needs admin.
      await _powershell(
          'Remove-Item (Join-Path ([Environment]::GetFolderPath("Startup")) "$_shortcutName") -ErrorAction SilentlyContinue; '
          'Remove-Item (Join-Path ([Environment]::GetFolderPath("CommonStartup")) "$_shortcutName") -ErrorAction SilentlyContinue');
    }
  }
}
