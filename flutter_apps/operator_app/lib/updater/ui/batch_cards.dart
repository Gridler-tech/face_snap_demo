// One row per kiosk while a batch runs: status, where it has got to, how long
// it took — expandable to that board's full step list. Collapsed by default,
// because the point of the batch view is seeing the whole fleet at a glance.
import 'package:flutter/material.dart';

import '../batch_runner.dart';
import '../engine.dart';
import '../../ui/ui.dart';

/// Colour and icon for a board's lifecycle phase.
({Color color, IconData icon}) batchPhaseLook(BatchPhase phase) =>
    switch (phase) {
      BatchPhase.waiting => (color: T.pending, icon: Icons.schedule),
      BatchPhase.running => (color: T.titleBlue, icon: Icons.sync),
      BatchPhase.succeeded => (color: T.pass, icon: Icons.check_circle),
      BatchPhase.failed => (color: T.fail, icon: Icons.cancel),
      BatchPhase.skipped => (color: T.muted, icon: Icons.remove_circle_outline),
    };

String batchPhaseLabel(BatchPhase phase) => switch (phase) {
      BatchPhase.waiting => 'Waiting',
      BatchPhase.running => 'Running',
      BatchPhase.succeeded => 'Done',
      BatchPhase.failed => 'Failed',
      BatchPhase.skipped => 'Skipped',
    };

class BatchBoardCard extends StatelessWidget {
  const BatchBoardCard({
    super.key,
    required this.title,
    required this.phase,
    required this.detail,
    this.elapsed,
    this.steps = const [],
    this.expanded = false,
    this.onToggle,
  });

  final String title;
  final BatchPhase phase;

  /// Current step while running, or the outcome line when finished.
  final String detail;
  final Duration? elapsed;

  /// That board's own pipeline, shown when [expanded].
  final List<UpdateStep> steps;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final look = batchPhaseLook(phase);
    final canExpand = steps.isNotEmpty && onToggle != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: T.card,
        border: Border.all(color: T.cardStroke),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        InkWell(
          onTap: canExpand ? onToggle : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
            child: Row(children: [
              phase == BatchPhase.running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.2))
                  : Icon(look.icon, size: 16, color: look.color),
              const SizedBox(width: 10),
              SizedBox(
                width: 210,
                child: Text(title,
                    style: const TextStyle(
                        color: T.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: Text(detail,
                    style: TextStyle(
                        color: phase == BatchPhase.failed ? T.fail : T.muted,
                        fontSize: 12.5),
                    overflow: TextOverflow.ellipsis),
              ),
              if (elapsed != null) ...[
                const SizedBox(width: 8),
                Text(formatDuration(elapsed!),
                    style: const TextStyle(color: T.muted, fontSize: 12)),
              ],
              const SizedBox(width: 6),
              _pill(look.color, batchPhaseLabel(phase)),
              if (canExpand)
                Icon(expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: T.muted),
            ]),
          ),
        ),
        if (expanded && steps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 12, 10),
            child: Column(children: [
              for (final step in steps)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(children: [
                    Icon(_stepIcon(step.status),
                        size: 14, color: _stepColor(step.status)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(step.title,
                          style: TextStyle(
                              color: step.status == StepStatus.pending
                                  ? T.muted
                                  : T.ink,
                              fontSize: 12.5),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (step.detail.isNotEmpty)
                      Flexible(
                        child: Text(step.detail,
                            style: TextStyle(
                                color: _stepColor(step.status), fontSize: 12),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ]),
                ),
            ]),
          ),
      ]),
    );
  }

  static Widget _pill(Color color, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
      );

  static IconData _stepIcon(StepStatus s) => switch (s) {
        StepStatus.ok => Icons.check_circle,
        StepStatus.fail => Icons.cancel,
        StepStatus.warn => Icons.warning_amber_rounded,
        StepStatus.running => Icons.sync,
        StepStatus.skipped => Icons.remove_circle_outline,
        StepStatus.pending => Icons.radio_button_unchecked,
      };

  static Color _stepColor(StepStatus s) => switch (s) {
        StepStatus.ok => T.pass,
        StepStatus.fail => T.fail,
        StepStatus.warn => T.warn,
        StepStatus.running => T.titleBlue,
        _ => T.muted,
      };
}
