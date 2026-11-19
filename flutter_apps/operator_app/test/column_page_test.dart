// The Column page (spec 2026-10-10 section 5.5): the column settings with Factory, Standard and
// Now, the ● on a changed one, "Save changes as standard" listing the changes before it saves,
// "Back to standard" / "Back to factory" per setting, the whole column back to factory, the
// factory column off without a factory set, the LED geometry editor; an older server hides
// the page (ColumnState.available). An in-process fake server over a real loopback connection.
import 'dart:convert';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/pages/column_page.dart';
import 'package:operator_app/services/column_state.dart';
import 'package:operator_app/services/settings_state.dart';

const _names = ['led_layout', 'led_geometry', 'led_colour', 'focus_light', 'expected_cameras',
                'calibration', 'glare_free_white_balance', 'focus_absolute', 'rotate_frames',
                'colour_correction', 'hub_upside_down', 'backlight_brightness'];

/// A server with a column: the red channel 200 in the standard, [now] in the settings files,
/// [factory] = a factory set (red 160). [saveError]: the server refuses the save with it.
class _FakeSettings extends SettingsServiceBase {
  _FakeSettings({this.now = 200, this.factory = true, this.oldServer = false, this.saveError});
  int now;
  bool factory;
  final bool oldServer;
  final GrpcError? saveError;
  int standard = 200;
  final saves = <List<String>>[];
  final discards = <List<String>>[];
  final restores = <List<String>>[];
  final gbls = <String>[];

  String _colour(int red) => jsonEncode({'red': red, 'green': 230, 'blue': 200});

  ColumnProfileResponse _profile() => ColumnProfileResponse(
        boardId: 'e6614c311b4a6f2a',
        boardConnected: true,
        revision: 3,
        adoptedFrom: 'KIOSK-A',
        hasFactory: factory,
        settings: [
          for (final name in _names)
            name == 'led_colour'
                ? ColumnSetting(
                    name: name,
                    factoryValue: factory ? _colour(160) : '',
                    standardValue: _colour(standard),
                    currentValue: _colour(now),
                    changed: now != standard)
                : ColumnSetting(
                    name: name,
                    factoryValue: factory ? (name == 'led_layout' ? '"strip"' : '0') : '',
                    standardValue: name == 'led_layout' ? '"strip"' : '0',
                    currentValue: name == 'led_layout' ? '"strip"' : '0'),
        ],
      );

  @override
  Future<ColumnProfileResponse> getColumnProfile(ServiceCall call, Empty request) async {
    if (oldServer) throw GrpcError.unimplemented('GetColumnProfile');
    return _profile();
  }

  @override
  Future<ColumnSaveResponse> saveColumnStandard(ServiceCall call, ColumnSettingsRequest request) async {
    saves.add(request.names);
    final refusal = saveError;
    if (refusal != null) throw refusal;
    standard = now;
    return ColumnSaveResponse(
        outcome: ColumnSaveOutcome.COLUMN_SAVE_OUTCOME_WRITTEN, names: ['led_colour'], profile: _profile());
  }

  @override
  Future<ColumnProfileResponse> discardColumnChanges(ServiceCall call, ColumnSettingsRequest request) async {
    discards.add(request.names);
    now = standard;
    return _profile();
  }

  @override
  Future<ColumnSaveResponse> restoreColumnFactory(ServiceCall call, ColumnSettingsRequest request) async {
    restores.add(request.names);
    now = standard = 160;
    return ColumnSaveResponse(outcome: ColumnSaveOutcome.COLUMN_SAVE_OUTCOME_WRITTEN, profile: _profile());
  }

  @override
  Future<BoardGblResponse> getBoardGbl(ServiceCall call, BoardGblLayoutRequest request) async =>
      BoardGblResponse(layout: request.layout, content: 'CENTERCAM1 = 86\n', message: '');

  @override
  Future<BoardGblResponse> setBoardGbl(ServiceCall call, BoardGblRequest request) async {
    gbls.add('${request.layout}:${request.content}');
    return BoardGblResponse(layout: request.layout, content: request.content, custom: true, message: 'stored');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

Future<_FakeSettings> _pump(WidgetTester tester, _FakeSettings settings) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final server = Server.create(services: [settings]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
  addTearDown(() => tester.runAsync(() => server.shutdown()));
  SettingsState.current = LoadSettingsResponse(ledLayout: 'strip');
  ColumnState.reset();
  await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
  await ColumnState.refresh();
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ColumnPage())));
  await _settle(tester);
  return settings;
}

/// A loopback port that was just closed: a call there fails at once.
Future<int> _closedPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  testWidgets('the table shows factory, standard and now, and marks the changed setting', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, _FakeSettings(now: 120));
      for (final label in columnSettingLabels.values) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('160 / 230 / 200'), findsOneWidget);  // factory
      expect(find.text('200 / 230 / 200'), findsOneWidget);  // standard
      expect(find.text('120 / 230 / 200'), findsOneWidget);  // now
      expect(find.byKey(const ValueKey('column-mark-led_colour')), findsOneWidget);
      expect(find.byKey(const ValueKey('column-mark-expected_cameras')), findsNothing);
      expect(find.textContaining('Column e6614c311b4a6f2a · LED board connected · standard revision 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('column-no-factory')), findsNothing);
    });
  });

  testWidgets('save lists the changes first and saves them after the confirmation', (tester) async {
    await tester.runAsync(() async {
      final settings = await _pump(tester, _FakeSettings(now: 120));
      await _tap(tester, find.byKey(const ValueKey('column-save')));
      expect(find.byKey(const ValueKey('save-change-led_colour')), findsOneWidget);
      expect(find.text('LED colour mix: 200 / 230 / 200 → 120 / 230 / 200'), findsOneWidget);
      expect(settings.saves, isEmpty, reason: 'nothing before the confirmation');
      await _tap(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('Save')));
      expect(settings.saves, [<String>[]], reason: 'every changed setting');
      expect(find.text('Saved on the column.'), findsOneWidget);
      expect(find.byKey(const ValueKey('column-mark-led_colour')), findsNothing);
    });
  });

  testWidgets('back to standard and back to factory work per setting', (tester) async {
    await tester.runAsync(() async {
      final settings = await _pump(tester, _FakeSettings(now: 120));
      await _tap(tester, find.byKey(const ValueKey('column-back-standard-led_colour')));
      expect(settings.discards, [['led_colour']]);
      await _tap(tester, find.byKey(const ValueKey('column-back-factory-led_colour')));
      expect(settings.restores, [['led_colour']]);
      expect(find.text('160 / 230 / 200'), findsNWidgets(3));
    });
  });

  testWidgets('the whole column goes back to factory after a confirmation', (tester) async {
    await tester.runAsync(() async {
      final settings = await _pump(tester, _FakeSettings());
      await _tap(tester, find.byKey(const ValueKey('column-factory-all')));
      await _tap(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('Back to factory')));
      expect(settings.restores, [<String>[]]);
    });
  });

  testWidgets('without a factory set the factory column and its buttons are off', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, _FakeSettings(now: 120, factory: false));
      expect(find.byKey(const ValueKey('column-no-factory')), findsOneWidget);
      final wholeColumn = tester.widget<OutlinedButton>(find.descendant(
          of: find.byKey(const ValueKey('column-factory-all')), matching: find.byType(OutlinedButton)));
      expect(wholeColumn.onPressed, isNull);
      expect(tester.widget<TextButton>(find.byKey(const ValueKey('column-back-factory-led_colour'))).onPressed, isNull);
      expect(tester.widget<TextButton>(find.byKey(const ValueKey('column-back-standard-led_colour'))).onPressed, isNotNull);
    });
  });

  testWidgets('the LED geometry editor sends the edited gbl.py for the column layout', (tester) async {
    await tester.runAsync(() async {
      final settings = await _pump(tester, _FakeSettings());
      await _tap(tester, find.byKey(const ValueKey('column-geometry-edit')));
      await tester.enterText(find.byKey(const ValueKey('column-geometry-text')), 'CENTERCAM1 = 90\n');
      await _tap(tester, find.text('Use this geometry'));
      expect(settings.gbls, ['strip:CENTERCAM1 = 90\n']);
    });
  });

  testWidgets('an older server has no column profile', (tester) async {
    await tester.runAsync(() async {
      final server = Server.create(services: [_FakeSettings(oldServer: true)]);
      await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => tester.runAsync(() => server.shutdown()));
      SettingsState.current = LoadSettingsResponse();
      ColumnState.reset();
      ColumnState.available = true;
      await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
      await ColumnState.refresh();
      expect(ColumnState.available, isFalse);
      expect(ColumnState.current, isNull);
    });
  });

  // A server switch: the previous server's profile does not stay when the new server
  // cannot be reached; the same server that stops answering keeps its last answer.
  testWidgets("a server switch drops the previous server's profile", (tester) async {
    await tester.runAsync(() async {
      final server = Server.create(services: [_FakeSettings()]);
      await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
      SettingsState.current = LoadSettingsResponse();
      ColumnState.reset();
      await GrpcChannelProvider.setAddress('127.0.0.1', server.port!);
      await ColumnState.refresh();
      expect(ColumnState.current?.boardId, 'e6614c311b4a6f2a');

      await server.shutdown(); // the same server, not answering
      await ColumnState.refresh();
      expect(ColumnState.current?.boardId, 'e6614c311b4a6f2a', reason: 'the last answer stays');
      expect(ColumnState.available, isTrue);

      await GrpcChannelProvider.setAddress('127.0.0.1', await _closedPort()); // another server
      final before = ColumnState.revision.value;
      await ColumnState.refresh();
      expect(ColumnState.current, isNull);
      expect(ColumnState.available, isFalse);
      expect(ColumnState.revision.value, greaterThan(before));
    });
  });

  // R14's marker: a value present in a settings file but invalid comes as {"invalid": text}.
  test('an invalid value in the settings file shows as such for every setting', () {
    final marker = jsonEncode({'invalid': '{"red":300,"green":230,"blue":200}'});
    for (final name in _names) {
      expect(columnValueText(name, marker), 'invalid in the settings file: {"red":300,"green":230,"blue":200}',
          reason: name);
    }
    expect(columnValueText('rotate_frames', jsonEncode({'invalid': '"yes"'})), 'invalid in the settings file: "yes"');
    expect(columnValueText('hub_upside_down', jsonEncode({'invalid': '1'})), 'invalid in the settings file: 1');
    expect(columnValueText('calibration', jsonEncode({'usb-1.2': 2})), '1 cameras', reason: 'a real map is not a marker');
  });

  test('the colour correction shows the shipped matrices or the lights measured here', () {
    expect(columnSettingLabels['colour_correction'], 'Photo colour correction (matrices)');
    expect(columnValueText('colour_correction', '{}'), 'shipped matrices');
    expect(
        columnValueText(
            'colour_correction',
            jsonEncode({
              'all': {'matrix': [1, 0, 0, 0, 1, 0, 0, 0, 1]},
              'glare_free': {'matrix': [1, 0, 0, 0, 1, 0, 0, 0, 1]},
            })),
        'measured here: all LEDs, glare-free');
  });

  testWidgets('the backlight brightness shows its label, not the raw name', (tester) async {
    await tester.runAsync(() async {
      await _pump(tester, _FakeSettings());
      expect(columnSettingLabels['backlight_brightness'], 'Backlight brightness');
      expect(find.text('Backlight brightness'), findsOneWidget);
      expect(find.text('backlight_brightness'), findsNothing);
    });
  });

  test('the backlight brightness shows bottom and top per light', () {
    expect(
        columnValueText(
            'backlight_brightness',
            jsonEncode({
              'standard': {'bottom': 100, 'top': 100},
              'glare_free': {'bottom': 80, 'top': 65},
            })),
        'standard: bottom 100 %, top 100 % · glare-free: bottom 80 %, top 65 %');
  });

  // The twelfth setting, after hub_upside_down (plasma-backlights spec 2026-10-15 section 4.1).
  test('the backlight brightness is the twelfth setting', () {
    expect(columnSettingLabels.length, 12);
    expect(columnSettingLabels.keys.elementAt(11), 'backlight_brightness');
  });

  // The eleventh setting (spec 2026-10-15 section 2): a profile without it has "—" in that layer.
  test('the hub switch has its label and its values', () {
    expect(columnSettingLabels.keys, _names, reason: "the profile's order");
    expect(columnSettingLabels['hub_upside_down'], 'USB hub mounted upside down');
    expect(columnValueText('hub_upside_down', 'true'), 'yes (camera order mirrored)');
    expect(columnValueText('hub_upside_down', 'false'), 'no');
    expect(columnValueText('hub_upside_down', ''), '—');
  });

  // The server's save refusals (column_profile.py: WRITE_FAILED is UNAVAILABLE, so the
  // generic "kiosk not reachable" text would hide it; BOARD_NOT_CONNECTED is FAILED_PRECONDITION).
  for (final (refusal, text) in [
    (GrpcError.unavailable("the column's LED board did not take the file"),
        "Not saved: the column's LED board did not take the file"),
    (GrpcError.failedPrecondition("the column's LED board is not connected"),
        "Not saved: the column's LED board is not connected"),
  ]) {
    testWidgets('a refused save shows the server\'s reason (${refusal.codeName})', (tester) async {
      await tester.runAsync(() async {
        final settings = await _pump(tester, _FakeSettings(now: 120, saveError: refusal));
        await _tap(tester, find.byKey(const ValueKey('column-save')));
        await _tap(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('Save')));
        expect(settings.saves, [<String>[]]);
        expect(find.text(text), findsOneWidget);
        expect(find.textContaining('not reachable'), findsNothing);
        expect(find.text('Saved on the column.'), findsNothing);
        expect(find.byKey(const ValueKey('column-mark-led_colour')), findsOneWidget, reason: 'still changed');
      });
    });
  }
}
