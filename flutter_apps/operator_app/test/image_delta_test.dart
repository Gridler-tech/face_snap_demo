// Delta image updates (image_delta.dart / image_install.dart): the planner
// leaves out exactly the layers the kiosk already has, the stream is a valid
// tar that a docker-like daemon loads to the identical image, and every case
// where a delta is not possible or does not load falls back to the whole tar.
//
// FakeDocker below applies docker load's real rule (moby tarexport, checked
// on Docker 29 overlay2 — builds/face_snap/updater_delta/exp_docker_load*.log):
// a layer whose chain the daemon already has is skipped WITHOUT opening its
// blob; a missing chain needs the blob, else "no such file or directory".
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/updater/image_delta.dart';
import 'package:operator_app/updater/image_install.dart';
import 'package:operator_app/updater/kiosk.dart';
import 'package:operator_app/updater/server_port.dart';
import 'package:operator_app/updater/update_engine.dart';

// ---------------------------------------------------------------- tar + image

String _hex(String seed) {
  final b = StringBuffer();
  for (final c in utf8.encode(seed)) {
    b.write(c.toRadixString(16).padLeft(2, '0'));
  }
  return b.toString().padRight(64, '0').substring(0, 64);
}

Uint8List _octal(int value, int width) {
  final s = value.toRadixString(8).padLeft(width - 1, '0');
  return Uint8List.fromList([...ascii.encode(s), 0]);
}

Uint8List _header(String name, int size, int type) {
  final h = Uint8List(512);
  final n = utf8.encode(name);
  h.setRange(0, n.length > 100 ? 100 : n.length, n);
  h.setRange(100, 108, _octal(0x1a4, 8));
  h.setRange(124, 136, _octal(size, 12));
  h.setRange(136, 148, _octal(0, 12));
  h[156] = type;
  h.setRange(257, 263, ascii.encode('ustar\x00'));
  h.setRange(263, 265, ascii.encode('00'));
  h.fillRange(148, 156, 0x20);
  final sum = h.fold<int>(0, (a, b) => a + b);
  h.setRange(148, 155, _octal(sum, 7));
  return h;
}

/// A ustar archive; names in [paxFor] get a PAX `path` record in front.
Uint8List buildTar(List<(String, List<int>)> entries,
    {Set<String> paxFor = const {}}) {
  final out = BytesBuilder();
  void member(String name, List<int> data, int type) {
    out.add(_header(name, data.length, type));
    out.add(data);
    out.add(Uint8List((512 - data.length % 512) % 512));
  }

  for (final (name, data) in entries) {
    if (paxFor.contains(name)) {
      final rec = ' path=$name\n';
      var len = rec.length + 2;
      if ('$len'.length + rec.length != len) len++;
      member('PaxHeaders/x', utf8.encode('$len$rec'), 0x78);
      member('truncated-name', data, 0x30);
    } else {
      member(name, data, name.endsWith('/') ? 0x35 : 0x30);
    }
  }
  out.add(Uint8List(1024));
  return out.takeBytes();
}

class TestImage {
  TestImage(this.tag, this.layers);
  final String tag;

  /// Layer seeds, bottom first; equal seeds = identical layer blob.
  final List<String> layers;

  String diffId(int i) => 'sha256:${_hex(layers[i])}';
  List<String> get diffIds => [for (var i = 0; i < layers.length; i++) diffId(i)];
  String blob(int i) => 'blobs/sha256/${_hex(layers[i])}';
  String get configHex => _hex('config $tag');
  String get id => 'sha256:$configHex';

  static List<int> content(String seed) =>
      List<int>.filled(1000 + seed.length * 37, seed.codeUnitAt(0));

  Uint8List tar({Set<String> paxFor = const {}}) {
    final config = utf8.encode(jsonEncode({
      'architecture': 'arm64',
      'rootfs': {'type': 'layers', 'diff_ids': diffIds},
    }));
    final manifest = utf8.encode(jsonEncode([
      {
        'Config': 'blobs/sha256/$configHex',
        'RepoTags': [tag],
        'Layers': [for (var i = 0; i < layers.length; i++) blob(i)],
      }
    ]));
    final blobs = <String, List<int>>{
      for (var i = 0; i < layers.length; i++) blob(i): content(layers[i]),
      'blobs/sha256/$configHex': config,
    };
    return buildTar([
      ('blobs/', <int>[]),
      ('blobs/sha256/', <int>[]),
      for (final e in blobs.entries) (e.key, e.value),
      ('index.json', utf8.encode('{"schemaVersion":2,"manifests":[]}')),
      ('manifest.json', manifest),
      ('oci-layout', utf8.encode('{"imageLayoutVersion":"1.0.0"}')),
    ], paxFor: paxFor);
  }
}

Map<String, Uint8List> readTar(Uint8List bytes) {
  final out = <String, Uint8List>{};
  var pos = 0;
  String? paxName;
  while (pos + 512 <= bytes.length) {
    final h = bytes.sublist(pos, pos + 512);
    if (h.every((b) => b == 0)) break;
    var end = 0;
    while (end < 100 && h[end] != 0) {
      end++;
    }
    final name = utf8.decode(h.sublist(0, end));
    final size = int.parse(
        ascii.decode(h.sublist(124, 135)).replaceAll('\x00', '').trim(),
        radix: 8);
    final data = bytes.sublist(pos + 512, pos + 512 + size);
    pos += 512 + ((size + 511) & ~511);
    if (h[156] == 0x78) {
      paxName = RegExp(r'path=(.*)\n').firstMatch(utf8.decode(data))!.group(1);
      continue;
    }
    out[paxName ?? name] = data;
    paxName = null;
  }
  return out;
}

// ---------------------------------------------------------------- fake docker

class FakeDocker {
  /// Layer chains present ("diffId1/diffId2/..."), as docker keys them.
  final chains = <String>{};
  final images = <String, ({String id, List<String> layers})>{};
  String driver = 'overlay2';
  bool layerListFails = false;

  /// What `docker image inspect` reports, when a test wants it to lie.
  List<String>? tamperedLayers;

  /// The next this-many loads fail (docker load exits 1), e.g. a full disk.
  int failNextLoads = 0;

  /// Per load: bytes received (wire), tar bytes after any gunzip.
  final loads = <({int bytes, int tarBytes, bool gzip, bool ok})>[];

  void add(TestImage image) {
    for (var i = 1; i <= image.layers.length; i++) {
      chains.add(image.diffIds.sublist(0, i).join('/'));
    }
    images[image.tag] = (id: image.id, layers: image.diffIds);
  }

  void removeImage(String tag) {
    images.remove(tag);
    chains.clear();
    for (final img in images.values) {
      for (var i = 1; i <= img.layers.length; i++) {
        chains.add(img.layers.sublist(0, i).join('/'));
      }
    }
  }

  CmdResult load(Uint8List input) {
    final gz = input.length > 2 && input[0] == 0x1f && input[1] == 0x8b;
    final bytes = gz ? Uint8List.fromList(gzip.decode(input)) : input;
    final files = readTar(bytes);
    CmdResult fail(String msg) {
      loads.add((bytes: input.length, tarBytes: bytes.length, gzip: gz, ok: false));
      return CmdResult(1, '', msg);
    }

    if (failNextLoads > 0) {
      failNextLoads--;
      return fail('write /var/lib/docker/tmp/docker-import-1/blobs: '
          'no space left on device');
    }
    final manifestBytes = files['manifest.json'];
    if (manifestBytes == null) {
      return fail('invalid archive: does not contain a manifest.json');
    }
    final m = (jsonDecode(utf8.decode(manifestBytes)) as List).first as Map;
    final configPath = m['Config'] as String;
    final config = jsonDecode(utf8.decode(files[configPath]!)) as Map;
    final diffIds = ((config['rootfs'] as Map)['diff_ids'] as List).cast<String>();
    final layerPaths = (m['Layers'] as List).cast<String>();
    final newChains = <String>[];
    for (var i = 0; i < diffIds.length; i++) {
      final chain = diffIds.sublist(0, i + 1).join('/');
      if (chains.contains(chain)) continue;
      if (!files.containsKey(layerPaths[i])) {
        return fail('open /var/lib/docker/tmp/docker-import-1/'
            '${layerPaths[i]}: no such file or directory');
      }
      newChains.add(chain);
    }
    chains.addAll(newChains);
    final tag = (m['RepoTags'] as List).first as String;
    images[tag] = (
      // The classic store's image ID is the config digest; the containerd
      // image store (driver "overlayfs", Docker 29's default on a fresh
      // install) reports the manifest/index digest instead.
      id: driver == 'overlay2'
          ? 'sha256:${configPath.split('/').last}'
          : 'sha256:${_hex('index $tag')}',
      layers: diffIds,
    );
    loads.add((bytes: input.length, tarBytes: bytes.length, gzip: gz, ok: true));
    return CmdResult(0, 'Loaded image: $tag\n', '');
  }
}

/// SshRunner stand-in: the docker commands of the installer go to
/// [docker]; everything else is answered by [answer] (default: ok, empty)
/// and recorded in [commands].
class FakeSsh implements SshRunner {
  FakeSsh(this.docker, {this.answer});
  final FakeDocker docker;
  final CmdResult? Function(String command)? answer;
  final commands = <String>[];

  @override
  Future<CmdResult> run(String command,
      {Duration timeout = const Duration(minutes: 3)}) async {
    commands.add(command);
    if (command == "docker info --format '{{.Driver}}'") {
      return CmdResult(0, '${docker.driver}\n', '');
    }
    if (command == kBoardLayersCmd) {
      if (docker.layerListFails) return CmdResult(1, '', 'permission denied');
      return CmdResult(
          0,
          docker.images.values.map((i) => jsonEncode(i.layers)).join('\n'),
          '');
    }
    if (command.startsWith('docker image inspect --format ')) {
      final img = docker.images[command.split(' ').last];
      if (img == null) return CmdResult(1, '', 'No such image');
      return CmdResult(
          0, '${img.id}|${jsonEncode(docker.tamperedLayers ?? img.layers)}\n', '');
    }
    final rmi = RegExp(r'^docker rmi (\S+)$').firstMatch(command);
    if (rmi != null) docker.removeImage(rmi.group(1)!);
    return answer?.call(command) ?? CmdResult(0, '', '');
  }

  @override
  Future<CmdResult> runChecked(String command,
      {Duration timeout = const Duration(minutes: 3)}) async {
    final r = await run(command, timeout: timeout);
    if (!r.ok) throw Exception('Command failed: $command');
    return r;
  }

  @override
  Future<CmdResult> runWithStreamStdin(String command, Stream<List<int>> data,
      {void Function(int sentBytes)? onProgress,
      Converter<List<int>, List<int>>? encoder}) async {
    commands.add(command);
    var sent = 0;
    Stream<List<int>> s = data.map((c) {
      sent += c.length;
      onProgress?.call(sent);
      return c;
    });
    if (encoder != null) s = s.transform(encoder);
    final b = BytesBuilder();
    await for (final c in s) {
      b.add(c);
    }
    expect(command, 'docker load');
    return docker.load(b.takeBytes());
  }

  @override
  Future<CmdResult> runWithFileStdin(String command, File file,
          {void Function(int sentBytes)? onProgress}) =>
      runWithStreamStdin(command, file.openRead(), onProgress: onProgress);

  /// Remote files written: path → content (last wins).
  final writes = <String, String>{};

  @override
  Future<void> writeRemoteFile(String path, String content) async {
    commands.add('write $path');
    writes[path] = content;
  }

  @override
  Future<SSHSocket> forwardLocal(String host, int port) =>
      throw UnimplementedError('no port forward in this fake');

  @override
  Future<void> downloadFile(String remotePath, String localPath) async {}

  @override
  void close() {}
}

// ---------------------------------------------------------------- the tests

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('delta_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  File writeTar(TestImage image, {Set<String> paxFor = const {}}) =>
      File('${tmp.path}/face_snap-${image.tag.split(':').last}.tar')
        ..writeAsBytesSync(image.tar(paxFor: paxFor));

  /// An installer on [ssh] with [free] bytes free on the kiosk's docker disk.
  ImageInstaller installerFor(FakeSsh ssh, File tar,
          {void Function(String line)? log,
          bool compress = kGzipImageStream,
          int free = 16 * 1000 * 1000 * 1000}) =>
      ImageInstaller(
          ssh: () => ssh,
          tarFile: tar,
          log: log ?? (_) {},
          freeSpace: () async => free,
          compress: compress);

  // 2.0.22 = 5 layers (one of them the empty layer); 2.0.23 = the same 5 +
  // 3 new ones, one of which is the empty layer again.
  final v22 = TestImage('facesnap2:2.0.22-arm64',
      ['base', 'python', 'empty', 'models', 'app22']);
  final v23 = TestImage('facesnap2:2.0.23-arm64',
      ['base', 'python', 'empty', 'models', 'app22', 'app23', 'empty', 'cfg']);

  group('planDelta', () {
    test('sends only the layers above what the kiosk has', () async {
      final file = writeTar(v23);
      final tar = await DockerSaveTar.scan(file);
      expect(tar.diffIds, v23.diffIds);
      expect(tar.imageId, v23.id);
      final plan = planDelta(tar, [v22.diffIds]);
      expect(plan.isDelta, isTrue);
      expect(plan.sharedLayers, 5);
      expect(plan.reason, 'the kiosk already has 5 of 8 layers');

      final sent = readTar(Uint8List.fromList(
          await streamRanges(file, plan.ranges).expand((c) => c).toList()));
      // Left out: base, python, models, app22. Kept: the empty layer (an
      // upper position needs the same blob), the new layers, config, manifest.
      for (final i in [0, 1, 3, 4]) {
        expect(sent.containsKey(v23.blob(i)), isFalse, reason: v23.layers[i]);
      }
      for (final i in [2, 5, 7]) {
        expect(sent.containsKey(v23.blob(i)), isTrue, reason: v23.layers[i]);
      }
      expect(sent.containsKey('manifest.json'), isTrue);
      expect(sent.containsKey('blobs/sha256/${v23.configHex}'), isTrue);
      final left = {for (final i in [0, 1, 3, 4]) v23.blob(i)};
      final omitted = tar.members
          .where((m) => left.contains(m.name))
          .fold<int>(0, (a, m) => a + m.end - m.start);
      expect(plan.bytes, tar.length - omitted);
    });

    test('a layer only counts when the chain below it matches', () async {
      final tar = await DockerSaveTar.scan(writeTar(v23));
      // Same 'python' layer but on another base: docker cannot reuse it.
      final other = TestImage('x:1', ['otherbase', 'python', 'empty']);
      final plan = planDelta(tar, [other.diffIds]);
      expect(plan.isDelta, isFalse);
      expect(plan.reason, contains('none of this image'));
      expect(plan.ranges, [ByteRange(0, tar.length)]);
    });

    test('the best of several images on the kiosk wins', () async {
      final tar = await DockerSaveTar.scan(writeTar(v23));
      final old = TestImage('facesnap2:2.0.9-arm64', ['base', 'python']);
      final plan = planDelta(tar, [old.diffIds, v22.diffIds]);
      expect(plan.sharedLayers, 5);
    });

    test('clean board / other version line fall back to the whole tar',
        () async {
      final tar = await DockerSaveTar.scan(writeTar(v23));
      expect(planDelta(tar, []).isDelta, isFalse);
      expect(planDelta(tar, []).reason, 'no images on the kiosk');
      expect(planDelta(tar, [TestImage('y:1', ['zzz']).diffIds]).isDelta,
          isFalse);
      expect(planDelta(tar, []).bytes, tar.length);
    });

    test('same image already present: only config + manifest go', () async {
      final tar = await DockerSaveTar.scan(writeTar(v23));
      final plan = planDelta(tar, [v23.diffIds]);
      expect(plan.isDelta, isTrue);
      expect(plan.reason, 'the kiosk already has all 8 layers');
      // Directories, config, index.json, manifest.json, oci-layout, the
      // end-of-archive blocks — no layer blob.
      expect(plan.bytes, lessThan(8 * 1024));
    });

    test('PAX path headers are dropped together with their member', () async {
      final file = writeTar(v23, paxFor: {v23.blob(0), v23.blob(5)});
      final tar = await DockerSaveTar.scan(file);
      expect(tar.members.map((m) => m.name), contains(v23.blob(0)));
      final plan = planDelta(tar, [v22.diffIds]);
      final bytes = Uint8List.fromList(
          await streamRanges(file, plan.ranges).expand((c) => c).toList());
      final sent = readTar(bytes);
      expect(sent.containsKey(v23.blob(0)), isFalse);
      expect(sent.containsKey(v23.blob(5)), isTrue);
      expect(sent.containsKey('truncated-name'), isFalse);
    });

    test('board layer lists: junk lines are ignored', () {
      expect(
          parseBoardLayerLists('["sha256:a","sha256:b"]\n\nWARNING: x\n[1,2]\n'),
          [
            ['sha256:a', 'sha256:b']
          ]);
    });

    test('not a docker save tar: scan refuses', () async {
      final f = File('${tmp.path}/junk.tar')
        ..writeAsBytesSync(buildTar([('hello.txt', utf8.encode('hi'))]));
      expect(() => DockerSaveTar.scan(f), throwsFormatException);
    });
  });

  group('ImageInstaller against a docker-like daemon', () {
    test('delta update: kiosk ends up with the identical image', () async {
      final docker = FakeDocker()..add(v22);
      final file = writeTar(v23);
      final ssh = FakeSsh(docker);
      final logs = <String>[];
      final fractions = <double>[];
      final installer =
          installerFor(ssh, file, log: logs.add, compress: false);
      final plan = await installer.plan();
      final result = await installer.install(plan,
          onProgress: (f, delta) => fractions.add(f));
      expect(result.usedDelta, isTrue);
      expect(result.loadedTag, v23.tag);
      expect(result.bytesSent, plan!.bytes);
      expect(result.bytesSent, lessThan(file.lengthSync() * 0.7));
      expect(docker.images[v23.tag]!.layers, v23.diffIds);
      expect(docker.loads.single.bytes, plan.bytes);
      expect(fractions.last, 1.0);
      expect(logs.join('\n'), contains('Verified'));
    });

    test('delta does not load (base layers gone): whole tar, automatically',
        () async {
      final docker = FakeDocker()..add(v22);
      final ssh = FakeSsh(docker);
      final installer = installerFor(ssh, writeTar(v23));
      final plan = await installer.plan();
      docker.chains.clear(); // listed, but no longer in the layer store
      final result = await installer.install(plan);
      expect(result.usedDelta, isFalse);
      expect(docker.loads.map((l) => l.ok), [false, true]);
      expect(docker.images[v23.tag]!.layers, v23.diffIds);
    });

    test('delta does not load, no room for the whole tar: refused unsent',
        () async {
      final docker = FakeDocker()..add(v22);
      final file = writeTar(v23);
      final installer = installerFor(FakeSsh(docker), file,
          free: loadSpaceNeeded(file.lengthSync()) - 1);
      final plan = await installer.plan();
      expect(plan!.isDelta, isTrue);
      docker.chains.clear(); // listed, but no longer in the layer store
      await expectLater(
          installer.install(plan),
          throwsA(predicate(
              (e) => '$e'.contains('Not enough free space on the kiosk for '
                  'the whole image'))));
      expect(docker.loads.map((l) => l.ok), [false]);
    });

    test('clean board: whole tar, verified', () async {
      final docker = FakeDocker();
      final installer = installerFor(FakeSsh(docker), writeTar(v23));
      final plan = await installer.plan();
      expect(plan!.isDelta, isFalse);
      final result = await installer.install(plan);
      expect(result.usedDelta, isFalse);
      expect(docker.loads.single.ok, isTrue);
    });

    test('layer list fails or not overlay2: whole tar', () async {
      for (final setup in <void Function(FakeDocker)>[
        (d) => d.layerListFails = true,
        (d) => d.driver = 'overlayfs',
      ]) {
        final docker = FakeDocker()..add(v22);
        setup(docker);
        final installer = installerFor(FakeSsh(docker), writeTar(v23));
        final plan = await installer.plan();
        expect(plan!.isDelta, isFalse, reason: plan.reason);
        expect((await installer.install(plan)).usedDelta, isFalse);
      }
    });

    test('loaded image with other layers than the tar: refused', () async {
      final docker = FakeDocker()
        ..add(v22)
        ..tamperedLayers = v22.diffIds;
      final installer = installerFor(FakeSsh(docker), writeTar(v23));
      final plan = await installer.plan();
      await expectLater(installer.install(plan),
          throwsA(predicate((e) => '$e'.contains('not the one in the tar'))));
      // The delta was tried, then the whole tar; both checked.
      expect(docker.loads.length, 2);
    });

    test('containerd image store: whole tar, verified by its layers',
        () async {
      // Its image ID is the manifest digest, not the tar's config digest.
      final docker = FakeDocker()
        ..add(v22)
        ..driver = 'overlayfs';
      final logs = <String>[];
      final installer =
          installerFor(FakeSsh(docker), writeTar(v23), log: logs.add);
      final plan = await installer.plan();
      expect(plan!.isDelta, isFalse);
      final result = await installer.install(plan);
      expect(result.usedDelta, isFalse);
      expect(result.loadedTag, v23.tag);
      expect(docker.images[v23.tag]!.id, isNot(v23.id));
      expect(docker.loads.single.ok, isTrue);
      expect(logs.join('\n'), contains('Verified'));
    });

    test('containerd image store: other layers than the tar are refused',
        () async {
      final docker = FakeDocker()
        ..add(v22)
        ..driver = 'overlayfs'
        ..tamperedLayers = v22.diffIds;
      final installer = installerFor(FakeSsh(docker), writeTar(v23));
      final plan = await installer.plan();
      await expectLater(installer.install(plan),
          throwsA(predicate((e) => '$e'.contains('not the one in the tar'))));
      expect(docker.loads.length, 1);
    });

    test('gzip on the wire: docker gets gzip, progress counts tar bytes',
        () async {
      final docker = FakeDocker()..add(v22);
      final installer =
          installerFor(FakeSsh(docker), writeTar(v23), compress: true);
      final plan = await installer.plan();
      final fractions = <double>[];
      final result =
          await installer.install(plan, onProgress: (f, _) => fractions.add(f));
      expect(docker.loads.single.gzip, isTrue);
      expect(docker.loads.single.bytes, lessThan(plan!.bytes));
      expect(result.bytesSent, plan.bytes);
      expect(fractions.last, 1.0);
      expect(docker.images[v23.tag]!.layers, v23.diffIds);
    });
  });

  test('SSH prefers ciphers that are fast in Dart over AES-GCM', () {
    final c = kSshAlgorithms.cipher;
    expect(c.first, SSHCipherType.chacha20poly1305);
    expect(c.indexOf(SSHCipherType.aes128ctr),
        lessThan(c.indexOf(SSHCipherType.aes128gcm)));
    expect(c.indexOf(SSHCipherType.aes256gcm), c.length - 1);
  });

  group('UpdateEngine order', () {
    CmdResult? kiosk(String c, {required int freeBytes}) {
      if (c == 'uname -m') return CmdResult(0, 'aarch64', '');
      if (c.startsWith('docker version')) return CmdResult(0, '28.1.1', '');
      if (c == composeImageCmd(kCompose)) {
        return CmdResult(0, v22.tag, '');
      }
      if (c == 'cat $kCompose') return CmdResult(0, composeTemplate(v22.tag), '');
      if (c.startsWith('df ')) return CmdResult(0, '$freeBytes', '');
      if (c.contains('.Config.Env')) {
        return CmdResult(0, '["FACE_SNAP_DATA_DIR=/data"]', '');
      }
      if (c.contains("--format '{{.Status}}'")) {
        return CmdResult(0, 'Up 5 seconds', '');
      }
      if (c.startsWith('docker logs')) {
        return CmdResult(
            0, 'Server 2.0 bound to 0.0.0.0:50051\nPlasma LED board connected', '');
      }
      if (c.contains('light_settings.json')) {
        return CmdResult(0, '"calibrated_camera_index": 1', '');
      }
      return null;
    }

    test('room for both images: load first, stop the server only after',
        () async {
      final docker = FakeDocker()..add(v22);
      final ssh = FakeSsh(docker,
          answer: (c) => kiosk(c, freeBytes: 16 * 1000 * 1000 * 1000));
      final logs = <String>[];
      final engine = _Engine(ssh, writeTar(v23), logs);
      expect(await engine.run(), isTrue, reason: logs.join('\n'));
      final load = ssh.commands.indexOf('docker load');
      final stop = ssh.commands.indexOf('systemctl stop $kServiceUnit');
      expect(load, greaterThan(0));
      expect(stop, greaterThan(load));
      expect(docker.loads.single.tarBytes,
          lessThan(writeTar(v23).lengthSync()));
      expect(docker.loads.single.gzip, kGzipImageStream);
      expect(engine.summary.join('\n'), contains('Sent only the new layers'));
      expect(engine.steps.map((s) => s.status),
          isNot(contains(StepStatus.fail)));
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('tight on space: stop + remove the old image first, whole tar',
        () async {
      final docker = FakeDocker()..add(v22);
      final ssh =
          FakeSsh(docker, answer: (c) => kiosk(c, freeBytes: 100 * 1000 * 1000));
      final logs = <String>[];
      final engine = _Engine(ssh, writeTar(v23), logs);
      expect(await engine.run(), isTrue, reason: logs.join('\n'));
      final stop = ssh.commands.indexOf('systemctl stop $kServiceUnit');
      final rmi = ssh.commands.indexOf('docker rmi ${v22.tag}');
      final load = ssh.commands.indexOf('docker load');
      expect(stop, lessThan(rmi));
      expect(rmi, lessThan(load));
      // The old image took the shared layers with it: re-planned → whole tar.
      expect(docker.loads.single.tarBytes, writeTar(v23).lengthSync());
      expect(docker.images[v23.tag]!.layers, v23.diffIds);
    }, timeout: const Timeout(Duration(minutes: 1)));

    /// Answers `df` with [free] in turn (the last value repeats).
    CmdResult? Function(String) kioskWithFree(List<int> free) {
      var i = 0;
      return (c) => c.startsWith('df ')
          ? CmdResult(0, '${free[i < free.length - 1 ? i++ : i]}', '')
          : kiosk(c, freeBytes: 0);
    }

    bool composeTouched(List<String> commands) => commands.any(
        (c) => c.contains("'s|image:") || c == 'write $kCompose');

    test('docker load fails for the delta and the whole tar: server untouched',
        () async {
      final docker = FakeDocker()
        ..add(v22)
        ..failNextLoads = 2;
      final ssh = FakeSsh(docker,
          answer: (c) => kiosk(c, freeBytes: 16 * 1000 * 1000 * 1000));
      final logs = <String>[];
      final engine = _Engine(ssh, writeTar(v23), logs);
      expect(await engine.run(), isFalse);
      expect(docker.loads.map((l) => l.ok), [false, false]);
      expect(docker.loads.first.tarBytes,
          lessThan(writeTar(v23).lengthSync())); // the delta came first
      expect(ssh.commands, isNot(contains('systemctl stop $kServiceUnit')));
      expect(composeTouched(ssh.commands), isFalse);
      expect(engine.summary,
          contains('The server was not stopped: the kiosk still runs '
              '${v22.tag}.'));
      expect(engine.summary.join('\n'),
          contains('Update failed: Exception: docker load failed'));
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('delta fails and the whole tar does not fit: abort, server untouched',
        () async {
      final docker = FakeDocker()
        ..add(v22)
        ..failNextLoads = 1;
      // Room for the delta next to the old image; then the disk is too full
      // for the whole tar.
      final ssh = FakeSsh(docker,
          answer: kioskWithFree([16 * 1000 * 1000 * 1000, 1000]));
      final logs = <String>[];
      final engine = _Engine(ssh, writeTar(v23), logs);
      expect(await engine.run(), isFalse);
      expect(docker.loads.length, 1, reason: 'the whole tar was never sent');
      expect(ssh.commands, isNot(contains('systemctl stop $kServiceUnit')));
      expect(composeTouched(ssh.commands), isFalse);
      expect(engine.summary.join('\n'), contains('Not enough free space'));
      expect(engine.summary,
          contains('The server was not stopped: the kiosk still runs '
              '${v22.tag}.'));
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('tight on space, re-plan needs the whole tar and it does not fit: '
        'nothing is sent', () async {
      final docker = FakeDocker()..add(v22);
      // Tight (old image removed first), and after that the whole tar the
      // re-plan needs does not fit.
      final ssh = FakeSsh(docker,
          answer: kioskWithFree([100 * 1000 * 1000, 100 * 1000 * 1000, 1000]));
      final logs = <String>[];
      final engine = _Engine(ssh, writeTar(v23), logs);
      expect(await engine.run(), isFalse);
      expect(ssh.commands, isNot(contains('docker load')));
      expect(docker.loads, isEmpty);
      expect(composeTouched(ssh.commands), isFalse);
      expect(engine.summary.join('\n'), contains('Not enough free space'));
      expect(engine.summary.join('\n'),
          contains('The server was stopped and its old image removed'));
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('a whole-tar load counts twice too: no room to keep the old image',
        () async {
      final docker = FakeDocker()
        ..add(v22)
        ..layerListFails = true; // → the whole tar is sent
      final tarBytes = writeTar(v23).lengthSync();
      // Headroom (1500 MiB) + 1.5 × the tar: enough for one copy of what is
      // sent, not for docker's temp copy beside it.
      final free = 1500 * 1024 * 1024 + (tarBytes * 1.5).round();
      final ssh = FakeSsh(docker, answer: (c) => kiosk(c, freeBytes: free));
      final logs = <String>[];
      final engine = _Engine(ssh, writeTar(v23), logs);
      expect(await engine.run(), isTrue, reason: logs.join('\n'));
      final stop = ssh.commands.indexOf('systemctl stop $kServiceUnit');
      final rmi = ssh.commands.indexOf('docker rmi ${v22.tag}');
      final load = ssh.commands.indexOf('docker load');
      expect(stop, greaterThan(0));
      expect(stop, lessThan(rmi));
      expect(rmi, lessThan(load));
    }, timeout: const Timeout(Duration(minutes: 1)));
  });

  // The board's port (data/server_config.json) survives every compose and
  // avahi write of an update: the from-scratch ones (fresh board, generation
  // conversion either way) write it in, a normal update only swaps the
  // image: line and leaves it alone. An image that cannot read the port file
  // still listens on 50051 inside the container, so the host side keeps the
  // board's port and the container side stays 50051.
  group('UpdateEngine keeps the board port', () {
    final v28 = TestImage('facesnap2:2.0.28-arm64',
        ['base', 'python', 'empty', 'models', 'app22', 'app28']);
    final v29 = TestImage('facesnap2:2.0.29-arm64',
        ['base', 'python', 'empty', 'models', 'app22', 'app29']);
    final legacy = TestImage('face_snap:1.4.3', ['base', 'py38', 'legacy']);
    const avahiPath = '/etc/avahi/services/facesnap.service';

    /// A board with [compose] (null: none yet), a parked first-generation
    /// compose file [parked], a port file saying [port] (null: no file) and
    /// [installed] images; the new image is first-generation when
    /// [newLegacy]. docker-compose.yml is stateful: writes, cp and the
    /// image: sed change what `cat` returns.
    FakeSsh board(
        {String? compose,
        String? parked,
        int? port,
        List<TestImage> installed = const [],
        bool newLegacy = false}) {
      final docker = FakeDocker();
      installed.forEach(docker.add);
      late final FakeSsh ssh;
      String? now() => ssh.writes[kCompose] ?? compose;
      final sedImage = RegExp(r"^sed -i 's\|image:\.\*\|image: (\S+)\|' ");
      ssh = FakeSsh(docker, answer: (c) {
        if (c == 'uname -m') return CmdResult(0, 'aarch64', '');
        if (c.startsWith('docker version')) return CmdResult(0, '28.1.1', '');
        if (c == 'test -f $kCompose') {
          return CmdResult(now() == null ? 1 : 0, '', '');
        }
        if (c == composeImageCmd(kCompose)) {
          final image = RegExp(r'image:\s*(\S+)').firstMatch(now() ?? '');
          return CmdResult(0, image?.group(1) ?? '', '');
        }
        if (c == 'cat $kCompose') {
          final text = now();
          return text == null
              ? CmdResult(1, '', 'No such file')
              : CmdResult(0, text, '');
        }
        if (c.contains(kBoardPortFile)) {
          return port == null
              ? CmdResult(1, '', '')
              : CmdResult(0, portFileContent(port), '');
        }
        if (c == 'test -f $kLegacyComposeBackup') {
          return CmdResult(parked == null ? 1 : 0, '', '');
        }
        if (c == 'cp $kLegacyComposeBackup $kCompose') {
          ssh.writes[kCompose] = parked!;
        }
        final sed = sedImage.firstMatch(c);
        if (sed != null) {
          ssh.writes[kCompose] = now()!
              .replaceFirst(RegExp(r'image:.*'), 'image: ${sed.group(1)}');
        }
        if (c.startsWith('df ')) {
          return CmdResult(0, '${16 * 1000 * 1000 * 1000}', '');
        }
        if (c.contains('.Config.Env')) {
          return CmdResult(
              0,
              newLegacy ? '["PATH=/usr/bin"]' : '["FACE_SNAP_DATA_DIR=/data"]',
              '');
        }
        if (c.contains("--format '{{.Status}}'")) {
          return CmdResult(0, 'Up 5 seconds', '');
        }
        if (c.startsWith('docker logs')) {
          return CmdResult(0,
              'Server 2.0 bound to 0.0.0.0:50051\nPlasma LED board connected', '');
        }
        if (c.contains('light_settings.json')) {
          return CmdResult(0, '"calibrated_camera_index": 1', '');
        }
        if (c.contains('/sys/class/net')) {
          return CmdResult(0, '001e06aabbcc', '');
        }
        if (c == kHostnameCmd) return CmdResult(0, 'facesnap-001e06aabbcc', '');
        return null;
      });
      return ssh;
    }

    Future<FakeSsh> update(FakeSsh ssh, TestImage image) async {
      final logs = <String>[];
      final engine = _Engine(ssh, writeTar(image), logs);
      expect(await engine.run(), isTrue, reason: logs.join('\n'));
      return ssh;
    }

    const timeout = Timeout(Duration(minutes: 1));

    test('fresh board: the compose file and avahi carry the port', () async {
      final ssh = await update(board(port: 50052), v28);
      expect(ssh.writes[kCompose], composeTemplate(v28.tag, port: 50052));
      expect(ssh.writes[kCompose], contains('- "50052:50052"'));
      expect(ssh.writes[avahiPath], avahiService(50052));
    }, timeout: timeout);

    test('R15: fresh board on port 50052, new image 2.0.27 (no port reader): '
        '"50052:50051"', () async {
      final v27 = TestImage('facesnap2:2.0.27-arm64',
          ['base', 'python', 'empty', 'models', 'app22', 'app27']);
      final ssh = await update(board(port: 50052), v27);
      expect(ssh.commands, contains('write $kCompose'));
      expect(ssh.writes[kCompose],
          composeTemplate(v27.tag, port: 50052, containerPort: 50051));
      expect(ssh.writes[kCompose], contains('- "50052:50051"'));
      expect(ssh.writes[avahiPath], avahiService(50052));
    }, timeout: timeout);

    test('fresh board without a port file: 50051 as before', () async {
      final ssh = await update(board(), v28);
      expect(ssh.writes[kCompose], composeTemplate(v28.tag));
      expect(ssh.writes[kCompose], contains('- "50051:50051"'));
      expect(ssh.writes[avahiPath], avahiService(50051));
    }, timeout: timeout);

    test('conversion to the data/ layout carries the port', () async {
      final ssh = await update(
          board(
              compose: legacyComposeTemplate(legacy.tag),
              port: 50052,
              installed: [legacy]),
          v28);
      expect(ssh.commands, contains('write $kCompose'));
      expect(ssh.writes[kCompose], composeTemplate(v28.tag, port: 50052));
      expect(ssh.writes[avahiPath], avahiService(50052));
    }, timeout: timeout);

    test('downgrade to the first generation (template): the host side keeps '
        'the port', () async {
      final ssh = await update(
          board(
              compose: composeTemplate(v28.tag, port: 50052),
              port: 50052,
              installed: [v28],
              newLegacy: true),
          legacy);
      expect(ssh.commands, contains('write $kCompose'));
      expect(ssh.writes[kCompose],
          legacyComposeTemplate(legacy.tag, port: 50052, containerPort: 50051));
      expect(ssh.writes[kCompose], contains('- "50052:50051"'));
      expect(ssh.writes[avahiPath], avahiService(50052));
    }, timeout: timeout);

    test('downgrade to the first generation (parked file): the host side '
        'keeps the port', () async {
      final ssh = await update(
          board(
              compose: composeTemplate(v28.tag, port: 50052),
              parked: legacyComposeTemplate('face_snap:1.4.2'),
              port: 50052,
              installed: [v28],
              newLegacy: true),
          legacy);
      expect(ssh.writes[kCompose],
          legacyComposeTemplate(legacy.tag, port: 50052, containerPort: 50051));
      expect(ssh.writes[avahiPath], avahiService(50052));
    }, timeout: timeout);

    test('normal update: only the image line changes, the port stays',
        () async {
      final ssh = await update(
          board(
              compose: composeTemplate(v28.tag, port: 50052),
              port: 50052,
              installed: [v28]),
          v29);
      expect(ssh.commands, isNot(contains('write $kCompose')),
          reason: 'no from-scratch write on a normal update');
      expect(ssh.writes[kCompose], composeTemplate(v29.tag, port: 50052));
      expect(ssh.writes[avahiPath], avahiService(50052));
    }, timeout: timeout);

    test('P3: a ports line the edit does not know: left alone, the warning '
        'in the log and the summary', () async {
      final twoMappings = composeTemplate(v28.tag, port: 50052).replaceFirst(
          '      - "50052:50052"\n', '      - "50052:50052"\n      - "8080:8080"\n');
      final ssh = board(compose: twoMappings, port: 50052, installed: [v28]);
      final logs = <String>[];
      final engine = _Engine(ssh, writeTar(v29), logs);
      expect(await engine.run(), isTrue, reason: logs.join('\n'));
      const warning = 'WARNING: unexpected ports line in docker-compose.yml: the ports '
          'line was left as it is; check that the kiosk answers on port 50052.';
      expect(logs, contains(warning));
      expect(engine.summary, contains(warning));
      expect(ssh.writes[kCompose], contains('- "8080:8080"'), reason: 'left as it is');
    }, timeout: timeout);

    test('normal update to an image without the port file: the container '
        'side goes back to 50051; up again: N:N', () async {
      final v23 = TestImage('facesnap2:2.0.23-arm64',
          ['base', 'python', 'empty', 'models', 'app22', 'app23']);
      var ssh = await update(
          board(
              compose: composeTemplate(v28.tag, port: 50052),
              port: 50052,
              installed: [v28]),
          v23);
      expect(ssh.writes[kCompose],
          composeTemplate(v23.tag, port: 50052, containerPort: 50051));
      ssh = await update(
          board(compose: ssh.writes[kCompose], port: 50052, installed: [v23]),
          v28);
      expect(ssh.writes[kCompose], composeTemplate(v28.tag, port: 50052));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

class _Engine extends UpdateEngine {
  _Engine(this.fake, File tar, List<String> logs)
      : super(
            host: 'kiosk',
            user: 'root',
            password: 'x',
            tarFile: tar,
            onChanged: () {},
            onLog: logs.add) {
    delay = (_) async {}; // no real waits in the verify polls (P2)
    checkServer = (_, port) async => port; // GetKioskInfo answers on the board port (X-12)
  }
  final FakeSsh fake;

  @override
  Future<SshRunner> openSsh() async => fake;
}
