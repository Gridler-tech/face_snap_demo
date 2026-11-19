// Loads a `docker save` tar into the kiosk's docker: only the layers the
// kiosk does not have yet (see image_delta.dart), the whole tar when that is
// not possible or the delta load fails (space permitting), and in both cases
// a check that the loaded image is exactly the tar's (layer list, plus the
// image ID on the classic overlay2 store).
import 'dart:io';

import 'engine.dart' show shorten;
import 'image_delta.dart';
import 'kiosk.dart';
import '../services/ssh_runner.dart';

/// Whether the image stream is gzip-compressed (level 1) on the way; docker
/// load recognises a gzip stream by itself. Measured 2026-10-08 against the
/// Odroid on Wi-Fi (the link, ~2.7 MB/s, is the bottleneck once the cipher
/// is fixed): the layers compress to 68-70%, gzip -1 runs at ~60 MB/s on the
/// PC and level 6 gained nothing over level 1. On a wired kiosk the link is
/// faster than gzip only above ~60 MB/s — more than dartssh2 encrypts.
const kGzipImageStream = true;

/// Where docker keeps its images on the kiosk (the free-space checks).
const kDockerRoot = '/var/lib/docker';

/// Disk space `docker load` needs for [sendBytes] of tar — the same for a
/// delta and for the whole tar. It unpacks the stream first (classic store:
/// into docker's temp folder, deleted afterwards; containerd image store:
/// into its content store) and then unpacks every layer into the store (an
/// unpacked layer is about the size of its tar), so what is sent counts
/// twice; plus 10%.
int loadSpaceNeeded(int sendBytes) => (sendBytes * 2.2).round();

class ImageInstallResult {
  ImageInstallResult({
    required this.loadedTag,
    required this.output,
    required this.usedDelta,
    required this.bytesSent,
    required this.elapsed,
  });

  /// The tag from docker load's "Loaded image:" line.
  final String loadedTag;
  final String output;
  final bool usedDelta;

  /// Bytes read from the tar and streamed (before any compression).
  final int bytesSent;
  final Duration elapsed;
}

class ImageInstaller {
  ImageInstaller({
    required SshRunner Function() ssh,
    required this.tarFile,
    required this.log,
    Future<int> Function()? freeSpace,
    this.compress = kGzipImageStream,
  })  : _connection = ssh,
        _readFreeSpace = freeSpace;

  /// The connection, fetched on every use: a reconnect (the cgroup reboot
  /// during provisioning) replaces the engine's runner.
  final SshRunner Function() _connection;
  SshRunner get ssh => _connection();

  final File tarFile;
  final void Function(String line) log;

  /// Free bytes on [kDockerRoot]; tests substitute a fake.
  final Future<int> Function()? _readFreeSpace;
  Future<int> freeSpace() =>
      _readFreeSpace?.call() ?? freeBytes(ssh, kDockerRoot);

  /// gzip the stream (level 1); see [kGzipImageStream].
  final bool compress;

  DockerSaveTar? _tar;
  bool _scanned = false;

  /// Whether the daemon reports the config digest as the image ID (classic
  /// overlay2 store), set by [plan]. While unknown only the layer list is
  /// verified — see [checkLoadedImage].
  bool _idIsConfigDigest = false;

  /// The tar's index; null when it is not a `docker save` tar this code
  /// understands (it is then streamed whole, as before).
  Future<DockerSaveTar?> scanTar() async {
    if (_scanned) return _tar;
    _scanned = true;
    try {
      _tar = await DockerSaveTar.scan(tarFile);
    } on Object catch (e) {
      log('Cannot read the image list of ${basenameOf(tarFile.path)} '
          '($e) — the whole file will be sent.');
    }
    return _tar;
  }

  /// What would be sent right now. Asks the kiosk which layers it has
  /// (read-only); any failure gives a full-tar plan. Null when the tar could
  /// not be indexed.
  Future<DeltaPlan?> plan() async {
    final tar = await scanTar();
    if (tar == null) return null;
    final driver = await ssh.run("docker info --format '{{.Driver}}'");
    _idIsConfigDigest = driver.ok && driver.stdout.trim() == 'overlay2';
    if (!driver.ok) {
      return DeltaPlan.full(tar, 'docker info failed on the kiosk');
    }
    // Leaving blobs out is proven for the classic overlay2 layer store; a
    // containerd-snapshotter store loads differently — send it everything.
    if (driver.stdout.trim() != 'overlay2') {
      return DeltaPlan.full(
          tar, 'storage driver "${driver.stdout.trim()}" (not overlay2)');
    }
    final layers = await ssh.run(kBoardLayersCmd);
    if (!layers.ok) {
      return DeltaPlan.full(tar, 'could not list the kiosk\'s image layers');
    }
    return planDelta(tar, parseBoardLayerLists(layers.stdout));
  }

  /// Throws when [kDockerRoot] has no room to load [sendBytes] of tar (see
  /// [loadSpaceNeeded]). Called before anything is sent, so a refusal leaves
  /// the kiosk as it was. [what] names the load in the messages.
  Future<void> ensureRoomFor(int sendBytes, String what) async {
    final avail = await freeSpace();
    final need = loadSpaceNeeded(sendBytes);
    if (avail < need) {
      throw Exception('Not enough free space on the kiosk for $what: '
          '${formatGb(avail)} free, about ${formatGb(need)} needed.');
    }
    log('Free space: ${formatGb(avail)} — enough for $what (about '
        '${formatGb(need)}).');
  }

  /// Streams [plan] (or the whole tar) into `docker load` and verifies the
  /// result. A failed delta is retried once with the whole tar when there is
  /// room for it. Throws when the image could not be loaded, is not the
  /// tar's image or the whole tar does not fit.
  /// [onProgress] gets the fraction 0..1 of the current stream.
  Future<ImageInstallResult> install(DeltaPlan? plan,
      {void Function(double fraction, bool delta)? onProgress}) async {
    final started = DateTime.now();
    if (plan != null && plan.isDelta) {
      log('Sending ${formatMb(plan.bytes)} instead of '
          '${formatMb(plan.tar.length)}: ${plan.reason}.');
      final result = await _load(
          streamRanges(tarFile, plan.ranges), plan.bytes, true, onProgress);
      final problem = result.ok ? await _verify(plan.tar, result) : null;
      if (result.ok && problem == null) {
        return ImageInstallResult(
            loadedTag: _loadedTag(result)!,
            output: result.combined,
            usedDelta: true,
            bytesSent: plan.bytes,
            elapsed: DateTime.now().difference(started));
      }
      log('The partial image did not load '
          '(${problem ?? shorten(result.combined.trim().replaceAll('\n', ' '))}).');
      // The space check before the update was sized on the delta; the whole
      // tar needs far more, beside the image the server still runs on.
      await ensureRoomFor(tarFile.lengthSync(), 'the whole image');
      log('Sending the whole image instead.');
    } else if (plan != null) {
      log('Sending the whole image (${formatMb(plan.tar.length)}): '
          '${plan.reason}.');
    }

    final total = tarFile.lengthSync();
    final result = await _load(tarFile.openRead(), total, false, onProgress);
    if (!result.ok) {
      throw Exception('docker load failed:\n${result.combined}');
    }
    final tar = plan?.tar ?? await scanTar();
    if (tar != null) {
      final problem = await _verify(tar, result);
      if (problem != null) {
        throw Exception('The loaded image is not the one in the tar: $problem');
      }
    } else if (_loadedTag(result) == null) {
      throw Exception(
          'docker load gave no "Loaded image" tag:\n${result.combined}');
    }
    return ImageInstallResult(
        loadedTag: _loadedTag(result)!,
        output: result.combined,
        usedDelta: false,
        bytesSent: total,
        elapsed: DateTime.now().difference(started));
  }

  Future<CmdResult> _load(Stream<List<int>> data, int total, bool delta,
      void Function(double fraction, bool delta)? onProgress) {
    return ssh.runWithStreamStdin('docker load', data,
        encoder: compress ? ZLibEncoder(gzip: true, level: 1) : null,
        onProgress: (sent) => onProgress?.call(total == 0 ? 1 : sent / total, delta));
  }

  static String? _loadedTag(CmdResult r) =>
      RegExp(r'Loaded image: (\S+)').firstMatch(r.stdout)?.group(1);

  /// Null when the tag docker load reported is exactly the tar's image.
  Future<String?> _verify(DockerSaveTar tar, CmdResult load) async {
    final tag = _loadedTag(load);
    if (tag == null) return 'no "Loaded image" line';
    final inspect = await ssh
        .run('docker image inspect --format $kLoadedImageCheckFormat $tag');
    if (!inspect.ok) return 'cannot inspect $tag: ${inspect.combined.trim()}';
    final problem = checkLoadedImage(tar, inspect.stdout,
        idIsConfigDigest: _idIsConfigDigest);
    if (problem == null) {
      log(_idIsConfigDigest
          ? 'Verified: $tag has the tar\'s image ID and all '
              '${tar.diffIds.length} layers.'
          : 'Verified: $tag has all ${tar.diffIds.length} of the tar\'s '
              'layers.');
    }
    return problem;
  }
}

String formatMb(num bytes) => bytes >= 1e9
    ? '${(bytes / 1e9).toStringAsFixed(2)} GB'
    : '${(bytes / 1e6).toStringAsFixed(0)} MB';
