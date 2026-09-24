// Headless version of the updater (same engine as the GUI):
//   dart run bin/updater_cli.dart <host> <user> <password> <image.tar> [profile]
//
// [profile] (optional) sends a settings profile along with the update:
// "recommended" for the built-in Server 2.0 profile, or the path of a profile
// JSON file (see lib/settings_profile.dart). Headless runs apply every row of
// the profile that differs on the kiosk; the changes are listed in the log and
// the summary.
import 'dart:io';

import 'package:operator_app/updater/cli_report.dart';
import 'package:operator_app/updater/settings_profile.dart';
import 'package:operator_app/updater/update_engine.dart';

Future<void> main(List<String> args) async {
  if (args.length != 4 && args.length != 5) {
    requireArgs(args, 4,
        'updater_cli <host> <user> <password> <image.tar> [recommended|profile.json]');
  }

  SettingsProfile? profile;
  if (args.length == 5) {
    try {
      profile = args[4] == 'recommended'
          ? SettingsProfile.recommended()
          : SettingsProfile.parse(requireFile(args[4]).readAsStringSync());
    } on FormatException catch (e) {
      stderr.writeln(e.message);
      exit(2);
    }
  }

  final engine = UpdateEngine(
    host: args[0],
    user: args[1],
    password: args[2],
    tarFile: requireFile(args[3]),
    onChanged: () {},
    onLog: (line) => stdout.writeln(line),
    profile: profile,
  );
  reportAndExit(engine, await engine.run());
}
