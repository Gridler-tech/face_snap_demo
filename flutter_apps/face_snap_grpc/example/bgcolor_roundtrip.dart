// Round-trip check for SetBackgroundColor against a live server:
// read -> set DDDDDD -> read back -> restore original -> read again.
import 'package:face_snap_grpc/face_snap_grpc.dart';

Future<void> main(List<String> args) async {
  final host = args.isNotEmpty ? args[0] : 'localhost';
  await GrpcChannelProvider.setAddress(host, 50051);
  final client = SettingsClient(GrpcChannelProvider.channel);

  final before = (await client.loadSettings(Empty())).backgroundColor;
  print('before: $before');

  await client.setBackgroundColor(BackgroundColorRequest(color: 'DDDDDD'));
  final after = (await client.loadSettings(Empty())).backgroundColor;
  print('after set DDDDDD: $after');

  await client.setBackgroundColor(BackgroundColorRequest(color: before));
  final restored = (await client.loadSettings(Empty())).backgroundColor;
  print('restored: $restored');

  print(after == 'DDDDDD' && restored == before ? 'ROUNDTRIP-OK' : 'ROUNDTRIP-FAILED');

}
