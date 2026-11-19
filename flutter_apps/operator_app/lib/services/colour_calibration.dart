// The colour calibration run and its Save (spec 2026-11-02 sections 2, 4.2-4.5
// and 5; plan Task 12): the steps over MeasureColourCard (find the card, the
// LED mix, the glare-free tint, one colour-correction photo per ticked light),
// three attempts per photo and then the four taps (ruling R16; none for a card
// refused by its greys, ruling F5), Cancel, and
// Save through the settings RPCs that exist today. Nothing is written before
// Save: the run holds no settings client. The dialog of Task 13 drives it.
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:face_snap_grpc/face_snap_grpc.dart' as pb show LedMix;
import 'package:face_snap_grpc/face_snap_grpc.dart' hide LedMix;

import '../util/card_reference.dart';
import '../util/colour_fit.dart';
import '../util/glare_free_tint.dart';
import '../util/led_mix_search.dart';
import 'rpc_error.dart';

// gRPC status codes (the grpc package's StatusCode is not re-exported).
const _invalidArgument = 3;
const _unimplemented = 12;

/// The steps, as the progress bar names them (spec 2).
const String stepFindCard = 'Find the card';
const String stepLedMix = 'LED mix';
const String stepTint = 'Glare-free tint';
const String stepCorrection = 'Colour correction';

/// The lights a run can fit, in the order it photographs them, and their names.
const Map<String, String> colourLightLabels = {
  'all': 'Standard (all LEDs)',
  'neighbours': 'Standard (neighbours)',
  'glare_free': 'Glare-free',
};

/// The photos taken for one measurement before the taps are offered (R16).
const int cardAttempts = 3;

/// A found card whose patches are smaller than this (whole-patch side, px)
/// counts as lost (ruling P5: R16's 17 px was measured on half-patch cells).
const double minPatchSizePx = 34;

/// The server's note when glare clips the white even at the darkest exposure.
const String whiteClippedNote = 'white clipped at the darkest exposure';

/// The run stops with this when the tapped patches cannot be read either.
const String tapsUnreadable = 'the card could not be read from the taps';

/// Ruling P11: the first photo found no card in three attempts, so the server
/// never set the exposure on the card's white; the run stops instead of taps.
const String cardNotFoundAutomatically = 'the card was not found automatically: use Measure manually';

/// The run stops with this when no attempt returned a photo to tap on.
const String cardNotFound = 'the card was not found in the photo';

/// The servers' note (byte-identical to the Python and Server 2.0 `GREYS_NOTE`)
/// when the card was seen but its grey patches refused it: its dark patches read
/// too light, typically glare. Not "not found": the remedy is the card's tilt.
const String greysNote =
    'the card was seen, but its dark patches read too light: tilt it 10-15° away from the lights or dim the room lights';

/// Ruling F5: the run stops with this when a photo's last attempt was a card the
/// servers saw but refused by its greys, on the first photo and on any later one.
/// No taps are offered: they read the same photo with the same grey check.
const String greysStopped = '$greysNote, then press Retry';

/// Shown before Start (the operator app only) when the camera's Automatic
/// exposure is off: the card photos then use the fixed exposure.
const String fixedExposureWarning =
    'Automatic exposure is off: the card photos use the fixed exposure and can be too dark under the '
    'glare-free light. Turn it on in Camera for the calibration.';

/// Ruling R19: why the tint step did not run.
const String tintSkippedAuto =
    "the camera's white balance is automatic: the glare-free white balance is not used";

/// The status while a lost card is retried (spec 2).
String holdCardStill(int camera) => 'Hold the card still in front of camera $camera';

/// What the R2 probe learnt about the server's card finder.
enum ColourCardAvailability {
  /// INVALID_ARGUMENT (the light refusal): the server has the card finder; Calibrate is offered.
  available,

  /// UNIMPLEMENTED (an older server, or no finder), or a reply (a server that took
  /// light "" as valid does not follow R2): only "Measure manually"; not asked again.
  unavailable,

  /// Any other error (a timeout, the kiosk unreachable, an internal error) says
  /// nothing about the finder: only "Measure manually" for now, and the probe is
  /// sent again later.
  unknown,
}

/// The R2 probe: `MeasureColourCard(light: "")`, which touches no camera or LED.
Future<ColourCardAvailability> colourCardAvailable(KioskClient kiosk) async {
  try {
    await kiosk.measureColourCard(ColourCardRequest(light: ''));
    return ColourCardAvailability.unavailable;
  } on GrpcError catch (e) {
    return switch (e.code) {
      _invalidArgument => ColourCardAvailability.available,
      _unimplemented => ColourCardAvailability.unavailable,
      _ => ColourCardAvailability.unknown,
    };
  } catch (_) {
    return ColourCardAvailability.unknown;
  }
}

/// One measurement of the card: the 24 patches (sRGB 0..255, the reference's
/// order), where they sit in [photo], and how the photo was taken.
class CardShot {
  CardShot({
    required this.srgb8,
    required this.clipped,
    required this.patchSizePx,
    required this.photo,
    required this.centres,
    required this.exposure,
    required this.camera,
    required this.method,
  });

  final List<List<double>> srgb8;
  final List<bool> clipped;

  /// The smallest whole patch's side in the full frame (0 for taps).
  final double patchSizePx;

  /// The JPEG the server measured (long side 1920).
  final Uint8List photo;

  /// The patch centres in [photo] pixels, the reference's order.
  final List<Offset> centres;

  /// The brightness target the photo was taken at, and the camera.
  final int exposure;
  final int camera;

  /// `auto` (the server found the card) or `taps` (the operator's four taps).
  final String method;
}

/// One photo through MeasureColourCard.
typedef MeasureCard = Future<ColourCardResponse> Function(ColourCardRequest request);

/// The four taps on [photo] (the last one the server returned); null = Cancel.
typedef TapsFallback = Future<CardShot?> Function(Uint8List photo, int camera, CardReference reference);

/// What the operator chose and what the kiosk has in force when Start is pressed.
class CalibrationPlan {
  CalibrationPlan({
    required this.reference,
    required this.neighbours,
    required this.glareFree,
    required this.kioskMix,
    required this.kioskWhiteBalance,
    required this.autoWhiteBalance,
  });

  /// The card and its version.
  final CardReference reference;

  /// The ticked lights besides Standard (all LEDs), which is always fitted.
  final bool neighbours, glareFree;

  /// The kiosk's LED mix and glare-free white balance (K; 0 = the camera's own
  /// white balance, or an invalid stored value).
  final LedMix kioskMix;
  final int kioskWhiteBalance;

  /// The camera's white balance is automatic: the tint step is skipped (R19).
  final bool autoWhiteBalance;
}

/// One light's matrix: its fit, the photo it came from and the record Save stores.
class LightFit {
  LightFit({required this.light, required this.fit, required this.shot, required this.measurement});

  final String light;
  final ColourFit fit;
  final CardShot shot;
  final ColourMeasurement measurement;
}

/// A finished run, for the result and Save.
class CalibrationOutcome {
  CalibrationOutcome({
    required this.mix,
    this.tint,
    this.tintSkipped,
    required this.fits,
    this.skipped = const [],
    required this.last,
  });

  final MixSearchResult mix;

  /// The glare-free bisection; null when Glare-free was not ticked or the step was skipped.
  final TintResult? tint;

  /// Why the tint step was skipped ([tintSkippedAuto]), else null.
  final String? tintSkipped;

  /// One per ticked light, in the order all, neighbours, glare_free.
  final List<LightFit> fits;

  /// Ruling P10: the ticked lights whose matrix would not improve the colours
  /// ([refusalNoImprovement]) or would make a skin patch worse at every skin
  /// weight ([refusalSkinWorse]): no fit and no write for them. Save still writes
  /// the mix, the white balance and the other lights.
  final List<({String light, String reason})> skipped;

  /// The run's last photo, for the result's view with the 24 points.
  final CardShot last;
}

/// Thrown by [ColourCalibration.run] after [ColourCalibration.cancel] (or a
/// cancelled taps fallback): nothing was written.
class CalibrationCancelled implements Exception {
  const CalibrationCancelled();

  @override
  String toString() => 'the calibration was cancelled';
}

/// The run cannot go on; [message] says why (for the operator).
class CalibrationStopped implements Exception {
  const CalibrationStopped(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The run of spec 4.2-4.5 over [measure]. A server error from [measure]
/// (busy, unreachable, a refusal) ends the run with that error.
class ColourCalibration {
  ColourCalibration({required this.measure, required this.taps, this.progress});

  /// Takes the photos.
  final MeasureCard measure;

  /// Offered on the last photo after [cardAttempts] lost attempts.
  final TapsFallback taps;

  /// Called with the step at its start (status null), with the hold-still text
  /// (or [greysNote] after a card refused by its greys) before a retry, and with
  /// null again once a retried photo found the card.
  final void Function(String step, String? status)? progress;

  /// Set by [cancel], never cleared: each Start makes a new [ColourCalibration],
  /// so a cancel that comes before [run] is not lost.
  bool _cancelled = false;

  /// Stops the run: the call in flight ends, then [run] throws [CalibrationCancelled].
  void cancel() => _cancelled = true;

  void _checkCancelled() {
    if (_cancelled) throw const CalibrationCancelled();
  }

  Future<CalibrationOutcome> run(CalibrationPlan plan) async {
    final reference = plan.reference;
    final card = reference.card;

    // 1. Find the card: its exposure (and camera) are kept for every later photo.
    progress?.call(stepFindCard, null);
    final (found, _) = await _shoot(
        stepFindCard, ColourCardRequest(light: 'all', camera: 0, card: card), reference, (_) => null,
        allowTaps: false);
    final exposure = found.exposure, camera = found.camera;

    ColourCardRequest request(String light, LedMix mix, {int? whiteBalance}) => ColourCardRequest(
          light: light,
          camera: camera,
          card: card,
          ledMix: pb.LedMix(red: mix.red, green: mix.green, blue: mix.blue),
          whiteBalance: whiteBalance,
          exposure: exposure,
        );

    // 2. The LED mix on the standard light.
    progress?.call(stepLedMix, null);
    final mix = await searchLedMix(
      start: plan.kioskMix,
      score: (candidate) async => (await _shoot(stepLedMix, request('all', candidate), reference,
              (shot) => photoScore(shot.srgb8, shot.clipped, reference)))
          .$2,
    );
    final winner = mix.best;

    // 3. The glare-free tint, unless the camera's white balance is automatic (R19).
    TintResult? tint;
    String? tintSkipped;
    if (plan.glareFree) {
      if (plan.autoWhiteBalance) {
        tintSkipped = tintSkippedAuto;
      } else {
        progress?.call(stepTint, null);
        // 0 = the camera's own white balance (or an invalid stored value; the
        // server then photographs at 5750 K): the bisection starts in the middle.
        final start = plan.kioskWhiteBalance == 0
            ? (kWhiteBalanceMin + kWhiteBalanceMax) ~/ 2
            : plan.kioskWhiteBalance;
        tint = await searchWhiteBalance(
          start: start,
          cast: (kelvin) async => (await _shoot(stepTint, request('glare_free', winner, whiteBalance: kelvin),
                  reference, (shot) => tintCast(shot.srgb8, reference)))
              .$2,
        );
      }
    }

    // 4. One matrix per ticked light, with the winner (and the new k for glare-free).
    progress?.call(stepCorrection, null);
    final fits = <LightFit>[];
    final skipped = <({String light, String reason})>[];
    CardShot? last;
    for (final light in colourLightLabels.keys) {
      if (light == 'neighbours' && !plan.neighbours) continue;
      if (light == 'glare_free' && !plan.glareFree) continue;
      final kelvin = light == 'glare_free' ? tint?.kelvin : null;
      final (shot, fit) = await _shoot(stepCorrection, request(light, winner, whiteBalance: kelvin), reference,
          (shot) => fitColourMatrixGuarded(shot.srgb8, [for (final c in shot.clipped) !c], reference: reference));
      last = shot;
      final refusal = colourFitRefusal(fit, reference: reference);
      if (refusal != null) {
        skipped.add((light: light, reason: refusal));
        continue;
      }
      fits.add(LightFit(
        light: light,
        fit: fit,
        shot: shot,
        // spec 5 and ruling P8: every field, for a tapped fit too
        measurement: ColourMeasurement(
          measured: measuredAt(DateTime.now()),
          camera: shot.camera,
          chart: card,
          meanDeBefore: fit.meanDeBefore,
          meanDeAfter: fit.meanDeAfter,
          method: shot.method,
          ledRed: winner.red,
          ledGreen: winner.green,
          ledBlue: winner.blue,
          scoreAfter: fit.scoreAfter,
          whiteBalance: kelvin ?? 0,
          cardVersion: card == 'classic' ? reference.version : '',
        ),
      ));
    }
    return CalibrationOutcome(
        mix: mix, tint: tint, tintSkipped: tintSkipped, fits: fits, skipped: skipped, last: last!);
  }

  /// One measurement with up to [cardAttempts] photos (R16), then the taps on the
  /// last photo. An attempt is lost when the card is not found, its patches are
  /// under [minPatchSizePx] (P5), or [use] cannot read the photo (an
  /// [ArgumentError], e.g. fewer than 3 usable patches). The white clipped note
  /// stops the run. A card refused by its greys shows [greysNote] before the next
  /// attempt; when the last attempt was refused so, the run stops with
  /// [greysStopped] and no taps (F5). Without [allowTaps] (the first photo, P11)
  /// the run stops with [cardNotFoundAutomatically] instead, or with
  /// [refusalTooSmall] when every attempt was lost to the size rule. Returns the
  /// shot and what [use] made of it.
  Future<(CardShot, T)> _shoot<T>(
      String step, ColourCardRequest request, CardReference reference, T Function(CardShot) use,
      {bool allowTaps = true}) async {
    ColourCardResponse? last;
    Uint8List? lastPhoto;
    String? lost;
    var tooSmall = 0;
    // The last attempt's card was seen but refused by its greys (the servers' note).
    var greysRefused = false;
    for (var attempt = 1; attempt <= cardAttempts; attempt++) {
      _checkCancelled();
      if (lost != null) progress?.call(step, lost);
      final ColourCardResponse response;
      try {
        response = await measure(request);
      } catch (_) {
        _checkCancelled();
        rethrow;
      }
      _checkCancelled();
      if (response.note == whiteClippedNote) throw const CalibrationStopped(refusalWhiteClipped);
      last = response;
      greysRefused = !response.found && response.note == greysNote;
      if (response.photo.isNotEmpty) lastPhoto = Uint8List.fromList(response.photo);
      if (!response.found) {
        // A card refused by its greys: the operator can tilt it before the next attempt.
        lost = greysRefused ? greysNote : holdCardStill(response.camera);
        continue;
      }
      if (response.patchSizePx < minPatchSizePx) {
        lost = refusalTooSmall;
        tooSmall++;
        continue;
      }
      final shot = _shotOf(response, reference);
      try {
        final value = use(shot);
        if (lost != null) progress?.call(step, null);
        return (shot, value);
      } on ArgumentError {
        lost = holdCardStill(response.camera);
      }
    }
    // F5: the taps would refuse this photo by the same grey check: tilting is the remedy.
    if (greysRefused) throw const CalibrationStopped(greysStopped);
    if (!allowTaps) {
      // Every attempt found the card but too small: holding it closer is the remedy.
      throw CalibrationStopped(tooSmall == cardAttempts ? refusalTooSmall : cardNotFoundAutomatically);
    }
    if (lastPhoto == null) throw const CalibrationStopped(cardNotFound);
    // The taps replace this one photo's measurement (with the run's exposure and camera).
    final tapped = await taps(lastPhoto, last!.camera, reference);
    _checkCancelled();
    if (tapped == null) throw const CalibrationCancelled();
    final shot = CardShot(
      srgb8: tapped.srgb8,
      clipped: tapped.clipped,
      patchSizePx: tapped.patchSizePx,
      photo: tapped.photo,
      centres: tapped.centres,
      exposure: last.exposure,
      camera: last.camera,
      method: 'taps',
    );
    try {
      final value = use(shot);
      progress?.call(step, null);
      return (shot, value);
    } on ArgumentError {
      throw const CalibrationStopped(tapsUnreadable);
    }
  }

  /// The response's patches in the reference's order.
  static CardShot _shotOf(ColourCardResponse response, CardReference reference) {
    final byId = {for (final p in response.patches) p.id: p};
    final patches = [for (final id in reference.ids) byId[id]];
    if (response.patches.length != reference.ids.length || patches.contains(null)) {
      throw CalibrationStopped(
          'the kiosk measured ${response.patches.length} patches, not the ${reference.ids.length} of the card');
    }
    return CardShot(
      srgb8: [
        for (final p in patches) [p!.r, p.g, p.b],
      ],
      clipped: [for (final p in patches) p!.clipped],
      patchSizePx: response.patchSizePx,
      photo: Uint8List.fromList(response.photo),
      centres: [for (final p in patches) Offset(p!.x, p.y)],
      exposure: response.exposure,
      camera: response.camera,
      method: 'auto',
    );
  }
}

/// What a Save stored: the writes done, in order, and the one that failed with
/// its error (both null when everything was stored).
class SaveReport {
  SaveReport({required this.stored, this.failed, this.error});

  final List<String> stored;
  final String? failed;
  final String? error;

  bool get ok => failed == null;
}

/// The names of Save's writes, as [SaveReport] lists them.
const String writeLedRed = 'LED red';
const String writeLedGreen = 'LED green';
const String writeLedBlue = 'LED blue';
const String writeWhiteBalance = 'glare-free white balance';
String writeColourCorrection(String light) => 'colour correction ${colourLightLabels[light] ?? light}';

/// Save (spec 5), in this order: the LED mix channels that changed
/// (SetIntensityRed/Green/Blue), the glare-free white balance when the tint step
/// changed it (SetGlareFreeWhiteBalance), then one SetColourCorrection per fit.
/// Stops at the first failure. With [resume] (the report of a failed Save) the
/// writes it stored are not sent again: Retry goes on from the failed one.
Future<SaveReport> saveCalibration(CalibrationOutcome outcome, LedMix kioskMix, int kioskWhiteBalance,
    {required SettingsClient settings, SaveReport? resume}) async {
  final best = outcome.mix.best;
  final kelvin = outcome.tint?.kelvin;
  final writes = <(String, Future<Object?> Function())>[
    if (best.red != kioskMix.red) (writeLedRed, () => settings.setIntensityRed(IntensityRequest(value: best.red))),
    if (best.green != kioskMix.green)
      (writeLedGreen, () => settings.setIntensityGreen(IntensityRequest(value: best.green))),
    if (best.blue != kioskMix.blue)
      (writeLedBlue, () => settings.setIntensityBlue(IntensityRequest(value: best.blue))),
    if (kelvin != null && kelvin != kioskWhiteBalance)
      (
        writeWhiteBalance,
        () => settings.setGlareFreeWhiteBalance(GlareFreeWhiteBalanceRequest(value: kelvin)),
      ),
    for (final f in outcome.fits)
      (
        writeColourCorrection(f.light),
        () => settings.setColourCorrection(
            ColourCorrectionRequest(light: f.light, matrix: f.fit.matrix, measurement: f.measurement)),
      ),
  ];
  final done = resume?.stored ?? const <String>[];
  final stored = <String>[];
  for (final (name, write) in writes) {
    if (done.contains(name)) {
      stored.add(name);
      continue;
    }
    try {
      await write();
    } catch (e) {
      return SaveReport(stored: stored, failed: name, error: operatorMessage(e));
    }
    stored.add(name);
  }
  return SaveReport(stored: stored);
}
