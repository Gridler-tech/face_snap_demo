// Turning discovered boards into a fleet the batch runner can act on.
//
// A batch is usually mixed: provisioned kiosks answer for their .local name and
// use the fleet password, while a clean vendor board has no name registered yet
// (connect by IP) and still carries its published vendor default. So each entry
// starts from sensible defaults and may override user/password per board.
//
// Pure (discovery + batch_runner only, no Flutter, no SSH) so the credential
// and host resolution is unit-tested without a board.
import 'batch_runner.dart';
import '../services/discovery.dart';

/// One board offered in the fleet picker: what was discovered, whether it is
/// ticked, and any per-board credential override the operator typed.
class FleetEntry {
  FleetEntry({required this.kiosk, this.selected = false});

  final DiscoveredKiosk kiosk;
  bool selected;

  /// null = use the batch-wide value (see [credentialsFor]).
  String? userOverride;
  String? passwordOverride;

  bool get isClean => kiosk.kind == BoardKind.clean;

  /// How to reach this board. A clean board has not registered a .local name
  /// yet, so it must be reached by IP; a provisioned kiosk is addressed by
  /// name, which survives the DHCP lease changes that move its address.
  String get host => isClean ? kiosk.ip : kiosk.hostName;

  /// What the picker shows: the name, plus the IP when that is not the host.
  String get title => kiosk.hostName;
  String get subtitle =>
      isClean ? '${kiosk.ip} — clean board, will be fully set up' : kiosk.ip;
}

/// The credentials to use for [entry]: an explicit override wins; otherwise a
/// clean vendor board uses root + its published default password, and a
/// provisioned kiosk uses the batch-wide credentials.
({String user, String password}) credentialsFor(
  FleetEntry entry, {
  required String defaultUser,
  required String defaultPassword,
}) {
  final user = entry.userOverride?.trim();
  final password = entry.passwordOverride;
  if (user != null && user.isNotEmpty && password != null && password.isNotEmpty) {
    return (user: user, password: password);
  }
  final vendor = entry.isClean ? cleanBoardDefaults[entry.kiosk.hostName] : null;
  return (
    user: (user != null && user.isNotEmpty)
        ? user
        : (entry.isClean ? 'root' : defaultUser),
    password: (password != null && password.isNotEmpty)
        ? password
        : (vendor ?? defaultPassword),
  );
}

/// [entry] as a batch target. The label is always the discovered name, so the
/// report reads by name even for a clean board addressed by IP.
BatchTarget targetFor(
  FleetEntry entry, {
  required String defaultUser,
  required String defaultPassword,
}) {
  final creds = credentialsFor(entry,
      defaultUser: defaultUser, defaultPassword: defaultPassword);
  return BatchTarget(
    host: entry.host,
    user: creds.user,
    password: creds.password,
    label: entry.kiosk.hostName,
  );
}

/// The ticked boards, in the order they are listed.
List<BatchTarget> selectedTargets(
  List<FleetEntry> entries, {
  required String defaultUser,
  required String defaultPassword,
}) =>
    [
      for (final e in entries.where((e) => e.selected))
        targetFor(e,
            defaultUser: defaultUser, defaultPassword: defaultPassword),
    ];

/// Merge a fresh discovery into the current list, KEEPING the ticks and
/// overrides of boards that are still present. A re-scan during selection must
/// not silently drop what the operator already set up.
List<FleetEntry> mergeDiscovery(
    List<FleetEntry> existing, List<DiscoveredKiosk> found) {
  final byName = {for (final e in existing) e.kiosk.hostName: e};
  return [
    for (final kiosk in found)
      if (byName[kiosk.hostName] case final kept?)
        (FleetEntry(kiosk: kiosk, selected: kept.selected)
          ..userOverride = kept.userOverride
          ..passwordOverride = kept.passwordOverride)
      else
        FleetEntry(kiosk: kiosk),
  ];
}
