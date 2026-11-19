// The photo store keeps the last ten captures and can be cleared (2026-10-06).
// FL-11: the files land INSIDE the captures folder on every platform (a
// hard-coded backslash made them strays in the parent folder on macOS/Linux,
// which the trim never saw), and those strays are cleaned up at load.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/app_config.dart';
import 'package:operator_app/services/photo_store.dart';

final sep = Platform.pathSeparator;
String get capturesDir => '${AppConfig.appDataDir}${sep}captures';

/// Waits until the fire-and-forget persist has written an index.json that
/// lists [file] (the index is the last thing a persist writes).
Future<void> persistedWith(String file) async {
  final index = File('$capturesDir${sep}index.json');
  for (var i = 0; i < 200; i++) {
    if (index.existsSync()) {
      try {
        final entries = jsonDecode(index.readAsStringSync()) as List<dynamic>;
        if (entries.any((e) => e['file'] == file)) return;
      } on FormatException {
        // being written
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('no persisted index.json listing $file');
}

/// The file names directly in [dir].
List<String> namesIn(String dir) => [
      for (final e in Directory(dir).listSync())
        if (e is File) e.uri.pathSegments.last,
    ];

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

  test('a capture is written inside the captures folder', () async {
    PhotoStore.addCapture([(0, Uint8List.fromList([1])), (2, Uint8List.fromList([2]))]);
    final c = PhotoStore.photos.last.capture; // the sequence spans the tests
    await persistedWith('capture${c}_cam2.jpg');

    expect(File('$capturesDir${sep}capture${c}_cam0.jpg').existsSync(), isTrue);
    expect(File('$capturesDir${sep}capture${c}_cam2.jpg').existsSync(), isTrue);
    expect(namesIn(AppConfig.appDataDir).where((n) => n.endsWith('.jpg')), isEmpty,
        reason: 'no stray photo next to the captures folder');
  });

  test('the trim deletes the files of a dropped capture', () async {
    final names = <String>[];
    for (var i = 0; i <= PhotoStore.keepCaptures; i++) {
      PhotoStore.addCapture([(0, Uint8List.fromList([i]))]);
      names.add('capture${PhotoStore.photos.last.capture}_cam0.jpg');
      await persistedWith(names.last);
    }
    final onDisk = namesIn(capturesDir);
    expect(onDisk, isNot(contains(names.first)), reason: 'the 11th capture drops the 1st');
    expect(onDisk, containsAll(names.skip(1)));
    expect(onDisk.where((n) => n.endsWith('.jpg')), hasLength(PhotoStore.keepCaptures));
    expect(namesIn(AppConfig.appDataDir).where((n) => n.endsWith('.jpg')), isEmpty);
  });

  test('the persisted captures load back', () async {
    PhotoStore.addCapture([(3, Uint8List.fromList([7, 8]))]);
    final capture = PhotoStore.photos.last.capture;
    await persistedWith('capture${capture}_cam3.jpg');
    PhotoStore.photos.clear();

    await PhotoStore.load();
    expect(PhotoStore.photos, hasLength(1));
    expect(PhotoStore.photos.single.cameraIndex, 3);
    expect(PhotoStore.photos.single.bytes, [7, 8]);
  });

  test('load removes the strays an older version left next to the folder',
      () async {
    // What the backslash join produced on macOS/Linux: a file in the PARENT
    // folder whose name starts with "captures\".
    final stray = File('${AppConfig.appDataDir}${sep}captures\\capture4_cam1.jpg')
      ..writeAsBytesSync([1]);
    final other = File('${AppConfig.appDataDir}${sep}config.json')
      ..writeAsStringSync('{}');

    await PhotoStore.load();
    expect(stray.existsSync(), isFalse);
    expect(other.existsSync(), isTrue, reason: 'only the strays go');
  }, skip: Platform.isWindows ? 'the backslash IS the separator on Windows' : false);
}
