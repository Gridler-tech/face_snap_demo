// Face recognition page — port of the MAUI FaceRecognitionPage: pick two
// photos from the recent captures (Capture page; the store keeps the last few
// captures, so two automatic captures can be compared), choose model/metric/
// threshold and let the server verify whether they are the same person.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../services/photo_store.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  // Selected by identity, not list position: the store's list shifts when a
  // new capture lands or an old one is trimmed.
  CapturedPhoto? _first;
  CapturedPhoto? _second;

  @override
  void initState() {
    super.initState();
    // The page sits const in the nav's IndexedStack, so a page switch does
    // NOT rebuild it — without this listener a fresh capture never appears.
    PhotoStore.revision.addListener(_onPhotosChanged);
  }

  @override
  void dispose() {
    PhotoStore.revision.removeListener(_onPhotosChanged);
    super.dispose();
  }

  void _onPhotosChanged() {
    if (mounted) setState(() {});
  }

  // Reference photos loaded from disk (e.g. a stored passport photo). Kept
  // for the app's lifetime, next to the captured photos.
  final List<CapturedPhoto> _diskPhotos = [];

  Future<void> _loadFromDisk() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Images', extensions: ['jpg', 'jpeg', 'png']),
    ]);
    if (file == null) return; // dialog cancelled
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      final photo = CapturedPhoto(0, -1, bytes, label: file.name);
      _diskPhotos.add(photo);
      // Put it straight into the first free comparison slot.
      if (_first == null) {
        _first = photo;
      } else {
        _second ??= photo;
      }
    });
  }
  Model _model = Model.DLIB;
  DistanceMetric _metric = DistanceMetric.COSINE;
  double _threshold = 0.07; // calibrated default for Dlib + cosine
  bool _busy = false;

  /// Calibrated decision threshold + a sensible slider ceiling per
  /// model/metric combination (deepface's tuned values — the same table the
  /// servers carry in FaceVerifier). Distances live on completely different
  /// scales per combination (Dlib cosine ~0.0-0.2, Facenet512 euclidean
  /// ~0-40), so one fixed slider range would be meaningless.
  static ({double calibrated, double max}) _thresholdSpec(
      Model model, DistanceMetric metric) {
    if (model == Model.DLIB) {
      if (metric == DistanceMetric.COSINE) return (calibrated: 0.07, max: 0.2);
      if (metric == DistanceMetric.EUCLIDEAN) return (calibrated: 0.6, max: 1.2);
      return (calibrated: 0.4, max: 0.8); // euclidean L2
    }
    if (model == Model.FACENET512) {
      if (metric == DistanceMetric.COSINE) return (calibrated: 0.30, max: 0.6);
      if (metric == DistanceMetric.EUCLIDEAN) return (calibrated: 23.56, max: 48);
      return (calibrated: 1.04, max: 2.0);
    }
    // SFace
    if (metric == DistanceMetric.COSINE) return (calibrated: 0.593, max: 1.2);
    if (metric == DistanceMetric.EUCLIDEAN) return (calibrated: 10.73, max: 22);
    return (calibrated: 1.06, max: 2.0);
  }

  /// Model/metric changed: jump the threshold to that combination's
  /// calibrated default (still adjustable afterwards).
  void _applyCalibratedThreshold() {
    _threshold = _thresholdSpec(_model, _metric).calibrated;
  }
  FaceRecognitionResponse? _result;
  String? _message;

  Future<void> _execute() async {
    final first = _first;
    final second = _second;
    if (first == null || second == null) return;
    setState(() {
      _busy = true;
      _result = null;
      _message = null;
    });
    try {
      final client = KioskClient(GrpcChannelProvider.channel);
      final response = await client.faceRecognition(
        FaceRecognitionRequest(
          image1: first.bytes,
          image2: second.bytes,
          threshold: _threshold,
          model: _model,
          similarityMetric: _metric,
        ),
        options: CallOptions(timeout: const Duration(seconds: 120)),
      );
      setState(() => _result = response);
    } catch (e) {
      setState(() => _message = 'Face recognition failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = PhotoStore.photos;
    // A trimmed-away capture invalidates its selection (disk photos live in
    // _diskPhotos and never expire — do NOT clear those).
    bool known(CapturedPhoto? p) =>
        p == null || photos.contains(p) || _diskPhotos.contains(p);
    if (!known(_first)) _first = null;
    if (!known(_second)) _second = null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        SectionCard(
          title: 'Photos to compare',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (photos.isEmpty && _diskPhotos.isEmpty)
              const Text(
                  'No photos yet — run a capture on the Capture page, or load '
                  'a stored photo from this PC below. Photos from the last '
                  '${PhotoStore.keepCaptures} captures stay available.',
                  style: TextStyle(color: T.muted, fontSize: 13))
            else
              Wrap(spacing: 10, runSpacing: 10, children: [
                // Disk photos (reference/passport) first, then the newest
                // capture first.
                for (final photo in _diskPhotos) _photoTile(photo),
                for (final photo in photos.reversed) _photoTile(photo),
              ]),
            const SizedBox(height: 12),
            QuietButton(
              text: 'Load photo from this PC…',
              width: 220,
              onPressed: _busy ? null : _loadFromDisk,
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Model and threshold',
          titleLeading: const DevInfoBadge('face-recognition'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const RowLabel('Model'),
              const SizedBox(width: 10),
              DropdownMenu<Model>(
                initialSelection: _model,
                width: 160,
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: Model.DLIB, label: 'Dlib'),
                  DropdownMenuEntry(
                      value: Model.FACENET512, label: 'Facenet512'),
                  DropdownMenuEntry(value: Model.SFACE, label: 'SFace'),
                ],
                onSelected: (v) => setState(() {
                  _model = v ?? _model;
                  _applyCalibratedThreshold();
                }),
              ),
              const SizedBox(width: 24),
              const RowLabel('Similarity metric'),
              const SizedBox(width: 10),
              DropdownMenu<DistanceMetric>(
                initialSelection: _metric,
                width: 180,
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                      value: DistanceMetric.COSINE, label: 'Cosine'),
                  DropdownMenuEntry(
                      value: DistanceMetric.EUCLIDEAN, label: 'Euclidean'),
                  DropdownMenuEntry(
                      value: DistanceMetric.EUCLIDEAN_L2, label: 'Euclidean L2'),
                ],
                onSelected: (v) => setState(() {
                  _metric = v ?? _metric;
                  _applyCalibratedThreshold();
                }),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              RowLabel('Threshold ${_threshold.toStringAsFixed(2)}'),
              const SizedBox(width: 12),
              Text(
                  'calibrated default '
                  '${_thresholdSpec(_model, _metric).calibrated.toStringAsFixed(2)}',
                  style: const TextStyle(color: T.muted, fontSize: 12)),
            ]),
            Slider(
              value: _threshold.clamp(0.01, _thresholdSpec(_model, _metric).max),
              min: 0.01,
              max: _thresholdSpec(_model, _metric).max,
              divisions: 100,
              onChanged: (v) => setState(() => _threshold = v),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 220,
              child: GoButton(
                text: _busy ? 'Comparing…' : 'Execute',
                onPressed:
                    (_busy || _first == null || _second == null) ? null : _execute,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Result',
          child: _result == null
              ? Text(_message ?? 'No comparison yet.',
                  style: TextStyle(
                      color: _message == null ? T.muted : T.fail, fontSize: 13))
              : _buildResult(_result!),
        ),
      ]),
    );
  }

  Widget _photoTile(CapturedPhoto photo) {
    final selection = _first == photo
        ? 1
        : _second == photo
            ? 2
            : null;
    final source = photo.label ??
        (photo.cameraIndex > 0
            ? 'Capture ${photo.capture} — camera ${photo.cameraIndex}'
            : 'Capture ${photo.capture} — auto');
    return GestureDetector(
      onTap: () => setState(() {
        if (_first == photo) {
          _first = null;
        } else if (_second == photo) {
          _second = null;
        } else if (_first == null) {
          _first = photo;
        } else {
          _second ??= photo;
        }
      }),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: selection == null ? T.line : T.titleBlue,
                  width: selection == null ? 1 : 3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(photo.bytes, height: 170)),
          ),
          if (selection != null)
            Positioned(
              left: 6,
              top: 6,
              child: CircleAvatar(
                  radius: 13,
                  backgroundColor: T.titleBlue,
                  child: Text('$selection',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13))),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(source,
              style: const TextStyle(color: T.muted, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildResult(FaceRecognitionResponse r) {
    final verified = r.verified;
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: verified ? T.passTint : T.failTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(verified ? 'Same person' : 'Different person',
            style: TextStyle(
                color: verified ? T.pass : T.fail,
                fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 18),
      RowLabel('distance ${r.distance.toStringAsFixed(3)} '
          '(threshold ${r.threshold.toStringAsFixed(2)}) · '
          '${r.time.toStringAsFixed(1)} s'),
    ]);
  }
}
