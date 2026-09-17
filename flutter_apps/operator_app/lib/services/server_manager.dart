import 'dart:io';

/// Local FaceSnap server control (Windows): status, start/stop and the
/// start-at-logon shortcut — the Dart port of the C# ServerProcessManager +
/// ServerAutostart helpers. Only meaningful when the app runs on the kiosk
/// machine itself (server on localhost).
class ServerManager {
  ServerManager._();

  static const exePath = r'C:\Program Files\FaceSnapServer\face_snap_server.exe';
  static const _shortcutName = 'FaceSnap Server.lnk';

  /// Whether the local server exe is installed. Computed once — build()
  /// consults it on every rebuild, and a stat per rebuild is UI-thread I/O.
  static final bool applicable =
      Platform.isWindows && File(exePath).existsSync();

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

  // The server installer's Inno Setup AppId (face_snap_server.iss) plus the
  // "_is1" suffix Inno appends to its uninstall registry key. The installed
  // version lives there as DisplayVersion — the frozen exe itself carries no
  // version resource.
  static const _uninstallKey = '{7B2F4E1A-0C3D-4A9E-9F1B-FACE5NAP0001}_is1';

  /// DisplayVersion of the locally installed server, or null when the
  /// registry has no entry (server not installed via the setup).
  static Future<String?> installedVersion() async {
    // The installer is 64-bit (x64compatible), but check the 32-bit view too
    // in case the app runs under a 32-bit PowerShell host.
    final out = await _powershell(
        '\$p = Get-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\$_uninstallKey" -ErrorAction SilentlyContinue; '
        'if (-not \$p) { \$p = Get-ItemProperty -Path "HKLM:\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\$_uninstallKey" -ErrorAction SilentlyContinue }; '
        'if (\$p) { \$p.DisplayVersion }');
    return out.isEmpty ? null : out;
  }

  static Future<bool> isAutostartEnabled() async {
    // One PowerShell spawn for both locations (each spawn is ~200-500 ms).
    final out = await _powershell(
        'if ((Test-Path (Join-Path ([Environment]::GetFolderPath("Startup")) "$_shortcutName")) -or '
        '(Test-Path (Join-Path ([Environment]::GetFolderPath("CommonStartup")) "$_shortcutName"))) '
        '{ "True" } else { "False" }');
    return out.toLowerCase() == 'true';
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
