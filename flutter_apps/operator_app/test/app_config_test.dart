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
}
