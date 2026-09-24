// The per-kiosk review of a settings profile: differing rows start ticked,
// rows the kiosk already has are greyed and cannot be ticked, Cancel returns
// null (no update), Update returns exactly the ticked row ids.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/updater_page.dart';
import 'package:operator_app/updater/settings_profile.dart';

const _kiosk2025 = '{"camera": {"width": 1280, "height": 720}, '
    '"kiosk": {"face_quality": {"eyes_check": true, "lips_check": true}}}';

Future<Object?> _open(WidgetTester tester,
    {required Future<void> Function() interact}) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final profile = SettingsProfile.recommended();
  Object? result = 'dialog still open';
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          result = await showDialog<Set<String>>(
            context: context,
            builder: (_) => ProfileReviewDialog(
              summaryText: 'Kiosk: test',
              profile: profile,
              rows: profile.diff(parseKioskSettings(_kiosk2025)),
            ),
          );
        },
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await interact();
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('shows before → after and greys what is already set',
      (tester) async {
    await _open(tester, interact: () async {
      expect(find.text('Camera resolution'), findsOneWidget);
      expect(find.text('1280×720  →  3840×2160'), findsOneWidget);
      expect(find.text('on (already set)'), findsNWidgets(2)); // eyes + lips
      expect(find.text('Untick what this kiosk should keep:'), findsOneWidget);

      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      // 1 resolution + 10 checks + background + jpeg + ofiq = 14 rows.
      expect(boxes, hasLength(14));
      expect(boxes.where((b) => b.onChanged == null), hasLength(2));
      expect(boxes.where((b) => b.value == true), hasLength(12));
    });
  });

  testWidgets('Update returns exactly the rows left ticked', (tester) async {
    final result = await _open(tester, interact: () async {
      // Untick the resolution: this kiosk keeps 1280×720.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Update'));
    });
    expect(result, isA<Set<String>>());
    final ticked = result! as Set<String>;
    expect(ticked, isNot(contains('camera.resolution')));
    expect(ticked, contains('kiosk.background_method'));
    expect(ticked, isNot(contains('kiosk.face_quality.eyes_check')));
    expect(ticked, hasLength(11));
  });

  testWidgets('Cancel returns null, so no update starts', (tester) async {
    final result = await _open(tester, interact: () async {
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    });
    expect(result, isNull);
  });
}
