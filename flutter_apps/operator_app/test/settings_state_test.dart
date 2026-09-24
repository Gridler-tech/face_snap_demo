// Pages remember which server their rows came from via serverKey and reload
// when it changes. The key must follow the shared channel's address — not the
// saved config — because that is what the pages actually talk to.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/settings_state.dart';

void main() {
  test('serverKey follows the shared channel address', () async {
    await GrpcChannelProvider.setAddress('facesnap-a.local', 50051);
    expect(SettingsState.serverKey, 'facesnap-a.local:50051');

    await GrpcChannelProvider.setAddress('facesnap-b.local', 50051);
    expect(SettingsState.serverKey, 'facesnap-b.local:50051');

    // Same host, different port is a different server too.
    await GrpcChannelProvider.setAddress('facesnap-b.local', 50052);
    expect(SettingsState.serverKey, 'facesnap-b.local:50052');
  });
}
