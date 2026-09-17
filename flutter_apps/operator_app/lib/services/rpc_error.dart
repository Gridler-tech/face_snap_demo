// The one place a failed server call is turned into a message an operator
// can act on. Every page interpolated the raw exception before, which showed
// non-technical operators things like "gRPC Error (code: 14, codeName:
// UNAVAILABLE, …, rawResponse: null, trailers: {})".
import 'package:face_snap_grpc/face_snap_grpc.dart';

// gRPC status codes (the grpc package's StatusCode is not re-exported).
const _unavailable = 14;
const _deadlineExceeded = 4;
const _unimplemented = 12;

/// A short operator-readable description of a server-call failure; anything
/// unrecognized falls back to the exception text.
String operatorMessage(Object e) {
  if (e is GrpcError) {
    switch (e.code) {
      case _unavailable:
        return 'kiosk not reachable — is the server running?';
      case _deadlineExceeded:
        return 'the kiosk did not answer in time';
      case _unimplemented:
        return "this kiosk's server is too old for that call — update the "
            'server';
      default:
        final detail = e.message;
        return detail == null || detail.isEmpty
            ? 'server error ${e.codeName}'
            : 'server error: $detail';
    }
  }
  return '$e';
}
