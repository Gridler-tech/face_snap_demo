// The verify loops read the compose container's log with `docker logs $(docker
// ps -q …)`. `docker ps -q` lists every running container matching the name
// filter, so an orphan beside the compose one used to expand to two ids,
// `docker logs` refused them, the ready marker never matched and a healthy
// update was rolled back. The command must take exactly one id.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/kiosk.dart';

void main() {
  test('containerLogsCmd feeds docker logs a single id', () {
    expect(containerLogsCmd(600),
        'docker logs --tail 600 \$(docker ps -q $kContainerFilter | head -1) 2>&1');
    expect(containerLogsCmd(400), contains('--tail 400'));
  });

  test('countLines counts non-blank lines of docker ps -q output', () {
    expect(countLines(''), 0);
    expect(countLines('\n'), 0);
    expect(countLines('3f2a1b\n'), 1);
    expect(countLines('3f2a1b\n9c8d7e\n'), 2);
    expect(countLines('3f2a1b\r\n9c8d7e'), 2);
  });
}
