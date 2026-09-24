// The two dialogs of a batch run. The picker must not let an empty selection
// through and must return exactly what was ticked; the pre-flight table must
// show bad boards as skipped WITHOUT blocking the reachable ones — that is the
// rule that stops one typo leaving a batch half-applied.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/batch_runner.dart';
import 'package:operator_app/services/discovery.dart';
import 'package:operator_app/updater/fleet.dart';
import 'package:operator_app/updater/ui/fleet_dialogs.dart';

DiscoveredKiosk _k(String name, String ip) =>
    DiscoveredKiosk(hostName: name, ip: ip);

BatchTarget _t(String name) =>
    BatchTarget(host: name, user: 'root', password: 'x', label: name);

/// Pump [child] as a dialog and hand back whatever it pops.
Future<T?> showIn<T>(WidgetTester tester, Widget child) async {
  T? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async =>
            result = await showDialog<T>(context: context, builder: (_) => child),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('FleetPickerDialog', () {
    List<FleetEntry> entries() => [
          FleetEntry(kiosk: _k('facesnap-a.local', '10.0.0.1')),
          FleetEntry(kiosk: _k('facesnap-b.local', '10.0.0.2')),
          FleetEntry(
              kiosk: DiscoveredKiosk(
                  hostName: 'odroid',
                  ip: '10.0.0.3',
                  kind: BoardKind.clean)),
        ];

    testWidgets('lists every discovered board, none ticked', (tester) async {
      await showIn<List<FleetEntry>>(
          tester,
          FleetPickerDialog(
              entries: entries(), defaultUser: 'root', defaultPassword: 'p'));
      expect(find.text('facesnap-a.local'), findsOneWidget);
      expect(find.text('facesnap-b.local'), findsOneWidget);
      expect(find.text('odroid'), findsOneWidget);
      expect(find.text('0 of 3 selected'), findsOneWidget);
    });

    testWidgets('a clean board is flagged and shows its vendor default user',
        (tester) async {
      await showIn<List<FleetEntry>>(
          tester,
          FleetPickerDialog(
              entries: entries(), defaultUser: 'root', defaultPassword: 'p'));
      expect(find.textContaining('clean board'), findsOneWidget);
    });

    testWidgets('cannot continue with nothing selected', (tester) async {
      await showIn<List<FleetEntry>>(
          tester,
          FleetPickerDialog(
              entries: entries(), defaultUser: 'root', defaultPassword: 'p'));
      final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Select kiosks'));
      expect(button.onPressed, isNull);
    });

    testWidgets('ticking boards enables Continue and returns just those',
        (tester) async {
      List<FleetEntry>? picked;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async => picked =
                await showDialog<List<FleetEntry>>(
                    context: context,
                    builder: (_) => FleetPickerDialog(
                        entries: entries(),
                        defaultUser: 'root',
                        defaultPassword: 'p')),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(find.text('1 of 3 selected'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Continue with 2'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.map((e) => e.kiosk.hostName),
          ['facesnap-a.local', 'odroid']);
    });

    testWidgets('Select all / Clear all toggles the whole fleet',
        (tester) async {
      await showIn<List<FleetEntry>>(
          tester,
          FleetPickerDialog(
              entries: entries(), defaultUser: 'root', defaultPassword: 'p'));
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(find.text('3 of 3 selected'), findsOneWidget);
      await tester.tap(find.text('Clear all'));
      await tester.pump();
      expect(find.text('0 of 3 selected'), findsOneWidget);
    });

    testWidgets('cancel returns nothing', (tester) async {
      final picked = await showIn<List<FleetEntry>>(
          tester,
          FleetPickerDialog(
              entries: entries(), defaultUser: 'root', defaultPassword: 'p'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(picked, isNull);
    });
  });

  group('PreflightDialog', () {
    testWidgets('all good: offers to update them all', (tester) async {
      await showIn<bool>(
        tester,
        PreflightDialog(
          imageName: 'face_snap-2.0.11-arm64.tar',
          results: [
            PreflightResult(_t('a.local'), PreflightVerdict.ok,
                detail: 'ODROID-N2Plus, 2.0.10-arm64'),
            PreflightResult(_t('b.local'), PreflightVerdict.ok,
                detail: 'Radxa Dragon Q6A, 2.0.10-arm64'),
          ],
        ),
      );
      expect(find.text('Update 2 kiosks?'), findsOneWidget);
      expect(find.textContaining('face_snap-2.0.11-arm64.tar'), findsOneWidget);
      expect(find.text('Skipped — these are not touched'), findsNothing);
    });

    testWidgets('a bad board is shown as skipped but does NOT block the rest',
        (tester) async {
      await showIn<bool>(
        tester,
        PreflightDialog(
          imageName: 'img.tar',
          results: [
            PreflightResult(_t('a.local'), PreflightVerdict.ok, detail: 'ok'),
            PreflightResult(_t('bad.local'), PreflightVerdict.authFailed,
                detail: 'Password rejected for root'),
          ],
        ),
      );
      expect(find.text('Skipped — these are not touched'), findsOneWidget);
      expect(find.text('Password rejected for root'), findsOneWidget);
      // One good board remains, so the run is still offered — for that one only.
      final go = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Update 1 kiosk'));
      expect(go.onPressed, isNotNull);
    });

    testWidgets('no reachable board disables the run', (tester) async {
      await showIn<bool>(
        tester,
        PreflightDialog(
          imageName: 'img.tar',
          results: [
            PreflightResult(_t('bad.local'), PreflightVerdict.unreachable,
                detail: 'not reachable'),
          ],
        ),
      );
      final go = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'No kiosk reachable'));
      expect(go.onPressed, isNull);
    });

    testWidgets('rolling mode is spelled out', (tester) async {
      await showIn<bool>(
        tester,
        PreflightDialog(
          imageName: 'img.tar',
          concurrency: 1,
          results: [PreflightResult(_t('a.local'), PreflightVerdict.ok)],
        ),
      );
      expect(find.textContaining('One at a time (rolling)'), findsOneWidget);
    });

    testWidgets('confirming returns true', (tester) async {
      bool? go;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async => go = await showDialog<bool>(
                context: context,
                builder: (_) => PreflightDialog(
                    imageName: 'img.tar',
                    results: [
                      PreflightResult(_t('a.local'), PreflightVerdict.ok)
                    ])),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Update 1 kiosk'));
      await tester.pumpAndSettle();
      expect(go, isTrue);
    });
  });
}
