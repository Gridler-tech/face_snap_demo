// The removal pipeline's step list is the contract the UI and the CLI both
// render. This locks its order — in particular that leftover-image cleanup runs
// after the containers/image are gone and before the verify — so a later edit
// can't silently drop or reorder it.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/remove_engine.dart';

void main() {
  RemoveEngine build({bool deleteConfigs = false}) => RemoveEngine(
        host: 'kiosk.local',
        user: 'root',
        password: 'x',
        deleteConfigs: deleteConfigs,
        onChanged: () {},
        onLog: (_) {},
      );

  test('removal steps are in the expected order', () {
    final titles = build().steps.map((s) => s.title).toList();
    expect(titles, [
      'Connect to the kiosk',
      'Inspect the current installation',
      'Back up configuration files',
      'Stop and disable auto-start',
      'Remove the auto-start service',
      'Remove containers and image',
      'Remove leftover image files',
      'Delete configuration files',
      'Verify removal',
    ]);
  });

  test('leftover cleanup sits between image removal and config deletion', () {
    final titles = build().steps.map((s) => s.title).toList();
    final leftover = titles.indexOf('Remove leftover image files');
    expect(leftover, greaterThan(titles.indexOf('Remove containers and image')));
    expect(leftover, lessThan(titles.indexOf('Delete configuration files')));
    expect(leftover, lessThan(titles.indexOf('Verify removal')));
  });
}
