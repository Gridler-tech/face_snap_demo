// The live connection status under the Kiosk card's credentials. A cheap SSH
// probe answers, SEPARATELY, "is the kiosk reachable?" and "does the updater
// get logged in?" — and reports what it found there (board or Windows PC,
// installed server version, running or not, the server port). It uses the
// same identify/inspect commands as the pipelines (kiosk.dart, server_port.dart),
// so the strip and a run never disagree.
// The label mapping and the image-version comparison are pure functions,
// unit-tested without a board.
import 'dart:async';

import 'package:dartssh2/dartssh2.dart';

import 'batch_runner.dart';
import 'kiosk.dart';
import 'server_port.dart';
import '../services/ssh_runner.dart';

enum ProbeState {
  /// Host, user or password still empty — nothing to check yet.
  idle,
  checking,
  connected,

  /// No SSH connection could be made (timeout, refused, unknown name).
  unreachable,

  /// The host answered but rejected the password.
  authFailed,

  /// Logged in, but not an arm64 board — almost certainly the wrong machine.
  wrongArch,

  /// Logged in on a Windows PC: only its server port can be changed here
  /// (no update, backup, restore or remove).
  windowsPc,
}

class ProbeResult {
  const ProbeResult(
    this.state, {
    this.host = '',
    this.user = '',
    this.model = '',
    this.arch = '',
    this.installedVersion,
    this.serverRunning = false,
    this.error = '',
    this.currentPort,
  });

  static const idle = ProbeResult(ProbeState.idle);
  static const checking = ProbeResult(ProbeState.checking);

  final ProbeState state;
  final String host;
  final String user;
  final String model;
  final String arch;

  /// Installed server version (the compose image tag); null when no FaceSnap
  /// server is installed — a clean board or a removed installation.
  final String? installedVersion;
  final bool serverRunning;

  /// Short reason for [ProbeState.unreachable].
  final String error;

  /// The port the server uses: a connected board's port file (else 50051),
  /// a Windows PC's set_server_port.ps1 -Query; null when unknown (another
  /// state, or a Windows PC without a server that has the script).
  final int? currentPort;

  /// A connected arm64 board: every action of the page.
  bool get connected => state == ProbeState.connected;

  /// The "Server port" card works: a connected board or a Windows PC.
  bool get portChangeable => connected || state == ProbeState.windowsPc;

  /// A verdict is in: not idle, not still checking.
  bool get settled =>
      state != ProbeState.idle && state != ProbeState.checking;
}

/// Probe [host] with [user]/[password]: connect, identify the machine; for a
/// board read the installed image, whether the service is active and the
/// port; for a Windows PC the port. Never throws — every outcome is a
/// [ProbeResult]. [connect] opens the SSH connection (tests script one).
Future<ProbeResult> probeKiosk(String host, String user, String password,
    {Future<SshRunner> Function(String host, String user, String password)
        connect = SshRunner.connect}) async {
  SshRunner ssh;
  try {
    ssh = await connect(host, user, password);
  } on SSHAuthFailError {
    return ProbeResult(ProbeState.authFailed, host: host, user: user);
  } catch (e) {
    return ProbeResult(ProbeState.unreachable,
        host: host, user: user, error: shortConnectionError('$e'));
  }
  try {
    final id = await identifyTarget(ssh);
    if (id.kind == TargetKind.windowsPc) {
      return ProbeResult(ProbeState.windowsPc,
          host: host,
          user: user,
          model: id.model,
          arch: id.arch,
          currentPort: await readWindowsPort(ssh));
    }
    if (id.kind != TargetKind.linuxBoard || id.arch != 'aarch64') {
      return ProbeResult(ProbeState.wrongArch,
          host: host, user: user, model: id.model, arch: id.arch);
    }
    final image =
        (await ssh.run(composeImageCmd(kCompose, tolerateMissing: true)))
            .stdout
            .trim();
    String? version;
    var running = false;
    if (image.isNotEmpty) {
      version = tagOf(image) ?? image;
      final active =
          (await ssh.run('systemctl is-active $kServiceUnit')).stdout.trim();
      running = active == 'active' || active == 'activating';
    }
    return ProbeResult(ProbeState.connected,
        host: host,
        user: user,
        model: id.model,
        arch: id.arch,
        installedVersion: version,
        serverRunning: running,
        currentPort: await readBoardPort(ssh));
  } catch (e) {
    return ProbeResult(ProbeState.unreachable,
        host: host, user: user, error: shortConnectionError('$e'));
  } finally {
    ssh.close();
  }
}

/// The batch pre-flight's verdict on [target] from its probe [r]: a
/// connected board goes ahead; a Windows PC is no kiosk board (only its port
/// can be changed, on the Updater page); the rest is skipped with the
/// strip's headline.
PreflightResult preflightResultOf(BatchTarget target, ProbeResult r) {
  final verdict = switch (r.state) {
    ProbeState.connected => PreflightVerdict.ok,
    ProbeState.authFailed => PreflightVerdict.authFailed,
    ProbeState.wrongArch || ProbeState.windowsPc => PreflightVerdict.wrongArch,
    _ => PreflightVerdict.unreachable,
  };
  return PreflightResult(target, verdict,
      detail: switch (r.state) {
        ProbeState.connected => '${r.model}, ${r.installedVersion ?? "clean board"}',
        ProbeState.windowsPc => 'Windows PC: not a kiosk board',
        _ => probeHeadline(r),
      },
      installedVersion: r.installedVersion);
}

/// A raw socket/SSH exception boiled down to the few words an operator needs
/// ("timed out", "connection refused", "name not found"), so the strip never
/// shows an errno dump.
String shortConnectionError(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('timed out') || s.contains('timeout')) return 'timed out';
  if (s.contains('refused')) return 'connection refused';
  if (s.contains('not known') ||
      s.contains('no such host') ||
      s.contains('failed host lookup') ||
      s.contains('nodename nor servname')) {
    return 'name not found';
  }
  if (s.contains('unreachable') || s.contains('no route')) return 'no route';
  return 'no SSH connection';
}

/// The strip's one-line headline for [r].
String probeHeadline(ProbeResult r) => switch (r.state) {
      ProbeState.idle => 'Enter a kiosk, user and password',
      ProbeState.checking => 'Checking…',
      ProbeState.connected =>
        'Connected — ${r.model} · logged in as ${r.user}',
      ProbeState.authFailed => 'Password rejected for ${r.user} on ${r.host}',
      ProbeState.unreachable =>
        '${r.host} not reachable${r.error.isEmpty ? '' : ' (${r.error})'}',
      ProbeState.wrongArch =>
        'Not an arm64 board${r.arch.isEmpty ? '' : ' (${r.arch})'} — is ${r.host} the right machine?',
      ProbeState.windowsPc => 'Windows PC ${r.model} · logged in as ${r.user}',
    };

/// The strip's second line: what is installed. For a connected probe, and for
/// a Windows PC without a server the Updater can change the port of.
String? probeDetail(ProbeResult r) {
  if (r.state == ProbeState.windowsPc) {
    return r.currentPort == null
        ? 'no FaceSnap server 1.1.25 or later found (FaceSnapServer service '
            'with set_server_port.ps1)'
        : null;
  }
  if (!r.connected) return null;
  final v = r.installedVersion;
  if (v == null) {
    return 'clean board, no FaceSnap server (Update will set it up)';
  }
  return 'FaceSnap $v installed, server ${r.serverRunning ? 'running' : 'stopped'}';
}

/// Note beside the chosen image comparing it with the installed version:
/// same version, downgrade or upgrade. null when either side is unknown or
/// carries no dotted version. [warn] marks the two cases worth a second look.
({String text, bool warn})? imageVersionNote(
    String? installedVersion, String? tarName) {
  if (installedVersion == null || tarName == null) return null;
  final tarTag = RegExp(r'face_snap-(.+?)\.tar$').firstMatch(tarName)?.group(1);
  final have = versionCore(installedVersion);
  final want = versionCore(tarTag);
  if (have == null || want == null) return null;
  final cmp = compareVersions(have, want);
  if (cmp == 0) return (text: 'version $have is already installed', warn: true);
  if (cmp > 0) return (text: 'downgrade: $have → $want', warn: true);
  return (text: 'upgrade: $have → $want', warn: false);
}

/// "2.0.11-arm64" -> "2.0.11"; null when the tag starts with no dotted number
/// ("arm64", "latest").
String? versionCore(String? tag) =>
    tag == null ? null : RegExp(r'^\d+(?:\.\d+)*').firstMatch(tag)?.group(0);

/// Compares dotted numeric versions ("2.0.9" < "2.0.24"); a missing part
/// counts as 0. Both must be [versionCore]s.
int compareVersions(String a, String b) {
  final pa = a.split('.').map(int.parse).toList();
  final pb = b.split('.').map(int.parse).toList();
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
