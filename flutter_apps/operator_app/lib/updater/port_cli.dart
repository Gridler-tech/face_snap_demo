// "Change port" without the GUI: the logic of bin/port_cli.dart, kept here so
// the tests can run it with a fake engine and capture what it prints.
//
// Exit codes: 0 the port changed; 1 the engine did not succeed (refused,
// rolled back, connection lost); 2 usage error. The password is only handed
// to the engine, never printed (nor is a bad port argument, which may be the
// password typed in its place). The CLI changes the machine only: unlike the
// Updater page it does not touch the operator app's saved server.
import 'dart:io';

import 'cli_report.dart';
import 'port_engine.dart';

const kPortCliUsage = 'port_cli <host> <user> <password> <port>';

/// Builds the engine for one run (tests substitute a fake).
typedef PortEngineFactory = PortEngine Function({
  required String host,
  required String user,
  required String password,
  required int newPort,
  required void Function(String line) onLog,
});

PortEngine _realEngine({
  required String host,
  required String user,
  required String password,
  required int newPort,
  required void Function(String line) onLog,
}) =>
    PortEngine(
      host: host,
      user: user,
      password: password,
      newPort: newPort,
      onChanged: () {},
      onLog: onLog,
    );

/// Runs Change port for `<host> <user> <password> <port>` and returns the
/// exit code. Log lines, the step table and the summary go to [out] (default
/// stdout), followed by the notice after a success; usage errors go to [err]
/// (default stderr).
Future<int> runPortCli(List<String> args,
    {PortEngineFactory? engine, StringSink? out, StringSink? err}) async {
  final o = out ?? stdout;
  final e = err ?? stderr;
  if (args.length != 4) {
    e.writeln('usage: $kPortCliUsage');
    return 2;
  }
  final port = RegExp(r'^\d+$').hasMatch(args[3]) ? int.tryParse(args[3]) : null;
  if (port == null) {
    // The argument itself is not echoed: with the password and the port
    // swapped it would be the password.
    e.writeln('the port (the fourth argument) must be a whole number');
    e.writeln('usage: $kPortCliUsage');
    return 2;
  }
  final portEngine = (engine ?? _realEngine)(
    host: args[0],
    user: args[1],
    password: args[2],
    newPort: port,
    onLog: o.writeln,
  );
  final ok = await portEngine.run();
  writeReport(portEngine, o);
  final notice = portEngine.notice;
  if (ok && notice != null) {
    o.writeln('\n$notice');
  }
  return ok ? 0 : 1;
}
