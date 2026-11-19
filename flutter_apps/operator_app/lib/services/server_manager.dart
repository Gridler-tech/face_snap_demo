import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';

/// The FaceSnapServer service's state as `Get-Service` reports it; anything
/// else (no service, an empty answer, Paused, …) is [unknown].
enum ServiceState { running, stopped, startPending, stopPending, unknown }

/// Local FaceSnap server control (Windows): status, start/stop and the
/// start-at-logon shortcut — the Dart port of the C# ServerProcessManager +
/// ServerAutostart helpers. Only meaningful when the app runs on the kiosk
/// machine itself (server on localhost).
///
/// From 1.1.25 the installer registers the server as the Windows service
/// [serviceName]; [start] and [stop] then drive the service instead of the
/// exe. No elevation is needed: the service's security descriptor lets
/// Authenticated Users start and stop it, and the stop event's lets them set
/// it. Older installs keep the exe and logon-shortcut paths.
class ServerManager {
  ServerManager._();

  static const exePath = r'C:\Program Files\FaceSnapServer\face_snap_server.exe';
  static const _shortcutName = 'FaceSnap Server.lnk';

  static const serviceName = 'FaceSnapServer';

  /// The manual-reset event the server waits on (server/stop_event.py);
  /// setting it runs the server's normal shutdown (lights off, settings
  /// saved, the LED board to its waiting pattern), then the server exits.
  static const stopEventName = r'Global\FaceSnapServerStop';

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

  static String get serviceExistsCommand =>
      'if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) { "True" } else { "False" }';

  static String get serviceStateCommand =>
      '(Get-Service -Name $serviceName -ErrorAction SilentlyContinue).Status';

  static String get serviceStartCommand => 'Start-Service -Name $serviceName';

  static String get serviceStopCommand => 'Stop-Service -Name $serviceName';

  /// Sets [stopEventName]; prints "signalled", or "no stop event" when no
  /// server has created it (none running) — never an error.
  static String get signalStopCommand =>
      "try { [System.Threading.EventWaitHandle]::OpenExisting('$stopEventName').Set() | Out-Null; "
      '"signalled" } catch { "no stop event" }';

  /// The [ServiceState] of a `Get-Service … .Status` answer: case-insensitive,
  /// surrounding whitespace (PowerShell's CRLF) ignored.
  static ServiceState parseServiceState(String out) =>
      switch (out.trim().toLowerCase()) {
        'running' => ServiceState.running,
        'stopped' => ServiceState.stopped,
        'startpending' => ServiceState.startPending,
        'stoppending' => ServiceState.stopPending,
        _ => ServiceState.unknown,
      };

  static Future<bool>? _serviceInstalled;

  /// Whether the FaceSnapServer service exists. Asked once per app run (one
  /// PowerShell spawn); a service installed while the app runs is noticed
  /// after an app restart.
  static Future<bool> serviceInstalled() => _serviceInstalled ??=
      _powershell(serviceExistsCommand).then((out) => out.toLowerCase() == 'true');

  static Future<ServiceState> serviceState() async =>
      parseServiceState(await _powershell(serviceStateCommand));

  /// The Server card's status line. [running] is whether the port listens
  /// (null while the first probe runs); [state] is the service's state, null
  /// without a service. A service that runs but does not listen yet (the
  /// frozen server needs tens of seconds to boot) is starting, not "not
  /// running".
  static String serverStatusText(bool? running, ServiceState? state) {
    if (running == null) return 'Checking…';
    if (state == ServiceState.stopPending) return 'Service is stopping…';
    if (running) return 'Server is running';
    if (state == ServiceState.startPending || state == ServiceState.running) {
      return 'Service is starting, port not open yet';
    }
    return 'Server is not running';
  }

  static Future<void> start() async {
    if (await serviceInstalled()) {
      await _powershell(serviceStartCommand);
      return;
    }
    await _powershell(
        "Start-Process -FilePath '$exePath' -WindowStyle Minimized");
  }

  /// Whether [port] stops listening within [limit], checked every 500 ms.
  static Future<bool> _portClosesWithin(int port, Duration limit) async {
    final waited = Stopwatch()..start();
    while (waited.elapsed < limit) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!await isRunning(port)) return true;
    }
    return false;
  }

  /// Stops the server listening on [port] (this PC's server port,
  /// [LocalServerConfig.port]). The backlights are switched off first, on
  /// the same port, a safety net for a server that is killed and skips its
  /// own shutdown.
  ///
  /// Service install: `Stop-Service`, never the event alone. The service's
  /// pre-stop hook (signal_stop.ps1) sets [stopEventName] and waits for the
  /// port itself, and NSSM then knows the exit was requested; an exit after
  /// an event set from here would count as unexpected and NSSM would start
  /// the server again 2 s later. Then up to 15 s for the port to close; a
  /// port still listening after that is reported with its owner (the UI
  /// shows "Server control failed: …"). No process is ever killed on this
  /// path.
  ///
  /// Otherwise the server is first asked to shut down in order through
  /// [stopEventName] (a 1.1.25+ server, also one run from source, creates
  /// it; a 1.1.24 server has none and answers "no stop event" at once) and
  /// given 10 s to close the port. A server still listening, or one without
  /// the event, is stopped — and only the server. The server
  /// may have been started elsewhere (logon shortcut, by hand), so the port's
  /// owner is looked up rather than a process this app started; but it is
  /// killed only when its executable is [exePath]. Any other program on the
  /// port is reported (the UI shows it as "Server control failed: …") and
  /// left alone.
  static Future<void> stop(int port) async {
    await backlightsOff(port);
    if (await serviceInstalled()) {
      await _powershell(serviceStopCommand);
      if (await _portClosesWithin(port, const Duration(seconds: 15))) return;
      final owner = portOwnerConflict(await _powershell(portOwnerCommand(port)));
      throw Exception(owner == null
          ? 'Port $port is still listening after Stop-Service'
          : 'Port $port is still listening after Stop-Service: $owner');
    }
    if (await _powershell(signalStopCommand) == 'signalled' &&
        await _portClosesWithin(port, const Duration(seconds: 10))) {
      return;
    }
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

  /// The lookup half of [stopCommand], without any kill: every listener on
  /// [port] is reported as `OTHER:<name>:<pid>` (whatever its executable),
  /// so [portOwnerConflict] names it. Used on a service install, where a
  /// port still open after `Stop-Service` is reported and never touched.
  static String portOwnerCommand(int port) =>
      '\$c = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue; '
      'if (\$c) { \$c.OwningProcess | Sort-Object -Unique | ForEach-Object { '
      '\$p = Get-Process -Id \$_ -ErrorAction SilentlyContinue; '
      'if (\$p) { "$_otherOwnerPrefix" + \$p.ProcessName + ":" + \$_ } } }';

  /// "name (PID n)" of the first owner in [stopCommand]'s or
  /// [portOwnerCommand]'s output, or null when there is none (every listener
  /// was the server [stopCommand] killed, or nothing listened at all).
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

  /// Whether the logon shortcut must go: on a service install a shortcut
  /// (left by the old autostart switch) starts a second server at logon,
  /// which only exits again on the single-instance lock.
  static bool shouldRemoveLogonShortcut(
          bool serviceInstalled, bool autostartEnabled) =>
      serviceInstalled && autostartEnabled;

  static bool _logonShortcutChecked = false;

  /// On a service install, removes this user's logon shortcut if there is
  /// one. Checked once per app run; never throws (best effort, like
  /// [setAutostart]).
  static Future<void> removeLogonShortcutUnderService() async {
    if (_logonShortcutChecked) return;
    _logonShortcutChecked = true;
    try {
      final service = await serviceInstalled();
      if (!service) return;
      if (shouldRemoveLogonShortcut(service, await isAutostartEnabled())) {
        await setAutostart(false);
      }
    } catch (_) {/* the shortcut stays; harmless next to the service */}
  }
}
