// The batch orchestrator's guarantees, driven with fake actions so the
// scheduling is tested without a board: never more than N boards at once,
// one board's failure never stops the fleet, results read in fleet order, and
// pre-flight reports bad boards instead of throwing.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/batch_runner.dart';

BatchTarget t(String host) =>
    BatchTarget(host: host, user: 'root', password: 'x');

List<BatchTarget> fleet(int n) =>
    [for (var i = 1; i <= n; i++) t('kiosk$i.local')];

void main() {
  group('runBatch scheduling', () {
    test('never runs more than the concurrency cap at once', () async {
      var live = 0, peak = 0;
      await runBatch(
        targets: fleet(6),
        concurrency: 2,
        action: (_) async {
          live++;
          peak = peak > live ? peak : live;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          live--;
          return true;
        },
      );
      expect(peak, 2);
    });

    test('concurrency 1 is a rolling update — strictly one at a time',
        () async {
      var live = 0, peak = 0;
      await runBatch(
        targets: fleet(4),
        concurrency: 1,
        action: (_) async {
          live++;
          peak = peak > live ? peak : live;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          live--;
          return true;
        },
      );
      expect(peak, 1);
    });

    test('a cap wider than the fleet just runs them all', () async {
      var live = 0, peak = 0;
      await runBatch(
        targets: fleet(3),
        concurrency: 10,
        action: (_) async {
          live++;
          peak = peak > live ? peak : live;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          live--;
          return true;
        },
      );
      expect(peak, 3);
    });

    test('a nonsensical cap is clamped to 1 rather than hanging', () async {
      final seen = <String>[];
      final out = await runBatch(
        targets: fleet(2),
        concurrency: 0,
        action: (target) async {
          seen.add(target.host);
          return true;
        },
      );
      expect(seen, hasLength(2));
      expect(out.every((o) => o.succeeded), isTrue);
    });

    test('every board runs exactly once', () async {
      final seen = <String>[];
      await runBatch(
        targets: fleet(5),
        concurrency: 2,
        action: (target) async {
          seen.add(target.host);
          return true;
        },
      );
      expect(seen, hasLength(5));
      expect(seen.toSet(), hasLength(5));
    });

    test('an empty fleet is a no-op', () async {
      final out = await runBatch(
          targets: const [], action: (_) async => true, concurrency: 2);
      expect(out, isEmpty);
    });
  });

  group('runBatch failure isolation', () {
    test('a failed board does not stop the others', () async {
      final out = await runBatch(
        targets: fleet(4),
        concurrency: 2,
        action: (target) async => target.host != 'kiosk2.local',
      );
      expect(out, hasLength(4));
      expect(out.where((o) => o.succeeded).length, 3);
      expect(out.firstWhere((o) => o.target.host == 'kiosk2.local').succeeded,
          isFalse);
    });

    test('a THROWN error is contained, and the rest still run', () async {
      final out = await runBatch(
        targets: fleet(3),
        concurrency: 2,
        action: (target) async {
          if (target.host == 'kiosk1.local') throw StateError('ssh exploded');
          return true;
        },
      );
      expect(out, hasLength(3));
      final bad = out.firstWhere((o) => o.target.host == 'kiosk1.local');
      expect(bad.succeeded, isFalse);
      expect(bad.summary.join(), contains('ssh exploded'));
      expect(out.where((o) => o.succeeded).length, 2);
    });
  });

  group('runBatch reporting', () {
    test('results come back in fleet order, not completion order', () async {
      // kiosk1 is slowest, so completion order is the reverse of fleet order.
      final out = await runBatch(
        targets: fleet(3),
        concurrency: 3,
        action: (target) async {
          final delay = {'kiosk1.local': 30, 'kiosk2.local': 20}[target.host] ?? 5;
          await Future<void>.delayed(Duration(milliseconds: delay));
          return true;
        },
      );
      expect(out.map((o) => o.target.host),
          ['kiosk1.local', 'kiosk2.local', 'kiosk3.local']);
    });

    test('callbacks fire once per board', () async {
      final started = <String>[], finished = <String>[];
      await runBatch(
        targets: fleet(4),
        concurrency: 2,
        action: (_) async => true,
        onStart: (target) => started.add(target.host),
        onDone: (outcome) => finished.add(outcome.target.host),
      );
      expect(started, hasLength(4));
      expect(finished, hasLength(4));
      expect(started.toSet(), finished.toSet());
    });

    test('elapsed time is measured per board', () async {
      final out = await runBatch(
        targets: fleet(1),
        action: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return true;
        },
      );
      expect(out.single.elapsed.inMilliseconds, greaterThanOrEqualTo(30));
    });

    test('batchReport counts successes, failures and skips', () async {
      final out = await runBatch(
        targets: fleet(3),
        concurrency: 3,
        action: (target) async => target.host != 'kiosk3.local',
      );
      final report = batchReport('Update', out, skipped: [
        PreflightResult(t('kiosk9.local'), PreflightVerdict.authFailed,
            detail: 'password rejected'),
      ]);
      expect(report.first, 'Update: 2 of 3 succeeded, 1 skipped.');
      expect(report.join('\n'), contains('FAIL  kiosk3.local'));
      expect(report.join('\n'), contains('SKIP  kiosk9.local'));
      expect(report.join('\n'), contains('password rejected'));
    });
  });

  group('runPreflight', () {
    test('reports bad boards instead of throwing', () async {
      final results = await runPreflight(
        targets: fleet(3),
        check: (target) async => switch (target.host) {
          'kiosk2.local' => PreflightResult(target, PreflightVerdict.authFailed,
              detail: 'password rejected'),
          _ => PreflightResult(target, PreflightVerdict.ok,
              installedVersion: '2.0.11'),
        },
      );
      expect(results, hasLength(3));
      expect(results.where((r) => r.ok).length, 2);
      final bad = results.firstWhere((r) => r.target.host == 'kiosk2.local');
      expect(bad.ok, isFalse);
      expect(bad.detail, 'password rejected');
    });

    test('a throwing check becomes an error verdict, not a crash', () async {
      final results = await runPreflight(
        targets: fleet(2),
        check: (target) async {
          if (target.host == 'kiosk1.local') throw StateError('boom');
          return PreflightResult(target, PreflightVerdict.ok);
        },
      );
      expect(results.firstWhere((r) => r.target.host == 'kiosk1.local').verdict,
          PreflightVerdict.error);
      expect(results.firstWhere((r) => r.target.host == 'kiosk2.local').ok,
          isTrue);
    });

    test('results are in fleet order and respect the cap', () async {
      var live = 0, peak = 0;
      final results = await runPreflight(
        targets: fleet(5),
        concurrency: 2,
        check: (target) async {
          live++;
          peak = peak > live ? peak : live;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          live--;
          return PreflightResult(target, PreflightVerdict.ok);
        },
      );
      expect(peak, 2);
      expect(results.map((r) => r.target.host).toList(),
          fleet(5).map((t) => t.host).toList());
    });
  });

  group('BatchTarget', () {
    test('title prefers the label over the raw host', () {
      expect(t('192.168.3.181').title, '192.168.3.181');
      expect(
          const BatchTarget(
                  host: '192.168.3.181',
                  user: 'root',
                  password: 'x',
                  label: 'facesnap-00485420970d.local')
              .title,
          'facesnap-00485420970d.local');
    });
  });
}
