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
  ('withoutbg', 'withoutBG (best quality, slower)'),
];

/// The retired fourth method. A server from before the withoutBG change still
/// reports it (and does not know 'withoutbg'), so it is listed only while it is
/// the server's current value.
const _legacyRembg = ('rembg', 'rembg (older server)');

/// The dropdown entries for a server whose current method is [current].
List<(String, String)> backgroundMethodEntries(String current) => [
      ..._backgroundMethods,
      if (current == _legacyRembg.$1) _legacyRembg,
    ];

/// What each erasing strength does (shown next to the 1-5 selector).
const _strengthHints = {
  1: 'mildest: soft edges and fine hair kept',
  2: 'mild: softer edges',
  3: 'standard',
  4: 'heavy: cleaner edges',
  5: 'heaviest: cleanest, hardest edges',
};

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> with ServerCallState {
  final _cropWidth = TextEditingController();
  final _backgroundColor = TextEditingController();

  late bool _crop;
  late String _photoFormat;
  late int _cropHeight;
  late String _backgroundMethod;
  late int _backgroundStrength;
  late double _jpegQuality;
  late Map<String, bool> _checks;
  late bool _ofiqChecks;
  late bool _icaoReport;
  // Live person check: the master switch (depth check over the selection scan)
  // and the two optional light checks on top of it.
  late bool _livenessCheck;
  late bool _livenessShading;
  late bool _livenessColour;

  // The snapshot the local fields were read from; re-read when the shared
  // snapshot is replaced (connect after boot, server change).
  LoadSettingsResponse? _source;

  SettingsClient get _client => SettingsState.client;

  @override
  void initState() {
    super.initState();
    // Leave "No server connected" the moment the snapshot lands after a
    // late server start (const IndexedStack pages never rebuild otherwise).
    SettingsState.revision.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    _cropWidth.dispose();
    _backgroundColor.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _readFromState() {
    final s = SettingsState.current!;
    _crop = s.crop;
    _photoFormat = s.photoFormat.isEmpty ? 'icao_35x45' : s.photoFormat;
    _cropWidth.text = '${s.cropWidth}';
    _cropHeight = s.cropHeight;
    _backgroundMethod = s.backgroundMethod.isEmpty ? 'none' : s.backgroundMethod;
    _backgroundColor.text = s.backgroundColor;
    // 0 = a server from before the setting existed; it erases like 3.
    _backgroundStrength = s.backgroundStrength == 0 ? 3 : s.backgroundStrength;
    _jpegQuality = (s.jpegQuality == 0 ? 95 : s.jpegQuality).toDouble();
    _ofiqChecks = s.ofiqChecks;
    _icaoReport = s.icaoReport;
    _livenessCheck = s.livenessCheck;
    _livenessShading = s.livenessShadingCheck;
    _livenessColour = s.livenessColourCheck;
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
    _source = s;
  }

  Future<void> _applyCropWidth() async {
    final width = int.tryParse(_cropWidth.text.trim());
    if (width == null || width < 100 || width > 3000) return;
    final format = _photoFormats.firstWhere((f) => f.code == _photoFormat);
    final height = (width * format.heightPerWidth).round();
    if (width == SettingsState.current?.cropWidth && height == _cropHeight) {
      return; // unchanged — skip the redundant push on focus loss
    }
    await runServerCall(() => _client.setCropResolution(
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
          message = 'Background color must be 6 hex digits, e.g. DDDDDD');
      return;
    }
    if (hex == SettingsState.current?.backgroundColor) return; // unchanged
    _backgroundColor.text = hex;
    runServerCall(() async {
      await _client.setBackgroundColor(BackgroundColorRequest(color: hex));
      // Keep the local snapshot in sync so pages re-reading it (and the
      // unchanged-check above) see the new value.
      SettingsState.current?.backgroundColor = hex;
    });
  }

  /// Send the erasing method; roll the dropdown back when the server refuses (an
  /// older server does not know 'withoutbg'). The server's reply is what was set:
  /// a current server answers 'withoutbg' when asked for the retired 'rembg'.
  Future<void> _setBackgroundMethod(String code) async {
    final before = _backgroundMethod;
    setState(() => _backgroundMethod = code);
    try {
      final r = await _client
          .setBackgroundMethod(BackgroundMethodRequest(method: code));
      final set = r.method.isEmpty ? code : r.method;
      // Keep the shared snapshot in step (pages seed from it).
      SettingsState.current?.backgroundMethod = set;
      if (mounted) {
        setState(() {
          _backgroundMethod = set;
          message = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backgroundMethod = before;
          message = 'Server call failed: ${operatorMessage(e)}';
        });
      }
    }
  }

  /// Send the erasing strength; roll the selector back when the server refuses
  /// (an older server does not know the setting).
  Future<void> _setBackgroundStrength(int level) async {
    final before = _backgroundStrength;
    setState(() => _backgroundStrength = level);
    try {
      final r = await _client
          .setBackgroundStrength(BackgroundStrengthRequest(value: level));
      SettingsState.current?.backgroundStrength = r.message;
      if (mounted) {
        setState(() {
          _backgroundStrength = r.message;
          message = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backgroundStrength = before;
          message = 'Server call failed: ${operatorMessage(e)}';
        });
      }
    }
  }

  Color _swatchColor() => hexToColor(
      _backgroundColor.text.trim().replaceFirst('#', ''),
      fallback: Colors.transparent);

  @override
  Widget build(BuildContext context) {
    if (SettingsState.current == null) return const NotConnectedNotice();
    // Fresh snapshot (connect after boot, server change): pick up its values.
    if (!identical(_source, SettingsState.current)) _readFromState();
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
        ErrorLine(message),
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
              runServerCall(() => _client.setCrop(CropRequest(value: _crop)));
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
            await runServerCall(
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
          // Keyed on the value so a refused change shows the old method again.
          key: ValueKey('background-method-$_backgroundMethod'),
          initialSelection: _backgroundMethod,
          width: 280,
          dropdownMenuEntries: [
            for (final (code, display)
                in backgroundMethodEntries(_backgroundMethod))
              DropdownMenuEntry(value: code, label: display),
          ],
          onSelected: (code) {
            if (code == null || code == _backgroundMethod) return;
            _setBackgroundMethod(code);
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
      if (_showBackgroundColor) ...[
        const SizedBox(height: 12),
        // Erasing strength 1 (mild) - 5 (heavy), for every method.
        Row(children: [
          const RowLabel('Erasing strength'),
          const SizedBox(width: 10),
          const Text('Mild', style: TextStyle(color: T.muted, fontSize: 13)),
          const SizedBox(width: 8),
          SegmentedButton<int>(
            segments: [
              for (var level = 1; level <= 5; level++)
                ButtonSegment(value: level, label: Text('$level')),
            ],
            selected: {_backgroundStrength},
            showSelectedIcon: false,
            onSelectionChanged: (s) => _setBackgroundStrength(s.first),
          ),
          const SizedBox(width: 8),
          const Text('Heavy', style: TextStyle(color: T.muted, fontSize: 13)),
          const SizedBox(width: 16),
          Text(_strengthHints[_backgroundStrength] ?? '',
              style: const TextStyle(color: T.muted, fontSize: 13)),
        ]),
      ],
      const SizedBox(height: 8),
      RowLabel(
          'JPEG quality ${_jpegQuality.round()} (100 = best, larger files)'),
      Slider(
        value: _jpegQuality,
        min: 50,
        max: 100,
        divisions: 50,
        onChanged: (v) => setState(() => _jpegQuality = v),
        onChangeEnd: (v) => runServerCall(() =>
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

  // Built once (not per build): the per-check setter RPCs by display label.
  late final Map<String, Future<dynamic> Function(bool)> _checkRpcs = {
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

  /// The live person check switches. The depth check is part of the master
  /// switch; the light checks only run with it on, so their switches are
  /// disabled without it (the stored values stay, the server keeps them too).
  List<Widget> _livenessRows() {
    void send() {
      final request = LivenessChecksRequest(
          livenessCheck: _livenessCheck,
          shadingCheck: _livenessShading,
          colourCheck: _livenessColour);
      final s = SettingsState.current;
      s?.livenessCheck = _livenessCheck;
      s?.livenessShadingCheck = _livenessShading;
      s?.livenessColourCheck = _livenessColour;
      runServerCall(() => _client.setLivenessChecks(request));
    }

    Widget lightRow(String label, String hint, bool value, void Function(bool) set) {
      return Padding(
        padding: const EdgeInsets.only(left: 28),
        child: Row(children: [
          Switch(
              value: value,
              onChanged: _livenessCheck
                  ? (v) {
                      setState(() => set(v));
                      send();
                    }
                  : null),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RowLabel(label),
            Text(hint, style: const TextStyle(color: T.muted, fontSize: 12)),
          ])),
        ]),
      );
    }

    return [
      Row(children: [
        Switch(
            value: _livenessCheck,
            onChanged: (v) {
              setState(() => _livenessCheck = v);
              send();
            }),
        const SizedBox(width: 10),
        const Expanded(
            child: RowLabel(
                'Live person check (depth measured over the camera scan; informational)')),
      ]),
      lightRow(
          'Shading check: the LEDs above and below the camera light the face in turn',
          'A flat picture, on paper or on a screen, shows no shading change. '
              'Needs the LED board; adds about half a second after the photo.',
          _livenessShading,
          (v) => _livenessShading = v),
      lightRow(
          'Colour check: one yellow flash of the LEDs',
          'Skin follows the colour, a screen does not. Needs the LED board; '
              'adds about half a second after the photo.',
          _livenessColour,
          (v) => _livenessColour = v),
    ];
  }

  Widget _buildChecks() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ICAO compliance report: one verdict per ICAO portrait requirement, from
      // OFIQ plus the kiosk's own checks. Wins over the two engines below.
      Row(children: [
        Switch(
            value: _icaoReport,
            onChanged: (v) {
              setState(() => _icaoReport = v);
              // Keep the shared snapshot current: the Capture page seeds its
              // result checklist from it.
              SettingsState.current?.icaoReport = v;
              runServerCall(() =>
                  _client.setIcaoReport(IcaoReportRequest(value: v)));
            }),
        const SizedBox(width: 10),
        const Expanded(
            child: RowLabel(
                'ICAO compliance report (one verdict per ICAO requirement)')),
      ]),
      if (_icaoReport)
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
              'The photo is delivered first; the report follows a few seconds '
              'later. It combines OFIQ (ISO/IEC 29794-5) with the kiosk\'s own '
              'checks for glasses, gaze, red eyes, shadows and head size, and '
              'replaces the OFIQ report and the checks below. Requires OFIQ '
              'installed on the server machine.',
              style: TextStyle(color: T.muted, fontSize: 12)),
        ),
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
              runServerCall(() =>
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
      ..._livenessRows(),
      const SizedBox(height: 4),
      // The custom checks stay configurable but are visually muted when the
      // OFIQ or ICAO report replaces them.
      Opacity(
        opacity: _ofiqChecks || _icaoReport ? 0.45 : 1.0,
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
                        runServerCall(() => _checkRpcs[entry.key]!(v));
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
