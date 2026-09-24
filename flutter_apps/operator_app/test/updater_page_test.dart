import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/updater_page.dart';
import 'package:operator_app/ui/ui.dart';
/// The page as the shell hosts it (a Scaffold body), for layout assertions.
Widget _app() => const MaterialApp(home: Scaffold(body: UpdaterPage()));

void main() {
  // Any layout assertion (unbounded viewport, RenderFlex overflow) fails the
  // pump, so building the page at a size IS the layout check for that size.
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    expect(find.text('Update server'), findsOneWidget);
  }

  // skipOffstage: in the short window the log starts below the fold.
  Rect logCard(WidgetTester tester) => tester.getRect(
      find.widgetWithText(SectionCard, 'LOG', skipOffstage: false));

  testWidgets('updater page builds', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('Update server'), findsOneWidget);
  });

  testWidgets('the log fills the default window down to the page padding',
      (tester) async {
    await pumpAt(tester, const Size(1280, 720));
    expect(logCard(tester).bottom, 720 - 14);
  });

  testWidgets('a short window scrolls; the log keeps a usable height',
      (tester) async {
    await pumpAt(tester, const Size(700, 480));
    expect(logCard(tester).height, 180);
  });

  group('password eye-toggle', () {
    // The password field on a kiosk board is worth revealing to catch a typo,
    // but must default to hidden. The toggle flips obscureText and swaps its
    // icon/tooltip.
    // The password field is the only TextField carrying an IconButton (its eye
    // suffix), so this finds it in either toggle state — unlike the tooltip,
    // whose text flips on tap.
    TextField passwordField(WidgetTester tester) => tester.widget<TextField>(
        find.ancestor(
            of: find.byType(IconButton), matching: find.byType(TextField)));

    testWidgets('password is obscured by default', (tester) async {
      await tester.pumpWidget(_app());
      expect(passwordField(tester).obscureText, isTrue);
      expect(find.byTooltip('Show password'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('tapping the eye reveals the password, and hides it again',
        (tester) async {
      await tester.pumpWidget(_app());

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(passwordField(tester).obscureText, isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(passwordField(tester).obscureText, isTrue);
      expect(find.byTooltip('Show password'), findsOneWidget);
    });
  });

  group('connection strip', () {
    // The actions arm only on a VERIFIED connection. With nothing to check
    // the strip is idle, no probe runs (no timer, no SSH) and nothing is
    // clickable — the old "fields filled in = armed" behaviour is gone.
    testWidgets('empty credentials: strip idle, actions disarmed',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(); // the post-frame probe is a no-op here
      expect(find.text('Enter a kiosk, user and password'), findsOneWidget);
      expect(find.byTooltip('Check again'), findsNothing);
      expect(
          tester
              .widget<GoButton>(find.widgetWithText(GoButton, 'Update server'))
              .onPressed,
          isNull);
      expect(
          tester
              .widget<QuietButton>(
                  find.widgetWithText(QuietButton, 'Get server info'))
              .onPressed,
          isNull);
    });
  });

  group('batch update control', () {
    // Batch picks its fleet in the picker and verifies each board in the
    // pre-flight, so unlike the single-host actions it needs neither a
    // verified connection NOR an image up front: choosing which kiosks needs
    // no image, and the image is asked for once they are picked.
    testWidgets('batch is enabled with no connection and no image',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      final button = tester.widget<QuietButton>(find.widgetWithText(
          QuietButton, 'Update several kiosks at once…'));
      expect(button.onPressed, isNotNull);
      // The single-host actions, by contrast, stay disarmed.
      expect(
          tester
              .widget<GoButton>(find.widgetWithText(GoButton, 'Update server'))
              .onPressed,
          isNull);
      expect(find.text('Pick the kiosks first — the image is chosen after.'),
          findsOneWidget);
    });

    testWidgets('the concurrency choice defaults to 2 at a time',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(
          tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
              .value,
          2);
    });
  });
}
