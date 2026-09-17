# face_snap_grpc

The Dart client SDK for the FaceSnap kiosk server — the same package the FaceSnap
operator app is built on.

- `lib/src/generated/` — gRPC stubs for the six services (Kiosk, Settings, Camera,
  Lights, Calibration, Monitoring), generated with `protoc` + `protoc_plugin` from the
  server's `.proto` contract. They are committed, so no code generation is needed to
  use the package.
- `lib/src/channel_provider.dart` — `GrpcChannelProvider`: one shared `ClientChannel`
  for all clients; `setAddress(host, port)` switches servers at runtime.
- `lib/src/automatic_capture.dart` — `startAutomaticCapture()` / `startManualCapture()`:
  the kiosk's capture streams as `Stream<CaptureEvent>` (`CaptureStatus` lines,
  `CapturePhoto` / per-camera `CameraPhoto` with the JPEG chunks already assembled).
- `example/` — small command-line tools against a live server, e.g.
  `probe.dart` (connect + load settings) and `capture_once.dart` (one automatic
  capture, saves the photo).

## Use

```yaml
dependencies:
  face_snap_grpc:
    path: ../face_snap_grpc   # relative to your pubspec.yaml
```

```
dart pub get
dart run example/probe.dart <server> [port]
dart run example/capture_once.dart <server> photo.jpg [port]
```

The server listens for plain-text HTTP/2 (h2c) gRPC on port 50051 by default. The
getting-started guide and API reference at https://gridler-tech.github.io/face_snap/
are written for the C# SDK; its methods map one-to-one onto the RPCs of the Dart
service clients here.
