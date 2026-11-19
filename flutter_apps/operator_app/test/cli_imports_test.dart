// The command-line tools in bin/ run with `dart run`, which has no dart:ui: no
// file they import (directly or through lib/) may import Flutter. The widget
// tests cannot notice this, because they run under Flutter.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _import = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// The lib/ or bin/ files [file] imports, as paths relative to the package root.
Iterable<String> _localImports(String file, String text) sync* {
  for (final m in _import.allMatches(text)) {
    final uri = m.group(1)!;
    if (uri.startsWith('package:operator_app/')) {
      yield 'lib/${uri.substring('package:operator_app/'.length)}';
    } else if (!uri.contains(':')) {
      yield File(file).parent.uri.resolve(uri).toFilePath().replaceAll(r'\', '/');
    }
  }
}

void main() {
  final tools = Directory('bin')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.replaceAll(r'\', '/'))
      .toList()
    ..sort();

  test('there are command-line tools to check', () {
    expect(tools, isNotEmpty);
  });

  for (final tool in tools) {
    test('$tool reaches no Flutter import', () {
      final root = Directory.current.path.replaceAll(r'\', '/');
      final seen = <String>{};
      final todo = [tool];
      final offenders = <String>[];
      while (todo.isNotEmpty) {
        var file = todo.removeLast();
        if (file.startsWith(root)) file = file.substring(root.length + 1);
        if (!seen.add(file)) continue;
        final text = File(file).readAsStringSync();
        for (final m in _import.allMatches(text)) {
          final uri = m.group(1)!;
          if (uri.startsWith('package:flutter/') || uri == 'dart:ui') {
            offenders.add('$file imports $uri');
          }
        }
        todo.addAll(_localImports(file, text));
      }
      expect(offenders, isEmpty, reason: 'dart run cannot load Flutter');
    });
  }
}
