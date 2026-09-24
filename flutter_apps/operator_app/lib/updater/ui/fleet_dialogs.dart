// The two dialogs a batch run goes through: pick the fleet, then confirm the
// pre-flight. Kept out of main.dart because both are self-contained and
// widget-testable on their own.
import 'package:flutter/material.dart';

import '../batch_runner.dart';
import '../fleet.dart';
import '../../ui/ui.dart';

/// Multi-select fleet picker. Returns the entries the operator ticked (with
/// any per-board credential overrides applied to them), or null on cancel.
class FleetPickerDialog extends StatefulWidget {
  const FleetPickerDialog({
    super.key,
    required this.entries,
    required this.defaultUser,
    required this.defaultPassword,
    this.onRescan,
  });

  final List<FleetEntry> entries;
  final String defaultUser;
  final String defaultPassword;

  /// Re-run discovery; the result is merged, keeping ticks and overrides.
  final Future<List<FleetEntry>> Function()? onRescan;

  @override
  State<FleetPickerDialog> createState() => _FleetPickerDialogState();
}

class _FleetPickerDialogState extends State<FleetPickerDialog> {
  late List<FleetEntry> _entries = widget.entries;
  final _expanded = <String>{};
  bool _rescanning = false;

  int get _selectedCount => _entries.where((e) => e.selected).length;

  Future<void> _rescan() async {
    final rescan = widget.onRescan;
    if (rescan == null) return;
    setState(() => _rescanning = true);
    final merged = await rescan();
    if (!mounted) return;
    setState(() {
      _entries = merged;
      _rescanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: T.card,
      title: const Text('Select the kiosks to update',
          style: TextStyle(color: T.ink, fontSize: 16, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 560,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: Text(
                  _entries.isEmpty
                      ? 'No kiosks found on the network.'
                      : '$_selectedCount of ${_entries.length} selected',
                  style: const TextStyle(color: T.muted, fontSize: 12.5)),
            ),
            if (_entries.isNotEmpty) ...[
              TextButton(
                onPressed: () => setState(() {
                  final all = _selectedCount != _entries.length;
                  for (final e in _entries) {
                    e.selected = all;
                  }
                }),
                child: Text(
                    _selectedCount == _entries.length ? 'Clear all' : 'Select all',
                    style: const TextStyle(fontSize: 12.5)),
              ),
            ],
            if (widget.onRescan != null)
              TextButton(
                onPressed: _rescanning ? null : _rescan,
                child: Text(_rescanning ? 'Searching…' : 'Search again',
                    style: const TextStyle(fontSize: 12.5)),
              ),
          ]),
          const SizedBox(height: 4),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _entries.length,
              itemBuilder: (context, i) => _row(_entries[i]),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: T.goGreen),
          onPressed: _selectedCount == 0
              ? null
              : () => Navigator.pop(
                  context, _entries.where((e) => e.selected).toList()),
          child: Text(_selectedCount == 0
              ? 'Select kiosks'
              : 'Continue with $_selectedCount'),
        ),
      ],
    );
  }

  Widget _row(FleetEntry entry) {
    final name = entry.kiosk.hostName;
    final open = _expanded.contains(name);
    final creds = credentialsFor(entry,
        defaultUser: widget.defaultUser,
        defaultPassword: widget.defaultPassword);
    final overridden =
        (entry.userOverride?.isNotEmpty ?? false) ||
            (entry.passwordOverride?.isNotEmpty ?? false);
    return Column(children: [
      CheckboxListTile(
        value: entry.selected,
        onChanged: (v) => setState(() => entry.selected = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(name,
            style: const TextStyle(
                color: T.ink, fontSize: 13.5, fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${entry.subtitle}  ·  ${creds.user}'
            '${overridden ? ' (custom password)' : ''}',
            style: TextStyle(
                color: entry.isClean ? T.warn : T.muted, fontSize: 12)),
        secondary: IconButton(
          icon: Icon(open ? Icons.expand_less : Icons.tune, size: 18),
          color: T.muted,
          tooltip: 'Credentials for this kiosk',
          onPressed: () => setState(
              () => open ? _expanded.remove(name) : _expanded.add(name)),
        ),
      ),
      if (open)
        Padding(
          padding: const EdgeInsets.fromLTRB(34, 0, 8, 10),
          child: Row(children: [
            Expanded(
              child: TextFormField(
                initialValue: entry.userOverride ?? '',
                decoration: InputDecoration(
                    labelText: 'User', hintText: creds.user, isDense: true),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => setState(() => entry.userOverride = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: entry.passwordOverride ?? '',
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'batch default',
                    isDense: true),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => setState(() => entry.passwordOverride = v),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// The pre-flight table: every board was checked BEFORE anything is touched.
/// Bad boards are listed as skipped rather than blocking the run. Returns true
/// to go ahead with the reachable ones.
class PreflightDialog extends StatelessWidget {
  const PreflightDialog({
    super.key,
    required this.results,
    required this.imageName,
    this.profileName,
    this.concurrency = 2,
  });

  final List<PreflightResult> results;
  final String imageName;
  final String? profileName;
  final int concurrency;

  @override
  Widget build(BuildContext context) {
    final ok = results.where((r) => r.ok).toList();
    final bad = results.where((r) => !r.ok).toList();
    return AlertDialog(
      backgroundColor: T.card,
      title: Text('Update ${ok.length} kiosk${ok.length == 1 ? '' : 's'}?',
          style: const TextStyle(
              color: T.ink, fontSize: 16, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 620,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Image: $imageName\n'
                'Settings: ${profileName ?? "keep each kiosk's own"}\n'
                '${concurrency == 1 ? 'One at a time (rolling).' : '$concurrency at a time.'} '
                'Each kiosk is offline while it updates (roughly 5-15 minutes).',
                style: const TextStyle(color: T.muted, fontSize: 12.5)),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final r in ok) _row(r, true),
              if (bad.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Skipped — these are not touched',
                        style: TextStyle(
                            color: T.fail,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                for (final r in bad) _row(r, false),
              ],
            ]),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: T.goGreen),
          onPressed:
              ok.isEmpty ? null : () => Navigator.pop(context, true),
          child: Text(ok.isEmpty
              ? 'No kiosk reachable'
              : 'Update ${ok.length} kiosk${ok.length == 1 ? '' : 's'}'),
        ),
      ],
    );
  }

  Widget _row(PreflightResult r, bool good) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(good ? Icons.check_circle : Icons.cancel,
              size: 16, color: good ? T.pass : T.fail),
          const SizedBox(width: 8),
          SizedBox(
            width: 230,
            child: Text(r.target.title,
                style: const TextStyle(
                    color: T.ink, fontSize: 12.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(r.detail,
                style: TextStyle(
                    color: good ? T.muted : T.fail, fontSize: 12.5)),
          ),
        ]),
      );
}
