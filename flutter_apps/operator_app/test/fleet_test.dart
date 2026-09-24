// A batch fleet is usually mixed: provisioned kiosks on the fleet password and
// addressed by name, clean vendor boards on their published default and
// addressed by IP. These lock that resolution, plus the rule that a re-scan
// never discards ticks or overrides the operator already made.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/discovery.dart';
import 'package:operator_app/updater/fleet.dart';

DiscoveredKiosk kiosk(String name, String ip) =>
    DiscoveredKiosk(hostName: name, ip: ip);

DiscoveredKiosk clean(String name, String ip) =>
    DiscoveredKiosk(hostName: name, ip: ip, kind: BoardKind.clean);

const _user = 'root';
const _pw = 'fleet-pw';

void main() {
  group('host resolution', () {
    test('a provisioned kiosk is addressed by name, not IP', () {
      // The name survives the DHCP moves that keep changing these addresses.
      final e = FleetEntry(kiosk: kiosk('facesnap-001e064358ca.local', '192.168.3.167'));
      expect(e.host, 'facesnap-001e064358ca.local');
      expect(e.isClean, isFalse);
    });

    test('a clean board is addressed by IP (no .local name yet)', () {
      final e = FleetEntry(kiosk: clean('odroid', '192.168.3.42'));
      expect(e.host, '192.168.3.42');
      expect(e.isClean, isTrue);
      expect(e.subtitle, contains('clean board'));
    });
  });

  group('credentialsFor', () {
    test('a provisioned kiosk uses the batch-wide credentials', () {
      final e = FleetEntry(kiosk: kiosk('facesnap-abc.local', '10.0.0.5'));
      final c = credentialsFor(e, defaultUser: _user, defaultPassword: _pw);
      expect(c.user, 'root');
      expect(c.password, _pw);
    });

    test('a clean Odroid uses its published vendor default', () {
      final e = FleetEntry(kiosk: clean('odroid', '10.0.0.6'));
      final c = credentialsFor(e, defaultUser: _user, defaultPassword: _pw);
      expect(c.user, 'root');
      expect(c.password, 'odroid');
    });

    test('a clean Radxa uses its own vendor default, not the Odroid one', () {
      final e = FleetEntry(kiosk: clean('radxa', '10.0.0.7'));
      final c = credentialsFor(e, defaultUser: _user, defaultPassword: _pw);
      expect(c.password, 'root');
    });

    test('an unknown clean board falls back to the batch password', () {
      final e = FleetEntry(kiosk: clean('mysteryboard', '10.0.0.8'));
      final c = credentialsFor(e, defaultUser: _user, defaultPassword: _pw);
      expect(c.password, _pw);
    });

    test('an explicit override wins over every default', () {
      final e = FleetEntry(kiosk: clean('odroid', '10.0.0.9'))
        ..userOverride = 'admin'
        ..passwordOverride = 'secret';
      final c = credentialsFor(e, defaultUser: _user, defaultPassword: _pw);
      expect(c.user, 'admin');
      expect(c.password, 'secret');
    });

    test('a password-only override keeps the default user', () {
      final e = FleetEntry(kiosk: kiosk('facesnap-abc.local', '10.0.0.10'))
        ..passwordOverride = 'other';
      final c = credentialsFor(e, defaultUser: _user, defaultPassword: _pw);
      expect(c.user, 'root');
      expect(c.password, 'other');
    });

    test('blank overrides are ignored, not used as empty credentials', () {
      final e = FleetEntry(kiosk: kiosk('facesnap-abc.local', '10.0.0.11'))
        ..userOverride = '  '
        ..passwordOverride = '';
      final c = credentialsFor(e, defaultUser: _user, defaultPassword: _pw);
      expect(c.user, 'root');
      expect(c.password, _pw);
    });
  });

  group('selectedTargets', () {
    test('only ticked boards, in listed order, labelled by name', () {
      final entries = [
        FleetEntry(kiosk: kiosk('a.local', '10.0.0.1'), selected: true),
        FleetEntry(kiosk: kiosk('b.local', '10.0.0.2')),
        FleetEntry(kiosk: clean('odroid', '10.0.0.3'), selected: true),
      ];
      final targets =
          selectedTargets(entries, defaultUser: _user, defaultPassword: _pw);
      expect(targets.map((t) => t.title), ['a.local', 'odroid']);
      // The clean board is REACHED by IP but still REPORTED by name.
      expect(targets[1].host, '10.0.0.3');
      expect(targets[1].label, 'odroid');
      expect(targets[1].password, 'odroid');
    });

    test('nothing ticked means nothing to run', () {
      final entries = [FleetEntry(kiosk: kiosk('a.local', '10.0.0.1'))];
      expect(selectedTargets(entries, defaultUser: _user, defaultPassword: _pw),
          isEmpty);
    });
  });

  group('mergeDiscovery', () {
    test('a re-scan keeps ticks and overrides of boards still present', () {
      final existing = [
        FleetEntry(kiosk: kiosk('a.local', '10.0.0.1'), selected: true)
          ..passwordOverride = 'custom',
        FleetEntry(kiosk: kiosk('b.local', '10.0.0.2')),
      ];
      final merged = mergeDiscovery(existing, [
        kiosk('a.local', '10.0.0.99'), // same board, new address
        kiosk('b.local', '10.0.0.2'),
      ]);
      final a = merged.firstWhere((e) => e.kiosk.hostName == 'a.local');
      expect(a.selected, isTrue, reason: 'the tick survives a re-scan');
      expect(a.passwordOverride, 'custom');
      expect(a.kiosk.ip, '10.0.0.99', reason: 'the address is refreshed');
      expect(merged.firstWhere((e) => e.kiosk.hostName == 'b.local').selected,
          isFalse);
    });

    test('a newly appeared board starts unticked', () {
      final merged = mergeDiscovery(
        [FleetEntry(kiosk: kiosk('a.local', '10.0.0.1'), selected: true)],
        [kiosk('a.local', '10.0.0.1'), kiosk('new.local', '10.0.0.3')],
      );
      expect(merged, hasLength(2));
      expect(merged.firstWhere((e) => e.kiosk.hostName == 'new.local').selected,
          isFalse);
    });

    test('a board that vanished from the network drops out', () {
      final merged = mergeDiscovery(
        [
          FleetEntry(kiosk: kiosk('a.local', '10.0.0.1'), selected: true),
          FleetEntry(kiosk: kiosk('gone.local', '10.0.0.2'), selected: true),
        ],
        [kiosk('a.local', '10.0.0.1')],
      );
      expect(merged.map((e) => e.kiosk.hostName), ['a.local']);
    });

    test('merging into an empty list is just the discovery', () {
      final merged = mergeDiscovery([], [kiosk('a.local', '10.0.0.1')]);
      expect(merged, hasLength(1));
      expect(merged.single.selected, isFalse);
    });
  });
}
