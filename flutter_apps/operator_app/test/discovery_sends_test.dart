// A query send the OS refuses must not end the kiosk search. On macOS an app
// without the Local Network permission gets "No route to host" (errno 65) for
// every multicast send; uncaught, that threw out of the whole scan.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/discovery.dart';

/// A socket whose send behaves like macOS without the Local Network permission
/// (refuses) or like a working interface.
class _Socket implements RawDatagramSocket {
  _Socket({required this.refuses});

  final bool refuses;
  int sends = 0;

  @override
  int send(List<int> buffer, InternetAddress address, int port) {
    sends++;
    if (refuses) {
      throw const SocketException('Send failed',
          osError: OSError('No route to host', 65));
    }
    return buffer.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final group = InternetAddress('224.0.0.251');

  test('a refused send is counted, not thrown, and every refusal means blocked', () {
    final sends = QuerySends();
    final socket = _Socket(refuses: true);
    sends.send(socket, [0, 1], group, 5353);
    sends.send(socket, [0, 1], group, 5353);
    expect(socket.sends, 2);
    expect(sends.refused, 2);
    expect(sends.sent, 0);
    expect(sends.blocked, isTrue);
  });

  test('one working interface is enough: the search is not blocked', () {
    final sends = QuerySends();
    sends.send(_Socket(refuses: true), [0], group, 5353);
    sends.send(_Socket(refuses: false), [0], group, 5353);
    expect(sends.refused, 1);
    expect(sends.sent, 1);
    expect(sends.blocked, isFalse);
  });

  test('no interface at all (offline) is not reported as blocked', () {
    expect(QuerySends().blocked, isFalse);
  });
}
