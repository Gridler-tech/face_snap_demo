// The whole UpdateEngine.run() against a STRICT scripted board (TEST-1/TEST-2):
// every command the engine sends must be scripted (an unscripted one exits 127
// and is collected in _Board.unscripted), so a new or non-POSIX command shows up
// here and not first on a kiosk. Docker's answers come from image_delta_test's
// FakeDocker (load, layer lists, inspect, rmi); the compose file and settings
// files live in _Board.files, which cat, sed, cp and file writes change.
//
// The failure cases pin FL-1: a failure after "Stop the server" rolls back (or
// at least starts the server again), on a fresh connection when the link
// dropped; the best-effort kiosk identity never fails an update.
//
// X-12: the verify asks GetKioskInfo through the SSH forward on the board's
// port; each connection forwards to an in-process fake Kiosk server while the
// board's server runs and [_Board.answers] says it is reachable on that port.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart' show SSHSocket;
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' show GrpcError, Server, ServiceCall;
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/updater/image_delta.dart';
import 'package:operator_app/updater/kiosk.dart';
import 'package:operator_app/updater/server_port.dart';
import 'package:operator_app/updater/settings_profile.dart';
import 'package:operator_app/updater/update_engine.dart';

import 'fake_server.dart';
import 'image_delta_test.dart' show FakeDocker, TestImage;
import 'scripted_ssh.dart';

/// The board's gRPC server as GetKioskInfo sees it (started once).
late Server _kioskServer;

final _old = TestImage('facesnap2:2.0.22-arm64', ['base', 'python', 'empty', 'models', 'app22']);
final _new = TestImage(
    'facesnap2:2.0.23-arm64', ['base', 'python', 'empty', 'models', 'app22', 'app23', 'cfg']);

const _unit = '/etc/systemd/system/$kServiceUnit';
const _kioskSettings = '$kKioskDir/data/kiosk_settings.json';
const _settingsBefore = '{"camera": {"width": 1920, "height": 1080}}';

String _esc(String s) => RegExp.escape(s);

/// A Radxa board on the data/ layout running [_old] with its server unit, a
/// calibrated column and default port. [free]: what `df` answers in turn (the
/// last value repeats). [newImageStarts] false: `systemctl start` fails while
/// the compose file names [_new] (a compose that cannot start);
/// [newImageRuns] false: it starts but the container does not stay up.
class _Board {
  _Board({this.free = const [16000000000], this.newImageStarts = true, this.newImageRuns = true});

  final List<int> free;
  final bool newImageStarts;
  final bool newImageRuns;

  final docker = FakeDocker()..add(_old);
  final files = <String, String>{
    kCompose: composeTemplate(_old.tag),
    _unit: '[Unit]',
    _kioskSettings: _settingsBefore,
    '$kKioskDir/data/light_settings.json': '{"rows": [{"calibrated_camera_index": 1}]}',
  };

  /// Commands no rule answered (exit 127), over every connection.
  final unscripted = <String>[];

  /// The image the running server was started from (null: stopped).
  String? running = _old.tag;

  /// Whether the running server answers GetKioskInfo on the board's [port]
  /// (null: on the compose file's published port only).
  bool Function(int port)? answers;

  /// The host side of the compose file's ports mapping.
  int publishedPort() =>
      int.parse(RegExp(r'"(\d+):\d+"').firstMatch(files[kCompose] ?? '')?.group(1) ?? '50051');
  Uint8List? lastLoad;
  int _df = 0;

  String composeImage() =>
      RegExp(r'image:\s*(\S+)').firstMatch(files[kCompose] ?? '')?.group(1) ?? '';

  /// A new connection to the board; [first] adds rules that win over the
  /// board's own (first match wins).
  _BoardSsh connect([void Function(ScriptedSsh ssh)? first]) {
    final ssh = _BoardSsh(this);
    first?.call(ssh);
    ssh.onForward = (host, port) async {
      if (running != null && (answers ?? (p) => p == publishedPort())(port)) {
        return SSHSocket.connect('127.0.0.1', _kioskServer.port!);
      }
      throw const SocketException('Connection refused');
    };
    CmdResult ok([String out = '']) => CmdResult(0, out, '');
    ssh
      ..on(RegExp(r'^uname -m$'), ok('aarch64\n'))
      ..on(RegExp('device-tree/model'), ok('Radxa Dragon Q6A'))
      ..on(RegExp(r'^docker version '), ok('28.1.1\n'))
      ..on(RegExp(r'^stat -fc %T /sys/fs/cgroup$'), ok('cgroup2fs\n'))
      ..on(RegExp(r'^uname -r$'), ok('6.1.0\n'))
      ..onCall(RegExp(r'^test -f (\S+)$'), (c) {
        final path = RegExp(r'^test -f (\S+)$').firstMatch(c)!.group(1)!;
        return CmdResult(files.containsKey(path) ? 0 : 1, '', '');
      })
      ..onCall(RegExp(r'^test -f (\S+) && cat (\S+)$'), (c) {
        final text = files[RegExp(r'^test -f (\S+)').firstMatch(c)!.group(1)!];
        return text == null ? CmdResult(1, '', '') : ok(text);
      })
      ..onCall(RegExp('^${_esc(composeImageCmd(kCompose))}\$'), (_) => ok('${composeImage()}\n'))
      ..onCall(RegExp(r'^cat (\S+)( 2>/dev/null)?$'), (c) {
        final text = files[RegExp(r'^cat (\S+)').firstMatch(c)!.group(1)!];
        return text == null ? CmdResult(1, '', 'No such file or directory') : ok(text);
      })
      ..onCall(RegExp(r'^cp (\S+) (\S+)( 2>/dev/null)?$'), (c) {
        final m = RegExp(r'^cp (\S+) (\S+)').firstMatch(c)!;
        final text = files[m.group(1)!];
        if (text == null) return CmdResult(1, '', 'cp: cannot stat');
        files[m.group(2)!] = text;
        return ok();
      })
      ..onCall(RegExp(r"^sed -i 's\|image:\.\*\|image: (\S+)\|' (\S+)$"), (c) {
        final m = RegExp(r"^sed -i 's\|image:\.\*\|image: (\S+)\|' (\S+)$").firstMatch(c)!;
        files[m.group(2)!] = files[m.group(2)!]!.replaceFirst(RegExp(r'image:.*'), 'image: ${m.group(1)}');
        return ok();
      })
      ..on(RegExp(r"^docker ps --format '\{\{\.Image\}\} \(\{\{\.Status\}\}\)' \| head -3$"),
          ok('${_old.tag} (Up 2 hours)\n'))
      // FakeDocker: the installer's layer lists, inspect, load, rmi.
      ..onCall(RegExp(r"^docker info --format '\{\{\.Driver\}\}'$"), (_) => ok('${docker.driver}\n'))
      ..onCall(RegExp('^${_esc(kBoardLayersCmd)}\$'),
          (_) => ok(docker.images.values.map((i) => jsonEncode(i.layers)).join('\n')))
      ..onCall(RegExp(r'^docker image inspect --format '), (c) {
        final img = docker.images[c.split(' ').last];
        return img == null
            ? CmdResult(1, '', 'No such image')
            : ok('${img.id}|${jsonEncode(img.layers)}\n');
      })
      ..onCall(RegExp(r'^docker load$'), (_) => docker.load(lastLoad!))
      ..onCall(RegExp(r'^docker rmi (\S+)$'), (c) {
        docker.removeImage(c.split(' ').last);
        return ok();
      })
      ..on(RegExp(r'^docker image prune -f$'), ok())
      ..onCall(RegExp(r'^df --output=avail -B1 /var/lib/docker \| tail -1$'),
          (_) => ok('${free[_df < free.length - 1 ? _df++ : _df]}\n'))
      ..onCall(RegExp('^${_esc(imageEnvCmd(''))}'), (_) => ok('["FACE_SNAP_DATA_DIR=/data"]\n'))
      // Backup.
      ..on(RegExp('^mkdir -p ${_esc(kKioskDir)}/data\$'), ok())
      ..on(RegExp(r'^for f in .* done$'), ok())
      ..on(RegExp(r'^tar czf .*\|\| true$'), ok())
      // The server unit.
      ..onCall(RegExp('^systemctl stop ${_esc(kServiceUnit)}\$'), (_) {
        running = null;
        return ok();
      })
      ..on(RegExp(r'^docker ps -aq --filter name=face_snap \| xargs -r docker rm -f$'), ok())
      ..on(RegExp('^systemctl (enable ${_esc(kServiceUnit)}|daemon-reload)\$'), ok())
      ..onCall(RegExp('^systemctl start ${_esc(kServiceUnit)}\$'), (_) {
        final image = composeImage();
        if (image == _new.tag && !newImageStarts) {
          return CmdResult(1, '', 'Job for $kServiceUnit failed because the control process '
              'exited with error code.');
        }
        running = image;
        return ok();
      })
      ..onCall(RegExp(r"^docker ps --filter name=face_snap --format '\{\{\.Status\}\}'$"),
          (_) => ok(running != null && (running != _new.tag || newImageRuns) ? 'Up 5 seconds\n' : ''))
      ..on(RegExp(r'^docker ps -q --filter name=face_snap$'), ok('abc123\n'))
      ..on(RegExp(r'^docker logs --tail '),
          ok('Server 2.0 bound to port 50051\nPlasma LED board connected\n'))
      // Kiosk identity: the name is already right, avahi is installed.
      ..on(RegExp(r'/sys/class/net'), ok('001e06aabbcc'))
      ..on(RegExp('^${_esc(kHostnameCmd)}\$'), ok('facesnap-001e06aabbcc\n'))
      ..on(RegExp(r'^command -v avahi-daemon >/dev/null 2>&1$'), ok())
      ..on(RegExp(r'^systemctl enable avahi-daemon && systemctl restart avahi-daemon$'), ok());
    return ssh;
  }
}

/// ScriptedSsh with the board's state: the docker load stream goes to
/// FakeDocker, file writes land in [_Board.files], unscripted commands are
/// collected.
class _BoardSsh extends ScriptedSsh {
  _BoardSsh(this.board);
  final _Board board;

  @override
  Future<CmdResult> run(String command, {Duration timeout = const Duration(minutes: 3)}) async {
    final result = await super.run(command, timeout: timeout);
    if (result.exitCode == 127) board.unscripted.add(command);
    return result;
  }

  @override
  Future<CmdResult> runWithStreamStdin(String command, Stream<List<int>> data,
      {void Function(int sentBytes)? onProgress, Converter<List<int>, List<int>>? encoder}) async {
    var sent = 0;
    var stream = data.map((c) {
      sent += c.length;
      return c;
    });
    if (encoder != null) stream = stream.transform(encoder);
    final bytes = BytesBuilder();
    await for (final chunk in stream) {
      bytes.add(chunk);
    }
    onProgress?.call(sent);
    board.lastLoad = bytes.takeBytes();
    return super.runWithStreamStdin(command, const Stream.empty());
  }

  @override
  Future<void> writeRemoteFile(String path, String content) async {
    await super.writeRemoteFile(path, content);
    board.files[path] = content;
  }
}

/// The real engine; each openSsh() hands out the next of [connections].
class _Engine extends UpdateEngine {
  _Engine(this.connections, File tar, List<String> logs, {super.profile})
      : super(host: 'kiosk', user: 'root', password: 'x', tarFile: tar, onChanged: () {}, onLog: logs.add) {
    delay = (_) async {}; // the verify polls return at once
  }

  final List<SshRunner> connections;
  int opened = 0;

  @override
  Future<SshRunner> openSsh() async => connections[opened++];
}

void main() {
  setUpAll(() async => _kioskServer = await serveFakes([_Kiosk()]));
  tearDownAll(() => _kioskServer.shutdown());

  late Directory tmp;
  late File tar;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('update_engine_test');
    tar = File('${tmp.path}/face_snap-2.0.23-arm64.tar')..writeAsBytesSync(_new.tar());
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  const timeout = Timeout(Duration(minutes: 1));
  const rollbackCp = 'cp $kCompose.bak $kCompose';
  const start = 'systemctl start $kServiceUnit';

  /// Runs the update over [connections] (the first one unless the engine
  /// reconnects).
  Future<(_Engine, bool, List<String>)> update(List<SshRunner> connections,
      {SettingsProfile? profile}) async {
    final logs = <String>[];
    final engine = _Engine(connections, tar, logs, profile: profile);
    final ok = await engine.run();
    return (engine, ok, logs);
  }

  Map<String, StepStatus> statuses(UpdateEngine e) => {for (final s in e.steps) s.title: s.status};

  test('happy path: data/ layout, old image kept — every command scripted, compose switched, '
      '.bak kept', () async {
    final board = _Board();
    final ssh = board.connect();
    final (engine, ok, logs) = await update([ssh]);

    expect(ok, isTrue, reason: logs.join('\n'));
    expect(board.unscripted, isEmpty, reason: 'every command the engine sends is scripted');
    expect(statuses(engine), {
      'Connect to the kiosk': StepStatus.ok,
      'Inspect the current installation': StepStatus.ok,
      'Set up a clean board (Docker)': StepStatus.skipped,
      'Pre-update checks (version, disk space)': StepStatus.ok,
      'Back up settings and configuration': StepStatus.ok,
      'Make room (old image)': StepStatus.skipped,
      'Install the new server image': StepStatus.ok,
      'Stop the server': StepStatus.ok,
      'Update the start-up configuration': StepStatus.ok,
      'Apply the settings profile': StepStatus.skipped,
      'Provision kiosk identity': StepStatus.ok,
      'Start the server': StepStatus.ok,
      'Verify the new server': StepStatus.ok,
      'Clean up': StepStatus.ok,
    });
    expect(board.files[kCompose], composeTemplate(_new.tag));
    expect(board.files['$kCompose.bak'], composeTemplate(_old.tag));
    expect(engine.summary.first, 'Version: 2.0.22-arm64 → 2.0.23-arm64');
    expect(engine.summary, contains('Server updated to ${_new.tag} and verified.'));
    expect(board.running, _new.tag);
    expect(board.docker.images.keys, [_new.tag], reason: 'the old image is removed at the end');
    expect(ssh.commands, isNot(contains(rollbackCp)));
    expect(engine.opened, 1);
  }, timeout: timeout);

  test('FL-1 (1): systemctl start fails after the stop → rolled back, old server started', () async {
    final board = _Board(newImageStarts: false);
    final ssh = board.connect();
    final (engine, ok, logs) = await update([ssh]);

    expect(ok, isFalse);
    final failedStart = ssh.commands.indexOf(start);
    expect(failedStart, greaterThan(0));
    expect(ssh.commands.sublist(failedStart), contains(rollbackCp), reason: logs.join('\n'));
    expect(ssh.commands.lastIndexOf(start), greaterThan(ssh.commands.indexOf(rollbackCp)));
    expect(board.files[kCompose], composeTemplate(_old.tag));
    expect(board.running, _old.tag);
    expect(engine.summary, contains('Rolled back to the previous server (${_old.tag}).'));
    expect(engine.summary.join('\n'), contains('Update failed:'));
    expect(engine.steps.map((s) => s.status), isNot(contains(StepStatus.running)));
    expect(engine.steps[11].status, StepStatus.fail, reason: 'the start step failed');
  }, timeout: timeout);

  test('FL-1 (2): the link drops right after the stop → reconnect, rollback on the new link',
      () async {
    final board = _Board();
    final first = board.connect((s) => s.failAfter(RegExp(r'^systemctl stop')));
    final second = board.connect();
    final (engine, ok, logs) = await update([first, second]);

    expect(ok, isFalse);
    expect(engine.opened, 2, reason: 'one reconnect\n${logs.join('\n')}');
    expect(second.commands, contains(rollbackCp));
    expect(second.commands.lastIndexOf(start), greaterThan(second.commands.indexOf(rollbackCp)));
    expect(board.running, _old.tag);
    expect(engine.summary, contains('Rolled back to the previous server (${_old.tag}).'));
    expect(second.closed, isTrue, reason: 'the run closes the connection it ends on');
  }, timeout: timeout);

  test('FL-1 (3): the avahi restart fails → identity warns, the update still verifies', () async {
    final board = _Board();
    final ssh = board.connect((s) => s.on(RegExp(r'systemctl restart avahi-daemon'),
        CmdResult(1, '', 'Job for avahi-daemon.service failed.')));
    final (engine, ok, logs) = await update([ssh]);

    expect(ok, isTrue, reason: logs.join('\n'));
    expect(engine.steps[10].status, StepStatus.warn);
    expect(ssh.commands, isNot(contains(rollbackCp)));
    expect(board.files[kCompose], composeTemplate(_new.tag));
    expect(logs.join('\n'), contains('avahi'));
  }, timeout: timeout);

  test('TEST-2 (4): verify fails after a profile → compose and settings rolled back', () async {
    final board = _Board(newImageRuns: false);
    final ssh = board.connect();
    final (engine, ok, logs) = await update([ssh], profile: SettingsProfile.recommended());

    expect(ok, isFalse);
    expect(board.files['$_kioskSettings.pre-profile'], _settingsBefore, reason: logs.join('\n'));
    expect(ssh.commands, contains('write $_kioskSettings'), reason: 'the profile was applied');
    expect(ssh.commands, contains('cp $_kioskSettings.pre-profile $_kioskSettings'));
    expect(board.files[_kioskSettings], _settingsBefore);
    expect(board.files[kCompose], composeTemplate(_old.tag));
    expect(board.running, _old.tag);
    expect(engine.steps[12].status, StepStatus.fail);
    expect(engine.steps[13].status, StepStatus.warn, reason: 'rolled back');
    expect(engine.summary, contains('Rolled back to the previous server (${_old.tag}).'));
  }, timeout: timeout);

  test('FL-1 (5): old image removed to make room, then the install fails → a start is still '
      'attempted, the kiosk needs attention', () async {
    final board = _Board(free: const [100 * 1000 * 1000]);
    board.docker.failNextLoads = 1;
    final ssh = board.connect();
    final (engine, ok, logs) = await update([ssh]);

    expect(ok, isFalse);
    expect(ssh.commands, contains('docker rmi ${_old.tag}'), reason: logs.join('\n'));
    final load = ssh.commands.indexOf('docker load');
    expect(load, greaterThan(0));
    expect(ssh.commands.sublist(load), contains(start));
    expect(ssh.commands, isNot(contains(rollbackCp)), reason: 'nothing to roll back to');
    expect(engine.summary.join('\n'), contains('needs attention'));
    expect(engine.steps.map((s) => s.status), isNot(contains(StepStatus.running)));
  }, timeout: timeout);
  group('X-12: the verify needs GetKioskInfo on the board port', () {
    test('the ready marker alone is not enough: no answer on port 50051 → verify fails, '
        'rolled back', () async {
      final board = _Board()..answers = (_) => false;
      final ssh = board.connect();
      final (engine, ok, logs) = await update([ssh]);

      expect(ok, isFalse, reason: logs.join('\n'));
      expect(ssh.commands, contains('forward 127.0.0.1:50051'));
      expect(statuses(engine)['Verify the new server'], StepStatus.fail);
      expect(logs.join('\n'), contains('does not answer GetKioskInfo on port 50051'));
      expect(ssh.commands, contains(rollbackCp));
      expect(board.files[kCompose], composeTemplate(_old.tag));
      expect(engine.summary, contains('Rolled back to the previous server (${_old.tag}).'));
    }, timeout: timeout);

    test('GetKioskInfo answers on port 50051 through the SSH forward → verified', () async {
      final board = _Board();
      final ssh = board.connect();
      final (engine, ok, logs) = await update([ssh]);

      expect(ok, isTrue, reason: logs.join('\n'));
      expect(ssh.commands, contains('forward 127.0.0.1:50051'));
      expect(ssh.commands, isNot(contains(rollbackCp)));
      expect(statuses(engine)['Verify the new server'], StepStatus.ok);
    }, timeout: timeout);

    test('a board on port 50061: GetKioskInfo is asked on 50061', () async {
      final board = _Board();
      board.files[kCompose] = composeTemplate(_old.tag, port: 50061);
      board.files[kBoardPortFile] = portFileContent(50061);
      final ssh = board.connect();
      final (engine, ok, logs) = await update([ssh]);

      expect(ok, isTrue, reason: logs.join('\n'));
      // 2.0.23 does not read the port file: 50051 inside, published as 50061.
      expect(board.files[kCompose], composeTemplate(_new.tag, port: 50061, containerPort: 50051));
      expect(ssh.commands, contains('forward 127.0.0.1:50061'));
      expect(ssh.commands, isNot(contains('forward 127.0.0.1:50051')));
      expect(engine.summary, contains('Server updated to ${_new.tag} and verified.'));
    }, timeout: timeout);

    test('an image whose environment sets FACESNAP_NET_PORT → a warning in the log', () async {
      final board = _Board();
      final ssh = board.connect((s) => s.on(RegExp(r"^docker inspect --format '\{\{json \.Config\.Env\}\}' "),
          CmdResult(0, '["FACE_SNAP_DATA_DIR=/data","FACESNAP_NET_PORT=50099"]\n', '')));
      final (_, ok, logs) = await update([ssh]);

      expect(ok, isTrue, reason: logs.join('\n'));
      expect(
          logs,
          contains('WARNING: ${_new.tag} sets FACESNAP_NET_PORT in its environment: its server '
              'ignores the port file (the board uses port 50051).'));
    }, timeout: timeout);
  });
}

class _Kiosk extends KioskServiceBase {
  @override
  Future<KioskInfoResponse> getKioskInfo(ServiceCall call, Empty request) async =>
      KioskInfoResponse(kioskInfo: KioskInfo(port: '50051'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw GrpcError.unimplemented('${invocation.memberName}');
}
