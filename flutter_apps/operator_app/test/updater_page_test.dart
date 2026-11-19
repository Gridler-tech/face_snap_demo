import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/updater_page.dart';
import 'package:operator_app/services/app_config.dart';
import 'package:operator_app/ui/ui.dart';
import 'package:operator_app/updater/connection_probe.dart';
import 'package:operator_app/updater/port_engine.dart';

/// A pipeline that goes on logging after its run was let go (FL-2): it waits
/// for [gate], then calls back into the page as every engine does.
class _LateEngine extends PortEngine {
  _LateEngine(
    this.gate, {
    required super.host,
    required super.user,
    required super.password,
    required super.newPort,
    required super.onChanged,
    required super.onLog,
  });

  final Completer<void> gate;
  bool finished = false;

  @override
  Future<bool> run() async {
    await gate.future;
    onLog('still running on the kiosk');
    onChanged();
    finished = true;
    return true;
  }
}
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

  group('FL-2: a run outlives the page', () {
    late String savedUpdaterHost, savedUser, savedPassword;
    late Directory dir;
    setUp(() {
      savedUpdaterHost = AppConfig.updaterHost;
      savedUser = AppConfig.boardUser;
      savedPassword = AppConfig.boardPassword;
      dir = Directory.systemTemp.createTempSync('updater_page_test');
      AppConfig.appDataDirOverride = dir.path; // the run saves the fields
      AppConfig.updaterHost = '192.168.3.169';
      AppConfig.boardUser = 'root';
      AppConfig.boardPassword = 'pw';
    });
    tearDown(() {
      AppConfig.updaterHost = savedUpdaterHost;
      AppConfig.boardUser = savedUser;
      AppConfig.boardPassword = savedPassword;
      AppConfig.appDataDirOverride = null;
      UpdaterRun.busy.value = false;
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {
        // A background config save may still hold the folder: left in temp.
      }
    });

    testWidgets('the engine logs after the page left the tree: no exception, the run ends, '
        'busy goes back to false', (tester) async {
      tester.view.physicalSize = const Size(1400, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final gate = Completer<void>();
      late _LateEngine engine;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: UpdaterPage(
        probe: (host, user, password) async => ProbeResult(ProbeState.connected,
            host: host, user: user, model: 'Radxa Dragon Q6A', arch: 'aarch64',
            installedVersion: '2.0.28-arm64', serverRunning: true, currentPort: 50051),
        portEngine: ({
          required String host,
          required String user,
          required String password,
          required int newPort,
          required void Function() onChanged,
          required void Function(String) onLog,
        }) =>
            engine = _LateEngine(gate,
                host: host,
                user: user,
                password: password,
                newPort: newPort,
                onChanged: onChanged,
                onLog: onLog),
      ))));
      await tester.pump(); // the post-frame probe starts
      await tester.pump(); // and answers
      await tester.enterText(find.byKey(const ValueKey('port-new')), '50052');
      await tester.pump();
      await tester.tap(find.widgetWithText(QuietButton, 'Change port'));
      await tester.pumpAndSettle();
      await tester.tap(
          find.descendant(of: find.byType(AlertDialog), matching: find.text('Change port')));
      await tester.pump();
      expect(UpdaterRun.busy.value, isTrue, reason: 'the run keeps the page in the shell');

      await tester.pumpWidget(const SizedBox()); // the page is gone (before FL-2: dev mode off)
      gate.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(engine.finished, isTrue);
      expect(UpdaterRun.busy.value, isFalse);
    });
  });
}
