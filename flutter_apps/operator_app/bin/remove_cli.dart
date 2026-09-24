// Headless "Remove server installation":
//   dart run bin/remove_cli.dart <host> <user> <password> [--delete-configs]
import 'dart:io';

import 'package:operator_app/updater/cli_report.dart';
import 'package:operator_app/updater/remove_engine.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln('usage: remove_cli <host> <user> <password> '
        '[--delete-configs] [--backup=<local.tgz>]');
    exit(2);
  }
  final backupArg = args
      .where((a) => a.startsWith('--backup='))
      .map((a) => a.substring('--backup='.length))
      .firstOrNull;
  final engine = RemoveEngine(
    host: args[0],
    user: args[1],
    password: args[2],
    deleteConfigs: args.contains('--delete-configs'),
    backupPath: backupArg,
    onChanged: () {},
    onLog: (line) => stdout.writeln(line),
  );
  reportAndExit(engine, await engine.run());
}
