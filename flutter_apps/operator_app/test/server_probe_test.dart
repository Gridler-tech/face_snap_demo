// What a server-list row says, given what the probe learned. Pure, so every
// combination is covered without a network: clean boards never claim a
// server, "connected" is reserved for the CURRENT host, and a stopped server
// explains itself instead of a bare "no answer".
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/board_server_manager.dart';
import 'package:operator_app/services/discovery.dart';
import 'package:operator_app/services/server_probe.dart';

const _up = ServerSnapshot(
    answering: true,
    cameras: 6,
    version: '2.0.11',
    running: true,
    model: 'Hardkernel ODROID-N2Plus');

void main() {
  group('rowStatus', () {
    test('a clean board has no server, whatever the probe says', () {
      expect(
          rowStatus(kind: BoardKind.clean, isCurrent: false, snapshot: _up),
          ServerRowStatus.noServer);
      expect(
          rowStatus(kind: BoardKind.clean, isCurrent: true, snapshot: null),
          ServerRowStatus.noServer);
    });

    test('no snapshot yet means probing', () {
      expect(
          rowStatus(
              kind: BoardKind.facesnap, isCurrent: false, snapshot: null),
          ServerRowStatus.probing);
    });

    test('the current host that answers is connected', () {
      expect(
          rowStatus(kind: BoardKind.facesnap, isCurrent: true, snapshot: _up),
          ServerRowStatus.connected);
    });

    test('another answering server is switchable, not connected', () {
      expect(
          rowStatus(kind: BoardKind.facesnap, isCurrent: false, snapshot: _up),
          ServerRowStatus.answering);
    });

    test('the current host that stopped answering is NOT still connected',
        () {
      const down = ServerSnapshot(answering: false, error: 'timed out');
      expect(
          rowStatus(kind: BoardKind.facesnap, isCurrent: true, snapshot: down),
          ServerRowStatus.notAnswering);
    });
  });

  group('rowStatusLabel', () {
    test('every status has a distinct label', () {
      final labels = ServerRowStatus.values.map(rowStatusLabel).toSet();
      expect(labels, hasLength(ServerRowStatus.values.length));
    });
  });

  group('rowDetail', () {
    test('an answering server lists version, cameras and model', () {
      expect(rowDetail(ServerRowStatus.answering, _up),
          '2.0.11 · 6 cameras · Hardkernel ODROID-N2Plus');
    });

    test('omits what is unknown without dangling separators', () {
      const partial = ServerSnapshot(answering: true, cameras: 4);
      expect(rowDetail(ServerRowStatus.answering, partial), '4 cameras');
      const bare = ServerSnapshot(answering: true);
      expect(rowDetail(ServerRowStatus.answering, bare), '');
    });

    test('a stopped server says so rather than a generic no-answer', () {
      const stopped =
          ServerSnapshot(answering: false, running: false, error: 'timed out');
      expect(rowDetail(ServerRowStatus.notAnswering, stopped),
          'server stopped');
    });

    test('a failed probe shows its reason', () {
      const down = ServerSnapshot(answering: false, error: 'timed out');
      expect(rowDetail(ServerRowStatus.notAnswering, down), 'timed out');
    });

    test('a clean board points at the Updater', () {
      expect(rowDetail(ServerRowStatus.noServer, null), contains('Updater'));
    });

    test('probing has nothing to say yet', () {
      expect(rowDetail(ServerRowStatus.probing, null), '');
    });
  });

  group('parseBoardDetails', () {
    test('parses the three KEY=value lines', () {
      final d = parseBoardDetails('IMAGE=facesnap2:2.0.11-arm64\n'
          'ACTIVE=active\n'
          'MODEL=Radxa Dragon Q6A\n');
      expect(d.version, '2.0.11');
      expect(d.running, isTrue);
      expect(d.model, 'Radxa Dragon Q6A');
    });

    test('an inactive service reads as not running', () {
      final d = parseBoardDetails('IMAGE=facesnap2:2.0.10-arm64\n'
          'ACTIVE=inactive\nMODEL=X\n');
      expect(d.running, isFalse);
    });

    test('activating counts as running (the server is coming up)', () {
      expect(parseBoardDetails('ACTIVE=activating\n').running, isTrue);
    });

    test('missing facts are null, not empty strings', () {
      // A clean board: no compose file, no unit, model present.
      final d = parseBoardDetails('IMAGE=\nACTIVE=\nMODEL=Hardkernel ODROID-N2Plus\n');
      expect(d.version, isNull);
      expect(d.running, isNull);
      expect(d.model, 'Hardkernel ODROID-N2Plus');
    });

    test('garbage lines are ignored', () {
      final d = parseBoardDetails('noise\nIMAGE=face_snap:1.4.0\n=bad\n');
      expect(d.version, '1.4.0');
    });
  });
}
