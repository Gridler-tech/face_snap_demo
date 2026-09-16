// Photo page (was "Settings"): the photo-adjustment card (crop, format,
// background erasing, JPEG quality) and the quality-check toggles. The former
// Connection/Server, Kiosk lighting and distance/camera cards moved to the
// Kiosk, Lighting and Camera pages. Every control pushes to the server
// immediately (no save button).
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import '../services/settings_state.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';

class _PhotoFormat {
  const _PhotoFormat(this.code, this.display, this.heightPerWidth);

  final String code;
  final String display;
  final double heightPerWidth;
}

const _photoFormats = [
  _PhotoFormat('icao_35x45', '35 × 45 mm (7:9) — international', 9 / 7),
  _PhotoFormat('us_2x2', '2 × 2 in (1:1) — USA / India', 1),
  _PhotoFormat('ca_50x70', '50 × 70 mm (5:7) — Canada', 7 / 5),
  _PhotoFormat(
      'iso_enrolment', 'Digital enrolment (3:4) — ISO/IEC 29794-5', 4 / 3),
];

const _backgroundMethods = [
  ('none', 'none (keep background)'),
  ('mediapipe', 'MediaPipe (fastest)'),
  ('modnet', 'MODNet (portrait matting)'),
  ('rembg', 'rembg (best quality, slower)'),
];

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final _cropWidth = TextEditingController();
  final _backgroundColor = TextEditingController();

  late bool _crop;
  late String _photoFormat;
  late int _cropHeight;
  late String _backgroundMethod;
  late double _jpegQuality;
  late Map<String, bool> _checks;
  late bool _ofiqChecks;
  String? _message;

  SettingsClient get _client => SettingsState.client;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Settings may be null at boot (app enters the shell before a server is
    // connected); read lazily in build() once one is chosen.
    if (SettingsState.current != null) _readFromState();
  }

  @override
  void dispose() {
    _cropWidth.dispose();
    _backgroundColor.dispose();
    super.dispose();
  }

  void _readFromState() {
    final s = SettingsState.current!;
    _crop = s.crop;
    _photoFormat = s.photoFormat.isEmpty ? 'icao_35x45' : s.photoFormat;
    _cropWidth.text = '${s.cropWidth}';
    _cropHeight = s.cropHeight;
    _backgroundMethod = s.backgroundMethod.isEmpty ? 'none' : s.backgroundMethod;
    _backgroundColor.text = s.backgroundColor;
    _jpegQuality = (s.jpegQuality == 0 ? 95 : s.jpegQuality).toDouble();
    _ofiqChecks = s.ofiqChecks;
    _checks = {
      'Eyes open': s.eyesCheck,
      'Lips closed': s.lipsCheck,
      'Glasses': s.eyeGlassesCheck,
      'Head pose': s.headPoseCheck,
      'Sharpness': s.sharpnessCheck,
      'Red eye': s.redEyeDetectionCheck,
      'Head size/position': s.headSizeCheck,
      'Expression': s.expressionCheck,
      'Gaze': s.gazeCheck,
      'Lighting evenness': s.lightingEvennessCheck,
    };
    _loaded = true;
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    try {
      await action();
      if (mounted) setState(() => _message = null);
    } catch (e) {
      if (mounted) setState(() => _message = 'Server call failed: $e');
    }
  }

  Future<void> _applyCropWidth() async {
    final width = int.tryParse(_cropWidth.text.trim());
    if (width == null || width < 100 || width > 3000) return;
    final format = _photoFormats.firstWhere((f) => f.code == _photoFormat);
    final height = (width * format.heightPerWidth).round();
    if (width == SettingsState.current?.cropWidth && height == _cropHeight) {
      return; // unchanged — skip the redundant push on focus loss
    }
    await _run(() => _client.setCropResolution(
        CropResolutionRequest(width: width, height: height)));
    SettingsState.current?.cropWidth = width;
    setState(() => _cropHeight = height);
  }

  bool get _showBackgroundColor => _backgroundMethod != 'none';

  /// Send the background color to the server (called on Enter AND focus loss).
  /// Invalid hex is not sent — the field shows an error and keeps the text so
  /// the operator can correct it.
  void _pushBackgroundColor() {
    final hex =
        _backgroundColor.text.trim().replaceFirst('#', '').toUpperCase();
    if (hex.length != 6 || int.tryParse(hex, radix: 16) == null) {
      setState(() =>
          _message = 'Background color must be 6 hex digits, e.g. DDDDDD');
      return;
    }
    if (hex == SettingsState.current?.backgroundColor) return; // unchanged
    _backgroundColor.text = hex;
    _run(() async {
      await _client.setBackgroundColor(BackgroundColorRequest(color: hex));
      // Keep the local snapshot in sync so pages re-reading it (and the
      // unchanged-check above) see the new value.
      SettingsState.current?.backgroundColor = hex;
    });
  }

  Color _swatchColor() {
    final hex = _backgroundColor.text.trim().replaceFirst('#', '');
    if (hex.length != 6 || int.tryParse(hex, radix: 16) == null) {
      return Colors.transparent;
    }
    return Color(0xFF000000 | int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (SettingsState.current == null) return const NotConnectedNotice();
    if (!_loaded) _readFromState(); // connected after boot — pick up settings
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        SectionCard(
            title: 'Photo adjustment',
            titleLeading: const DevInfoBadge('photo-adjustment'),
            child: _buildPhotoAdjustment()),
        const SizedBox(height: 14),
        SectionCard(
            title: 'Quality checks',
            titleLeading: const DevInfoBadge('quality-checks'),
            child: _buildChecks()),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, style: const TextStyle(color: T.fail, fontSize: 13)),
        ],
      ]),
    );
  }

  Widget _buildPhotoAdjustment() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Switch(
            value: _crop,
            onChanged: (v) {
              setState(() => _crop = v);
              _run(() => _client.setCrop(CropRequest(value: _crop)));
            }),
        const SizedBox(width: 10),
        const RowLabel('Crop photo'),
      ]),
      const SizedBox(height: 8),
      // Photo format + crop sizes on one line (the layout the user asked for
      // in the MAUI app).
      Row(children: [
        const RowLabel('Photo format'),
        const SizedBox(width: 10),
        DropdownMenu<String>(
          initialSelection: _photoFormat,
          width: 300,
          dropdownMenuEntries: [
            for (final f in _photoFormats)
              DropdownMenuEntry(value: f.code, label: f.display),
          ],
          onSelected: (code) async {
            if (code == null) return;
            setState(() => _photoFormat = code);
            await _run(
                () => _client.setPhotoFormat(PhotoFormatRequest(value: code)));
            await _applyCropWidth();
          },
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 90,
          // Push on focus loss as well as Enter (same trap as the background
          // color field: typed values were lost when clicking elsewhere).
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) _applyCropWidth();
            },
            child: TextField(
              controller: _cropWidth,
              decoration: const InputDecoration(labelText: 'Crop width'),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _applyCropWidth(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 90,
          // InputDecorator, not a TextField: the value is display-only and a
          // controller built inside build() would leak one per rebuild.
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Crop height'),
            child: Text('$_cropHeight'),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      // Background erasing + colour on one line.
      Row(children: [
        const RowLabel('Background erasing'),
        const SizedBox(width: 10),
        DropdownMenu<String>(
          initialSelection: _backgroundMethod,
          width: 280,
          dropdownMenuEntries: [
            for (final (code, display) in _backgroundMethods)
              DropdownMenuEntry(value: code, label: display),
          ],
          onSelected: (code) {
            if (code == null) return;
            setState(() => _backgroundMethod = code);
            _run(() => _client
                .setBackgroundMethod(BackgroundMethodRequest(method: code)));
          },
        ),
        if (_showBackgroundColor) ...[
          const SizedBox(width: 24),
          const RowLabel('Color (hex)'),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            // Push on focus loss as well as Enter: with only onSubmitted the
            // value silently never reached the server when the operator typed
            // a color and clicked elsewhere (field then snapped back to the
            // server's old value on the next settings load).
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) _pushBackgroundColor();
              },
              child: TextField(
                controller: _backgroundColor,
                maxLength: 6,
                decoration: const InputDecoration(
                    counterText: '', hintText: 'FFFFFF'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _pushBackgroundColor(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _swatchColor(),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: T.line),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      RowLabel(
          'JPEG quality ${_jpegQuality.round()} (100 = best, larger files)'),
      Slider(
        value: _jpegQuality,
        min: 50,
        max: 100,
        divisions: 50,
        onChanged: (v) => setState(() => _jpegQuality = v),
        onChangeEnd: (v) => _run(() =>
            _client.setJpegQuality(JpegQualityRequest(value: v.round()))),
      ),
    ]);
  }

  /// Mirror a check-toggle change into the shared settings snapshot.
  void _syncCheckToSnapshot(String label, bool v) {
    final s = SettingsState.current;
    if (s == null) return;
    switch (label) {
      case 'Eyes open':
        s.eyesCheck = v;
      case 'Lips closed':
        s.lipsCheck = v;
      case 'Glasses':
        s.eyeGlassesCheck = v;
      case 'Head pose':
        s.headPoseCheck = v;
      case 'Sharpness':
        s.sharpnessCheck = v;
      case 'Red eye':
        s.redEyeDetectionCheck = v;
      case 'Head size/position':
        s.headSizeCheck = v;
      case 'Expression':
        s.expressionCheck = v;
      case 'Gaze':
        s.gazeCheck = v;
      case 'Lighting evenness':
        s.lightingEvennessCheck = v;
    }
  }

  Widget _buildChecks() {
    final rpcs = <String, Future<dynamic> Function(bool)>{
      'Eyes open': (v) => _client.setEyesCheck(EyesCheckRequest(value: v)),
      'Lips closed': (v) => _client.setLipsCheck(LipsCheckRequest(value: v)),
      'Glasses': (v) =>
          _client.setEyeGlassesCheck(EyeGlassesCheckRequest(value: v)),
      'Head pose': (v) =>
          _client.setHeadPoseCheck(HeadPoseCheckRequest(value: v)),
      'Sharpness': (v) =>
          _client.setSharpnessCheck(SharpnessCheckRequest(value: v)),
      'Red eye': (v) => _client
          .setRedEyeDetectionCheck(RedEyeDetectionCheckRequest(value: v)),
      'Head size/position': (v) =>
          _client.setHeadSizeCheck(HeadSizeCheckRequest(value: v)),
      'Expression': (v) =>
          _client.setExpressionCheck(ExpressionCheckRequest(value: v)),
      'Gaze': (v) => _client.setGazeCheck(GazeCheckRequest(value: v)),
      'Lighting evenness': (v) => _client
          .setLightingEvennessCheck(LightingEvennessCheckRequest(value: v)),
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Engine choice: the kiosk's own checks, or the standardized OFIQ
      // (ISO/IEC 29794-5) report computed on the delivered photo.
      Row(children: [
        Switch(
            value: _ofiqChecks,
            onChanged: (v) {
              setState(() => _ofiqChecks = v);
              // Keep the shared snapshot current: the Capture page seeds its
              // result checklist from it (custom rows vs the OFIQ row).
              SettingsState.current?.ofiqChecks = v;
              _run(() =>
                  _client.setOfiqChecks(OfiqChecksRequest(value: v)));
            }),
        const SizedBox(width: 10),
        const Expanded(
            child: RowLabel(
                'Score with OFIQ (ISO/IEC 29794-5) instead of the checks below')),
      ]),
      if (_ofiqChecks)
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
              'The photo is delivered first; the OFIQ report follows a few '
              'seconds later. Requires OFIQ installed on the server machine.',
              style: TextStyle(color: T.muted, fontSize: 12)),
        ),
      const SizedBox(height: 4),
      // The custom checks stay configurable but are visually muted when the
      // OFIQ report replaces them.
      Opacity(
        opacity: _ofiqChecks ? 0.45 : 1.0,
        child: Wrap(
          spacing: 24,
          runSpacing: 4,
          children: [
            for (final entry in _checks.entries)
              SizedBox(
                width: 250,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Switch(
                      value: entry.value,
                      onChanged: (v) {
                        setState(() => _checks[entry.key] = v);
                        // Keep the shared snapshot current (like the OFIQ
                        // toggle above): the Capture page seeds its result
                        // checklist from it.
                        _syncCheckToSnapshot(entry.key, v);
                        _run(() => rpcs[entry.key]!(v));
                      }),
                  const SizedBox(width: 10),
                  Flexible(child: RowLabel(entry.key)),
                ]),
              ),
          ],
        ),
      ),
    ]);
  }
}
