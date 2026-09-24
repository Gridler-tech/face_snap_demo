import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../updater/backup_engine.dart';
import '../updater/batch_runner.dart';
import '../updater/connection_probe.dart';
import '../services/discovery.dart';
import '../updater/fleet.dart';
import '../updater/ui/batch_cards.dart';
import '../updater/ui/fleet_dialogs.dart';
import '../updater/kiosk.dart';
import '../updater/remove_engine.dart';
import '../updater/restore_engine.dart';
import '../updater/server_info.dart';
import '../updater/settings_profile.dart';
import '../services/ssh_runner.dart';
import '../ui/ui.dart';
import '../updater/update_engine.dart';
import '../services/app_config.dart';

/// The Updater page: install, update, back up, restore and remove the
/// FaceSnap server on a kiosk board, single or as a fleet. Formerly the
/// stand-alone updater app; now a page of the operator app, shown only in
/// dev mode because its remove/delete actions are fleet-destructive. The
/// headless bin/ CLIs drive the same engines.
class UpdaterPage extends StatefulWidget {
  const UpdaterPage({super.key});

  @override
  State<UpdaterPage> createState() => _UpdaterPageState();
}

class _UpdaterPageState extends State<UpdaterPage> {
  // No credentials ship in the app: the fields prefill from the saved
  // config.json (%APPDATA%\FaceSnapUpdater) and are saved back when a run
  // starts. A clean-board pick from Search still prefills the published
  // vendor default for that board.
  final _host = TextEditingController(text: AppConfig.host);
  final _user = TextEditingController(text: AppConfig.boardUser);
  final _password = TextEditingController(text: AppConfig.boardPassword);
  bool _obscurePassword = true;
  File? _tar;
  int _tarBytes = 0;

  // Settings profile sent along with the update ('keep' = none). 'recommended'
  // = the built-in one, 'file' = _customProfile.
  String _profileChoice = 'keep';
  SettingsProfile? _customProfile;
  String? _customProfileName;
  String? _profileError;
  bool _readingSettings = false;

  SettingsProfile? get _selectedProfile => switch (_profileChoice) {
        'recommended' => SettingsProfile.recommended(),
        'file' => _customProfile,
        _ => null,
      };

  String _action = 'Update';
  List<UpdateStep>? _runSteps;
  List<String>? _runSummary;
  bool _busy = false;
  bool? _success;
  bool _deleteConfigs = false;
  File? _restoreFile;
  final _logLines = <String>[];
  final _logScroll = ScrollController();

  DateTime? _runStart;
  Timer? _ticker;

  ServerInfoResult? _info;
  bool _infoBusy = false;
  String? _infoError;
  bool _searching = false;

  // Live connection status of the credentials above (connection_probe.dart).
  // The action buttons arm only on a CONNECTED verdict — never on "fields
  // filled in". _probeSeq discards the answer of a probe that was overtaken
  // by a field edit or a newer probe.
  ProbeResult _probe = ProbeResult.idle;
  Timer? _probeDebounce;
  int _probeSeq = 0;

  // ---- batch ("update several kiosks at once") ----------------------------
  // Non-null once a batch has been started; the Update-steps card then shows
  // one row per board instead of a single pipeline. Each board keeps its own
  // engine, so its full step list is there to expand.
  List<BatchProgress>? _batch;
  final _batchEngines = <String, UpdateEngine>{};
  final _batchExpanded = <String>{};
  List<PreflightResult> _batchSkipped = const [];

  /// Boards updated at once. 2 overlaps the slow board-side work; 1 is a
  /// rolling update, for a venue where only one kiosk may be offline.
  int _concurrency = 2;

  @override
  void initState() {
    super.initState();
    // The remembered kiosk is checked straight away, after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runProbe());
  }

  Future<void> _searchKiosks() async {
    setState(() => _searching = true);
    List<DiscoveredKiosk> kiosks;
    try {
      // Provisioned kiosks (_facesnap._tcp) AND clean vendor boards that
      // still answer for their stock hostname ("odroid" / "radxa").
      kiosks = await discoverBoards();
    } catch (e) {
      kiosks = const [];
    } finally {
      setState(() => _searching = false);
    }
    if (!mounted) return;
    if (kiosks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No kiosks or boards found on the network. Kiosks '
              'announce themselves after being installed; clean boards '
              'answer for their stock name (odroid/radxa).')));
      return;
    }
    final choice = await showDialog<DiscoveredKiosk>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Kiosks on the network'),
        children: [
          for (final kiosk in kiosks)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, kiosk),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kiosk.hostName,
                          style: const TextStyle(
                              color: T.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(
                          kiosk.kind == BoardKind.clean
                              ? '${kiosk.ip} — clean board, will be fully '
                                  'set up by "Update server"'
                              : kiosk.ip,
                          style: TextStyle(
                              color: kiosk.kind == BoardKind.clean
                                  ? T.warn
                                  : T.muted,
                              fontSize: 12.5)),
                    ]),
              ),
            ),
        ],
      ),
    );
    if (choice != null) {
      setState(() {
        if (choice.kind == BoardKind.clean) {
          // Clean boards: connect by IP (no .local name registered yet) and
          // prefill the vendor image's default root password.
          _host.text = choice.ip;
          _user.text = 'root';
          _password.text =
              cleanBoardDefaults[choice.hostName] ?? _password.text;
        } else {
          _host.text = choice.hostName;
        }
      });
      _runProbe();
    }
  }

  List<UpdateStep> get _activeSteps => _runSteps ?? _placeholderSteps;

  List<String> get _activeSummary => _runSummary ?? const [];

  /// Remembers the working connection settings for the next launch.
  void _saveConfig() {
    AppConfig.host = _host.text.trim();
    AppConfig.boardUser = _user.text.trim();
    AppConfig.boardPassword = _password.text;
    unawaited(AppConfig.save());
  }

  void _startAction(
      String action, List<UpdateStep> steps, List<String> summary) {
    _saveConfig();
    setState(() {
      _action = action;
      _runSteps = steps;
      _runSummary = summary;
      _busy = true;
      _success = null;
      _logLines.clear();
      _beginRun();
    });
  }

  void _finishAction(bool ok) {
    setState(() {
      _busy = false;
      _success = ok;
      _endRun();
    });
    // The run may have installed, removed or restarted the server: refresh
    // the strip so it shows the kiosk as it is now.
    _runProbe();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _probeDebounce?.cancel();
    super.dispose();
  }

  void _beginRun() {
    _runStart = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  void _endRun() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _pickTar() async {
    const group = XTypeGroup(label: 'Server image', extensions: ['tar']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file != null) {
      final tar = File(file.path);
      final bytes = tar.lengthSync();
      setState(() {
        _tar = tar;
        _tarBytes = bytes;
      });
    }
  }

  Future<void> _chooseProfile(String? choice) async {
    if (choice == null) return;
    if (choice != 'file') {
      setState(() {
        _profileChoice = choice;
        _profileError = null;
      });
      return;
    }
    const group = XTypeGroup(label: 'Settings profile', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) {
      setState(() {}); // cancelled: the dropdown snaps back to the old choice
      return;
    }
    try {
      final profile = SettingsProfile.parse(await file.readAsString());
      setState(() {
        _customProfile = profile;
        _customProfileName = basenameOf(file.path);
        _profileChoice = 'file';
        _profileError = null;
      });
    } on FormatException catch (e) {
      // A rejected profile never becomes the selection.
      setState(() => _profileError = e.message);
    }
  }

  /// The shared confirm dialog of the three destructive actions.
  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: danger
                  ? FilledButton.styleFrom(backgroundColor: T.fail)
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel)),
        ],
      ),
    );
    return confirmed == true;
  }

  bool get _credentialsComplete =>
      _host.text.trim().isNotEmpty &&
      _user.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  /// A credential field changed: the last verdict no longer applies. Show
  /// "Checking…" at once (which disarms the buttons), invalidate any probe in
  /// flight and re-check once typing settles — one SSH attempt per pause, not
  /// one per keystroke.
  void _onCredentialsChanged() {
    _probeSeq++;
    final complete = _credentialsComplete;
    setState(
        () => _probe = complete ? ProbeResult.checking : ProbeResult.idle);
    _probeDebounce?.cancel();
    if (complete) {
      _probeDebounce = Timer(const Duration(milliseconds: 900), _runProbe);
    }
  }

  /// Probe the kiosk now: at start-up, after a Search pick, on "Check again"
  /// and when a run ends (it may have changed what is installed).
  Future<void> _runProbe() async {
    _probeDebounce?.cancel();
    if (_busy) return; // a run owns the connection; re-probed when it ends
    if (!_credentialsComplete) {
      if (_probe.state != ProbeState.idle) {
        setState(() => _probe = ProbeResult.idle);
      }
      return;
    }
    final seq = ++_probeSeq;
    setState(() => _probe = ProbeResult.checking);
    final result = await probeKiosk(
        _host.text.trim(), _user.text.trim(), _password.text);
    // A field changed or a newer probe started meanwhile: this answer is stale.
    if (!mounted || seq != _probeSeq) return;
    setState(() => _probe = result);
  }

  /// Actions arm on a verified connection — the probe said "connected" for
  /// the credentials as they are now — not merely on filled-in fields.
  bool get _connectable => !_busy && !_infoBusy && _probe.connected;

  bool get _ready => _connectable && _tar != null;

  Future<void> _getInfo() async {
    _saveConfig();
    setState(() {
      _infoBusy = true;
      _info = null;
      _infoError = null;
    });
    try {
      final info = await ServerInfo.fetch(
          _host.text.trim(), _user.text.trim(), _password.text);
      setState(() => _info = info);
    } catch (e) {
      setState(() => _infoError = '$e');
    } finally {
      setState(() => _infoBusy = false);
    }
  }

  Future<void> _startUpdate() async {
    final tar = _tar!;
    final host = _host.text.trim();
    final summaryText = 'Kiosk: $host\nImage: ${basenameOf(tar.path)} '
        '(${formatGb(_tarBytes)})\n\n'
        'The server will be offline for the duration of the update '
        '(roughly 5-15 minutes).';

    final profile = _selectedProfile;
    Set<String>? profileRowIds;
    if (profile == null) {
      final confirmed = await _confirm(
          title: 'Update the kiosk server?',
          body: summaryText,
          confirmLabel: 'Update');
      if (!confirmed) return;
    } else {
      // The review list needs the kiosk's CURRENT values, so read them first.
      _saveConfig();
      setState(() => _readingSettings = true);
      List<ProfileChange> rows;
      try {
        final ssh = await SshRunner.connect(
            host, _user.text.trim(), _password.text);
        try {
          rows = profile.diff(await readKioskSettings(ssh));
        } finally {
          ssh.close();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _readingSettings = false);
          await _confirm(
              title: "Could not read the kiosk's settings",
              body: "The settings profile needs the kiosk's current settings "
                  'for the review list, but $host did not answer:\n\n'
                  '${shorten('$e')}',
              confirmLabel: 'OK');
        }
        return;
      }
      if (!mounted) return;
      setState(() => _readingSettings = false);
      profileRowIds = await showDialog<Set<String>>(
        context: context,
        builder: (context) => ProfileReviewDialog(
            summaryText: summaryText, profile: profile, rows: rows),
      );
      if (profileRowIds == null) return; // cancelled
    }

    final engine = UpdateEngine(
      host: host,
      user: _user.text.trim(),
      password: _password.text,
      tarFile: tar,
      onChanged: () => setState(() {}),
      onLog: _appendLog,
      profile: profile,
      profileRowIds: profileRowIds,
    );
    _startAction('Update', engine.steps, engine.summary);
    _finishAction(await engine.run());
  }

  void _appendLog(String line) => setState(() {
        _logLines.add(line);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logScroll.hasClients) {
            _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
          }
        });
      });

  Future<void> _startBackup() async {
    final host = _host.text.trim();
    final now = DateTime.now();
    final stamp = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}';
    final location = await getSaveLocation(
      suggestedName: 'Backup_$stamp.tgz',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Backup archive', extensions: ['tgz'])
      ],
    );
    if (location == null) return;

    final engine = BackupEngine(
      host: host,
      user: _user.text.trim(),
      password: _password.text,
      backupPath: location.path,
      onChanged: () => setState(() {}),
      onLog: _appendLog,
    );
    _startAction('Backup', engine.steps, engine.summary);
    _finishAction(await engine.run());
  }

  Future<void> _pickRestoreFile() async {
    const group =
        XTypeGroup(label: 'Configuration backup', extensions: ['tgz']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file != null) setState(() => _restoreFile = File(file.path));
  }

  Future<void> _startRestore() async {
    final host = _host.text.trim();
    final restoreFile = _restoreFile;
    if (restoreFile == null) return;

    final confirmed = await _confirm(
      title: 'Restore configuration files?',
      body: 'Kiosk: $host\n'
          'Backup: ${basenameOf(restoreFile.path)}\n\n'
          'The configuration files (settings and camera calibration) on '
          'the kiosk are replaced by the ones in this backup. If the '
          'server is installed it is restarted, which takes about a '
          'minute.',
      confirmLabel: 'Restore',
    );
    if (!confirmed) return;

    final engine = RestoreEngine(
      host: host,
      user: _user.text.trim(),
      password: _password.text,
      backupFile: restoreFile,
      onChanged: () => setState(() {}),
      onLog: _appendLog,
    );
    _startAction('Restore', engine.steps, engine.summary);
    _finishAction(await engine.run());
  }

  Future<void> _startRemove() async {
    final host = _host.text.trim();
    final confirmed = await _confirm(
      title: 'Remove the FaceSnap server?',
      body: 'Kiosk: $host\n\n'
          'This stops the server, disables start on boot and removes the '
          'server image from the kiosk.\n\n'
          '${_deleteConfigs ? 'The configuration files (settings and camera '
              'calibration) will ALSO BE DELETED from the kiosk. Use '
              '"Backup configuration files" first if you have no backup '
              'yet.' : 'The configuration files (settings and camera '
              'calibration) are kept on the kiosk and will be reused by a '
              'future install.'}',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!confirmed) return;

    final engine = RemoveEngine(
      host: host,
      user: _user.text.trim(),
      password: _password.text,
      deleteConfigs: _deleteConfigs,
      onChanged: () => setState(() {}),
      onLog: _appendLog,
    );
    _startAction('Removal', engine.steps, engine.summary);
    _finishAction(await engine.run());
  }

  // ---- batch update ------------------------------------------------------

  /// Update several kiosks with one image: discover -> pick the fleet ->
  /// pre-flight every board -> run them with the concurrency cap. A board that
  /// fails never stops the others, and one that cannot be reached is excluded
  /// up front rather than failing halfway through.
  Future<void> _startBatchUpdate() async {
    // 1. Discover, and offer the fleet. Deliberately BEFORE asking for the
    // image: choosing which kiosks needs no image, and "who, then what" is the
    // order the job is actually thought about.
    setState(() => _searching = true);
    List<DiscoveredKiosk> found;
    try {
      found = await discoverBoards();
    } catch (_) {
      found = const [];
    }
    if (!mounted) return;
    setState(() => _searching = false);
    if (found.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No kiosks found on the network.')));
      return;
    }

    final picked = await showDialog<List<FleetEntry>>(
      context: context,
      builder: (context) => FleetPickerDialog(
        entries: mergeDiscovery(const [], found),
        defaultUser: _user.text.trim(),
        defaultPassword: _password.text,
        onRescan: () async =>
            mergeDiscovery(const [], await discoverBoards()),
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;

    // 2. From here an image IS needed, so ask for it now rather than having
    // blocked the picker on it.
    if (_tar == null) {
      await _pickTar();
      if (!mounted) return;
      if (_tar == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Choose a server image to update the selected kiosks.')));
        return;
      }
    }
    final tar = _tar!;

    final targets = selectedTargets(picked,
        defaultUser: _user.text.trim(), defaultPassword: _password.text);

    // 3. Pre-flight EVERY board before touching any of them.
    _saveConfig();
    setState(() {
      _readingSettings = true;
      _logLines.clear();
      _appendLog('Pre-flight on ${targets.length} board(s) …');
    });
    final checks = await runPreflight(
      targets: targets,
      check: (target) async {
        final r =
            await probeKiosk(target.host, target.user, target.password);
        final verdict = switch (r.state) {
          ProbeState.connected => PreflightVerdict.ok,
          ProbeState.authFailed => PreflightVerdict.authFailed,
          ProbeState.wrongArch => PreflightVerdict.wrongArch,
          _ => PreflightVerdict.unreachable,
        };
        return PreflightResult(target, verdict,
            detail: verdict == PreflightVerdict.ok
                ? '${r.model}, ${r.installedVersion ?? "clean board"}'
                : probeHeadline(r),
            installedVersion: r.installedVersion);
      },
      onResult: (r) => _appendLog(
          '  ${r.ok ? "OK  " : "SKIP"}  ${r.target.title}  ${r.detail}'),
    );
    if (!mounted) return;
    setState(() => _readingSettings = false);

    final go = await showDialog<bool>(
      context: context,
      builder: (context) => PreflightDialog(
        results: checks,
        imageName: '${basenameOf(tar.path)} (${formatGb(_tarBytes)})',
        profileName: switch (_profileChoice) {
          'recommended' => 'apply the recommended Server 2.0 settings',
          'file' => 'apply $_customProfileName',
          _ => null,
        },
        concurrency: _concurrency,
      ),
    );
    if (go != true || !mounted) return;

    // 4. Run.
    final good = [for (final c in checks.where((c) => c.ok)) c.target];
    final profile = _selectedProfile;
    final boards = [for (final t in good) BatchProgress(t)];
    _batchEngines.clear();
    _batchExpanded.clear();
    setState(() {
      _batch = boards;
      _batchSkipped = checks.where((c) => !c.ok).toList();
      _action = 'Batch update';
      _runSteps = null;
      _runSummary = null;
      _success = null;
      _busy = true;
      _beginRun();
    });

    BatchProgress board(BatchTarget t) =>
        boards.firstWhere((b) => b.target.host == t.host);

    final outcomes = await runBatch(
      targets: good,
      concurrency: _concurrency,
      onStart: (t) => setState(() {
        board(t)
          ..phase = BatchPhase.running
          ..step = 'starting …';
      }),
      onDone: (o) => setState(() {
        board(o.target)
          ..phase = o.succeeded ? BatchPhase.succeeded : BatchPhase.failed
          ..elapsed = o.elapsed
          ..step = o.succeeded
              ? 'updated'
              : (_batchEngines[o.target.host]
                      ?.steps
                      .where((s) => s.status == StepStatus.fail)
                      .map((s) => s.detail.isEmpty ? s.title : s.detail)
                      .firstOrNull ??
                  'failed');
      }),
      action: (target) async {
        final engine = UpdateEngine(
          host: target.host,
          user: target.user,
          password: target.password,
          tarFile: tar,
          // Repaint the board's card as its pipeline advances.
          onChanged: () => setState(() {
            final running = _batchEngines[target.host]
                ?.steps
                .where((s) => s.status == StepStatus.running)
                .firstOrNull;
            if (running != null) board(target).step = running.title;
          }),
          // One interleaved log, prefixed so parallel boards stay readable.
          onLog: (line) => _appendLog('[${target.title}] $line'),
          profile: profile,
        );
        _batchEngines[target.host] = engine;
        return engine.run();
      },
    );
    if (!mounted) return;

    final report =
        batchReport('Update', outcomes, skipped: _batchSkipped);
    for (final line in report) {
      _appendLog(line);
    }
    setState(() {
      _busy = false;
      _success = outcomes.every((o) => o.succeeded) && _batchSkipped.isEmpty;
      _runSummary = report;
      _endRun();
    });
  }

  static const _logMinHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(children: [
                  SectionCard(
                      title: 'Kiosk & image', shrinkWrap: true, child: _form()),
                  const SizedBox(height: 14),
                  if (_success != null)
                    SectionCard(
                        title: 'Result', shrinkWrap: true, child: _result()),
                  if (_infoBusy || _info != null || _infoError != null)
                    SectionCard(
                        title: 'Server info',
                        shrinkWrap: true,
                        child: _infoView()),
                ]),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              // The log fills what the steps card leaves of the window; in a
              // window too short for that it keeps a usable height and the
              // pane scrolls instead of overflowing.
              child: CustomScrollView(clipBehavior: Clip.none, slivers: [
                SliverToBoxAdapter(
                  child: SectionCard(
                      title: _batch == null
                          ? 'Update steps'
                          : 'Batch — ${_batch!.length} kiosks',
                      shrinkWrap: true,
                      child: _batch == null ? _steps() : _batchView()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverLayoutBuilder(
                  builder: (context, sliver) => SliverToBoxAdapter(
                    child: SizedBox(
                      height: max(
                          _logMinHeight,
                          sliver.viewportMainAxisExtent -
                              sliver.precedingScrollExtent),
                      // The fill card's child must be flexed itself:
                      // SectionCard puts it in a Column, which would hand the
                      // log's ListView an unbounded height (no scrolling, no
                      // follow-the-tail).
                      child: SectionCard(
                          title: 'Log', child: Expanded(child: _logView())),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const RowLabel('Kiosk (name or IP address)'),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
          child: TextField(
              controller: _host,
              enabled: !_busy,
              decoration: _fieldDecoration('use Search or enter an IP'),
              onChanged: (_) => _onCredentialsChanged()),
        ),
        const SizedBox(width: 10),
        QuietButton(
            text: _searching ? 'Searching…' : 'Search',
            onPressed: (_busy || _searching) ? null : _searchKiosks),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const RowLabel('User'),
            const SizedBox(height: 6),
            TextField(
                controller: _user,
                enabled: !_busy,
                decoration: _fieldDecoration('root'),
                onChanged: (_) => _onCredentialsChanged()),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const RowLabel('Password'),
            const SizedBox(height: 6),
            TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: _obscurePassword,
                decoration: _fieldDecoration('').copyWith(
                  // Eye toggle to reveal the password (off by default).
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: T.muted),
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onChanged: (_) => _onCredentialsChanged()),
          ]),
        ),
      ]),
      const SizedBox(height: 10),
      _connectionStrip(),
      const SizedBox(height: 12),
      const RowLabel('Server image (.tar)'),
      const SizedBox(height: 6),
      Row(children: [
        QuietButton(text: 'Choose file…', onPressed: _busy ? null : _pickTar),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _tar == null
                  ? 'No file selected'
                  : '${basenameOf(_tar!.path)}\n${formatGb(_tarBytes)}',
              style: const TextStyle(color: T.muted, fontSize: 12.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            // Same version / downgrade / upgrade against what the probe found
            // installed — right where the operator is choosing.
            if (imageVersionNote(_probe.installedVersion,
                    _tar == null ? null : basenameOf(_tar!.path))
                case final note?)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(note.text,
                    style: TextStyle(
                        color: note.warn ? T.warn : T.pass,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      const RowLabel('Settings on the kiosk'),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        // Keyed on the choice so a cancelled/rejected file pick snaps back.
        key: ValueKey('$_profileChoice/$_customProfileName'),
        initialValue: _profileChoice,
        isExpanded: true,
        decoration: _fieldDecoration(''),
        style: const TextStyle(color: T.ink, fontSize: 13.5),
        onChanged: _busy ? null : _chooseProfile,
        items: [
          const DropdownMenuItem(
              value: 'keep', child: Text("Keep the kiosk's settings")),
          const DropdownMenuItem(
              value: 'recommended',
              child: Text('Apply the recommended Server 2.0 settings')),
          DropdownMenuItem(
              value: 'file',
              child: Text(
                  _customProfileName == null
                      ? 'Apply a profile file…'
                      : 'Profile file: $_customProfileName',
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
      if (_profileError != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_profileError!,
              style: const TextStyle(color: T.fail, fontSize: 12.5)),
        )
      else if (_profileChoice != 'keep')
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
              'You review every change per kiosk before the update starts. '
              'Calibration and camera tuning are never touched.',
              style: TextStyle(color: T.muted, fontSize: 12.5)),
        ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: GoButton(
              text: _busy
                  ? 'Working…'
                  : _readingSettings
                      ? 'Reading settings…'
                      : 'Update server',
              onPressed: _ready && !_readingSettings ? _startUpdate : null),
        ),
        const SizedBox(width: 10),
        QuietButton(
            text: _infoBusy ? 'Reading…' : 'Get server info',
            onPressed: _connectable ? _getInfo : null),
      ]),
      const SizedBox(height: 10),
      // Batch: the fleet is chosen in the picker and each board is verified by
      // the pre-flight, so this needs neither a verified single-host
      // connection (unlike the buttons above) nor an image up front — the
      // image is asked for after the kiosks are picked.
      Row(children: [
        Expanded(
          child: QuietButton(
              text: _searching
                  ? 'Searching…'
                  : 'Update several kiosks at once…',
              onPressed:
                  (_busy || _searching) ? null : _startBatchUpdate),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Kiosks updated at the same time.\n'
              '1 = rolling: only one kiosk is offline at a time.',
          child: DropdownButton<int>(
            value: _concurrency,
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: T.ink, fontSize: 13),
            onChanged: _busy
                ? null
                : (v) => setState(() => _concurrency = v ?? 2),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 at a time')),
              DropdownMenuItem(value: 2, child: Text('2 at a time')),
              DropdownMenuItem(value: 3, child: Text('3 at a time')),
            ],
          ),
        ),
      ]),
      if (_tar == null)
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Pick the kiosks first — the image is chosen after.',
              style: TextStyle(color: T.muted, fontSize: 12)),
        ),
      const SizedBox(height: 18),
      const Divider(color: T.cardStroke, height: 1),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: QuietButton(
              text: 'Backup configuration files…',
              onPressed: _connectable ? _startBackup : null),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        QuietButton(
            text: 'Choose backup…',
            onPressed: _busy ? null : _pickRestoreFile),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _restoreFile == null
                ? 'No backup file selected'
                : _restoreFile!.uri.pathSegments.last,
            style: const TextStyle(color: T.muted, fontSize: 12.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
          child: QuietButton(
              text: 'Restore configuration files',
              onPressed:
                  (_connectable && _restoreFile != null) ? _startRestore : null),
        ),
      ]),
      const SizedBox(height: 18),
      const Divider(color: T.cardStroke, height: 1),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _connectable ? _startRemove : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: T.fail,
              side: const BorderSide(color: T.fail),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove server installation',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Text(
            'Also delete configuration files (settings, camera calibration)',
            style: TextStyle(
                color: _deleteConfigs ? T.fail : T.muted, fontSize: 12.5),
          ),
        ),
        Switch(
          value: _deleteConfigs,
          activeTrackColor: T.fail,
          onChanged:
              _busy ? null : (v) => setState(() => _deleteConfigs = v),
        ),
      ]),
    ]);
  }

  Widget _infoView() {
    if (_infoBusy) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Row(children: [
          SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4)),
          SizedBox(width: 12),
          Text('Reading kiosk…', style: TextStyle(color: T.muted, fontSize: 13)),
        ]),
      );
    }
    if (_infoError != null) {
      return Text('Could not read the kiosk:\n$_infoError',
          style: const TextStyle(color: T.fail, fontSize: 12.5, height: 1.4));
    }
    final info = _info!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _infoGroup('FaceSnap server', info.server),
      const SizedBox(height: 10),
      _infoGroup('System', info.system),
      const SizedBox(height: 10),
      const Text('CONFIGURATION',
          style: TextStyle(
              color: T.titleBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
      for (final entry in info.configs.entries) ...[
        const SizedBox(height: 8),
        Text(entry.key,
            style: const TextStyle(
                color: T.ink, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: T.cardStroke),
          ),
          child: Text(entry.value,
              style: const TextStyle(
                  color: T.ink,
                  fontSize: 11,
                  height: 1.45,
                  fontFamily: 'Consolas',
                  fontFamilyFallback: ['Courier New', 'monospace'])),
        ),
      ],
    ]);
  }

  Widget _infoGroup(String title, List<(String, String)> rows) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(),
          style: const TextStyle(
              color: T.titleBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
      const SizedBox(height: 6),
      for (final (label, value) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 110,
                child: Text(label,
                    style: const TextStyle(color: T.muted, fontSize: 12.5))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(color: T.ink, fontSize: 12.5))),
          ]),
        ),
    ]);
  }

  /// The connection status strip under the credentials: reachable? logged in?
  /// what is installed? Its verdict is what arms the action buttons.
  Widget _connectionStrip() {
    final r = _probe;
    final failed = r.settled && !r.connected;
    final tint = r.connected
        ? T.passTint
        : failed
            ? T.failTint
            : T.ground;
    final headline = r.connected
        ? T.ink
        : failed
            ? T.fail
            : T.muted;
    const size = 16.0;
    final Widget icon = switch (r.state) {
      ProbeState.checking => const SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(strokeWidth: 2.2)),
      ProbeState.connected =>
        const Icon(Icons.check_circle, size: size, color: T.pass),
      ProbeState.idle => const Icon(Icons.radio_button_unchecked,
          size: size, color: T.pending),
      _ => const Icon(Icons.cancel, size: size, color: T.fail),
    };
    final detail = probeDetail(r);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration:
          BoxDecoration(color: tint, borderRadius: BorderRadius.circular(8)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: icon),
        const SizedBox(width: 8),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(probeHeadline(r),
                style: TextStyle(
                    color: headline,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(detail,
                    style: const TextStyle(color: T.muted, fontSize: 12.5)),
              ),
          ]),
        ),
        if (r.settled)
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: T.muted,
            tooltip: 'Check again',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
            onPressed: _busy ? null : _runProbe,
          ),
      ]),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: T.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: T.titleBlue)),
      );

  /// The batch view: one card per board, newest state first-hand from its own
  /// engine. Replaces the single pipeline in the Update-steps card.
  Widget _batchView() {
    final boards = _batch!;
    final elapsed =
        _runStart == null ? null : DateTime.now().difference(_runStart!);
    final done = boards.where((b) =>
        b.phase == BatchPhase.succeeded || b.phase == BatchPhase.failed);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          const Icon(Icons.schedule, size: 15, color: T.muted),
          const SizedBox(width: 6),
          Text(
            '${_busy ? 'Elapsed' : 'Total time'}: '
            '${elapsed == null ? '-' : formatDuration(elapsed)}'
            '   ·   ${done.length} of ${boards.length} finished'
            '${_concurrency == 1 ? '   ·   rolling' : '   ·   $_concurrency at a time'}',
            style: const TextStyle(color: T.muted, fontSize: 12.5),
          ),
        ]),
      ),
      for (final board in boards)
        BatchBoardCard(
          title: board.target.title,
          phase: board.phase,
          detail: board.step,
          elapsed: board.elapsed == Duration.zero ? null : board.elapsed,
          steps: _batchEngines[board.target.host]?.steps ?? const [],
          expanded: _batchExpanded.contains(board.target.host),
          onToggle: () => setState(() {
            final host = board.target.host;
            _batchExpanded.contains(host)
                ? _batchExpanded.remove(host)
                : _batchExpanded.add(host);
          }),
        ),
      for (final skipped in _batchSkipped)
        BatchBoardCard(
          title: skipped.target.title,
          phase: BatchPhase.skipped,
          detail: skipped.detail,
        ),
    ]);
  }

  Widget _steps() {
    final steps = _activeSteps;
    final elapsed =
        _runStart == null ? null : DateTime.now().difference(_runStart!);
    // The title keeps its natural width while it fits (the detail takes the
    // rest) and ellipsizes once the window gets too narrow for it, instead of
    // overflowing the row.
    return LayoutBuilder(builder: (context, box) {
      final titleMax = (box.maxWidth - _stepIconSize - 2 * _stepGap)
          .clamp(0.0, double.infinity);
      return _stepRows(steps, elapsed, titleMax);
    });
  }

  static const _stepIconSize = 20.0;
  static const _stepGap = 12.0;

  Widget _stepRows(List<UpdateStep> steps, Duration? elapsed, double titleMax) {
    return Column(children: [
      if (elapsed != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            const Icon(Icons.schedule, size: 15, color: T.muted),
            const SizedBox(width: 6),
            Text(
              '${_busy ? 'Elapsed' : 'Total time'}: '
              '${formatDuration(elapsed)}',
              style: const TextStyle(color: T.muted, fontSize: 12.5),
            ),
          ]),
        ),
      for (final step in steps)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            _statusIcon(step.status),
            const SizedBox(width: _stepGap),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: titleMax),
              child: Text(step.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color:
                          step.status == StepStatus.pending ? T.muted : T.ink,
                      fontSize: 13.5,
                      fontWeight: step.status == StepStatus.running
                          ? FontWeight.w700
                          : FontWeight.w400)),
            ),
            const SizedBox(width: _stepGap),
            Expanded(
              child: Text(step.detail,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: _statusColor(step.status), fontSize: 12.5)),
            ),
          ]),
        ),
    ]);
  }

  static final _placeholderSteps = [
    for (final title in UpdateEngine.stepTitles) UpdateStep(title)
  ];

  Color _statusColor(StepStatus status) => switch (status) {
        StepStatus.ok => T.pass,
        StepStatus.fail => T.fail,
        StepStatus.warn => T.warn,
        StepStatus.running => T.titleBlue,
        _ => T.muted,
      };

  Widget _statusIcon(StepStatus status) {
    const size = _stepIconSize;
    return switch (status) {
      StepStatus.pending =>
        const Icon(Icons.radio_button_unchecked, size: size, color: T.pending),
      StepStatus.running => const SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(strokeWidth: 2.4)),
      StepStatus.ok =>
        const Icon(Icons.check_circle, size: size, color: T.pass),
      StepStatus.warn => const Icon(Icons.warning_amber_rounded,
          size: size, color: T.warn),
      StepStatus.fail => const Icon(Icons.cancel, size: size, color: T.fail),
      StepStatus.skipped =>
        const Icon(Icons.remove_circle_outline, size: size, color: T.pending),
    };
  }

  Widget _result() {
    final ok = _success == true;
    final action = _action;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ok ? T.passTint : T.failTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(ok ? '$action successful' : '$action failed',
            style: TextStyle(
                color: ok ? T.pass : T.fail, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 10),
      for (final line in _activeSummary)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('•  $line',
              style: const TextStyle(color: T.ink, fontSize: 13, height: 1.4)),
        ),
    ]);
  }

  Widget _logView() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: T.cardStroke),
      ),
      padding: const EdgeInsets.all(10),
      child: ListView.builder(
        controller: _logScroll,
        itemCount: _logLines.length,
        itemBuilder: (context, i) => Text(
          _logLines[i],
          style: const TextStyle(
              color: T.ink,
              fontSize: 12,
              height: 1.5,
              fontFamily: 'Consolas',
              fontFamilyFallback: ['Courier New', 'monospace']),
        ),
      ),
    );
  }
}

/// The per-kiosk review of a settings profile, doubling as the update's
/// confirmation: every setting with the kiosk's value and the profile's, a
/// tick per row. Pops the ticked row ids (possibly empty = update without
/// changing settings) or null on Cancel.
class ProfileReviewDialog extends StatefulWidget {
  const ProfileReviewDialog({
    super.key,
    required this.summaryText,
    required this.profile,
    required this.rows,
  });

  final String summaryText;
  final SettingsProfile profile;
  final List<ProfileChange> rows;

  @override
  State<ProfileReviewDialog> createState() => _ProfileReviewDialogState();
}

class _ProfileReviewDialogState extends State<ProfileReviewDialog> {
  late final Set<String> _ticked = {
    for (final row in widget.rows)
      if (row.differs) row.id
  };

  @override
  Widget build(BuildContext context) {
    final changing = widget.rows.where((r) => r.differs).length;
    return AlertDialog(
      title: const Text('Update the kiosk server?'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.summaryText),
            const SizedBox(height: 14),
            Text(widget.profile.name,
                style: const TextStyle(
                    color: T.titleBlue, fontWeight: FontWeight.w700)),
            if (widget.profile.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(widget.profile.description,
                    style: const TextStyle(color: T.muted, fontSize: 12.5)),
              ),
            const SizedBox(height: 8),
            Text(
                changing == 0
                    ? 'This kiosk already has every value of the profile.'
                    : 'Untick what this kiosk should keep:',
                style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: Column(children: [
                  for (final row in widget.rows) _buildRow(row),
                ]),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _ticked),
            child: const Text('Update')),
      ],
    );
  }

  Widget _buildRow(ProfileChange row) {
    final muted = !row.differs;
    final color = muted ? T.muted : T.ink;
    return Row(children: [
      Checkbox(
        value: _ticked.contains(row.id),
        onChanged: muted
            ? null
            : (on) => setState(() =>
                on == true ? _ticked.add(row.id) : _ticked.remove(row.id)),
      ),
      Expanded(
          flex: 5,
          child: Text(row.label, style: TextStyle(color: color, fontSize: 13))),
      Expanded(
        flex: 5,
        child: Text(
            muted
                ? '${row.newText} (already set)'
                : '${row.currentText}  →  ${row.newText}',
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: muted ? FontWeight.w400 : FontWeight.w600)),
      ),
    ]);
  }
}
