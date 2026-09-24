// The live connection status under the Kiosk card's credentials. A cheap SSH
// probe answers, SEPARATELY, "is the kiosk reachable?" and "does the updater
// get logged in?" — and reports what it found there (board, installed server
// version, running or not). It uses the same identify/inspect commands as the
// pipelines' first steps (kiosk.dart), so the strip and a run never disagree.
// The label mapping and the image-version comparison are pure functions,
// unit-tested without a board.
import 'dart:async';

import 'package:dartssh2/dartssh2.dart';

import 'kiosk.dart';
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

  bool get connected => state == ProbeState.connected;

  /// A verdict is in: not idle, not still checking.
  bool get settled =>
      state != ProbeState.idle && state != ProbeState.checking;
}

/// Probe [host] with [user]/[password]: connect, identify the board, read the
/// installed image and whether the service is active. Never throws — every
/// outcome is a [ProbeResult].
Future<ProbeResult> probeKiosk(
    String host, String user, String password) async {
  SshRunner ssh;
  try {
    ssh = await SshRunner.connect(host, user, password);
  } on SSHAuthFailError {
    return ProbeResult(ProbeState.authFailed, host: host, user: user);
  } catch (e) {
    return ProbeResult(ProbeState.unreachable,
        host: host, user: user, error: shortConnectionError('$e'));
  }
  try {
    final id = await identifyBoard(ssh);
    if (id.arch != 'aarch64') {
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
        serverRunning: running);
  } catch (e) {
    return ProbeResult(ProbeState.unreachable,
        host: host, user: user, error: shortConnectionError('$e'));
  } finally {
    ssh.close();
  }
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
        'Not an arm64 board (${r.arch}) — is ${r.host} the right machine?',
    };

/// The strip's second line: what is installed. Only for a connected probe.
String? probeDetail(ProbeResult r) {
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
  final have = _versionCore(installedVersion);
  final want = _versionCore(tarTag);
  if (have == null || want == null) return null;
  final cmp = _compareVersions(have, want);
  if (cmp == 0) return (text: 'version $have is already installed', warn: true);
  if (cmp > 0) return (text: 'downgrade: $have → $want', warn: true);
  return (text: 'upgrade: $have → $want', warn: false);
}

/// "2.0.11-arm64" -> "2.0.11"; null when the tag starts with no dotted number
/// ("arm64", "latest").
String? _versionCore(String? tag) =>
    tag == null ? null : RegExp(r'^\d+(?:\.\d+)*').firstMatch(tag)?.group(0);

int _compareVersions(String a, String b) {
  final pa = a.split('.').map(int.parse).toList();
  final pb = b.split('.').map(int.parse).toList();
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
