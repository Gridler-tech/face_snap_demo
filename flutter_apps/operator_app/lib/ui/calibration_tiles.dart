// The Calibration page's overview (design 2026-10-16, proposal A): four tiles - Camera
// order, Expected cameras, Focus, Photo colour - each with an icon, its name, one value
// line and a status pill; only the selected tile's section shows below them. The four
// status functions are pure (the values the page holds in, a value line and a status
// out), so every row of the status table is unit-tested without a server.
import 'package:face_snap_grpc/face_snap_grpc.dart' show ColourCorrectionState;
import 'package:flutter/material.dart';

import '../pages/photo_colour_card.dart' show colourNotAvailable;
import '../pages/photo_colour_measure_dialog.dart' show colourLights;
import 'ui.dart';

/// The four tiles, in their order, with their names and icons.
enum CalibrationSection {
  cameraOrder('Camera order', Icons.swap_vert),
  expectedCameras('Expected cameras', Icons.videocam_outlined),
  focus('Focus', Icons.center_focus_strong_outlined),
  photoColour('Photo colour', Icons.palette_outlined);

  const CalibrationSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// A tile's status pill. Done / Own colours = success, To do / Check / Not saved =
/// warning, Shipped / Not available / Set = neutral (the shipped matrix is a working
/// default, not a fault; "Set" is the focus value, which the tile does not judge).
enum TileStatus {
  done('Done', T.pass, needsAttention: false),
  toDo('To do', T.warn, needsAttention: true),
  check('Check', T.warn, needsAttention: true),
  notSaved('Not saved', T.warn, needsAttention: true),
  ownColours('Own colours', T.pass, needsAttention: false),
  shipped('Shipped', T.muted, needsAttention: false),
  notAvailable('Not available', T.muted, needsAttention: false),
  set('Set', T.muted, needsAttention: false);

  const TileStatus(this.label, this.color, {required this.needsAttention});
  final String label;
  final Color color;

  /// The tile asks for the operator: the default selection opens the first such tile.
  final bool needsAttention;
}

/// A tile's value line and status; a null status = the page is still loading (no pill).
typedef TileState = ({String value, TileStatus? status});

/// The ordering modes (GetSettings camera_ordering_mode) with their operator labels:
/// the Camera order selector's segments and the tile's value line.
const orderingModeLabels = <String, String>{
  'manual': 'Manual',
  'automatic': 'Automatic (USB sockets)',
  'person': 'By a person',
  'surroundings': 'From the surroundings',
};

/// "Not saved" (the column marks: [ColumnState.anyChanged]) wins over every other status.
TileState _tile(String value, TileStatus? status, bool notSaved) =>
    (value: value, status: notSaved ? TileStatus.notSaved : status);

/// Camera order: the mode and "N of M placed" ([positions]: each listed camera's
/// calibrated position, 0 = unset; null = still loading). Done when every camera has a
/// position; To do when one is unset or no camera is listed.
TileState cameraOrderTile(
    {required String mode, required List<int>? positions, required bool notSaved}) {
  final label = orderingModeLabels[mode] ?? mode;
  if (positions == null) return _tile(label, null, notSaved);
  final placed = positions.where((p) => p > 0).length;
  final all = positions.isNotEmpty && placed == positions.length;
  return _tile('$label · $placed of ${positions.length} placed',
      all ? TileStatus.done : TileStatus.toDo, notSaved);
}

/// Expected cameras: "Automatic (N found)" or the set number ([expected], 0 =
/// automatic; [found] = the cameras GetCalibration lists, null = still loading). Check
/// when a set number differs from the number found (the line then names both).
TileState expectedCamerasTile(
    {required int expected, required int? found, required bool notSaved}) {
  if (expected <= 0) {
    return _tile(found == null ? 'Automatic' : 'Automatic ($found found)',
        found == null ? null : TileStatus.done, notSaved);
  }
  if (found == null) return _tile('$expected', null, notSaved);
  return found == expected
      ? _tile('$expected', TileStatus.done, notSaved)
      : _tile('$expected · $found found', TileStatus.check, notSaved);
}

/// Focus: the value in force ("Focus 62"; -1 = unknown) with the neutral "Set". The
/// tile never judges done or to do: the server has no reliable "focus was calibrated"
/// signal (a column adopted by a server gets a standard holding every setting in
/// force, the default focus 40 included; "Restore factory (all)" deletes the
/// standard). Not saved (the column mark) wins. [focus] null = still loading.
TileState focusTile({required int? focus, required bool notSaved}) {
  if (focus == null) return _tile('Focus', null, notSaved);
  return _tile(focus >= 0 ? 'Focus $focus' : 'Focus unknown', TileStatus.set, notSaved);
}

/// Photo colour: which lights have this kiosk's own matrix and which the shipped one,
/// by the labels the Photo colour card shows (the same rule as colourStatusText: own =
/// source "kiosk"; a light the server does not list is shipped). Own colours when all
/// three are own, Shipped otherwise; a server without the feature (no
/// colour_corrections): not available.
TileState photoColourTile(List<ColourCorrectionState>? states,
    {required bool notSaved}) {
  if (states == null || states.isEmpty) {
    return _tile(colourNotAvailable, TileStatus.notAvailable, notSaved);
  }
  bool own(String light) =>
      states.any((s) => s.light == light && s.source == 'kiosk');
  final ownLabels = [for (final (l, label) in colourLights) if (own(l)) label];
  final shippedLabels = [for (final (l, label) in colourLights) if (!own(l)) label];
  final value = [
    if (ownLabels.isNotEmpty) 'Own: ${ownLabels.join(', ')}',
    if (shippedLabels.isNotEmpty)
      '${ownLabels.isEmpty ? 'Shipped' : 'shipped'}: ${shippedLabels.join(', ')}',
  ].join(' · ');
  return _tile(value,
      shippedLabels.isEmpty ? TileStatus.ownColours : TileStatus.shipped, notSaved);
}

/// The tile opened when the operator has not chosen one: the first that is not done
/// (To do, Check, Not saved); Camera order when all are.
CalibrationSection defaultSection(Map<CalibrationSection, TileState> tiles) {
  for (final section in CalibrationSection.values) {
    if (tiles[section]?.status?.needsAttention ?? false) return section;
  }
  return CalibrationSection.cameraOrder;
}

/// One overview tile: the section's icon and name, the value line and the status pill;
/// the selected one has the accent border.
class CalibrationTileCard extends StatelessWidget {
  const CalibrationTileCard(
      {super.key,
      required this.section,
      required this.state,
      required this.selected,
      required this.onTap});

  final CalibrationSection section;
  final TileState state;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    final radius = BorderRadius.circular(12);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: T.card,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: EdgeInsets.all(selected ? 13 : 14),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                  color: selected ? T.titleBlue : T.cardStroke,
                  width: selected ? 2 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(section.icon, size: 20, color: T.titleBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(section.label,
                      style: const TextStyle(
                          color: T.ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(state.value,
                  style: const TextStyle(color: T.muted, fontSize: 12.5, height: 1.35)),
              const SizedBox(height: 8),
              if (status != null) pill(status.color, status.label),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The four tiles: one row on a wide window, two rows of two on a narrow one (one
/// column on a very narrow one); the tiles of a row share its height.
class CalibrationTiles extends StatelessWidget {
  const CalibrationTiles(
      {super.key, required this.tiles, required this.selected, required this.onSelect});

  final Map<CalibrationSection, TileState> tiles;
  final CalibrationSection selected;
  final ValueChanged<CalibrationSection> onSelect;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final perRow = width >= 840 ? 4 : (width >= 420 ? 2 : 1);
      const sections = CalibrationSection.values;
      return Column(children: [
        for (var start = 0; start < sections.length; start += perRow) ...[
          if (start > 0) const SizedBox(height: _gap),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = start; i < start + perRow && i < sections.length; i++) ...[
                if (i > start) const SizedBox(width: _gap),
                Expanded(
                  child: CalibrationTileCard(
                    key: ValueKey('calibration-tile-${sections[i].name}'),
                    section: sections[i],
                    state: tiles[sections[i]] ?? (value: '', status: null),
                    selected: sections[i] == selected,
                    onTap: () => onSelect(sections[i]),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ]);
    });
  }
}

/// A section's closed "How it works" fold: the longer explanation, out of the way.
class HowItWorks extends StatelessWidget {
  const HowItWorks(this.paragraphs, {super.key});

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text('How it works',
            style: TextStyle(color: T.titleBlue, fontSize: 13, fontWeight: FontWeight.w600)),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: Alignment.centerLeft,
        dense: true,
        visualDensity: VisualDensity.compact,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: T.titleBlue,
        collapsedIconColor: T.titleBlue,
        children: [
          for (final (i, text) in paragraphs.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: T.muted, fontSize: 12.5, height: 1.45)),
          ],
        ],
      ),
    );
  }
}
