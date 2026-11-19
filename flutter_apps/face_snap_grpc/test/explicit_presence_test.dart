// Tripwire for the RPC trace's explicit-presence table (rpc_trace.dart):
// every proto3 `optional` field of the generated stubs, and nothing else. The
// Dart stubs carry no presence marker at run time, so the table is written by
// hand; the descriptors in lib/src/generated/*.pbjson.dart mark such a field
// with '17': true (proto3_optional). A new `optional` field fails here until it
// is added to the table - otherwise copy-as-code would write its default.
import 'dart:convert';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:test/test.dart';

/// {qualified message name: {field numbers}} of the '17': true fields of one
/// generated pbjson file, nested messages included.
Map<String, Set<int>> _optionalFields(File file) {
  final package = file.uri.pathSegments.last.split('.').first;
  final text = file.readAsStringSync();
  final out = <String, Set<int>>{};

  void visit(Map<String, dynamic> message, String prefix) {
    final name = '$prefix.${message['1']}';
    for (final field in (message['2'] as List? ?? const [])) {
      if ((field as Map)['17'] == true) {
        out.putIfAbsent(name, () => <int>{}).add(field['3'] as int);
      }
    }
    for (final nested in (message['3'] as List? ?? const [])) {
      visit(nested as Map<String, dynamic>, name);
    }
  }

  // Top-level `const <Name>$json = {...};` literals: Dart map syntax that is
  // JSON once the quotes are double and the trailing commas gone.
  final literal = RegExp(r'^const \w+\$json = (\{.*?^\});', multiLine: true, dotAll: true);
  for (final m in literal.allMatches(text)) {
    final json = m
        .group(1)!
        .replaceAll('"', r'\"')
        .replaceAll("'", '"')
        .replaceAllMapped(RegExp(r',(\s*[}\]])'), (m) => m.group(1)!);
    final message = jsonDecode(json) as Map<String, dynamic>;
    final entries = message['2'] as List? ?? const [];
    final isEnum = entries.isNotEmpty && !(entries.first as Map).containsKey('3');
    if (!isEnum) visit(message, package);
  }
  return out;
}

void main() {
  test('the explicit-presence table is every proto3 optional field of the stubs', () {
    final files = Directory('lib/src/generated')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.pbjson.dart'))
        .toList();
    expect(files, hasLength(6));
    final found = <String, Set<int>>{};
    for (final f in files) {
      found.addAll(_optionalFields(f));
    }
    expect(found['lights.BacklightRequest'], {3}, reason: 'the parser finds a known one');
    // 28 = lap, a child on a parent's lap (spec 2026-10-19).
    expect(found['kiosk.CaptureSettings'], containsAll({27, 28}));
    expect(explicitPresenceFields, found);
  });
}
