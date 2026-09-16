import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// One photo available for comparison: delivered by a capture on the Capture
/// page, or loaded from disk on the Face recognition page (then [label] holds
/// the file name and [capture] is 0).
class CapturedPhoto {
  CapturedPhoto(this.capture, this.cameraIndex, this.bytes, {this.label});

  /// 1-based capture sequence number (grows for the app's lifetime).
  final int capture;

  /// Calibrated camera index; 0 = the automatic-flow photo.
  final int cameraIndex;

  final Uint8List bytes;

  /// Display label overriding the capture/camera caption (disk photos).
  final String? label;
}

/// Photos from the most recent captures on the Capture page, shared with the
/// Face recognition page (the MAUI apps shared these via KioskViewModel).
/// Captures ACCUMULATE (up to the last [keepCaptures]) so two photos from
/// different captures can be compared — e.g. two automatic captures, which
/// deliver only one photo each — and are PERSISTED under
/// %APPDATA%\FaceSnapOperator\captures so they survive an app restart
/// (compare a fresh passport file against yesterday's capture).
class PhotoStore {
  PhotoStore._();

  static const keepCaptures = 3;

  /// Oldest capture first; newest photos at the end.
  static final List<CapturedPhoto> photos = [];

  /// Bumped on every change. Pages sitting unchanged in the nav's
  /// IndexedStack (const widgets are never rebuilt on a page switch) listen
  /// to this to re-read [photos] when a capture lands.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static int _captureSeq = 0;

  static Directory get _dir {
    final appData = Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        '.';
    return Directory('$appData\\FaceSnapOperator\\captures');
  }

  /// Append one capture's photos ((camera index, jpeg bytes); index 0 =
  /// automatic-flow photo) and drop captures beyond the newest [keepCaptures].
  static void addCapture(List<(int, Uint8List)> capture) {
    if (capture.isEmpty) {
      return;
    }
    _captureSeq++;
    photos.addAll([
      for (final (cameraIndex, bytes) in capture)
        CapturedPhoto(_captureSeq, cameraIndex, bytes),
    ]);
    final cutoff = _captureSeq - keepCaptures;
    photos.removeWhere((p) => p.capture <= cutoff);
    revision.value++;
    _persist();
  }

  /// Load the persisted captures (call once at app start; best-effort).
  static Future<void> load() async {
    try {
      final index = File('${_dir.path}\\index.json');
      if (!await index.exists()) return;
      final entries = jsonDecode(await index.readAsString()) as List<dynamic>;
      for (final e in entries) {
        final file = File('${_dir.path}\\${e['file']}');
        if (!await file.exists()) continue;
        photos.add(CapturedPhoto(e['capture'] as int, e['camera'] as int,
            await file.readAsBytes()));
      }
      if (photos.isNotEmpty) {
        _captureSeq = photos.map((p) => p.capture).reduce((a, b) => a > b ? a : b);
        revision.value++;
      }
    } catch (_) {
      // Corrupt/missing store: start empty.
      photos.clear();
    }
  }

  /// Rewrite the on-disk store to match [photos] (best-effort, fire-and-forget).
  static Future<void> _persist() async {
    try {
      final dir = _dir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);
      final index = <Map<String, dynamic>>[];
      for (final p in photos) {
        final name = 'capture${p.capture}_cam${p.cameraIndex}.jpg';
        await File('${dir.path}\\$name').writeAsBytes(p.bytes, flush: true);
        index.add({'capture': p.capture, 'camera': p.cameraIndex, 'file': name});
      }
      await File('${dir.path}\\index.json').writeAsString(jsonEncode(index));
    } catch (_) {
      // Persistence is a convenience; never let it break a capture.
    }
  }
}
