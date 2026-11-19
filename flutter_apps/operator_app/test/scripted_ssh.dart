// A general SshRunner test double: commands are answered by RegExp rules
// (first match wins; an unmatched command exits 127, like a shell that does
// not know it), every call is recorded, and the connection can be made to
// drop after a given command (every later call throws, as a lost SSH
// transport does), and a command can be made to never answer (a half-open
// link: the caller's timeout must end the wait). A Windows command line
// (`powershell ... -EncodedCommand <base64>`) can be matched on its decoded
// script with [ScriptedSsh.onPs].
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:operator_app/services/ssh_runner.dart';

/// The script inside a `powershell ... -EncodedCommand <base64 of UTF-16LE>`
/// command line (as built by `windowsPs`), or null for any other command.
String? decodedPowerShell(String command) {
  final match = RegExp(r'^powershell .*-EncodedCommand (\S+)$').firstMatch(command);
  if (match == null) return null;
  final List<int> bytes;
  try {
    bytes = base64.decode(match.group(1)!);
  } on FormatException {
    return null;
  }
  if (bytes.length.isOdd) return null;
  return String.fromCharCodes([
    for (var i = 0; i < bytes.length; i += 2) bytes[i] | (bytes[i + 1] << 8),
  ]);
}

class ScriptedSsh implements SshRunner {
  /// [script]: pattern → answer, tried in insertion order. A pattern is a
  /// [RegExp] or a String (matched as a RegExp too).
  ScriptedSsh([Map<Pattern, CmdResult> script = const {}]) {
    script.forEach(on);
  }

  /// (pattern, answer, matched on the decoded PowerShell script).
  final _rules = <(RegExp, CmdResult Function(String command), bool)>[];

  /// Every command run, in order; a file write shows as `write <path>`, a
  /// download as `download <path>`, a port forward as `forward <host>:<port>`.
  final commands = <String>[];

  /// The decoded scripts of the PowerShell commands run, in order.
  List<String> get scripts =>
      commands.map(decodedPowerShell).whereType<String>().toList();

  /// Remote files written with [writeRemoteFile]: path → content (last wins).
  final writes = <String, String>{};

  /// Remote files [downloadFile] can fetch: path → content.
  final remoteFiles = <String, String>{};

  /// Answers [forwardLocal]; null → it throws (no forward scripted).
  Future<SSHSocket> Function(String host, int port)? onForward;

  RegExp? _failAfter;
  RegExp? _failAfterPs;
  RegExp? _failWrite;
  RegExp? _hang;
  RegExp? _hangPs;
  RegExp? _hangWrite;
  bool _lost = false;
  bool closed = false;

  /// Answer commands matching [pattern] with [result].
  void on(Pattern pattern, CmdResult result) => onCall(pattern, (_) => result);

  /// Answer commands matching [pattern] with [answer] (sees the command).
  void onCall(Pattern pattern, CmdResult Function(String command) answer) =>
      _rules.add((
        pattern is RegExp ? pattern : RegExp(pattern.toString()),
        answer,
        false,
      ));

  /// Answer PowerShell commands whose decoded script matches [pattern];
  /// [answer] sees the decoded script.
  void onPs(Pattern pattern, CmdResult Function(String script) answer) =>
      _rules.add((
        pattern is RegExp ? pattern : RegExp(pattern.toString()),
        answer,
        true,
      ));

  /// After the first command matching [pattern] has run (and answered),
  /// the connection is lost: every later call throws.
  void failAfter(RegExp pattern) => _failAfter = pattern;

  /// Like [failAfter], for the first PowerShell command whose decoded script
  /// matches [pattern].
  void failAfterPs(RegExp pattern) => _failAfterPs = pattern;

  /// [writeRemoteFile] to a path matching [pattern] throws.
  void failWrite(RegExp pattern) => _failWrite = pattern;

  /// Commands matching [pattern] are recorded but never answer.
  void hang(RegExp pattern) => _hang = pattern;

  /// PowerShell commands whose decoded script matches [pattern] are recorded
  /// but never answer.
  void hangPs(RegExp pattern) => _hangPs = pattern;

  /// [writeRemoteFile] to a path matching [pattern] is recorded but never
  /// finishes.
  void hangWrite(RegExp pattern) => _hangWrite = pattern;

  bool _hangs(String command) {
    if (_hang?.hasMatch(command) ?? false) return true;
    final script = decodedPowerShell(command);
    return script != null && (_hangPs?.hasMatch(script) ?? false);
  }

  /// Whether the scripted connection loss has happened.
  bool get lost => _lost;

  void _checkConnection() {
    if (_lost) throw SSHStateError('Transport is closed');
  }

  CmdResult _answer(String command) {
    commands.add(command);
    final script = decodedPowerShell(command);
    final rule = _rules
        .where((r) => r.$3
            ? script != null && r.$1.hasMatch(script)
            : r.$1.hasMatch(command))
        .firstOrNull;
    final result = rule == null
        ? CmdResult(127, '', 'scripted ssh: no rule for "${script ?? command}"')
        : rule.$2(rule.$3 ? script! : command);
    if (_failAfter?.hasMatch(command) ?? false) _lost = true;
    if (script != null && (_failAfterPs?.hasMatch(script) ?? false)) _lost = true;
    return result;
  }

  @override
  Future<CmdResult> run(
    String command, {
    Duration timeout = const Duration(minutes: 3),
  }) async {
    _checkConnection();
    if (_hangs(command)) {
      commands.add(command);
      return Completer<CmdResult>().future; // never answers
    }
    return _answer(command);
  }

  @override
  Future<CmdResult> runChecked(
    String command, {
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final result = await run(command, timeout: timeout);
    if (!result.ok) {
      throw Exception(
        'Command failed (exit ${result.exitCode}): $command\n${result.combined}',
      );
    }
    return result;
  }

  @override
  Future<CmdResult> runWithStreamStdin(
    String command,
    Stream<List<int>> data, {
    void Function(int sentBytes)? onProgress,
    Converter<List<int>, List<int>>? encoder,
  }) async {
    _checkConnection();
    var sent = 0;
    await for (final chunk in data) {
      sent += chunk.length;
    }
    onProgress?.call(sent);
    return _answer(command);
  }

  @override
  Future<CmdResult> runWithFileStdin(
    String command,
    File file, {
    void Function(int sentBytes)? onProgress,
  }) => runWithStreamStdin(command, file.openRead(), onProgress: onProgress);

  @override
  Future<void> writeRemoteFile(String path, String content) async {
    _checkConnection();
    commands.add('write $path');
    if (_hangWrite?.hasMatch(path) ?? false) {
      return Completer<void>().future; // never finishes
    }
    if (_failWrite?.hasMatch(path) ?? false) {
      throw Exception('Failed to write remote file $path');
    }
    writes[path] = content;
    if (_failAfter?.hasMatch('write $path') ?? false) _lost = true;
  }

  @override
  Future<void> downloadFile(String remotePath, String localPath) async {
    _checkConnection();
    commands.add('download $remotePath');
    final content = remoteFiles[remotePath];
    if (content == null) throw Exception('No such file: $remotePath');
    await File(localPath).writeAsString(content, flush: true);
  }

  @override
  Future<SSHSocket> forwardLocal(String host, int port) async {
    _checkConnection();
    commands.add('forward $host:$port');
    final forward = onForward;
    if (forward == null) {
      throw Exception('scripted ssh: no forward to $host:$port');
    }
    return forward(host, port);
  }

  @override
  void close() => closed = true;
}
