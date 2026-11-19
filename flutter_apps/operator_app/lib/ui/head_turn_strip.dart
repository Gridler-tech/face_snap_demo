// The head turn on the operator's Capture page (spec 2026-10-08 section 5.2): a
// compact strip with the arrow, the server's text, the progress towards the
// turn and the seconds left of the current ask - what the person in front of
// the kiosk is asked to do right now.
import 'dart:async';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import 'ui_shared.dart';

/// The status lines the head turn also sends its instructions as (for clients
/// that only show status texts). The Capture page shows them in the strip,
/// not as result rows. Keep in step with the servers' texts: HeadTurn.TextOf
/// (Server 2.0, HeadTurn.cs) and head_turn.TEXTS (Python, head_turn.py).
bool isHeadTurnInstruction(String text) => const {
      'Turn your head to the left',
      'Once more: turn your head to the left',
      'Turn your head to the right',
      'Once more: turn your head to the right',
      'Look straight ahead',
    }.contains(text);

class HeadTurnStrip extends StatefulWidget {
  const HeadTurnStrip({super.key, required this.instruction});

  final CaptureInstruction instruction;

  @override
  State<HeadTurnStrip> createState() => _HeadTurnStripState();
}

class _HeadTurnStripState extends State<HeadTurnStrip> {
  static const _tick = Duration(milliseconds: 100);

  Timer? _countdown;
  double _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(HeadTurnStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.instruction, widget.instruction)) _startCountdown();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  /// seconds_left is the time left when the server SENT the instruction, and
  /// the server sends a new one only on a change (a new ask, or the progress
  /// moved 5 points): a person who does not move gets none. So count down
  /// locally from the moment this instruction arrived; the next one restarts
  /// the count from its own value.
  void _startCountdown() {
    _countdown?.cancel();
    _countdown = null;
    final from = widget.instruction.secondsLeft;
    _secondsLeft = from < 0 ? 0 : from;
    if (_secondsLeft == 0 || widget.instruction.kind == InstructionKind.DONE) return;
    _countdown = Timer.periodic(_tick, (timer) {
      // tick counts the periods passed, also the ones a busy UI thread missed.
      final left = from - timer.tick * _tick.inMilliseconds / 1000;
      if (left <= 0) timer.cancel();
      setState(() => _secondsLeft = left < 0 ? 0 : left);
    });
  }

  @override
  Widget build(BuildContext context) {
    final instruction = widget.instruction;
    final turning = instruction.kind == InstructionKind.TURN_LEFT ||
        instruction.kind == InstructionKind.TURN_RIGHT;
    // The person's own left: the arrow as the kiosk screen in front of them shows it.
    final IconData icon = switch (instruction.kind) {
      InstructionKind.TURN_LEFT => Icons.arrow_back_rounded,
      InstructionKind.TURN_RIGHT => Icons.arrow_forward_rounded,
      _ => Icons.center_focus_strong_rounded,
    };
    return Row(children: [
      Icon(icon, size: 34, color: T.titleBlue),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(instruction.text,
              style: const TextStyle(
                  color: T.ink, fontSize: 15, fontWeight: FontWeight.w600)),
          if (turning) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: instruction.progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              color: T.pass,
              backgroundColor: T.line,
            ),
          ],
        ]),
      ),
      const SizedBox(width: 12),
      Text('${_secondsLeft.toStringAsFixed(1)} s',
          style: const TextStyle(color: T.muted, fontSize: 13)),
    ]);
  }
}
