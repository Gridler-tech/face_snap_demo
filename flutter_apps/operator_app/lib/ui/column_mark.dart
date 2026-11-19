// The ● mark of a column setting that is changed and not saved (spec 2026-10-10 section
// 5.5), with the link to the Column page, where it is saved as the column's standard or put
// back. The Lighting, Calibration and Camera pages show it next to those settings.
import 'package:flutter/material.dart';

import '../services/column_state.dart';
import 'page_nav.dart';
import 'ui_shared.dart';

class ColumnChangedMark extends StatelessWidget {
  const ColumnChangedMark(this.names, {super.key});

  /// The column settings (GetColumnProfile names) this mark stands for.
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ColumnState.revision,
      builder: (context, _, _) {
        if (!ColumnState.anyChanged(names)) return const SizedBox.shrink();
        return Padding(
          key: ValueKey('column-changed-${names.join('+')}'),
          padding: const EdgeInsets.only(left: 4, top: 2, bottom: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('●', style: TextStyle(color: T.warn, fontSize: 14)),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => PageNav.open(columnPageLabel),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 28),
                  foregroundColor: T.warn),
              child: const Text('Not saved — open the Column page',
                  style: TextStyle(fontSize: 12.5)),
            ),
          ]),
        );
      },
    );
  }
}
