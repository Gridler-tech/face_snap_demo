// Headless "Backup configuration files":
//   dart run bin/backup_cli.dart <host> <user> <password> <local.tgz>
import 'dart:io';

import 'package:operator_app/updater/backup_engine.dart';
import 'package:operator_app/updater/cli_report.dart';

Future<void> main(List<String> args) async {
  requireArgs(args, 4, 'backup_cli <host> <user> <password> <local.tgz>');
  final engine = BackupEngine(
    host: args[0],
    user: args[1],
    password: args[2],
    backupPath: args[3],
    onChanged: () {},
    onLog: (line) => stdout.writeln(line),
  );
  reportAndExit(engine, await engine.run());
}
