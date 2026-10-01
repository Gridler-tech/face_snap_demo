// The update pipeline: connects to the Odroid over SSH and replaces the
// FaceSnap server image with the one in the selected `docker save` tar.
//
// Designed for small eMMC boards (16 GB): the tar is never copied to the
// device — it is streamed from this machine straight into `docker load` —
// and when free space is too tight to hold the old and new image together,
// the old image is removed BEFORE loading (at the cost of automatic
// rollback, which the operator is told about).
import 'dart:io';

import 'engine.dart';
import 'kiosk.dart';
import 'settings_profile.dart';
import '../services/ssh_runner.dart';

export 'engine.dart';

class UpdateEngine extends KioskEngine {
  UpdateEngine({
    required super.host,
    required super.user,
    required super.password,
    required this.tarFile,
    required super.onChanged,
    required super.onLog,
    this.profile,
    this.profileRowIds,
  });

  final File tarFile;

  /// Optional settings profile applied to the kiosk's settings during the
  /// update (see settings_profile.dart). [profileRowIds] = the rows the
  /// operator left ticked in the review list; null applies every row that
  /// differs (headless use).
  final SettingsProfile? profile;
  final Set<String>? profileRowIds;

  static final _tarVersionRe = RegExp(r'face_snap-(.+?)\.tar$');

  /// The pipeline's step titles (also used by the GUI's idle view).
  static const stepTitles = [
    'Connect to the kiosk',
    'Inspect the current installation',
    'Set up a clean board (Docker)',
    'Pre-update checks (version, disk space)',
    'Back up settings and configuration',
    'Stop the server',
    'Make room (old image)',
    'Install the new server image',
    'Update the start-up configuration',
    'Apply the settings profile',
    'Provision kiosk identity',
    'Start the server',
    'Verify the new server',
    'Clean up',
  ];

  @override
  final List<UpdateStep> steps = [for (final t in stepTitles) UpdateStep(t)];

  String _oldImageRef = '';
  String _newImageTag = '';
  bool _oldImageKept = false;
  bool _hadCompose = true;
  bool _dockerMissing = false;

  /// First-generation layout on either side of the update (see kiosk.dart):
  /// the compose file found on the board, and the image being installed.
  bool _legacyCompose = false;
  bool _newImageLegacy = false;

  /// Versions for display: the tag part of the old/new image refs.
  String get oldVersion =>
      _oldImageRef.isEmpty ? 'none' : (tagOf(_oldImageRef) ?? _oldImageRef);
  String get newVersion =>
      _newImageTag.isEmpty ? '' : (tagOf(_newImageTag) ?? _newImageTag);

  UpdateStep get _connect => steps[0];
  UpdateStep get _inspect => steps[1];
  UpdateStep get _provision => steps[2];
  UpdateStep get _checks => steps[3];
  UpdateStep get _backup => steps[4];
  UpdateStep get _stop => steps[5];
  UpdateStep get _makeRoom => steps[6];
  UpdateStep get _install => steps[7];
  UpdateStep get _autostart => steps[8];
  UpdateStep get _profile => steps[9];
  UpdateStep get _identity => steps[10];
  UpdateStep get _start => steps[11];
  UpdateStep get _verify => steps[12];
  UpdateStep get _cleanup => steps[13];

  Future<bool> run() => runGuarded('Update', () async {
        await connectStep(_connect);
        await _doInspect();
        await _doProvision();
        await _doChecks();
        await _doBackup();
        await _doStop();
        await _doMakeRoom();
        await _doInstall();
        await _doAutostart();
        await _doProfile();
        await _doIdentity();
        await _doStart();
        final verified = await _doVerify();
        if (!verified) {
          await _doRollback();
          return false;
        }
        await _doCleanup();
        summary.insert(0, 'Version: $oldVersion → $newVersion');
        summary.add('Server updated to $_newImageTag and verified.');
        return true;
      });

  Future<void> _doInspect() async {
    setStep(_inspect, StepStatus.running);

    // A clean vendor image (stock "odroid"/"radxa" install) has no Docker
    // yet — that is not an error, it just means the board must be set up
    // first (the next step installs Docker; the later steps write compose,
    // the unit and the kiosk identity, completing the provisioning).
    final docker = await ssh.run('docker version --format {{.Server.Version}}');
    _dockerMissing = !docker.ok;
    if (_dockerMissing) {
      log('Docker is not installed — this looks like a clean board; it '
          'will be set up during this install.');
    } else {
      log('Docker ${docker.stdout.trim()}');
    }

    _hadCompose = (await ssh.run('test -f $kCompose')).ok;
    if (_hadCompose) {
      final image = await ssh.run(composeImageCmd(kCompose));
      _oldImageRef = image.stdout.trim();
      log('Current compose image: '
          '${_oldImageRef.isEmpty ? '(none found)' : _oldImageRef}');

      // First-generation boards reference the image by ID; resolve it to its
      // repo:tag so the version shows up in the report and comparisons.
      if (_oldImageRef.isNotEmpty && !_oldImageRef.contains(':')) {
        final resolved = await ssh.run(
            "docker inspect --format '{{index .RepoTags 0}}' $_oldImageRef");
        final tag = resolved.stdout.trim();
        if (resolved.ok && tag.contains(':')) {
          log('Image ID $_oldImageRef is $tag.');
          _oldImageRef = tag;
        }
      }

      final compose = await ssh.run('cat $kCompose');
      _legacyCompose = compose.ok && isLegacyCompose(compose.stdout);
      if (_legacyCompose) {
        log('First-generation installation layout: settings files next to '
            'docker-compose.yml, no data/ folder.');
      }
    } else {
      log('No docker-compose.yml on the kiosk yet — this will be a first '
          'install.');
    }

    final running = await ssh.run(
        "docker ps --format '{{.Image}} ({{.Status}})' | head -3");
    if (running.stdout.trim().isNotEmpty) {
      log('Running containers:\n${running.stdout.trim()}');
    }

    final unit = await ssh.run('test -f /etc/systemd/system/$kServiceUnit');
    log(unit.ok
        ? 'Auto-start service present.'
        : 'Auto-start service missing — it will be installed.');

    setStep(
        _inspect,
        StepStatus.ok,
        _dockerMissing
            ? 'clean board — full setup'
            : _oldImageRef.isEmpty
                ? 'first install'
                : 'version $oldVersion');
  }

  /// Set up a clean vendor image so the rest of the pipeline can run:
  /// install Docker (docker-ce via apt on Ubuntu/Debian, pacman on Arch) and
  /// make containers actually runnable on old vendor kernels. Skipped on
  /// provisioned kiosks. Requires the board to have internet access.
  Future<void> _doProvision() async {
    var didWork = false;
    if (_dockerMissing) {
      didWork = true;
      setStep(_provision, StepStatus.running, 'installing Docker');
      log('Installing Docker on the clean board (needs internet) …');

      final hasApt = (await ssh.run('command -v apt-get >/dev/null 2>&1')).ok;
      final hasPacman = (await ssh.run('command -v pacman >/dev/null 2>&1')).ok;
      CmdResult install;
      if (hasApt) {
        // A freshly booted vendor image immediately runs unattended-upgrades,
        // which holds the dpkg lock for minutes — stop it and wait.
        await ssh.run('systemctl stop unattended-upgrades 2>/dev/null');
        await ssh.run(
            'i=0; while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 '
            '&& [ \$i -lt 60 ]; do sleep 5; i=\$((i+1)); done',
            timeout: const Duration(minutes: 6));
        // docker-ce from Docker's own repository — NOT Ubuntu's docker.io:
        // its runc runs fine on the old vendor kernels, and it is what the
        // golden images use. (Proven on the Odroid N2+ 4.9 kernel.)
        install = await ssh.run(
            'export DEBIAN_FRONTEND=noninteractive && '
            'apt-get update -qq && apt-get install -y ca-certificates curl && '
            'install -m 0755 -d /etc/apt/keyrings && '
            'curl -fsSL https://download.docker.com/linux/ubuntu/gpg '
            '-o /etc/apt/keyrings/docker.asc && '
            '. /etc/os-release && '
            'echo "deb [arch=\$(dpkg --print-architecture) '
            'signed-by=/etc/apt/keyrings/docker.asc] '
            'https://download.docker.com/linux/ubuntu \$VERSION_CODENAME '
            'stable" > /etc/apt/sources.list.d/docker.list && '
            'apt-get update -qq && apt-get install -y '
            'docker-ce docker-ce-cli containerd.io docker-compose-plugin',
            timeout: const Duration(minutes: 20));
      } else if (hasPacman) {
        install = await ssh.run('pacman -Sy --noconfirm docker docker-compose',
            timeout: const Duration(minutes: 15));
      } else {
        throw Exception('Unknown distribution: neither apt-get nor pacman is '
            'available — cannot install Docker on this board.');
      }
      if (!install.ok) {
        throw Exception('Docker installation failed (is the board online?):\n'
            '${shorten(install.combined)}');
      }

      // docker-ce uses systemd socket activation; enable the socket too or
      // dockerd exits with "no sockets found via socket activation".
      await ssh.run('systemctl enable --now docker.socket 2>/dev/null');
      await ssh.runChecked('systemctl enable --now docker',
          timeout: const Duration(minutes: 2));
      final docker =
          await ssh.run('docker version --format {{.Server.Version}}');
      if (!docker.ok) {
        throw Exception('Docker was installed but is not responding:\n'
            '${shorten(docker.combined)}');
      }
      log('Docker ${docker.stdout.trim()} installed and running.');
      summary.add('Clean board set up: Docker installed.');
    }

    // Modern runc cannot start containers on a cgroup-v2 system with a
    // pre-5.x kernel: bpf_prog_query(BPF_CGROUP_DEVICE) fails with EINVAL
    // (hit on the Odroid N2+ vendor 4.9 kernel). Boot with the v1 hierarchy
    // instead — on Hardkernel images the kernel cmdline lives in
    // /media/boot/boot.ini. Requires a reboot; the engine reconnects after.
    final cgroup = (await ssh.run('stat -fc %T /sys/fs/cgroup')).stdout.trim();
    final kernel = (await ssh.run('uname -r')).stdout.trim();
    final kernelMajor = int.tryParse(kernel.split('.').first) ?? 99;
    if (cgroup == 'cgroup2fs' && kernelMajor < 5) {
      didWork = true;
      final hasBootIni = (await ssh.run('test -f /media/boot/boot.ini')).ok;
      if (!hasBootIni) {
        setStep(_provision, StepStatus.warn,
            'old kernel ($kernel) with cgroup v2 — containers may not start '
            '(no boot.ini to patch)');
        log('WARNING: kernel $kernel with cgroup v2 and no known boot '
            'config; the container runtime may fail on this board.');
        return;
      }
      setStep(_provision, StepStatus.running,
          'old kernel: switching to cgroup v1 (reboot)');
      log('Kernel $kernel cannot run containers under cgroup v2 — '
          'patching boot.ini for the v1 hierarchy and rebooting …');
      await ssh.runChecked(
          'grep -q unified_cgroup_hierarchy /media/boot/boot.ini || '
          '{ cp /media/boot/boot.ini /media/boot/boot.ini.bak && '
          "sed -i 's|^setenv bootargs \"|setenv bootargs "
          '"systemd.unified_cgroup_hierarchy=0 |\' /media/boot/boot.ini; }');
      await ssh.run('(sleep 2 && reboot) >/dev/null 2>&1 &');
      sshOrNull?.close();
      sshOrNull = null;

      // Reconnect (boards take ~40-90 s to come back).
      log('Waiting for the kiosk to reboot …');
      await Future<void>.delayed(const Duration(seconds: 20));
      SshRunner? again;
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(seconds: 6));
        try {
          again = await SshRunner.connect(host, user, password);
          break;
        } catch (_) {/* still rebooting */}
      }
      if (again == null) {
        throw Exception('The kiosk did not come back after the cgroup '
            'reboot. Check it and run the update again.');
      }
      sshOrNull = again;
      final now = (await ssh.run('stat -fc %T /sys/fs/cgroup')).stdout.trim();
      if (now == 'cgroup2fs') {
        throw Exception('The kiosk still boots with cgroup v2 after the '
            'boot.ini patch — containers will not start on this kernel.');
      }
      log('Rebooted on the cgroup v1 hierarchy.');
      summary.add('Boot configuration adjusted for the old kernel '
          '(cgroup v1) — one automatic reboot.');
    }

    if (didWork) {
      setStep(_provision, StepStatus.ok, 'board ready for containers');
    } else {
      setStep(_provision, StepStatus.skipped, 'nothing to set up');
    }
  }

  Future<void> _doChecks() async {
    setStep(_checks, StepStatus.running);
    var status = StepStatus.ok;
    final notes = <String>[];

    // Version comparison from the tar filename (authoritative tag is known
    // only after `docker load`, which prints it).
    final name = basenameOf(tarFile.path);
    final tarVersion = _tarVersionRe.firstMatch(name)?.group(1) ?? '';
    if (tarVersion.isEmpty) {
      status = StepStatus.warn;
      notes.add('unrecognised tar name');
      log('WARNING: "$name" does not match face_snap-<version>.tar — '
          'cannot compare versions up front.');
    } else {
      if (!tarVersion.contains('arm64')) {
        status = StepStatus.warn;
        notes.add('name lacks "arm64"');
        log('WARNING: tar name has no "arm64" — make sure this is the '
            'Odroid build, not a PC build.');
      }
      final currentVersion = tagOf(_oldImageRef) ?? '';
      if (currentVersion.isNotEmpty && currentVersion == tarVersion) {
        status = StepStatus.warn;
        notes.add('same version ($tarVersion) — reinstall');
        log('WARNING: the kiosk already runs $currentVersion; '
            'proceeding as a reinstall.');
      } else {
        log('Version: ${currentVersion.isEmpty ? '(unknown)' : currentVersion} '
            '→ $tarVersion');
      }
    }

    // Disk space: the loaded image is about the size of the tar. Decide
    // whether the old image can be kept for rollback.
    final tarBytes = tarFile.lengthSync();
    final avail = await freeBytes(ssh, '/var/lib/docker');
    final needed = (tarBytes * 1.1).round();
    const headroom = 1500 * 1024 * 1024;
    log('Free space: ${formatGb(avail)} — new image needs about '
        '${formatGb(needed)}.');
    if (avail < needed + headroom) {
      _oldImageKept = false;
      if (_oldImageRef.isEmpty) {
        throw Exception('Not enough free space (${formatGb(avail)}) and no '
            'old image to remove. Free up space on the kiosk first.');
      }
      status = StepStatus.warn;
      notes.add('tight on space: old image removed before install '
          '(no automatic rollback)');
      log('Space is tight: the old image will be removed BEFORE the new '
          'one is installed. Automatic rollback will not be possible.');
    } else {
      _oldImageKept = _oldImageRef.isNotEmpty;
      if (_oldImageKept) {
        log('Enough space to keep the old image until the new server is '
            'verified (rollback possible).');
      }
    }

    setStep(
        _checks, status, notes.isEmpty ? 'version and space OK' : notes.join('; '));
  }

  Future<void> _doBackup() async {
    setStep(_backup, StepStatus.running);

    await ssh.runChecked('mkdir -p $kKioskDir/data');
    // One-time migration from the pre-/data layout (settings next to compose).
    // The originals stay where they are: a first-generation server (before or
    // after a downgrade) keeps using them. Files already in data/ win — they
    // hold the richer settings of the newer server generations.
    final migrated = await ssh.runChecked(
        'for f in ${kSettingsFiles.join(' ')}; do '
        'if [ -f $kKioskDir/\$f ] && [ ! -f $kKioskDir/data/\$f ]; then '
        'cp $kKioskDir/\$f $kKioskDir/data/\$f; echo "\$f"; fi; done');
    final migratedFiles = migrated.stdout.trim().split('\n')
      ..removeWhere((f) => f.trim().isEmpty);
    if (migratedFiles.isNotEmpty) {
      log('Copied into data/: ${migratedFiles.join(', ')}');
    }

    // Settings backup (small) + compose backup for rollback.
    await ssh.runChecked(
        'tar czf $kKioskDir/data_backup_last.tgz -C $kKioskDir data '
        '2>/dev/null || true');
    if (_hadCompose) {
      await ssh.runChecked('cp $kCompose $kCompose.bak');
    }
    setStep(_backup, StepStatus.ok, 'settings → data_backup_last.tgz');
    log('Settings backed up to $kKioskDir/data_backup_last.tgz');
  }

  Future<void> _doStop() async {
    setStep(_stop, StepStatus.running);
    await ssh.run('systemctl stop $kServiceUnit');
    // Belt and braces: remove any face_snap container the unit did not own.
    await ssh.run('docker ps -aq $kContainerFilter | xargs -r docker rm -f');
    setStep(_stop, StepStatus.ok);
    log('Server stopped.');
  }

  Future<void> _doMakeRoom() async {
    if (_oldImageKept || _oldImageRef.isEmpty) {
      setStep(_makeRoom, StepStatus.skipped,
          _oldImageRef.isEmpty ? 'first install' : 'old image kept for rollback');
      return;
    }
    setStep(_makeRoom, StepStatus.running);
    log('Removing old image $_oldImageRef to free space …');
    await ssh.run('docker rmi $_oldImageRef');
    await ssh.run('docker image prune -f');
    final avail = await freeBytes(ssh, '/var/lib/docker');
    setStep(_makeRoom, StepStatus.ok, '${formatGb(avail)} free now');
    log('Old image removed. ${formatGb(avail)} free.');
  }

  Future<void> _doInstall() async {
    setStep(_install, StepStatus.running, '0%');
    final total = tarFile.lengthSync();
    log('Streaming ${formatGb(total)} into docker load (nothing is stored on '
        'the eMMC) …');
    final started = DateTime.now();
    final result = await ssh.runWithFileStdin('docker load', tarFile,
        onProgress: (sent) {
      final pct = (sent / total * 100).clamp(0, 100).toStringAsFixed(0);
      setStep(_install, StepStatus.running, '$pct%');
    });
    if (!result.ok) {
      throw Exception('docker load failed:\n${result.combined}');
    }
    final loaded =
        RegExp(r'Loaded image: (\S+)').firstMatch(result.stdout)?.group(1);
    if (loaded == null) {
      throw Exception(
          'docker load gave no "Loaded image" tag:\n${result.combined}');
    }
    _newImageTag = loaded;

    // A tag that does not start with a dotted number carries no version
    // (facesnap2:arm64 — "arm64" merely CONTAINS digits). When the tar
    // filename has a real version (face_snap-2.0.0-arm64.tar), re-tag the
    // image with it so "Get server info" and later version comparisons can
    // tell builds apart on the kiosk itself.
    final tarVersion =
        _tarVersionRe.firstMatch(basenameOf(tarFile.path))?.group(1);
    if (!kVersionLike.hasMatch(newVersion) &&
        tarVersion != null &&
        kVersionLike.hasMatch(tarVersion)) {
      final repo = loaded.split(':').first;
      final versioned = '$repo:$tarVersion';
      await ssh.runChecked('docker tag $loaded $versioned');
      log('Tagged $loaded as $versioned (version from the tar name).');
      _newImageTag = versioned;
    }

    // Which layout does the new image expect? Every data/ generation sets
    // FACE_SNAP_DATA_DIR in the image; a first-generation image does not.
    final env = await ssh.run(
        "docker inspect --format '{{json .Config.Env}}' $_newImageTag");
    _newImageLegacy = env.ok && !imageUsesDataDir(env.stdout);
    if (_newImageLegacy) {
      log('$_newImageTag is a first-generation image (settings files next '
          'to docker-compose.yml).');
    }

    final elapsed = DateTime.now().difference(started);
    setStep(_install, StepStatus.ok,
        'version $newVersion in ${formatDuration(elapsed)}');
    log('Loaded $_newImageTag in ${formatDuration(elapsed)}.');
  }

  Future<void> _doAutostart() async {
    setStep(_autostart, StepStatus.running);

    var layoutNote = '';
    if (!_hadCompose) {
      await ssh.writeRemoteFile(
          kCompose,
          _newImageLegacy
              ? legacyComposeTemplate(_newImageTag)
              : composeTemplate(_newImageTag));
      if (_newImageLegacy) await _ensureLegacySettingsFiles();
      log('Wrote a fresh docker-compose.yml.');
    } else if (_legacyCompose && !_newImageLegacy) {
      // Upgrade across the generation boundary: the old compose file's
      // `command:` and per-file mounts would make the new image crash-loop.
      // Park it for a later downgrade and switch to the data/ layout (the
      // settings were copied into data/ by the backup step).
      await ssh.runChecked('cp $kCompose $kLegacyComposeBackup');
      await ssh.writeRemoteFile(kCompose, composeTemplate(_newImageTag));
      layoutNote = 'layout converted to data/';
      log('Converted the first-generation docker-compose.yml to the data/ '
          'layout (old file kept as ${basenameOf(kLegacyComposeBackup)}).');
      summary.add('Installation layout converted to the data/ folder; the '
          'first-generation compose file is kept for a downgrade.');
    } else if (!_legacyCompose && _newImageLegacy) {
      // Downgrade across the boundary: a first-generation image needs its
      // start command and per-file mounts back.
      final parked = (await ssh.run('test -f $kLegacyComposeBackup')).ok;
      if (parked) {
        await ssh.runChecked('cp $kLegacyComposeBackup $kCompose');
        await ssh.runChecked(
            "sed -i 's|image:.*|image: $_newImageTag|' $kCompose");
        log('Restored the first-generation docker-compose.yml that was '
            'parked during the upgrade.');
      } else {
        await ssh.writeRemoteFile(
            kCompose, legacyComposeTemplate(_newImageTag));
        log('Wrote a first-generation docker-compose.yml.');
      }
      await _ensureLegacySettingsFiles();
      layoutNote = 'first-generation layout restored';
      summary.add('Installation layout switched back to the first-generation '
          'one (settings files next to docker-compose.yml; data/ is kept).');
    } else {
      await ssh.runChecked(
          "sed -i 's|image:.*|image: $_newImageTag|' $kCompose");
    }

    final unitExists =
        (await ssh.run('test -f /etc/systemd/system/$kServiceUnit')).ok;
    if (!unitExists) {
      await ssh.writeRemoteFile(
          '/etc/systemd/system/$kServiceUnit', _systemdUnit);
      await ssh.runChecked('systemctl daemon-reload');
      log('Installed the auto-start service.');
    }
    await ssh.runChecked('systemctl enable $kServiceUnit');
    setStep(
        _autostart,
        StepStatus.ok,
        'compose → $_newImageTag, service enabled'
        '${layoutNote.isEmpty ? '' : ', $layoutNote'}');
    log('Start-up configuration updated.');
  }

  /// A first-generation compose file bind-mounts the three settings files
  /// from next to itself. Docker turns a MISSING bind source into a directory,
  /// which the server then cannot read — so make sure each one is a file:
  /// keep what is there (the board's own first-generation settings), seed an
  /// empty-but-valid file otherwise.
  Future<void> _ensureLegacySettingsFiles() async {
    for (final name in kSettingsFiles) {
      final path = '$kKioskDir/$name';
      final seeded = await ssh.runChecked(
          '[ -d $path ] && rmdir $path; '
          "[ -f $path ] || { echo '${legacySettingsSeed(name)}' > $path; "
          'echo seeded; }');
      if (seeded.stdout.contains('seeded')) {
        log('Created an empty $name for the first-generation server.');
      }
    }
  }

  static const _kioskSettingsPath = '$kKioskDir/data/kiosk_settings.json';
  bool _profileApplied = false;

  /// Writes the ticked profile rows into data/kiosk_settings.json — after the
  /// settings backup (Restore brings the old values back) and before the
  /// server starts (it reads the file at boot and fills in its own defaults
  /// for everything the file lacks). A first-generation image is skipped: its
  /// settings files are not the data/ ones and its keys differ.
  Future<void> _doProfile() async {
    final profile = this.profile;
    if (profile == null) {
      setStep(_profile, StepStatus.skipped, 'kiosk settings kept as they are');
      return;
    }
    if (_newImageLegacy) {
      setStep(_profile, StepStatus.skipped,
          'not applicable to a first-generation server');
      summary.add('Settings profile NOT applied: $_newImageTag is a '
          'first-generation server.');
      return;
    }
    setStep(_profile, StepStatus.running);

    final read = await ssh.run('cat $_kioskSettingsPath 2>/dev/null');
    final current = parseKioskSettings(read.stdout);
    final changes = profile
        .diff(current)
        .where((row) =>
            row.differs && (profileRowIds?.contains(row.id) ?? true))
        .toList();
    if (changes.isEmpty) {
      setStep(_profile, StepStatus.ok, 'nothing to change');
      log('Settings profile "${profile.name}": the kiosk already has every '
          'selected value.');
      return;
    }

    await ssh.run('cp $_kioskSettingsPath $_kioskSettingsPath.pre-profile '
        '2>/dev/null');
    await ssh.writeRemoteFile(_kioskSettingsPath,
        encodeKioskSettings(applyProfileChanges(current, changes)));
    _profileApplied = true;

    log('Settings profile "${profile.name}" applied:');
    for (final row in changes) {
      log('  ${row.label}: ${row.currentText} → ${row.newText}');
    }
    summary.add('Settings changed by the profile: '
        '${changes.map((r) => '${r.label} ${r.currentText} → ${r.newText}').join('; ')}.');
    setStep(_profile, StepStatus.ok,
        '${changes.length} setting${changes.length == 1 ? '' : 's'} changed');
  }

  /// Give every kiosk a stable, discoverable network identity:
  /// hostname `facesnap-<eth0 MAC>` announced over mDNS, plus a
  /// `_facesnap._tcp` service so the app's "Search kiosks" can find it.
  /// Best-effort — a kiosk without internet that lacks avahi still updates
  /// fine (warn only).
  Future<void> _doIdentity() async {
    setStep(_identity, StepStatus.running);

    // First wired NIC: "eth0" on the Odroid images, predictable names like
    // "enp1s0" on Arch (Radxa Q6A) — never wlan/docker/bridge interfaces.
    final mac = (await ssh.run(
            'nic=\$(ls /sys/class/net | grep -E "^(eth|en)" | head -1); '
            'cat /sys/class/net/\$nic/address 2>/dev/null | tr -d ":\\n"'))
        .stdout
        .trim();
    if (mac.isEmpty) {
      setStep(_identity, StepStatus.warn, 'no wired NIC found — skipped');
      log('Could not find a wired network interface; kiosk name unchanged.');
      return;
    }
    final target = 'facesnap-$mac';
    final current = (await ssh.runChecked(kHostnameCmd)).stdout.trim();
    if (current != target) {
      await ssh.runChecked('hostnamectl set-hostname $target');
      await ssh.runChecked(
          'if grep -q "^127.0.1.1" /etc/hosts; then '
          'sed -i "s/^127.0.1.1.*/127.0.1.1\\t$target/" /etc/hosts; '
          'else printf "127.0.1.1\\t$target\\n" >> /etc/hosts; fi');
      log('Hostname set to $target (was $current).');
    }

    // Distro-neutral presence check (dpkg only exists on Debian/Ubuntu;
    // Radxa Q6A kiosks run Arch).
    final hasAvahi =
        (await ssh.run('command -v avahi-daemon >/dev/null 2>&1')).ok;
    if (!hasAvahi) {
      log('Installing avahi-daemon for network discovery …');
      final install = await ssh.run(
          'DEBIAN_FRONTEND=noninteractive apt-get install -y avahi-daemon '
          '|| pacman -Sy --noconfirm avahi',
          timeout: const Duration(minutes: 5));
      if (!install.ok) {
        setStep(_identity, StepStatus.warn,
            '$target (avahi install failed — kiosk offline?)');
        log('avahi-daemon could not be installed; the kiosk keeps working '
            'but is not discoverable by name.');
        summary.add('Kiosk name set to $target, but network discovery is '
            'unavailable (avahi missing).');
        return;
      }
    }
    await ssh.writeRemoteFile(
        '/etc/avahi/services/facesnap.service', _avahiService);
    await ssh.runChecked(
        'systemctl enable avahi-daemon && systemctl restart avahi-daemon');
    setStep(_identity, StepStatus.ok, '$target.local');
    log('Kiosk reachable as $target.local (discovery service active).');
    summary.add('Kiosk name: $target.local');
  }

  Future<void> _doStart() async {
    setStep(_start, StepStatus.running);
    await ssh.runChecked('systemctl start $kServiceUnit',
        timeout: const Duration(minutes: 4));
    setStep(_start, StepStatus.ok);
    log('Server starting …');
  }

  Future<bool> _doVerify() async {
    setStep(_verify, StepStatus.running);

    // Wait for the server's own "ready" marker in the container log. The
    // published port is useless as a readiness signal: docker-proxy listens on
    // 50051 the moment the container starts, well before the server has
    // finished booting and binding.
    var text = '';
    var bound = false;
    for (var i = 0; i < 36; i++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      final status =
          await ssh.run("docker ps $kContainerFilter --format '{{.Status}}'");
      if (!status.stdout.contains('Up')) {
        if (i < 3) continue; // restart=always may still be spinning it up
        setStep(_verify, StepStatus.fail, 'container not running');
        log('Verification failed: the container did not stay up.');
        return false;
      }
      final logs = await ssh.run(
          'docker logs --tail 600 \$(docker ps -q $kContainerFilter) 2>&1');
      text = logs.stdout;
      if (kServerReadyMarker.hasMatch(text)) {
        bound = true;
        break;
      }
      setStep(
          _verify, StepStatus.running, 'waiting for server boot (${(i + 1) * 5}s)');
    }
    if (!bound) {
      setStep(_verify, StepStatus.fail, 'server never reported ready');
      log('Verification failed: the gRPC server did not come up within 3 '
          'minutes.');
      return false;
    }

    // Hardware discovery logs land right around the bind — give it a moment,
    // then take the final log snapshot.
    await Future<void>.delayed(const Duration(seconds: 8));
    final logs = await ssh.run(
        'docker logs --tail 600 \$(docker ps -q $kContainerFilter) 2>&1');
    text = logs.stdout;

    // Real problems fail the update (see serverLogErrors). Missing kiosk
    // hardware does not: a board is often updated before it is built into a
    // kiosk, so no LED board / cameras is reported as a warning below.
    final errors = serverLogErrors(text);
    final hardwareAbsent =
        text.split('\n').where(kHardwareAbsentRe.hasMatch).length;

    // Server 2.0 does not enumerate cameras at startup (they are opened
    // lazily per capture), so a missing camera count is normal there.
    final isServer20 = text.contains('Server 2.0 bound to');
    final cameras =
        RegExp(r'found (\d+) camera').firstMatch(text)?.group(1) ?? '?';
    final ledBoard = kLedBoardConnectedMarker.hasMatch(text);

    summary.add(isServer20 && cameras == '?'
        ? 'Cameras: opened per capture (Server 2.0)'
        : 'Cameras found: $cameras');
    summary.add('LED board: ${ledBoard ? 'connected' : 'NOT detected'}');
    log('Cameras: $cameras — LED board '
        '${ledBoard ? 'connected' : 'NOT detected'}.');
    if (hardwareAbsent > 0) {
      log('$hardwareAbsent server log line(s) say kiosk hardware is not '
          'attached — not a failure (fine for a board that is not in a kiosk '
          'yet).');
    }

    if (errors.isNotEmpty) {
      setStep(_verify, StepStatus.fail, shorten(errors.first));
      log('Verification failed, errors in the server log:');
      for (final line in errors.take(10)) {
        log('  $line');
      }
      return false;
    }

    // A board that was never calibrated (typical after upgrading a
    // first-generation install) reports success here but may refuse every
    // capture — say so instead of leaving the operator to find out.
    if (!_newImageLegacy) {
      final calibration =
          await ssh.run('cat $kKioskDir/data/light_settings.json 2>/dev/null');
      if (!hasCalibratedPositions(calibration.stdout)) {
        summary.add('Camera positions are NOT calibrated on this kiosk. A '
            'standard column (6-camera strip, server 2.0.11 and later; '
            '4-camera ring, 2.0.12 and later) is ordered by its USB sockets '
            'automatically; any other wiring needs '
            'one calibration in the operator app (Calibration page), or '
            'restore a settings backup.');
        log('Note: the camera calibration holds no positions.');
      }
    }

    final camerasUnknown = !isServer20 && (cameras == '?' || cameras == '0');
    final warn = !ledBoard || camerasUnknown;
    setStep(
        _verify,
        warn ? StepStatus.warn : StepStatus.ok,
        'running, port open, '
        '${isServer20 && cameras == '?' ? 'Server 2.0' : '$cameras cameras'}, '
        'LED ${ledBoard ? 'OK' : 'missing'}');
    return true;
  }

  Future<void> _doRollback() async {
    if (!_oldImageKept || !_hadCompose) {
      summary.add('No rollback possible (old image was removed for space). '
          'The kiosk needs attention.');
      log('No rollback possible — the old image is gone.');
      setStep(_cleanup, StepStatus.skipped, 'rollback not possible');
      return;
    }
    setStep(_cleanup, StepStatus.running, 'rolling back');
    log('Rolling back to $_oldImageRef …');
    await ssh.run('systemctl stop $kServiceUnit');
    await ssh.runChecked('cp $kCompose.bak $kCompose');
    if (_profileApplied) {
      await ssh.run('cp $_kioskSettingsPath.pre-profile $_kioskSettingsPath');
      log('Restored the settings from before the profile.');
    }
    await ssh.run('systemctl start $kServiceUnit');
    final status =
        await ssh.run("docker ps $kContainerFilter --format '{{.Status}}'");
    final ok = status.stdout.contains('Up');
    summary.add(ok
        ? 'Rolled back to the previous server ($_oldImageRef).'
        : 'Rollback attempted but the old server did not start — '
            'the kiosk needs attention.');
    setStep(_cleanup, ok ? StepStatus.warn : StepStatus.fail,
        ok ? 'rolled back to $_oldImageRef' : 'rollback failed');
    log(ok ? 'Rollback complete.' : 'Rollback FAILED.');
  }

  Future<void> _doCleanup() async {
    setStep(_cleanup, StepStatus.running);
    if (_oldImageKept &&
        _oldImageRef.isNotEmpty &&
        _oldImageRef != _newImageTag) {
      log('Removing the old image $_oldImageRef …');
      await ssh.run('docker rmi $_oldImageRef');
    }
    await ssh.run('docker image prune -f');
    final avail = await freeBytes(ssh, '/var/lib/docker');
    summary.add('Free space on the kiosk: ${formatGb(avail)}.');
    setStep(_cleanup, StepStatus.ok, '${formatGb(avail)} free');
    log('Cleanup done. ${formatGb(avail)} free.');
  }

  static const _avahiService = '''
<?xml version="1.0" standalone="no"?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">FaceSnap kiosk on %h</name>
  <service>
    <type>_facesnap._tcp</type>
    <port>50051</port>
  </service>
</service-group>
''';

  static const _systemdUnit = '''
[Unit]
Description=face snap with docker compose
PartOf=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=$kKioskDir
# "docker compose" (not a hardcoded plugin path): the compose plugin lives in
# /usr/libexec on Debian/Ubuntu but /usr/lib on Arch (Radxa Q6A kiosks).
ExecStart=/usr/bin/docker compose up -d --remove-orphans
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
''';
}
