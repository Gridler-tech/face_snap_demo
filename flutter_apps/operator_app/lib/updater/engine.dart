// Shared scaffolding for the update/backup/restore/remove pipelines: the
// step model, the guarded run wrapper (fail the running steps, summary,
// total time, SSH cleanup) and the identical connect-and-identify first step.
import 'kiosk.dart';
import '../services/ssh_runner.dart';

enum StepStatus { pending, running, ok, warn, fail, skipped }

class UpdateStep {
  UpdateStep(this.title);

  final String title;
  StepStatus status = StepStatus.pending;
  String detail = '';
}

String formatDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return minutes > 0 ? '$minutes min $seconds s' : '$seconds s';
}

/// Caps exception text so a step's one-line detail stays readable.
String shorten(String s) => s.length > 220 ? '${s.substring(0, 220)}…' : s;

abstract class KioskEngine {
  KioskEngine({
    required this.host,
    required this.user,
    required this.password,
    required this.onChanged,
    required this.onLog,
  });

  final String host;
  final String user;
  final String password;
  final void Function() onChanged;
  final void Function(String line) onLog;

  /// Human summary lines set as the run progresses; shown in the result card.
  final summary = <String>[];

  List<UpdateStep> get steps;

  SshRunner? sshOrNull;
  SshRunner get ssh => sshOrNull!;

  void log(String line) => onLog(line);

  void setStep(UpdateStep step, StepStatus status, [String detail = '']) {
    step.status = status;
    if (detail.isNotEmpty) step.detail = detail;
    onChanged();
  }

  /// Runs a pipeline [body]: on error the running steps are marked failed and
  /// "[noun] failed" is added to the summary; the total time and the SSH
  /// close always happen. [beforeClose] runs in the finally (fire-and-forget
  /// remote cleanup, e.g. removing a staging file).
  Future<bool> runGuarded(String noun, Future<bool> Function() body,
      {void Function()? beforeClose}) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await body();
    } catch (e) {
      for (final step in steps.where((s) => s.status == StepStatus.running)) {
        setStep(step, StepStatus.fail, shorten('$e'));
      }
      log('FAILED: $e');
      summary.add('$noun failed: ${shorten('$e')}');
      return false;
    } finally {
      summary.add('Total time: ${formatDuration(stopwatch.elapsed)}.');
      beforeClose?.call();
      sshOrNull?.close();
    }
  }

  /// First step of every pipeline: connect and identify the board.
  Future<void> connectStep(UpdateStep step) async {
    setStep(step, StepStatus.running);
    log('Connecting to $user@$host …');
    sshOrNull = await SshRunner.connect(host, user, password);
    final id = await identifyBoard(ssh);
    if (id.arch != 'aarch64') {
      throw Exception('Target is ${id.arch}, expected aarch64 (Odroid). '
          'Is $host the right machine?');
    }
    setStep(step, StepStatus.ok, id.model);
    log('Connected: ${id.model} (${id.arch})');
  }
}
