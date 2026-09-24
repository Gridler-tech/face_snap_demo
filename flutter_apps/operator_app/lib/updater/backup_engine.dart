// Downloads the kiosk's configuration files (settings, camera calibration,
// compose file) as a tgz to this machine. Read-only: the server keeps running.
import 'engine.dart';
import 'kiosk.dart';

class BackupEngine extends KioskEngine {
  BackupEngine({
    required super.host,
    required super.user,
    required super.password,
    required this.backupPath,
    required super.onChanged,
    required super.onLog,
  });

  /// Local (Windows) destination for the tgz.
  final String backupPath;

  @override
  final List<UpdateStep> steps = [
    UpdateStep('Connect to the kiosk'),
    UpdateStep('Inspect the configuration'),
    UpdateStep('Back up configuration files'),
  ];

  UpdateStep get _connect => steps[0];
  UpdateStep get _inspect => steps[1];
  UpdateStep get _backup => steps[2];

  Future<bool> run() => runGuarded('Backup', () async {
        await connectStep(_connect);
        await _doInspect();
        await _doBackup();
        return true;
      }, beforeClose: () => sshOrNull?.run('rm -f $kConfigBackupTgz').ignore());

  Future<void> _doInspect() async {
    setStep(_inspect, StepStatus.running);
    if (!(await ssh.run('test -d $kKioskDir/data')).ok) {
      throw Exception('No configuration files on the kiosk '
          '($kKioskDir/data does not exist) — nothing to back up.');
    }
    final files = await ssh.runChecked('ls $kKioskDir/data/');
    final names =
        files.stdout.split('\n').where((l) => l.trim().isNotEmpty).toList();
    setStep(_inspect, StepStatus.ok, '${names.length} file(s)');
    log('Configuration files: ${names.join(', ')}');
  }

  Future<void> _doBackup() async {
    setStep(_backup, StepStatus.running);
    await backupKioskConfigTo(ssh, backupPath);
    setStep(_backup, StepStatus.ok, basenameOf(backupPath));
    log('Configuration backed up to $backupPath');
    summary.add('Configuration backed up to $backupPath');
  }
}
