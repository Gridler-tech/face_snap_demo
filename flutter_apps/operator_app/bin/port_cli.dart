// Headless "Change port" (same engine as the Updater page's Server port card):
//   dart run bin/port_cli.dart <host> <user> <password> <port>
//
// Works on a Linux board and on a Windows PC running the server as a service.
// Exit 0: the port changed (the new address and a firewall reminder are
// printed last); 1: refused, rolled back or the connection was lost (the
// summary says which port the machine is on); 2: usage error.
import 'dart:io';

import 'package:operator_app/updater/port_cli.dart';

Future<void> main(List<String> args) async {
  exit(await runPortCli(args));
}
