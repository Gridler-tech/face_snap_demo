// Developer-mode popups: every </> badge on a page has a topic, and every
// topic's popup lays out (summary, every snippet tab) without an overflow at a
// small desktop window size.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/ui/dev_info.dart';

void main() {
  test('every DevInfoBadge on a page names a topic', () {
    final badge = RegExp(r"DevInfoBadge\('([^']+)'\)");
    final used = <String>{
      for (final file in Directory('lib/pages').listSync().whereType<File>())
        for (final m in badge.allMatches(file.readAsStringSync())) m.group(1)!,
    };
    expect(used, isNotEmpty);
    expect(
      used.difference(devTopicIds.toSet()),
      isEmpty,
      reason: 'badges without a topic render nothing',
    );
  });

  testWidgets('every topic popup renders all its tabs without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DevMode.enabled.value = true;
    addTearDown(() => DevMode.enabled.value = false);

    for (final id in devTopicIds) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: DevInfoBadge(id))),
        ),
      );
      await tester.tap(find.byType(DevInfoBadge));
      await tester.pumpAndSettle();
      expect(find.textContaining('Implementing: '), findsOneWidget, reason: id);
      expect(tester.takeException(), isNull, reason: '$id: first tab');

      // Every snippet tab: the labels are the only texts with these prefixes.
      final tabs = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            RegExp(r'^(C#|Dart|Shell|Protocol|Stream)').hasMatch(w.data ?? ''),
      );
      final count = tabs.evaluate().length;
      expect(count, greaterThanOrEqualTo(2), reason: id);
      for (var i = 0; i < count; i++) {
        await tester.tap(tabs.at(i));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$id: tab $i');
      }

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }
  });
}
