// runGuarded's beforeClose hook is the engines' remote cleanup (removing a
// staging tgz over SSH). It has to be AWAITED before the SSH transport is
// closed and before the run reports back — a fire-and-forget call is still
// being set up when close() tears the connection down, and the staging file
// stays in /tmp on the kiosk. A hook that hangs or throws must not hang or
// fail the run itself.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/engine.dart';

class _Engine extends KioskEngine {
  _Engine(this.events)
      : super(
            host: 'kiosk.local',
            user: 'root',
            password: 'x',
            onChanged: () {},
            onLog: events.add);

  final List<String> events;

  @override
  final List<UpdateStep> steps = [UpdateStep('only step')];
}

void main() {
  test('beforeClose completes before runGuarded returns', () async {
    final events = <String>[];
    final engine = _Engine(events);
    final ok = await engine.runGuarded('Test', () async {
      events.add('body');
      return true;
    }, beforeClose: () async {
      events.add('cleanup started');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      events.add('cleanup done');
    });
    expect(ok, isTrue);
    expect(events, ['body', 'cleanup started', 'cleanup done']);
  });

  test('beforeClose also runs, awaited, when the body fails', () async {
    final events = <String>[];
    final engine = _Engine(events);
    final ok = await engine.runGuarded('Test', () async {
      engine.setStep(engine.steps.single, StepStatus.running);
      throw Exception('boom');
    }, beforeClose: () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      events.add('cleanup done');
    });
    expect(ok, isFalse);
    expect(engine.steps.single.status, StepStatus.fail);
    expect(events.last, 'cleanup done');
  });

  test('a throwing beforeClose does not fail the run', () async {
    final events = <String>[];
    final engine = _Engine(events);
    final ok = await engine.runGuarded('Test', () async => true,
        beforeClose: () async => throw Exception('ssh gone'));
    expect(ok, isTrue);
    expect(events.join('\n'), contains('ssh gone'));
  });
}
