// The compose image tag is the board server's version (there is no version
// inside the binary) — the parser must handle both server generations and
// refuse garbage rather than display it.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/board_server_manager.dart';

void main() {
  group('versionFromImageTag', () {
    test('Server 2.0 tag with architecture suffix', () {
      expect(BoardServerManager.versionFromImageTag('facesnap2:2.0.11-arm64'),
          '2.0.11');
    });

    test('first-generation tag', () {
      expect(
          BoardServerManager.versionFromImageTag('face_snap:1.4.0'), '1.4.0');
    });

    test('x64 suffix is stripped too', () {
      expect(BoardServerManager.versionFromImageTag('facesnap2:2.0.11-x64'),
          '2.0.11');
    });

    test('surrounding whitespace and trailing lines are ignored', () {
      expect(
          BoardServerManager.versionFromImageTag(
              '  facesnap2:2.0.11-arm64  \nsomething else\n'),
          '2.0.11');
    });

    test('no tag means no version', () {
      expect(BoardServerManager.versionFromImageTag(''), isNull);
      expect(BoardServerManager.versionFromImageTag('facesnap2'), isNull);
      expect(BoardServerManager.versionFromImageTag('facesnap2:'), isNull);
      expect(BoardServerManager.versionFromImageTag(':2.0.11'), isNull);
    });
  });

  group('validatePasswordChange', () {
    test('accepts a valid change', () {
      expect(BoardServerManager.validatePasswordChange('old', 'newpass', 'newpass'),
          isNull);
    });

    test('current password required', () {
      expect(BoardServerManager.validatePasswordChange('', 'newpass', 'newpass'),
          contains('current'));
    });

    test('new password required', () {
      expect(
          BoardServerManager.validatePasswordChange('old', '', ''), contains('new password'));
    });

    test('new password minimum length', () {
      expect(BoardServerManager.validatePasswordChange('old', 'abc', 'abc'),
          contains('4 characters'));
    });

    test('repeat must match', () {
      expect(BoardServerManager.validatePasswordChange('old', 'newpass', 'newpas'),
          contains('do not match'));
    });

    test('new must differ from current', () {
      expect(BoardServerManager.validatePasswordChange('samepass', 'samepass', 'samepass'),
          contains('same'));
    });
  });
}
