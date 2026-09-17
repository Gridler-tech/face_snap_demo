// Operator Kiosk page — connecting to and controlling servers: the
// search-or-manual server picker plus the server-process cards (this PC /
// remote kiosk PC). The capture flow lives on its own Capture page.
import 'package:flutter/material.dart';

import '../services/app_config.dart';
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

  @override
  void initState() {
    super.initState();
    // Repaint the status dot when the snapshot lands after a server start
    // (the page sits const in the IndexedStack and never rebuilds otherwise).
    SettingsState.revision.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  /// Open the search-or-manual server picker; on a new connection reload the
  /// state so the cards reflect the new kiosk.
  Future<void> _changeServer() async {
    final changed = await showServerPicker(context);
    if (!mounted || !changed) return;
    setState(() {});
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FaceSnap',
                  style: TextStyle(
                      color: T.titleBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text(
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
