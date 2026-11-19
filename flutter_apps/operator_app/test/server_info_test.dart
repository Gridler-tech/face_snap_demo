// "Get server info": the settings files of either layout (FL-8) — data/ on
// the later generations, next to docker-compose.yml on a first-generation
// board — instead of "(not present)".
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/updater/kiosk.dart';
import 'package:operator_app/updater/server_info.dart';

import 'scripted_ssh.dart';

void main() {
  test('a first-generation board: the settings files are read next to the compose', () async {
    final ssh = ScriptedSsh()
      ..onCall(RegExp(r'^cat '), (command) {
        // data/ does not exist; the files sit in /root/face_snap.
        for (final name in kSettingsFiles) {
          if (command.contains('$kKioskDir/$name')) {
            return CmdResult(0, '{"from": "$name"}', '');
          }
        }
        return CmdResult(1, '', 'No such file or directory');
      });
    final result = ServerInfoResult();

    await ServerInfo.configSection(ssh, result);

    for (final name in kSettingsFiles) {
      expect(result.configs[name], contains('"from": "$name"'), reason: name);
    }
  });

  test('data/ wins over a first-generation copy left next to the compose', () async {
    final ssh = ScriptedSsh()
      ..onCall(RegExp(r'^cat '), (command) => command.startsWith('cat $kKioskDir/data/')
          ? CmdResult(0, '{"where": "data"}', '')
          : CmdResult(0, '{"where": "legacy"}', ''));
    final result = ServerInfoResult();

    await ServerInfo.configSection(ssh, result);

    expect(result.configs.values, everyElement(contains('"where": "data"')));
  });
}
