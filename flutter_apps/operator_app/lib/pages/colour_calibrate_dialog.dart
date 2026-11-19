// Calibrate on the Photo colour card (spec 2026-11-02 sections 2 and 5; plan
// Task 13): the dialog that runs the colour calibration of
// lib/services/colour_calibration.dart. Setup: the card (and the Classic's
// version, kept in the app's preferences), the lights (Standard (all LEDs)
// always on; neighbours pre-ticked when the kiosk's photo light is
// `neighbours`, Glare-free when its glare-free light is on), the hold-the-card
// text and Start, disabled while the column's lights are off. Running: a
// progress bar naming the step, the hold-still message of a lost card, Cancel;
// three lost attempts open the four taps on the last photo (the measurement
// dialog on that one photo). Result: the LED mix old -> new with the brightness
// change, the glare-free white balance old -> new with the residual a*, per light ΔE before -> after,
// skin, worst patch and score (and the lights skipped, with why), the last
// photo with its 24 points; Save / Discard. Saving: a failed write names itself
// and what was already stored, and Retry goes on from it. Nothing is written
// before Save.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:face_snap_grpc/face_snap_grpc.dart' hide LedMix;
import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../services/colour_calibration.dart';
import '../services/column_state.dart';
import '../services/settings_state.dart';
import '../ui/ui.dart';
import '../util/card_reference.dart';
import '../util/led_mix_search.dart';
import 'lighting_page.dart' show glareFreeLightOf;
import 'photo_colour_measure_dialog.dart';

/// The cards and the Classic's versions as the operator reads them (spec 2 step 1).
const colourCardNames = {'spyder24': 'SpyderCheckr 24', 'classic': 'ColorChecker Classic'};
const classicVersionNames = {'pre2014': 'before November 2014', '2014': 'November 2014 or later'};

/// Review Focus 1: the server would measure a dark card.
const calibrateLightsOff = "The column's lights are off (Lighting page): switch them on to calibrate";

/// Spec 2 step 3.
const calibrateHoldCard = 'Hold the card at face height on the subject marking, flat to the middle camera, '
    'fingers off the patches, then press Start.';

/// A result in which no setting would change.
const nothingToSave = 'Nothing to save: this run would change no setting.';

/// The card (and the Classic's version) of the app's preferences, as two dropdowns;
/// a change is saved at once and reported to [onChanged].
class ColourCardChoice extends StatefulWidget {
  const ColourCardChoice({super.key, this.onChanged, this.enabled = true});

  final VoidCallback? onChanged;
  final bool enabled;

  @override
  State<ColourCardChoice> createState() => _ColourCardChoiceState();
}

class _ColourCardChoiceState extends State<ColourCardChoice> {
  void _set(void Function() change) {
    setState(change);
    unawaited(AppConfig.save().catchError((Object _) {}));
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final card = AppConfig.colourCard;
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 4, children: [
      const RowLabel('Card'),
      DropdownButton<String>(
        key: const ValueKey('colour-card'),
        value: card,
        items: [
          for (final c in kCards) DropdownMenuItem(value: c, child: Text(colourCardNames[c]!)),
        ],
        onChanged: widget.enabled ? (c) => c == null ? null : _set(() => AppConfig.colourCard = c) : null,
      ),
      if (card == 'classic') ...[
        const SizedBox(width: 10),
        const RowLabel('Made'),
        DropdownButton<String>(
          key: const ValueKey('colour-card-version'),
          value: AppConfig.colourCardVersion,
          items: [
            for (final v in kClassicVersions) DropdownMenuItem(value: v, child: Text(classicVersionNames[v]!)),
          ],
          onChanged:
              widget.enabled ? (v) => v == null ? null : _set(() => AppConfig.colourCardVersion = v) : null,
        ),
      ],
    ]);
  }
}

enum _Phase { setup, running, stopped, result, saving, saveFailed }

/// Pops true when Save stored everything, false when a failed Save stored a part,
/// null when nothing was stored.
class ColourCalibrateDialog extends StatefulWidget {
  const ColourCalibrateDialog({
    super.key,
    this.decode = decodeJpeg,
    this.loadReference = loadChosenCardReference,
  });

  /// Photo bytes -> RGBA: the result's photo and the taps (tests pass a synthetic chart).
  final Future<DecodedImage> Function(Uint8List) decode;

  /// Reads the chosen card's reference (tests read the files).
  final CardReferenceLoader loadReference;

  @override
  State<ColourCalibrateDialog> createState() => _ColourCalibrateDialogState();
}

class _ColourCalibrateDialogState extends State<ColourCalibrateDialog> {
  _Phase _phase = _Phase.setup;
  late bool _neighbours, _glareFree;

  /// The camera's Automatic exposure as read when the dialog opened (null: not read
  /// yet or not readable: no warning). Off = the card photos use the fixed exposure.
  bool? _exposureAuto;

  /// The run of the last Start (a new one per Start; a stale one's end is ignored).
  ColourCalibration? _run;
  bool _cancelling = false;
  String _step = stepFindCard;
  List<String> _steps = const [stepFindCard, stepLedMix, stepCorrection];
  String? _status;
  String? _error;

  /// What the kiosk had in force at Start (Save writes only what differs).
  LedMix _kioskMix = const LedMix(0, 0, 0);
  int _kioskWhiteBalance = 0;

  CardReference? _reference;
  CalibrationOutcome? _outcome;
  Future<DecodedImage>? _lastImage;
  SaveReport? _report;

  @override
  void initState() {
    super.initState();
    final s = SettingsState.current;
    _neighbours = s?.photoLight == 'neighbours';
    _glareFree = s != null && glareFreeLightOf(s) != GlareFreeLight.GLARE_FREE_LIGHT_OFF;
    unawaited(_readExposure());
  }

  /// A warning only: a camera that cannot be read shows none and Start stays open.
  Future<void> _readExposure() async {
    try {
      final camera = await CameraClient(GrpcChannelProvider.channel)
          .loadSettings(Empty(), options: CallOptions(timeout: const Duration(seconds: 10)));
      if (mounted) setState(() => _exposureAuto = camera.exposureAutoPriority);
    } catch (_) {}
  }

  /// The dialog gone mid-run (closed, the page left): no further photo.
  @override
  void dispose() {
    _run?.cancel();
    super.dispose();
  }

  bool get _lightsOn => SettingsState.current?.lighting ?? false;

  Future<void> _start() async {
    final s = SettingsState.current;
    // A second tap before the dialog rebuilt starts no second run.
    if (s == null || !s.lighting || _phase == _Phase.running) return;
    final run = ColourCalibration(measure: _measure, taps: _taps, progress: _progress);
    final neighbours = _neighbours, glareFree = _glareFree;
    _run?.cancel();
    _run = run;
    _kioskMix = LedMix(s.intensityRed, s.intensityGreen, s.intensityBlue);
    _kioskWhiteBalance = s.glareFreeWhiteBalance;
    setState(() {
      _phase = _Phase.running;
      _cancelling = false;
      _step = stepFindCard;
      _steps = [stepFindCard, stepLedMix, if (glareFree) stepTint, stepCorrection];
      _status = null;
      _error = null;
    });
    try {
      final reference = await widget.loadReference(AppConfig.colourCard, AppConfig.colourCardVersion);
      // R19: an automatic white balance is ignored by both servers: no tint step.
      var auto = false;
      if (glareFree) {
        final camera = await CameraClient(GrpcChannelProvider.channel)
            .loadSettings(Empty(), options: CallOptions(timeout: const Duration(seconds: 10)));
        auto = camera.whiteBalanceTemperatureAuto;
        if (auto && mounted && run == _run) setState(() => _steps = [stepFindCard, stepLedMix, stepCorrection]);
      }
      final outcome = await run.run(CalibrationPlan(
        reference: reference,
        neighbours: neighbours,
        glareFree: glareFree,
        kioskMix: _kioskMix,
        kioskWhiteBalance: _kioskWhiteBalance,
        autoWhiteBalance: auto,
      ));
      if (!mounted || run != _run) return;
      setState(() {
        _reference = reference;
        _outcome = outcome;
        _report = null;
        _lastImage = widget.decode(outcome.last.photo);
        _phase = _Phase.result;
      });
    } catch (e) {
      if (!mounted || run != _run) return;
      // Cancel ends the run once the call in flight is answered: nothing was written.
      if (e is CalibrationCancelled || _cancelling) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _error = e is CalibrationStopped ? e.message : 'Calibration failed: ${operatorMessage(e)}';
        _phase = _Phase.stopped;
      });
    }
  }

  Future<ColourCardResponse> _measure(ColourCardRequest request) => KioskClient(GrpcChannelProvider.channel)
      .measureColourCard(request, options: CallOptions(timeout: const Duration(seconds: 60)));

  void _progress(String step, String? status) {
    if (!mounted) return;
    setState(() {
      _step = step;
      _status = status;
    });
  }

  /// R16: the four taps on the last photo, in the measurement dialog; null = Cancel.
  Future<CardShot?> _taps(Uint8List photo, int camera, CardReference reference) async {
    if (!mounted) return null;
    final taps = await showDialog<PhotoColourTaps>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PhotoColourMeasureDialog(
        photos: [CameraPhoto(camera, photo, 0, 0)],
        light: 'all',
        decode: widget.decode,
        reference: reference,
        tapsOnly: true,
        title: '$_step · the card was not found: tap its four corner patches',
      ),
    );
    if (taps == null) return null;
    return CardShot(
      srgb8: taps.sample.means,
      clipped: taps.sample.clipped,
      patchSizePx: 0,
      photo: photo,
      centres: taps.centres,
      exposure: 0,
      camera: camera,
      method: 'taps',
    );
  }

  void _cancel() {
    _run?.cancel();
    setState(() => _cancelling = true);
  }

  Future<void> _save() async {
    final outcome = _outcome;
    // A second tap before the dialog rebuilt sends no write twice.
    if (outcome == null || _phase == _Phase.saving) return;
    setState(() => _phase = _Phase.saving);
    final report = await saveCalibration(outcome, _kioskMix, _kioskWhiteBalance,
        settings: SettingsClient(GrpcChannelProvider.channel,
            options: CallOptions(timeout: const Duration(seconds: 20))),
        resume: _report);
    _applyStored(outcome, report.stored);
    if (!mounted) return;
    if (report.ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _report = report;
      _phase = _Phase.saveFailed;
    });
  }

  /// The stored writes into the shared settings snapshot; the column profile is
  /// read again (the card's "Not saved" mark).
  void _applyStored(CalibrationOutcome outcome, List<String> stored) {
    final s = SettingsState.current;
    if (s == null || stored.isEmpty) return;
    final best = outcome.mix.best;
    if (stored.contains(writeLedRed)) s.intensityRed = best.red;
    if (stored.contains(writeLedGreen)) s.intensityGreen = best.green;
    if (stored.contains(writeLedBlue)) s.intensityBlue = best.blue;
    final tint = outcome.tint;
    if (tint != null && stored.contains(writeWhiteBalance)) s.glareFreeWhiteBalance = tint.kelvin;
    for (final f in outcome.fits) {
      if (!stored.contains(writeColourCorrection(f.light))) continue;
      final state = ColourCorrectionState(
          light: f.light, matrix: f.fit.matrix, source: 'kiosk', measurement: f.measurement);
      final i = s.colourCorrections.indexWhere((c) => c.light == f.light);
      if (i >= 0) {
        s.colourCorrections[i] = state;
      } else {
        s.colourCorrections.add(state);
      }
    }
    ColumnState.touch();
    SettingsState.revision.value++;
  }

  bool _anyChange(CalibrationOutcome o) =>
      o.mix.best != _kioskMix ||
      (o.tint != null && o.tint!.kelvin != _kioskWhiteBalance) ||
      o.fits.isNotEmpty;

  static String _f1(double v) => v.toStringAsFixed(1);

  static String _signed(double v) {
    final t = _f1(v);
    return t.startsWith('-') ? t : '+$t';
  }

  // ---------------------------------------------------------------------------
  // The phases
  // ---------------------------------------------------------------------------

  static const _muted = TextStyle(color: T.muted, fontSize: 12.5, height: 1.4);
  static const _ink = TextStyle(color: T.ink, fontSize: 14, height: 1.4);

  Widget _setup() {
    final lightsOn = _lightsOn;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ColourCardChoice(),
      if (_exposureAuto == false) ...[
        const SizedBox(height: 8),
        const Text(fixedExposureWarning, style: TextStyle(color: T.warn, fontSize: 14)),
      ],
      const SizedBox(height: 12),
      const RowLabel('Lights'),
      const SizedBox(height: 4),
      Wrap(spacing: 18, children: [
        for (final MapEntry(key: light, value: label) in colourLightLabels.entries)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Checkbox(
              key: ValueKey('calibrate-light-$light'),
              value: switch (light) { 'all' => true, 'neighbours' => _neighbours, _ => _glareFree },
              // Standard (all LEDs) is always on: the LED mix is tuned on it.
              onChanged: switch (light) {
                'all' => null,
                'neighbours' => (v) => setState(() => _neighbours = v ?? false),
                _ => (v) => setState(() => _glareFree = v ?? false),
              },
            ),
            Text(label, style: _ink),
          ]),
      ]),
      const SizedBox(height: 10),
      const Text(calibrateHoldCard, style: _ink),
      if (!lightsOn) ...[
        const SizedBox(height: 10),
        const Text(calibrateLightsOff, style: TextStyle(color: T.warn, fontSize: 14)),
      ],
      const Spacer(),
      _buttons([
        QuietButton(text: 'Cancel', width: 130, onPressed: () => Navigator.of(context).pop()),
        SizedBox(width: 160, child: GoButton(text: 'Start', onPressed: lightsOn ? _start : null)),
      ]),
    ]);
  }

  Widget _running() {
    final index = math.max(0, _steps.indexOf(_step));
    final status = _status;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_step, style: const TextStyle(color: T.ink, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text('Step ${index + 1} of ${_steps.length}', style: _muted),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: (index + 0.5) / _steps.length),
      const SizedBox(height: 12),
      if (status != null)
        Text(status, style: const TextStyle(color: T.warn, fontSize: 14, fontWeight: FontWeight.w600))
      else
        const Text('Keep the card still, flat to the middle camera, until the result shows.', style: _ink),
      if (_cancelling) ...[
        const SizedBox(height: 8),
        const Text('Cancelling: the photo being taken ends first…', style: _muted),
      ],
      const Spacer(),
      _buttons([QuietButton(text: 'Cancel', width: 130, onPressed: _cancelling ? null : _cancel)]),
    ]);
  }

  Widget _stopped() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_error ?? '', style: const TextStyle(color: T.fail, fontSize: 14)),
        if (!_lightsOn) ...[
          const SizedBox(height: 10),
          const Text(calibrateLightsOff, style: TextStyle(color: T.warn, fontSize: 14)),
        ],
        const Spacer(),
        _buttons([
          QuietButton(text: 'Cancel', width: 130, onPressed: () => Navigator.of(context).pop()),
          SizedBox(width: 160, child: GoButton(text: 'Retry', onPressed: _lightsOn ? _start : null)),
        ]),
      ]);

  String _mixLine(MixSearchResult mix) => mix.changed
      ? 'LED mix ${mix.start} → ${mix.best} · brightness ${_signed(mix.brightnessChangePercent)} %'
      : 'LED mix ${mix.start}: ${mix.message ?? mixAlreadyBest}';

  String _kelvin(int k) => k == 0 ? "the camera's own" : '$k K';

  String _fitLine(LightFit f, CardReference reference) {
    final fit = f.fit;
    final skin = [
      for (final id in reference.skin)
        if (reference.indexOf(id) >= 0)
          '$id ${_f1(fit.deBefore[reference.indexOf(id)])} → ${_f1(fit.deAfter[reference.indexOf(id)])}',
    ].join(', ');
    return '${colourLightLabels[f.light] ?? f.light}: mean ΔE ${_f1(fit.meanDeBefore)} → '
        '${_f1(fit.meanDeAfter)} · skin $skin · worst ${_f1(fit.worstBefore)} → ${_f1(fit.worstAfter)} · '
        'score ${_f1(fit.scoreBefore)} → ${_f1(fit.scoreAfter)}${f.shot.method == 'taps' ? ' (taps)' : ''}';
  }

  Widget _resultLines(CalibrationOutcome o) {
    final reference = _reference!;
    final tint = o.tint;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_mixLine(o.mix), style: const TextStyle(color: T.ink, fontSize: 14, fontWeight: FontWeight.w600)),
      if (o.tintSkipped != null)
        Text(o.tintSkipped!, style: _ink)
      else if (tint != null)
        Text(
            'Glare-free white balance ${_kelvin(_kioskWhiteBalance)} → ${_kelvin(tint.kelvin)}'
            '${tint.kelvin == _kioskWhiteBalance ? ' (unchanged)' : ''}'
            // spec 4.4 step 3: the green-magenta cast the white balance cannot move
            ' · residual a* ${_signed(tint.deltaA)}',
            style: _ink),
      for (final f in o.fits) Text(_fitLine(f, reference), style: _ink),
      for (final s in o.skipped)
        Text('${colourLightLabels[s.light] ?? s.light}: not changed: ${s.reason}',
            style: const TextStyle(color: T.warn, fontSize: 14)),
      if (!_anyChange(o)) ...[
        const SizedBox(height: 4),
        const Text(nothingToSave, style: TextStyle(color: T.warn, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    ]);
  }

  Widget _result(CalibrationOutcome o) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _resultLines(o),
        const SizedBox(height: 10),
        Expanded(child: _photo(o.last)),
        const SizedBox(height: 12),
        _buttons([
          QuietButton(text: 'Discard', width: 130, onPressed: () => Navigator.of(context).pop()),
          SizedBox(width: 160, child: GoButton(text: 'Save', onPressed: _anyChange(o) ? _save : null)),
        ]),
      ]);

  /// The last photo with its 24 measured (or tapped) points.
  Widget _photo(CardShot shot) => FutureBuilder<DecodedImage>(
        future: _lastImage,
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) {
            return Center(
                child: snapshot.hasError
                    ? const Text('The photo could not be read', style: _muted)
                    : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)));
          }
          return LayoutBuilder(builder: (context, constraints) {
            final box = applyBoxFit(
                    BoxFit.contain, Size(image.width.toDouble(), image.height.toDouble()), constraints.biggest)
                .destination;
            final scale = box.width / image.width;
            return Center(
              child: SizedBox.fromSize(
                key: const ValueKey('calibrate-result-photo'),
                size: box,
                child: Stack(fit: StackFit.expand, children: [
                  Image.memory(shot.photo,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stack) => const ColoredBox(color: Color(0xFF101C26))),
                  CustomPaint(painter: _PointsPainter([for (final c in shot.centres) c * scale])),
                ]),
              ),
            );
          });
        },
      );

  Widget _saving() => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
          SizedBox(width: 10),
          RowLabel('Saving…'),
        ]),
      ]);

  Widget _saveFailed() {
    final report = _report!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Not saved: ${report.failed} failed: ${report.error}',
          style: const TextStyle(color: T.fail, fontSize: 14)),
      const SizedBox(height: 4),
      Text(report.stored.isEmpty ? 'Nothing was stored.' : 'Already stored: ${report.stored.join(', ')}.',
          style: _ink),
      const Spacer(),
      _buttons([
        QuietButton(
            text: 'Cancel',
            width: 130,
            onPressed: () => Navigator.of(context).pop(report.stored.isEmpty ? null : false)),
        SizedBox(width: 160, child: GoButton(text: 'Retry', onPressed: _save)),
      ]),
    ]);
  }

  Widget _buttons(List<Widget> buttons) => Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(width: 10), buttons[i]],
      ]);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: _phase != _Phase.running && _phase != _Phase.saving,
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: math.min(1000, screen.width - 48),
          height: math.min(820, screen.height - 48),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Calibrate · Photo colour',
                  style: TextStyle(color: T.titleBlue, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Expanded(
                child: switch (_phase) {
                  _Phase.setup => _setup(),
                  _Phase.running => _running(),
                  _Phase.stopped => _stopped(),
                  _Phase.result => _result(_outcome!),
                  _Phase.saving => _saving(),
                  _Phase.saveFailed => _saveFailed(),
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The 24 points as green dots with a dark ring.
class _PointsPainter extends CustomPainter {
  _PointsPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()..color = const Color(0xCC000000);
    final dot = Paint()..color = T.goGreen;
    for (final p in points) {
      canvas.drawCircle(p, 5, ring);
      canvas.drawCircle(p, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_PointsPainter old) => old.points != points;
}
