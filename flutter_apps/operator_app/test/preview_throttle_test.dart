// The live-preview throttle behind the Backlights card's sliders: at most one call per
// 100 ms while a value keeps changing, the newest value wins, and a release sends the
// released value (unless it was the last one sent) after every earlier call. Timers run on
// the widget tester's fake clock (pump(Duration)), never on real time.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/preview_throttle.dart';

void main() {
  testWidgets('the preview throttle sends at most one value per 100 ms and the latest wins', (tester) async {
    final sent = <int>[];
    final throttle = PreviewThrottle<int>((v) async => sent.add(v));

    throttle.add(5);
    await tester.pump();
    expect(sent, [5], reason: 'the first value goes at once');

    throttle.add(10);
    throttle.add(15);
    await tester.pump(const Duration(milliseconds: 99));
    expect(sent, [5], reason: 'nothing more inside the 100 ms');
    await tester.pump(const Duration(milliseconds: 1));
    expect(sent, [5, 15], reason: 'after 100 ms the newest value; 10 is skipped');

    await tester.pump(const Duration(milliseconds: 300));
    expect(sent, [5, 15], reason: 'nothing pending, nothing sent');

    throttle.add(20);
    await tester.pump();
    expect(sent, [5, 15, 20], reason: 'quiet for 100 ms: the next value goes at once');
    throttle.dispose(); // its 100 ms timer: no timer may outlive the test
  });

  testWidgets('a release sends the released value at once and drops the pending one', (tester) async {
    final sent = <int>[];
    final throttle = PreviewThrottle<int>((v) async => sent.add(v));

    throttle.add(5);
    throttle.add(10); // pending
    await throttle.flush(30);
    expect(sent, [5, 30]);
    await tester.pump(const Duration(milliseconds: 300));
    expect(sent, [5, 30], reason: 'the pending 10 never goes after the release');

    throttle.add(40);
    await tester.pump(const Duration(milliseconds: 150));
    await throttle.flush(40);
    expect(sent, [5, 30, 40], reason: 'the released value was the last sent: not again');

    await throttle.flush(null);
    expect(sent, [5, 30, 40], reason: 'flush(null) only waits');
    throttle.dispose();
  });

  testWidgets('calls go one after another, so the released value lands last', (tester) async {
    final sent = <int>[];
    final gates = <Completer<void>>[];
    final throttle = PreviewThrottle<int>((v) {
      final gate = Completer<void>();
      gates.add(gate);
      return gate.future.then((_) => sent.add(v));
    });

    throttle.add(5); // still running when the release comes
    await tester.pump();
    var released = false;
    unawaited(throttle.flush(50).then((_) => released = true));
    await tester.pump();
    expect(gates, hasLength(1), reason: 'the release waits for the call before it');
    gates[0].complete();
    await tester.pump();
    expect(gates, hasLength(2));
    gates[1].complete();
    await tester.pump();
    expect(sent, [5, 50]);
    expect(released, isTrue);
    throttle.dispose();
  });

  testWidgets('a failing call does not stop the next one', (tester) async {
    final sent = <int>[];
    final throttle = PreviewThrottle<int>((v) async {
      if (v == 5) throw StateError('board busy');
      sent.add(v);
    });
    throttle.add(5);
    await throttle.flush(25);
    expect(sent, [25]);
    throttle.dispose();
  });
}
