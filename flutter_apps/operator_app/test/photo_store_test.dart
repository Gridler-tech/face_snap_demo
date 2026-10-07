// The photo store keeps the last ten captures and can be cleared (2026-10-06).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/app_config.dart';
import 'package:operator_app/services/photo_store.dart';

void main() {
  setUp(() {
    AppConfig.appDataDirOverride =
        Directory.systemTemp.createTempSync('facesnap-photo-store').path;
    PhotoStore.photos.clear();
  });

  test('the newest ten captures stay, older ones go', () {
    for (var i = 1; i <= 12; i++) {
      PhotoStore.addCapture([(0, Uint8List.fromList([i]))]);
    }
    expect(PhotoStore.photos.length, 10);
    expect(PhotoStore.photos.first.capture, 3);
    expect(PhotoStore.photos.last.capture, 12);
  });

  test('clear forgets every capture and bumps the revision', () {
    PhotoStore.addCapture([(0, Uint8List.fromList([1]))]);
    final before = PhotoStore.revision.value;
    PhotoStore.clear();
    expect(PhotoStore.photos, isEmpty);
    expect(PhotoStore.revision.value, before + 1);
    PhotoStore.clear();
    expect(PhotoStore.revision.value, before + 1, reason: 'nothing to clear: no change');
  });
}
