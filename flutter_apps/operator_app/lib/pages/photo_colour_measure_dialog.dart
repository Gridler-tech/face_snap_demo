// The Photo colour measurement (spec 2026-10-13 section 4.1, ruling R1; "Measure
// manually" of spec 2026-11-02 sections 2 and 4.6): the photos of a manual
// capture taken with the correction off, the middle camera's first (a dropdown
// switches), the operator taps the centres of the card's four corner patches
// (the SpyderCheckr 24 or the ColorChecker Classic of the app's preferences) on
// the zoomable photo, and the app reads the chart, fits the matrix
// (lib/util/colour_fit.dart) and shows before -> after with Save / Discard. A
// refused reading shows its reason and no Save; a fit that would not improve the
// colours offers only Discard. The measurement is recorded with `method: "taps"`.
// Nothing is sent from here: the card saves what the dialog returns.
//
// With [PhotoColourMeasureDialog.tapsOnly] it is Calibrate's taps fallback
// (ruling R16): one photo, and the 24 patches read from the taps are returned
// ([PhotoColourTaps]); the run fits them.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/settings_state.dart';
import '../ui/ui.dart';
import '../util/card_reference.dart';
import '../util/colour_fit.dart';

/// The three corrected lights (the servers' light keys) and their labels, in the order
/// of LoadSettings' colour_corrections.
const colourLights = <(String, String)>[
  ('all', 'Standard light (all LEDs)'),
  ('neighbours', 'Standard light (neighbours)'),
  ('glare_free', 'Glare-free light'),
];

/// The label of a light key ([colourLights]); the key itself for an unknown one.
String colourLightLabel(String light) =>
    colourLights.firstWhere((l) => l.$1 == light, orElse: () => (light, light)).$2;

/// A decoded photo: tightly packed RGBA, [width] x [height] (as
/// `ui.Image.toByteData(rawRgba)` gives).
class DecodedImage {
  const DecodedImage(this.rgba, this.width, this.height);

  final Uint8List rgba;
  final int width;
  final int height;
}

/// Decodes a JPEG (or any format the engine reads) to RGBA.
Future<DecodedImage> decodeJpeg(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw StateError('the photo could not be decoded');
      return DecodedImage(data.buffer.asUint8List(), image.width, image.height);
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

/// What Save returns: the matrix (9 numbers, row-major, RGB, linear light) and the
/// measurement record SetColourCorrection stores with it.
class PhotoColourResult {
  PhotoColourResult({required this.matrix, required this.measurement, required this.fit});

  final List<double> matrix;
  final ColourMeasurement measurement;
  final ColourFit fit;
}

/// What the taps fallback returns: the 24 patches read from the taps and their
/// centres in the photo's pixels (the reference's order).
class PhotoColourTaps {
  PhotoColourTaps({required this.sample, required this.centres});

  final PatchSample sample;
  final List<Offset> centres;
}

/// The fit of a chart's patches against [reference] with the skin guard
/// ([fitColourMatrixGuarded]: skin weight 3, then 6, 12, 24, 48), a patch with a clipped
/// channel left out of the fit and the score (as cc_probe); a fit that cannot be solved,
/// would not improve the weighted score or would make a skin patch worse is refused.
({ColourFit? fit, String? refusal}) fitPatches(PatchSample sample, CardReference reference) {
  try {
    final fit = fitColourMatrixGuarded(sample.means, [for (final c in sample.clipped) !c], reference: reference);
    final refusal = colourFitRefusal(fit, reference: reference);
    return (fit: refusal == null ? fit : null, refusal: refusal);
  } on ArgumentError {
    return (fit: null, refusal: refusalNoImprovement);
  }
}

/// The middle camera's photo: calibrated index (count + 1) ~/ 2 of the photos received;
/// the first photo when that camera sent none.
CameraPhoto middlePhoto(List<CameraPhoto> photos) {
  final middle = (photos.length + 1) ~/ 2;
  return photos.firstWhere((p) => p.cameraIndex == middle, orElse: () => photos.first);
}

class PhotoColourMeasureDialog extends StatefulWidget {
  const PhotoColourMeasureDialog({
    super.key,
    required this.photos,
    required this.light,
    this.decode = decodeJpeg,
    this.reference,
    this.loadReference = loadChosenCardReference,
    this.tapsOnly = false,
    this.title,
  });

  /// The manual capture's photos, one per camera (not empty).
  final List<CameraPhoto> photos;

  /// The light measured: all, neighbours or glare_free.
  final String light;

  /// Photo bytes -> RGBA (tests pass a synthetic chart).
  final Future<DecodedImage> Function(Uint8List) decode;

  /// The card's reference; null = [loadReference] of the card and version in the
  /// app's preferences.
  final CardReference? reference;

  /// Reads the chosen card's reference (tests read the files).
  final CardReferenceLoader loadReference;

  /// The taps fallback of Calibrate: the patches read are returned, no fit.
  final bool tapsOnly;

  /// The heading; null = "Photo colour · " and the light.
  final String? title;

  @override
  State<PhotoColourMeasureDialog> createState() => _PhotoColourMeasureDialogState();
}

class _PhotoColourMeasureDialogState extends State<PhotoColourMeasureDialog> {
  /// One photo per camera (the last one of a camera that sent two).
  late final List<CameraPhoto> _photos;
  late CameraPhoto _photo;
  DecodedImage? _image;
  String? _decodeError;
  int _decodeToken = 0;

  /// The card's reference, read before the first photo is shown.
  CardReference? _reference;

  /// The taps, in image pixels.
  final List<Offset> _taps = [];
  ChartReading? _reading;
  ColourFit? _fit;
  String? _refusal;
  final TransformationController _zoom = TransformationController();

  @override
  void initState() {
    super.initState();
    final byCamera = <int, CameraPhoto>{for (final p in widget.photos) p.cameraIndex: p};
    _photos = byCamera.values.toList()..sort((a, b) => a.cameraIndex.compareTo(b.cameraIndex));
    _photo = middlePhoto(_photos);
    _load();
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _clearTaps() {
    _taps.clear();
    _reading = null;
    _fit = null;
    _refusal = null;
  }

  Future<void> _load() async {
    final token = ++_decodeToken;
    try {
      _reference ??=
          widget.reference ?? await widget.loadReference(AppConfig.colourCard, AppConfig.colourCardVersion);
    } catch (e) {
      if (!mounted || token != _decodeToken) return;
      setState(() => _decodeError = 'The card reference could not be read: $e');
      return;
    }
    try {
      final image = await widget.decode(_photo.bytes);
      if (!mounted || token != _decodeToken) return;
      setState(() => _image = image);
    } catch (e) {
      if (!mounted || token != _decodeToken) return;
      setState(() => _decodeError = 'The photo could not be read: $e');
    }
  }

  void _choose(int? camera) {
    if (camera == null || camera == _photo.cameraIndex) return;
    setState(() {
      _photo = _photos.firstWhere((p) => p.cameraIndex == camera);
      _image = null;
      _decodeError = null;
      _zoom.value = Matrix4.identity();
      _clearTaps();
    });
    _load();
  }

  void _onTap(TapUpDetails details, Size box, DecodedImage image) {
    if (_taps.length >= 4) return;
    final scene = _zoom.toScene(details.localPosition);
    if (scene.dx < 0 || scene.dy < 0 || scene.dx > box.width || scene.dy > box.height) return;
    setState(() {
      _taps.add(Offset(scene.dx * image.width / box.width, scene.dy * image.height / box.height));
      if (_taps.length == 4) _evaluate(image);
    });
  }

  void _evaluate(DecodedImage image) {
    final reference = _reference!;
    final reading = readChart(image.rgba, image.width, image.height, _taps, reference: reference);
    _reading = reading;
    if (reading.refusal != null || reading.sample == null) {
      _refusal = reading.refusal ?? refusalTaps;
      return;
    }
    if (widget.tapsOnly) return;
    final outcome = fitPatches(reading.sample!, reference);
    _fit = outcome.fit;
    _refusal = outcome.refusal;
  }

  void _undo() {
    if (_taps.isEmpty) return;
    setState(() {
      _taps.removeLast();
      _reading = null;
      _fit = null;
      _refusal = null;
    });
  }

  /// The taps fallback's answer: the patches read.
  bool get _tapsRead => widget.tapsOnly && _refusal == null && _reading?.sample != null;

  void _useTaps() {
    final reading = _reading;
    if (!_tapsRead || reading == null) return;
    Navigator.of(context).pop(PhotoColourTaps(sample: reading.sample!, centres: reading.centres));
  }

  void _save() {
    final fit = _fit;
    if (fit == null) return;
    final reference = _reference!;
    // spec 5: the mix (and for the glare-free light the white balance) the kiosk
    // took the photo with, as the settings snapshot has them
    final s = SettingsState.current;
    Navigator.of(context).pop(PhotoColourResult(
      matrix: List.unmodifiable(fit.matrix),
      measurement: ColourMeasurement(
        measured: measuredAt(DateTime.now()),
        camera: _photo.cameraIndex,
        chart: reference.card,
        meanDeBefore: fit.meanDeBefore,
        meanDeAfter: fit.meanDeAfter,
        method: 'taps',
        ledRed: s?.intensityRed ?? 0,
        ledGreen: s?.intensityGreen ?? 0,
        ledBlue: s?.intensityBlue ?? 0,
        scoreAfter: fit.scoreAfter,
        whiteBalance: widget.light == 'glare_free' ? s?.glareFreeWhiteBalance ?? 0 : 0,
        cardVersion: reference.card == 'classic' ? reference.version : '',
      ),
      fit: fit,
    ));
  }

  static String _f1(double v) => v.toStringAsFixed(1);

  Widget _photoView() {
    final error = _decodeError;
    if (error != null) {
      return Center(child: Text(error, style: const TextStyle(color: T.fail, fontSize: 13.5)));
    }
    final image = _image;
    if (image == null) return const Center(child: CircularProgressIndicator());
    return LayoutBuilder(builder: (context, constraints) {
      final box = applyBoxFit(BoxFit.contain,
              Size(image.width.toDouble(), image.height.toDouble()), constraints.biggest)
          .destination;
      final scale = box.width / image.width; // box pixels per image pixel
      return Center(
        child: SizedBox.fromSize(
          size: box,
          child: ClipRect(
            child: GestureDetector(
              key: const ValueKey('photo-colour-photo'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _onTap(details, box, image),
              child: InteractiveViewer(
                transformationController: _zoom,
                maxScale: 8,
                child: Stack(fit: StackFit.expand, children: [
                  Image.memory(_photo.bytes,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stack) =>
                          const ColoredBox(color: Color(0xFF101C26))),
                  CustomPaint(
                    painter: _TapPainter(
                      taps: [for (final t in _taps) t * scale],
                      centres: [for (final c in _reading?.centres ?? const <Offset>[]) c * scale],
                      refused: _refusal != null,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _result() {
    final refusal = _refusal;
    if (refusal != null) {
      return Text(refusal, style: const TextStyle(color: T.fail, fontSize: 14));
    }
    if (_tapsRead) {
      return const Text('The 24 patches are read.', style: TextStyle(color: T.ink, fontSize: 14));
    }
    final fit = _fit;
    if (fit == null) return const SizedBox.shrink();
    final reference = _reference!;
    String skin(String id) {
      final k = reference.indexOf(id);
      return '${reference.names[k]} ($id) ${_f1(fit.deBefore[k])} → ${_f1(fit.deAfter[k])}';
    }

    const muted = TextStyle(color: T.muted, fontSize: 12.5);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          'Mean ΔE ${_f1(fit.meanDeBefore)} → ${_f1(fit.meanDeAfter)} · '
          'worst ${_f1(fit.worstBefore)} → ${_f1(fit.worstAfter)}',
          style: const TextStyle(color: T.ink, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Skin ΔE: ${reference.skin.map(skin).join(' · ')}', style: muted),
      Text(
          'Grey row a*/b* after: ${[
            for (final k in reference.greyIndexes)
              '${reference.ids[k]} ${_f1(fit.labAfter[k][1])}/${_f1(fit.labAfter[k][2])}'
          ].join(' · ')}',
          style: muted),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final fit = _fit;
    // refused after the fit (the taps were right): nothing to undo, only Discard
    final noImprovement = _refusal == refusalNoImprovement || _refusal == refusalSkinWorse;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: math.min(1100, screen.width - 48),
        height: math.min(860, screen.height - 48),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text(widget.title ?? 'Photo colour · ${colourLightLabel(widget.light)}',
                    style: const TextStyle(
                        color: T.titleBlue, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const RowLabel('Photo of'),
              const SizedBox(width: 10),
              DropdownButton<int>(
                key: const ValueKey('photo-colour-camera'),
                value: _photo.cameraIndex,
                items: [
                  for (final p in _photos)
                    DropdownMenuItem(value: p.cameraIndex, child: Text('Camera ${p.cameraIndex}')),
                ],
                onChanged: _choose,
              ),
            ]),
            const SizedBox(height: 4),
            Text(
                'Tap the four corner patches (or the card\'s four corners), in any order: '
                '${_taps.length} of 4. Scroll or pinch to zoom.',
                style: const TextStyle(color: T.muted, fontSize: 12.5)),
            const SizedBox(height: 8),
            Expanded(child: _photoView()),
            const SizedBox(height: 10),
            _result(),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (!noImprovement) ...[
                QuietButton(text: 'Undo tap', width: 130, onPressed: _taps.isEmpty ? null : _undo),
                const SizedBox(width: 10),
              ],
              QuietButton(
                  text: widget.tapsOnly ? 'Cancel' : 'Discard',
                  width: 130,
                  onPressed: () => Navigator.of(context).pop()),
              if (_tapsRead) ...[
                const SizedBox(width: 10),
                SizedBox(width: 180, child: GoButton(text: 'Use the taps', onPressed: _useTaps)),
              ],
              if (fit != null) ...[
                const SizedBox(width: 10),
                SizedBox(width: 160, child: GoButton(text: 'Save', onPressed: _save)),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}

/// The taps as small rings and, once read, the 24 patch centres as dots.
class _TapPainter extends CustomPainter {
  _TapPainter({required this.taps, required this.centres, required this.refused});

  final List<Offset> taps;
  final List<Offset> centres;
  final bool refused;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()
      ..color = const Color(0xCC000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final light = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final t in taps) {
      canvas.drawCircle(t, 8, dark);
      canvas.drawCircle(t, 8, light);
    }
    final dot = Paint()..color = refused ? T.warn : T.goGreen;
    for (final c in centres) {
      canvas.drawCircle(c, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_TapPainter old) =>
      old.taps != taps || old.centres != centres || old.refused != refused;
}
