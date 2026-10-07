import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';

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

  /// Stops the server listening on [port] — and only the server. The server
  /// may have been started elsewhere (logon shortcut, by hand), so the port's
  /// owner is looked up rather than a process this app started; but it is
  /// killed only when its executable is [exePath]. Any other program on the
  /// port is reported (the UI shows it as "Server control failed: …") and
  /// left alone.
  /// The windowless server is force-killed, which skips its own shutdown
  /// steps, so the backlights are switched off first (as a normal stop does).
  static Future<void> stop(int port) async {
    await backlightsOff(port);
    final out = await _powershell(stopCommand(port));
    final other = portOwnerConflict(out);
    if (other != null) {
      throw Exception('port $port is in use by $other, not by the FaceSnap '
          'server ($exePath) — not stopped');
    }
  }

  static const _otherOwnerPrefix = 'OTHER:';

  /// The stop script: every listener on [port] (IPv4 + IPv6 = two rows, one
  /// process) is resolved to its process; it is killed when its executable
  /// is [exePath] (case-insensitive) and reported as `OTHER:<name>:<pid>`
  /// otherwise. A process whose Path cannot be read (another user's, a
  /// service) is reported, never killed.
  static String stopCommand(int port) =>
      '\$c = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue; '
      'if (\$c) { \$c.OwningProcess | Sort-Object -Unique | ForEach-Object { '
      '\$p = Get-Process -Id \$_ -ErrorAction SilentlyContinue; '
      "if (\$p -and \$p.Path -and \$p.Path -ieq '$exePath') { Stop-Process -Id \$_ -Force -ErrorAction SilentlyContinue } "
      'elseif (\$p) { "$_otherOwnerPrefix" + \$p.ProcessName + ":" + \$_ } } }';

  /// "name (PID n)" of a port owner [stopCommand] refused to kill, or null
  /// when every listener was the server (or nothing listened at all).
  static String? portOwnerConflict(String out) {
    for (final line in out.split('\n')) {
      final l = line.trim();
      if (!l.startsWith(_otherOwnerPrefix)) continue;
      final parts = l.substring(_otherOwnerPrefix.length).split(':');
      return parts.length > 1 ? '${parts[0]} (PID ${parts[1]})' : parts[0];
    }
    return null;
  }

  /// Both backlights off on the local server, best effort: no relay module,
  /// a server without backlight support or one that does not answer within
  /// two seconds simply leaves nothing to switch off. Both calls go out at
  /// once under one two-second budget, so a hung server (the usual reason to
  /// press Stop) delays the kill by two seconds, not four.
  static Future<void> backlightsOff(int port) async {
    final channel = GrpcChannelProvider.openChannel('127.0.0.1', port);
    try {
      final lights = LightsClient(channel);
      final options = CallOptions(timeout: const Duration(seconds: 2));
      await Future.wait([
        for (final backlight in [
          Backlight.BACKLIGHT_BOTTOM,
          Backlight.BACKLIGHT_TOP,
        ])
          lights.setBacklight(
              BacklightRequest(backlight: backlight, on: false),
              options: options),
      ]);
    } catch (_) {
      // Nothing to switch off (see above).
    } finally {
      await channel.shutdown();
    }
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
