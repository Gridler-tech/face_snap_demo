// Headless "Get server info":
//   dart run bin/info_cli.dart <host> <user> <password>
import 'dart:io';

import 'package:operator_app/updater/server_info.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln('usage: info_cli <host> <user> <password>');
    exit(2);
  }
  final info = await ServerInfo.fetch(args[0], args[1], args[2]);
  stdout.writeln('--- FaceSnap server ---');
  for (final (label, value) in info.server) {
    stdout.writeln('${label.padRight(14)} $value');
  }
  stdout.writeln('--- System ---');
  for (final (label, value) in info.system) {
    stdout.writeln('${label.padRight(14)} $value');
  }
  for (final entry in info.configs.entries) {
    stdout.writeln('--- ${entry.key} ---');
    stdout.writeln(entry.value);
  }
}
