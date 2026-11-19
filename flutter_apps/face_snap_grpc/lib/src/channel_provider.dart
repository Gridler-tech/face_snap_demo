import 'package:grpc/grpc.dart';

import 'rpc_trace.dart';

/// [options] with the column-session header (spec 2026-10-10 section 4.12) while
/// [GrpcChannelProvider.useColumnSession] is on; unchanged otherwise. Every channel of
/// [GrpcChannelProvider] applies it to every call. [options] itself is not changed, and a
/// value of the header the caller set itself is kept (as the C# SDK keeps it).
CallOptions withColumnSession(CallOptions options) =>
    GrpcChannelProvider.useColumnSession
        ? CallOptions(metadata: const {GrpcChannelProvider.columnSessionHeader: '1'})
            .mergedWith(options)
        : options;

// ---- default deadlines (FL-12) ------------------------------------------------
//
// Without a deadline, a call to a server that vanished (rebooted mid-sweep, pulled
// cable) never completes: gRPC keeps retrying the connection and the page waiting for
// it stays busy until the app restarts. So every UNARY call made through
// GrpcChannelProvider's channels without a timeout of its own gets
// [kDefaultUnaryDeadline]. Exempt, and left without a deadline as before:
//   * every streaming RPC (captures, high-resolution grabs, the preview, AutoTune,
//     the monitoring streams) - their length is the person in front of the column;
//   * the long unary RPCs in [kNoDefaultDeadline].
// A timeout the caller set always wins. THE VALUES ARE NOT DECIDED YET (audit FL-12;
// the C# SDK's twin is SDK-3): this table is the one place to change them.

/// The deadline of a unary call whose caller set no timeout.
const kDefaultUnaryDeadline = Duration(seconds: 30);

/// The unary RPCs (gRPC paths) that get NO default deadline: they legitimately run
/// longer than [kDefaultUnaryDeadline]. Their callers set their own timeout.
const kNoDefaultDeadline = <String>{
  '/calibration.Calibration/CalibrateByPerson', // camera-order scan; the app waits 180 s
  '/calibration.Calibration/CalibrateBySurroundings', // camera-order scan; 180 s
  '/camera.Camera/CalibrateFocus', // focus sweep; 60 s in the samples
  '/kiosk.Kiosk/GetFocusedCameraIndex', // the request carries its own timeoutInMs
  '/kiosk.Kiosk/FaceRecognition', // first use loads the models; the app waits 120 s
};

/// [options] with [kDefaultUnaryDeadline] when [path] is a unary RPC outside
/// [kNoDefaultDeadline] and the caller set no timeout; unchanged otherwise. [options]
/// itself is not changed.
CallOptions withDefaultDeadline(String path, CallOptions options) =>
    options.timeout == null &&
            !kNoDefaultDeadline.contains(path) &&
            RpcTrace.kindOf(path) == RpcKind.unary
        ? CallOptions(timeout: kDefaultUnaryDeadline).mergedWith(options)
        : options;

/// What every channel of [GrpcChannelProvider] does to the options of each call:
/// the column-session header ([withColumnSession]) and the default deadline
/// ([withDefaultDeadline]).
CallOptions providerCallOptions(String path, CallOptions options) =>
    withDefaultDeadline(path, withColumnSession(options));

/// A channel that is NOT traced and still sends the column-session header while it is on.
class SessionClientChannel extends ClientChannel {
  SessionClientChannel(super.host, {super.port, super.options});

  @override
  ClientCall<Q, R> createCall<Q, R>(
          ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options) =>
      super.createCall(method, requests, providerCallOptions(method.path, options));
}

/// Owns the single [ClientChannel] shared by all FaceSnap gRPC clients,
/// mirroring the C# GrpcChannelProvider: the server address can be swapped at
/// runtime and the next call transparently uses a channel to the new address,
/// so an IP change never requires an app restart.
class GrpcChannelProvider {
  GrpcChannelProvider._();

  static String _host = 'localhost';
  static int _port = 50051;
  static ClientChannel? _channel;

  /// The gRPC metadata key of the column session (value `1`).
  static const columnSessionHeader = 'facesnap-column-session';

  /// Whether every call on this provider's channels carries the column-session header
  /// (spec 2026-10-10 section 4.12). Off by default: the server then saves a change of a
  /// column setting on the column by itself (as before the column profile). The operator
  /// app switches it on at start: its changes wait for "Save as standard". Takes effect on
  /// the next call.
  static bool useColumnSession = false;

  static String get host => _host;
  static int get port => _port;

  /// The shared channel, created on first use. Like every channel from this
  /// provider it is a [TracingClientChannel]: its calls show up in
  /// [RpcTrace] while recording is on (a plain ClientChannel otherwise).
  static ClientChannel get channel => _channel ??= TracingClientChannel(
        _host,
        port: _port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );

  /// An INDEPENDENT channel to [host]:[port], for probing or talking to a
  /// server other than the shared one (e.g. checking every kiosk on the
  /// network) without disturbing it. The caller owns it: shut it down when
  /// done.
  static ClientChannel openChannel(String host, int port) =>
      TracingClientChannel(
        host,
        port: port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );

  /// An independent channel that is NOT traced: for a call whose request must never show in
  /// the RPC console, such as the updater's factory write with its key. It still sends the
  /// column-session header while [useColumnSession] is on. The caller owns it: shut it down
  /// when done.
  static ClientChannel openPlainChannel(String host, int port) =>
      SessionClientChannel(
        host,
        port: port,
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
