// Operator-app UI: the shared design system (ui_shared.dart, sync copy with
// the updater app) plus the widgets only this app uses.
import 'package:flutter/material.dart';

import '../services/rpc_error.dart';
import 'ui_shared.dart';

export '../services/rpc_error.dart';
export 'ui_shared.dart';

/// The settings pages' shared server-call state: run an RPC, clear the error
/// line on success, show an operator-readable failure otherwise. Pages render
/// [message] through [ErrorLine].
mixin ServerCallState<T extends StatefulWidget> on State<T> {
  String? message;

  Future<void> runServerCall(Future<dynamic> Function() action) async {
    try {
      await action();
      if (mounted) setState(() => message = null);
    } catch (e) {
      if (mounted) {
        setState(() => message = 'Server call failed: ${operatorMessage(e)}');
      }
    }
  }
}

/// The error footer every page renders under its cards: nothing while
/// [message] is null, otherwise the standard red line with its top gap.
class ErrorLine extends StatelessWidget {
  const ErrorLine(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(message, style: const TextStyle(color: T.fail, fontSize: 13)),
    );
  }
}

/// Parse a 6-digit hex colour ("00FF00"); [fallback] on anything else.
Color hexToColor(String hex, {required Color fallback}) {
  if (hex.length != 6) return fallback;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? fallback : Color(0xFF000000 | value);
}

/// The 6-digit uppercase hex of a colour (no leading #).
String colorToHex(Color c) =>
    (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

/// Small square numbered button (per-camera actions).
class NumButton extends StatelessWidget {
  const NumButton({super.key, required this.number, this.onPressed});

  final int number;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: T.ink,
          side: const BorderSide(color: T.line),
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text('$number',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Placeholder shown on pages that need live settings when no server is
/// connected yet — the app now boots without a connect screen, so any page can
/// be visited before a kiosk is chosen on the Kiosk page.
class NotConnectedNotice extends StatelessWidget {
  const NotConnectedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_outlined, size: 40, color: T.muted),
            SizedBox(height: 12),
            Text(
              'No server connected.\nChoose a kiosk on the Kiosk page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: T.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
