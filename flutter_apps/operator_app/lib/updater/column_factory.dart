// The updater's factory actions on a column (spec 2026-10-10 section 5.4): "Write factory
// defaults" after a factory calibration (the values in force) and "Save this column's current
// standard as factory defaults" (a field column). The server's WriteColumnFactory RPC needs
// the factory key, which only the updater's config holds (config.json, factory_key) - it is
// never shown, logged or traced: the call goes over a plain, untraced channel and no message
// carries it. "This PC" is the server on 127.0.0.1; a kiosk is reached over SSH, its server
// port forwarded through the SSH connection (a kiosk PC's server listens on localhost only).
import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:face_snap_grpc/face_snap_grpc.dart';

import '../services/ssh_runner.dart';

/// A kiosk's server's default gRPC port (behind SSH): the Updater page passes
/// the port the probe read from the kiosk's port file as [openOverSsh]'s
/// `remotePort` and falls back to this one only when it knows none. This
/// PC's server port is [LocalServerConfig.port] (server_config.json).
const kServerPort = LocalServerConfig.defaultPort;

enum FactorySource {
  /// The values in force: after a factory calibration on this server.
  valuesInForce,

  /// The column's current standard: a column already in the field.
  currentStandard,
}

/// A channel to a server and how to close what it needs (the channel; an SSH tunnel).
class ServerLink {
  ServerLink(this.channel, this._close);

  final ClientChannel channel;
  final Future<void> Function() _close;

  Future<void> close() => _close();
}

/// The server on this PC, on [port] (default [LocalServerConfig.port]: 50051, or the
/// port chosen in the setup).
Future<ServerLink> openThisPc({int? port}) async {
  final channel = GrpcChannelProvider.openPlainChannel('127.0.0.1', port ?? LocalServerConfig.port);
  return ServerLink(channel, () => channel.shutdown());
}

/// The server on a kiosk, through an SSH connection: a local port on 127.0.0.1 whose
/// connections are forwarded to the kiosk's 127.0.0.1:[remotePort] (the port its server
/// uses: the kiosk's port file, else [kServerPort]).
Future<ServerLink> openOverSsh(String host, String user, String password,
    {int remotePort = kServerPort}) async {
  final socket = await SSHSocket.connect(host, 22, timeout: const Duration(seconds: 15));
  final client = SSHClient(socket,
      username: user, onPasswordRequest: () => password, algorithms: kSshAlgorithms);
  try {
    await client.authenticated;
  } catch (_) {
    client.close();
    rethrow;
  }
  return openTunnel(client.forwardLocal, () async => client.close(), remotePort: remotePort);
}

/// The tunnel of [openOverSsh] over any SSH connection: a local port, bound to 127.0.0.1
/// only, each of whose connections [forward] carries to the kiosk's 127.0.0.1:[remotePort].
/// The first forward is opened at once, so a kiosk whose server does not listen fails here
/// instead of after the call's timeout. The link's close shuts the channel, the local port
/// and then [closeSsh]; when the tunnel cannot be opened, [closeSsh] runs before the throw.
Future<ServerLink> openTunnel(Future<SSHSocket> Function(String host, int port) forward,
    Future<void> Function() closeSsh,
    {int remotePort = kServerPort}) async {
  SSHSocket? first;
  final ServerSocket local;
  try {
    first = await forward('127.0.0.1', remotePort);
    local = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  } catch (_) {
    first?.destroy();
    await closeSsh();
    rethrow;
  }
  local.listen((connection) async {
    try {
      final remote = first ?? await forward('127.0.0.1', remotePort);
      first = null;
      unawaited(remote.stream.cast<List<int>>().pipe(connection).catchError((_) {}));
      unawaited(connection.cast<List<int>>().pipe(remote.sink).catchError((_) {}));
    } catch (_) {
      connection.destroy();
    }
  });
  final channel = GrpcChannelProvider.openPlainChannel('127.0.0.1', local.port);
  return ServerLink(channel, () async {
    try {
      await channel.shutdown();
      await local.close();
      first?.destroy();
    } finally {
      await closeSsh();
    }
  });
}

/// gRPC status PERMISSION_DENIED / UNIMPLEMENTED.
const _permissionDenied = 7;
const _unimplemented = 12;

/// Write the column's factory defaults through [open] with [key] and say what happened, in
/// one line for the operator. Never throws and never puts the key in its answer.
Future<({bool ok, String text})> writeColumnFactory(
    Future<ServerLink> Function() open, String key, FactorySource source) async {
  if (key.isEmpty) {
    return (ok: false, text: 'No factory key in config.json (factory_key): the factory actions are off.');
  }
  // A server's own text is shown as it is, but never with the key in it.
  String withoutKey(String text) => text.replaceAll(key, '<factory key>');
  ServerLink? link;
  try {
    link = await open();
    final reply = await SettingsClient(link.channel).writeColumnFactory(
        WriteColumnFactoryRequest(
            key: key,
            source: source == FactorySource.currentStandard
                ? ColumnFactorySource.COLUMN_FACTORY_SOURCE_STANDARD
                : ColumnFactorySource.COLUMN_FACTORY_SOURCE_VALUES_IN_FORCE),
        options: CallOptions(timeout: const Duration(seconds: 30)));
    return (
      ok: true,
      text: 'Factory defaults written to column ${reply.profile.boardId} '
          '(${reply.names.length} settings, from the '
          '${source == FactorySource.currentStandard ? "column's standard" : 'values in force'}).'
    );
  } on GrpcError catch (e) {
    final text = switch (e.code) {
      _permissionDenied => 'The server refused the factory key (config.json, factory_key).',
      _unimplemented => 'This server has no column profile (an older server version).',
      _ => 'The factory defaults were not written: ${withoutKey(e.message ?? 'error ${e.code}')}',
    };
    return (ok: false, text: text);
  } catch (e) {
    return (ok: false, text: 'The server could not be reached: ${e.runtimeType}');
  } finally {
    try {
      await link?.close();
    } catch (_) {
      // Closing a link that already failed: nothing left to tell the operator.
    }
  }
}
