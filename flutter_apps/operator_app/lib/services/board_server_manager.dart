// FaceSnap server control on a kiosk board (Odroid/Radxa) over SSH: the
// board-side counterpart of ServerManager. The server runs as the
// face-snap-docker-compose.service systemd unit (see the updater app's
// update_engine.dart, which installs it). SSH credentials come from the
// operator's config.json (AppConfig). The SSH plumbing is the shared
// SshRunner (sync copy with the updater app), not its own dartssh2 code.
import 'dart:async';

import 'app_config.dart';
import 'ssh_runner.dart';

enum BoardServerStatus { running, stopped, unreachable, noCredentials }

class BoardServerManager {
  BoardServerManager._();

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

  /// systemctl start blocks until `docker compose up -d` returns, so a
  /// completed call means the container is up (the gRPC port follows within
  /// seconds).
  static Future<void> start(String host) =>
      _run(host, 'systemctl start $_service');

  static Future<void> stop(String host) =>
      _run(host, 'systemctl stop $_service');

  static Future<void> restart(String host) =>
      _run(host, 'systemctl restart $_service');
}
