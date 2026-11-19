// A provisioned kiosk on the LAN twice (cable + WiFi) must appear once in
// Search. Measured 2026-10-16 on the Radxa Dragon Q6A: the service search found
// the kiosk "facesnap-00485420970d-2" (host name from the CABLE MAC, avahi
// suffix after a name conflict) at the WiFi address, and the subnet sweep found
// the cable address with the Radxa OUI and listed it again as a clean board.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/discovery.dart';

DiscoveredKiosk _kiosk(String name, String ip, {String? mac}) =>
    DiscoveredKiosk(hostName: name, ip: ip, port: 50051, mac: mac);

DiscoveredKiosk _clean(String ip, String mac) =>
    DiscoveredKiosk(hostName: 'radxa', ip: ip, kind: BoardKind.clean, mac: mac);

void main() {
  test('(a) a kiosk on WiFi hides the sweep hit of its own cable card', () {
    final merged = mergeDiscovered(
      [_kiosk('facesnap-00485420970d-2.local', '192.168.3.181')],
      [_clean('192.168.3.169', '00-48-54-20-97-0d')],
    );
    expect(merged.map((k) => k.ip), ['192.168.3.181']);
    expect(merged.single.kind, BoardKind.facesnap);
  });

  test('(b) without the avahi suffix and with an uppercase MAC: still one row', () {
    final merged = mergeDiscovered(
      [_kiosk('facesnap-00485420970d', '192.168.3.181')],
      [_clean('192.168.3.169', '00-48-54-20-97-0D')],
    );
    expect(merged.map((k) => k.hostName), ['facesnap-00485420970d']);
  });

  test('(b2) a hostname-probe hit with the kiosk MAC is dropped too', () {
    final merged = mergeDiscovered(
      [_kiosk('FACESNAP-00485420970D-12.local', '192.168.3.181')],
      [
        DiscoveredKiosk(
            hostName: 'radxa',
            ip: '192.168.3.169',
            kind: BoardKind.clean,
            mac: '00:48:54:20:97:0d'),
      ],
    );
    expect(merged, hasLength(1));
  });

  test('(c) a clean board with a different MAC stays', () {
    final merged = mergeDiscovered(
      [_kiosk('facesnap-00485420970d-2.local', '192.168.3.181')],
      [_clean('192.168.3.170', '00-48-54-aa-bb-cc')],
    );
    expect(merged.map((k) => k.ip), ['192.168.3.181', '192.168.3.170']);
  });

  test('(d) a kiosk with a hand-set name does not hide a sweep hit', () {
    final merged = mergeDiscovered(
      [_kiosk('front-door.local', '192.168.3.181')],
      [_clean('192.168.3.169', '00-48-54-20-97-0d')],
    );
    expect(merged, hasLength(2));
  });

  test('(d2) a kiosk hit that carries the MAC hides a hit with that MAC', () {
    final merged = mergeDiscovered(
      [_kiosk('front-door.local', '192.168.3.181', mac: '00-48-54-20-97-0d')],
      [_clean('192.168.3.169', '00-48-54-20-97-0D')],
    );
    expect(merged.map((k) => k.ip), ['192.168.3.181']);
  });

  test('(d3) a clean board without a MAC is never matched', () {
    final merged = mergeDiscovered(
      [_kiosk('facesnap-00485420970d.local', '192.168.3.181')],
      [DiscoveredKiosk(hostName: 'radxa', ip: '192.168.3.169', kind: BoardKind.clean)],
    );
    expect(merged, hasLength(2));
  });

  test('(e) IP de-duplication is unchanged; kiosks are never dropped', () {
    final merged = mergeDiscovered(
      [
        _kiosk('facesnap-001e0644278f.local', '10.0.0.5'),
        _kiosk('facesnap-001e0644278f-2.local', '10.0.0.6'),
      ],
      [
        DiscoveredKiosk(hostName: 'odroid', ip: '10.0.0.5', kind: BoardKind.clean),
        DiscoveredKiosk(hostName: 'odroid', ip: '10.0.0.9', kind: BoardKind.clean),
        DiscoveredKiosk(hostName: 'radxa', ip: '10.0.0.9', kind: BoardKind.clean),
      ],
    );
    expect(merged.map((k) => '${k.hostName}@${k.ip}'), [
      'facesnap-001e0644278f.local@10.0.0.5',
      'facesnap-001e0644278f-2.local@10.0.0.6',
      'odroid@10.0.0.9',
    ]);
  });

  test('(f) the Windows arp -a table gives normalised MACs per IP', () {
    const output = '''
Interface: 192.168.3.50 --- 0x7
  Internet Address      Physical Address      Type
  192.168.3.1           a4-91-b1-0c-22-10     dynamic
  192.168.3.169         00-48-54-20-97-0D     dynamic
  192.168.3.181         f4-ab-5c-32-7d-84     dynamic
  224.0.0.251           01-00-5e-00-00-fb     static
''';
    final table = parseArpTable(output);
    expect(table['192.168.3.169'], '00485420970d');
    expect(table['192.168.3.181'], 'f4ab5c327d84');
    expect(table, hasLength(4));
  });

  test('normalizeMac accepts dashes, colons and bare hex; rejects the rest', () {
    expect(normalizeMac('00-48-54-20-97-0D'), '00485420970d');
    expect(normalizeMac('00:48:54:20:97:0d'), '00485420970d');
    expect(normalizeMac('00485420970D'), '00485420970d');
    expect(normalizeMac('00-48-54'), isNull);
    expect(DiscoveredKiosk(hostName: 'x', ip: '1.2.3.4', mac: 'F4:AB:5C:32:7D:84').mac,
        'f4ab5c327d84');
  });
}
