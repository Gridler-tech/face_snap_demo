// Operator Kiosk page — connecting to and controlling servers: the
// search-or-manual server picker plus the server-process cards (this PC /
// remote kiosk PC). The capture flow lives on its own Capture page.
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/app_config.dart';
import '../services/board_server_manager.dart';
import '../services/server_manager.dart';
import 'connection_cards.dart';
import '../services/settings_state.dart';
import '../ui/dev_info.dart';
import '../ui/server_picker.dart';
import '../ui/ui.dart';

class KioskPage extends StatefulWidget {
  const KioskPage({super.key});

  @override
  State<KioskPage> createState() => _KioskPageState();
}

class _KioskPageState extends State<KioskPage> {
  /// Derived, not stored: a settings snapshot means the server answered.
  bool get _connected => SettingsState.current != null;

  /// This app's own version (from pubspec via the exe's version resource).
  String _appVersion = '';

  /// The connected server's version, and the host it belongs to (so a server
  /// change re-probes and a stale probe result is dropped).
  String? _serverVersion;
  String? _versionHost;

  @override
  void initState() {
    super.initState();
    // Repaint the status dot when the snapshot lands after a server start
    // (the page sits const in the IndexedStack and never rebuilds otherwise).
    SettingsState.revision.addListener(_onSettingsChanged);
    _loadAppVersion();
    _refreshServerVersion();
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
    _refreshServerVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {
      // No plugin in widget tests — the header simply omits the version.
    }
  }

  /// Fetch the connected server's version: a kiosk board reports it via the
  /// compose image tag over SSH, a server on this PC via its installer's
  /// registry entry. Probed once per host; unknown stays blank.
  Future<void> _refreshServerVersion() async {
    final host = AppConfig.host;
    if (!_connected || host == _versionHost) return;
    _versionHost = host;
    String? version;
    if (BoardServerManager.isRemoteHost(host)) {
      version = await BoardServerManager.serverVersion(host);
    } else if (ServerManager.applicable) {
      version = await ServerManager.installedVersion();
    }
    if (!mounted || AppConfig.host != host) return;
    setState(() => _serverVersion = version);
  }

  /// Open the search-or-manual server picker; on a new connection reload the
  /// state so the cards reflect the new kiosk.
  Future<void> _changeServer() async {
    final changed = await showServerPicker(context);
    if (!mounted || !changed) return;
    setState(() {
      // Forget the previous server's version so the new one is probed.
      _versionHost = null;
      _serverVersion = null;
    });
    await _refreshServerVersion();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(children: [
            const Align(
              alignment: Alignment.centerRight,
              child: DevModeToggle(),
            ),
            _buildHeader(),
            const SizedBox(height: 24),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: SectionCard(
                  title: 'Automatically find servers',
                  titleLeading: const DevInfoBadge('discovery'),
                  shrinkWrap: true,
                  child: _buildServerRow(),
                ),
              ),
              const SizedBox(width: 14),
              // Server-process cards (this PC + remote kiosk PC over SSH).
              // The host key recreates their state after a server change, so
              // the board status is re-probed for the new address.
              Expanded(child: ConnectionCards(key: ValueKey(AppConfig.host))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
      child: Row(children: [
        Image.asset('assets/logo_gridler.png', height: 150),
        const SizedBox(width: 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FaceSnap',
                  style: TextStyle(
                      color: T.titleBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              if (_appVersion.isNotEmpty)
                Text('Operator app $_appVersion',
                    style: const TextStyle(color: T.muted, fontSize: 12)),
              const SizedBox(height: 8),
              const Text(
                'Welcome to FaceSnap, the Gridler photo kiosk for official '
                'document photos. Connect to a kiosk below and take photos '
                'on the Capture page — every shot is checked against the '
                'ICAO quality rules as it is taken. Lighting, camera and '
                'check settings live in the pages on the left.',
                style: TextStyle(color: T.ink, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildServerRow() {
    final dot = _connected ? T.pass : T.pending;
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          _connected
              ? '${AppConfig.host}:${AppConfig.port}'
                  '${_serverVersion == null ? '' : '  ·  server $_serverVersion'}'
              : 'No server — search or add one',
          style: TextStyle(
              color: _connected ? T.ink : T.muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 12),
      QuietButton(
        text: 'Search / change…',
        width: 170,
        onPressed: _changeServer,
      ),
    ]);
  }
}
