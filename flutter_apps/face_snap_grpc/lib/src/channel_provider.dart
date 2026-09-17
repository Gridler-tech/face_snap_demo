import 'package:grpc/grpc.dart';

/// Owns the single [ClientChannel] shared by all FaceSnap gRPC clients,
/// mirroring the C# GrpcChannelProvider: the server address can be swapped at
/// runtime and the next call transparently uses a channel to the new address,
/// so an IP change never requires an app restart.
class GrpcChannelProvider {
  GrpcChannelProvider._();

  static String _host = 'localhost';
  static int _port = 50051;
  static ClientChannel? _channel;

  static String get host => _host;
  static int get port => _port;

  /// The shared channel, created on first use.
  static ClientChannel get channel => _channel ??= ClientChannel(
        _host,
        port: _port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );

  /// Points the shared channel at a new address. No-op when unchanged;
  /// otherwise the old channel is shut down (in-flight calls on it fail,
  /// which is expected when switching servers).
  static Future<void> setAddress(String host, int port) async {
    if (host == _host && port == _port && _channel != null) return;
    final old = _channel;
    _host = host;
    _port = port;
    _channel = null;
    await old?.shutdown();
  }
}
