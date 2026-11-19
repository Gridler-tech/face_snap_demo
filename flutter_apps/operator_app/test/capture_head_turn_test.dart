// The head turn on the Capture page (spec 2026-10-08 section 5.2): while the
// server's head turn runs, a strip shows the arrow, the text and the progress;
// the instruction's status line is not added as a result row; after DONE the
// strip goes and the head-turn result row joins the live person check block.
// Against an in-process fake Kiosk server.
import 'dart:async';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, ServiceCall;
import 'package:operator_app/pages/capture_page.dart';
import 'package:operator_app/services/settings_state.dart';
import 'package:operator_app/ui/head_turn_strip.dart';

import 'fake_server.dart';

const _failed = 'Live person check (head turn): failed - no head turn to the right';

// Set by the page once the stream has ENDED: waiting for it lets the call close
// before the teardown shuts the channel and the server down.
const _ended = 'The capture ended without a photo.';

const _depth = 'Live person check: passed (3D face confirmed by 4 cameras, depth 0.18)';
const _colour = 'Live person check (colour): passed (skin follows the light 3.66, min 2.00)';

class _FakeKiosk extends KioskServiceBase {
  _FakeKiosk({this.before = const [], this.after = const [], this.headTurn = true});

  /// Status rows before / after the head turn's own lines.
  final List<String> before;
  final List<String> after;

  /// False: an older server, with no head turn lines or Instruction items.
  final bool headTurn;
  final release = Completer<void>();

  ProcessAutomaticResponse _status(String text) => ProcessAutomaticResponse(
      processStatus: ProcessStepStatus(index: 4, description: text, status: StatusType.OK));

  @override
  Stream<ProcessAutomaticResponse> startAutomaticProcess(
      ServiceCall call, Empty request) async* {
    for (final line in before) {
      yield _status(line);
    }
    yield _status('Taking a high res photo using camera 4');
    if (headTurn) {
      yield _status('Turn your head to the left');
      yield ProcessAutomaticResponse(
          instruction: Instruction(
              index: 4,
              kind: InstructionKind.TURN_LEFT,
              progress: 0.5,
              secondsLeft: 3.5,
              text: 'Turn your head to the left'));
      await release.future;
      yield ProcessAutomaticResponse(
          instruction: Instruction(index: 4, kind: InstructionKind.DONE));
    }
    yield _status('Distance in cm: 55');
    if (headTurn) yield _status(_failed);
    for (final line in after) {
      yield _status(line);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}

Future<void> _pump(WidgetTester tester, bool Function() until) async {
  for (var i = 0; i < 30 && !until(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

/// Serves [kiosk], shows the Capture page and starts an automatic capture.
Future<void> _startCapture(WidgetTester tester, _FakeKiosk kiosk) async {
  tester.view.physicalSize = const Size(1900, 1100);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final server = await serveFakes([kiosk]);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  addTearDown(() => tester.runAsync(() => GrpcChannelProvider.channel.shutdown()));
  // Runs first: a failed expectation before the release must not leave the
  // fake's stream waiting, or the shutdowns above never finish.
  addTearDown(() {
    if (!kiosk.release.isCompleted) kiosk.release.complete();
  });
  SettingsState.current = LoadSettingsResponse();
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CapturePage())));
  await tester.pump();
  await tester.tap(find.text('Automatic'));
}

double _top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

void main() {
  testWidgets('the strip shows the head turn while it runs, then the result row',
      (tester) async {
    await tester.runAsync(() async {
      final kiosk = _FakeKiosk();
      await _startCapture(tester, kiosk);

      await _pump(tester, () => find.byType(HeadTurnStrip).evaluate().isNotEmpty);
      expect(find.byType(HeadTurnStrip), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(
          tester.widget<LinearProgressIndicator>(find.descendant(
              of: find.byType(HeadTurnStrip),
              matching: find.byType(LinearProgressIndicator))).value,
          closeTo(0.5, 1e-6));
      // the text once: in the strip, not also as a result row
      expect(find.text('Turn your head to the left'), findsOneWidget);

      kiosk.release.complete();
      await _pump(tester, () => find.text(_ended).evaluate().isNotEmpty);
      expect(find.byType(HeadTurnStrip), findsNothing);
      expect(find.text(_failed), findsOneWidget);
    });
  });

  testWidgets('the head-turn row joins the live person check block', (tester) async {
    await tester.runAsync(() async {
      final kiosk = _FakeKiosk(before: [_depth], after: [_colour])..release.complete();
      await _startCapture(tester, kiosk);
      await _pump(tester, () => find.text(_ended).evaluate().isNotEmpty);
      // depth, head turn, colour: consecutive, in the order they arrived; the
      // amber head turn lifts the block above the distance row
      final depth = _top(tester, _depth);
      final headTurn = _top(tester, _failed);
      final colour = _top(tester, _colour);
      expect(headTurn, greaterThan(depth));
      expect(colour, greaterThan(headTurn));
      expect(colour, lessThan(_top(tester, 'Distance in cm: 55')));
    });
  });

  testWidgets('an older server: no head turn card, the capture runs as before',
      (tester) async {
    await tester.runAsync(() async {
      await _startCapture(tester, _FakeKiosk(headTurn: false));
      await _pump(tester, () => find.text(_ended).evaluate().isNotEmpty);
      expect(find.text('Distance in cm: 55'), findsOneWidget);
      expect(find.text('Head turn'), findsNothing);
      expect(find.byType(HeadTurnStrip), findsNothing);
    });
  });

  group('HeadTurnStrip', () {
    Future<void> show(WidgetTester tester, CaptureInstruction instruction) =>
        tester.pumpWidget(MaterialApp(
            home: Scaffold(body: HeadTurnStrip(instruction: instruction))));

    testWidgets('seconds left counts down locally until the next instruction',
        (tester) async {
      // seconds_left is a snapshot at send time, and a new instruction comes
      // only on a change: a person who does not move gets no new item.
      await show(tester, CaptureInstruction(
          InstructionKind.TURN_LEFT, 0.2, false, 3.5, 'Turn your head to the left'));
      expect(find.text('3.5 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2.5 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('0.0 s'), findsOneWidget); // never below zero

      // a new instruction starts from its own snapshot
      await show(tester, CaptureInstruction(InstructionKind.TURN_LEFT, 0.3, true,
          4.0, 'Once more: turn your head to the left'));
      expect(find.text('4.0 s'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('3.5 s'), findsOneWidget);
    });

    testWidgets('right is the person\'s right; looking straight has no progress',
        (tester) async {
      await show(tester, CaptureInstruction(
          InstructionKind.TURN_RIGHT, 0.4, false, 2.0, 'Turn your head to the right'));
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await show(tester, CaptureInstruction(
          InstructionKind.LOOK_STRAIGHT, 0, false, 4.0, 'Look straight ahead'));
      expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  test('only the head turn\'s own lines count as instructions', () {
    expect(isHeadTurnInstruction('Once more: turn your head to the right'), isTrue);
    expect(isHeadTurnInstruction('Look straight ahead'), isTrue);
    expect(isHeadTurnInstruction('Live person check (head turn): passed'), isFalse);
    expect(isHeadTurnInstruction('Head pose frontal: True'), isFalse);
  });
}
