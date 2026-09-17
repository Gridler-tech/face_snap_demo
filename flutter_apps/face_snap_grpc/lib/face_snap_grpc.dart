/// Shared gRPC client library for the FaceSnap kiosk server.
///
/// Exposes the generated clients for all six services plus the shared
/// [GrpcChannelProvider]; construct clients with
/// `SettingsClient(GrpcChannelProvider.channel)` so a runtime address change
/// is picked up without an app restart.
library;

export 'package:grpc/grpc.dart' show CallOptions, GrpcError;

export 'src/automatic_capture.dart';
export 'src/channel_provider.dart';
export 'src/generated/calibration.pbgrpc.dart';
export 'src/generated/camera.pbgrpc.dart';
export 'src/generated/kiosk.pbgrpc.dart';
export 'src/generated/lights.pbgrpc.dart';
export 'src/generated/monitoring.pbgrpc.dart';
export 'src/generated/settings.pbgrpc.dart';
// Empty comes from the protobuf runtime's bundled well-known types (the
// generated pbgrpc files import it from there too).
export 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';
