import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/app_config.dart';

/// The Updater page's board is not the app's connected server: before
/// 2026-10-08 updating a kiosk saved it as AppConfig.host, the Kiosk page then
/// showed that kiosk "Connected" while captures still went to the old server.
void main() {
  late String savedHost, savedUpdaterHost, savedUser, savedPassword;
  late Directory dir;

  setUp(() {
    savedHost = AppConfig.host;
    savedUpdaterHost = AppConfig.updaterHost;
    savedUser = AppConfig.boardUser;
    savedPassword = AppConfig.boardPassword;
    dir = Directory.systemTemp.createTempSync('operator_config_test');
    AppConfig.appDataDirOverride = dir.path;
  });

  tearDown(() {
    AppConfig.host = savedHost;
    AppConfig.updaterHost = savedUpdaterHost;
    AppConfig.boardUser = savedUser;
    AppConfig.boardPassword = savedPassword;
    AppConfig.appDataDirOverride = null;
    dir.deleteSync(recursive: true);
  });

  test('the Updater remembers its board without changing the connected server',
      () {
    AppConfig.host = '127.0.0.1';
    AppConfig.rememberUpdaterBoard('facesnap-001e064358ca.local', 'root', 'pw');
    expect(AppConfig.host, '127.0.0.1');
    expect(AppConfig.updaterHost, 'facesnap-001e064358ca.local');
    expect(AppConfig.boardUser, 'root');
    expect(AppConfig.boardPassword, 'pw');
  });

  test('the Updater board survives a save and load, next to the server',
      () async {
    AppConfig.host = '127.0.0.1';
    AppConfig.rememberUpdaterBoard('facesnap-a.local', 'root', 'pw');
    await AppConfig.save();
    AppConfig.host = 'x';
    AppConfig.updaterHost = '';
    await AppConfig.load();
    expect(AppConfig.host, '127.0.0.1');
    expect(AppConfig.updaterHost, 'facesnap-a.local');
  });

  // The column profile's factory key (spec 2026-10-10 section 5.4) lives in config.json next to
  // the board password: a save keeps it, a load reads it back.
  test('the factory key survives a save and load', () async {
    final savedKey = AppConfig.factoryKey;
    addTearDown(() => AppConfig.factoryKey = savedKey);
    AppConfig.factoryKey = 'a-factory-key';
    await AppConfig.save();
    AppConfig.factoryKey = '';
    await AppConfig.load();
    expect(AppConfig.factoryKey, 'a-factory-key');
  });

  // After "Change port" the saved server follows only when it IS the machine
  // changed: the same name, compared case-insensitively — never a guess.
  group('followPortChange', () {
    late int savedPort;
    setUp(() => savedPort = AppConfig.port);
    tearDown(() => AppConfig.port = savedPort);

    test('the same host (any case) takes the new port and is saved', () async {
      AppConfig.host = 'FaceSnap-1A2B.local';
      AppConfig.port = 50051;
      expect(AppConfig.followPortChange('facesnap-1a2b.local', 50052), isTrue);
      expect(AppConfig.port, 50052);
      // Saved (in the background): config.json gets the new port.
      final file = File('${dir.path}${Platform.pathSeparator}config.json');
      Object? saved;
      for (var i = 0; i < 40 && saved != 50052; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        try {
          saved = (jsonDecode(file.readAsStringSync()) as Map)['port'];
        } catch (_) {
          // Not (fully) written yet.
        }
      }
      expect(saved, 50052);
      expect(AppConfig.host, 'FaceSnap-1A2B.local');
    });

    test('another host (an IP for the same name, a shorter name) is left alone', () {
      AppConfig.host = 'facesnap-1a2b.local';
      AppConfig.port = 50051;
      expect(AppConfig.followPortChange('192.168.3.169', 50052), isFalse);
      expect(AppConfig.followPortChange('facesnap-1a2b', 50052), isFalse);
      expect(AppConfig.port, 50051);
      expect(AppConfig.host, 'facesnap-1a2b.local');
    });
  });
}
