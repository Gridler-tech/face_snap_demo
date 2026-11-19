// bin/port_cli.dart (runPortCli): usage errors exit 2, a successful change
// exits 0 and prints the notice, a refusal exits 1, and the password is never
// printed.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/engine.dart';
import 'package:operator_app/updater/port_cli.dart';
import 'package:operator_app/updater/port_engine.dart';

const _password = 'S3cret-pa55';

/// A PortEngine whose run() only plays a script: no SSH.
class _FakeEngine extends PortEngine {
  _FakeEngine({
    required super.host,
    required super.user,
    required super.password,
    required super.newPort,
    required super.onLog,
    required this.ok,
  }) : super(onChanged: () {});

  final bool ok;

  @override
  Future<bool> run() async {
    log('Connecting to $user@$host …');
    for (final s in steps) {
      setStep(s, ok ? StepStatus.ok : StepStatus.skipped);
    }
    if (ok) {
      resultPort = newPort;
      notice = 'New address: $host:$newPort\n'
          'If this machine runs a firewall, open port $newPort.';
      summary.add('$host now uses port $newPort (was 50051).');
    } else {
      setStep(steps[1], StepStatus.fail, 'nothing to change');
      resultPort = 50051;
      summary.add('Port not changed, $host stays on port 50051: '
          'nothing to change: $host already uses port 50051.');
    }
    return ok;
  }
}

class _Run {
  final out = StringBuffer();
  final err = StringBuffer();
  final engines = <_FakeEngine>[];

  Future<int> call(List<String> args, {bool ok = true}) => runPortCli(
        args,
        engine: ({required host, required user, required password, required newPort, required onLog}) {
          final e = _FakeEngine(
              host: host, user: user, password: password, newPort: newPort, onLog: onLog, ok: ok);
          engines.add(e);
          return e;
        },
        out: out,
        err: err,
      );

  String get all => '$out$err';
}

void main() {
  group('usage errors exit 2', () {
    test('three arguments: usage line, no engine', () async {
      final run = _Run();
      expect(await run(['10.0.0.5', 'root', _password]), 2);
      expect(run.err.toString(), contains('usage: port_cli <host> <user> <password> <port>'));
      expect(run.engines, isEmpty);
      expect(run.all, isNot(contains(_password)));
    });

    test('five arguments: usage line, no engine', () async {
      final run = _Run();
      expect(await run(['10.0.0.5', 'root', _password, '50052', 'extra']), 2);
      expect(run.err.toString(), contains('usage: port_cli'));
      expect(run.engines, isEmpty);
      expect(run.all, isNot(contains(_password)));
    });

    test('P9: password and port swapped: exit 2, the password is not echoed', () async {
      final run = _Run();
      expect(await run(['10.0.0.5', 'root', '50052', _password]), 2);
      expect(run.err.toString(), contains('the port (the fourth argument) must be a whole number'));
      expect(run.err.toString(), contains('usage: port_cli'));
      expect(run.engines, isEmpty);
      expect(run.all, isNot(contains(_password)));
    });

    test('a port that is not a whole number', () async {
      for (final bad in ['abc', '50052x', '5005.2', '']) {
        final run = _Run();
        expect(await run(['10.0.0.5', 'root', _password, bad]), 2, reason: bad);
        expect(run.err.toString(), contains('must be a whole number'), reason: bad);
        expect(run.engines, isEmpty, reason: bad);
        expect(run.all, isNot(contains(_password)), reason: bad);
      }
    });
  });

  test('success: exit 0, the engine gets the arguments, log + summary + notice printed',
      () async {
    final run = _Run();
    expect(await run(['10.0.0.5', 'root', _password, '50052']), 0);
    final e = run.engines.single;
    expect((e.host, e.user, e.password, e.newPort), ('10.0.0.5', 'root', _password, 50052));
    final out = run.out.toString();
    expect(out, contains('Connecting to root@10.0.0.5 …'));
    expect(out, contains('--- steps ---'));
    expect(out, contains('--- summary ---'));
    expect(out, contains('10.0.0.5 now uses port 50052 (was 50051).'));
    expect(out, contains('New address: 10.0.0.5:50052'));
    expect(out, contains('If this machine runs a firewall, open port 50052.'));
    // The notice comes last, after the summary.
    expect(out.indexOf('New address'), greaterThan(out.indexOf('--- summary ---')));
    expect(run.all, isNot(contains(_password)));
  });

  test('refusal: exit 1, the reason printed, no notice', () async {
    final run = _Run();
    expect(await run(['10.0.0.5', 'root', _password, '50051'], ok: false), 1);
    final out = run.out.toString();
    expect(out, contains('Port not changed, 10.0.0.5 stays on port 50051'));
    expect(out, isNot(contains('New address')));
    expect(run.all, isNot(contains(_password)));
  });

  test('the real engine refuses an out-of-range port before connecting: exit 1', () async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runPortCli(['10.0.0.5', 'root', _password, '80'], out: out, err: err);
    expect(code, 1);
    expect('$out', contains('Port not changed: port 80 is outside 1024–65535.'));
    expect('$out$err', isNot(contains(_password)));
  });
}
