// Running one action across several kiosks.
//
// The per-host pipelines already are self-contained — each KioskEngine owns its
// SSH session, steps, summary and log, and runGuarded turns any failure into a
// false return instead of an exception. So a batch is N engines plus this
// orchestrator: pick the fleet, check every board BEFORE touching any of them,
// then run them with a concurrency cap and collect one report.
//
// Deliberately free of SSH and Flutter: the scheduling, the failure isolation
// and the pre-flight exclusion are all unit-tested without a board.
import 'dart:async';

/// One kiosk in a batch: where it is and who to log in as. The credentials
/// default to the batch-wide ones but can be overridden per board — a mixed
/// fleet is normal (a provisioned kiosk uses the fleet password, a clean
/// Odroid "odroid", a clean Radxa its own vendor default).
class BatchTarget {
  const BatchTarget({
    required this.host,
    required this.user,
    required this.password,
    this.label,
  });

  final String host;
  final String user;
  final String password;

  /// Display name when it differs from [host] (e.g. the mDNS name for an IP).
  final String? label;

  String get title => label ?? host;
}

/// How a board fared in the pre-flight sweep.
enum PreflightVerdict { ok, unreachable, authFailed, wrongArch, error }

class PreflightResult {
  const PreflightResult(this.target, this.verdict,
      {this.detail = '', this.installedVersion});

  final BatchTarget target;
  final PreflightVerdict verdict;

  /// Operator-readable reason, shown in the pre-flight table.
  final String detail;

  /// What is installed now, for the "what will change" column.
  final String? installedVersion;

  bool get ok => verdict == PreflightVerdict.ok;
}

/// Outcome of one board's pipeline.
class BatchOutcome {
  BatchOutcome(this.target, this.succeeded, this.elapsed, this.summary);

  final BatchTarget target;
  final bool succeeded;
  final Duration elapsed;

  /// The engine's own summary lines.
  final List<String> summary;
}

/// Lifecycle of one board inside a running batch (drives the per-board cards).
enum BatchPhase { waiting, running, succeeded, failed, skipped }

class BatchProgress {
  BatchProgress(this.target);

  final BatchTarget target;
  BatchPhase phase = BatchPhase.waiting;

  /// Title of the step the board is on, for the collapsed card.
  String step = '';
  Duration elapsed = Duration.zero;
}

/// Runs [action] over [targets], at most [concurrency] at a time. A board's
/// failure never stops the others — [action] is expected to resolve false
/// rather than throw (runGuarded already guarantees that), but a throw is
/// caught here too so one broken engine cannot abort the batch.
///
/// Results come back in the order of [targets], not the order they finished,
/// so the report reads like the fleet list.
Future<List<BatchOutcome>> runBatch({
  required List<BatchTarget> targets,
  required Future<bool> Function(BatchTarget target) action,
  int concurrency = 2,
  void Function(BatchTarget target)? onStart,
  void Function(BatchOutcome outcome)? onDone,
}) async {
  if (targets.isEmpty) return const [];
  final slots = concurrency < 1 ? 1 : concurrency;
  final outcomes = List<BatchOutcome?>.filled(targets.length, null);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= targets.length) return;
      final target = targets[index];
      onStart?.call(target);
      final clock = Stopwatch()..start();
      var ok = false;
      var summary = <String>[];
      try {
        ok = await action(target);
      } catch (e) {
        // A pipeline should not throw, but one that does must not take the
        // rest of the fleet down with it.
        summary = ['${target.title} failed: $e'];
      }
      clock.stop();
      final outcome = BatchOutcome(target, ok, clock.elapsed, summary);
      outcomes[index] = outcome;
      onDone?.call(outcome);
    }
  }

  await Future.wait([for (var i = 0; i < slots; i++) worker()]);
  return [for (final o in outcomes) o!];
}

/// Pre-flight every board BEFORE any of them is touched, at most
/// [concurrency] at a time. Unreachable or wrong-password boards are reported,
/// not thrown — the caller excludes them and runs the rest, so one typo can
/// never leave a batch half-applied.
Future<List<PreflightResult>> runPreflight({
  required List<BatchTarget> targets,
  required Future<PreflightResult> Function(BatchTarget target) check,
  int concurrency = 4,
  void Function(PreflightResult result)? onResult,
}) async {
  if (targets.isEmpty) return const [];
  final slots = concurrency < 1 ? 1 : concurrency;
  final results = List<PreflightResult?>.filled(targets.length, null);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= targets.length) return;
      final target = targets[index];
      PreflightResult result;
      try {
        result = await check(target);
      } catch (e) {
        result = PreflightResult(target, PreflightVerdict.error, detail: '$e');
      }
      results[index] = result;
      onResult?.call(result);
    }
  }

  await Future.wait([for (var i = 0; i < slots; i++) worker()]);
  return [for (final r in results) r!];
}

/// One line per board plus a headline, for the end-of-batch report.
List<String> batchReport(String action, List<BatchOutcome> outcomes,
    {List<PreflightResult> skipped = const []}) {
  final done = outcomes.length;
  final ok = outcomes.where((o) => o.succeeded).length;
  final lines = <String>[
    '$action: $ok of $done succeeded'
        '${skipped.isEmpty ? '' : ', ${skipped.length} skipped'}.',
  ];
  for (final o in outcomes) {
    lines.add('  ${o.succeeded ? 'OK  ' : 'FAIL'}  ${o.target.title}  '
        '(${_short(o.elapsed)})');
  }
  for (final s in skipped) {
    lines.add('  SKIP  ${s.target.title}  '
        '(${s.detail.isEmpty ? s.verdict.name : s.detail})');
  }
  return lines;
}

String _short(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return m > 0 ? '$m min $s s' : '$s s';
}
