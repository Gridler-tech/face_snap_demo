// RPC trace: records every gRPC call made through the channels that
// GrpcChannelProvider hands out (the shared channel AND every openChannel),
// for the operator app's RPC console.
//
// The hook is a ClientChannel subclass (TracingClientChannel) that overrides
// createCall — the one method every generated client funnels through, unary
// and streaming alike (Client.$createUnaryCall / $createStreamingCall both end
// in channel.createCall). Interceptors would need every client constructed
// with `interceptors: [...]` (~20 call sites, and every future one); the
// channel sees them all with no call-site change. While recording is off,
// createCall is the inherited one: one bool test per call, nothing else.
//
// What a recorded call keeps: the request and every response as proto3 JSON
// in which every `bytes` field is replaced by a size marker ("<262144
// bytes>") — never the message objects, so no image data is retained. The
// caller's stream is observed, not consumed: every item, error, pause and
// cancel passes through unchanged.
import 'dart:async';
import 'dart:collection';

import 'package:grpc/grpc.dart';
import 'package:protobuf/protobuf.dart';

import 'generated/calibration.pbgrpc.dart';
import 'generated/camera.pbgrpc.dart';
import 'generated/kiosk.pbgrpc.dart';
import 'generated/lights.pbgrpc.dart';
import 'generated/monitoring.pbgrpc.dart';
import 'generated/settings.pbgrpc.dart';

/// The call shape, from the generated service definition.
enum RpcKind { unary, serverStreaming, clientStreaming, bidiStreaming, unknown }

/// One request or response message of a recorded call.
class RpcMessage {
  RpcMessage._(this.at, this.type, this.json, this.bytes, this.info);

  /// When it passed, relative to the call's start.
  final Duration at;

  /// Fully qualified protobuf name, e.g. `settings.CropRequest`.
  final String type;

  /// Proto3 JSON (as `toProto3Json`), every bytes field replaced by a
  /// `<N bytes>` marker.
  final Object? json;

  /// Total size of the bytes fields that were summarised.
  final int bytes;

  /// The message's static metadata (field names and types; holds no data) —
  /// used to turn [json] back into code.
  final BuilderInfo? info;

  Map<String, Object?> toJson() =>
      {'atMs': at.inMicroseconds / 1000, 'type': type, 'message': json};
}

/// One recorded call. Mutable while the call runs; [done] once it finished.
class RpcCall {
  RpcCall._({
    required this.id,
    required this.start,
    required this.host,
    required this.port,
    required this.path,
    required this.kind,
    required this.tag,
    required this.responseType,
  }) : _clock = Stopwatch()..start();

  final int id;
  final DateTime start;
  final String host;
  final int port;

  /// The gRPC path, `/settings.Settings/SetCrop`.
  final String path;
  final RpcKind kind;

  /// Set by [RpcTrace.runTagged] around the code that made the call (e.g.
  /// `poll` for the server list's periodic probes).
  final String? tag;

  /// The Dart type of the response message (e.g. `CropResponse`).
  final String responseType;

  final Stopwatch _clock;

  /// The request message(s), in the order they were sent.
  final List<RpcMessage> requests = [];

  /// The response messages in order — the first [RpcTrace.maxItemsPerCall];
  /// [responseCount] counts all of them, [lastResponse] is the newest.
  final List<RpcMessage> responses = [];
  int responseCount = 0;
  RpcMessage? lastResponse;

  /// Set when the call finished.
  Duration? duration;

  /// gRPC status code (0 = OK) and its name / message, once finished.
  int? statusCode;
  String? statusName;
  String? statusMessage;

  /// The caller cancelled (left the stream / cancelled the call).
  bool cancelledByCaller = false;
  bool _cancelRequested = false;

  /// `settings.Settings`
  String get service {
    final parts = path.split('/');
    return parts.length >= 3 ? parts[1] : path;
  }

  /// `Settings`
  String get serviceName => service.split('.').last;

  /// `SetCrop`
  String get method => path.split('/').last;

  String get address => '$host:$port';
  bool get done => duration != null;
  bool get isError => statusCode != null && statusCode != StatusCode.ok;
  Duration get elapsed => duration ?? _clock.elapsed;
  int get droppedResponses => responseCount - responses.length;

  Map<String, Object?> toJson() => {
        'id': id,
        'start': start.toIso8601String(),
        'address': address,
        'service': service,
        'method': method,
        'kind': kind.name,
        if (tag != null) 'tag': tag,
        'requests': [for (final r in requests) r.toJson()],
        'responses': [for (final r in responses) r.toJson()],
        'responseCount': responseCount,
        if (droppedResponses > 0) 'responsesNotKept': droppedResponses,
        if (duration != null) 'durationMs': duration!.inMicroseconds / 1000,
        if (statusCode != null) 'status': statusName,
        if (statusCode != null) 'code': statusCode,
        if (statusMessage != null && statusMessage!.isNotEmpty)
          'statusMessage': statusMessage,
        if (cancelledByCaller) 'cancelledByCaller': true,
      };

  RpcMessage _message(Object? m, {bool includeDefaults = false}) {
    final at = _clock.elapsed;
    if (m is GeneratedMessage) {
      final counter = _ByteCounter();
      final json = rpcMessageJson(m, counter, includeDefaults);
      return RpcMessage._(
          at, m.info_.qualifiedMessageName, json, counter.bytes, m.info_);
    }
    return RpcMessage._(at, m.runtimeType.toString(), '$m', 0, null);
  }

  void _addRequest(Object? q) {
    // Requests are small: show every field, defaults included, so the console
    // reads as what was sent. Replies keep the compact proto3 form.
    final message = _message(q, includeDefaults: true);
    requests.add(message);
    RpcTrace._emit(RpcEventType.request, this, message);
  }

  void _addResponse(Object? r) {
    final message = _message(r);
    responseCount++;
    lastResponse = message;
    if (responses.length < RpcTrace.maxItemsPerCall) responses.add(message);
    RpcTrace._emit(RpcEventType.response, this, message);
  }

  void _finish(int code, String? message, {bool byCaller = false}) {
    if (done) return;
    duration = _clock.elapsed;
    _clock.stop();
    statusCode = code;
    statusName = _codeName(code);
    statusMessage = message;
    cancelledByCaller = byCaller;
    RpcTrace._emit(RpcEventType.finished, this, null);
  }

  void _finishWithError(Object error) {
    if (error is GrpcError) {
      _finish(error.code, error.message,
          byCaller: _cancelRequested && error.code == StatusCode.cancelled);
    } else {
      _finish(StatusCode.unknown, '$error');
    }
  }
}

enum RpcEventType { started, request, response, finished }

/// A change to a recorded call: it started, sent a request, received a
/// response, or finished.
class RpcEvent {
  const RpcEvent(this.type, this.call, [this.message]);

  final RpcEventType type;
  final RpcCall call;

  /// The request / response for those event types.
  final RpcMessage? message;
}

/// The recorder. Off by default; while off nothing is recorded and the
/// channels behave exactly like plain ClientChannels.
abstract final class RpcTrace {
  /// Turn recording on/off. Calls started while it is on are recorded until
  /// they finish.
  static bool enabled = false;

  /// The ring buffer keeps the newest [capacity] calls.
  static const int capacity = 2000;

  /// Responses kept per call (a preview stream sends thousands); the rest is
  /// only counted ([RpcCall.responseCount], [RpcCall.lastResponse]).
  static int maxItemsPerCall = 1000;

  static final StreamController<RpcEvent> _events =
      StreamController<RpcEvent>.broadcast();
  static final ListQueue<RpcCall> _calls = ListQueue<RpcCall>();
  static int _nextId = 1;
  static const Symbol _tagKey = #faceSnapRpcTraceTag;

  /// Every change to a recorded call, as it happens.
  static Stream<RpcEvent> get events => _events.stream;

  /// The recorded calls, oldest first (at most [capacity]).
  static List<RpcCall> get calls => List.unmodifiable(_calls);

  /// Forget every recorded call.
  static void clear() => _calls.clear();

  /// Run [body] with every call it makes (also from its async continuations)
  /// tagged [tag] — e.g. `poll` for background status probes, so a viewer can
  /// hide them.
  static T runTagged<T>(String tag, T Function() body) =>
      runZoned(body, zoneValues: {_tagKey: tag});

  static RpcCall _begin(String host, int port, String path, Type response) {
    final call = RpcCall._(
      id: _nextId++,
      start: DateTime.now(),
      host: host,
      port: port,
      path: path,
      kind: _kindOf(path),
      tag: Zone.current[_tagKey] as String?,
      responseType: '$response',
    );
    _calls.addLast(call);
    while (_calls.length > capacity) {
      _calls.removeFirst();
    }
    _emit(RpcEventType.started, call, null);
    return call;
  }

  static void _emit(RpcEventType type, RpcCall call, RpcMessage? message) {
    if (_events.hasListener) _events.add(RpcEvent(type, call, message));
  }

  // ---- call shapes, from the generated service definitions -----------------

  static Map<String, Service>? _services;

  static RpcKind _kindOf(String path) {
    final parts = path.split('/');
    if (parts.length < 3) return RpcKind.unknown;
    final services = _services ??= {
      for (final Service s in [
        _CalibrationShape(),
        _CameraShape(),
        _KioskShape(),
        _LightsShape(),
        _MonitoringShape(),
        _SettingsShape(),
      ])
        s.$name: s,
    };
    final m = services[parts[1]]?.$lookupMethod(parts[2]);
    if (m == null) return RpcKind.unknown;
    return switch ((m.streamingRequest, m.streamingResponse)) {
      (false, false) => RpcKind.unary,
      (false, true) => RpcKind.serverStreaming,
      (true, false) => RpcKind.clientStreaming,
      (true, true) => RpcKind.bidiStreaming,
    };
  }
}

// Concrete views of the generated service bases, only to read each method's
// streaming flags ($lookupMethod). Never served; every handler is missing.
class _CalibrationShape extends CalibrationServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CameraShape extends CameraServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _KioskShape extends KioskServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LightsShape extends LightsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MonitoringShape extends MonitoringServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SettingsShape extends SettingsServiceBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _codeName(int code) => switch (code) {
      StatusCode.ok => 'OK',
      StatusCode.cancelled => 'CANCELLED',
      StatusCode.unknown => 'UNKNOWN',
      StatusCode.invalidArgument => 'INVALID_ARGUMENT',
      StatusCode.deadlineExceeded => 'DEADLINE_EXCEEDED',
      StatusCode.notFound => 'NOT_FOUND',
      StatusCode.alreadyExists => 'ALREADY_EXISTS',
      StatusCode.permissionDenied => 'PERMISSION_DENIED',
      StatusCode.resourceExhausted => 'RESOURCE_EXHAUSTED',
      StatusCode.failedPrecondition => 'FAILED_PRECONDITION',
      StatusCode.aborted => 'ABORTED',
      StatusCode.outOfRange => 'OUT_OF_RANGE',
      StatusCode.unimplemented => 'UNIMPLEMENTED',
      StatusCode.internal => 'INTERNAL',
      StatusCode.unavailable => 'UNAVAILABLE',
      StatusCode.dataLoss => 'DATA_LOSS',
      StatusCode.unauthenticated => 'UNAUTHENTICATED',
      _ => 'CODE_$code',
    };

// ---- proto3 JSON with bytes summarised --------------------------------------

class _ByteCounter {
  int bytes = 0;
}

/// [message] as proto3 JSON (same shape as `toProto3Json`), except that
/// every `bytes` field becomes a `<N bytes>` marker — the bytes are measured,
/// never copied or encoded.
///
/// proto3 JSON leaves out fields that hold their default (false, 0, "", the
/// first enum value). With [includeDefaults] those singular fields are written
/// too, so a request reads as what the caller sent (`{value: false}` instead
/// of `{}`). Members of a oneof are still written only when set; repeated and
/// map fields only when non-empty. The Dart stubs carry no marker for proto3
/// `optional` fields, so an unset one would show its default here: no request
/// message has one (only CheckResult, which is never sent), and replies are
/// formatted without defaults.
Object? rpcMessageJson(GeneratedMessage message,
    [Object? counter, bool includeDefaults = false]) {
  final c = counter is _ByteCounter ? counter : _ByteCounter();
  final out = <String, Object?>{};
  final oneofs = message.info_.oneofs;
  for (final fi in message.info_.sortedByTag) {
    var value = message.getFieldOrNull(fi.tagNumber);
    if (value == null &&
        includeDefaults &&
        !fi.isRepeated &&
        fi is! MapFieldInfo &&
        !oneofs.containsKey(fi.tagNumber) &&
        PbFieldType.baseType(fi.type) != PbFieldType.MESSAGE_BIT &&
        PbFieldType.baseType(fi.type) != PbFieldType.GROUP_BIT) {
      value = message.getField(fi.tagNumber);
    }
    if (value == null) continue;
    if (value is List && value.isEmpty) continue; // repeated / empty bytes
    if (value is Map && value.isEmpty) continue;
    if (fi is MapFieldInfo) {
      out[fi.name] = {
        for (final e in (value as Map).entries)
          '${e.key}': _jsonValue(e.value, fi.valueFieldType, c),
      };
    } else if (fi.isRepeated) {
      out[fi.name] = [
        for (final e in value as List)
          _jsonValue(e, fi.type, c, includeDefaults),
      ];
    } else {
      out[fi.name] = _jsonValue(value, fi.type, c, includeDefaults);
    }
  }
  return out;
}

Object? _jsonValue(Object? v, int type, _ByteCounter c,
    [bool includeDefaults = false]) {
  if (v == null) return null;
  if (v is GeneratedMessage) return rpcMessageJson(v, c, includeDefaults);
  if (v is ProtobufEnum) return v.name;
  final base = PbFieldType.baseType(type);
  if (base == PbFieldType.BYTES_BIT) {
    final n = (v as List).length;
    c.bytes += n;
    return bytesMarker(n);
  }
  if (v is double) {
    if (v.isNaN) return 'NaN';
    if (v.isInfinite) return v.isNegative ? '-Infinity' : 'Infinity';
    if (v == v.truncateToDouble() && v.abs() < 1e15) return v.toInt();
    return v;
  }
  if (v is bool || v is String || v is int) return v;
  // Int64 and the unsigned 64-bit types: proto3 JSON writes them as strings.
  return v.toString();
}

/// The marker that replaces a bytes field's content.
String bytesMarker(int length) => '<$length bytes>';

final RegExp _bytesMarkerPattern = RegExp(r'^<(\d+) bytes>$');

/// The byte count of a [bytesMarker] string, or null.
int? bytesMarkerLength(Object? value) {
  if (value is! String) return null;
  final m = _bytesMarkerPattern.firstMatch(value);
  return m == null ? null : int.parse(m.group(1)!);
}

// ---- the hook ---------------------------------------------------------------

/// A [ClientChannel] that records its calls in [RpcTrace] while
/// [RpcTrace.enabled] is on. GrpcChannelProvider builds every channel with it.
class TracingClientChannel extends ClientChannel {
  TracingClientChannel(super.host, {super.port, super.options});

  @override
  ClientCall<Q, R> createCall<Q, R>(
      ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options) {
    if (!RpcTrace.enabled) return super.createCall(method, requests, options);

    final record = RpcTrace._begin('$host', port, method.path, R);
    final call = _TracedCall<Q, R>(
        method, _observeRequests(requests, record), options, record);
    // Same dispatch as ClientChannelBase.createCall (minus the timeline task,
    // which is null unless timeline logging is switched on).
    getConnection().then((connection) {
      if (call.isCancelled) return;
      connection.dispatchCall(call);
    }, onError: call.onConnectionError);
    return call;
  }

  /// Records each request message as it passes. A single-message request
  /// (unary / server streaming: the generated client's `Stream.value`) is
  /// read at once, so a call that never reaches the server (connection
  /// refused) still shows what it asked; a streamed request is recorded as
  /// the call consumes it, keeping its flow control untouched.
  static Stream<Q> _observeRequests<Q>(Stream<Q> requests, RpcCall record) {
    void note(Q q) {
      try {
        record._addRequest(q);
      } catch (_) {/* recording must never break a call */}
    }

    if (record.kind == RpcKind.unary || record.kind == RpcKind.serverStreaming) {
      final out = StreamController<Q>();
      requests.listen((q) {
        note(q);
        out.add(q);
      }, onError: out.addError, onDone: out.close);
      return out.stream;
    }
    return requests.map((q) {
      note(q);
      return q;
    });
  }
}

/// A [ClientCall] whose response stream is observed on its way to the caller.
class _TracedCall<Q, R> extends ClientCall<Q, R> {
  _TracedCall(ClientMethod<Q, R> method, Stream<Q> requests,
      CallOptions options, this._record)
      : super(method, requests, options);

  final RpcCall _record;
  Stream<R>? _observed;

  @override
  Stream<R> get response => _observed ??= _observe(super.response);

  /// cancel() also runs inside grpc after a normal end (the response
  /// controller's onCancel), so it only marks the intent: the CANCELLED error
  /// it injects (when the call is still open) is then the caller's.
  @override
  Future<void> cancel() {
    _record._cancelRequested = true;
    return super.cancel();
  }

  /// Pass-through: every event, pause, resume and cancel goes straight to /
  /// from [source]; the record only looks.
  Stream<R> _observe(Stream<R> source) {
    StreamSubscription<R>? sub;
    late final StreamController<R> out;
    out = StreamController<R>(
      sync: true,
      onListen: () {
        sub = source.listen(
          (r) {
            try {
              _record._addResponse(r);
            } catch (_) {/* recording must never break a call */}
            out.add(r);
          },
          onError: (Object e, StackTrace s) {
            _record._finishWithError(e);
            out.addError(e, s);
          },
          onDone: () {
            _record._finish(StatusCode.ok, null);
            out.close();
          },
        );
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () {
        // After an error/done the caller's cancelOnError lands here too;
        // _finish ignores it then.
        _record._finish(StatusCode.cancelled, 'Cancelled by the caller',
            byCaller: true);
        return sub?.cancel();
      },
    );
    return out.stream;
  }
}
