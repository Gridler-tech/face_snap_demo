// The server port as the Updater sees it: where a board keeps its port, which
// images read that file, the docker-compose `ports:` edit, the avahi
// announcement, telling a Linux board from a Windows PC over SSH, and the
// PowerShell command line used on a Windows PC. The "Change port" engines
// and the update pipeline build on these.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:face_snap_grpc/face_snap_grpc.dart' show LocalServerConfig;

import 'connection_probe.dart' show compareVersions, versionCore;
import '../services/ssh_runner.dart';

/// The board's port file (`{"grpc_port": N}`); the container sees it as
/// /data/server_config.json.
const kBoardPortFile = '/root/face_snap/data/server_config.json';

/// The port of a server without a port file (or with an invalid one).
const kDefaultPort = LocalServerConfig.defaultPort;

/// The first images that read the port file (older ones always bind 50051).
// 2.0.24-2.0.27 were head-turn live-check test images without the reader (R15).
const kMinFacesnap2 = '2.0.28';
const kMinPythonImage = '1.1.25';

/// Longest inline PowerShell script [windowsPs] accepts: encoded as UTF-16LE
/// and base64 it must stay well under cmd.exe's 8,191-character line limit.
const kMaxPsScriptLength = 2500;

enum TargetKind { linuxBoard, windowsPc, unknown }

/// What answers on the other end of [ssh]: a Linux board (`uname -s -m` says
/// "Linux"; model from the device tree, else the architecture) or a Windows
/// PC (Windows OpenSSH runs cmd.exe, which has no `uname`; PowerShell then
/// reports the platform `Win32NT`, the computer name and the architecture).
/// Anything else is [TargetKind.unknown].
///
/// `uname -s` and not just `-m`: a Windows PC with Git for Windows on its
/// PATH does have a `uname`, which reports x86_64 like a Linux PC would.
///
/// The PowerShell probe gets [probeTimeout] (a half-open link must not hang
/// it); no answer in time throws a [TimeoutException].
Future<({TargetKind kind, String model, String arch})> identifyTarget(
  SshRunner ssh, {
  Duration probeTimeout = kWindowsQueryTimeout,
}) async {
  final uname = await ssh.run('uname -s -m');
  final unameText = uname.ok ? uname.stdout.trim() : '';
  final parts = unameText.split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts.first == 'Linux') {
    final arch = parts.last;
    final board = await ssh.run(
      "tr -d '\\0' < /proc/device-tree/model 2>/dev/null",
    );
    final model = board.ok && board.stdout.trim().isNotEmpty
        ? board.stdout.trim()
        : arch;
    return (kind: TargetKind.linuxBoard, model: model, arch: arch);
  }

  final ps = await ssh
      .run(windowsPs(_windowsProbe), timeout: probeTimeout)
      .timeout(probeTimeout);
  final lines = ps.stdout
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (ps.ok && lines.isNotEmpty && lines.first == 'Win32NT') {
    return (
      kind: TargetKind.windowsPc,
      model: lines.length > 1 ? lines[1] : 'Windows PC',
      arch: lines.length > 2 ? lines[2] : '',
    );
  }
  return (
    kind: TargetKind.unknown,
    model: unameText,
    arch: unameText.isEmpty ? '' : parts.last,
  );
}

/// One line each: platform, computer name, processor architecture.
const _windowsProbe =
    r"$ProgressPreference = 'SilentlyContinue'; "
    r'Write-Output ([string][Environment]::OSVersion.Platform); '
    r'Write-Output $env:COMPUTERNAME; '
    r'Write-Output $env:PROCESSOR_ARCHITECTURE';

/// The port a board's server uses, from [kBoardPortFile], read by the same
/// rule as the servers (LocalServerConfig.parsePort): no file means 50051
/// silently; a file that does not hold a valid port means 50051 too, with
/// one [onWarning].
Future<int> readBoardPort(
  SshRunner ssh, {
  void Function(String warning)? onWarning,
}) async {
  const fallback = kDefaultPort;
  final read = await ssh.run('test -f $kBoardPortFile && cat $kBoardPortFile');
  if (!read.ok) return fallback; // no port file: the default port
  // The command output is decoded leniently and loses one leading BOM: a BOM
  // still in front means the file had two, and U+FFFD marks bytes that were
  // not UTF-8 — the servers refuse both.
  final text = read.stdout;
  final undecodable = text.startsWith('﻿') || text.contains('�');
  final port = undecodable ? fallback : LocalServerConfig.parsePort(text);
  if (port == fallback && (undecodable || !_saysDefaultPort(text))) {
    onWarning?.call(
      '$kBoardPortFile does not hold a valid port '
      '(${_preview(text)}); the server uses $fallback.',
    );
  }
  return port;
}

/// Whether a port file's [text] names the default port itself (valid).
bool _saysDefaultPort(String text) {
  try {
    final json = jsonDecode(text);
    final value = json is Map ? json['grpc_port'] : null;
    return value is int && value == kDefaultPort;
  } on FormatException {
    return false;
  }
}

String _preview(String text) {
  final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return 'empty';
  return t.length > 60 ? '"${t.substring(0, 60)}…"' : '"$t"';
}

/// Whether [imageRef] (a compose `image:` value) is a server that reads the
/// port file: facesnap2 from [kMinFacesnap2], face_snap_server from
/// [kMinPythonImage]. Anything else — another repository, no tag, a tag
/// without a version — is false.
bool imageSupportsPortFile(String imageRef) {
  final ref = imageRef.trim().replaceAll('"', '').replaceAll("'", '');
  final name = ref.split('/').last;
  final colon = name.indexOf(':');
  if (colon <= 0) return false;
  final min = switch (name.substring(0, colon)) {
    'facesnap2' => kMinFacesnap2,
    'face_snap_server' => kMinPythonImage,
    _ => null,
  };
  final version = versionCore(name.substring(colon + 1));
  if (min == null || version == null) return false;
  return compareVersions(version, min) >= 0;
}

/// [composeText] with its single `ports:` mapping set to "[port]:[containerPort]"
/// ([containerPort] defaults to [port]). Accepted forms: `- "A:B"`,
/// `- 'A:B'`, `- A:B` and `- "IP:A:B"` (the host IP is kept). Everything
/// else in the file stays byte for byte (indentation, comments, line
/// endings). No mapping, several mappings or any other form throw
/// `FormatException('unexpected ports line in docker-compose.yml')`.
String withComposePort(String composeText, int port, {int? containerPort}) {
  const unexpected = FormatException(
    'unexpected ports line in docker-compose.yml',
  );
  final lines = composeText.split('\n');
  String bare(String line) =>
      line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
  int indentOf(String line) => line.length - line.trimLeft().length;

  final items = <int>[];
  for (var i = 0; i < lines.length; i++) {
    final key = RegExp(r'^(\s*)ports\s*:(.*)$').firstMatch(bare(lines[i]));
    if (key == null) continue;
    final rest = key.group(2)!.trim();
    if (rest.isNotEmpty && !rest.startsWith('#')) throw unexpected; // [..]
    final keyIndent = key.group(1)!.length;
    for (var j = i + 1; j < lines.length; j++) {
      final line = bare(lines[j]);
      final text = line.trimLeft();
      if (text.isEmpty || text.startsWith('#')) continue;
      final indent = indentOf(line);
      if (indent < keyIndent ||
          (indent == keyIndent && !text.startsWith('-'))) {
        break; // the next key: the list has ended
      }
      // A deeper line that is no list item continues an item in the long
      // syntax (target:/published:) — not a form this edit handles.
      if (!text.startsWith('-')) throw unexpected;
      items.add(j);
    }
  }
  if (items.length != 1) throw unexpected;

  final index = items.single;
  final line = lines[index];
  final cr = line.endsWith('\r') ? '\r' : '';
  final mapping = RegExp(
    r'''^(\s*-\s*)(["']?)((?:\d{1,3}(?:\.\d{1,3}){3}:)?)(\d+):(\d+)\2(\s*(?:#.*)?)$''',
  ).firstMatch(bare(line));
  if (mapping == null) throw unexpected;
  lines[index] =
      '${mapping.group(1)}"${mapping.group(3)}'
      '$port:${containerPort ?? port}"${mapping.group(6)}$cr';
  return lines.join('\n');
}

/// Where a board keeps [avahiService].
const kAvahiServiceFile = '/etc/avahi/services/facesnap.service';

/// The mDNS announcement of a kiosk's server (`_facesnap._tcp` on [port]),
/// [kAvahiServiceFile] on the board.
String avahiService(int port) =>
    '''
<?xml version="1.0" standalone="no"?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">FaceSnap kiosk on %h</name>
  <service>
    <type>_facesnap._tcp</type>
    <port>$port</port>
  </service>
</service-group>
''';

/// The port file's bytes on the board (LF; the Windows setup writes CRLF).
String portFileContent(int port) => '{"grpc_port": $port}\n';

/// The command line running [script] in Windows PowerShell over SSH:
/// `-EncodedCommand` (base64 of UTF-16LE) so neither cmd.exe nor PowerShell
/// re-parses quotes, `$` or pipes; `-ExecutionPolicy Bypass` because the
/// default policy blocks scripts. Throws [ArgumentError] for a script longer
/// than [kMaxPsScriptLength] characters.
String windowsPs(String script) {
  if (script.length > kMaxPsScriptLength) {
    throw ArgumentError.value(
      script.length,
      'script',
      'PowerShell script longer than $kMaxPsScriptLength characters',
    );
  }
  final bytes = Uint8List(script.length * 2);
  for (var i = 0; i < script.length; i++) {
    final unit = script.codeUnitAt(i);
    bytes[2 * i] = unit & 0xff;
    bytes[2 * i + 1] = unit >> 8;
  }
  return 'powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass '
      '-EncodedCommand ${base64.encode(bytes)}';
}

// ---------------------------------------------------------------- Windows --

/// The Windows service the setup registers (NSSM; its PathName is nssm.exe
/// in the install folder).
const kWindowsService = 'FaceSnapServer';

/// The setup's port script, next to nssm.exe (Task 2's contract).
const kSetPortScript = 'set_server_port.ps1';

/// [text] as a PowerShell single-quoted string. PowerShell also takes the
/// typographic single quotes as quotes; each is escaped by doubling it.
String psQuote(String text) =>
    "'${text.replaceAllMapped(RegExp('[\'\u2018\u2019\u201A\u201B]'), (m) => '${m[0]}${m[0]}')}'";

/// Prints one JSON line with the keys `admin`, `service` (bools), `app`
/// (the server folder or ""), `script` (bool), `override` and `error` (why
/// the service lookup failed, or ""). `app` is the folder of the exe in the
/// FaceSnapServer service's PathName (NSSM: `<app>\nssm.exe`, quoted or
/// not); `script` whether set_server_port.ps1 is there; `override` is
/// "FACE_SNAP_GRPC_BIND" when that variable (it wins over the port file) is
/// set for the service — in NSSM's AppEnvironmentExtra, read with the app
/// folder's nssm.exe (whose output may be UTF-16: NULs are dropped), or in
/// the machine environment — else "". Non-ASCII is escaped (\uXXXX) so the
/// SSH console's code page cannot change a path on the way.
const windowsFactsScript = r'''
$ProgressPreference = 'SilentlyContinue'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$admin = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$service = $null
$failure = ''
try {
    $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='FaceSnapServer'" -ErrorAction Stop
} catch { $failure = "$($_.Exception.Message)" }
$app = ''
if ($service) {
    $image = "$($service.PathName)".Trim()
    if ($image -match '^"([^"]+)"') { $exe = $Matches[1] }
    elseif ($image -match '^(.+?\.exe)(\s|$)') { $exe = $Matches[1] }
    else { $exe = $image }
    if ($exe) { $app = Split-Path -Parent $exe }
}
$present = [bool]($app -and (Test-Path -LiteralPath (Join-Path $app 'set_server_port.ps1') -PathType Leaf))
$override = ''
$bind = 'FACE_SNAP_GRPC_BIND'
$nssm = if ($app) { Join-Path $app 'nssm.exe' } else { '' }
if ($nssm -and (Test-Path -LiteralPath $nssm -PathType Leaf)) {
    $extra = (& $nssm get FaceSnapServer AppEnvironmentExtra 2>$null | Out-String) -replace "`0", ''
    if ($extra -match "(?m)^\s*$bind=") { $override = $bind }
}
if ([Environment]::GetEnvironmentVariable($bind, 'Machine')) { $override = $bind }
$facts = [ordered]@{ admin = [bool]$admin; service = [bool]$service; app = "$app"; script = $present; override = $override; error = $failure }
$json = $facts | ConvertTo-Json -Compress
[regex]::Replace($json, '[^\x00-\x7F]', { param($m) '\u{0:x4}' -f [int][char]$m.Value })
''';

/// `& '<app>\set_server_port.ps1' <args>`: [args] is `-Query`,
/// `-Port N`, `-Restore '<base64>'` or `-Remove`.
String setServerPortCall(String app, String args) =>
    '& ${psQuote(app.endsWith('\\') ? '$app$kSetPortScript' : '$app\\$kSetPortScript')} $args';

/// [setServerPortCall] as the inline script the engine sends (no progress
/// records: they would reach stderr as CLIXML and fill the error text).
String setServerPortScript(String app, String args) =>
    "\$ProgressPreference = 'SilentlyContinue'; ${setServerPortCall(app, args)}";

/// The last line of [stdout] that is a JSON object, or null.
Map<String, dynamic>? jsonLine(String stdout) {
  for (final line in stdout.split('\n').reversed) {
    final text = line.trim();
    if (!text.startsWith('{')) continue;
    try {
      final value = jsonDecode(text);
      if (value is Map<String, dynamic>) return value;
    } on FormatException {
      // Not JSON after all: look further up.
    }
  }
  return null;
}

/// Each of [readWindowsPort]'s two PowerShell calls (and identifyTarget's
/// probe) gets this long, not SshRunner's 3-minute default: a probe must not
/// hang on a half-open link. The `.timeout` beside SshRunner's own also
/// covers opening the channel, which SshRunner's does not.
const kWindowsQueryTimeout = Duration(seconds: 30);

/// The port the FaceSnapServer service on the Windows PC behind [ssh] uses,
/// as set_server_port.ps1 -Query reports it (the setup's rule: the file's
/// valid port, else 50051) — the same facts script and call the engine's
/// check makes. Null when there is no such service or script (a server older
/// than 1.1.25) or the answer is not a port. Reads only.
Future<int?> readWindowsPort(SshRunner ssh) async {
  final facts = jsonLine((await ssh
          .run(windowsPs(windowsFactsScript), timeout: kWindowsQueryTimeout)
          .timeout(kWindowsQueryTimeout))
      .stdout);
  final app = facts?['app'];
  if (facts?['service'] != true || facts?['script'] != true || app is! String || app.isEmpty) {
    return null;
  }
  final String command;
  try {
    command = windowsPs(setServerPortScript(app, '-Query'));
  } on ArgumentError {
    return null; // a server folder too long for one command line
  }
  final query = await ssh
      .run(command, timeout: kWindowsQueryTimeout)
      .timeout(kWindowsQueryTimeout);
  final port = jsonLine(query.stdout)?['port'];
  return query.exitCode == 0 && port is int ? port : null;
}
