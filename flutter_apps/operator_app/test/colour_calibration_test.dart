// The colour calibration run and its Save (spec 2026-11-02 sections 2, 4.2-4.5
// and 5; plan Task 12, rulings R2, R16, R17, R19, R20, P5 and P8): the photos
// in the spec's order, the three attempts per photo and the taps after them,
// the white clipped stop, Cancel, the skipped tint with automatic white
// balance, Save in the spec's order with a failure and its Retry, the R2 probe
// and the card preferences. The run measures through a fake MeasureCard built
// on simulated_card.dart; Save and the probe talk to in-process fake servers
// over a real loopback connection.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:face_snap_grpc/face_snap_grpc.dart' hide LedMix;
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart'
    show ChannelCredentials, ChannelOptions, ClientChannel, GrpcError, Server, Service, ServiceCall;
import 'package:operator_app/services/app_config.dart';
import 'package:operator_app/services/colour_calibration.dart';
import 'package:operator_app/util/card_reference.dart';
import 'package:operator_app/util/colour_fit.dart';
import 'package:operator_app/util/glare_free_tint.dart';
import 'package:operator_app/util/led_mix_search.dart';

import 'fake_server.dart';
import 'simulated_card.dart';
import 'colorchecker_files.dart';

// `flutter test` runs with the package root as the working directory.
CardReference _read(String card, [String version = '']) => CardReference.fromJson(
    jsonDecode(File('assets/colour_cards/$card.json').readAsStringSync()) as Map<String, dynamic>,
    version: version);

final _spyder = _read('spyder24');
final _classic = _read('classic', 'pre2014');

/// The kiosk's mix: neutral, so the simulated best (bestFrom) is a real move.
const _kioskMix = LedMix(200, 200, 200);

/// The fake server's camera for camera 0 (the middle one) and its exposure.
const _middleCamera = 3;
const _cardExposure = 24;

const _notFound = 'the card was not found in the photo';
const _whiteClippedNote = 'white clipped at the darkest exposure';
const _greysNote =
    'the card was seen, but its dark patches read too light: tilt it 10-15° away from the lights or dim the room lights';

/// A kiosk answering MeasureColourCard from a simulated camera. Every request is
/// recorded with the step the run reported when it was sent; [lose] answers
/// "not found" for a call, [small] reports small patches, [unreadable] clips
/// every patch, [perfect] answers the reference itself (a photo no matrix
/// improves), [patchesOf] answers its patches (non-null) instead of the
/// simulated photo, [clippedNoteAt] adds the white clipped note.
class _Kiosk {
  _Kiosk(this.sim,
      {this.lose,
      this.small,
      this.unreadable,
      this.perfect,
      this.patchesOf,
      this.clippedNoteAt,
      this.loseNote = _notFound,
      this.loseNoteOf});

  final SimulatedCard sim;
  final bool Function(int call, String step, ColourCardRequest request)? lose, small, unreadable, perfect;
  final List<List<double>>? Function(int call, String step, ColourCardRequest request)? patchesOf;
  final int? clippedNoteAt;

  /// The note a lost call carries (the servers' "not found" or their greys note).
  final String loseNote;

  /// The note of a lost call by its number, instead of [loseNote] (non-null).
  final String Function(int call)? loseNoteOf;
  void Function(int call)? onCall;

  /// The last call whose answer was complete (set at the end of [measure]).
  int? ended;

  final List<ColourCardRequest> requests = [];
  final List<String> stepOf = [];
  final List<(String, String?)> progress = [];
  String step = '';

  CardReference get reference => sim.reference;

  void report(String step, String? status) {
    this.step = step;
    progress.add((step, status));
  }

  static Uint8List photoOf(int call) => Uint8List.fromList([0xff, 0xd8, call & 0xff, call >> 8]);

  Future<ColourCardResponse> measure(ColourCardRequest request) async {
    final call = requests.length;
    requests.add(request.deepCopy());
    stepOf.add(step);
    onCall?.call(call);
    await Future<void>.delayed(Duration.zero);
    final camera = request.camera == 0 ? _middleCamera : request.camera;
    final exposure = request.hasExposure() ? request.exposure : _cardExposure;
    final photo = photoOf(call);
    if (lose?.call(call, step, request) ?? false) {
      ended = call;
      return ColourCardResponse(found: false, exposure: exposure, camera: camera, photo: photo, note: loseNoteOf?.call(call) ?? loseNote);
    }
    final mix = request.hasLedMix()
        ? LedMix(request.ledMix.red, request.ledMix.green, request.ledMix.blue)
        : _kioskMix;
    var p = sim.photo(mix);
    if (perfect?.call(call, step, request) ?? false) {
      final srgb8 = [
        for (final lab in reference.lab)
          [for (final v in labD50ToLinearSrgb(lab)) (255 * linearToSrgb(v)).clamp(0, 255).toDouble()],
      ];
      p = (srgb8: srgb8, clipped: List.filled(srgb8.length, false));
    }
    final given = patchesOf?.call(call, step, request);
    if (given != null) p = (srgb8: given, clipped: List.filled(given.length, false));
    final clipAll = unreadable?.call(call, step, request) ?? false;
    ended = call;
    return ColourCardResponse(
      found: true,
      patches: [
        for (var i = 0; i < p.srgb8.length; i++)
          ColourPatch(
              id: reference.ids[i],
              r: p.srgb8[i][0],
              g: p.srgb8[i][1],
              b: p.srgb8[i][2],
              clipped: clipAll || p.clipped[i],
              x: 100.0 + i,
              y: 200.0 + i),
      ],
      patchSizePx: (small?.call(call, step, request) ?? false) ? 33.9 : 60,
      exposure: exposure,
      camera: camera,
      photo: photo,
      note: call == clippedNoteAt ? _whiteClippedNote : '',
    );
  }
}

/// The taps fallback: records what it was offered and answers the simulated
/// photo of the winner's mix (or null = Cancel).
class _Taps {
  _Taps(this.sim, {this.cancel = false, this.unreadable = false});

  final SimulatedCard sim;
  final bool cancel;

  /// Every tapped patch clipped: nothing to fit.
  final bool unreadable;
  final List<(Uint8List, int, CardReference)> offered = [];
  LedMix mix = _kioskMix;

  Future<CardShot?> call(Uint8List photo, int camera, CardReference reference) async {
    offered.add((photo, camera, reference));
    if (cancel) return null;
    final p = sim.photo(mix);
    return CardShot(
      srgb8: p.srgb8,
      clipped: [for (final c in p.clipped) unreadable || c],
      patchSizePx: 0,
      photo: photo,
      centres: [for (var i = 0; i < 24; i++) Offset(10.0 + i, 20.0 + i)],
      exposure: 0,
      camera: 0,
      method: 'taps',
    );
  }
}

SimulatedCard _sim(CardReference reference, {LedMix? best, double c = 1000}) =>
    SimulatedCard(reference: reference, best: best ?? bestFrom(_kioskMix), c: c);

CalibrationPlan _plan(CardReference reference,
        {bool neighbours = true, bool glareFree = true, bool auto = false, int whiteBalance = 5000}) =>
    CalibrationPlan(
      reference: reference,
      neighbours: neighbours,
      glareFree: glareFree,
      kioskMix: _kioskMix,
      kioskWhiteBalance: whiteBalance,
      autoWhiteBalance: auto,
    );

ColourCalibration _calibration(_Kiosk kiosk, _Taps taps) =>
    ColourCalibration(measure: kiosk.measure, taps: taps.call, progress: kiosk.report);

LedMix _mixOf(ColourCardRequest r) => LedMix(r.ledMix.red, r.ledMix.green, r.ledMix.blue);

const _hold = 'Hold the card still in front of camera $_middleCamera';

void main() {
  group('the run', () {
    test("a full run asks for the photos in the spec's order", () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim);
      final outcome = await _calibration(kiosk, _Taps(sim)).run(_plan(_spyder));
      final r = kiosk.requests;
      final mixPhotos = outcome.mix.photos, tintPhotos = outcome.tint!.photos;
      expect(r, hasLength(1 + mixPhotos + tintPhotos + 3));

      // Find the card: light all, the kiosk's own mix, the middle camera, no exposure
      expect(r[0].light, 'all');
      expect(r[0].card, 'spyder24');
      expect(r[0].camera, 0);
      expect(r[0].hasExposure(), isFalse);
      expect(r[0].hasLedMix(), isFalse);
      expect(r[0].hasWhiteBalance(), isFalse);
      // every later photo: the card's exposure and the camera measured
      for (final later in r.skip(1)) {
        expect(later.exposure, _cardExposure);
        expect(later.hasExposure(), isTrue);
        expect(later.camera, _middleCamera);
        expect(later.card, 'spyder24');
        expect(later.hasLedMix(), isTrue);
      }
      // LED mix: light all with the candidate, no white balance; the start twice first
      final mix = r.sublist(1, 1 + mixPhotos);
      expect(mix.every((q) => q.light == 'all' && !q.hasWhiteBalance()), isTrue);
      expect([_mixOf(mix[0]), _mixOf(mix[1])], [_kioskMix, _kioskMix]);
      expect(outcome.mix.changed, isTrue, reason: 'the simulated best is a real move');
      final winner = outcome.mix.best;
      // Glare-free tint: light glare_free, the winner, a white balance from the kiosk's
      final tint = r.sublist(1 + mixPhotos, 1 + mixPhotos + tintPhotos);
      expect(tint.every((q) => q.light == 'glare_free' && q.hasWhiteBalance() && _mixOf(q) == winner), isTrue);
      expect(tint.first.whiteBalance, 5000);
      // Colour correction: one photo per ticked light with the winner; glare_free at the new k
      final matrix = r.sublist(1 + mixPhotos + tintPhotos);
      expect([for (final q in matrix) q.light], ['all', 'neighbours', 'glare_free']);
      expect(matrix.every((q) => _mixOf(q) == winner), isTrue);
      expect(matrix[0].hasWhiteBalance() || matrix[1].hasWhiteBalance(), isFalse);
      expect(matrix[2].whiteBalance, outcome.tint!.kelvin);

      expect(kiosk.stepOf, [
        'Find the card',
        for (var i = 0; i < mixPhotos; i++) 'LED mix',
        for (var i = 0; i < tintPhotos; i++) 'Glare-free tint',
        'Colour correction', 'Colour correction', 'Colour correction',
      ]);
      expect(kiosk.progress.where((p) => p.$2 != null), isEmpty, reason: 'no card was lost');

      // one fit per light, each recorded as spec 5 and ruling P8 say
      expect([for (final f in outcome.fits) f.light], ['all', 'neighbours', 'glare_free']);
      for (final f in outcome.fits) {
        final m = f.measurement;
        expect(m.measured, matches(RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$')));
        expect(m.camera, _middleCamera);
        expect(m.chart, 'spyder24');
        expect(m.meanDeBefore, f.fit.meanDeBefore);
        expect(m.meanDeAfter, f.fit.meanDeAfter);
        expect(m.method, 'auto');
        expect([m.ledRed, m.ledGreen, m.ledBlue], [winner.red, winner.green, winner.blue]);
        expect(m.scoreAfter, f.fit.scoreAfter);
        expect(m.whiteBalance, f.light == 'glare_free' ? outcome.tint!.kelvin : 0);
        expect(m.cardVersion, '');
        expect(f.shot.method, 'auto');
        expect(f.shot.exposure, _cardExposure);
        expect(f.shot.centres, hasLength(24));
        expect(f.fit.scoreAfter, lessThan(f.fit.scoreBefore));
      }
      expect(outcome.last, same(outcome.fits.last.shot));
      expect(outcome.tintSkipped, isNull);
    });

    test('only the ticked lights get a matrix photo, and a Classic records its version', () async {
      final sim = _sim(_classic);
      final kiosk = _Kiosk(sim);
      final outcome =
          await _calibration(kiosk, _Taps(sim)).run(_plan(_classic, neighbours: false, glareFree: false));
      expect(outcome.tint, isNull);
      expect(kiosk.requests.where((q) => q.light != 'all'), isEmpty);
      expect([for (final f in outcome.fits) f.light], ['all']);
      final m = outcome.fits.single.measurement;
      expect(m.chart, 'classic');
      expect(m.cardVersion, 'pre2014');
      expect(m.whiteBalance, 0);
    });

    test('a lost-card retry does not count', () async {
      // the best three moves away (a gentler c keeps its far photos readable): the
      // search uses all its 16 photos
      final sim = _sim(_spyder, best: const LedMix(209, 202, 149), c: 100);
      var mixCalls = 0;
      final kiosk = _Kiosk(sim, lose: (call, step, request) => step == 'LED mix' && ++mixCalls == 5);
      final outcome =
          await _calibration(kiosk, _Taps(sim)).run(_plan(_spyder, neighbours: false, glareFree: false));
      expect(outcome.mix.photos, 16);
      expect(kiosk.stepOf.where((s) => s == 'LED mix'), hasLength(17));
      // the lost photo is taken again with the same mix
      final mix = [for (var i = 0; i < kiosk.requests.length; i++) if (kiosk.stepOf[i] == 'LED mix') kiosk.requests[i]];
      expect(_mixOf(mix[5]), _mixOf(mix[4]));
      expect(kiosk.progress, contains(('LED mix', _hold)));
    });

    test('three lost attempts open the taps on the last photo', () async {
      final sim = _sim(_spyder);
      // the card found, then lost for the first LED-mix photo (calls 1, 2, 3)
      final kiosk = _Kiosk(sim, lose: (call, step, request) => call >= 1 && call <= 3);
      final taps = _Taps(sim);
      final outcome =
          await _calibration(kiosk, taps).run(_plan(_spyder, neighbours: false, glareFree: false));
      // three attempts at that photo, then the taps on the third; the run goes on
      expect(kiosk.stepOf.take(5), ['Find the card', 'LED mix', 'LED mix', 'LED mix', 'LED mix']);
      expect(_mixOf(kiosk.requests[4]), _kioskMix, reason: 'the next photo is the second start photo');
      expect(taps.offered, hasLength(1));
      expect(taps.offered.single.$1, _Kiosk.photoOf(3));
      expect(taps.offered.single.$2, _middleCamera);
      expect(taps.offered.single.$3, same(_spyder));
      expect(kiosk.progress.where((p) => p.$2 == _hold), hasLength(2)); // before the 2nd and 3rd attempt
      expect(outcome.fits.single.measurement.method, 'auto');
    });

    test('a card seen but refused by its greys shows the note between attempts', () async {
      final sim = _sim(_spyder);
      // the first LED-mix photo refused by its greys twice (calls 1, 2), then found
      final kiosk = _Kiosk(sim, lose: (call, step, request) => call == 1 || call == 2, loseNote: _greysNote);
      final taps = _Taps(sim);
      await _calibration(kiosk, taps).run(_plan(_spyder, neighbours: false, glareFree: false));
      expect(greysNote, _greysNote);
      // before the 2nd and the 3rd attempt: the operator can tilt the card while they run
      expect(kiosk.progress.where((p) => p == ('LED mix', _greysNote)), hasLength(2));
      expect(kiosk.progress.where((p) => p.$2 == _hold), isEmpty);
      expect(taps.offered, isEmpty);
    });

    test('a later photo refused by its greys stops the run, with no taps', () async {
      final sim = _sim(_spyder);
      // the card found, then refused by its greys for the first LED-mix photo (calls 1, 2, 3)
      final kiosk = _Kiosk(sim, lose: (call, step, request) => call >= 1 && call <= 3, loseNote: _greysNote);
      final taps = _Taps(sim);
      await expectLater(
          _calibration(kiosk, taps).run(_plan(_spyder, neighbours: false, glareFree: false)),
          throwsA(isA<CalibrationStopped>()
              .having((e) => e.message, 'message', '$_greysNote, then press Retry')));
      // the taps read the same photo with the same grey check: they would refuse it too
      expect(taps.offered, isEmpty);
      expect(kiosk.requests, hasLength(4));
    });

    test('a colour-correction photo refused by its greys stops the run, with no taps', () async {
      final sim = _sim(_classic);
      final kiosk = _Kiosk(sim,
          lose: (call, step, request) => step == 'Colour correction' && request.light == 'neighbours',
          loseNote: _greysNote);
      final taps = _Taps(sim);
      await expectLater(
          _calibration(kiosk, taps).run(_plan(_classic, glareFree: false)),
          throwsA(isA<CalibrationStopped>()
              .having((e) => e.message, 'message', '$_greysNote, then press Retry')));
      expect(taps.offered, isEmpty);
      expect(kiosk.requests.where((r) => r.light == 'neighbours'), hasLength(cardAttempts));
    });

    test('the greys stop needs the note on the last attempt; a last plain not-found opens the taps', () async {
      final sim = _sim(_spyder);
      // the greys note on calls 1 and 2, a plain not-found on the third attempt (call 3)
      final kiosk = _Kiosk(sim,
          lose: (call, step, request) => call >= 1 && call <= 3,
          loseNoteOf: (call) => call == 3 ? _notFound : _greysNote);
      final taps = _Taps(sim);
      await _calibration(kiosk, taps).run(_plan(_spyder, neighbours: false, glareFree: false));
      expect(taps.offered, hasLength(1));
      expect(kiosk.progress.where((p) => p.$2 == _greysNote), hasLength(2));
    });

    test('a card not found carries on to the taps as before', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim, lose: (call, step, request) => call >= 1 && call <= 3);
      final taps = _Taps(sim);
      await _calibration(kiosk, taps).run(_plan(_spyder, neighbours: false, glareFree: false));
      expect(taps.offered, hasLength(1));
      expect(kiosk.progress.where((p) => p.$2 == _hold), hasLength(2));
      expect(kiosk.progress.where((p) => p.$2 == _greysNote), isEmpty);
    });

    test('a first photo refused by its greys stops the run with the greys note', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim, lose: (call, step, request) => call < 3, loseNote: _greysNote);
      final taps = _Taps(sim);
      await expectLater(
          _calibration(kiosk, taps).run(_plan(_spyder)),
          throwsA(isA<CalibrationStopped>()
              .having((e) => e.message, 'message', '$_greysNote, then press Retry')));
      expect(kiosk.progress.where((p) => p == ('Find the card', _greysNote)), hasLength(2));
      expect(taps.offered, isEmpty);
    });

    test('a card not found by the first photo stops the run (ruling P11)', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim, lose: (call, step, request) => call < 3);
      final taps = _Taps(sim);
      await expectLater(
          _calibration(kiosk, taps).run(_plan(_spyder)),
          throwsA(isA<CalibrationStopped>()
              .having((e) => e.message, 'message', 'the card was not found automatically: use Measure manually')));
      expect(kiosk.stepOf, ['Find the card', 'Find the card', 'Find the card']);
      expect(taps.offered, isEmpty);
    });

    test('a tapped matrix photo records method taps', () async {
      final sim = _sim(_classic);
      final kiosk = _Kiosk(sim,
          lose: (call, step, request) => step == 'Colour correction' && request.light == 'glare_free');
      final taps = _Taps(sim);
      final calibration = ColourCalibration(
          measure: kiosk.measure,
          taps: (photo, camera, reference) {
            taps.mix = _mixOf(kiosk.requests.last);
            return taps.call(photo, camera, reference);
          },
          progress: kiosk.report);
      final outcome = await calibration.run(_plan(_classic, neighbours: false));
      expect(taps.offered, hasLength(1));
      final last = kiosk.requests.length - 1;
      expect(taps.offered.single.$1, _Kiosk.photoOf(last));
      final byLight = {for (final f in outcome.fits) f.light: f};
      expect(byLight['all']!.measurement.method, 'auto');
      final tapped = byLight['glare_free']!;
      expect(tapped.shot.method, 'taps');
      // ruling P8: every field recorded for a tapped fit
      final m = tapped.measurement;
      final winner = outcome.mix.best;
      expect(m.method, 'taps');
      expect([m.ledRed, m.ledGreen, m.ledBlue], [winner.red, winner.green, winner.blue]);
      expect(m.whiteBalance, outcome.tint!.kelvin);
      expect(m.cardVersion, 'pre2014');
      expect(m.chart, 'classic');
      expect(m.camera, _middleCamera);
      expect(m.scoreAfter, tapped.fit.scoreAfter);
      // the run's exposure and camera, not the tap dialog's
      expect(tapped.shot.exposure, _cardExposure);
      expect(tapped.shot.camera, _middleCamera);
      expect(outcome.last, same(tapped.shot));
    });

    test('patches under 34 px count as a lost attempt (ruling P5)', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim, small: (call, step, request) => call == 0);
      await _calibration(kiosk, _Taps(sim)).run(_plan(_spyder, neighbours: false, glareFree: false));
      expect(kiosk.stepOf.take(3), ['Find the card', 'Find the card', 'LED mix']);
      expect(kiosk.progress, contains(('Find the card', refusalTooSmall)));
    });

    test('a first photo lost three times to the size rule stops with the too-small text', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim, small: (call, step, request) => call < 3);
      await expectLater(_calibration(kiosk, _Taps(sim)).run(_plan(_spyder)),
          throwsA(isA<CalibrationStopped>().having((e) => e.message, 'message', refusalTooSmall)));
      expect(kiosk.stepOf, ['Find the card', 'Find the card', 'Find the card']);
      // one attempt lost to "not found": the card was not found automatically
      final mixed = _Kiosk(sim, lose: (call, step, request) => call == 0, small: (call, step, request) => call < 3);
      await expectLater(_calibration(mixed, _Taps(sim)).run(_plan(_spyder)),
          throwsA(isA<CalibrationStopped>().having((e) => e.message, 'message', cardNotFoundAutomatically)));
    });

    test('a photo that cannot be scored counts as a lost attempt', () async {
      final sim = _sim(_spyder);
      var mixCalls = 0;
      final kiosk = _Kiosk(sim, unreadable: (call, step, request) => step == 'LED mix' && ++mixCalls == 3);
      final outcome =
          await _calibration(kiosk, _Taps(sim)).run(_plan(_spyder, neighbours: false, glareFree: false));
      expect(kiosk.stepOf.where((s) => s == 'LED mix'), hasLength(outcome.mix.photos + 1));
      expect(kiosk.progress, contains(('LED mix', _hold)));
    });

    test('the white clipped note stops the run', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim, clippedNoteAt: 1);
      final taps = _Taps(sim);
      await expectLater(
          _calibration(kiosk, taps).run(_plan(_spyder)),
          throwsA(isA<CalibrationStopped>().having((e) => e.message, 'message', refusalWhiteClipped)));
      expect(kiosk.requests, hasLength(2));
      expect(taps.offered, isEmpty);
    });

    test('cancel stops after the call in flight and writes nothing', () async {
      // the run holds no settings client: nothing can be written before Save
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim);
      final calibration = _calibration(kiosk, _Taps(sim));
      kiosk.onCall = (call) {
        if (call == 5) calibration.cancel();
      };
      await expectLater(calibration.run(_plan(_spyder)), throwsA(isA<CalibrationCancelled>()));
      expect(kiosk.requests, hasLength(6));
      expect(kiosk.ended, 5, reason: 'the call in flight ended before the run stopped');
    });

    test('a cancel before the run is not lost', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim);
      final calibration = _calibration(kiosk, _Taps(sim))..cancel();
      await expectLater(calibration.run(_plan(_spyder)), throwsA(isA<CalibrationCancelled>()));
      expect(kiosk.requests, isEmpty);
    });

    test('cancel in the taps stops the run', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim, lose: (call, step, request) => step == 'LED mix');
      final taps = _Taps(sim, cancel: true);
      await expectLater(_calibration(kiosk, taps).run(_plan(_spyder)), throwsA(isA<CalibrationCancelled>()));
      expect(kiosk.requests, hasLength(4)); // the card found, then three lost mix photos
      expect(taps.offered, hasLength(1));
    });

    test('unreadable taps stop the run', () async {
      final sim = _sim(_spyder);
      // the card found, then lost for the first LED-mix photo
      final kiosk = _Kiosk(sim, lose: (call, step, request) => step == 'LED mix');
      final taps = _Taps(sim, unreadable: true);
      await expectLater(_calibration(kiosk, taps).run(_plan(_spyder)),
          throwsA(isA<CalibrationStopped>().having((e) => e.message, 'message', tapsUnreadable)));
      expect(kiosk.stepOf, ['Find the card', 'LED mix', 'LED mix', 'LED mix']);
      expect(taps.offered, hasLength(1));
    });

    test('the tint step is skipped with automatic white balance', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim);
      final outcome = await _calibration(kiosk, _Taps(sim)).run(_plan(_spyder, auto: true));
      expect(outcome.tint, isNull);
      expect(outcome.tintSkipped,
          "the camera's white balance is automatic: the glare-free white balance is not used");
      expect(kiosk.stepOf, isNot(contains('Glare-free tint')));
      expect(kiosk.requests.where((q) => q.hasWhiteBalance()), isEmpty);
      final glareFree = outcome.fits.singleWhere((f) => f.light == 'glare_free');
      expect(glareFree.measurement.whiteBalance, 0);
    });
  });

  group('save', () {
    late _Settings fake;
    late Server server;
    late ClientChannel channel;
    late SettingsClient settings;

    setUp(() async {
      fake = _Settings();
      server = await serveFakes([fake]);
      channel = ClientChannel('127.0.0.1',
          port: server.port!, options: const ChannelOptions(credentials: ChannelCredentials.insecure()));
      settings = SettingsClient(channel);
    });

    tearDown(() async {
      await channel.shutdown();
      await server.shutdown();
    });

    test('save writes in the spec order and only what changed', () async {
      // the mix moved in red and blue only, the white balance moved, two lights fitted
      final outcome = _outcome(best: const LedMix(214, 200, 182), kelvin: 4650, lights: ['all', 'glare_free']);
      final report = await saveCalibration(outcome, _kioskMix, 5000, settings: settings);
      expect(fake.calls, [
        'SetIntensityRed 214',
        'SetIntensityBlue 182',
        'SetGlareFreeWhiteBalance 4650',
        'SetColourCorrection all',
        'SetColourCorrection glare_free',
      ]);
      expect(report.failed, isNull);
      expect(report.error, isNull);
      expect(report.stored, [
        'LED red',
        'LED blue',
        'glare-free white balance',
        'colour correction Standard (all LEDs)',
        'colour correction Glare-free',
      ]);
      expect(fake.colour.first.matrix, outcome.fits.first.fit.matrix);
      expect(fake.colour.first.measurement, outcome.fits.first.measurement);

      // nothing moved: only the corrections are written
      fake.calls.clear();
      final kept = _outcome(best: _kioskMix, kelvin: 5000, lights: ['all']);
      await saveCalibration(kept, _kioskMix, 5000, settings: settings);
      expect(fake.calls, ['SetColourCorrection all']);
      // no tint step: no white balance write
      fake.calls.clear();
      await saveCalibration(_outcome(best: _kioskMix, lights: ['all']), _kioskMix, 0, settings: settings);
      expect(fake.calls, ['SetColourCorrection all']);
    });

    test('a light whose matrix would not improve is skipped, the rest saved (ruling P10)', () async {
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim,
          perfect: (call, step, request) => step == 'Colour correction' && request.light == 'neighbours');
      final outcome = await _calibration(kiosk, _Taps(sim)).run(_plan(_spyder));
      expect([for (final f in outcome.fits) f.light], ['all', 'glare_free']);
      expect(outcome.skipped, [(light: 'neighbours', reason: refusalNoImprovement)]);
      expect(outcome.mix.changed, isTrue);
      expect(outcome.tint, isNotNull);
      await saveCalibration(outcome, _kioskMix, 5000, settings: settings);
      expect(fake.calls.where((c) => c.startsWith('SetColourCorrection')),
          ['SetColourCorrection all', 'SetColourCorrection glare_free']);
      expect(fake.calls.where((c) => c.startsWith('SetIntensity')), isNotEmpty);

      // every ticked light skipped: the mix is still there and Save writes it
      fake.calls.clear();
      final none = _Kiosk(sim, perfect: (call, step, request) => step == 'Colour correction');
      final alone =
          await _calibration(none, _Taps(sim)).run(_plan(_spyder, neighbours: false, glareFree: false));
      expect(alone.fits, isEmpty);
      expect(alone.skipped, [(light: 'all', reason: refusalNoImprovement)]);
      expect(alone.mix.changed, isTrue);
      final report = await saveCalibration(alone, _kioskMix, 5000, settings: settings);
      expect(report.ok, isTrue);
      expect(fake.calls, isNotEmpty);
      expect(fake.calls.every((c) => c.startsWith('SetIntensity')), isTrue);
    });

    test('a matrix is saved only when no skin patch gets worse (skin weight 3, 6, 12, 24, 48)', () async {
      // the fixture's cases (tools/colorchecker/fixtures/colour_fit_cases.json): weight 3
      // gives 5H away but weight 6 does not; no weight keeps the skin
      final fixture = jsonDecode(File('$colorcheckerDir/fixtures/colour_fit_cases.json')
          .readAsStringSync()) as Map<String, dynamic>;
      List<List<double>> patches(String name) => [
            for (final row in (fixture['cases'] as List)
                .cast<Map<String, dynamic>>()
                .firstWhere((c) => c['name'] == name)['measured_srgb8'] as List)
              [for (final v in row as List) (v as num).toDouble()],
          ];
      final kept = patches('skin kept at weight 6'), none = patches('skin worse at every weight');
      final sim = _sim(_spyder);
      final kiosk = _Kiosk(sim, patchesOf: (call, step, request) {
        if (step != 'Colour correction') return null;
        return switch (request.light) { 'all' => kept, 'neighbours' => none, _ => null };
      });
      final outcome = await _calibration(kiosk, _Taps(sim)).run(_plan(_spyder));
      expect([for (final f in outcome.fits) f.light], ['all', 'glare_free']);
      expect(outcome.skipped, [(light: 'neighbours', reason: refusalSkinWorse)]);
      final all = outcome.fits.first;
      expect(all.fit.skinWeight, 6);
      // the score recorded at the standard weights (skin 3), whatever weight the fit used
      expect(all.measurement.scoreAfter, weightedScore(all.fit.deAfter, _spyder.weights, List.filled(24, true)));
      final plain = fitColourMatrix(kept, List.filled(24, true), reference: _spyder);
      expect(plain.scoreAfter, lessThan(plain.scoreBefore)); // the old rule would have saved weight 3
      expect(all.fit.matrix, isNot(plain.matrix));
    });

    test('a write failure stops and reports what was stored', () async {
      fake.failWhiteBalance = 1;
      final outcome = _outcome(best: const LedMix(214, 205, 160), kelvin: 4650, lights: ['all']);
      final report = await saveCalibration(outcome, _kioskMix, 5000, settings: settings);
      expect(report.stored, ['LED red', 'LED green', 'LED blue']);
      expect(report.failed, 'glare-free white balance');
      expect(report.error, contains('the board did not answer'));
      expect(fake.calls, ['SetIntensityRed 214', 'SetIntensityGreen 205', 'SetIntensityBlue 160', 'SetGlareFreeWhiteBalance 4650']);

      // Retry resumes from the failed write
      fake.calls.clear();
      final retry = await saveCalibration(outcome, _kioskMix, 5000, settings: settings, resume: report);
      expect(fake.calls, ['SetGlareFreeWhiteBalance 4650', 'SetColourCorrection all']);
      expect(retry.failed, isNull);
      expect(retry.stored,
          ['LED red', 'LED green', 'LED blue', 'glare-free white balance', 'colour correction Standard (all LEDs)']);
    });
  });

  group('the probe (R2)', () {
    Future<ColourCardAvailability> probe(List<Service> services) async {
      final server = await serveFakes(services);
      final channel = ClientChannel('127.0.0.1',
          port: server.port!, options: const ChannelOptions(credentials: ChannelCredentials.insecure()));
      try {
        return await colourCardAvailable(KioskClient(channel));
      } finally {
        await channel.shutdown();
        await server.shutdown();
      }
    }

    test('the probe: available on INVALID_ARGUMENT, not on UNIMPLEMENTED, unknown on a failure', () async {
      final refusing = _ProbeKiosk(GrpcError.invalidArgument("colour card light must be all, neighbours or glare_free, not ''"));
      expect(await probe([refusing]), ColourCardAvailability.available);
      expect(refusing.requests.single.light, '');
      // the stand-in: UNIMPLEMENTED, an older server
      expect(await probe([]), ColourCardAvailability.unavailable);
      expect(await probe([_ProbeKiosk(GrpcError.unimplemented('colour card finding is not available on this server'))]),
          ColourCardAvailability.unavailable);
      // a reply (the server took light "" as valid): it does not follow R2, so not available
      expect(await probe([_ProbeKiosk(null)]), ColourCardAvailability.unavailable);
      // a failure says nothing about the card finder: unknown (the card probes again later)
      expect(await probe([_ProbeKiosk(GrpcError.internal('boom'))]), ColourCardAvailability.unknown);
      expect(await probe([_ProbeKiosk(GrpcError.unavailable('the kiosk did not answer'))]), ColourCardAvailability.unknown);
      expect(await probe([_ProbeKiosk(GrpcError.deadlineExceeded('Deadline exceeded'))]), ColourCardAvailability.unknown);
    });
  });

  group('the card preferences', () {
    late Directory dir;
    late String savedCard, savedVersion;

    setUp(() {
      savedCard = AppConfig.colourCard;
      savedVersion = AppConfig.colourCardVersion;
      dir = Directory.systemTemp.createTempSync('operator_colour_card_test');
      AppConfig.appDataDirOverride = dir.path;
    });

    tearDown(() {
      AppConfig.colourCard = savedCard;
      AppConfig.colourCardVersion = savedVersion;
      AppConfig.appDataDirOverride = null;
      dir.deleteSync(recursive: true);
    });

    test('the card preferences round-trip in config.json', () async {
      expect(savedCard, 'spyder24');
      expect(savedVersion, 'pre2014');
      AppConfig.colourCard = 'classic';
      AppConfig.colourCardVersion = '2014';
      await AppConfig.save();
      final json = jsonDecode(File('${dir.path}${Platform.pathSeparator}config.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(json['colour_card'], 'classic');
      expect(json['colour_card_version'], '2014');
      AppConfig.colourCard = 'spyder24';
      AppConfig.colourCardVersion = 'pre2014';
      await AppConfig.load();
      expect(AppConfig.colourCard, 'classic');
      expect(AppConfig.colourCardVersion, '2014');
      // a value the app does not know is not taken
      File('${dir.path}${Platform.pathSeparator}config.json')
          .writeAsStringSync(jsonEncode({'colour_card': 'macbeth', 'colour_card_version': '2020'}));
      await AppConfig.load();
      expect(AppConfig.colourCard, 'classic');
      expect(AppConfig.colourCardVersion, '2014');
    });
  });
}

/// A finished run with [lights] fitted on simulated photos at [best].
CalibrationOutcome _outcome({required LedMix best, int? kelvin, required List<String> lights}) {
  final sim = _sim(_spyder);
  LightFit fit(String light) {
    final p = sim.photo(best);
    final f = fitColourMatrix(p.srgb8, [for (final c in p.clipped) !c], reference: _spyder);
    final shot = CardShot(
      srgb8: p.srgb8,
      clipped: p.clipped,
      patchSizePx: 60,
      photo: Uint8List.fromList([1]),
      centres: const [],
      exposure: _cardExposure,
      camera: _middleCamera,
      method: 'auto',
    );
    return LightFit(
      light: light,
      fit: f,
      shot: shot,
      measurement: ColourMeasurement(
          measured: '2026-11-03T10:00:00Z',
          camera: _middleCamera,
          chart: 'spyder24',
          meanDeBefore: f.meanDeBefore,
          meanDeAfter: f.meanDeAfter,
          method: 'auto',
          ledRed: best.red,
          ledGreen: best.green,
          ledBlue: best.blue,
          scoreAfter: f.scoreAfter,
          whiteBalance: light == 'glare_free' ? kelvin ?? 0 : 0),
    );
  }

  final fits = [for (final l in lights) fit(l)];
  return CalibrationOutcome(
    mix: MixSearchResult(
      start: _kioskMix,
      best: best,
      changed: best != _kioskMix,
      brightnessChangePercent: brightnessChangePercent(_kioskMix, best),
      scoreStart: 2,
      scoreBest: 1,
      margin: 0.15,
      photos: 10,
    ),
    tint: kelvin == null
        ? null
        : TintResult(start: 5000, kelvin: kelvin, deltaB: 0.4, deltaA: -0.2, photos: 3),
    fits: fits,
    last: fits.last.shot,
  );
}

class _Settings extends SettingsServiceBase {
  final List<String> calls = [];
  final List<ColourCorrectionRequest> colour = [];

  /// The SetGlareFreeWhiteBalance calls that fail, from the first.
  int failWhiteBalance = 0;

  Future<IntensityResponse> _intensity(String name, IntensityRequest request) async {
    calls.add('$name ${request.value}');
    return IntensityResponse(message: request.value);
  }

  @override
  Future<IntensityResponse> setIntensityRed(ServiceCall call, IntensityRequest request) =>
      _intensity('SetIntensityRed', request);

  @override
  Future<IntensityResponse> setIntensityGreen(ServiceCall call, IntensityRequest request) =>
      _intensity('SetIntensityGreen', request);

  @override
  Future<IntensityResponse> setIntensityBlue(ServiceCall call, IntensityRequest request) =>
      _intensity('SetIntensityBlue', request);

  @override
  Future<GlareFreeWhiteBalanceResponse> setGlareFreeWhiteBalance(
      ServiceCall call, GlareFreeWhiteBalanceRequest request) async {
    calls.add('SetGlareFreeWhiteBalance ${request.value}');
    if (failWhiteBalance > 0) {
      failWhiteBalance--;
      throw GrpcError.internal('the board did not answer');
    }
    return GlareFreeWhiteBalanceResponse(message: request.value);
  }

  @override
  Future<ColourCorrectionResponse> setColourCorrection(ServiceCall call, ColourCorrectionRequest request) async {
    calls.add('SetColourCorrection ${request.light}');
    colour.add(request);
    return ColourCorrectionResponse(
        state: ColourCorrectionState(
            light: request.light, matrix: request.matrix, source: 'kiosk', measurement: request.measurement));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

/// A kiosk whose MeasureColourCard answers [error] (null: an answer).
class _ProbeKiosk extends KioskServiceBase {
  _ProbeKiosk(this.error);

  final GrpcError? error;
  final List<ColourCardRequest> requests = [];

  @override
  Future<ColourCardResponse> measureColourCard(ServiceCall call, ColourCardRequest request) async {
    requests.add(request);
    if (error != null) throw error!;
    return ColourCardResponse(found: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw GrpcError.unimplemented('${invocation.memberName}');
}

