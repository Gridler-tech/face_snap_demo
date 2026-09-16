// Connection cards: server process controls for this PC (start/stop +
// autostart, only where the server runs locally) and for a remote kiosk board
// (over SSH). Formerly their own Connection page; now embedded on the Kiosk
// page. Manual address entry lives in the server picker dialog.
import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/board_server_manager.dart';
import '../services/server_manager.dart';
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
    final running = await ServerManager.isRunning(AppConfig.port);
    final autostart = await ServerManager.isAutostartEnabled();
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
      await _refreshServerState();
    } catch (e) {
      if (mounted) setState(() => _message = 'Server control failed: $e');
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

  Future<void> _boardAction(Future<void> Function(String host) action) async {
    final host = AppConfig.host;
    setState(() => _boardBusy = true);
    try {
      await action(host);
      if (!mounted) return;
      setState(() => _message = null);
    } catch (e) {
      if (mounted) setState(() => _message = 'Board server control failed: $e');
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
    return Column(children: [
      for (var i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        cards[i],
      ],
      if (_message != null) ...[
        const SizedBox(height: 12),
        Text(_message!, style: const TextStyle(color: T.fail, fontSize: 13)),
      ],
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
                  setState(() => _message = 'Autostart change failed: $e');
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
    ]);
  }

}
