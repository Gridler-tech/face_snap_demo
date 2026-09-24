// Headless batch update: one image onto several kiosks (same engine as the
// GUI, orchestrated by batch_runner.dart).
//
//   dart run bin/batch_cli.dart <image.tar> <hosts-file> [options]
//
// <hosts-file> is one board per line:
//     host [user] [password]
// User and password fall back to --user/--password (user defaults to root;
// the password has no default and must be given),
// so a mixed fleet can override just the boards that differ. Blank lines and
// lines starting with # are ignored.
//
// Options:
//   --user <u>         default user           (default: root)
//   --password <p>     the boards' root password (required)
//   --concurrency <n>  boards at a time       (default: 2; 1 = rolling)
//   --profile <p>      "recommended" or a profile .json; applies every row
//                      that differs on each kiosk (headless semantics)
//   --dry-run          pre-flight only: check every board, change nothing
import 'dart:io';

import 'package:operator_app/updater/batch_runner.dart';
import 'package:operator_app/updater/cli_report.dart';
import 'package:operator_app/updater/connection_probe.dart';
import 'package:operator_app/updater/settings_profile.dart';
import 'package:operator_app/updater/update_engine.dart';

String _opt(List<String> args, String name, String fallback) {
  final i = args.indexOf('--$name');
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : fallback;
}

List<BatchTarget> _readHosts(String path, String user, String password) {
  final targets = <BatchTarget>[];
  for (final raw in requireFile(path).readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split(RegExp(r'\s+'));
    targets.add(BatchTarget(
      host: parts[0],
      user: parts.length > 1 ? parts[1] : user,
      password: parts.length > 2 ? parts[2] : password,
    ));
  }
  return targets;
}

Future<void> main(List<String> args) async {
  if (args.length < 2 || args.first.startsWith('--')) {
    stderr.writeln('usage: batch_cli <image.tar> <hosts-file> '
        '[--user u] [--password p] [--concurrency n] [--profile p] [--dry-run]');
    exit(2);
  }
  final tar = requireFile(args[0]);
  final user = _opt(args, 'user', 'root');
  // No built-in default: the fleet password is never shipped in source.
  final password = _opt(args, 'password', '');
  if (password.isEmpty) {
    stderr.writeln('batch_cli: --password is required (the boards\' root '
        'password; per-host overrides go in the hosts file as host user pw)');
    exit(2);
  }
  final concurrency = int.tryParse(_opt(args, 'concurrency', '2')) ?? 2;
  final dryRun = args.contains('--dry-run');

  SettingsProfile? profile;
  final profileArg = _opt(args, 'profile', '');
  if (profileArg.isNotEmpty) {
    try {
      profile = profileArg == 'recommended'
          ? SettingsProfile.recommended()
          : SettingsProfile.parse(requireFile(profileArg).readAsStringSync());
    } on FormatException catch (e) {
      stderr.writeln(e.message);
      exit(2);
    }
  }

  final targets = _readHosts(args[1], user, password);
  if (targets.isEmpty) {
    stderr.writeln('No hosts in ${args[1]}.');
    exit(2);
  }

  // ---- pre-flight: check EVERY board before touching any of them ----------
  stdout.writeln('Pre-flight on ${targets.length} board(s) …');
  final checks = await runPreflight(
    targets: targets,
    check: (target) async {
      final r = await probeKiosk(target.host, target.user, target.password);
      final verdict = switch (r.state) {
        ProbeState.connected => PreflightVerdict.ok,
        ProbeState.authFailed => PreflightVerdict.authFailed,
        ProbeState.wrongArch => PreflightVerdict.wrongArch,
        _ => PreflightVerdict.unreachable,
      };
      return PreflightResult(target, verdict,
          detail: verdict == PreflightVerdict.ok
              ? '${r.model}, ${r.installedVersion ?? "clean board"}'
              : probeHeadline(r),
          installedVersion: r.installedVersion);
    },
    onResult: (r) => stdout.writeln(
        '  ${r.ok ? 'OK  ' : 'SKIP'}  ${r.target.title.padRight(34)} ${r.detail}'),
  );

  final good = [for (final c in checks.where((c) => c.ok)) c.target];
  final skipped = checks.where((c) => !c.ok).toList();
  if (good.isEmpty) {
    stderr.writeln('\nNo reachable board — nothing to do.');
    exit(1);
  }
  if (dryRun) {
    stdout.writeln('\nDry run: ${good.length} board(s) would be updated, '
        '${skipped.length} skipped. Nothing was changed.');
    exit(skipped.isEmpty ? 0 : 1);
  }

  // ---- run ---------------------------------------------------------------
  stdout.writeln('\nUpdating ${good.length} board(s), $concurrency at a time '
      '(${skipped.length} skipped) …\n');
  final engines = <String, UpdateEngine>{};
  final outcomes = await runBatch(
    targets: good,
    concurrency: concurrency,
    onStart: (t) => stdout.writeln('[${t.title}] start'),
    onDone: (o) => stdout.writeln(
        '[${o.target.title}] ${o.succeeded ? 'DONE' : 'FAILED'}'),
    action: (target) async {
      final engine = UpdateEngine(
        host: target.host,
        user: target.user,
        password: target.password,
        tarFile: tar,
        onChanged: () {},
        // One interleaved log, prefixed so parallel boards stay readable.
        onLog: (line) => stdout.writeln('[${target.title}] $line'),
        profile: profile,
      );
      engines[target.host] = engine;
      return engine.run();
    },
  );

  // ---- report ------------------------------------------------------------
  stdout.writeln('\n--- batch report ---');
  batchReport('Update', outcomes, skipped: skipped).forEach(stdout.writeln);
  for (final o in outcomes) {
    stdout.writeln('\n--- ${o.target.title} ---');
    final engine = engines[o.target.host];
    for (final l in engine?.summary ?? const <String>[]) {
      stdout.writeln('  $l');
    }
    for (final l in o.summary) {
      stdout.writeln('  $l');
    }
  }
  exit(outcomes.every((o) => o.succeeded) && skipped.isEmpty ? 0 : 1);
}
