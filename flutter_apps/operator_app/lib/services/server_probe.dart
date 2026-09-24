// What the Kiosk page's server list knows about each server, and how it finds
// out. Two tiers, because they cost differently:
//   1. gRPC GetKioskInfo on an independent channel, 2 s deadline, no
//      credentials — answers the question that matters most ("can I connect
//      to this?") and brings the camera count along for free.
//   2. One SSH session for version / running / board model — only for a
//      remote board and only when the board password is configured.
// The row-status mapping is pure so it is unit-tested without a network.
import 'package:face_snap_grpc/face_snap_grpc.dart';

import 'app_config.dart';
import 'board_server_manager.dart';
import 'discovery.dart';
import 'rpc_error.dart';

/// Everything a probe learned about one server. Fields are null when that
/// tier did not run or did not answer.
class ServerSnapshot {
  const ServerSnapshot({
    required this.answering,
    this.cameras,
    this.version,
    this.running,
    this.model,
    this.error,
  });

  /// The gRPC server answered GetKioskInfo.
  final bool answering;
  final int? cameras;

  /// From the compose image tag over SSH (null: no credentials / unreachable).
  final String? version;

  /// systemd unit active (null: SSH tier did not run).
  final bool? running;
  final String? model;

  /// Why [answering] is false, operator-readable.
  final String? error;
}

/// Upper bound on the SSH tier of one probe (see [probeServer]).
const kSshDetailsTimeout = Duration(seconds: 8);

/// Probe [host]:[port]. Never throws.
Future<ServerSnapshot> probeServer(String host, int port,
    {bool sshDetails = true}) async {
  final channel = GrpcChannelProvider.openChannel(host, port);
  bool answering;
  int? cameras;
  String? error;
  try {
    final info = await KioskClient(channel).getKioskInfo(Empty(),
        options: CallOptions(timeout: const Duration(seconds: 2)));
    answering = true;
    cameras = info.hasKioskInfo() ? info.kioskInfo.numberOfCameras : null;
  } catch (e) {
    answering = false;
    error = operatorMessage(e);
  } finally {
    await channel.shutdown();
  }

  BoardDetails? details;
  if (sshDetails &&
      BoardServerManager.isRemoteHost(host) &&
      AppConfig.boardPassword.isNotEmpty) {
    // Bounded: the SSH layer's own limits (20 s connect, 20 s command) would
    // keep a row on "Checking…" for most of a minute when a board vanished or
    // was renamed. The details are a nicety; the answer above is the point.
    details = await BoardServerManager.details(host)
        .timeout(kSshDetailsTimeout, onTimeout: () => null);
  }
  return ServerSnapshot(
    answering: answering,
    cameras: cameras,
    version: details?.version,
    running: details?.running,
    model: details?.model,
    error: error,
  );
}

/// What a row says about its server.
enum ServerRowStatus { probing, connected, answering, notAnswering, noServer }

/// Status of a row: a clean board has no server to talk to; until the probe
/// lands it is probing; the CURRENT host that answers is connected, any other
/// answering server can be switched to; else it is not answering.
ServerRowStatus rowStatus({
  required BoardKind kind,
  required bool isCurrent,
  required ServerSnapshot? snapshot,
}) {
  if (kind == BoardKind.clean) return ServerRowStatus.noServer;
  if (snapshot == null) return ServerRowStatus.probing;
  if (!snapshot.answering) return ServerRowStatus.notAnswering;
  return isCurrent ? ServerRowStatus.connected : ServerRowStatus.answering;
}

String rowStatusLabel(ServerRowStatus s) => switch (s) {
      ServerRowStatus.probing => 'Checking…',
      ServerRowStatus.connected => 'Connected',
      ServerRowStatus.answering => 'Answering',
      ServerRowStatus.notAnswering => 'Not answering',
      ServerRowStatus.noServer => 'No FaceSnap server',
    };

/// The detail line under a row: version · cameras · model, with what is
/// known; a stopped server or a failed probe explains itself instead.
String rowDetail(ServerRowStatus status, ServerSnapshot? snap) {
  if (status == ServerRowStatus.noServer) {
    return 'clean board — install a server with the Updater';
  }
  if (snap == null) return '';
  if (!snap.answering) {
    if (snap.running == false) return 'server stopped';
    return snap.error ?? 'no answer';
  }
  final parts = <String>[
    if (snap.version != null) snap.version!,
    if (snap.cameras != null) '${snap.cameras} cameras',
    if (snap.model != null) snap.model!,
  ];
  return parts.join(' · ');
}
