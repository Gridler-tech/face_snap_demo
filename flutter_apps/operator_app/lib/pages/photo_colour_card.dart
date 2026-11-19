// The Calibration page's "Photo colour" card (spec 2026-10-13 section 4.1; spec
// 2026-11-02 sections 2 and 6): per light (all LEDs, neighbours, glare-free) the
// matrix in force - "shipped" or this kiosk's own with its date and mean ΔE
// before -> after - from LoadSettings. Calibrate (offered when the server has the
// card finder: the R2 probe of MeasureColourCard) opens the calibration dialog.
// Under "Measure manually" (the only way on an older server): the card of the
// app's preferences, and per light Measure runs a manual capture with that light
// and the correction off and opens the measurement dialog, Save stores the fit
// with SetColourCorrection, Back to shipped clears this kiosk's matrix. A server
// without the feature (no colour_corrections in LoadSettings, or an
// UNIMPLEMENTED answer) shows "Not available on this server".
// SetColourCorrection is a column setter: the column profile is read again after it.
import 'dart:typed_data';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/colour_calibration.dart' show ColourCardAvailability, colourCardAvailable;
import '../services/column_state.dart';
import '../services/settings_state.dart';
import '../ui/column_mark.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';
import '../util/card_reference.dart';
import 'colour_calibrate_dialog.dart';
import 'photo_colour_measure_dialog.dart';

/// gRPC status codes (the grpc package is only a dev dependency of the app).
const _invalidArgument = 3;
const _unimplemented = 12;

/// What the operator does before Measure (and in the dialog after it), with [cardName].
String photoColourHelp(String cardName) =>
    'Hold the $cardName at face height, flat to the middle camera, fingers off the '
    'patches. Then tap the centres of the four corner patches.';

/// The capture's settings used report the correction on: the photo would not be the
/// camera's own colours.
const colourMeasurementCorrected =
    'this kiosk could not switch the correction off for the measurement';

/// The kiosk takes its photos with the LEDs off: the light asked for is not the photo's.
const colourMeasurementLedsOff =
    'this kiosk takes its photos with the LEDs off: switch "Lights off for the photo" off '
    'on the Lighting page to measure';

const colourNotAvailable = 'Not available on this server';

/// The manual capture's settings for measuring [light]: never corrected; the glare-free
/// light through "everyone", the others as the photo light with the glare-free light off.
CaptureSettings colourMeasurementSettings(String light) => light == 'glare_free'
    ? CaptureSettings(colourCorrection: false, glareFreeLight: 'everyone')
    : CaptureSettings(colourCorrection: false, photoLight: light, glareFreeLight: 'off');

/// A light's status line: "shipped", or "this kiosk · `yyyy-MM-dd` · ΔE `before` → `after`"
/// (one decimal).
String colourStatusText(ColourCorrectionState? state) {
  if (state == null || state.source != 'kiosk') return 'shipped';
  if (!state.hasMeasurement()) return 'this kiosk';
  final m = state.measurement;
  final time = DateTime.tryParse(m.measured)?.toUtc();
  final date = time == null
      ? m.measured
      : '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-'
          '${time.day.toString().padLeft(2, '0')}';
  return 'this kiosk · $date · ΔE ${m.meanDeBefore.toStringAsFixed(1)} → '
      '${m.meanDeAfter.toStringAsFixed(1)}';
}

class PhotoColourCard extends StatefulWidget {
  const PhotoColourCard({
    super.key,
    this.decode = decodeJpeg,
    this.onMeasured,
    this.loadReference = loadChosenCardReference,
  });

  /// Photo bytes -> RGBA, handed to the dialogs (tests pass a synthetic chart).
  final Future<DecodedImage> Function(Uint8List) decode;

  /// Reads the chosen card's reference, handed to the dialogs (tests read the files).
  final CardReferenceLoader loadReference;

  /// Called when the measurement dialog closes with a result, just before it is saved
  /// (the Calibration page shows this card again if another tile is shown meanwhile).
  final VoidCallback? onMeasured;

  @override
  State<PhotoColourCard> createState() => _PhotoColourCardState();
}

class _PhotoColourCardState extends State<PhotoColourCard> {
  /// The light being measured or saved; null when idle.
  String? _busy;
  String? _progress;
  String? _message;

  /// The server this card found without the feature (an UNIMPLEMENTED answer).
  String? _unavailableFor;

  /// The server the R2 probe was sent to, and whether it offers Calibrate.
  String? _probedFor;
  bool _calibrate = false;

  @override
  void initState() {
    super.initState();
    SettingsState.revision.addListener(_onSettings);
    _probe();
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    if (!mounted) return;
    setState(() {});
    _probe();
  }

  /// Calibrate is offered when the server answers the probe with the light refusal
  /// (R2); an older server, or one without the card finder, gets Measure manually only.
  /// A probe that failed (a timeout, the kiosk unreachable) decided nothing: the next
  /// settings change ([SettingsState.revision]) probes the server again.
  void _probe() {
    final server = SettingsState.serverKey;
    if (!_available || _probedFor == server) return;
    _probedFor = server;
    _calibrate = false;
    final kiosk = KioskClient(GrpcChannelProvider.channel,
        options: CallOptions(timeout: const Duration(seconds: 10)));
    colourCardAvailable(kiosk).then((availability) {
      if (!mounted || _probedFor != server) return;
      switch (availability) {
        case ColourCardAvailability.available:
          setState(() => _calibrate = true);
        case ColourCardAvailability.unavailable:
          break;
        case ColourCardAvailability.unknown:
          _probedFor = null;
      }
    });
  }

  bool get _available {
    final s = SettingsState.current;
    return s != null &&
        s.colourCorrections.isNotEmpty &&
        _unavailableFor != SettingsState.serverKey;
  }

  ColourCorrectionState? _state(String light) {
    for (final s in SettingsState.current?.colourCorrections ?? const <ColourCorrectionState>[]) {
      if (s.light == light) return s;
    }
    return null;
  }

  /// The server's answer into the shared snapshot.
  void _store(ColourCorrectionState state) {
    final states = SettingsState.current?.colourCorrections;
    if (states == null) return;
    final i = states.indexWhere((s) => s.light == state.light);
    if (i >= 0) {
      states[i] = state;
    } else {
      states.add(state);
    }
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      if (e is GrpcError && e.code == _unimplemented) {
        _unavailableFor = SettingsState.serverKey;
        _message = null;
      } else if (e is GrpcError && e.code == _invalidArgument && (e.message ?? '').isNotEmpty) {
        _message = 'Not saved: ${e.message}';
      } else {
        _message = 'Server call failed: ${operatorMessage(e)}';
      }
    });
  }

  Future<void> _send(ColourCorrectionRequest request) async {
    setState(() {
      _busy = request.light;
      _progress = 'Saving…';
      _message = null;
    });
    try {
      final response = await SettingsState.client.setColourCorrection(request);
      _store(response.state);
      ColumnState.touch();
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _backToShipped(String light) =>
      _send(ColourCorrectionRequest(light: light, clear_4: true));

  Future<void> _measure(String light) async {
    setState(() {
      _busy = light;
      _progress = 'Taking a photo with every camera (about 15-20 s)…';
      _message = null;
    });
    final photos = <CameraPhoto>[];
    String? refusal;
    try {
      await for (final event in startManualCapture(settings: colourMeasurementSettings(light))) {
        switch (event) {
          case CaptureSettingsReport(:final values):
            if (values.hasColourCorrection() && values.colourCorrection) {
              refusal = colourMeasurementCorrected;
            } else if (values.hasLedsOffForPhoto() && values.ledsOffForPhoto) {
              refusal = colourMeasurementLedsOff;
            }
          case CameraPhoto():
            photos.add(event);
            if (mounted) setState(() => _progress = 'Photo ${photos.length} received…');
          default:
            break;
        }
        // Stops the capture: its photos could not measure this light.
        if (refusal != null) break;
      }
    } on PerCaptureSettingsNotSupported {
      if (mounted) setState(() => _unavailableFor = SettingsState.serverKey);
      return;
    } catch (e) {
      if (mounted) setState(() => _message = 'Capture failed: ${operatorMessage(e)}');
      return;
    } finally {
      if (mounted) setState(() => _busy = null);
    }
    if (!mounted) return;
    if (refusal != null || photos.isEmpty) {
      setState(() => _message = refusal ?? 'The capture ended without a photo.');
      return;
    }
    final result = await showDialog<PhotoColourResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PhotoColourMeasureDialog(
          photos: photos, light: light, decode: widget.decode, loadReference: widget.loadReference),
    );
    if (result == null || !mounted) return; // Discard: nothing is stored
    widget.onMeasured?.call();
    await _send(ColourCorrectionRequest(
        light: light, matrix: result.matrix, measurement: result.measurement));
  }

  Future<void> _openCalibrate() async {
    setState(() => _message = null);
    final stored = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ColourCalibrateDialog(decode: widget.decode, loadReference: widget.loadReference),
    );
    if (!mounted) return;
    if (stored != null) widget.onMeasured?.call();
    setState(() {}); // the card choice and the rows (the dialog updated the snapshot)
  }

  Widget _row(String light, String label) {
    final state = _state(light);
    final idle = _busy == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 240, child: RowLabel(label)),
        Expanded(
          child: Text(colourStatusText(state),
              style: const TextStyle(color: T.muted, fontSize: 13)),
        ),
        QuietButton(text: 'Measure', width: 120, onPressed: idle ? () => _measure(light) : null),
        if (state?.source == 'kiosk') ...[
          const SizedBox(width: 10),
          QuietButton(
              text: 'Back to shipped',
              width: 170,
              onPressed: idle ? () => _backToShipped(light) : null),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = _available;
    return SectionCard(
      title: 'Photo colour',
      titleLeading: const DevInfoBadge('photo-colour'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Every photo\'s colours are corrected with a matrix per light: the one shipped for '
          'this LED hardware, or this kiosk\'s own, measured here with a SpyderCheckr 24 or a '
          'ColorChecker Classic. Calibrate tunes the LED colour and the glare-free white balance '
          'on the card held in front of the middle camera and measures each light; Measure takes '
          'a photo with every camera (about 15-20 s) with the correction off. The switch for the '
          'whole kiosk is on the Lighting page.',
          style: TextStyle(color: T.muted, fontSize: 12.5, height: 1.45),
        ),
        const SizedBox(height: 10),
        if (!available)
          const Text(colourNotAvailable, style: TextStyle(color: T.ink, fontSize: 13.5))
        else ...[
          if (_calibrate) ...[
            SizedBox(
                width: 200,
                child: GoButton(text: 'Calibrate', onPressed: _busy == null ? _openCalibrate : null)),
            const SizedBox(height: 14),
          ],
          const Text('Measure manually',
              style: TextStyle(color: T.ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ColourCardChoice(enabled: _busy == null, onChanged: () => setState(() {})),
          const SizedBox(height: 4),
          Text(photoColourHelp(colourCardNames[AppConfig.colourCard] ?? AppConfig.colourCard),
              style: const TextStyle(color: T.ink, fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 8),
          for (final (light, label) in colourLights) _row(light, label),
          if (_busy != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
              const SizedBox(width: 10),
              Expanded(child: RowLabel(_progress ?? '')),
            ]),
          ],
        ],
        // Calibrate's Save writes the LED colour and the glare-free white balance too.
        const ColumnChangedMark(['colour_correction', 'led_colour', 'glare_free_white_balance']),
        ErrorLine(_message),
      ]),
    );
  }
}
