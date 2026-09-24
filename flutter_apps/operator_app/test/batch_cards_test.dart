// The per-board card is the whole batch view at a glance, so each phase must
// read unambiguously and a board's own step list must be reachable without
// leaving the screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/batch_runner.dart';
import 'package:operator_app/updater/engine.dart';
import 'package:operator_app/updater/ui/batch_cards.dart';

Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))));

List<UpdateStep> steps() => [
      UpdateStep('Connect to the kiosk')..status = StepStatus.ok,
      UpdateStep('Install the new server image')..status = StepStatus.running,
      UpdateStep('Verify the new server'),
    ];

void main() {
  group('BatchBoardCard', () {
    testWidgets('a waiting board shows its name and phase', (tester) async {
      await pump(
          tester,
          const BatchBoardCard(
              title: 'facesnap-a.local',
              phase: BatchPhase.waiting,
              detail: 'queued'));
      expect(find.text('facesnap-a.local'), findsOneWidget);
      expect(find.text('Waiting'), findsOneWidget);
    });

    testWidgets('a running board shows a spinner and its current step',
        (tester) async {
      await pump(
          tester,
          const BatchBoardCard(
              title: 'facesnap-a.local',
              phase: BatchPhase.running,
              detail: 'Install the new server image'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Install the new server image'), findsOneWidget);
    });

    testWidgets('a finished board shows Done and its elapsed time',
        (tester) async {
      await pump(
          tester,
          const BatchBoardCard(
              title: 'facesnap-a.local',
              phase: BatchPhase.succeeded,
              detail: 'updated',
              elapsed: Duration(minutes: 6, seconds: 8)));
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('6 min 8 s'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failed board is marked Failed', (tester) async {
      await pump(
          tester,
          const BatchBoardCard(
              title: 'bad.local',
              phase: BatchPhase.failed,
              detail: 'docker load failed'));
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('docker load failed'), findsOneWidget);
    });

    testWidgets('a skipped board says why and offers no step list',
        (tester) async {
      await pump(
          tester,
          const BatchBoardCard(
              title: 'gone.local',
              phase: BatchPhase.skipped,
              detail: 'not reachable (name not found)'));
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('steps stay hidden until the card is expanded', (tester) async {
      var toggled = false;
      await pump(
          tester,
          BatchBoardCard(
            title: 'facesnap-a.local',
            phase: BatchPhase.running,
            detail: 'Install the new server image',
            steps: steps(),
            onToggle: () => toggled = true,
          ));
      // Collapsed: the running step shows as the detail line only, and the
      // other steps of the pipeline are not rendered.
      expect(find.text('Connect to the kiosk'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      await tester.tap(find.byIcon(Icons.expand_more));
      expect(toggled, isTrue);
    });

    testWidgets('an expanded card lists that board own pipeline',
        (tester) async {
      await pump(
          tester,
          BatchBoardCard(
            title: 'facesnap-a.local',
            phase: BatchPhase.running,
            detail: 'Install the new server image',
            steps: steps(),
            expanded: true,
            onToggle: () {},
          ));
      expect(find.text('Connect to the kiosk'), findsOneWidget);
      expect(find.text('Verify the new server'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });
  });

  group('phase look-up', () {
    test('every phase has a distinct label', () {
      final labels = BatchPhase.values.map(batchPhaseLabel).toSet();
      expect(labels, hasLength(BatchPhase.values.length));
    });

    test('succeeded is green, failed is red', () {
      expect(batchPhaseLook(BatchPhase.succeeded).color,
          isNot(batchPhaseLook(BatchPhase.failed).color));
    });
  });
}
