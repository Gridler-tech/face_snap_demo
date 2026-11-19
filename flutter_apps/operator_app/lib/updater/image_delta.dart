// Delta image transfer: send the kiosk only the layers it does not have yet.
//
// A `docker save` tar holds every layer of the image, but an update usually
// adds a few layers on top of the previous version's — 2.0.22 → 2.0.23 is
// 250 MB of new layers in a 2.2 GB tar. `docker load` (classic overlay2
// store) skips any layer whose chain it already has WITHOUT opening its blob,
// so a copy of the tar with those blobs left out loads to the identical
// image. Proven on Docker 29 (overlay2) before this was written:
//   - blobs removed, manifest.json + OCI index kept      → loads, same layers
//   - blobs removed, Docker-legacy manifest.json only    → loads, same layers
//   - OCI layout only (no manifest.json)                 → "invalid archive:
//     does not contain a manifest.json"
//   - a blob the daemon does NOT have left out           → "open …/blobs/
//     sha256/<digest>: no such file or directory", exit 1, nothing loaded
//   - gzip-compressed (file or stdin)                     → loads
// (builds/face_snap/updater_delta/exp_docker_load*.log.)
//
// Nothing is written to disk: [DockerSaveTar.scan] indexes the tar's entries
// (headers only), [planDelta] decides which byte ranges to send, and
// [streamRanges] reads exactly those ranges. The result is a valid tar
// (whole entries are copied verbatim, the end-of-archive blocks included).
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// A byte range [start, end) of the source tar.
class ByteRange {
  const ByteRange(this.start, this.end);
  final int start;
  final int end;
  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is ByteRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
  @override
  String toString() => '[$start, $end)';
}

/// One logical tar member: [start] is its first header block (a PAX or GNU
/// long-name header in front of it included), [end] the end of its padded
/// data.
class TarMember {
  TarMember(this.name, this.start, this.dataStart, this.size, this.end);
  final String name;
  final int start;
  final int dataStart;
  final int size;
  final int end;
}

/// The image described by a `docker save` tar.
class DockerSaveTar {
  DockerSaveTar({
    required this.members,
    required this.trailerStart,
    required this.length,
    required this.repoTags,
    required this.configPath,
    required this.layerPaths,
    required this.diffIds,
  });

  final List<TarMember> members;

  /// Offset of the end-of-archive zero blocks (copied verbatim).
  final int trailerStart;
  final int length;
  final List<String> repoTags;
  final String configPath;

  /// manifest.json "Layers": the blob path of each layer, bottom first.
  final List<String> layerPaths;

  /// The config's rootfs.diff_ids, bottom first — what the daemon reports
  /// as `.RootFS.Layers` once the image is loaded.
  final List<String> diffIds;

  /// The image ID a classic (overlay2) daemon will report (`sha256:` + the
  /// config digest), or null when the config path does not carry the digest.
  /// The containerd image store reports the manifest digest instead.
  String? get imageId {
    final base = configPath.split('/').last.replaceAll('.json', '');
    return RegExp(r'^[0-9a-f]{64}$').hasMatch(base) ? 'sha256:$base' : null;
  }

  /// Indexes [file] (headers only; manifest.json and the config are read).
  /// Throws [FormatException] when it is not a `docker save` tar with a
  /// single-image manifest.json.
  static Future<DockerSaveTar> scan(File file) async {
    final raf = await file.open();
    try {
      final length = await raf.length();
      final members = <TarMember>[];
      var pos = 0;
      var trailerStart = length;
      String? pendingName;
      int? pendingSize;
      int? pendingStart;
      while (pos + 512 <= length) {
        await raf.setPosition(pos);
        final h = await raf.read(512);
        if (h.length < 512) break;
        if (h.every((b) => b == 0)) {
          trailerStart = pos;
          break;
        }
        final type = h[156];
        final size = pendingSize ?? _parseSize(h);
        final dataStart = pos + 512;
        final end = dataStart + _roundUp(size);
        if (end > length) {
          throw const FormatException('truncated tar');
        }
        if (type == 0x78 /* x: PAX */ || type == 0x4c /* L: GNU long name */) {
          await raf.setPosition(dataStart);
          final data = await raf.read(size);
          pendingStart ??= pos;
          if (type == 0x4c) {
            pendingName = _cString(data, 0, data.length);
          } else {
            final pax = _parsePax(data);
            pendingName = pax['path'] ?? pendingName;
            final s = pax['size'];
            if (s != null) pendingSize = int.tryParse(s);
          }
          pos = end;
          continue;
        }
        final name = pendingName ?? _headerName(h);
        members.add(
            TarMember(_normalize(name), pendingStart ?? pos, dataStart, size, end));
        pendingName = null;
        pendingSize = null;
        pendingStart = null;
        pos = end;
      }

      Future<String> readMember(String name) async {
        final m = members.firstWhere((m) => m.name == name,
            orElse: () => throw FormatException('no $name in the tar'));
        await raf.setPosition(m.dataStart);
        return utf8.decode(await raf.read(m.size));
      }

      final manifest = jsonDecode(await readMember('manifest.json'));
      if (manifest is! List || manifest.length != 1) {
        throw const FormatException(
            'manifest.json does not describe exactly one image');
      }
      final entry = manifest.first as Map<String, dynamic>;
      final configPath = _normalize(entry['Config'] as String);
      final layerPaths = [
        for (final l in entry['Layers'] as List) _normalize(l as String)
      ];
      final config =
          jsonDecode(await readMember(configPath)) as Map<String, dynamic>;
      final diffIds = [
        for (final d in (config['rootfs'] as Map)['diff_ids'] as List)
          d as String
      ];
      if (diffIds.length != layerPaths.length) {
        throw FormatException('config lists ${diffIds.length} layers, '
            'manifest.json ${layerPaths.length}');
      }
      return DockerSaveTar(
        members: members,
        trailerStart: trailerStart,
        length: length,
        repoTags: [
          for (final t in (entry['RepoTags'] as List?) ?? const []) t as String
        ],
        configPath: configPath,
        layerPaths: layerPaths,
        diffIds: diffIds,
      );
    } finally {
      await raf.close();
    }
  }

  static int _roundUp(int n) => (n + 511) & ~511;

  static int _parseSize(Uint8List h) {
    if (h[124] & 0x80 != 0) {
      // GNU base-256 for sizes >= 8 GiB.
      var v = h[124] & 0x7f;
      for (var i = 125; i < 136; i++) {
        v = (v << 8) | h[i];
      }
      return v;
    }
    final s = _cString(h, 124, 136).trim();
    return s.isEmpty ? 0 : int.parse(s, radix: 8);
  }

  static String _headerName(Uint8List h) {
    final name = _cString(h, 0, 100);
    final ustar = ascii.decode(h.sublist(257, 262), allowInvalid: true) == 'ustar';
    final prefix = ustar ? _cString(h, 345, 500) : '';
    return prefix.isEmpty ? name : '$prefix/$name';
  }

  static String _cString(Uint8List b, int from, int to) {
    var end = from;
    while (end < to && b[end] != 0) {
      end++;
    }
    return utf8.decode(b.sublist(from, end), allowMalformed: true);
  }

  static Map<String, String> _parsePax(Uint8List data) {
    // Records are "<length> <key>=<value>\n"; <length> counts BYTES.
    final out = <String, String>{};
    var i = 0;
    while (i < data.length) {
      var sp = i;
      while (sp < data.length && data[sp] != 0x20) {
        sp++;
      }
      if (sp >= data.length) break;
      final len = int.tryParse(ascii.decode(data.sublist(i, sp), allowInvalid: true));
      if (len == null || len <= 0 || i + len > data.length) break;
      final record = utf8.decode(data.sublist(sp + 1, i + len - 1),
          allowMalformed: true);
      final eq = record.indexOf('=');
      if (eq > 0) out[record.substring(0, eq)] = record.substring(eq + 1);
      i += len;
    }
    return out;
  }

  static String _normalize(String name) =>
      name.startsWith('./') ? name.substring(2) : name;
}

/// What to send for one update: the whole tar, or a delta.
class DeltaPlan {
  DeltaPlan({
    required this.tar,
    required this.isDelta,
    required this.reason,
    required this.sharedLayers,
    required this.ranges,
  });

  final DockerSaveTar tar;
  final bool isDelta;

  /// Why the plan is what it is (logged).
  final String reason;

  /// Bottom layers the kiosk already has (left out of the stream).
  final int sharedLayers;
  final List<ByteRange> ranges;

  int get totalLayers => tar.diffIds.length;
  int get bytes => ranges.fold(0, (a, r) => a + r.length);

  /// A plan that streams the whole file.
  factory DeltaPlan.full(DockerSaveTar tar, String reason) => DeltaPlan(
      tar: tar,
      isDelta: false,
      reason: reason,
      sharedLayers: 0,
      ranges: [ByteRange(0, tar.length)]);
}

/// Parses the board's `docker image inspect --format '{{json .RootFS.Layers}}'`
/// output (one JSON array per image) — see [kBoardLayersCmd]. Lines that are
/// not a JSON list of strings are ignored.
List<List<String>> parseBoardLayerLists(String stdout) {
  final out = <List<String>>[];
  for (final line in const LineSplitter().convert(stdout)) {
    final t = line.trim();
    if (!t.startsWith('[')) continue;
    try {
      final list = jsonDecode(t);
      if (list is List && list.every((e) => e is String)) {
        out.add(list.cast<String>());
      }
    } on FormatException {
      // not a layer list
    }
  }
  return out;
}

/// Layer lists of every image on the kiosk, one JSON array per line.
/// Read-only. Every image counts: a layer is reused when ANY local image has
/// the same chain of layers below and including it.
const kBoardLayersCmd = 'docker image ls -q --no-trunc | sort -u | '
    "xargs -r docker image inspect --format '{{json .RootFS.Layers}}'";

/// Decides what to send. A layer can be left out when some image on the kiosk
/// has the same layers from the bottom up to and including it (docker keys
/// layers by that chain, not by the single layer). Anything unexpected falls
/// back to the whole tar.
DeltaPlan planDelta(DockerSaveTar tar, List<List<String>> boardImages) {
  final n = tar.diffIds.length;
  var shared = 0;
  for (final layers in boardImages) {
    var k = 0;
    while (k < n && k < layers.length && layers[k] == tar.diffIds[k]) {
      k++;
    }
    shared = max(shared, k);
  }
  if (boardImages.isEmpty) {
    return DeltaPlan.full(tar, 'no images on the kiosk');
  }
  if (shared == 0) {
    return DeltaPlan.full(tar, 'the kiosk has none of this image\'s layers');
  }

  // A blob can serve several positions (identical empty layers): keep it
  // when any position above the shared part needs it.
  final needed = {for (var i = shared; i < n; i++) tar.layerPaths[i]};
  final omitted = {
    for (var i = 0; i < shared; i++) tar.layerPaths[i]
  }.difference(needed);
  if (omitted.isEmpty) {
    return DeltaPlan.full(tar, 'nothing to leave out');
  }

  final ranges = <ByteRange>[];
  void add(int start, int end) {
    if (end <= start) return;
    if (ranges.isNotEmpty && ranges.last.end == start) {
      ranges[ranges.length - 1] = ByteRange(ranges.last.start, end);
    } else {
      ranges.add(ByteRange(start, end));
    }
  }

  for (final m in tar.members) {
    if (!omitted.contains(m.name)) add(m.start, m.end);
  }
  add(tar.trailerStart, tar.length);

  return DeltaPlan(
    tar: tar,
    isDelta: true,
    reason: shared == n
        ? 'the kiosk already has all $n layers'
        : 'the kiosk already has $shared of $n layers',
    sharedLayers: shared,
    ranges: ranges,
  );
}

/// Reads [ranges] of [file] in order, as one stream.
Stream<List<int>> streamRanges(File file, List<ByteRange> ranges) async* {
  for (final r in ranges) {
    yield* file.openRead(r.start, r.end);
  }
}

/// Whether the loaded image is exactly the one in the tar: the daemon's
/// `{{.Id}}|{{json .RootFS.Layers}}` output (see [kLoadedImageCheckFormat])
/// against the tar's config digest and diff IDs. Returns null when it
/// matches, else what differs.
///
/// [idIsConfigDigest]: only the classic overlay2 store reports the config
/// digest as the image ID; the containerd image store (driver "overlayfs",
/// the default on a fresh Docker 29 install) reports the manifest digest, so
/// for any other or unknown driver only the layer list is compared.
String? checkLoadedImage(DockerSaveTar tar, String inspectOutput,
    {required bool idIsConfigDigest}) {
  final line = inspectOutput.trim();
  final bar = line.indexOf('|');
  if (bar < 0) return 'unreadable image inspect output: "$line"';
  final id = line.substring(0, bar).trim();
  final layers = parseBoardLayerLists(line.substring(bar + 1));
  if (layers.isEmpty) return 'no layer list in "$line"';
  final expectedId = idIsConfigDigest ? tar.imageId : null;
  if (expectedId != null && id != expectedId) {
    return 'image ID $id, expected $expectedId';
  }
  final got = layers.first;
  if (got.length != tar.diffIds.length) {
    return '${got.length} layers, expected ${tar.diffIds.length}';
  }
  for (var i = 0; i < got.length; i++) {
    if (got[i] != tar.diffIds[i]) return 'layer ${i + 1} differs';
  }
  return null;
}

const kLoadedImageCheckFormat = "'{{.Id}}|{{json .RootFS.Layers}}'";
