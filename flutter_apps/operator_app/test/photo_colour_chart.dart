// A synthetic, upright SpyderCheckr 24 for the Photo colour widget tests: 24
// squares on a dark background, drawn straight into RGBA (no JPEG decode), and
// the screen point of an image pixel in the measurement dialog's photo.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/photo_colour_measure_dialog.dart';
import 'package:operator_app/util/card_reference.dart';
import 'package:operator_app/util/colour_fit.dart';

class TestChart {
  TestChart(this.image, this.centres);

  final DecodedImage image;

  /// The patch centres, JSON order (1E..6E, 1F..6F, 1G..6G, 1H..6H).
  final List<Offset> centres;

  /// The centres of the corner patches 1E, 1H, 6H, 6E.
  List<Offset> get corners => [centres[0], centres[18], centres[23], centres[5]];
}

/// The SpyderCheckr 24 reference, read from the app's copy (the working directory
/// of `flutter test` is the package root).
final spyderReference = CardReference.fromJson(
    jsonDecode(File('assets/colour_cards/spyder24.json').readAsStringSync()) as Map<String, dynamic>);

/// The ColorChecker Classic reference in [version], read from the app's copy.
CardReference classicReference([String version = 'pre2014']) => CardReference.fromJson(
    jsonDecode(File('assets/colour_cards/classic.json').readAsStringSync()) as Map<String, dynamic>,
    version: version);

/// [reference]'s colours (the SpyderCheckr's by default) through a channel crosstalk that
/// keeps greys grey (each row sums to 1), as sRGB bytes: a camera whose colours a matrix
/// can improve. The Classic's patches sit in the same cells (k = across × 6 + along).
List<List<int>> castColours([CardReference? reference]) => [
      for (final lab in (reference ?? spyderReference).lab)
        () {
          final lin = labD50ToLinearSrgb(lab);
          const cast = [
            [0.80, 0.15, 0.05],
            [0.05, 0.85, 0.10],
            [0.05, 0.20, 0.75],
          ];
          return [
            for (final row in cast)
              (linearToSrgb((row[0] * lin[0] + row[1] * lin[1] + row[2] * lin[2]).clamp(0.0, 1.0)) *
                      255)
                  .round()
                  .clamp(0, 255),
          ];
        }(),
    ];

/// An upright chart (column E on the left, row 1 at the top), centre spacing
/// [spacing] px, in a [width] x [height] image.
TestChart testChart({
  List<List<int>>? colours,
  int width = 320,
  int height = 400,
  double spacing = 40,
}) {
  final rgb = colours ?? castColours();
  final cx = width / 2, cy = height / 2;
  final half = spacing * 25 / 28 / 2;
  final centres = [
    for (var k = 0; k < 24; k++)
      Offset(cx + (k ~/ 6 - 1.5) * spacing, cy + (k % 6 - 2.5) * spacing),
  ];
  final rgba = Uint8List(width * height * 4);
  var i = 0;
  for (var py = 0; py < height; py++) {
    for (var px = 0; px < width; px++) {
      final x = px + 0.5 - cx, y = py + 0.5 - cy;
      final c = (x / spacing + 1.5).round(), r = (y / spacing + 2.5).round();
      var colour = const [20, 20, 22];
      if (c >= 0 &&
          c < 4 &&
          r >= 0 &&
          r < 6 &&
          (x - (c - 1.5) * spacing).abs() <= half &&
          (y - (r - 2.5) * spacing).abs() <= half) {
        colour = rgb[c * 6 + r];
      }
      rgba[i++] = colour[0];
      rgba[i++] = colour[1];
      rgba[i++] = colour[2];
      rgba[i++] = 255;
    }
  }
  return TestChart(DecodedImage(rgba, width, height), centres);
}

/// Taps the dialog's photo at the image pixel [pixel] (identity zoom).
Future<void> tapPhotoAt(WidgetTester tester, DecodedImage image, Offset pixel) async {
  final rect = tester.getRect(find.byKey(const ValueKey('photo-colour-photo')));
  await tester.tapAt(rect.topLeft +
      Offset(pixel.dx * rect.width / image.width, pixel.dy * rect.height / image.height));
  await tester.pump();
}
