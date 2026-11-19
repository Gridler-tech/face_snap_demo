// The Face recognition page's calibrated thresholds (measured 2026-10-04 with
// the servers' face-first comparison): the table itself, that euclidean L2
// follows cosine, and that the slider can reach every calibrated value. The
// page offers Dlib and SFace only: Facenet512 is retired (the servers refuse it).
import 'dart:math' as math;

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/pages/face_recognition_page.dart';

void main() {
  const models = [Model.DLIB, Model.SFACE];
  const metrics = [
    DistanceMetric.COSINE,
    DistanceMetric.EUCLIDEAN,
    DistanceMetric.EUCLIDEAN_L2
  ];

  test('the calibrated thresholds are the measured ones', () {
    final expected = {
      Model.DLIB: [0.07, 0.54, 0.38],
      Model.SFACE: [0.45, 6.5, 0.95],
    };
    for (final model in models) {
      for (var i = 0; i < metrics.length; i++) {
        expect(faceRecognitionThresholdSpec(model, metrics[i]).calibrated,
            expected[model]![i],
            reason: '$model ${metrics[i]}');
      }
    }
  });

  testWidgets('the page opens on SFace with its calibrated threshold, Dlib and SFace offered',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: FaceRecognitionPage()))));
    final model = tester.widget<DropdownMenu<Model>>(
        find.byWidgetPredicate((w) => w is DropdownMenu<Model>));
    expect(model.initialSelection, Model.SFACE);
    expect(model.dropdownMenuEntries.map((e) => (e.value, e.label)),
        [(Model.DLIB, 'Dlib'), (Model.SFACE, 'SFace')]);
    expect(find.text('Threshold 0.45'), findsOneWidget);
    expect(find.text('calibrated default 0.45'), findsOneWidget);
  });

  test('euclidean L2 judges like cosine: sqrt(2 x cosine)', () {
    for (final model in models) {
      final cosine =
          faceRecognitionThresholdSpec(model, DistanceMetric.COSINE).calibrated;
      final l2 = faceRecognitionThresholdSpec(model, DistanceMetric.EUCLIDEAN_L2)
          .calibrated;
      expect(l2, closeTo(math.sqrt(2 * cosine), 0.011), reason: '$model');
    }
  });

  test('the slider reaches every calibrated value with room on both sides', () {
    for (final model in models) {
      for (final metric in metrics) {
        final spec = faceRecognitionThresholdSpec(model, metric);
        expect(spec.calibrated, greaterThan(0.01), reason: '$model $metric');
        expect(spec.max, greaterThanOrEqualTo(spec.calibrated * 1.9),
            reason: '$model $metric');
        expect(spec.max, lessThanOrEqualTo(spec.calibrated * 3),
            reason: '$model $metric');
      }
    }
  });
}
