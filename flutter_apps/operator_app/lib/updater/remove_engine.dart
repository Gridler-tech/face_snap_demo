// Removes the FaceSnap server from a kiosk: autostart service, containers and
// images. The configuration files (settings, calibration, backups in
// /root/face_snap) are kept unless [deleteConfigs] is set — kept configs are
// picked up automatically by a later install. [backupPath] downloads a tgz of
// the configuration to this machine first, before anything is touched.
import 'engine.dart';
import 'kiosk.dart';

class RemoveEngine extends KioskEngine {
  RemoveEngine({
    required super.host,
    required super.user,
    required super.password,
    required this.deleteConfigs,
    this.backupPath,
    required super.onChanged,
    required super.onLog,
  });

  final bool deleteConfigs;

  /// Local (Windows) path to save a tgz of the configuration files to before
  /// anything is touched; null = no backup requested.
  final String? backupPath;

  @override
  final List<UpdateStep> steps = [
    UpdateStep('Connect to the kiosk'),
    UpdateStep('Inspect the current installation'),
    UpdateStep('Back up configuration files'),
    UpdateStep('Stop and disable auto-start'),
    UpdateStep('Remove the auto-start service'),
    UpdateStep('Remove containers and image'),
    UpdateStep('Remove leftover image files'),
    UpdateStep('Delete configuration files'),
    UpdateStep('Verify removal'),
  ];

  String _installedVersion = '';

  UpdateStep get _connect => steps[0];
  UpdateStep get _inspect => steps[1];
  UpdateStep get _backup => steps[2];
  UpdateStep get _stop => steps[3];
  UpdateStep get _unit => steps[4];
  UpdateStep get _docker => steps[5];
  UpdateStep get _leftovers => steps[6];
  UpdateStep get _configs => steps[7];
  UpdateStep get _verify => steps[8];

  Future<bool> run() => runGuarded('Removal', () async {
        await connectStep(_connect);
        await _doInspect();
        await _doBackup();
        await _doStop();
        await _doUnit();
        await _doDocker();
        await _doLeftovers();
        await _doConfigs();
        await _doVerify();
        return true;
      });

  Future<void> _doInspect() async {
    setStep(_inspect, StepStatus.running);
    final image = await ssh.run(composeImageCmd(kCompose, tolerateMissing: true));
    final ref = image.stdout.trim();
    _installedVersion = ref.isEmpty ? '' : (tagOf(ref) ?? ref);

    // Both server generations: face_snap_server (Python) and facesnap2.
    final images = await ssh.run(
        "docker images $kImageRefFilters --format '{{.Repository}}:{{.Tag}}'");
    final unit = (await ssh.run('test -f /etc/systemd/system/$kServiceUnit')).ok;
    final dataDir = (await ssh.run('test -d $kKioskDir')).ok;

    if (!dataDir && images.stdout.trim().isEmpty && !unit) {
      setStep(_inspect, StepStatus.warn, 'nothing installed');
      log('No FaceSnap installation found on this kiosk — nothing to do.');
    } else {
      setStep(
          _inspect,
          StepStatus.ok,
          _installedVersion.isEmpty
              ? 'partial installation found'
              : 'version $_installedVersion');
      log('Found: '
          '${_installedVersion.isEmpty ? "partial installation" : "version $_installedVersion"}'
          '${unit ? ", auto-start service" : ""}'
          '${dataDir ? ", configuration files" : ""}.');
    }
  }

  Future<void> _doBackup() async {
    final path = backupPath;
    if (path == null) {
      setStep(_backup, StepStatus.skipped, 'not requested');
      return;
    }
    setStep(_backup, StepStatus.running);
    if (!(await ssh.run('test -d $kKioskDir')).ok) {
      setStep(_backup, StepStatus.warn, 'nothing to back up');
      log('No configuration files on the kiosk — nothing to back up.');
      return;
    }
    // Settings/calibration (data/) plus the compose file; tolerate either
    // being absent on a partial installation.
    await backupKioskConfigTo(ssh, path);
    setStep(_backup, StepStatus.ok, basenameOf(path));
    log('Configuration backed up to $path');
    summary.add('Configuration backed up to $path');
  }

  Future<void> _doStop() async {
    setStep(_stop, StepStatus.running);
    await ssh.run('systemctl stop $kServiceUnit');
    await ssh.run('systemctl disable $kServiceUnit');
    setStep(_stop, StepStatus.ok);
    log('Server stopped, auto-start disabled.');
  }

  Future<void> _doUnit() async {
    final existed =
        (await ssh.run('test -f /etc/systemd/system/$kServiceUnit')).ok;
    if (!existed) {
      setStep(_unit, StepStatus.skipped, 'not present');
      return;
    }
    setStep(_unit, StepStatus.running);
    await ssh.runChecked(
        'rm -f /etc/systemd/system/$kServiceUnit && systemctl daemon-reload');
    setStep(_unit, StepStatus.ok);
    log('Auto-start service removed.');
  }

  Future<void> _doDocker() async {
    setStep(_docker, StepStatus.running);
    await ssh.run('docker ps -aq $kContainerFilter | xargs -r docker rm -f');
    final images =
        await ssh.run('docker images -q $kImageRefFilters | sort -u');
    final ids = images.stdout.trim();
    if (ids.isNotEmpty) {
      await ssh.run("docker rmi -f ${ids.split('\n').join(' ')}",
          timeout: const Duration(minutes: 5));
    }
    await ssh.run('docker image prune -f');
    setStep(_docker, StepStatus.ok,
        ids.isEmpty ? 'no image present' : 'image removed');
    log(ids.isEmpty
        ? 'No FaceSnap image was present.'
        : 'Containers and image removed.');
  }

  Future<void> _doLeftovers() async {
    setStep(_leftovers, StepStatus.running);
    final leftovers =
        parseLeftoverTars((await ssh.run(leftoverTarScanCmd())).stdout);
    if (leftovers.isEmpty) {
      setStep(_leftovers, StepStatus.ok, 'none found');
      log('No leftover image .tar files on the kiosk.');
      return;
    }
    final freed = leftovers.fold<int>(0, (sum, f) => sum + f.bytes);
    for (final f in leftovers) {
      log('  leftover image file: ${f.path}');
    }
    await ssh.run(leftoverTarDeleteCmd());
    // Re-scan: a file we could not delete is still a leftover, so it must not
    // be reported as removed.
    final remaining =
        parseLeftoverTars((await ssh.run(leftoverTarScanCmd())).stdout);
    if (remaining.isNotEmpty) {
      setStep(_leftovers, StepStatus.warn,
          '${remaining.length} could not be removed');
      log('WARNING: ${remaining.length} leftover .tar file(s) could not be '
          'removed (${remaining.map((f) => f.path).join(', ')}).');
      return;
    }
    final n = leftovers.length;
    final plural = n == 1 ? '' : 's';
    setStep(_leftovers, StepStatus.ok, '$n removed, ${formatGb(freed)} freed');
    log('Removed $n leftover image .tar file$plural '
        '(${formatGb(freed)} reclaimed).');
    summary.add('Removed $n leftover image .tar file$plural '
        '(${formatGb(freed)}).');
  }

  Future<void> _doConfigs() async {
    if (!deleteConfigs) {
      setStep(_configs, StepStatus.skipped, 'kept — reused by a future install');
      log('Configuration files kept in $kKioskDir (settings and calibration '
          'will be picked up by a future install).');
      summary.add('Configuration files were kept.');
      return;
    }
    setStep(_configs, StepStatus.running);
    await ssh.runChecked('rm -rf $kKioskDir');
    setStep(_configs, StepStatus.ok, 'deleted');
    log('Configuration files deleted ($kKioskDir removed).');
    summary.add('Configuration files were deleted.');
  }

  Future<void> _doVerify() async {
    setStep(_verify, StepStatus.running);
    final images = await ssh
        .run("docker images $kImageRefFilters --format '{{.Repository}}'");
    final containers = await ssh
        .run("docker ps -a $kContainerFilter --format '{{.Names}}'");
    final unit = (await ssh.run('test -f /etc/systemd/system/$kServiceUnit')).ok;
    final leftovers =
        parseLeftoverTars((await ssh.run(leftoverTarScanCmd())).stdout);
    final clean = images.stdout.trim().isEmpty &&
        containers.stdout.trim().isEmpty &&
        !unit &&
        leftovers.isEmpty;
    if (!clean) {
      throw Exception('Removal incomplete: '
          '${images.stdout.trim().isNotEmpty ? "image still present; " : ""}'
          '${containers.stdout.trim().isNotEmpty ? "container still present; " : ""}'
          '${unit ? "service unit still present; " : ""}'
          '${leftovers.isNotEmpty ? "leftover .tar file still present" : ""}');
    }
    final avail = await freeBytes(ssh, '/');
    summary.insert(
        0,
        'FaceSnap server '
        '${_installedVersion.isEmpty ? "" : "$_installedVersion "}removed.');
    summary.add('Free space on the kiosk: ${formatGb(avail)}.');
    setStep(_verify, StepStatus.ok, '${formatGb(avail)} free');
    log('Removal verified. ${formatGb(avail)} free.');
  }
}
