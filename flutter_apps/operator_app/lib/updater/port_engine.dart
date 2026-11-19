// "Change port": gives the FaceSnap server on the connected machine a new
// gRPC port without an update (spec 2026-10-15 §4). On a Linux board that is
// three files — the port file the server reads, the compose `ports:` mapping
// and the avahi announcement — and a restart of the compose service. On a
// Windows PC it is server_config.json, written by the setup's own
// set_server_port.ps1 (in the FaceSnapServer service's folder), with the
// service stopped before that write and started after it: NSSM's pre-stop
// hook (signal_stop.ps1) reads the port file to find the server it shuts down
// in order, so the file must still name the port the server runs on when the
// stop comes (D-1). Every Windows command is one `powershell -EncodedCommand`
// (windowsPs, ruling R4).
//
// Every refusal happens before any write. Every failure after a write ends in
// a rollback attempt and a message naming the machine and the port it is on
// now; a connection that drops after a write gets no rollback (there is
// nothing to send it over) and says which two ports the machine may be on —
// or, when it dropped before the restart was sent, that the files may be
// partly changed while the server keeps its old port until it restarts.
//
// No step may hang on a half-open link: from the first write on every board
// command is bounded, as are every Windows call, the probe and the tunnel
// ([PortTimeouts]); the board's pre-write checks and backup copies use
// SshRunner's 3-minute limit (nothing is written yet). No answer within a
// limit is a failure like any other (a rollback is tried); a rollback that
// gets no answer either ends like a lost connection.
//
// Verification (Rulings R1, R7, R8): the server is ready when GetKioskInfo,
// called through the same SSH connection on the machine's 127.0.0.1:N,
// answers with N. The call is repeated until it answers or the wait runs
// out — a Docker host's listener (docker-proxy) binds as soon as the
// container starts, before the server inside is ready. A listener (`ss` on a
// board, Get-NetTCPConnection owned by face_snap_server on Windows) is only a
// hint for the log, never required: a host with Docker's userland-proxy off
// has no host listener for a published port at all.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:face_snap_grpc/face_snap_grpc.dart';

import 'column_factory.dart' show ServerLink, openTunnel;
import 'engine.dart';
import 'kiosk.dart';
import 'server_port.dart';
import '../services/ssh_runner.dart';

/// Lowest and highest port the servers accept in the port file.
const kMinServerPort = 1024;
const kMaxServerPort = 65535;

/// Suffix of the copies taken before the change.
const kPortBackupSuffix = '.port-bak';

/// Suffix of a board file being written; `mv -f` puts it in place, so a
/// file is either the old one or the whole new one (ruling I1). Every
/// `.tmp` is written first and all of them are moved in one command (D-4),
/// so a link that drops between two writes leaves every file the old one.
const kPortTempSuffix = '.tmp';

/// How long the server may take to answer on its new port (ruling R13): a
/// board boots its container like an update does (UpdateEngine's verify
/// waits 180 s); the Windows service is up within a minute.
const kBoardReadyTimeout = Duration(seconds: 180);
const kWindowsReadyTimeout = Duration(seconds: 60);

/// The limits of the engine's SSH uses (ruling I3). Tests inject zeros.
class PortTimeouts {
  const PortTimeouts({
    this.query = kWindowsQueryTimeout,
    this.write = const Duration(seconds: 60),
    this.restartSlack = const Duration(seconds: 30),
    this.boardRestart = const Duration(minutes: 4),
    this.tunnel = const Duration(seconds: 10),
  });

  /// Reads: identifyTarget's PowerShell probe, the Windows facts, -Query.
  final Duration query;

  /// A write: -Port / -Restore / -Remove, Stop-Service, a board file and its
  /// `mv`, a copy.
  final Duration write;

  /// The Windows start script: its listener wait (the ready timeout) plus
  /// this much for Start-Service.
  final Duration restartSlack;

  /// `systemctl restart` of the board's compose service.
  final Duration boardRestart;

  /// Opening the SSH forward for GetKioskInfo (the call itself keeps its own
  /// 5 s gRPC deadline).
  final Duration tunnel;
}

/// An SSH use that got no answer within its limit (maybe a half-open link).
class PortNoAnswer implements Exception {
  PortNoAnswer(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Lists TCP listeners on [port] (no header); `-p` adds the owning process.
String listenersCmd(int port, {bool withProcess = false}) =>
    'ss -ltn${withProcess ? 'p' : ''}H "sport = :$port"';

/// True for an error that means the SSH connection itself is gone (as
/// opposed to a command that failed on a live connection).
bool isConnectionLoss(Object e) =>
    e is SSHStateError ||
    e is SSHDisconnectError ||
    e is SSHSocketError ||
    e is SocketException;

/// The environment variable in [composeText] that overrides the port file
/// (FACESNAP_NET_PORT for Server 2.0, FACE_SNAP_GRPC_BIND for the Python
/// server), or null. Comments are ignored.
///
/// Known residue (P12): a variable that reaches the container another way —
/// an `env_file:`, or a `${VAR}` substituted from the shell — is not seen
/// here. A `${FACESNAP_NET_PORT}` mention still matches, so that case errs
/// towards refusing.
String? composePortOverride(String composeText) {
  for (final line in composeText.split('\n')) {
    final code = line.split('#').first;
    final match =
        RegExp(r'\b(FACESNAP_NET_PORT|FACE_SNAP_GRPC_BIND)\b').firstMatch(code);
    if (match != null) return match.group(1);
  }
  return null;
}

/// The variable in an image's environment (`docker inspect --format
/// '{{json .Config.Env}}'`, a JSON list of "NAME=value") that overrides the
/// port file, or null.
String? imagePortOverride(String imageEnv) => RegExp(
  r'"(FACESNAP_NET_PORT|FACE_SNAP_GRPC_BIND)=',
).firstMatch(imageEnv)?.group(1);

// ---------------------------------------------------------------- Windows --
// (The service name, set_server_port.ps1, the facts script, jsonLine and
// readWindowsPort live in server_port.dart: the probe uses them too.)

/// Stops the FaceSnapServer service (NSSM's pre-stop hook does the clean
/// stop, finding the server by the port in the port file — so this runs
/// BEFORE the file changes, D-1) and prints `{"stopped":true}`. A failed
/// Stop-Service ends the script with an error and no JSON line.
const windowsStopScript = '''
\$ErrorActionPreference = 'Stop'
\$ProgressPreference = 'SilentlyContinue'
Stop-Service -Name $kWindowsService -WarningAction SilentlyContinue
'{"stopped":true}'
''';

/// Starts the FaceSnapServer service, then waits up to [timeoutSeconds] for
/// a listener on [port] owned by face_snap_server and prints
/// `{"listening":true|false,"waited_ms":N}` — N: how long the listener wait
/// took, counted from when Start-Service returned (the engine's ready
/// deadline counts from there too, P5). A failed Start-Service ends the
/// script with an error and no JSON line.
String windowsStartScript(int port, int timeoutSeconds) => '''
\$ErrorActionPreference = 'Stop'
\$ProgressPreference = 'SilentlyContinue'
Start-Service -Name $kWindowsService -WarningAction SilentlyContinue
\$started = Get-Date
\$deadline = \$started.AddSeconds($timeoutSeconds)
\$up = \$false
while (\$true) {
    \$owners = @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | ForEach-Object { \$_.OwningProcess })
    foreach (\$id in \$owners) {
        if ((Get-Process -Id \$id -ErrorAction SilentlyContinue).ProcessName -eq 'face_snap_server') { \$up = \$true }
    }
    if (\$up -or (Get-Date) -ge \$deadline) { break }
    Start-Sleep -Milliseconds 500
}
\$waited = [int]((Get-Date) - \$started).TotalMilliseconds
'{"listening":' + "\$up".ToLower() + ',"waited_ms":' + \$waited + '}'
''';

/// A PowerShell call's outcome: exit code, its JSON line (null when it
/// printed none) and its output shortened for messages.
typedef _PsAnswer = ({int exit, Map<String, dynamic>? json, String raw});

/// A failure with a message meant for the summary as it is.
class _Failure implements Exception {
  _Failure(this.message);
  final String message;
  @override
  String toString() => message;
}

class PortEngine extends KioskEngine {
  PortEngine({
    required super.host,
    required super.user,
    required super.password,
    required this.newPort,
    Future<int?> Function(SshRunner ssh, int port)? checkServer,
    this.pollInterval = const Duration(seconds: 2),
    this._readyTimeout,
    this.timeouts = const PortTimeouts(),
    required super.onChanged,
    required super.onLog,
  }) : checkServer = checkServer ??
            ((ssh, port) => defaultCheckServer(ssh, port, openTimeout: timeouts.tunnel));

  /// The port asked for.
  final int newPort;

  /// Asks the server on the machine's 127.0.0.1:[port] (through [ssh]) which
  /// port it serves; null when it does not answer.
  final Future<int?> Function(SshRunner ssh, int port) checkServer;

  /// How often the verification asks again.
  final Duration pollInterval;

  /// The limits of the SSH uses.
  final PortTimeouts timeouts;

  final Duration? _readyTimeout;

  /// How long the verification (and the rollback's) waits in all: the one
  /// given, else [kBoardReadyTimeout] for a board, [kWindowsReadyTimeout]
  /// for a Windows PC (ruling R13).
  Duration get readyTimeout =>
      _readyTimeout ?? (_windows ? kWindowsReadyTimeout : kBoardReadyTimeout);

  /// The port the server used before (null until read).
  int? oldPort;

  /// The port the machine is on at the end; null = unknown (connection lost
  /// or the rollback failed).
  int? resultPort;

  /// What to tell the operator after a success (null otherwise): the new
  /// address of a board; for a Windows PC, whose server accepts local
  /// connections only (ruling R14), the new port and who follows it.
  String? notice;

  /// What the connect step found: a Linux board or a Windows PC go on.
  TargetKind? targetKind;

  @override
  final List<UpdateStep> steps = [
    UpdateStep('Connect'),
    UpdateStep('Check'),
    UpdateStep('Back up'),
    UpdateStep('Write'),
    UpdateStep('Restart'),
    UpdateStep('Verify'),
  ];

  UpdateStep get _connect => steps[0];
  UpdateStep get _check => steps[1];
  UpdateStep get _backup => steps[2];
  UpdateStep get _write => steps[3];
  UpdateStep get _restart => steps[4];
  UpdateStep get _verify => steps[5];

  /// Shown only when used.
  final _rollback = UpdateStep('Roll back');

  bool get _windows => targetKind == TargetKind.windowsPc;

  // The connected machine's architecture (uname / PROCESSOR_ARCHITECTURE).
  String _arch = '';

  // What the check found and the backup step saved.
  String _newCompose = '';
  bool _hadPortFile = false;
  bool _hasAvahi = false;

  // How far the change got: (Windows) the stop was sent, the restart (a
  // board's) or start (Windows) was sent, the rollback began. They decide
  // what a lost connection means.
  bool _stopSent = false;
  bool _restartSent = false;
  bool _rollbackStarted = false;

  // Windows: the server folder, server_config.json as -Query returned it
  // (base64, "" for none) and the rollback's set_server_port.ps1 arguments.
  String _app = '';
  String _portFileBase64 = '';
  String _restoreArgs = '';

  /// GetKioskInfo through [ssh]: a forward to the machine's 127.0.0.1:[port]
  /// (the SSH connection stays open — the engine keeps using it). Null when
  /// the server does not answer or reports no port, and when the forward
  /// does not open within [openTimeout] (a half-open link: the verification
  /// then runs out and a rollback is tried). A lost SSH transport is
  /// rethrown, not "no answer": the engine must stop and report it (on
  /// Windows this forward is the only SSH use between restart and verdict).
  static Future<int?> defaultCheckServer(SshRunner ssh, int port,
      {Duration openTimeout = const Duration(seconds: 10)}) async {
    Future<SSHSocket> forward(String host, int remotePort) {
      final opening = ssh.forwardLocal(host, remotePort);
      return opening.timeout(openTimeout, onTimeout: () {
        // A forward that opens after all is closed again.
        opening.then((socket) => socket.destroy(), onError: (_) {});
        throw PortNoAnswer('no SSH forward to $host:$remotePort within '
            '${openTimeout.inSeconds} s');
      });
    }

    ServerLink? link;
    try {
      link = await openTunnel(forward, () async {}, remotePort: port);
      final info = await KioskClient(link.channel).getKioskInfo(Empty(),
          options: CallOptions(timeout: const Duration(seconds: 5)));
      return int.tryParse(info.kioskInfo.port.trim());
    } catch (e) {
      if (e is SSHStateError || e is SSHDisconnectError || e is SSHSocketError) rethrow;
      return null;
    } finally {
      try {
        await link?.close();
      } catch (_) {
        // A tunnel that already failed: nothing to close.
      }
    }
  }

  Future<bool> run() => runGuarded('Change port', () async {
        if (newPort < kMinServerPort || newPort > kMaxServerPort) {
          return _refuse('port $newPort is outside $kMinServerPort–$kMaxServerPort');
        }
        await _doConnect();
        switch (targetKind) {
          case TargetKind.linuxBoard:
            // The same rule as the page's probe and the other pipelines (M4).
            if (_arch != 'aarch64') {
              return _refuse('Target is $_arch, expected aarch64 (a kiosk board)',
                  at: _connect);
            }
            final refusal = await _doCheck();
            if (refusal != null) return _refuse(refusal);
            await _doBackup();
          case TargetKind.windowsPc:
            final refusal = await _doCheckWindows();
            if (refusal != null) return _refuse(refusal);
            final backupRefusal = _doBackupWindows();
            if (backupRefusal != null) return _refuse(backupRefusal, at: _backup);
          default:
            return _refuse('$host is neither a Linux board nor a Windows PC');
        }
        return _changeAndVerify();
      });

  Future<void> _doConnect() async {
    setStep(_connect, StepStatus.running);
    log('Connecting to $user@$host …');
    sshOrNull = await openSsh();
    final id = await identifyTarget(ssh, probeTimeout: timeouts.query);
    targetKind = id.kind;
    _arch = id.arch;
    if (id.kind == TargetKind.unknown) {
      setStep(_connect, StepStatus.fail,
          id.model.isEmpty ? 'unknown system' : id.model);
      log('Not a Linux board or a Windows PC: '
          '${id.model.isEmpty ? 'no answer to uname' : id.model}');
      return;
    }
    setStep(_connect, StepStatus.ok, id.model);
    log('Connected: ${id.model} (${id.arch})');
  }

  /// Everything that can refuse; returns the reason, or null to go ahead.
  /// Reads only.
  Future<String?> _doCheck() async {
    setStep(_check, StepStatus.running);
    final current = await readBoardPort(ssh, onWarning: (w) => log('WARNING: $w'));
    oldPort = current;
    log('Current port: $current');

    if (newPort == current) {
      return 'nothing to change: $host already uses port $current';
    }

    final image = (await ssh.run(composeImageCmd(kCompose))).stdout.trim();
    if (!imageSupportsPortFile(image)) {
      final what = image.isEmpty
          ? 'no image: line in docker-compose.yml'
          : tagOf(image) == null || !kVersionLike.hasMatch(tagOf(image)!)
              ? '$host runs $image (no version in the tag)'
              : '$host runs $image, which does not read the port file';
      return '$what — update this kiosk first '
          '(facesnap2 $kMinFacesnap2 or face_snap_server $kMinPythonImage or later)';
    }

    final compose = (await ssh.runChecked('cat $kCompose')).stdout;
    final override = composePortOverride(compose);
    if (override != null) {
      return "this kiosk's docker-compose.yml sets $override; "
          'the port file would be ignored';
    }
    // The image's own environment can set the variable too (M2).
    final env = await ssh.run(imageEnvCmd(image));
    if (!env.ok) {
      return 'could not read the environment of $image on $host '
          '(${shorten(env.combined.trim())})';
    }
    final imageOverride = imagePortOverride(env.stdout);
    if (imageOverride != null) {
      return "this kiosk's image $image sets $imageOverride; "
          'the port file would be ignored';
    }
    try {
      _newCompose = withComposePort(compose, newPort);
    } on FormatException catch (e) {
      return e.message;
    }

    final listeners = await ssh.run(listenersCmd(newPort));
    if (!listeners.ok) {
      return 'could not check whether port $newPort is free on $host '
          '(${shorten(listeners.combined.trim())})';
    }
    if (listeners.stdout.trim().isNotEmpty) {
      final owners = await ssh.run(listenersCmd(newPort, withProcess: true));
      final name = RegExp(r'users:\(\("([^"]+)"').firstMatch(owners.stdout)?.group(1);
      return name == null
          ? 'port $newPort is already in use on $host'
          : 'port $newPort is in use on $host by $name';
    }

    setStep(_check, StepStatus.ok, '$current → $newPort');
    return null;
  }

  /// [call] bounded by [limit]: no answer in time throws [PortNoAnswer].
  /// (SshRunner's own timeout does not cover opening the channel.)
  Future<T> _bounded<T>(Future<T> call, Duration limit, String what) =>
      call.timeout(limit,
          onTimeout: () => throw PortNoAnswer(
              'no answer from $host to $what within ${(limit.inMilliseconds / 1000).ceil()} s'));

  /// [command] on the board, bounded by [limit] (default: a write's).
  Future<CmdResult> _run(String command, {Duration? limit}) {
    final l = limit ?? timeouts.write;
    return _bounded(ssh.run(command, timeout: l), l, command);
  }

  /// [_run] that throws on a non-zero exit.
  Future<CmdResult> _runChecked(String command, {Duration? limit}) async {
    final result = await _run(command, limit: limit);
    if (!result.ok) {
      throw Exception('Command failed (exit ${result.exitCode}): $command\n${result.combined}');
    }
    return result;
  }

  /// The `.tmp` files [_writeAll] may leave on a board.
  static const _tempFiles = [
    '$kBoardPortFile$kPortTempSuffix',
    '$kCompose$kPortTempSuffix',
    '$kAvahiServiceFile$kPortTempSuffix',
  ];

  /// `mv -f` of each `<path>.tmp` over its path, chained in one command
  /// (a rename each: never half written).
  static String _moveAllCmd(Iterable<String> paths) =>
      paths.map((p) => "mv -f '$p$kPortTempSuffix' '$p'").join(' && ');

  /// Writes [files] (path → content) on the board: every one into
  /// `<path>.tmp` first, then all moved in ONE command (D-4) — a link that
  /// drops between two writes leaves every file the old one.
  Future<void> _writeAll(Map<String, String> files) async {
    for (final e in files.entries) {
      final temp = '${e.key}$kPortTempSuffix';
      await _bounded(ssh.writeRemoteFile(temp, e.value), timeouts.write, 'the write of $temp');
    }
    await _runChecked(_moveAllCmd(files.keys));
  }

  /// Runs [script] through windowsPs within [limit] ([what] names it in the
  /// no-answer message). An over-long [script] throws ArgumentError.
  Future<_PsAnswer> _ps(String script, Duration limit, String what) async {
    final result = await _bounded(ssh.run(windowsPs(script), timeout: limit), limit, what);
    return (
      exit: result.exitCode,
      json: jsonLine(result.stdout),
      raw: shorten(result.combined.trim()),
    );
  }

  /// set_server_port.ps1's error, else what the call printed.
  static String _psError(_PsAnswer answer) {
    final error = answer.json?['error'];
    if (error is String && error.isNotEmpty) return error;
    return answer.raw.isEmpty
        ? 'exit code ${answer.exit}, no output'
        : 'exit code ${answer.exit}: ${answer.raw}';
  }

  /// The Windows checks (administrator, the service, set_server_port.ps1, no
  /// FACE_SNAP_GRPC_BIND, the current port); returns the reason to refuse,
  /// or null. Reads only: whether the new port is free is
  /// set_server_port.ps1 -Port's own check (exit 3), made before it writes.
  Future<String?> _doCheckWindows() async {
    setStep(_check, StepStatus.running);
    const update = 'update the server on this PC to $kMinPythonImage or later first';
    final facts = await _ps(windowsFactsScript, timeouts.query, 'the setup check');
    final f = facts.json;
    if (f == null ||
        f['admin'] is! bool ||
        f['service'] is! bool ||
        f['app'] is! String ||
        f['script'] is! bool) {
      log('The setup check on $host printed no JSON line (exit code ${facts.exit}): '
          '${facts.raw.isEmpty ? 'no output' : facts.raw}');
      return 'could not read the server setup on $host';
    }
    final failure = f['error'];
    if (failure is String && failure.isNotEmpty) {
      return 'could not read the services on $host ($failure)';
    }
    if (f['admin'] != true) {
      return 'this account is not an administrator on $host';
    }
    if (f['service'] != true) {
      return 'there is no $kWindowsService service on $host — $update';
    }
    final app = f['app'] as String;
    if (f['script'] != true || app.isEmpty) {
      return 'there is no $kSetPortScript in ${app.isEmpty ? 'the service folder' : app} — $update';
    }
    final override = f['override'];
    if (override is String && override.isNotEmpty) {
      return 'the $kWindowsService service on $host sets $override; '
          'the port file would be ignored';
    }
    _app = app;
    log('Server folder: $_app');

    final _PsAnswer query;
    try {
      query = await _ps(
          setServerPortScript(_app, '-Query'), timeouts.query, '$kSetPortScript -Query');
    } on ArgumentError {
      // P7: the folder makes the call longer than one command line.
      return 'the server folder on $host is too long for one command line ($_app)';
    }
    final port = query.json?['port'];
    final content = query.json?['content'];
    if (query.exit != 0 || port is! int || content is! String) {
      return 'could not read the port on $host (${_psError(query)})';
    }
    try {
      base64.decode(content);
    } on FormatException {
      return 'could not read the port on $host ($kSetPortScript -Query returned no base64)';
    }
    oldPort = port;
    _portFileBase64 = content;
    // An empty server_config.json counts as none (P8): the rollback removes
    // the new file rather than writing the empty one back — the same port,
    // 50051, either way.
    _hadPortFile = content.isNotEmpty;
    final fromFile = query.json?['source'] == 'file';
    log('Current port: $port${fromFile ? '' : ' (the default)'}');
    if (_hadPortFile && !fromFile) {
      log('WARNING: server_config.json on $host does not hold a valid port; '
          'the server uses $port.');
    }
    if (newPort == port) {
      return 'nothing to change: $host already uses port $port';
    }
    setStep(_check, StepStatus.ok, '$port → $newPort');
    return null;
  }

  /// Keeps what the rollback needs: the file's bytes (from -Query) for
  /// -Restore, or -Remove when there was none. Refuses a file too large to
  /// send back in one command (the 2,500-character script limit).
  String? _doBackupWindows() {
    setStep(_backup, StepStatus.running);
    _restoreArgs = _hadPortFile ? "-Restore ${psQuote(_portFileBase64)}" : '-Remove';
    try {
      windowsPs(setServerPortScript(_app, _restoreArgs));
    } on ArgumentError {
      return 'server_config.json on $host is too large to keep for a rollback '
          '(${base64.decode(_portFileBase64).length} bytes)';
    }
    if (_hadPortFile) {
      final size = base64.decode(_portFileBase64).length;
      log('server_config.json kept for a rollback ($size bytes).');
      setStep(_backup, StepStatus.ok, 'server_config.json ($size bytes)');
    } else {
      log('There is no server_config.json on $host (the server used the default '
          '$oldPort); a rollback removes the new one.');
      setStep(_backup, StepStatus.ok, 'no port file');
    }
    return null;
  }

  bool _refuse(String reason, {UpdateStep? at}) {
    final step = at ?? (_connect.status == StepStatus.fail ? _connect : _check);
    setStep(step, StepStatus.fail, reason);
    for (final s in steps.where((s) => s.status == StepStatus.pending)) {
      setStep(s, StepStatus.skipped);
    }
    log('Refused: $reason');
    resultPort = oldPort;
    summary.add(oldPort == null
        ? 'Port not changed: $reason.'
        : 'Port not changed, $host stays on port $oldPort: $reason.');
    return false;
  }

  Future<void> _doBackup() async {
    setStep(_backup, StepStatus.running);
    await ssh.runChecked('cp $kCompose $kCompose$kPortBackupSuffix');
    _hadPortFile = (await ssh.run('test -f $kBoardPortFile')).ok;
    if (_hadPortFile) {
      await ssh.runChecked('cp $kBoardPortFile $kBoardPortFile$kPortBackupSuffix');
    } else {
      log('There is no port file on $host (the server used the default '
          '$oldPort); a rollback removes the new one.');
    }
    _hasAvahi = (await ssh.run('test -f $kAvahiServiceFile')).ok;
    if (_hasAvahi) {
      await ssh.runChecked('cp $kAvahiServiceFile $kAvahiServiceFile$kPortBackupSuffix');
    } else {
      log('No $kAvahiServiceFile on $host: the network announcement skipped '
          '(Search finds this kiosk by its name only).');
    }
    final copies = 1 + (_hadPortFile ? 1 : 0) + (_hasAvahi ? 1 : 0);
    setStep(_backup, StepStatus.ok,
        '$copies cop${copies == 1 ? 'y' : 'ies'}${_hadPortFile ? '' : ' (no port file)'}');
  }

  /// Write, restart, verify; any failure from the first write on rolls back
  /// (or, with the connection gone, says what the machine may be on now).
  Future<bool> _changeAndVerify() async {
    final old = oldPort!;
    try {
      setStep(_write, StepStatus.running);
      if (_windows) {
        // Stop first: the pre-stop hook still finds the server by the old
        // port in the file (D-1).
        final notWritten = await _stopWindows() ?? await _writeWindows();
        if (notWritten != null) {
          await _startAgainWindows(old);
          return _refuse(notWritten, at: _write);
        }
      } else {
        await _writeLinux();
      }

      setStep(_restart, StepStatus.running);
      var waited = Duration.zero;
      bool? listener;
      if (_windows) {
        final started = await _startWindows(newPort);
        listener = started.listening;
        waited = started.waited;
        setStep(_restart, StepStatus.ok, listener ? 'listening' : 'no listener seen');
      } else {
        await _restartServices();
        setStep(_restart, StepStatus.ok);
      }

      setStep(_verify, StepStatus.running);
      final problem = await _verifyPort(newPort, waited: waited, listener: listener);
      if (problem == null) {
        setStep(_verify, StepStatus.ok, 'GetKioskInfo: port $newPort');
        resultPort = newPort;
        notice = _windows
            ? 'New port on $host: $newPort (the server accepts local connections only).\n'
                'The FaceSnap apps on that PC follow after they restart; '
                'other programs on that PC must use 127.0.0.1:$newPort.'
            : 'New address: $host:$newPort\n'
                'If this machine runs a firewall, open port $newPort.';
        log('$host now serves on port $newPort.');
        summary.add('$host now uses port $newPort (was $old).');
        return true;
      }
      setStep(_verify, StepStatus.fail, problem);
      log('Verification failed: $problem');
      return _rollBack(problem);
    } catch (e) {
      if (isConnectionLoss(e)) return _connectionLost(e);
      // Anything else — a failed command, no answer within a limit — is a
      // failure: try the rollback.
      for (final s in steps.where((s) => s.status == StepStatus.running)) {
        setStep(s, StepStatus.fail, shorten('$e'));
      }
      log('FAILED: $e');
      return _rollBack(shorten('$e'));
    }
  }

  Future<void> _writeLinux() async {
    await _writeAll({
      kBoardPortFile: portFileContent(newPort),
      kCompose: _newCompose,
      if (_hasAvahi) kAvahiServiceFile: avahiService(newPort),
    });
    setStep(_write, StepStatus.ok, 'port $newPort');
    log('Port file, docker-compose.yml${_hasAvahi ? ' and the avahi service' : ''} '
        'now say $newPort.');
  }

  /// set_server_port.ps1 -Port N. Returns the reason when it wrote nothing
  /// (exit 2 out of range, exit 3 port in use, exit 4 with "written": false);
  /// throws when the file may have changed (exit 4 with "written": true or
  /// without "written", no JSON line, any other answer) so the caller rolls
  /// back.
  Future<String?> _writeWindows() async {
    final answer = await _ps(setServerPortScript(_app, '-Port $newPort'), timeouts.write,
        '$kSetPortScript -Port $newPort');
    final json = answer.json;
    if (answer.exit == 0 && json?['ok'] == true && json?['port'] == newPort) {
      setStep(_write, StepStatus.ok, 'port $newPort');
      log('server_config.json now says $newPort.');
      return null;
    }
    final nothingWritten = json != null &&
        json['ok'] == false &&
        (answer.exit == 2 || answer.exit == 3 || (answer.exit == 4 && json['written'] == false));
    if (nothingWritten) return _psError(answer);
    if (json == null) {
      throw _Failure('$kSetPortScript -Port $newPort printed no result (${_psError(answer)})');
    }
    if (answer.exit == 0) {
      throw _Failure('$kSetPortScript -Port $newPort reported port ${json['port']}');
    }
    throw _Failure(_psError(answer));
  }

  /// Stop-Service (NSSM's pre-stop hook shuts the server down in order).
  /// Returns the reason when the stop failed; throws when it got no answer.
  Future<String?> _stopWindows() async {
    log('Stopping the $kWindowsService service …');
    final answer = await _sendStop(
        () => _ps(windowsStopScript, timeouts.write, 'Stop-Service $kWindowsService'));
    if (answer.exit != 0 || answer.json?['stopped'] != true) {
      return 'could not stop the $kWindowsService service on $host (${_psError(answer)})';
    }
    log('The $kWindowsService service is stopped.');
    return null;
  }

  /// After a stop with nothing written: the service started again on [old]
  /// and verified there. Throws when it does not come back (the caller then
  /// rolls back).
  Future<void> _startAgainWindows(int old) async {
    log('Nothing was written; starting the $kWindowsService service again on port $old.');
    final started = await _startWindows(old);
    final problem = await _verifyPort(old, waited: started.waited, listener: started.listening);
    if (problem != null) throw _Failure(problem);
  }

  /// Start-Service and the listener wait in one call: whether
  /// face_snap_server listens on [port] (a hint only) and how long that wait
  /// took. Throws when the start fails.
  Future<({bool listening, Duration waited})> _startWindows(int port) async {
    log('Starting the $kWindowsService service …');
    final seconds = (readyTimeout.inMilliseconds / 1000).ceil();
    final answer = await _sendRestart(() => _ps(windowsStartScript(port, seconds),
        readyTimeout + timeouts.restartSlack, 'Start-Service $kWindowsService'));
    final listening = answer.json?['listening'];
    if (answer.exit != 0 || listening is! bool) {
      throw _Failure('Start-Service $kWindowsService failed (${_psError(answer)})');
    }
    log(listening
        ? 'face_snap_server is listening on port $port.'
        : 'No face_snap_server listener on port $port within $seconds s.');
    final waited = answer.json?['waited_ms'];
    return (
      listening: listening,
      waited: Duration(milliseconds: waited is int && waited > 0 ? waited : 0),
    );
  }

  /// Sends the restart [call] and notes that a restart was sent — unless
  /// the SSH transport was already closed (SSHStateError: this command never
  /// left this machine; an earlier restart still counts).
  Future<T> _sendRestart<T>(Future<T> Function() call) async {
    final before = _restartSent;
    _restartSent = true;
    try {
      return await call();
    } on SSHStateError {
      _restartSent = before;
      rethrow;
    }
  }

  /// [_sendRestart] for the Windows stop.
  Future<T> _sendStop<T>(Future<T> Function() call) async {
    final before = _stopSent;
    _stopSent = true;
    try {
      return await call();
    } on SSHStateError {
      _stopSent = before;
      rethrow;
    }
  }

  Future<void> _restartServices() async {
    log('Restarting $kServiceUnit …');
    await _sendRestart(
        () => _runChecked('systemctl restart $kServiceUnit', limit: timeouts.boardRestart));
    if (_hasAvahi) {
      final avahi = await _run('systemctl restart avahi-daemon');
      if (!avahi.ok) {
        log('WARNING: avahi-daemon did not restart (${shorten(avahi.combined.trim())}); '
            'Search may show the old port until it does.');
      }
    }
  }

  /// Null when GetKioskInfo on [port] answers [port] within [readyTimeout];
  /// otherwise what went wrong. The deadline counts from the restart's
  /// return; [waited] is the part of it the Windows restart script already
  /// spent on its listener wait (P5). With [listener] null (a board) each
  /// round first looks for an `ss` listener, for the log only; otherwise
  /// [listener] is the Windows restart's hint. The deadline is checked
  /// between attempts, so the last attempt may overshoot it by one
  /// [checkServer] call (the default one is bounded by its tunnel limit and
  /// its own 5 s gRPC deadline).
  Future<String?> _verifyPort(int port,
      {Duration waited = Duration.zero, bool? listener}) async {
    final clock = Stopwatch()..start();
    var listenerSeen = listener ?? false;
    while (true) {
      if (listener == null && !listenerSeen) {
        final ss = await _run(listenersCmd(port), limit: timeouts.query);
        if (ss.ok && ss.stdout.trim().isNotEmpty) {
          listenerSeen = true;
          log('A listener is up on port $port.');
        }
      }
      final answer = await checkServer(ssh, port);
      if (answer == port) return null;
      if (answer != null) {
        return 'the server answers on port $port but reports port $answer';
      }
      if (waited + clock.elapsed >= readyTimeout) {
        return 'the server does not answer GetKioskInfo on port $port'
            '${listenerSeen ? '' : ' (no listener seen)'}';
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  Future<bool> _rollBack(String why) async {
    final old = oldPort!;
    steps.add(_rollback);
    _rollbackStarted = true;
    setStep(_rollback, StepStatus.running);
    log('Rolling back to port $old …');
    try {
      if (_windows) {
        await _restoreWindows(old);
      } else {
        await _restoreLinux(old);
      }
    } catch (e) {
      // A rollback that gets no answer either: the link is as good as gone.
      if (isConnectionLoss(e) || e is PortNoAnswer) return _connectionLost(e);
      setStep(_rollback, StepStatus.fail, shorten('$e'));
      log('ROLLBACK FAILED: $e');
      resultPort = null;
      summary.add('Port change failed ($why) and the rollback failed too '
          '(${shorten('$e')}): $host may be on port $newPort or $old. '
          '${_restoreByHand()}');
      return false;
    }
    setStep(_rollback, StepStatus.ok, 'port $old');
    resultPort = old;
    log('Rolled back: $host is back on port $old.');
    summary.add('Port change failed ($why); $host is back on port $old.');
    return false;
  }

  /// The backups back in place — copied to `.tmp`, then all moved (and a
  /// port file that was not there before removed) in ONE command (D-4); the
  /// services restarted only when the restart had been sent (M1) —
  /// otherwise the server never left [old].
  Future<void> _restoreLinux(int old) async {
    final backedUp = [
      if (_hadPortFile) kBoardPortFile,
      kCompose,
      if (_hasAvahi) kAvahiServiceFile,
    ];
    await _runChecked([
      for (final p in backedUp) "cp '$p$kPortBackupSuffix' '$p$kPortTempSuffix'",
      _moveAllCmd(backedUp),
      if (!_hadPortFile) "rm -f '$kBoardPortFile'",
    ].join(' && '));
    // A write that failed between its .tmp and the move leaves the .tmp.
    await _runChecked('rm -f ${_tempFiles.map((f) => "'$f'").join(' ')}');
    if (_restartSent) {
      await _restartServices();
    } else {
      log('The server was not restarted: it still serves port $old.');
    }
    final problem = await _verifyPort(old);
    if (problem != null) throw Exception(problem);
  }

  /// Stop the service when it was started on the new port (while the file
  /// still names that port, D-1), -Restore the old bytes (or -Remove the new
  /// file), then start it on [old] — only when the stop had been sent:
  /// otherwise the server never left [old].
  Future<void> _restoreWindows(int old) async {
    if (_restartSent) {
      final notStopped = await _stopWindows();
      if (notStopped != null) throw _Failure(notStopped);
    }
    final mode = _hadPortFile ? '-Restore' : '-Remove';
    final answer = await _ps(
        setServerPortScript(_app, _restoreArgs), timeouts.write, '$kSetPortScript $mode');
    if (answer.exit != 0 || answer.json?['ok'] != true) {
      throw _Failure('$kSetPortScript $mode failed: ${_psError(answer)}');
    }
    log(_hadPortFile
        ? 'server_config.json restored.'
        : 'server_config.json removed (there was none before).');
    var listener = true;
    var waited = Duration.zero;
    if (_stopSent) {
      final started = await _startWindows(old);
      listener = started.listening;
      waited = started.waited;
    } else {
      log('The service was not stopped: the server still serves port $old.');
    }
    final problem = await _verifyPort(old, waited: waited, listener: listener);
    if (problem != null) throw _Failure(problem);
  }

  /// How to put the old port back by hand.
  String _restoreByHand() => _windows
      ? 'Check by hand, as an administrator on $host: '
          'Stop-Service $kWindowsService, then ${setServerPortCall(_app, _restoreArgs)}, '
          'then Start-Service $kWindowsService.'
      : 'Check by hand: restore $kCompose$kPortBackupSuffix to docker-compose.yml, '
          '${_hadPortFile ? 'restore $kBoardPortFile$kPortBackupSuffix to server_config.json' : 'delete $kBoardPortFile (there was none before)'}'
          '${_hasAvahi ? ', restore $kAvahiServiceFile$kPortBackupSuffix' : ''}, '
          'then systemctl restart $kServiceUnit.';

  /// The connection is gone (or a rollback got no answer): no rollback over
  /// it. Before the restart was sent a board's server still runs the old
  /// port, but the files may already be partly changed and its next restart
  /// would read them (I1); a Windows service may be stopped (D-1); after the
  /// (re)start, the machine may be on either port.
  bool _connectionLost(Object e) {
    for (final s in steps.where((s) => s.status == StepStatus.running)) {
      setStep(s, StepStatus.fail, 'connection lost');
    }
    log('Connection lost: $e');
    resultPort = null;
    final check = _windows ? 'check the server on that PC' : 'check with Search';
    final state = _restartSent
        ? '$host may be on port $newPort or $oldPort; $check'
        : _stopSent
            ? 'the $kWindowsService service on $host may be stopped, and its '
                'server_config.json may already say port $newPort'
            : 'the port files on $host may be partly changed; its server runs on '
                'port $oldPort only until its next restart';
    final hint = _rollbackStarted || !_restartSent ? ' ${_restoreByHand()}' : '';
    summary.add('connection lost: $state.'
        '${_rollbackStarted ? ' The rollback was interrupted.' : ''}$hint');
    return false;
  }
}
