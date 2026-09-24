// Headless "Restore configuration files":
//   dart run bin/restore_cli.dart <host> <user> <password> <backup.tgz>
import 'dart:io';

import 'package:operator_app/updater/cli_report.dart';
import 'package:operator_app/updater/restore_engine.dart';

Future<void> main(List<String> args) async {
  requireArgs(args, 4, 'restore_cli <host> <user> <password> <backup.tgz>');
  final engine = RestoreEngine(
    host: args[0],
    user: args[1],
    password: args[2],
    backupFile: requireFile(args[3]),
    onChanged: () {},
    onLog: (line) => stdout.writeln(line),
  );
  reportAndExit(engine, await engine.run());
}
