import 'dart:typed_data';

import 'package:grpc/grpc.dart' show GrpcError, StatusCode;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

import 'channel_provider.dart';
import 'generated/kiosk.pbgrpc.dart';

/// A single event from the server's automatic capture flow.
sealed class CaptureEvent {}

/// A status line from the server (ICAO checks, progress messages).
class CaptureStatus extends CaptureEvent {
  CaptureStatus(this.description, this.status);

  final String description;
  final String status;
}

/// The final photo, assembled from the streamed JPEG chunks.
class CapturePhoto extends CaptureEvent {
  CapturePhoto(this.bytes, this.width, this.height,
      {this.firstChunkAt, this.lastChunkAt});

  final Uint8List bytes;
  final int width;
  final int height;

  /// Local wall-clock times at which the first and last JPEG chunk arrived.
  /// The event itself can only be emitted once the stream shows the chunks
  /// are complete (next status line or stream end), which may be well after
  /// the last chunk — e.g. the server scores OFIQ between the two — so use
  /// these to time the photo delivery itself.
  final DateTime? firstChunkAt;
  final DateTime? lastChunkAt;
}

/// A structured check result from the automatic flow: the server sends one
/// right after the [CaptureStatus] line of each check that ran (distance,
/// eyes, lips, the kiosk checks, liveness, OFIQ, ICAO). Match on
/// `result.name` (stable, e.g. "distance", "ofiq.Sharpness",
/// "icao.compliance"), not on `result.description` (the status-line text).
/// A server that does not send check results produces none.
class CaptureCheck extends CaptureEvent {
  CaptureCheck(this.result);

  /// The generated message: index, kind, name, verdict, gatesPhoto,
  /// value/min/max (check `hasValue()` etc.; unset = the check has no such
  /// number), unit and description.
  final CheckResult result;
}

/// The live person check's head turn (kiosk setting liveness_head_turn_check):
/// what the person in front of the kiosk is asked to do now. The server sends
/// one when the instruction changes and in between when [progress] moved 5
/// points or more (at most ~10 per second); every new instruction also comes as
/// a [CaptureStatus] line with the same English [text], so a client that skips
/// this event still shows it. "Left" is the person's own left: on a screen the
/// person faces, the screen's left. [InstructionKind.DONE] ends the head turn.
///
/// The generated message's `index` (the selected camera's index: the same
/// value as [ProcessStepStatus.index] in this stream) is not carried here.
class CaptureInstruction extends CaptureEvent {
  CaptureInstruction(
      this.kind, this.progress, this.repeat, this.secondsLeft, this.text);

  /// TURN_LEFT, TURN_RIGHT, LOOK_STRAIGHT or DONE.
  final InstructionKind kind;

  /// 0..1: the measured head turn towards the 20 degree target (0 for
  /// LOOK_STRAIGHT and DONE).
  final double progress;

  /// The second ask for this direction ("Once more: ...").
  final bool repeat;

  /// Of the current ask.
  final double secondsLeft;

  /// The server's English text ("Turn your head to the left"; empty for DONE).
  final String text;
}

/// The settings this capture runs with: the first event of every capture from a server with
/// per-capture settings — with or without settings, automatic or manual. Its arrival also
/// tells you that the server accepted the request. A server from before per-capture
/// settings sends none; the stream then starts with its first [CaptureStatus] as before,
/// and nothing is made up here.
///
/// Added in SDK 1.5.5.
final class CaptureSettingsReport extends CaptureEvent {
  CaptureSettingsReport(this.values, Iterable<String> overridden)
      : overridden = List.unmodifiable(overridden);

  /// The values in force for this capture: all 28 fields for an automatic capture, the five
  /// manual fields (jpeg quality, glare-free light, photo light, LEDs off for the photo, colour
  /// correction) for a manual one. `backgroundMethod` is the normalised name (`withoutbg`, never `rembg`).
  final CaptureSettings values;

  /// The field names (`photo_format`, ...) whose value came from the request, in field
  /// order; empty without settings and for an empty [CaptureSettings]. Unmodifiable.
  final List<String> overridden;
}

/// A capture with per-capture settings went to a server from before them (it answered the
/// new RPC UNIMPLEMENTED before the first event). The server did not start the capture.
/// Without settings, [startAutomaticCapture] / [startManualCapture] use the older RPCs and
/// work against such a server as before.
///
/// Added in SDK 1.5.5.
class PerCaptureSettingsNotSupported implements Exception {
  const PerCaptureSettingsNotSupported([this.cause]);

  /// The server's UNIMPLEMENTED status.
  final GrpcError? cause;

  @override
  String toString() =>
      'this FaceSnap server does not support per-capture settings; update the server';
}

/// One camera's photo from the manual flow (which returns a photo per camera).
class CameraPhoto extends CaptureEvent {
  CameraPhoto(this.cameraIndex, this.bytes, this.width, this.height,
      {this.firstChunkAt, this.lastChunkAt});

  final int cameraIndex;
  final Uint8List bytes;
  final int width;
  final int height;

  /// See [CapturePhoto.firstChunkAt] / [CapturePhoto.lastChunkAt].
  final DateTime? firstChunkAt;
  final DateTime? lastChunkAt;
}

/// Runs the server's automatic flow once: yields [CaptureStatus] events while
/// the server works (each check that ran followed by a [CaptureCheck], from a
/// server that sends check results) and, when the capture succeeds, one
/// [CapturePhoto]
/// (the server streams the JPEG in chunks; they are assembled here, mirroring
/// the C# KioskProcessor). No photo event = the flow ended without a photo.
///
/// The photo is emitted as soon as its last chunk is known to have arrived:
/// either when the next status line follows the chunks (the OFIQ report is
/// scored AFTER the photo is delivered, so the caller gets the image ~2 s
/// before the score rows instead of after them) or at stream end.
///
/// With the head turn on, [CaptureInstruction] events come between the camera
/// selection and the photo.
///
/// [settings] apply to this capture only (per-capture settings, SDK 1.5.5): they go to the
/// server's `StartAutomaticCapture` RPC. Without them (`null`) the call is the older
/// `StartAutomaticProcess`, so it works against every server. A server with per-capture
/// settings starts every capture with a [CaptureSettingsReport]. A server from before them
/// refuses settings with [PerCaptureSettingsNotSupported]; a refused value is a [GrpcError]
/// INVALID_ARGUMENT with the server's text.
Stream<CaptureEvent> startAutomaticCapture({CaptureSettings? settings}) async* {
  // Started on listen, as before; cancelling the subscription cancels the call.
  final client = KioskClient(GrpcChannelProvider.channel);
  if (settings == null) {
    yield* automaticCaptureEvents(client.startAutomaticProcess(Empty()));
  } else {
    yield* _withOldServerError(automaticCaptureEvents(
        client.startAutomaticCapture(CaptureRequest(settings: settings))));
  }
}

/// [events] with an UNIMPLEMENTED before the first event — the server has no per-capture
/// RPCs — as [PerCaptureSettingsNotSupported]. Any later error passes through unchanged (as
/// the C# SDK's WithOldServerError).
Stream<CaptureEvent> _withOldServerError(Stream<CaptureEvent> events) async* {
  var first = true;
  try {
    await for (final event in events) {
      first = false;
      yield event;
    }
  } on GrpcError catch (e, stack) {
    if (first && e.code == StatusCode.unimplemented) {
      Error.throwWithStackTrace(PerCaptureSettingsNotSupported(e), stack);
    }
    rethrow;
  }
}

/// The events of an automatic capture's response stream (see
/// [startAutomaticCapture], which runs it on the server's stream; the tests
/// feed it messages directly).
Stream<CaptureEvent> automaticCaptureEvents(
    Stream<ProcessAutomaticResponse> messages) async* {
  final chunks = BytesBuilder(copy: false);
  var width = 0;
  var height = 0;
  DateTime? firstChunkAt;
  DateTime? lastChunkAt;

  CapturePhoto flush() {
    final photo = CapturePhoto(chunks.takeBytes(), width, height,
        firstChunkAt: firstChunkAt, lastChunkAt: lastChunkAt);
    firstChunkAt = lastChunkAt = null;
    return photo;
  }

  await for (final message in messages) {
    switch (message.whichResult()) {
      case ProcessAutomaticResponse_Result.processStatus:
        if (chunks.length > 0) yield flush();
        yield CaptureStatus(
            message.processStatus.description, message.processStatus.status.name);
      case ProcessAutomaticResponse_Result.instruction:
        if (chunks.length > 0) yield flush();
        final instruction = message.instruction;
        yield CaptureInstruction(instruction.kind, instruction.progress,
            instruction.repeat, instruction.secondsLeft, instruction.text);
      case ProcessAutomaticResponse_Result.checkResult:
        // Always follows its status line, so the photo is normally flushed
        // already; flush here too so the photo never waits behind a check.
        if (chunks.length > 0) yield flush();
        yield CaptureCheck(message.checkResult);
      case ProcessAutomaticResponse_Result.imageData:
        lastChunkAt = DateTime.now();
        firstChunkAt ??= lastChunkAt;
        chunks.add(message.imageData.chunkData);
        if (message.imageData.width != 0) width = message.imageData.width;
        if (message.imageData.height != 0) height = message.imageData.height;
      case ProcessAutomaticResponse_Result.settingsUsed:
        // The settings the capture runs with: the first message of the stream
        // (servers with per-capture settings).
        if (chunks.length > 0) yield flush();
        yield CaptureSettingsReport(
            message.settingsUsed.values, message.settingsUsed.overridden);
      case ProcessAutomaticResponse_Result.notSet:
        break;
    }
  }

  if (chunks.length > 0) yield flush();
}

/// Runs the server's manual flow once: yields [CaptureStatus] events and one
/// [CameraPhoto] per camera. The server streams every camera's JPEG in chunks
/// tagged with the camera index; a photo is emitted whenever the index moves
/// on, when a status line follows the chunks (the next camera's "Taking a
/// high res photo"), and once at stream end — mirroring the C# KioskProcessor.
///
/// [settings] as for [startAutomaticCapture], on the server's `StartManualCapture` RPC; the
/// manual flow uses only `jpegQuality`, `glareFreeLight`, `photoLight`, `ledsOffForPhoto` and
/// `colourCorrection` and refuses any other field (INVALID_ARGUMENT). `null` = the older `StartManualProcess`.
Stream<CaptureEvent> startManualCapture({CaptureSettings? settings}) async* {
  final client = KioskClient(GrpcChannelProvider.channel);
  if (settings == null) {
    yield* manualCaptureEvents(client.startManualProcess(Empty()));
  } else {
    yield* _withOldServerError(manualCaptureEvents(
        client.startManualCapture(CaptureRequest(settings: settings))));
  }
}

/// The events of a manual capture's response stream (see [startManualCapture], which runs
/// it on the server's stream; the tests feed it messages directly).
Stream<CaptureEvent> manualCaptureEvents(
    Stream<ProcessManualResponse> messages) async* {
  final chunks = BytesBuilder(copy: false);
  var cameraIndex = 0;
  var width = 0;
  var height = 0;
  DateTime? firstChunkAt;
  DateTime? lastChunkAt;

  CameraPhoto flush() {
    final photo = CameraPhoto(cameraIndex, chunks.takeBytes(), width, height,
        firstChunkAt: firstChunkAt, lastChunkAt: lastChunkAt);
    firstChunkAt = lastChunkAt = null;
    return photo;
  }

  await for (final message in messages) {
    switch (message.whichResult()) {
      case ProcessManualResponse_Result.processStatus:
        if (chunks.length > 0) yield flush();
        yield CaptureStatus(
            message.processStatus.description, message.processStatus.status.name);
      case ProcessManualResponse_Result.imageData:
        final image = message.imageData;
        if (image.index != cameraIndex) {
          if (chunks.length > 0) yield flush();
          cameraIndex = image.index;
        }
        lastChunkAt = DateTime.now();
        firstChunkAt ??= lastChunkAt;
        chunks.add(image.chunkData);
        if (image.width != 0) width = image.width;
        if (image.height != 0) height = image.height;
      case ProcessManualResponse_Result.settingsUsed:
        // The settings the capture runs with: the first message of the stream
        // (servers with per-capture settings).
        if (chunks.length > 0) yield flush();
        yield CaptureSettingsReport(
            message.settingsUsed.values, message.settingsUsed.overridden);
      case ProcessManualResponse_Result.notSet:
        break;
    }
  }

  if (chunks.length > 0) yield flush();
}
