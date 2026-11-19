// The operator app works in a column session (spec 2026-10-10 sections 4.12 and 5.5): main()
// switches the header on before its first call, so its changes, the updater's included, wait
// for "Save as standard".
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main() switches the column-session header on before its first call', () {
    final source = File('lib/main.dart').readAsStringSync();
    final on = source.indexOf('GrpcChannelProvider.useColumnSession = true;');
    expect(on, greaterThan(0));
    expect(on, lessThan(source.indexOf('AppConfig.load()')));
    expect(on, lessThan(source.indexOf('GrpcChannelProvider.setAddress(')));
  });
}
