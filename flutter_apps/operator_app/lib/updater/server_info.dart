// Read-only inspection of a kiosk: is the FaceSnap server installed, which
// version, on what hardware/OS, and with which configuration.
import 'dart:convert';

import 'kiosk.dart';
import '../services/ssh_runner.dart';

class ServerInfoResult {
  final server = <(String, String)>[];
  final system = <(String, String)>[];

  /// Settings file name → pretty-printed JSON (or a "not present" note).
  final configs = <String, String>{};
}

class ServerInfo {
  static Future<ServerInfoResult> fetch(
      String host, String user, String password) async {
    final ssh = await SshRunner.connect(host, user, password);
    try {
      final result = ServerInfoResult();
      await _serverSection(ssh, result);
      await _systemSection(ssh, result);
      await _configSection(ssh, result);
      return result;
    } finally {
      ssh.close();
    }
  }

  static Future<void> _serverSection(
      SshRunner ssh, ServerInfoResult result) async {
    final compose =
        await ssh.run(composeImageCmd(kCompose, tolerateMissing: true));
    final image = compose.stdout.trim();
    if (image.isEmpty) {
      result.server.add(('Installed', 'no — FaceSnap server not found'));
      return;
    }
    // Version, most to least authoritative: an OCI version label baked into
    // the image, then the image tag when it actually carries a version
    // (starts with a dotted number — "arm64" does not), then the raw tag.
    final label = (await ssh.run(
            "docker inspect --format "
            "'{{index .Config.Labels \"org.opencontainers.image.version\"}}' "
            '$image 2>/dev/null'))
        .stdout
        .trim();
    final tag = tagOf(image) ?? image;
    final version = label.isNotEmpty && label != '<no value>'
        ? label
        : kVersionLike.hasMatch(tag)
            ? tag
            : '$tag (image has no version tag)';
    result.server.add(('Installed', 'yes'));
    result.server.add(('Version', version));
    result.server.add(('Image', image));

    final status = await ssh
        .run("docker ps $kContainerFilter --format '{{.Status}}' | head -1");
    result.server.add((
      'Running',
      status.stdout.trim().isEmpty ? 'no' : status.stdout.trim()
    ));

    final enabled = await ssh.run('systemctl is-enabled $kServiceUnit');
    result.server.add(('Start on boot', enabled.stdout.trim()));

    // Inspect the exact compose image (a reference glob like face_snap*
    // missed facesnap2). Short ID + creation date identify the build even
    // when tags are reused.
    final imageInfo = await ssh.run(
        "docker images $image --format '{{.Size}} (built {{.CreatedSince}})' | head -1");
    if (imageInfo.stdout.trim().isNotEmpty) {
      result.server.add(('Image size', imageInfo.stdout.trim()));
    }
    final id = (await ssh.run(
            "docker inspect --format '{{.Id}}' $image 2>/dev/null"))
        .stdout
        .trim();
    if (id.isNotEmpty) {
      result.server.add((
        'Image ID',
        id.replaceFirst('sha256:', '').substring(0, 12)
      ));
    }
  }

  static Future<void> _systemSection(
      SshRunner ssh, ServerInfoResult result) async {
    Future<String> grab(String cmd) async =>
        (await ssh.run(cmd)).stdout.trim();

    final board =
        await grab("tr -d '\\0' < /proc/device-tree/model 2>/dev/null");
    if (board.isNotEmpty) result.system.add(('Board', board));
    result.system.add(('Hostname', await grab(kHostnameCmd)));
    result.system.add((
      'OS',
      await grab(
          "sed -n 's/^PRETTY_NAME=\"\\(.*\\)\"/\\1/p' /etc/os-release")
    ));
    final kernel = await grab('uname -r');
    final arch = await grab('uname -m');
    result.system.add(('Kernel', '$kernel ($arch)'));
    result.system.add(('CPU cores', await grab('nproc')));
    result.system.add(('Memory',
        await grab("free -h | awk 'NR==2{print \$2\" total, \"\$7\" available\"}'")));
    result.system.add(('Disk (/)',
        await grab("df -h / | awk 'NR==2{print \$2\" total, \"\$4\" free (\"\$5\" used)\"}'")));
    final docker =
        await grab('docker version --format {{.Server.Version}} 2>/dev/null');
    result.system.add(('Docker', docker.isEmpty ? 'not installed' : docker));
  }

  static Future<void> _configSection(
      SshRunner ssh, ServerInfoResult result) async {
    for (final name in kSettingsFiles) {
      final content = await ssh.run('cat $kKioskDir/data/$name 2>/dev/null');
      final text = content.stdout.trim();
      if (text.isEmpty) {
        result.configs[name] = '(not present)';
        continue;
      }
      try {
        result.configs[name] =
            const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
      } catch (_) {
        result.configs[name] = text;
      }
    }
  }
}
