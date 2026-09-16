// Server picker — the "connect to a kiosk" flow that replaces the old startup
// ConnectPage. Two ways in: SEARCH the local network (mDNS discovery of the
// _facesnap._tcp service every provisioned kiosk announces) and pick from the
// list, or type an IP/port MANUALLY. On confirm it points the shared gRPC
// channel at the chosen address, persists it, and reloads the settings
// snapshot. Returns true when the server changed + settings loaded.
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/discovery.dart';
import '../services/settings_state.dart';
import 'ui.dart';

/// Opens the picker; returns true when a new server was connected.
Future<bool> showServerPicker(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => const _ServerPickerDialog(),
  );
  return result ?? false;
}

class _ServerPickerDialog extends StatefulWidget {
  const _ServerPickerDialog();

  @override
  State<_ServerPickerDialog> createState() => _ServerPickerDialogState();
}

class _ServerPickerDialogState extends State<_ServerPickerDialog> {
  final _host = TextEditingController(text: AppConfig.host);
  final _port = TextEditingController(text: '${AppConfig.port}');

  List<DiscoveredKiosk> _found = const [];
  bool _searching = false;
  bool _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search(); // scan immediately so the operator usually just clicks a kiosk
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      // mDNS only finds provisioned boards (they announce _facesnap._tcp);
      // a server on this machine announces nothing, so probe the local gRPC
      // port directly and list it first when it answers.
      final results =
          await Future.wait([discoverKiosks(), _findLocalServer()]);
      final kiosks = results[0] as List<DiscoveredKiosk>;
      final local = results[1] as DiscoveredKiosk?;
      if (!mounted) return;
      setState(() => _found = [?local, ...kiosks]);
    } catch (e) {
      if (mounted) setState(() => _error = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// A FaceSnap server on this machine, if one is listening on the gRPC port.
  Future<DiscoveredKiosk?> _findLocalServer() async {
    try {
      final socket = await Socket.connect(
          InternetAddress.loopbackIPv4, AppConfig.port,
          timeout: const Duration(seconds: 1));
      socket.destroy();
      return DiscoveredKiosk(
          hostName: 'This PC', ip: '127.0.0.1', port: AppConfig.port);
    } catch (_) {
      return null; // nothing listening locally
    }
  }

  Future<void> _connect(String host, int port) async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await GrpcChannelProvider.setAddress(host, port);
      await SettingsState.refresh(); // proves the server answers before saving
      AppConfig.host = host;
      AppConfig.port = port;
      await AppConfig.save();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Could not connect to $host:$port. Is the server running?\n$e');
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _connectManual() {
    final host = _host.text.trim();
    final port = int.tryParse(_port.text.trim());
    if (host.isEmpty || port == null || port < 1 || port > 65535) {
      setState(() => _error = 'Enter a valid IP address and port.');
      return;
    }
    _connect(host, port);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Expanded(
                  child: Text('Connect to a FaceSnap kiosk',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: T.titleBlue,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    onPressed: _connecting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),

              // ---- discovered kiosks ----
              Row(children: [
                const Text('Found on your network',
                    style: TextStyle(
                        color: T.ink, fontWeight: FontWeight.w600)),
                const Spacer(),
                QuietButton(
                  text: _searching ? 'Searching…' : 'Search again',
                  width: 140,
                  onPressed: _searching ? null : _search,
                ),
              ]),
              const SizedBox(height: 8),
              // Fixed-height list area: a Flexible/Expanded child cannot live in
              // a Column with mainAxisSize.min (contradictory constraints — it
              // throws at layout), so the discovered-kiosks list gets a bounded
              // box it scrolls within.
              SizedBox(
                height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: T.cardStroke),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildFoundList(),
                ),
              ),
              const SizedBox(height: 18),

              // ---- manual entry ----
              const Text('Or enter an address',
                  style:
                      TextStyle(color: T.ink, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _host,
                    decoration: const InputDecoration(
                        labelText: 'Server IP / host',
                        isDense: true,
                        border: OutlineInputBorder()),
                    onSubmitted: (_) => _connectManual(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: _port,
                    decoration: const InputDecoration(
                        labelText: 'Port',
                        isDense: true,
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _connectManual(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 130,
                  child: GoButton(
                    text: _connecting ? 'Connecting…' : 'Connect',
                    onPressed: _connecting ? null : _connectManual,
                  ),
                ),
              ]),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: T.fail, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoundList() {
    if (_searching && _found.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(
              width: 26, height: 26, child: CircularProgressIndicator()),
        ),
      );
    }
    if (_found.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No kiosks found. Try again or enter an address below.',
              style: TextStyle(color: T.muted, fontSize: 13)),
        ),
      );
    }
    return ListView.separated(
      itemCount: _found.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: T.cardStroke),
      itemBuilder: (_, i) {
        final k = _found[i];
        // Drop the trailing ".local" for a cleaner label.
        final name = k.hostName.endsWith('.local')
            ? k.hostName.substring(0, k.hostName.length - 6)
            : k.hostName;
        final isLocal = k.ip.startsWith('127.');
        // Connect on the port the kiosk ANNOUNCED (its SRV record); only a
        // find without one (e.g. the local-server probe fallback) uses this
        // PC's configured port.
        final port = k.port ?? AppConfig.port;
        return ListTile(
          leading: Icon(isLocal ? Icons.computer : Icons.sensors,
              color: T.titleBlue),
          title: Text(name,
              style: const TextStyle(
                  color: T.ink, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('${k.ip}:$port',
              style: const TextStyle(color: T.muted, fontSize: 12)),
          trailing: _connecting
              ? null
              : const Icon(Icons.chevron_right, color: T.muted),
          onTap: _connecting ? null : () => _connect(k.ip, port),
        );
      },
    );
  }
}
