// Operator Kiosk page — connecting to and controlling servers: the live list
// of every server on the network (click to connect; manual address behind
// "Add an address…") plus the server-process cards (this PC / remote kiosk
// PC). The capture flow lives on its own Capture page.
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/app_config.dart';
import 'connection_cards.dart';
import '../services/settings_state.dart';
import '../ui/dev_info.dart';
import '../ui/server_list.dart';
import '../ui/server_picker.dart';
import '../ui/ui.dart';

class KioskPage extends StatefulWidget {
  const KioskPage({super.key});

  @override
  State<KioskPage> createState() => _KioskPageState();
}

class _KioskPageState extends State<KioskPage> {
  /// This app's own version (from pubspec via the exe's version resource).
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    // Repaint when the snapshot lands after a server start (the page sits
    // const in the IndexedStack and never rebuilds otherwise).
    SettingsState.revision.addListener(_onSettingsChanged);
    _loadAppVersion();
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {
      // No plugin in widget tests — the header simply omits the version.
    }
  }

  /// After the connection changed (a list row, or a manual address): rebuild
  /// so the server-process cards re-key on the new host. The server's version
  /// is the list's business now — every row shows its own.
  Future<void> _afterServerChange() async {
    if (mounted) setState(() {});
  }

  /// Manual entry for a kiosk the network does not show.
  Future<void> _changeServer() async {
    final changed = await showServerPicker(context);
    if (!mounted || !changed) return;
    await _afterServerChange();
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
                  title: 'Servers on the network',
                  titleLeading: const DevInfoBadge('discovery'),
                  shrinkWrap: true,
                  child: ServerList(
                      onConnected: _afterServerChange,
                      onAddAddress: _changeServer),
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

}
