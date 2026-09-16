// Operator-app UI: the shared design system (ui_shared.dart, sync copy with
// the updater app) plus the widgets only this app uses.
import 'package:flutter/material.dart';

import 'ui_shared.dart';

export 'ui_shared.dart';

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
