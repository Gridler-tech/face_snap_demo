// Connection cards: server process controls for this PC (start/stop +
// autostart, only where the server runs locally) and for a remote kiosk board
// (over SSH). Formerly their own Connection page; now embedded on the Kiosk
// page. Manual address entry lives in the server picker dialog.
import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/board_server_manager.dart';
import '../services/server_manager.dart';
import '../services/settings_state.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';

class ConnectionCards extends StatefulWidget {
  const ConnectionCards({super.key});

  @override
  State<ConnectionCards> createState() => _ConnectionCardsState();
}

class _ConnectionCardsState extends State<ConnectionCards> {
  String? _message;

  // Server card state (Windows, server installed locally).
  bool? _serverRunning;
  bool _serverBusy = false;
  bool _autostart = false;

  // Board server card state (remote kiosk board over SSH).
  BoardServerStatus? _boardStatus;
  bool _boardBusy = false;

  @override
  void initState() {
    super.initState();
    if (ServerManager.applicable) _refreshServerState();
    if (BoardServerManager.isRemoteHost(AppConfig.host)) _refreshBoardStatus();
  }

  Future<void> _refreshServerState() async {
    // Independent PowerShell probes — run them concurrently.
    final [running, autostart] = await Future.wait([
      ServerManager.isRunning(AppConfig.port),
      ServerManager.isAutostartEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _serverRunning = running;
      _autostart = autostart;
    });
  }

  Future<void> _toggleServer() async {
    final starting = _serverRunning != true;
    setState(() => _serverBusy = true);
    try {
      if (starting) {
        await ServerManager.start();
      } else {
        await ServerManager.stop(AppConfig.port);
      }
      // Poll until the port reaches the expected state: the frozen server
      // needs tens of seconds to boot (model imports) before it binds, so a
      // single early probe would report "not running" and never re-check.
      for (var attempt = 0; attempt < 40; attempt++) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        if (await ServerManager.isRunning(AppConfig.port) == starting) break;
      }
      if (starting) {
        // The server is up — load the settings snapshot so every page leaves
        // its "No server connected" state (they listen to the revision).
        try {
          await SettingsState.refresh();
        } catch (_) {/* port open but not answering yet — picker still works */}
      }
      await _refreshServerState();
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Server control failed: ${operatorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _serverBusy = false);
    }
  }

  Future<void> _refreshBoardStatus() async {
    final host = AppConfig.host;
    setState(() => _boardStatus = null);
    final status = await BoardServerManager.status(host);
    // The address may have changed while the SSH probe ran.
    if (!mounted || AppConfig.host != host) return;
    setState(() => _boardStatus = status);
  }

  Future<void> _changeBoardPassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeBoardPasswordDialog(
          host: AppConfig.host, user: AppConfig.boardUser),
    );
    if (changed == true && mounted) {
      setState(() => _message = null);
      // The stored credential is now the new one — re-probe with it.
      await _refreshBoardStatus();
    }
  }

  Future<void> _boardAction(Future<void> Function(String host) action) async {
    final host = AppConfig.host;
    setState(() => _boardBusy = true);
    try {
      await action(host);
      if (!mounted) return;
      setState(() => _message = null);
    } catch (e) {
      if (mounted) {
        setState(
            () => _message = 'Board server control failed: ${operatorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _boardBusy = false);
    }
    if (mounted) await _refreshBoardStatus();
  }

  @override
  Widget build(BuildContext context) {
    // Rendered inside the Kiosk page's (scrolling) column — no scroll view or
    // page padding of its own; spacing between cards only, the page spaces
    // around the widget.
    final cards = <Widget>[
      if (ServerManager.applicable)
        SectionCard(
            title: 'Server (this PC)',
            titleLeading: const DevInfoBadge('server-local'),
            child: _buildServer()),
      if (BoardServerManager.isRemoteHost(AppConfig.host))
        SectionCard(
            title: 'Server (remote kiosk PC)',
            titleLeading: const DevInfoBadge('server-board'),
            child: _buildBoard()),
    ];
    return Column(spacing: 14, children: [
      ...cards,
      ErrorLine(_message),
    ]);
  }

  Widget _buildServer() {
    final running = _serverRunning;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: RowLabel(running == null
              ? 'Checking…'
              : running
                  ? 'Server is running'
                  : 'Server is not running'),
        ),
        const SizedBox(width: 24),
        QuietButton(
          text: _serverBusy
              ? 'Working…'
              : running == true
                  ? 'Stop server'
                  : 'Start server',
          width: 160,
          onPressed: (_serverBusy || running == null) ? null : _toggleServer,
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Switch(
            value: _autostart,
            onChanged: (v) async {
              setState(() => _autostart = v);
              try {
                await ServerManager.setAutostart(v);
              } catch (e) {
                if (mounted) {
                  setState(() =>
                      _message = 'Autostart change failed: ${operatorMessage(e)}');
                }
              }
            }),
        const SizedBox(width: 8),
        const Expanded(
            child: RowLabel('Start the server automatically at logon')),
      ]),
    ]);
  }

  Widget _buildBoard() {
    final status = _boardStatus;
    final label = switch (status) {
      null => 'Checking…',
      BoardServerStatus.running => 'Server is running on ${AppConfig.host}',
      BoardServerStatus.stopped => 'Server is not running on ${AppConfig.host}',
      BoardServerStatus.unreachable => 'No SSH access to ${AppConfig.host}',
      BoardServerStatus.noCredentials =>
        'Set board_user / board_password in config.json first',
    };
    final running = status == BoardServerStatus.running;
    final controllable = !_boardBusy &&
        (status == BoardServerStatus.running ||
            status == BoardServerStatus.stopped);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: RowLabel(label)),
        const SizedBox(width: 12),
        QuietButton(
          text: 'Refresh',
          width: 100,
          onPressed:
              (_boardBusy || status == null) ? null : _refreshBoardStatus,
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        QuietButton(
          text: _boardBusy
              ? 'Working…'
              : running
                  ? 'Stop server'
                  : 'Start server',
          width: 160,
          onPressed: controllable
              ? () => _boardAction(
                  running ? BoardServerManager.stop : BoardServerManager.start)
              : null,
        ),
        const SizedBox(width: 12),
        QuietButton(
          text: 'Restart server',
          width: 160,
          onPressed: (controllable && running)
              ? () => _boardAction(BoardServerManager.restart)
              : null,
        ),
      ]),
      const SizedBox(height: 8),
      const Text(
          'A stopped server disconnects the apps until it is started again.',
          style: TextStyle(color: T.muted, fontSize: 12)),
      const SizedBox(height: 14),
      const Divider(color: T.cardStroke, height: 1),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: QuietButton(
            text: 'Change FaceSnap server password…',
            onPressed: _boardBusy ? null : _changeBoardPassword,
          ),
        ),
      ]),
      const SizedBox(height: 6),
      const Text(
          'Sets a new login password on the kiosk itself and remembers it here.',
          style: TextStyle(color: T.muted, fontSize: 12)),
    ]);
  }

}

/// Change the board's SSH login password: current + new + repeat. On success
/// it sets the password on the kiosk over SSH AND stores the new one in the
/// app's config, so the connection keeps working. Pops true when changed.
class ChangeBoardPasswordDialog extends StatefulWidget {
  const ChangeBoardPasswordDialog(
      {super.key, required this.host, required this.user});

  final String host;
  final String user;

  @override
  State<ChangeBoardPasswordDialog> createState() =>
      _ChangeBoardPasswordDialogState();
}

class _ChangeBoardPasswordDialogState extends State<ChangeBoardPasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validationError = BoardServerManager.validatePasswordChange(
        _current.text, _next.text, _repeat.text);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BoardServerManager.changePassword(
          widget.host, widget.user, _current.text, _next.text);
      // Persist the new credential so every later SSH probe/action uses it.
      AppConfig.boardPassword = _next.text;
      await AppConfig.save();
      if (mounted) Navigator.pop(context, true);
    } on BoardPasswordException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Password change failed: ${operatorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change password on ${widget.host}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Sets the login password for user "${widget.user}" on the '
                'kiosk. The apps will use the new password from now on.',
                style: const TextStyle(color: T.muted, fontSize: 12.5)),
            const SizedBox(height: 14),
            _field('Current password', _current),
            const SizedBox(height: 10),
            _field('New password', _next),
            const SizedBox(height: 10),
            _field('Repeat new password', _repeat, onSubmit: _submit),
            const SizedBox(height: 8),
            Row(children: [
              Checkbox(
                value: !_obscure,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _obscure = !(v ?? false)),
              ),
              const Text('Show passwords',
                  style: TextStyle(color: T.muted, fontSize: 12.5)),
            ]),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_error!,
                    style: const TextStyle(color: T.fail, fontSize: 12.5)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Changing…' : 'Change password')),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller,
      {VoidCallback? onSubmit}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RowLabel(label),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        enabled: !_busy,
        obscureText: _obscure,
        autofillHints: const [],
        onSubmitted: onSubmit == null ? null : (_) => onSubmit(),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: T.line)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: T.titleBlue)),
        ),
      ),
    ]);
  }
}
