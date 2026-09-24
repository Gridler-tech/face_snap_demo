// The ONE way the operator app connects to a server, shared by the Kiosk
// page's server list and the manual-address dialog: point the shared gRPC
// channel at the address, prove the server answers (settings snapshot under a
// short deadline), then persist. Plus the local-server probe and the identity
// key that keeps one board from showing up twice.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';

import 'app_config.dart';
import 'discovery.dart';
import 'settings_state.dart';

/// Connect the app to [host]:[port]. Throws when the server does not answer
/// (the address is then NOT saved). The deadline is short on purpose: a dead
/// host must fail fast, not hang the UI on "Connecting…".
Future<void> connectTo(String host, int port) async {
  await GrpcChannelProvider.setAddress(host, port);
  await SettingsState.refresh(timeout: const Duration(seconds: 5));
  AppConfig.host = host;
  AppConfig.port = port;
  await AppConfig.save();
}

/// A FaceSnap server on this machine, if one is listening on the gRPC port.
/// mDNS only finds provisioned boards (they announce _facesnap._tcp); a
/// server on this PC announces nothing, so it is probed directly.
Future<DiscoveredKiosk?> findLocalServer({int? port}) async {
  final p = port ?? AppConfig.port;
  try {
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, p,
        timeout: const Duration(seconds: 1));
    socket.destroy();
    return DiscoveredKiosk(hostName: 'This PC', ip: '127.0.0.1', port: p);
  } catch (_) {
    return null; // nothing listening locally
  }
}

/// The stable identity of a discovered kiosk: its name without `.local` and
/// without the `-N` counter mDNS appends when a name is re-registered (a board
/// that re-joins on Wi-Fi comes back as `facesnap-…-2.local`). Bounded to a
/// 1–2 digit counter so a MAC that happens to be all decimal digits is never
/// mistaken for one.
String baseName(String hostName) {
  var n = hostName;
  if (n.endsWith('.local')) n = n.substring(0, n.length - 6);
  return n.replaceFirst(RegExp(r'-\d{1,2}$'), '');
}

/// One entry per board, without hiding a board.
///
/// Two answers are the same board when they carry the same announced name
/// (mDNS keeps a live name unique on the network, so one name at two
/// addresses is one board on two interfaces — the Radxa on Ethernet + Wi-Fi),
/// or the same base name at the same address (a board that re-registered as
/// `…-2.local`). The same base name at DIFFERENT addresses is NOT collapsed:
/// boards cloned from one golden image all announce the donor's name until
/// their first update renames them, and mDNS conflict resolution hands the
/// later ones `-2`, `-3`… — six such clones are six boards, not one.
List<DiscoveredKiosk> dedupeDiscovered(List<DiscoveredKiosk> found) {
  final names = <String>{}, baseAt = <String>{};
  return [
    for (final k in found)
      if (names.add(announcedName(k.hostName)) &
          baseAt.add('${baseName(k.hostName)}@${k.ip}'))
        k,
  ];
}

/// The name as announced, minus the `.local` suffix — what a row is titled.
/// The `-N` counter stays: it is what tells clones apart until their first
/// update names them.
String announcedName(String hostName) =>
    hostName.endsWith('.local') ? hostName.substring(0, hostName.length - 6) : hostName;
