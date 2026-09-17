// Operator Capture page — the capture flow split out of the Kiosk page:
// automatic/manual capture, the photo pane and the per-step timing card on
// the left, the pill-style capture-results checklist (pre-populated from the
// enabled quality checks) on the right.
import 'dart:async';
import 'dart:typed_data';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../services/photo_store.dart';
import '../services/settings_state.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';

enum _Verdict { pending, pass, fail, warn, info }

class _ResultItem {
  _ResultItem(this.key, this.text, this.verdict);

  final String? key; // null = keyless process message
  String text;
  _Verdict verdict;
}

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  static final _cameraNumberRe = RegExp(r'camera (\d+)');

  final List<_ResultItem> _results = [];
  final List<(int, Uint8List)> _photos = []; // (camera index, jpeg)
  bool _capturing = false;
  String? _message;

  // ---------- step timing ----------
  // Wall clock at the operator app from the moment the capture RPC is sent.
  // Each server status line marks the END of a stage, so the gaps between the
  // marks are the per-stage durations (the same split the measurement
  // scripts use): selection -> photo -> checks/background -> OFIQ.
  final Stopwatch _clock = Stopwatch();
  DateTime? _clockStartedAt; // wall-clock twin of _clock, for chunk stamps
  Timer? _clockTicker;
  bool _timedRunIsManual = false;
  bool _timedRunHasOfiq = false;
  Duration? _tSelected; // "Best Camera was determined"
  Duration? _tPhotoStart; // "Taking a high res photo using camera N"
  Duration? _tFrame; // "Distance in cm" = a valid frame was grabbed
  Duration? _tPhoto; // the assembled photo arrived
  Duration? _tOfiq; // OFIQ overall score (or OFIQ failure) line
  Duration? _tEnd; // stream closed
  final List<(int, Duration)> _tManualPhotos = []; // (camera, arrival)

  @override
  void initState() {
    super.initState();
    _prepareChecklist();
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    super.dispose();
  }

  void _resetTiming(bool manual) {
    _clock
      ..reset()
      ..start();
    _clockStartedAt = DateTime.now();
    _timedRunIsManual = manual;
    _timedRunHasOfiq = SettingsState.current?.ofiqChecks ?? false;
    _tSelected = _tPhotoStart = _tFrame = _tPhoto = _tOfiq = _tEnd = null;
    _tManualPhotos.clear();
    // Repaint the running step's counter while the capture is in flight.
    _clockTicker?.cancel();
    _clockTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  void _finishTiming() {
    _clock.stop();
    _clockTicker?.cancel();
    _clockTicker = null;
    _tEnd = _clock.elapsed;
  }

  /// When the photo's last JPEG chunk arrived, on the capture clock. The photo
  /// EVENT can only be emitted once the stream shows the chunks are complete
  /// (the next status line), which on the C# server is after OFIQ scoring —
  /// the chunk stamp is what actually times the delivery.
  Duration _photoArrival(DateTime? lastChunkAt) {
    final started = _clockStartedAt;
    if (lastChunkAt == null || started == null) return _clock.elapsed;
    return lastChunkAt.difference(started);
  }

  /// Marks the stage a server status line closes (automatic flow).
  void _markTiming(String text) {
    final now = _clock.elapsed;
    if (text.startsWith('Best Camera was determined')) {
      _tSelected ??= now;
    } else if (text.startsWith('Taking a high res photo')) {
      _tPhotoStart = now;
    } else if (text.startsWith('Distance in cm')) {
      _tFrame ??= now;
    } else if (text.startsWith('OFIQ overall quality') ||
        text.startsWith('OFIQ scoring')) {
      _tOfiq ??= now;
    }
  }

  // ---------- results checklist ----------

  /// Pre-populates one pending row per enabled quality check, so the operator
  /// sees the full checklist before the first status arrives (MAUI
  /// PrepareChecklist).
  void _prepareChecklist() {
    final s = SettingsState.current;
    _results
      ..clear()
      ..add(_ResultItem('Distance', 'Distance', _Verdict.pending));
    void add(bool enabled, String key, String label) {
      if (enabled) _results.add(_ResultItem(key, label, _Verdict.pending));
    }

    final ofiq = s?.ofiqChecks ?? false;
    if (ofiq) {
      // OFIQ mode: the standardized report replaces ALL the kiosk's own check
      // rows (lips/eyes still gate the capture server-side, they just don't
      // report). Only Distance above plus the OFIQ row are shown.
      add(true, 'OFIQReport', 'OFIQ quality report (ISO/IEC 29794-5)');
      return;
    }
    add(s?.lipsCheck ?? true, 'Lips', 'Lips closed');
    add(s?.eyesCheck ?? true, 'Eyes', 'Eyes open');
    add(s?.eyeGlassesCheck ?? true, 'Glasses', 'Glasses');
    add(s?.headPoseCheck ?? true, 'HeadPose', 'Head pose (frontal)');
    add(s?.sharpnessCheck ?? true, 'Sharpness', 'Sharpness');
    add(s?.redEyeDetectionCheck ?? true, 'RedEye', 'Red eye');
    add(s?.expressionCheck ?? true, 'Expression', 'Expression');
    add(s?.gazeCheck ?? true, 'Gaze', 'Gaze');
    add(s?.lightingEvennessCheck ?? true, 'LightingEven', 'Lighting evenness');
    add(s?.headSizeCheck ?? true, 'HeadSize', 'Head size/position');
  }

  /// Classifies a server status line exactly like the MAUI
  /// StatusItem.FromServerMessage and replaces the keyed row (or inserts a
  /// keyless process row at the top).
  void _addServerStatus(String text) {
    bool? parseBool(String value) {
      final colon = value.indexOf(':');
      if (colon < 0) return null;
      final rest = value.substring(colon + 1).trimLeft();
      if (rest.startsWith('True')) return true;
      if (rest.startsWith('False')) return false;
      return null;
    }

    String? key;
    var verdict = _Verdict.info;

    // 'Best Camera was determined' and 'Taking a high res photo using camera N'
    // describe the same event to an operator; keep them as ONE row that upgrades
    // its text when the camera number becomes known.
    if (text.startsWith('Best Camera was determined')) {
      setState(() => _results.insert(
          0, _ResultItem('SelectedCamera', 'Best camera was determined', _Verdict.info)));
      return;
    }
    if (text.startsWith('Taking a high res photo')) {
      final match = _cameraNumberRe.firstMatch(text);
      final combined = match == null
          ? 'Best camera determined — taking a high res photo'
          : 'Camera ${match.group(1)} selected — taking a high res photo';
      setState(() {
        // Re-insert at the top: the capture-in-progress row is the freshest
        // information and must lead the list.
        _results.removeWhere((r) => r.key == 'SelectedCamera');
        _results.insert(0, _ResultItem('SelectedCamera', combined, _Verdict.info));
      });
      return;
    }
    if (text.startsWith('Live person check')) {
      // Multi-view liveness (informational): amber when a flat photo/screen is
      // suspected so the operator's eye is drawn to it without a hard fail.
      verdict = text.contains(': passed')
          ? _Verdict.pass
          : text.contains(': failed')
              ? _Verdict.warn
              : _Verdict.info;
      setState(() => _results.insert(0, _ResultItem(null, text, verdict)));
      return;
    }
    // OFIQ report rows: the keyed row tracks progress (pending -> scoring ->
    // overall score); the per-measure detail rows are APPENDED below the
    // checklist so they don't push the process rows off the top.
    // The server judges OFIQ scores against its threshold table (provisional
    // pending ISO/IEC TR 25722): "- passed" / "- attention" suffixes.
    _Verdict ofiqVerdict(String text) => text.contains('- passed')
        ? _Verdict.pass
        : text.contains('- attention')
            ? _Verdict.warn
            : _Verdict.info;

    if (text.startsWith('Scoring the photo with OFIQ')) {
      key = 'OFIQReport';
      verdict = _Verdict.pending;
    } else if (text.startsWith('OFIQ overall quality')) {
      key = 'OFIQReport';
      verdict = ofiqVerdict(text);
    } else if (text.startsWith('OFIQ scoring')) {
      // "unavailable" / "failed"
      key = 'OFIQReport';
      verdict = _Verdict.warn;
    } else if (text.startsWith('OFIQ ')) {
      setState(() => _results.add(_ResultItem(null, text, ofiqVerdict(text))));
      return;
    } else if (text.startsWith('Distance in cm')) {
      key = 'Distance';
      verdict = _Verdict.pass;
    } else if (text.startsWith('Lips are closed')) {
      key = 'Lips';
      verdict = _Verdict.pass;
    } else if (text.startsWith('Both eyes are opened')) {
      key = 'Eyes';
      verdict = _Verdict.pass;
    } else if (text.startsWith('Glasses detected')) {
      key = 'Glasses';
      // True is bad, but glasses are allowed on some documents: amber warning.
      verdict = parseBool(text) == true ? _Verdict.warn : _Verdict.pass;
    } else if (text.startsWith('Head pose frontal')) {
      key = 'HeadPose';
      verdict = parseBool(text) == true ? _Verdict.pass : _Verdict.fail;
    } else if (text.startsWith('Sharpness OK')) {
      key = 'Sharpness';
      verdict = parseBool(text) == true ? _Verdict.pass : _Verdict.fail;
    } else if (text.startsWith('Red eye detected')) {
      key = 'RedEye';
      verdict = parseBool(text) == true ? _Verdict.fail : _Verdict.pass;
    } else if (text.startsWith('Expression neutral')) {
      key = 'Expression';
      verdict = parseBool(text) == true ? _Verdict.pass : _Verdict.fail;
    } else if (text.startsWith('Looking at camera')) {
      key = 'Gaze';
      verdict = parseBool(text) == true ? _Verdict.pass : _Verdict.fail;
    } else if (text.startsWith('Lighting even')) {
      key = 'LightingEven';
      verdict = parseBool(text) == true ? _Verdict.pass : _Verdict.fail;
    } else if (text.startsWith('Head size/position OK')) {
      key = 'HeadSize';
      verdict = parseBool(text) == true ? _Verdict.pass : _Verdict.fail;
    }

    setState(() {
      if (key != null) {
        final row = _results.where((r) => r.key == key).firstOrNull;
        if (row != null) {
          row
            ..text = text
            ..verdict = verdict;
          return;
        }
        // Recognized check but no seeded row (checklist out of sync with the
        // server's settings): keep the computed verdict rather than degrading
        // to a plain grey info row.
        _results.insert(0, _ResultItem(key, text, verdict));
        return;
      }
      _results.insert(0, _ResultItem(null, text, _Verdict.info));
    });
  }

  // ---------- capture ----------

  Future<void> _capture(bool automatic) async {
    // Re-load the settings snapshot first: the checklist must be seeded from
    // what the SERVER will actually run with. The snapshot goes stale when
    // check toggles are flipped on the Photo page after boot (they only push
    // RPCs), and results for unseeded checks would render as plain grey rows.
    try {
      await SettingsState.refresh();
    } catch (_) {
      // Unreachable right now — seed from the last known snapshot instead.
    }
    if (!mounted) return;
    setState(() {
      _capturing = true;
      _message = null;
      _photos.clear();
      _prepareChecklist();
      _resetTiming(!automatic);
    });
    try {
      final stream = automatic ? startAutomaticCapture() : startManualCapture();
      await for (final event in stream) {
        switch (event) {
          case CaptureStatus(:final description):
            _markTiming(description);
            _addServerStatus(description);
          case CapturePhoto(:final bytes, :final lastChunkAt):
            _tPhoto ??= _photoArrival(lastChunkAt);
            setState(() => _photos.add((0, bytes)));
          case CameraPhoto(:final cameraIndex, :final bytes, :final lastChunkAt):
            _tManualPhotos.add((cameraIndex, _photoArrival(lastChunkAt)));
            setState(() => _photos.add((cameraIndex, bytes)));
        }
      }
      if (_photos.isEmpty) {
        setState(() => _message = 'The capture ended without a photo.');
      }
      // Photos accumulate in the store (last few captures) so the Face
      // recognition page can compare across captures.
      PhotoStore.addCapture(_photos);
    } catch (e) {
      setState(() => _message = 'Capture failed: ${operatorMessage(e)}');
    } finally {
      _finishTiming();
      setState(() => _capturing = false);
    }
  }

  // ---------- timing rows ----------

  /// (label, start, end) per stage; `end == null` = still running. Stages
  /// the flow never reached are left out, so a failed capture shows exactly
  /// how far it got.
  List<(String, Duration, Duration?)> _timingRows() {
    if (!_clock.isRunning && _tEnd == null) return const [];
    final rows = <(String, Duration, Duration?)>[];
    if (_timedRunIsManual) {
      // One photo per camera, no gating: each row is that camera's turn.
      var previous = Duration.zero;
      for (final (camera, at) in _tManualPhotos) {
        rows.add(('Camera $camera photo', previous, at));
        previous = at;
      }
      if (_capturing) rows.add(('Next camera', previous, null));
      return rows;
    }

    rows.add(('Camera selection + liveness', Duration.zero, _tSelected));
    if (_tSelected == null) return rows;

    final photoStart = _tPhotoStart ?? _tSelected!;
    rows.add(('Photo (open camera, valid frame)', photoStart, _tFrame));
    if (_tFrame == null) return rows;

    rows.add((
      _timedRunHasOfiq
          ? 'Background + delivery'
          : 'Quality checks + background + delivery',
      _tFrame!,
      _tPhoto,
    ));
    if (_tPhoto == null) return rows;

    if (_timedRunHasOfiq || _tOfiq != null) {
      rows.add(('OFIQ scoring', _tPhoto!, _tOfiq));
    }
    return rows;
  }

  static String _seconds(Duration d) =>
      '${(d.inMilliseconds / 1000).toStringAsFixed(2)} s';

  Widget _buildTimingCard() {
    final rows = _timingRows();
    final total = _tEnd ?? (_clock.isRunning ? _clock.elapsed : null);
    if (rows.isEmpty && total == null) {
      return const Text(
          'Run a capture to see how long each step takes '
          '(measured at this app, so network time is included).',
          style: TextStyle(color: T.muted, fontSize: 13));
    }
    final scale = (total ?? Duration.zero).inMilliseconds.clamp(1, 1 << 30);

    Widget row(String label, Duration? duration, {bool running = false,
        bool bold = false}) {
      final style = TextStyle(
          color: T.ink,
          fontSize: 13.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          fontFeatures: const [FontFeature.tabularFigures()]);
      final fraction = duration == null
          ? 0.0
          : (duration.inMilliseconds / scale).clamp(0.0, 1.0);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 250, child: Text(label, style: style)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Stack(children: [
                  Container(color: const Color(0xFFF0F3F7)),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                        color: running ? T.pending : T.titleBlue),
                  ),
                ]),
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              duration == null ? '…' : _seconds(duration),
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (label, start, end) in rows)
        row(label, (end ?? _clock.elapsed) - start, running: end == null),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: T.cardStroke, height: 1),
      ),
      row(_capturing ? 'Total (running)' : 'Total', total,
          running: _capturing, bold: true),
    ]);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left: capture buttons + photo
          Expanded(
            flex: 48,
            child: Column(children: [
              SectionCard(
                title: 'Capture',
                titleLeading: const DevInfoBadge('capture'),
                shrinkWrap: true,
                child: Row(children: [
                  Expanded(
                      child: GoButton(
                          text: 'Automatic',
                          onPressed:
                              _capturing ? null : () => _capture(true))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: GoButton(
                          text: 'Manual',
                          onPressed:
                              _capturing ? null : () => _capture(false))),
                ]),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SectionCard(
                  title: 'Photo',
                  titleLeading: const DevInfoBadge('capture-photos'),
                  child: Expanded(child: _buildPhotoPane()),
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Capture timing',
                shrinkWrap: true,
                child: _buildTimingCard(),
              ),
              ErrorLine(_message),
            ]),
          ),
          const SizedBox(width: 14),
          // right: results
          Expanded(
            flex: 52,
            child: SectionCard(
              title: 'Capture results',
              titleLeading: const DevInfoBadge('capture-results'),
              child: Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _buildResultRow(_results[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPane() {
    if (_photos.isEmpty) {
      return Center(
        child: Container(
          width: 224,
          height: 288,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: T.line),
          ),
          child: _capturing
              ? const Center(child: CircularProgressIndicator())
              : const Icon(Icons.person_outline, size: 96, color: T.pending),
        ),
      );
    }
    return SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (index, bytes) in _photos)
            GestureDetector(
              onTap: () => _openPhotoViewer(index, bytes),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  // cacheHeight: decode at thumbnail size, not the 4K native
                  // resolution (~50 MB RGBA per photo without it). The zoom
                  // dialog decodes the full bytes itself.
                  child: Image.memory(bytes, height: 240, cacheHeight: 480),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      index > 0
                          ? 'Camera $index — click to zoom'
                          : 'Click to zoom',
                      style: const TextStyle(color: T.muted, fontSize: 12)),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _openPhotoViewer(int cameraIndex, Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (context) => _PhotoViewerDialog(
          cameraIndex: cameraIndex, bytes: bytes),
    );
  }

  Widget _buildResultRow(_ResultItem item) {
    final (tint, badge, glyph) = switch (item.verdict) {
      _Verdict.pass => (T.passTint, T.pass, '✓'),
      _Verdict.fail => (T.failTint, T.fail, '✕'),
      _Verdict.warn => (T.warnTint, T.warn, '!'),
      _Verdict.pending => (Colors.white, T.pending, '•'),
      _Verdict.info => (Colors.white, T.muted, 'i'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: T.cardStroke),
      ),
      child: Row(children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: badge, shape: BoxShape.circle),
          child: Text(glyph,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(item.text,
                style: const TextStyle(color: T.ink, fontSize: 13.5))),
      ]),
    );
  }
}

/// Full-screen photo viewer: pinch/scroll-wheel zoom and pan via PhotoView
/// (image-anchored, stays centered), save-to-disk through the native dialog.
class _PhotoViewerDialog extends StatelessWidget {
  const _PhotoViewerDialog({required this.cameraIndex, required this.bytes});

  final int cameraIndex;
  final Uint8List bytes;

  Future<void> _save(BuildContext context) async {
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final suggested = cameraIndex > 0
        ? 'facesnap_camera${cameraIndex}_$stamp.jpg'
        : 'facesnap_$stamp.jpg';
    final location = await getSaveLocation(
      suggestedName: suggested,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JPEG image', extensions: ['jpg']),
      ],
    );
    if (location == null) return; // dialog cancelled

    await XFile.fromData(bytes, mimeType: 'image/jpeg').saveTo(location.path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo saved to ${location.path}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF101C26),
      insetPadding: const EdgeInsets.all(24),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(children: [
            Text(
              cameraIndex > 0 ? 'Camera $cameraIndex' : 'Captured photo',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _save(context),
              icon: const Icon(Icons.save_alt, color: Colors.white),
              label: const Text('Save as…',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ]),
        ),
        Expanded(
          // PhotoView instead of a plain InteractiveViewer: it anchors zoom on
          // the image (not the letterboxed canvas), keeps it centered and
          // clamps panning to the image bounds.
          child: PhotoView(
            imageProvider: MemoryImage(bytes),
            backgroundDecoration: const BoxDecoration(color: Color(0xFF101C26)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.contained * 10,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8, left: 16, right: 16, top: 8),
          child: Text('Scroll or pinch to zoom, drag to pan, double-tap to reset',
              style: TextStyle(color: Color(0xFF93A5B5), fontSize: 12)),
        ),
      ]),
    );
  }
}
