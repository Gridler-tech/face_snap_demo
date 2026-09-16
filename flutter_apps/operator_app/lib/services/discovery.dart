// Network discovery of FaceSnap kiosks AND clean (not yet provisioned) boards.
//
// Shared verbatim with the updater app (client/flutter/updater_app/lib/
// discovery.dart) - keep the two copies in sync; it is deliberately self-
// contained (dart:io only) so it can be dropped into either app unchanged.
//
// (updater header continues)
//
// Provisioned kiosks announce a _facesnap._tcp service (see UpdateEngine's
// identity step) and are found with a one-shot mDNS PTR query. Clean vendor
// images announce nothing FaceSnap-specific — but they do answer for their
// stock hostname ("odroid" for Hardkernel Ubuntu, "radxa" for Radxa images),
// so discoverBoards() additionally probes those names two ways:
//   - mDNS A query for "<name>.local"  (answered by avahi, if installed)
//   - LLMNR A query for "<name>"       (answered by systemd-resolved, which
//     Ubuntu server runs by default even without avahi)
//
// Everything is a "legacy" one-shot query (RFC 6762 §6.7 / RFC 4795): sent
// from an ephemeral UDP port to the multicast group; responders reply UNICAST
// to that port. This deliberately avoids binding port 5353/5355 and joining
// multicast groups, both of which are unreliable on Windows (the
// multicast_dns package fails there with errno 10042).
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// What kind of machine answered.
enum BoardKind {
  /// A provisioned FaceSnap kiosk (announces _facesnap._tcp).
  facesnap,

  /// A clean vendor image (answers for its stock hostname); it needs to be
  /// set up by the updater (docker, compose, identity) during install.
  clean,
}

class DiscoveredKiosk {
  DiscoveredKiosk(
      {required this.hostName,
      required this.ip,
      this.port,
      this.kind = BoardKind.facesnap});

  /// mDNS host name, e.g. facesnap-001e0644278f.local — or the stock name of
  /// a clean board ("odroid" / "radxa").
  final String hostName;
  final String ip;

  /// The gRPC port from the kiosk's _facesnap._tcp SRV record; null when the
  /// machine was found another way (clean boards, hostname probes) and the
  /// caller should fall back to its own default.
  final int? port;
  final BoardKind kind;
}

/// Stock hostnames of supported boards with a clean vendor image, mapped to
/// the image's default root password (prefilled in the UI, editable).
const cleanBoardDefaults = <String, String>{
  'odroid': 'odroid', // Hardkernel Ubuntu
  'radxa': 'root', // Arch Linux ARM (root/root); Radxa Debian varies
};

/// MAC vendor prefixes (OUIs) of the supported boards, for the subnet sweep.
const _boardOuis = <String, String>{
  '00-1e-06': 'odroid', // Hardkernel
  '00-48-54': 'radxa', // Radxa
};

const _service = '_facesnap._tcp.local';
final _mdnsGroup = InternetAddress('224.0.0.251');
const _mdnsPort = 5353;
final _llmnrGroup = InternetAddress('224.0.0.252');
const _llmnrPort = 5355;

/// Provisioned kiosks only (the _facesnap._tcp service search).
Future<List<DiscoveredKiosk>> discoverKiosks(
    {Duration timeout = const Duration(seconds: 4)}) async {
  // One socket per local IPv4 address: on a multi-homed machine (WSL/Docker
  // virtual adapters next to the real NIC) the OS routes the multicast query
  // out of ONE interface only — usually the wrong one. Binding to each
  // address pins the egress interface per socket.
  final addresses = await _localAddresses();
  if (addresses.isEmpty) return const [];

  final found = <String, DiscoveredKiosk>{};
  final sockets = <RawDatagramSocket>[];
  try {
    for (final address in addresses) {
      final socket = await _bind(address);
      if (socket == null) continue;
      sockets.add(socket);
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null) return;
        try {
          for (final kiosk in _parseServiceResponse(datagram.data)) {
            found[kiosk.hostName] = kiosk;
          }
        } catch (_) {
          // Malformed or unrelated packet — ignore.
        }
      });
    }

    // Ask a few times during the window: mDNS is UDP, replies can get lost.
    final query = _buildQuery(_service, qtype: 12);
    for (var i = 0; i < 3; i++) {
      for (final socket in sockets) {
        socket.send(query, _mdnsGroup, _mdnsPort);
      }
      await Future<void>.delayed(timeout ~/ 3);
    }
  } finally {
    for (final socket in sockets) {
      socket.close();
    }
  }
  final kiosks = found.values.toList()
    ..sort((a, b) => a.hostName.compareTo(b.hostName));
  return kiosks;
}

/// Kiosks AND clean boards: the service search plus stock-hostname probes,
/// run concurrently over the same window. A machine found both ways is
/// reported once, as a kiosk.
Future<List<DiscoveredKiosk>> discoverBoards(
    {Duration timeout = const Duration(seconds: 4)}) async {
  final results = await Future.wait([
    discoverKiosks(timeout: timeout),
    probeHostnames(cleanBoardDefaults.keys.toList(), timeout: timeout),
    _sweepSubnetForBoards(),
  ]);
  final kiosks = results[0];
  final seen = kiosks.map((k) => k.ip).toSet();
  final boards = [...kiosks];
  for (final list in [results[1], results[2]]) {
    for (final board in list) {
      if (seen.add(board.ip)) boards.add(board);
    }
  }
  return boards;
}

/// Active sweep: try TCP port 22 on every host of each local /24, then match
/// the responders' MAC vendor (from the ARP table, populated as a side effect
/// of the connection attempts) against the known board OUIs. Finds clean
/// boards whose OS answers no name protocol at all. Windows-only (the
/// updater's platform); a no-op elsewhere.
Future<List<DiscoveredKiosk>> _sweepSubnetForBoards() async {
  if (!Platform.isWindows) return const [];
  final addresses = await _localAddresses();
  final subnets = {
    for (final a in addresses)
      a.address.substring(0, a.address.lastIndexOf('.')),
  };
  if (subnets.isEmpty) return const [];

  // Port-22 connect attempts, ~64 at a time; a successful connect also means
  // SSH is up, which is exactly what the updater needs next.
  final open = <String>{};
  for (final subnet in subnets) {
    final hosts = [for (var i = 1; i < 255; i++) '$subnet.$i'];
    for (var start = 0; start < hosts.length; start += 64) {
      final chunk = hosts.skip(start).take(64);
      await Future.wait(chunk.map((ip) async {
        try {
          final socket = await Socket.connect(ip, 22,
              timeout: const Duration(milliseconds: 500));
          socket.destroy();
          open.add(ip);
        } catch (_) {/* closed or absent */}
      }));
    }
  }
  if (open.isEmpty) return const [];

  // MAC per IP from the ARP table.
  final arp = await Process.run('arp', ['-a']);
  final macByIp = <String, String>{};
  for (final match in RegExp(
          r'(\d+\.\d+\.\d+\.\d+)\s+([0-9a-fA-F-]{17})')
      .allMatches(arp.stdout as String)) {
    macByIp[match.group(1)!] = match.group(2)!.toLowerCase();
  }

  final boards = <DiscoveredKiosk>[];
  for (final ip in open) {
    final mac = macByIp[ip];
    if (mac == null) continue;
    final stock = _boardOuis[mac.substring(0, 8)];
    if (stock != null) {
      boards.add(
          DiscoveredKiosk(hostName: stock, ip: ip, kind: BoardKind.clean));
    }
  }
  boards.sort((a, b) => a.ip.compareTo(b.ip));
  return boards;
}

/// Probe hostnames via mDNS (`name.local`, answered by avahi) and
/// LLMNR (bare `name`, answered by systemd-resolved). Both are DNS-format A
/// queries; replies come back unicast to our ephemeral port. Public so the
/// discover CLI can probe arbitrary names for diagnostics.
Future<List<DiscoveredKiosk>> probeHostnames(List<String> names,
    {Duration timeout = const Duration(seconds: 4)}) async {
  final addresses = await _localAddresses();
  if (addresses.isEmpty) return const [];

  final found = <String, DiscoveredKiosk>{}; // name -> board
  final sockets = <RawDatagramSocket>[];
  try {
    for (final address in addresses) {
      final socket = await _bind(address);
      if (socket == null) continue;
      sockets.add(socket);
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null) return;
        try {
          for (final (name, ip) in _parseARecords(datagram.data)) {
            // "odroid.local" and "odroid" both map to the stock name.
            final stock = name.endsWith('.local')
                ? name.substring(0, name.length - 6)
                : name;
            if (names.contains(stock)) {
              found[stock] = DiscoveredKiosk(
                  hostName: stock, ip: ip, kind: BoardKind.clean);
            }
          }
        } catch (_) {
          // Malformed or unrelated packet — ignore.
        }
      });
    }

    final queries = <(Uint8List, InternetAddress, int)>[
      for (final name in names) ...[
        (_buildQuery('$name.local', qtype: 1), _mdnsGroup, _mdnsPort),
        (_buildQuery(name, qtype: 1), _llmnrGroup, _llmnrPort),
      ],
    ];
    for (var i = 0; i < 3; i++) {
      for (final socket in sockets) {
        for (final (query, group, port) in queries) {
          socket.send(query, group, port);
        }
      }
      await Future<void>.delayed(timeout ~/ 3);
    }
  } finally {
    for (final socket in sockets) {
      socket.close();
    }
  }
  final boards = found.values.toList()
    ..sort((a, b) => a.hostName.compareTo(b.hostName));
  return boards;
}

Future<List<InternetAddress>> _localAddresses() async {
  final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4, includeLoopback: false);
  return [for (final interface in interfaces) ...interface.addresses];
}

Future<RawDatagramSocket?> _bind(InternetAddress address) async {
  try {
    return await RawDatagramSocket.bind(address, 0);
  } catch (_) {
    return null; // interface without UDP bind support — skip
  }
}

/// DNS-format query: works for mDNS (PTR/A) and LLMNR (A) alike.
Uint8List _buildQuery(String name, {required int qtype}) {
  final builder = BytesBuilder();
  // Header: random ID (legacy query), flags 0, QDCOUNT 1.
  final id = Random().nextInt(0xFFFF);
  builder.add([id >> 8, id & 0xFF, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]);
  for (final label in name.split('.')) {
    final bytes = label.codeUnits;
    builder.addByte(bytes.length);
    builder.add(bytes);
  }
  builder.addByte(0);
  builder.add([0, qtype, 0, 1]); // QTYPE, QCLASS IN
  return builder.toBytes();
}

/// Extract kiosks from one mDNS response: SRV records under the _facesnap
/// service give the host name; A records give that host's address (avahi
/// includes both in its answer/additional sections).
Iterable<DiscoveredKiosk> _parseServiceResponse(Uint8List data) sync* {
  final view = ByteData.sublistView(data);
  if (data.length < 12) return;
  final isResponse = (view.getUint16(2) & 0x8000) != 0;
  if (!isResponse) return;
  final counts = [
    view.getUint16(4), // questions
    view.getUint16(6) + view.getUint16(8) + view.getUint16(10), // records
  ];

  var offset = 12;
  for (var q = 0; q < counts[0]; q++) {
    offset = _skipName(data, offset) + 4;
  }

  final srvPorts = <String, int>{}; // SRV target -> announced gRPC port
  final addresses = <String, String>{};
  for (var r = 0; r < counts[1]; r++) {
    final name = _readName(data, offset);
    offset = _skipName(data, offset);
    final type = view.getUint16(offset);
    final rdLength = view.getUint16(offset + 8);
    final rdataOffset = offset + 10;
    if (type == 33 && name.value.endsWith(_service)) {
      // SRV: priority(2) weight(2) port(2) target(name)
      srvPorts[_readName(data, rdataOffset + 6).value] =
          view.getUint16(rdataOffset + 4);
    } else if (type == 1 && rdLength == 4) {
      addresses[name.value] =
          '${data[rdataOffset]}.${data[rdataOffset + 1]}.'
          '${data[rdataOffset + 2]}.${data[rdataOffset + 3]}';
    }
    offset = rdataOffset + rdLength;
  }

  for (final entry in srvPorts.entries) {
    final ip = addresses[entry.key];
    if (ip != null) {
      yield DiscoveredKiosk(
          hostName: entry.key,
          ip: ip,
          port: entry.value > 0 ? entry.value : null);
    }
  }
}

/// All (name, IPv4) pairs from the A records of one DNS-format response —
/// used for the hostname probes, where the response only ever describes the
/// name we asked about.
Iterable<(String, String)> _parseARecords(Uint8List data) sync* {
  final view = ByteData.sublistView(data);
  if (data.length < 12) return;
  final isResponse = (view.getUint16(2) & 0x8000) != 0;
  if (!isResponse) return;
  final questions = view.getUint16(4);
  final records =
      view.getUint16(6) + view.getUint16(8) + view.getUint16(10);

  var offset = 12;
  for (var q = 0; q < questions; q++) {
    offset = _skipName(data, offset) + 4;
  }
  for (var r = 0; r < records; r++) {
    final name = _readName(data, offset);
    offset = _skipName(data, offset);
    final type = view.getUint16(offset);
    final rdLength = view.getUint16(offset + 8);
    final rdataOffset = offset + 10;
    if (type == 1 && rdLength == 4) {
      yield (
        name.value,
        '${data[rdataOffset]}.${data[rdataOffset + 1]}.'
            '${data[rdataOffset + 2]}.${data[rdataOffset + 3]}'
      );
    }
    offset = rdataOffset + rdLength;
  }
}

class _Name {
  _Name(this.value);
  final String value;
}

_Name _readName(Uint8List data, int offset, [int depth = 0]) {
  if (depth > 8) return _Name('');
  final labels = <String>[];
  var i = offset;
  while (i < data.length) {
    final length = data[i];
    if (length == 0) break;
    if ((length & 0xC0) == 0xC0) {
      final pointer = ((length & 0x3F) << 8) | data[i + 1];
      labels.add(_readName(data, pointer, depth + 1).value);
      return _Name(labels.join('.'));
    }
    labels.add(String.fromCharCodes(data.sublist(i + 1, i + 1 + length)));
    i += 1 + length;
  }
  return _Name(labels.join('.'));
}

int _skipName(Uint8List data, int offset) {
  var i = offset;
  while (i < data.length) {
    final length = data[i];
    if (length == 0) return i + 1;
    if ((length & 0xC0) == 0xC0) return i + 2;
    i += 1 + length;
  }
  return i;
}
