// ColourCardRequest's optional fields keep their presence (MeasureColourCard, spec
// 2026-11-02 section 6): an unset led_mix / white_balance / exposure is absent on the wire
// (the server then uses its own default), while a field set to its default value - an
// all-zero LedMix, an exposure of 0 - is present and sent. No server: the messages are
// built and round-tripped through their wire form.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:test/test.dart';

void main() {
  test('unset optional fields are absent', () {
    final request = ColourCardRequest(light: 'all', card: 'spyder24');

    expect(request.hasLedMix(), isFalse);
    expect(request.hasWhiteBalance(), isFalse);
    expect(request.hasExposure(), isFalse);
  });

  test('an all-zero LedMix and an exposure of 0 are present', () {
    final request = ColourCardRequest(
        light: 'glare_free', card: 'classic', ledMix: LedMix(), exposure: 0);

    expect(request.hasLedMix(), isTrue);
    expect(request.ledMix.red, 0);
    expect(request.hasExposure(), isTrue);
    expect(request.exposure, 0);
    expect(request.hasWhiteBalance(), isFalse);
  });

  test('presence survives the wire', () {
    final bare = ColourCardRequest.fromBuffer(
        ColourCardRequest(light: 'all', card: 'spyder24', camera: 2)
            .writeToBuffer());
    expect(bare.camera, 2);
    expect(bare.hasLedMix(), isFalse);
    expect(bare.hasWhiteBalance(), isFalse);
    expect(bare.hasExposure(), isFalse);

    final set = ColourCardRequest.fromBuffer(ColourCardRequest(
            light: 'all',
            card: 'spyder24',
            ledMix: LedMix(),
            whiteBalance: 0,
            exposure: 0)
        .writeToBuffer());
    expect(set.hasLedMix(), isTrue);
    expect(set.hasWhiteBalance(), isTrue);
    expect(set.hasExposure(), isTrue);
  });

  test('clearing a field makes it absent again', () {
    final request = ColourCardRequest(whiteBalance: 5750, exposure: 118);
    request.clearExposure();

    expect(request.hasWhiteBalance(), isTrue);
    expect(request.whiteBalance, 5750);
    expect(request.hasExposure(), isFalse);
  });

  test('the measurement carries the new fields', () {
    final measurement = ColourMeasurement.fromBuffer(ColourMeasurement(
            method: 'auto',
            ledRed: 180,
            ledGreen: 200,
            ledBlue: 160,
            scoreAfter: 1.9,
            whiteBalance: 5750,
            cardVersion: '2014')
        .writeToBuffer());

    expect(measurement.method, 'auto');
    expect([measurement.ledRed, measurement.ledGreen, measurement.ledBlue],
        [180, 200, 160]);
    expect(measurement.scoreAfter, 1.9);
    expect(measurement.whiteBalance, 5750);
    expect(measurement.cardVersion, '2014');
  });
}
