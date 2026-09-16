// Shared design tokens + base widgets — the card design system from the MAUI
// operator app (Styles.xaml): grey workspace, white cards with hairline
// strokes, blue caps titles, green primary buttons, quiet outlined
// secondaries.
//
// Shared verbatim between the operator app (lib/ui/ui_shared.dart) and the
// updater app (lib/ui/ui_shared.dart) - keep the two copies in sync; app-
// specific widgets live in each app's own ui.dart, which re-exports this file.
import 'package:flutter/material.dart';

/// Design tokens.
class T {
  T._();

  static const ground = Color(0xFFF3F5F8);
  static const card = Colors.white;
  static const cardStroke = Color(0xFFE2E8EF);
  static const titleBlue = Color(0xFF0C5AA6);
  static const ink = Color(0xFF1E2A36);
  static const muted = Color(0xFF7D8B98);
  static const line = Color(0xFFCFD8E0);

  static const goGreen = Color(0xFF64A32F);
  static const pass = Color(0xFF3E9142);
  static const fail = Color(0xFFC6413D);
  static const warn = Color(0xFFC77D2A);
  static const pending = Color(0xFFB9C2CA);
  static const passTint = Color(0xFFE4EFE0);
  static const failTint = Color(0xFFF7E3E1);
  static const warnTint = Color(0xFFF8EBDC);
}

/// White card with the shared stroke/radius/shadow and a caps title + hairline.
class SectionCard extends StatelessWidget {
  const SectionCard(
      {super.key,
      required this.title,
      required this.child,
      this.shrinkWrap = false,
      this.titleLeading});

  final String title;
  final Widget child;

  /// true = card hugs its content (for centred/bounded layouts); false = the
  /// default column behaviour (fills scroll/flex parents).
  final bool shrinkWrap;

  /// Optional widget in front of the title (e.g. a badge).
  final Widget? titleLeading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.cardStroke),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            if (titleLeading != null) ...[
              titleLeading!,
              const SizedBox(width: 8),
            ],
            Text(title.toUpperCase(),
                style: const TextStyle(
                    color: T.titleBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4)),
            const SizedBox(width: 10),
            const Expanded(child: Divider(color: T.cardStroke, height: 1)),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Green primary action button.
class GoButton extends StatelessWidget {
  const GoButton({super.key, required this.text, this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: T.goGreen,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

/// White outlined secondary button.
class QuietButton extends StatelessWidget {
  const QuietButton({super.key, required this.text, this.onPressed, this.width});

  final String text;
  final VoidCallback? onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: T.ink,
        side: const BorderSide(color: T.line),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
    return width == null ? button : SizedBox(width: width, child: button);
  }
}

/// Row label (form rows).
class RowLabel extends StatelessWidget {
  const RowLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: T.ink, fontSize: 14));
}
