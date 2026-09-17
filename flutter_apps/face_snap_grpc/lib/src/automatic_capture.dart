import 'dart:typed_data';

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
/// the server works and, when the capture succeeds, one [CapturePhoto]
/// (the server streams the JPEG in chunks; they are assembled here, mirroring
/// the C# KioskProcessor). No photo event = the flow ended without a photo.
///
/// The photo is emitted as soon as its last chunk is known to have arrived:
/// either when the next status line follows the chunks (the OFIQ report is
/// scored AFTER the photo is delivered, so the caller gets the image ~2 s
/// before the score rows instead of after them) or at stream end.
Stream<CaptureEvent> startAutomaticCapture() async* {
  final client = KioskClient(GrpcChannelProvider.channel);
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

  await for (final message in client.startAutomaticProcess(Empty())) {
    switch (message.whichResult()) {
      case ProcessAutomaticResponse_Result.processStatus:
        if (chunks.length > 0) yield flush();
        yield CaptureStatus(
            message.processStatus.description, message.processStatus.status.name);
      case ProcessAutomaticResponse_Result.imageData:
        lastChunkAt = DateTime.now();
        firstChunkAt ??= lastChunkAt;
        chunks.add(message.imageData.chunkData);
        if (message.imageData.width != 0) width = message.imageData.width;
        if (message.imageData.height != 0) height = message.imageData.height;
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
Stream<CaptureEvent> startManualCapture() async* {
  final client = KioskClient(GrpcChannelProvider.channel);
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

  await for (final message in client.startManualProcess(Empty())) {
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
      case ProcessManualResponse_Result.notSet:
        break;
    }
  }

  if (chunks.length > 0) yield flush();
}
