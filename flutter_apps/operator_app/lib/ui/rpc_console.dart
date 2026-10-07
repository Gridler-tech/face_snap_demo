// RPC console (developer mode): every gRPC call this app makes to a FaceSnap
// server and every answer, so an operator or developer sees exactly what a
// button does. Docked at the bottom of the window by HomeShell, it stays open
// across page switches; opening it switches the SDK's recorder (RpcTrace in
// face_snap_grpc) on, closing it switches recording off again — with the
// console closed the channels do nothing extra.
//
// One line per call: time, Service.Method, the request in one line, duration,
// the outcome (reply, or the gRPC error in red). Expand a line for the full
// request and reply as proto3 JSON (bytes fields shown as "<N bytes>"); a
// stream lists its items in order, a camera preview is summarised (frames,
// frames/s, last frame size). "Dart" / "C#" copy the code for that exact call.
import 'dart:async';
import 'dart:convert';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui.dart';

/// The console's state, app-wide (the panel is rebuilt when the shell is, the
/// calls and filters are not lost).
class RpcConsoleController extends ChangeNotifier {
  RpcConsoleController({this.repaintEvery = const Duration(milliseconds: 100)});

  /// The one the app uses.
  static final RpcConsoleController instance = RpcConsoleController();

  /// Repaints are coalesced: a preview stream changes its call ~30 times/s.
  final Duration repaintEvery;

  /// Open = docked panel visible AND recording on.
  final ValueNotifier<bool> open = ValueNotifier(false);

  final List<RpcCall> _calls = [];
  StreamSubscription<RpcEvent>? _events;
  Timer? _repaint;

  bool _paused = false;
  bool _errorsOnly = false;
  bool _showPolling = false;
  String? _service;
  String _search = '';

  /// Expanded lines (call ids) and expanded stream items ("id:index").
  final Set<int> expanded = {};
  final Set<String> expandedItems = {};

  bool get paused => _paused;
  bool get errorsOnly => _errorsOnly;
  bool get showPolling => _showPolling;
  String? get service => _service;
  String get search => _search;

  /// Every call the console holds, oldest first.
  List<RpcCall> get calls => List.unmodifiable(_calls);

  /// The services seen so far, for the filter.
  List<String> get services =>
      ({for (final c in _calls) c.serviceName}.toList()..sort());

  /// The calls that pass the filters, oldest first.
  List<RpcCall> get visible => [
    for (final c in _calls)
      if (_passes(c)) c,
  ];

  bool _passes(RpcCall c) {
    if (!_showPolling && isPolling(c)) return false;
    if (_service != null && c.serviceName != _service) return false;
    if (_errorsOnly && !isFailure(c)) return false;
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    return '${c.serviceName}.${c.method}'.toLowerCase().contains(q) ||
        requestSummary(c).toLowerCase().contains(q) ||
        outcomeSummary(c).toLowerCase().contains(q);
  }

  /// Open/close the console; recording follows.
  void setOpen(bool on) {
    if (on == open.value) return;
    if (on) {
      // Pick up what was recorded before (the SDK keeps the last 2000 calls).
      _calls
        ..clear()
        ..addAll(RpcTrace.calls);
      _events = RpcTrace.events.listen(_onEvent);
      RpcTrace.enabled = true;
    } else {
      RpcTrace.enabled = false;
      _events?.cancel();
      _events = null;
      _repaint?.cancel();
      _repaint = null;
    }
    open.value = on;
    notifyListeners();
  }

  void toggle() => setOpen(!open.value);

  void _onEvent(RpcEvent e) {
    if (e.type == RpcEventType.started) {
      if (_paused) return; // paused: no new lines
      _calls.add(e.call);
      if (_calls.length > RpcTrace.capacity) _calls.removeAt(0);
    } else if (_paused && !_calls.contains(e.call)) {
      return;
    }
    _scheduleRepaint();
  }

  void _scheduleRepaint() {
    if (_repaint != null) return;
    _repaint = Timer(repaintEvery, () {
      _repaint = null;
      notifyListeners();
    });
  }

  void setPaused(bool v) {
    _paused = v;
    notifyListeners();
  }

  void setErrorsOnly(bool v) {
    _errorsOnly = v;
    notifyListeners();
  }

  void setShowPolling(bool v) {
    _showPolling = v;
    notifyListeners();
  }

  void setService(String? v) {
    _service = v;
    notifyListeners();
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void toggleExpanded(int id) {
    expanded.contains(id) ? expanded.remove(id) : expanded.add(id);
    notifyListeners();
  }

  void toggleItem(String key) {
    expandedItems.contains(key)
        ? expandedItems.remove(key)
        : expandedItems.add(key);
    notifyListeners();
  }

  /// Forget every call (also the SDK's ring buffer).
  void clear() {
    _calls.clear();
    expanded.clear();
    expandedItems.clear();
    RpcTrace.clear();
    notifyListeners();
  }

  /// The shown calls as JSON lines (one call per line).
  String toJsonl() =>
      visible.map((c) => jsonEncode(c.toJson())).join('\n') +
      (visible.isEmpty ? '' : '\n');

  /// Test seam for the "Save…" dialog.
  @visibleForTesting
  static Future<FileSaveLocation?> Function({
    String? suggestedName,
    List<XTypeGroup> acceptedTypeGroups,
  })
  pickSaveLocation = getSaveLocation;

  @override
  void dispose() {
    _events?.cancel();
    _repaint?.cancel();
    open.dispose();
    super.dispose();
  }
}

// ---- summaries ----------------------------------------------------------------

/// Background status polling (the server list's automatic probes).
bool isPolling(RpcCall c) => c.tag == 'poll';

/// A failed call. Leaving a stream (the caller's cancel) is not a failure.
bool isFailure(RpcCall c) => c.isError && !c.cancelledByCaller;

bool isPreview(RpcCall c) =>
    c.service == 'kiosk.Kiosk' && c.method == 'StreamPreview';

bool isStream(RpcCall c) =>
    c.kind != RpcKind.unary && c.kind != RpcKind.unknown;

/// `key: value, key: {…}` — compact, no quotes, for one line.
String oneLine(Object? json, {int max = 160}) {
  String render(Object? v) => switch (v) {
    null => 'null',
    final Map<dynamic, dynamic> m when m.isEmpty => '{}',
    final Map<dynamic, dynamic> m =>
      '{${m.entries.map((e) => '${e.key}: ${render(e.value)}').join(', ')}}',
    final List<dynamic> l => '[${l.map(render).join(', ')}]',
    final String s when bytesMarkerLength(s) != null => s,
    final String s => '"$s"',
    _ => '$v',
  };
  var text = render(json);
  // The outer braces add nothing on one line.
  if (text.startsWith('{') && text.endsWith('}') && text.length > 2) {
    text = text.substring(1, text.length - 1);
  }
  return text.length <= max ? text : '${text.substring(0, max - 1)}…';
}

final Expando<String> _requestCache = Expando();
final Expando<(int, bool, String)> _outcomeCache = Expando();

/// What a call without parameters shows as its request.
const String noParameters = 'no parameters (Empty)';

/// The request on one line ([noParameters] for Empty).
String requestSummary(RpcCall c) {
  final cached = _requestCache[c];
  if (cached != null) return cached;
  if (c.requests.isEmpty) return '';
  final r = c.requests.first;
  final text =
      r.type == 'google.protobuf.Empty' ? noParameters : oneLine(r.json);
  return _requestCache[c] = text;
}

/// The outcome on one line: the reply, the stream's progress, or the error.
String outcomeSummary(RpcCall c) {
  final cached = _outcomeCache[c];
  if (cached != null && cached.$1 == c.responseCount && cached.$2 == c.done) {
    return cached.$3;
  }
  final text = _outcome(c);
  _outcomeCache[c] = (c.responseCount, c.done, text);
  return text;
}

String _outcome(RpcCall c) {
  final error = isFailure(c)
      ? '${c.statusName}${(c.statusMessage ?? '').isEmpty ? '' : ': ${c.statusMessage}'}'
      : null;
  if (isPreview(c)) {
    final p = previewSummary(c);
    return error == null ? p : '$p · $error';
  }
  if (isStream(c)) {
    final items = '${c.responseCount} item${c.responseCount == 1 ? '' : 's'}';
    if (!c.done) return 'streaming… $items';
    if (error != null) return '$items · $error';
    if (c.cancelledByCaller) return '$items · stopped by the app';
    return '$items · OK';
  }
  if (!c.done) return '…';
  if (error != null) return error;
  final reply = c.lastResponse;
  if (reply == null) return c.statusName ?? '';
  if (reply.type == 'google.protobuf.Empty') return 'OK';
  final line = oneLine(reply.json);
  return line.isEmpty ? 'OK (default reply)' : line;
}

/// "120 frames · 29.8 fps · last 46,512 bytes (640×480)"
String previewSummary(RpcCall c) {
  final n = c.responseCount;
  final parts = <String>['$n frame${n == 1 ? '' : 's'}'];
  final first = c.responses.isEmpty ? null : c.responses.first;
  final last = c.lastResponse;
  if (first != null && last != null && n > 1 && last.at > first.at) {
    final fps = (n - 1) / (last.at - first.at).inMicroseconds * 1e6;
    parts.add('${fps.toStringAsFixed(1)} fps');
  }
  if (last != null) {
    final json = last.json;
    final size = json is Map && json['width'] != null && json['height'] != null
        ? ' (${json['width']}×${json['height']})'
        : '';
    parts.add('last ${_thousands(last.bytes)} bytes$size');
  }
  if (!c.done) parts.add('running');
  if (c.done && c.cancelledByCaller) parts.add('stopped by the app');
  return parts.join(' · ');
}

String _thousands(int n) {
  final s = '$n';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String _two(int n) => n.toString().padLeft(2, '0');

/// hh:mm:ss.mmm
String clockTime(DateTime t) =>
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}.'
    '${t.millisecond.toString().padLeft(3, '0')}';

String durationText(RpcCall c) {
  if (!c.done) return '…';
  final ms = c.duration!.inMicroseconds / 1000;
  if (ms < 10) return '${ms.toStringAsFixed(1)} ms';
  if (ms < 10000) return '${ms.round()} ms';
  return '${(ms / 1000).toStringAsFixed(1)} s';
}

String prettyJson(Object? json) =>
    const JsonEncoder.withIndent('  ').convert(json);

// ---- the shell's pieces -------------------------------------------------------

/// The console's on/off button (top of the navigation rail; HomeShell shows
/// it in developer mode only).
class RpcConsoleButton extends StatelessWidget {
  const RpcConsoleButton({super.key, this.controller});

  final RpcConsoleController? controller;

  @override
  Widget build(BuildContext context) {
    final c = controller ?? RpcConsoleController.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: c.open,
      builder: (context, on, _) => Tooltip(
        message: on
            ? 'Close the RPC console (stops recording)'
            : 'RPC console: every gRPC call and its answer',
        child: InkWell(
          key: const ValueKey('rpc-console-button'),
          borderRadius: BorderRadius.circular(10),
          onTap: c.toggle,
          child: Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: on ? const Color(0xFFDCE9F6) : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: on ? T.titleBlue : T.line),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.terminal,
                  size: 20,
                  color: on ? T.titleBlue : T.muted,
                ),
                const SizedBox(height: 2),
                Text(
                  'RPC',
                  style: TextStyle(
                    color: on ? T.titleBlue : T.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The docked console with its drag handle; the height survives closing.
class RpcConsoleDock extends StatefulWidget {
  const RpcConsoleDock({super.key, this.controller});

  final RpcConsoleController? controller;

  @override
  State<RpcConsoleDock> createState() => _RpcConsoleDockState();
}

class _RpcConsoleDockState extends State<RpcConsoleDock> {
  static double _height = 300;

  @override
  Widget build(BuildContext context) {
    final max = (MediaQuery.sizeOf(context).height - 160).clamp(140.0, 4000.0);
    final height = _height.clamp(120.0, max);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.resizeRow,
          child: GestureDetector(
            key: const ValueKey('rpc-console-resize'),
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => setState(
              () => _height = (height - d.delta.dy).clamp(120.0, max),
            ),
            child: Container(
              height: 7,
              decoration: const BoxDecoration(
                color: T.ground,
                border: Border(top: BorderSide(color: T.cardStroke)),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 44,
                height: 3,
                decoration: BoxDecoration(
                  color: T.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: height,
          child: RpcConsolePanel(controller: widget.controller),
        ),
      ],
    );
  }
}

// ---- the panel ----------------------------------------------------------------

const _mono = TextStyle(
  fontFamily: 'Consolas',
  fontFamilyFallback: ['Courier New', 'monospace'],
  fontSize: 12.5,
  color: T.ink,
);

class RpcConsolePanel extends StatefulWidget {
  const RpcConsolePanel({super.key, this.controller});

  final RpcConsoleController? controller;

  @override
  State<RpcConsolePanel> createState() => _RpcConsolePanelState();
}

class _RpcConsolePanelState extends State<RpcConsolePanel> {
  late final TextEditingController _searchText;
  final ScrollController _scroll = ScrollController();

  RpcConsoleController get _c =>
      widget.controller ?? RpcConsoleController.instance;

  @override
  void initState() {
    super.initState();
    _searchText = TextEditingController(text: _c.search);
  }

  @override
  void dispose() {
    _searchText.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Keep following the newest call while the list sits at its end.
  void _followTail() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.maxScrollExtent - p.pixels < 40) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _save() async {
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final location = await RpcConsoleController.pickSaveLocation(
      suggestedName: 'facesnap_rpc_$stamp.jsonl',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON lines', extensions: ['jsonl']),
      ],
    );
    if (location == null) return; // dialog cancelled
    final text = _c.toJsonl();
    await XFile.fromData(
      utf8.encode(text),
      mimeType: 'application/x-ndjson',
    ).saveTo(location.path);
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('RPC log saved to ${location.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final visible = _c.visible;
        _followTail();
        return Container(
          color: T.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _toolbar(visible.length),
              const Divider(height: 1, color: T.cardStroke),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          _c.calls.isEmpty
                              ? 'Recording. Every gRPC call the app makes shows up here.'
                              : 'No call matches the filters.',
                          style: const TextStyle(color: T.muted, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        itemCount: visible.length,
                        itemBuilder: (context, i) => _CallLine(
                          key: ValueKey('rpc-call-${visible[i].id}'),
                          call: visible[i],
                          controller: _c,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolbar(int shown) {
    final services = _c.services;
    final service = _c.service != null && services.contains(_c.service)
        ? _c.service
        : null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      child: Row(
        children: [
          const Text(
            'RPC CONSOLE',
            style: TextStyle(
              color: T.titleBlue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _c.paused
                ? '$shown of ${_c.calls.length} calls · paused'
                : '$shown of ${_c.calls.length} calls',
            style: TextStyle(color: _c.paused ? T.warn : T.muted, fontSize: 12),
          ),
          const SizedBox(width: 16),
          DropdownButton<String?>(
            key: const ValueKey('rpc-service-filter'),
            value: service,
            isDense: true,
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: T.ink, fontSize: 13),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All services'),
              ),
              for (final s in services)
                DropdownMenuItem<String?>(value: s, child: Text(s)),
            ],
            onChanged: _c.setService,
          ),
          const SizedBox(width: 10),
          _Toggle(
            label: 'Errors only',
            value: _c.errorsOnly,
            onChanged: _c.setErrorsOnly,
          ),
          const SizedBox(width: 6),
          _Toggle(
            label: 'Show polling',
            tooltip:
                'The server list\'s automatic GetKioskInfo probes '
                '(every 30 s)',
            value: _c.showPolling,
            onChanged: _c.setShowPolling,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 210,
            height: 32,
            child: TextField(
              key: const ValueKey('rpc-search'),
              controller: _searchText,
              onChanged: _c.setSearch,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: T.line),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            key: const ValueKey('rpc-pause'),
            tooltip: _c.paused
                ? 'Resume (append new calls again)'
                : 'Pause (stop appending)',
            onPressed: () => _c.setPaused(!_c.paused),
            icon: Icon(
              _c.paused ? Icons.play_arrow : Icons.pause,
              color: _c.paused ? T.warn : T.ink,
            ),
          ),
          IconButton(
            key: const ValueKey('rpc-clear'),
            tooltip: 'Clear',
            onPressed: _c.clear,
            icon: const Icon(Icons.delete_sweep_outlined, color: T.ink),
          ),
          TextButton.icon(
            key: const ValueKey('rpc-save'),
            onPressed: _c.calls.isEmpty ? null : _save,
            icon: const Icon(Icons.save_alt, size: 18),
            label: const Text('Save…'),
          ),
          IconButton(
            tooltip: 'Close the console (stops recording)',
            onPressed: () => _c.setOpen(false),
            icon: const Icon(Icons.close, color: T.muted),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: value,
      onSelected: onChanged,
      visualDensity: VisualDensity.compact,
      selectedColor: const Color(0xFFDCE9F6),
      checkmarkColor: T.titleBlue,
      side: BorderSide(color: value ? T.titleBlue : T.line),
      backgroundColor: T.card,
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// One call: the summary line, and its details when expanded.
class _CallLine extends StatelessWidget {
  const _CallLine({super.key, required this.call, required this.controller});

  final RpcCall call;
  final RpcConsoleController controller;

  void _copy(BuildContext context, String language, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          '$language code for ${call.serviceName}.${call.method} '
          'copied to the clipboard.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = call;
    final open = controller.expanded.contains(c.id);
    final failed = isFailure(c);
    final outcomeColor = failed
        ? T.fail
        : (c.done ? (c.cancelledByCaller ? T.muted : T.pass) : T.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => controller.toggleExpanded(c.id),
          child: Container(
            decoration: BoxDecoration(
              color: failed ? const Color(0x0FC6413D) : null,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF0F3F6)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
            child: Row(
              children: [
                Icon(
                  open ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: T.muted,
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 98,
                  child: Text(
                    clockTime(c.start),
                    style: _mono.copyWith(color: T.muted),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${c.serviceName}.${c.method}',
                          overflow: TextOverflow.ellipsis,
                          style: _mono.copyWith(
                            color: T.titleBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isStream(c)) ...[
                        const SizedBox(width: 6),
                        const _Badge('stream'),
                      ],
                      if (isPolling(c)) ...[
                        const SizedBox(width: 6),
                        const _Badge('poll'),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    requestSummary(c),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _mono,
                  ),
                ),
                SizedBox(
                  width: 76,
                  child: Text(
                    durationText(c),
                    textAlign: TextAlign.right,
                    style: _mono.copyWith(color: T.muted),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Text(
                    outcomeSummary(c),
                    key: ValueKey('rpc-outcome-${c.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _mono.copyWith(color: outcomeColor),
                  ),
                ),
                _CopyButton(
                  label: 'Dart',
                  tooltip: 'Copy as Dart (face_snap_grpc)',
                  onPressed: () => _copy(context, 'Dart', rpcCallAsDart(c)),
                ),
                _CopyButton(
                  label: 'C#',
                  tooltip: 'Copy as C# (GrpcLibrary)',
                  onPressed: () => _copy(context, 'C#', rpcCallAsCSharp(c)),
                ),
              ],
            ),
          ),
        ),
        if (open) _Details(call: c, controller: controller),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: const Color(0xFFE3EDF7),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: T.titleBlue,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(40, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: T.titleBlue,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// The expanded view: metadata, the request, then the reply / the stream.
class _Details extends StatelessWidget {
  const _Details({required this.call, required this.controller});

  final RpcCall call;
  final RpcConsoleController controller;

  /// A stream shows at most this many items (the saved file has them all,
  /// up to the SDK's per-call limit).
  static const maxItemsShown = 300;

  @override
  Widget build(BuildContext context) {
    final c = call;
    final meta = [
      c.address,
      c.kind.name,
      if (c.tag != null) 'tag ${c.tag}',
      '#${c.id}',
      if (c.done) '${c.statusName}',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 2, 10, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: T.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(meta, style: const TextStyle(color: T.muted, fontSize: 12)),
          const SizedBox(height: 8),
          _label('REQUEST'),
          _JsonBlock(
            c.requests.isEmpty
                ? '(not sent)'
                : c.requests.length == 1 &&
                        c.requests.single.type == 'google.protobuf.Empty'
                    ? noParameters
                    : prettyJson(
                    c.requests.length == 1
                        ? c.requests.single.json
                        : [for (final r in c.requests) r.json],
                  ),
          ),
          const SizedBox(height: 10),
          ..._reply(context),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: T.titleBlue,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _status() {
    final c = call;
    if (!c.done) {
      return const Text(
        'running…',
        style: TextStyle(color: T.muted, fontSize: 12.5),
      );
    }
    final failed = isFailure(c);
    final text = c.cancelledByCaller
        ? 'CANCELLED by the app after ${durationText(c)}'
        : '${c.statusName}${(c.statusMessage ?? '').isEmpty ? '' : ': ${c.statusMessage}'}'
              ' after ${durationText(c)}';
    return SelectableText(
      text,
      style: _mono.copyWith(
        color: failed ? T.fail : (c.cancelledByCaller ? T.muted : T.pass),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  List<Widget> _reply(BuildContext context) {
    final c = call;
    if (isPreview(c)) {
      return [
        _label('PREVIEW'),
        Text(
          previewSummary(c),
          key: ValueKey('rpc-preview-${c.id}'),
          style: _mono,
        ),
        const SizedBox(height: 6),
        _status(),
      ];
    }
    if (isStream(c)) {
      final items = c.responses.length > maxItemsShown
          ? c.responses.sublist(0, maxItemsShown)
          : c.responses;
      final hidden = c.responseCount - items.length;
      return [
        _label(
          'STREAM — ${c.responseCount} ITEM${c.responseCount == 1 ? '' : 'S'}',
        ),
        for (var i = 0; i < items.length; i++)
          _StreamItem(
            key: ValueKey('rpc-item-${c.id}-$i'),
            index: i,
            message: items[i],
            expanded: controller.expandedItems.contains('${c.id}:$i'),
            onTap: () => controller.toggleItem('${c.id}:$i'),
          ),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '… $hidden more not shown',
              style: const TextStyle(color: T.muted, fontSize: 12),
            ),
          ),
        const SizedBox(height: 6),
        _status(),
      ];
    }
    if (isFailure(c) || c.responses.isEmpty) {
      return [_label('REPLY'), _status()];
    }
    return [
      _label('REPLY'),
      _JsonBlock(prettyJson(c.responses.single.json)),
      const SizedBox(height: 6),
      _status(),
    ];
  }
}

class _StreamItem extends StatelessWidget {
  const _StreamItem({
    super.key,
    required this.index,
    required this.message,
    required this.expanded,
    required this.onTap,
  });

  final int index;
  final RpcMessage message;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final at = '+${(message.at.inMicroseconds / 1000).round()} ms';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: T.muted,
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '#${index + 1}',
                    style: _mono.copyWith(color: T.muted),
                  ),
                ),
                SizedBox(
                  width: 84,
                  child: Text(at, style: _mono.copyWith(color: T.muted)),
                ),
                Expanded(
                  child: Text(
                    oneLine(message.json, max: 220),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _mono,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 0, 6),
            child: _JsonBlock(prettyJson(message.json)),
          ),
      ],
    );
  }
}

/// Dark code block, as in the developer-info popups.
class _JsonBlock extends StatelessWidget {
  const _JsonBlock(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: T.ink,
      borderRadius: BorderRadius.circular(8),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SelectableText(
        text,
        style: _mono.copyWith(color: const Color(0xFFDCE4EC), height: 1.45),
      ),
    ),
  );
}
