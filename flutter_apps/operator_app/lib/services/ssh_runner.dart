// Thin wrapper around dartssh2: run remote commands collecting stdout/stderr
// and exit code, and stream local files into a remote command's stdin.
//
// Shared verbatim with the operator app (client/flutter/operator_app/lib/
// services/ssh_runner.dart) - keep the two copies in sync; it is deliberately
// self-contained (dartssh2 + dart:io only) so it can be dropped into either
// app unchanged.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

class CmdResult {
  CmdResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get ok => exitCode == 0;
  String get combined =>
      [stdout, stderr].where((s) => s.trim().isNotEmpty).join('\n');
}

class SshRunner {
  SshRunner._(this._client);

  final SSHClient _client;

  static Future<SshRunner> connect(
      String host, String user, String password) async {
    final socket = await SSHSocket.connect(host, 22,
        timeout: const Duration(seconds: 15));
    final client = SSHClient(
      socket,
      username: user,
      onPasswordRequest: () => password,
    );
    await client.authenticated;
    return SshRunner._(client);
  }

  /// Run a command, collect stdout/stderr, return the exit code.
  Future<CmdResult> run(String command,
      {Duration timeout = const Duration(minutes: 3)}) async {
    final session = await _client.execute(command);
    try {
      final out = BytesBuilder(copy: false);
      final err = BytesBuilder(copy: false);
      await Future.wait([
        session.stdout.forEach(out.add),
        session.stderr.forEach(err.add),
        session.done,
      ]).timeout(timeout, onTimeout: () {
        throw TimeoutException('Remote command timed out: $command');
      });
      return CmdResult(
        session.exitCode ?? -1,
        utf8.decode(out.takeBytes(), allowMalformed: true),
        utf8.decode(err.takeBytes(), allowMalformed: true),
      );
    } finally {
      // Channels count against sshd's MaxSessions (default 10) until they are
      // closed — without this, the 11th command kills the whole connection.
      session.close();
    }
  }

  /// Like [run], but throws with a readable message on a non-zero exit.
  Future<CmdResult> runChecked(String command,
      {Duration timeout = const Duration(minutes: 3)}) async {
    final result = await run(command, timeout: timeout);
    if (!result.ok) {
      throw Exception(
          'Command failed (exit ${result.exitCode}): $command\n${result.combined}');
    }
    return result;
  }

  /// Stream a local file into `command`'s stdin (e.g. `docker load`).
  /// [onProgress] receives the number of bytes sent so far.
  Future<CmdResult> runWithFileStdin(String command, File file,
      {void Function(int sentBytes)? onProgress}) async {
    final session = await _client.execute(command);
    try {
      final out = BytesBuilder(copy: false);
      final err = BytesBuilder(copy: false);
      final outDone = session.stdout.forEach(out.add);
      final errDone = session.stderr.forEach(err.add);

      var sent = 0;
      var lastReport = 0;
      await session.stdin.addStream(file.openRead().map((chunk) {
        sent += chunk.length;
        // Throttle progress callbacks to every 4 MB.
        if (onProgress != null && sent - lastReport >= 4 * 1024 * 1024) {
          lastReport = sent;
          onProgress(sent);
        }
        return chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
      }));
      onProgress?.call(sent);
      await session.stdin.close();

      await Future.wait([outDone, errDone, session.done]);
      return CmdResult(
        session.exitCode ?? -1,
        utf8.decode(out.takeBytes(), allowMalformed: true),
        utf8.decode(err.takeBytes(), allowMalformed: true),
      );
    } finally {
      session.close();
    }
  }

  /// Download a (small) remote file to a local path via SFTP.
  Future<void> downloadFile(String remotePath, String localPath) async {
    final sftp = await _client.sftp();
    final remote = await sftp.open(remotePath);
    try {
      final data = await remote.readBytes();
      await File(localPath).writeAsBytes(data, flush: true);
    } finally {
      await remote.close();
      sftp.close();
    }
  }

  /// Write a small text file on the remote host (via stdin, no SFTP needed).
  Future<void> writeRemoteFile(String path, String content) async {
    final session = await _client.execute("cat > '$path'");
    try {
      session.stdin.add(Uint8List.fromList(utf8.encode(content)));
      await session.stdin.close();
      await session.done;
      if ((session.exitCode ?? -1) != 0) {
        throw Exception('Failed to write remote file $path');
      }
    } finally {
      session.close();
    }
  }

  void close() => _client.close();
}
