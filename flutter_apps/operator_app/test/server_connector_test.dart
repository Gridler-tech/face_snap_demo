// The identity key that keeps one board from appearing twice in the server
// list. mDNS appends "-2" when a name is re-registered (a board re-joining on
// Wi-Fi did exactly that today), so rows must key on the base name — but the
// counter is 1–2 digits and a MAC can be all decimal digits, so the strip
// must be bounded or it would eat a whole name.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/discovery.dart';
import 'package:operator_app/services/server_connector.dart';

DiscoveredKiosk k(String name, String ip) =>
    DiscoveredKiosk(hostName: name, ip: ip);

/// A loopback port with nothing listening on it: bound, then released.
Future<int> deadPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

void main() {
  group('connectTo', () {
    // FL-3: connectTo points the SHARED channel at the new address before it
    // proves the server answers. A failed connect must put the channel back on
    // the server the app still shows as connected, and still fail the caller.
    test('a failed connect restores the previous address and rethrows', () async {
      // The old server is never called: setAddress and the channel getter do
      // not connect, so any address will do.
      const oldHost = '10.255.0.1', oldPort = 50051;
      await GrpcChannelProvider.setAddress(oldHost, oldPort);
      GrpcChannelProvider.channel; // the old server's channel is live

      final badPort = await deadPort();
      await expectLater(connectTo('127.0.0.1', badPort), throwsA(isA<GrpcError>()));

      expect(GrpcChannelProvider.host, oldHost);
      expect(GrpcChannelProvider.port, oldPort);
    });
  });

  group('baseName', () {
    test('strips .local', () {
      expect(baseName('facesnap-001e064358ca.local'), 'facesnap-001e064358ca');
    });

    test('strips the mDNS re-registration counter', () {
      expect(baseName('facesnap-00485420970d-2.local'),
          'facesnap-00485420970d');
      expect(baseName('facesnap-00485420970d-12.local'),
          'facesnap-00485420970d');
    });

    test('an all-digit MAC is NOT mistaken for a counter', () {
      // 00:12:06:43:58:12 -> 12 decimal digits; must survive intact.
      expect(baseName('facesnap-001206435812.local'), 'facesnap-001206435812');
    });

    test('names without either are untouched', () {
      expect(baseName('This PC'), 'This PC');
      expect(baseName('odroid'), 'odroid');
      expect(baseName('radxa'), 'radxa');
    });
  });

  group('dedupeDiscovered', () {
    test('one board on two interfaces (same name, two addresses) is one row', () {
      // The Radxa on Ethernet + Wi-Fi announces its (re-registered) name on both.
      final out = dedupeDiscovered([
        k('facesnap-00485420970d-2.local', '192.168.3.169'),
        k('facesnap-00485420970d-2.local', '192.168.3.181'),
        k('facesnap-001e064358ca.local', '192.168.3.167'),
      ]);
      expect(out.map((e) => e.hostName), [
        'facesnap-00485420970d-2.local',
        'facesnap-001e064358ca.local',
      ]);
    });

    test('a re-registered duplicate at the same address collapses', () {
      final out = dedupeDiscovered([
        k('facesnap-00485420970d.local', '192.168.3.169'),
        k('facesnap-00485420970d-2.local', '192.168.3.169'),
      ]);
      expect(out.map((e) => e.hostName), ['facesnap-00485420970d.local']);
    });

    test('clones of one golden image are separate boards, not one', () {
      // Six boards flashed from the same eMMC image all boot as the donor's
      // name; mDNS conflict resolution suffixes the later ones. Each has its
      // own address and must get its own row (2026-09-24: six were updated
      // one by one because the list showed one).
      final out = dedupeDiscovered([
        k('facesnap-001e064358ca.local', '192.168.3.192'),
        k('facesnap-001e064358ca-2.local', '192.168.3.193'),
        k('facesnap-001e064358ca-3.local', '192.168.3.194'),
      ]);
      expect(out, hasLength(3));
    });

    test('distinct boards all survive', () {
      final out = dedupeDiscovered([
        k('facesnap-a.local', '10.0.0.1'),
        k('facesnap-b.local', '10.0.0.2'),
      ]);
      expect(out, hasLength(2));
    });

    test('empty in, empty out', () {
      expect(dedupeDiscovered(const []), isEmpty);
    });
  });
}
