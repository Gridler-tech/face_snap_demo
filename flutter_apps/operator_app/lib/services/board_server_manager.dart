// FaceSnap server control on a kiosk board (Odroid/Radxa) over SSH: the
// board-side counterpart of ServerManager. The server runs as the
// face-snap-docker-compose.service systemd unit (see the updater app's
// update_engine.dart, which installs it). SSH credentials come from the
// operator's config.json (AppConfig). The SSH plumbing is the shared
// SshRunner (sync copy with the updater app), not its own dartssh2 code.
import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';

import 'app_config.dart';
import 'rpc_error.dart';
import 'ssh_runner.dart';

enum BoardServerStatus { running, stopped, unreachable, noCredentials }

/// A change-board-password failure carrying a message ready to show the
/// operator (wrong current password, host unreachable, chpasswd refused).
class BoardPasswordException implements Exception {
  const BoardPasswordException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BoardServerManager {
  BoardServerManager._();

  // Same literal as updater_app/lib/kiosk.dart's kServiceUnit (the board
  // contract's owner) — keep the two in sync on a rename.
  static const _service = 'face-snap-docker-compose.service';

  /// true when [host] is not this machine — only then can it be a board.
  /// (A Windows host without sshd simply reports unreachable.)
  static bool isRemoteHost(String host) {
    final h = host.trim().toLowerCase();
    return h.isNotEmpty && h != 'localhost' && h != '127.0.0.1' && h != '::1';
  }

  static Future<String> _run(String host, String command,
      {Duration timeout = const Duration(minutes: 3)}) async {
    final ssh = await SshRunner.connect(
        host, AppConfig.boardUser, AppConfig.boardPassword);
    try {
      final result = await ssh.run(command, timeout: timeout);
      return result.stdout.trim();
    } finally {
      ssh.close();
    }
  }

  static Future<BoardServerStatus> status(String host) async {
    if (AppConfig.boardPassword.isEmpty) {
      return BoardServerStatus.noCredentials;
    }
    try {
      // "active" / "activating" = up (or coming up); "inactive" / "failed" =
      // down. is-active exits non-zero when inactive, but run() only collects
      // output, so parse the text.
      final out = await _run(host, 'systemctl is-active $_service',
          timeout: const Duration(seconds: 20));
      return out == 'active' || out == 'activating'
          ? BoardServerStatus.running
          : BoardServerStatus.stopped;
    } catch (_) {
      return BoardServerStatus.unreachable;
    }
  }

  /// The board server's version, read from the compose file's image tag over
  /// SSH — the tag is the version's single source of truth on a board (the
  /// server binary carries no version of its own, and this is also where the
  /// updater's "Inspect the current installation" reads it). null when the
  /// board is unreachable or runs no known layout.
  static Future<String?> serverVersion(String host) async {
    if (AppConfig.boardPassword.isEmpty) return null;
    try {
      final out = await _run(
          host,
          r"sed -n 's/^[[:space:]]*image:[[:space:]]*//p' "
          '/root/face_snap/docker-compose.yml',
          timeout: const Duration(seconds: 20));
      return versionFromImageTag(out);
    } catch (_) {
      return null;
    }
  }

  /// 'facesnap2:2.0.11-arm64' -> '2.0.11', first-generation
  /// 'face_snap:1.4.0' -> '1.4.0'; null when there is no tag. Exposed for
  /// tests.
  static String? versionFromImageTag(String image) {
    final tag = image.trim().split('\n').first.trim();
    final colon = tag.lastIndexOf(':');
    if (colon <= 0 || colon == tag.length - 1) return null;
    var version = tag.substring(colon + 1);
    // The architecture suffix is not part of the version the operator cares
    // about.
    for (final suffix in const ['-arm64', '-x64']) {
      if (version.endsWith(suffix)) {
        version = version.substring(0, version.length - suffix.length);
      }
    }
    return version;
  }

  /// systemctl start blocks until `docker compose up -d` returns, so a
  /// completed call means the container is up (the gRPC port follows within
  /// seconds).
  static Future<void> start(String host) =>
      _run(host, 'systemctl start $_service');

  static Future<void> stop(String host) =>
      _run(host, 'systemctl stop $_service');

  static Future<void> restart(String host) =>
      _run(host, 'systemctl restart $_service');

  /// Change the board's login password over SSH. Authenticating with
  /// [currentPassword] is itself the check that it is correct; the new
  /// password is then set for [AppConfig.boardUser] via `chpasswd` (the fleet
  /// boards log in as root, so no sudo). Throws [BoardPasswordException] with
  /// an operator-readable message on any failure. On success the caller must
  /// store the new password (see AppConfig) — this method does not, so the
  /// service layer stays free of app state.
  static Future<void> changePassword(
      String host, String user, String currentPassword, String newPassword) async {
    SshRunner ssh;
    try {
      ssh = await SshRunner.connect(host, user, currentPassword);
    } on SSHAuthFailError {
      throw const BoardPasswordException('The current password is incorrect.');
    } catch (e) {
      throw BoardPasswordException(
          'Could not reach $host over SSH: ${operatorMessage(e)}');
    }
    try {
      // chpasswd reads "user:password" from stdin. The line is base64-encoded
      // so the new password — whatever characters it contains (spaces, quotes,
      // $, …) — never reaches the remote shell parser; only the base64 alphabet
      // [A-Za-z0-9+/=] appears on the command line.
      final payload = base64.encode(utf8.encode('$user:$newPassword'));
      final result = await ssh.run("echo '$payload' | base64 -d | chpasswd",
          timeout: const Duration(seconds: 20));
      if (!result.ok) {
        final detail = result.combined.trim();
        throw BoardPasswordException('The kiosk rejected the password change: '
            '${detail.isEmpty ? 'chpasswd exited ${result.exitCode}' : detail}');
      }
    } finally {
      ssh.close();
    }
  }

  /// Validate the change-password form. Returns an operator-readable error, or
  /// null when the inputs are acceptable. Factored out of the dialog so it can
  /// be unit-tested without pumping a widget.
  static String? validatePasswordChange(
      String current, String next, String repeat) {
    if (current.isEmpty) return 'Enter the current password.';
    if (next.isEmpty) return 'Enter a new password.';
    if (next.length < 4) {
      return 'The new password must be at least 4 characters.';
    }
    if (next != repeat) return 'The new passwords do not match.';
    if (next == current) {
      return 'The new password is the same as the current one.';
    }
    return null;
  }
}
