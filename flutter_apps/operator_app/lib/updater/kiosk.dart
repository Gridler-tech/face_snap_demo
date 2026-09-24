// The kiosk contract: the facts about a FaceSnap board's on-disk layout and
// naming that the engines and "Get server info" rely on. Single source —
// callers interpolate these instead of restating them per file.
import 'settings_profile.dart';
import '../services/ssh_runner.dart';

/// Install directory on the board; holds docker-compose.yml and data/.
const kKioskDir = '/root/face_snap';
const kCompose = '$kKioskDir/docker-compose.yml';

/// The auto-start systemd unit (also referenced by the operator app).
const kServiceUnit = 'face-snap-docker-compose.service';

/// Read the kiosk's hostname. `uname -n` (POSIX coreutils, on every board
/// image) — NOT the `hostname` binary, which the Arch-based Radxa Q6A image
/// does not ship (it lives in inetutils there). The first batch update of a
/// Radxa died in "Provision kiosk identity" on exactly that, leaving the
/// kiosk stopped with its compose file already switched to the new image.
const kHostnameCmd = 'uname -n';

/// The server's settings files under data/ (migration, backup, info view).
const kSettingsFiles = [
  'camera_settings.json',
  'kiosk_settings.json',
  'light_settings.json',
];

/// Staging path for the config-backup tgz on the board.
const kConfigBackupTgz = '/tmp/facesnap_config_backup.tgz';

/// Container-name filter matching the compose service's container.
const kContainerFilter = '--filter name=face_snap';

/// Image-reference filters covering both server generations:
/// face_snap_server (Python) and facesnap2.
const kImageRefFilters =
    "--filter reference='face_snap*' --filter reference='facesnap*'";

/// The server's own "ready" log line, all generations: the first-generation
/// Python server (face_snap:1.4.x) logs "gRPC server started", the later
/// Python server "gRPC server bound to", Server 2.0 (C#) "FaceSnap Server 2.0
/// bound to port".
final kServerReadyMarker = RegExp(
    r'gRPC server started|gRPC server bound to|Server 2\.0 bound to');

/// Proof in the server log that the Plasma LED board answered: the current
/// servers log "Plasma LED board connected", the first-generation server only
/// its mpremote exchanges ("Successfully communicated with plasma").
final kLedBoardConnectedMarker = RegExp(
    r'Plasma LED board connected|Successfully communicated with plasma');

/// True when a light_settings.json (the camera calibration) assigns at least
/// one camera a position. A never-calibrated board — typically one upgraded
/// from the first generation — carries rows whose position is null; Server 2.0
/// then only captures when the column matches a standard wiring loom (2.0.11+)
/// and refuses otherwise, so the update report points it out.
bool hasCalibratedPositions(String lightSettingsJson) =>
    RegExp(r'"calibrated_camera_index"\s*:\s*\d').hasMatch(lightSettingsJson);

// ---- first-generation ("legacy") installation layout ------------------------
//
// Boards installed before the data/ folder existed (face_snap:1.4.x, 2025) keep
// the three settings JSONs NEXT TO docker-compose.yml and bind-mount them one
// by one into /root/face_snap/server/; their compose file also carries a
// `command:` that starts the Python 3.8 server by hand. Every later image
// (Python 1.1.x and Server 2.0) sets FACE_SNAP_DATA_DIR=/data and expects the
// single ./data:/data mount instead. Swapping only the `image:` line between
// the two generations therefore produces a container that cannot start, so the
// update pipeline converts the compose file whenever the generation changes.

/// Where the last legacy compose file is parked when a board is converted to
/// the data/ layout, so a later downgrade restores it verbatim.
const kLegacyComposeBackup = '$kCompose.bak-legacy';

/// True for a first-generation compose file: it lacks the data/ mount every
/// later generation relies on.
bool isLegacyCompose(String composeText) =>
    !RegExp(r'^\s*-\s*\./data:/data\s*$', multiLine: true)
        .hasMatch(composeText);

/// True when an image belongs to the data/ generations. [imageEnv] is the
/// output of `docker inspect --format '{{json .Config.Env}}' <image>`.
bool imageUsesDataDir(String imageEnv) =>
    imageEnv.contains('FACE_SNAP_DATA_DIR');

/// Empty-but-valid content for a legacy settings file that does not exist yet
/// (a bind mount of a missing file would make Docker create a DIRECTORY).
String legacySettingsSeed(String fileName) =>
    fileName == 'light_settings.json' ? '[]' : '{}';

/// docker-compose.yml for the data/ generations (Python 1.1.x, Server 2.0).
String composeTemplate(String imageTag) => '''
services:
  face_snap:
    image: $imageTag
    restart: always
    ports:
      - "50051:50051"
    volumes:
      # All mutable data (settings JSONs, logs, numba cache) lives here - the
      # image sets FACE_SNAP_DATA_DIR=/data. Survives image updates.
      - ./data:/data

      # Mount /dev and udev so the container reaches the cameras (/dev/video*),
      # the LED board (/dev/ttyACM*) and the proximity reader (GPIO).
      - /dev:/dev
      - /run/udev:/run/udev:ro

    privileged: true # required for camera/serial/GPIO access via /dev
''';

/// docker-compose.yml for a first-generation image on a board that has no
/// parked legacy compose file to restore (mirrors the 2025 original).
String legacyComposeTemplate(String imageTag) => '''
services:
  face_snap:
    image: $imageTag
    command: >
      bash -c "cd /root/face_snap/server && watchmedo auto-restart --recursive --pattern='*.py' -- python3.8 server.py"
    restart: always
    environment:
      - PYTHONPATH=/usr/local/lib/python3.8/dist-packages:/usr/local/lib/python3.8/site-packages
      - PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
    ports:
      - "50051:50051"
    volumes:
      # First-generation layout: the settings files live next to this file and
      # are mounted into the server folder one by one.
${kSettingsFiles.map((f) => '      - type: bind\n        source: ./$f\n        target: /root/face_snap/server/$f').join('\n')}

      # Mount /dev and udev so the container reaches the cameras and LED board.
      - /dev:/dev
      - /run/udev:/run/udev:ro

    privileged: true # required for camera/serial access via /dev
''';

/// A tag that starts with a dotted number actually carries a version
/// ("2.0.9-arm64" does, "arm64" does not — it merely CONTAINS digits).
final kVersionLike = RegExp(r'^\d+\.');

/// Shell command printing the `image:` line of a compose file.
String composeImageCmd(String composePath, {bool tolerateMissing = false}) =>
    "sed -n 's/^[[:space:]]*image:[[:space:]]*//p' $composePath"
    "${tolerateMissing ? ' 2>/dev/null' : ''} | head -1 | tr -d '\"'";

/// The tag part of an image ref, or null when the ref carries no tag.
String? tagOf(String ref) => RegExp(r':(.+)$').firstMatch(ref)?.group(1);

/// Last path segment, for both Windows and POSIX separators.
String basenameOf(String path) => path.split(RegExp(r'[/\\]')).last;

String formatGb(num bytes) =>
    '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';

/// Architecture and board model of the connected machine, e.g.
/// ("aarch64", "Hardkernel ODROID-N2Plus"). The model is the device-tree
/// string (NUL-terminated), falling back to the architecture on machines
/// without one. Shared by the pipelines' connect step and the Kiosk card's
/// connection probe so the two can never disagree about what they see.
Future<({String arch, String model})> identifyBoard(SshRunner ssh) async {
  final arch = (await ssh.runChecked('uname -m')).stdout.trim();
  final board =
      await ssh.run("tr -d '\\0' < /proc/device-tree/model 2>/dev/null");
  final model = board.stdout.trim().isEmpty ? arch : board.stdout.trim();
  return (arch: arch, model: model);
}

/// Free bytes of the filesystem holding [path] on the board.
Future<int> freeBytes(SshRunner ssh, String path) async {
  final df = await ssh.runChecked('df --output=avail -B1 $path | tail -1');
  return int.tryParse(df.stdout.trim()) ?? 0;
}

/// The kiosk's current kiosk_settings.json for the settings-profile review
/// list: the data/ one, else the first-generation file next to the compose
/// file (the update copies that one into data/), else {} on a clean board.
Future<Map<String, dynamic>> readKioskSettings(SshRunner ssh) async {
  final result = await ssh.run(
      'cat $kKioskDir/data/kiosk_settings.json 2>/dev/null || '
      'cat $kKioskDir/kiosk_settings.json 2>/dev/null');
  return parseKioskSettings(result.stdout);
}

// ---- leftover image tar cleanup --------------------------------------------
//
// A clean update streams the image straight into `docker load` and stores
// nothing on the eMMC (see update_engine.dart). But a failed stream or a
// hand-run install (SFTP the tar, then `docker load`) can leave the image
// .tar behind — most often in the SSH home (/root), sometimes /tmp. The
// removal pipeline hunts these down so nothing is left behind.

/// Directories scanned for leftover image tars (bounded, not a whole-FS scan:
/// the eMMC is slow and these are the only places an install drops a tar).
const kLeftoverTarRoots = '/root /tmp /var/tmp /home';

/// find(1) predicate matching an image tar of EITHER server generation
/// (`face_snap-*.tar`, `facesnap*-*.tar`) — the same prefixes as
/// [kImageRefFilters], so an unrelated `backup.tar` is never touched.
const kLeftoverTarPredicate =
    r"-maxdepth 2 -type f \( -name 'face_snap*.tar' -o -name 'facesnap*.tar' \)";

/// Command listing leftover image tars as `<bytes>\t<path>` lines (missing
/// roots are tolerated).
String leftoverTarScanCmd() =>
    "find $kLeftoverTarRoots $kLeftoverTarPredicate -printf '%s\\t%p\\n' "
    '2>/dev/null';

/// Command deleting every leftover image tar.
String leftoverTarDeleteCmd() =>
    'find $kLeftoverTarRoots $kLeftoverTarPredicate -delete 2>/dev/null';

/// Parse [leftoverTarScanCmd] output into (bytes, path) records, skipping
/// blank or malformed lines. Exposed for testing.
List<({int bytes, String path})> parseLeftoverTars(String findOutput) {
  final out = <({int bytes, String path})>[];
  for (final line in findOutput.split('\n')) {
    final tab = line.indexOf('\t');
    if (tab <= 0) continue;
    final bytes = int.tryParse(line.substring(0, tab).trim());
    final path = line.substring(tab + 1).trim(); // keeps spaces inside the path
    if (bytes == null || path.isEmpty) continue;
    out.add((bytes: bytes, path: path));
  }
  return out;
}

/// Config backup: tgz of data/ plus the compose file (tolerating either being
/// absent on a partial installation), downloaded to [localPath] on this
/// machine; the staging tgz on the board is removed again.
Future<void> backupKioskConfigTo(SshRunner ssh, String localPath) async {
  await ssh.runChecked(
      'cd $kKioskDir && tar czf $kConfigBackupTgz --ignore-failed-read '
      'data docker-compose.yml 2>/dev/null || '
      'tar czf $kConfigBackupTgz --ignore-failed-read data');
  await ssh.downloadFile(kConfigBackupTgz, localPath);
  await ssh.run('rm -f $kConfigBackupTgz');
}
