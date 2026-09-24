// Headless "Search kiosks":
//   dart run bin/discover_cli.dart                  kiosks + clean boards
//   dart run bin/discover_cli.dart --probe a,b,c    probe specific hostnames
//                                                   (mDNS <name>.local + LLMNR)
import 'dart:io';

import 'package:operator_app/services/discovery.dart';

Future<void> main(List<String> args) async {
  if (args.length == 2 && args[0] == '--probe') {
    final names = args[1].split(',');
    stdout.writeln('Probing ${names.join(", ")} via mDNS + LLMNR …');
    final boards = await probeHostnames(names);
    if (boards.isEmpty) {
      stdout.writeln('No answers.');
      exit(1);
    }
    for (final board in boards) {
      stdout.writeln('${board.hostName.padRight(36)} ${board.ip}');
    }
    return;
  }

  stdout.writeln('Searching kiosks (_facesnap._tcp) and clean boards '
      '(odroid/radxa) for 4 seconds …');
  final boards = await discoverBoards();
  if (boards.isEmpty) {
    stdout.writeln('Nothing found.');
    exit(1);
  }
  for (final board in boards) {
    final tag = board.kind == BoardKind.clean ? '  [clean board]' : '';
    stdout.writeln('${board.hostName.padRight(36)} ${board.ip}$tag');
  }
}
