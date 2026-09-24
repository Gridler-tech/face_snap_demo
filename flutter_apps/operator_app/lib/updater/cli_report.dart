// Shared plumbing for the headless CLIs in bin/: argument checking and the
// step/summary report every engine command prints before exiting.
import 'dart:io';

import 'engine.dart';

/// Exits 2 with a usage line unless exactly [count] arguments are present.
void requireArgs(List<String> args, int count, String usage) {
  if (args.length != count) {
    stderr.writeln('usage: $usage');
    exit(2);
  }
}

/// The file at [path], or exit 2 when it does not exist.
File requireFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('No such file: $path');
    exit(2);
  }
  return file;
}

/// Prints the step table and the summary, then exits 0/1.
Never reportAndExit(KioskEngine engine, bool ok) {
  stdout.writeln('\n--- steps ---');
  for (final step in engine.steps) {
    stdout.writeln('${step.status.name.padRight(8)} ${step.title}'
        '${step.detail.isEmpty ? '' : '  [${step.detail}]'}');
  }
  stdout.writeln('\n--- summary ---');
  engine.summary.forEach(stdout.writeln);
  exit(ok ? 0 : 1);
}
