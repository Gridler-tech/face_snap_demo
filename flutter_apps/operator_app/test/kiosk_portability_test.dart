// The kiosk contract may only use commands present on EVERY supported board
// image. The first batch update of a Radxa Q6A died in "Provision kiosk
// identity" because its Arch-based image has no `hostname` binary (it lives
// in inetutils there) — and it died AFTER the compose file had been switched,
// leaving the kiosk stopped. `uname -n` is POSIX coreutils and returns the
// same value on both boards. This is the tripwire against "simplifying" it
// back.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/kiosk.dart';

void main() {
  test('the hostname is read with uname, never the hostname binary', () {
    expect(kHostnameCmd, startsWith('uname'));
    expect(kHostnameCmd, isNot(contains('hostname')));
  });
}
