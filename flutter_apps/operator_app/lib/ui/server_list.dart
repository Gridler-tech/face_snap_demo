// The Kiosk page's server list: every FaceSnap server on the network, found
// automatically at start-up and kept fresh, one row each with what it is and
// whether it answers — click a row to connect. Replaces the one-line "search
// or change…" card, so the operator sees the fleet without opening anything.
//
// Two tiers per row, because they cost differently (server_probe.dart): the
// row appears at once from discovery, then fills in from a credential-free
// gRPC ping and, once, an SSH read of version/state. Discovery, probe and
// connect are injectable so the widget is tested with fakes; the real ones are
// the defaults.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/discovery.dart';
import '../services/server_connector.dart';
import '../services/server_probe.dart';
import 'ui.dart';

typedef DiscoverFn = Future<List<DiscoveredKiosk>> Function();
typedef ProbeFn = Future<ServerSnapshot> Function(String host, int port,
    {bool sshDetails});
typedef ConnectFn = Future<void> Function(String host, int port);

class ServerList extends StatefulWidget {
  const ServerList({
    super.key,
    required this.onConnected,
    required this.onAddAddress,
    this.discover,
    this.probe,
    this.connect,
    this.refreshEvery = const Duration(seconds: 30),
  });

  /// Called after a row connected, so the page refreshes for the new server.
  final Future<void> Function() onConnected;

  /// Opens the manual-address dialog (a kiosk mDNS cannot see).
  final Future<void> Function() onAddAddress;

  /// Test seams; null = the real network functions.
  final DiscoverFn? discover;
  final ProbeFn? probe;
  final ConnectFn? connect;

  /// Re-scan interval; null disables the timer (tests).
  final Duration? refreshEvery;

  @override
  State<ServerList> createState() => _ServerListState();
}

class _Row {
  _Row(this.kiosk, {this.saved = false});

  final DiscoveredKiosk kiosk;

  /// The remembered server, listed because discovery did not report it.
  final bool saved;
  ServerSnapshot? snapshot;
}

class _ServerListState extends State<ServerList> {
  List<_Row> _rows = const [];
  bool _scanning = false;
  String? _connecting; // host of the row being connected
  String? _error;
  Timer? _timer;

  /// Bumped per scan; a late probe result for a superseded scan is dropped.
  int _gen = 0;

  DiscoverFn get _discover => widget.discover ?? _discoverAll;
  ProbeFn get _probe => widget.probe ?? probeServer;
  ConnectFn get _connect => widget.connect ?? connectTo;

  /// Everything that can be connected to: the boards on the network (kiosks
  /// and clean ones) plus a server on this PC, which announces nothing over
  /// mDNS and is probed directly — listed first when it answers. Behind the
  /// `discover` seam as one unit, so tests never touch a real socket.
  static Future<List<DiscoveredKiosk>> _discoverAll() async {
    final results = await Future.wait([discoverBoards(), findLocalServer()]);
    final local = results[1] as DiscoveredKiosk?;
    return [?local, ...results[0] as List<DiscoveredKiosk>];
  }

  @override
  void initState() {
    super.initState();
    // Under `flutter test` the real scan (multicast sockets, 4 s window) is
    // not started unless a fake was injected — the shell test builds this
    // page too.
    final underTest = Platform.environment['FLUTTER_TEST'] == 'true';
    if (widget.discover != null || !underTest) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
      final every = widget.refreshEvery;
      if (every != null) _timer = Timer.periodic(every, (_) => _scan());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---- identity ------------------------------------------------------------

  /// How to reach a row: a provisioned kiosk by its .local NAME (survives the
  /// DHCP moves that keep changing these addresses), a clean board or this PC
  /// by IP.
  static String _hostFor(DiscoveredKiosk k) =>
      k.kind == BoardKind.clean || k.ip.startsWith('127.') ? k.ip : k.hostName;

  static int _portFor(DiscoveredKiosk k) => k.port ?? AppConfig.port;

  /// The row the app is connected to: the saved host may be the name OR the
  /// address (older configs saved the IP).
  static bool _isCurrent(_Row r) {
    final saved = AppConfig.host;
    return (saved == _hostFor(r.kiosk) ||
            saved == r.kiosk.ip ||
            saved == r.kiosk.hostName) &&
        AppConfig.port == _portFor(r.kiosk);
  }

  /// Snapshot carry-over key across re-scans: name AND address, so two clones
  /// still announcing the same name never share a snapshot.
  static String _key(_Row r) => '${r.kiosk.hostName}@${r.kiosk.ip}';

  // ---- scanning ------------------------------------------------------------

  /// One scan: discover, list, probe every row. The periodic timer never
  /// overlaps a running scan; the operator's "Search again" ([restart]) does —
  /// it supersedes the running one (a stale probe can sit on "Checking…" for
  /// seconds when a kiosk was renamed or unplugged, and the operator must
  /// not have to wait that out). Bumping [_gen] orphans the old scan: its
  /// late results and its own clean-up are dropped by the generation checks.
  Future<void> _scan({bool restart = false}) async {
    if (!mounted || (_scanning && !restart)) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    final gen = ++_gen;
    try {
      final rows = [
        for (final k in dedupeDiscovered(await _discover())) _Row(k),
      ];

      // The remembered server must never vanish from the list just because
      // one mDNS scan missed it — it still gets a row, and a probe.
      final saved = AppConfig.host.trim();
      final isLocalSaved = saved.isEmpty || saved == 'localhost' || saved.startsWith('127.');
      if (!isLocalSaved &&
          !rows.any((r) =>
              r.kiosk.ip == saved || r.kiosk.hostName == saved || _hostFor(r.kiosk) == saved)) {
        rows.add(_Row(
            DiscoveredKiosk(hostName: saved, ip: saved, port: AppConfig.port),
            saved: true));
      }
      if (!mounted || gen != _gen) return;

      // Carry each row's last snapshot across the re-scan so the list does
      // not flicker back to "Checking…" every 30 s.
      final previous = {for (final r in _rows) _key(r): r.snapshot};
      for (final r in rows) {
        r.snapshot = previous[_key(r)];
      }
      setState(() => _rows = rows);
      await Future.wait([for (final r in rows) _probeRow(r, gen)]);
    } catch (e) {
      if (mounted && gen == _gen) {
        setState(() => _error = 'Search failed: ${operatorMessage(e)}');
      }
    } finally {
      if (mounted && gen == _gen) setState(() => _scanning = false);
    }
  }

  Future<void> _probeRow(_Row r, int gen) async {
    if (r.kiosk.kind == BoardKind.clean) return; // nothing to talk to
    final old = r.snapshot;
    // The SSH tier costs a session per board: run it until the version is
    // known, then rely on the gRPC ping for liveness and keep what we learned.
    final snap = await _probe(_hostFor(r.kiosk), _portFor(r.kiosk),
        sshDetails: old?.version == null);
    if (!mounted || gen != _gen) return;
    setState(() => r.snapshot = ServerSnapshot(
          answering: snap.answering,
          cameras: snap.cameras ?? old?.cameras,
          version: snap.version ?? old?.version,
          running: snap.running ?? old?.running,
          model: snap.model ?? old?.model,
          error: snap.error,
        ));
  }

  // ---- connecting ----------------------------------------------------------

  Future<void> _connectRow(_Row r) async {
    final host = _hostFor(r.kiosk), port = _portFor(r.kiosk);
    setState(() {
      _connecting = host;
      _error = null;
    });
    try {
      await _connect(host, port);
      if (!mounted) return;
      await widget.onConnected();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = 'Could not connect to $host:$port — ${operatorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _connecting = null);
    }
  }

  // ---- view ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: Text(
            _scanning
                ? 'Searching the network…'
                : _rows.isEmpty
                    ? 'No servers found yet'
                    : '${_rows.length} server${_rows.length == 1 ? '' : 's'} found',
            style: const TextStyle(color: T.muted, fontSize: 12.5),
          ),
        ),
        // Always available: pressing it during a scan starts a fresh one.
        QuietButton(
            text: 'Search again',
            width: 150,
            onPressed:
                _connecting != null ? null : () => _scan(restart: true)),
        const SizedBox(width: 8),
        QuietButton(
            text: 'Add an address…',
            width: 180,
            onPressed: _connecting != null ? null : widget.onAddAddress),
      ]),
      const SizedBox(height: 8),
      if (_rows.isEmpty && !_scanning)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text(
              'Kiosks announce themselves once installed. Search again, or add '
              'an address for one the network does not show.',
              style: TextStyle(color: T.muted, fontSize: 13)),
        ),
      for (final r in _rows) _row(r),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_error!,
              style: const TextStyle(color: T.fail, fontSize: 12.5)),
        ),
    ]);
  }

  Widget _row(_Row r) {
    final status = rowStatus(
        kind: r.kiosk.kind, isCurrent: _isCurrent(r), snapshot: r.snapshot);
    final host = _hostFor(r.kiosk);
    final busy = _connecting == host;
    final clickable = status == ServerRowStatus.answering && _connecting == null;
    final (color, tint) = switch (status) {
      ServerRowStatus.connected => (T.pass, T.passTint),
      ServerRowStatus.answering => (T.titleBlue, const Color(0xFFE4EEF8)),
      ServerRowStatus.notAnswering => (T.fail, T.failTint),
      ServerRowStatus.noServer => (T.warn, T.warnTint),
      ServerRowStatus.probing => (T.muted, T.ground),
    };
    final isLocal = r.kiosk.ip.startsWith('127.');
    final detail = rowDetail(status, r.snapshot);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: status == ServerRowStatus.connected ? T.passTint : T.card,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: clickable ? () => _connectRow(r) : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            decoration: BoxDecoration(
                border: Border.all(
                    color: status == ServerRowStatus.connected
                        ? T.pass
                        : T.cardStroke),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(
                  isLocal
                      ? Icons.computer
                      : r.kiosk.kind == BoardKind.clean
                          ? Icons.memory
                          : Icons.sensors,
                  size: 20,
                  color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${announcedName(r.kiosk.hostName)}'
                          '${r.saved ? '  (saved)' : ''}',
                          style: const TextStyle(
                              color: T.ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(
                          '${r.kiosk.ip}:${_portFor(r.kiosk)}'
                          '${detail.isEmpty ? '' : '  ·  $detail'}',
                          style: TextStyle(
                              color: status == ServerRowStatus.notAnswering
                                  ? T.fail
                                  : T.muted,
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ]),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.2))
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: tint, borderRadius: BorderRadius.circular(20)),
                  child: Text(rowStatusLabel(status),
                      style: TextStyle(
                          color: color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600)),
                ),
              if (clickable) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: T.muted),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
