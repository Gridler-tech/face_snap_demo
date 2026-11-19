// The Updater page's "Server port" card (spec 2026-10-15 §6): the port the
// connected machine's server uses (a board's port file, a Windows PC's
// server_config.json, read by the probe), a New port field and Change port.
// The page confirms and runs the change (PortEngine); the card shows the
// notice the page hands back after a successful change.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/ui.dart';
import '../updater/connection_probe.dart';
import '../updater/port_engine.dart' show kMaxServerPort, kMinServerPort;
import '../updater/server_port.dart' show kDefaultPort;

/// "Current port: 50051 (default)" / "Current port: N"; "unknown" when the
/// probe could not read it.
String currentPortText(int? port) => switch (port) {
  null => 'Current port: unknown',
  kDefaultPort => 'Current port: $kDefaultPort (default)',
  _ => 'Current port: $port',
};

class ServerPortCard extends StatefulWidget {
  const ServerPortCard({
    super.key,
    required this.probe,
    required this.enabled,
    required this.onChangePort,
    this.notice = const [],
  });

  /// The live probe of the kiosk above.
  final ProbeResult probe;

  /// False while anything else on the page runs (a port change included).
  final bool enabled;

  /// Change port was pressed with a valid new port.
  final void Function(int newPort) onChangePort;

  /// Lines to show after a successful change (the new address, …).
  final List<String> notice;

  @override
  State<ServerPortCard> createState() => _ServerPortCardState();
}

class _ServerPortCardState extends State<ServerPortCard> {
  final _newPort = TextEditingController();

  @override
  void dispose() {
    _newPort.dispose();
    super.dispose();
  }

  /// The typed port when it is one the servers accept and not the current one.
  int? get _validPort {
    final port = int.tryParse(_newPort.text.trim());
    if (port == null || port < kMinServerPort || port > kMaxServerPort) return null;
    if (port == widget.probe.currentPort) return null;
    return port;
  }

  @override
  Widget build(BuildContext context) {
    // The notice stays while the machine is probed again after the change,
    // and when that probe fails: the new address is still worth copying.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_controls(), if (widget.notice.isNotEmpty) _notice()],
    );
  }

  Widget _controls() {
    final probe = widget.probe;
    if (!probe.portChangeable) {
      return const Text(
        'Connect to a kiosk first.',
        style: TextStyle(color: T.muted, fontSize: 12.5),
      );
    }
    final port = _validPort;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentPortText(probe.currentPort),
          style: const TextStyle(color: T.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        const RowLabel('New port'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('port-new'),
                controller: _newPort,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  hintText: '$kMinServerPort–$kMaxServerPort',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: T.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: T.titleBlue),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            QuietButton(
              text: 'Change port',
              onPressed: widget.enabled && port != null ? () => widget.onChangePort(port) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _notice() => Container(
    key: const ValueKey('port-notice'),
    width: double.infinity,
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: T.passTint, borderRadius: BorderRadius.circular(8)),
    // Selectable: the new address is there to be copied.
    child: SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in widget.notice)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(line, style: const TextStyle(color: T.ink, fontSize: 12.5)),
            ),
        ],
      ),
    ),
  );
}
