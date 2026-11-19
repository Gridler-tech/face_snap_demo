// The Updater's port groundwork (server_port.dart): the compose ports edit,
// the image versions that read the port file, the board's port file, the
// avahi announcement, Linux/Windows target detection and the PowerShell
// command line for a Windows PC.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/services/ssh_runner.dart';
import 'package:operator_app/updater/connection_probe.dart';
import 'package:operator_app/updater/kiosk.dart';
import 'package:operator_app/updater/server_port.dart';

import 'scripted_ssh.dart';

/// The script inside a [windowsPs] command line.
String decodePs(String command) {
  final b64 = command.split(' ').last;
  final bytes = base64.decode(b64);
  final units = Uint16List(bytes.length ~/ 2);
  for (var i = 0; i < units.length; i++) {
    units[i] = bytes[2 * i] | (bytes[2 * i + 1] << 8);
  }
  return String.fromCharCodes(units);
}

void main() {
  test('constants', () {
    expect(kBoardPortFile, '/root/face_snap/data/server_config.json');
    expect(kMinFacesnap2, '2.0.28');
    expect(kMinPythonImage, '1.1.25');
    expect(portFileContent(50052), '{"grpc_port": 50052}\n');
  });

  group('withComposePort', () {
    const unexpected = 'unexpected ports line in docker-compose.yml';
    Matcher refused() => throwsA(
      isA<FormatException>().having((e) => e.message, 'message', unexpected),
    );

    test('quoted mapping: only the mapping changes', () {
      final before = composeTemplate('facesnap2:2.0.28-arm64');
      final after = withComposePort(before, 50052);
      expect(after, before.replaceFirst('- "50051:50051"', '- "50052:50052"'));
      expect(after, isNot(before));
    });

    test('unquoted mapping becomes a quoted one', () {
      final before = composeTemplate(
        'facesnap2:2.0.28-arm64',
      ).replaceFirst('- "50051:50051"', '- 50051:50051');
      expect(
        withComposePort(before, 50052),
        before.replaceFirst('- 50051:50051', '- "50052:50052"'),
      );
    });

    test('a host IP prefix is kept', () {
      final before = composeTemplate(
        'facesnap2:2.0.28-arm64',
      ).replaceFirst('- "50051:50051"', '- "0.0.0.0:50051:50051"');
      expect(
        withComposePort(before, 50052),
        before.replaceFirst('"0.0.0.0:50051:50051"', '"0.0.0.0:50052:50052"'),
      );
    });

    test('different host and container ports become N:N', () {
      const before = 'services:\n  s:\n    ports:\n      - "50060:50051"\n';
      expect(
        withComposePort(before, 50052),
        'services:\n  s:\n    ports:\n      - "50052:50052"\n',
      );
    });

    test('CRLF line endings, comments and a trailing comment are kept', () {
      const before =
          'services:\r\n'
          '  face_snap:\r\n'
          '    ports:\r\n'
          '      # the gRPC port\r\n'
          "      - '50051:50051'   # gRPC\r\n"
          '    volumes:\r\n'
          '      - ./data:/data\r\n';
      expect(
        withComposePort(before, 50099),
        before.replaceFirst(
          "- '50051:50051'   # gRPC",
          '- "50099:50099"   # gRPC',
        ),
      );
    });

    test('containerPort maps host N to another container port', () {
      final before = composeTemplate('face_snap:1.4.3');
      expect(
        withComposePort(before, 50052, containerPort: 50051),
        before.replaceFirst('"50051:50051"', '"50052:50051"'),
      );
    });

    test('no mapping is refused', () {
      expect(
        () => withComposePort('services:\n  s:\n    image: x\n', 50052),
        refused(),
      );
      expect(
        () => withComposePort('services:\n  s:\n    ports:\n', 50052),
        refused(),
      );
    });

    test('two mappings are refused', () {
      const two =
          'services:\n  s:\n    ports:\n'
          '      - "50051:50051"\n      - "8080:8080"\n';
      expect(() => withComposePort(two, 50052), refused());
      const twoServices =
          'services:\n  a:\n    ports:\n      - "50051:50051"\n'
          '  b:\n    ports:\n      - "50051:50051"\n';
      expect(() => withComposePort(twoServices, 50052), refused());
    });

    test('other forms are refused', () {
      for (final line in [
        '    ports: ["50051:50051"]\n',
        '    ports:\n      - "50051-50052:50051-50052"\n',
        '    ports:\n      - "50051:50051/udp"\n',
        '    ports:\n      - target: 50051\n        published: 50051\n',
        '    ports:\n      - "50051"\n',
      ]) {
        expect(
          () => withComposePort('services:\n  s:\n$line', 50052),
          refused(),
          reason: line,
        );
      }
    });
  });

  group('templates follow the port', () {
    test('composeTemplate', () {
      expect(
        composeTemplate('facesnap2:2.0.28-arm64'),
        contains('      - "50051:50051"\n'),
      );
      final t = composeTemplate('facesnap2:2.0.28-arm64', port: 50052);
      expect(t, contains('      - "50052:50052"\n'));
      expect(t, isNot(contains('50051')));
      expect(isLegacyCompose(t), isFalse);
    });

    test('legacyComposeTemplate', () {
      expect(
        legacyComposeTemplate('face_snap:1.4.3'),
        contains('      - "50051:50051"\n'),
      );
      final t = legacyComposeTemplate(
        'face_snap:1.4.3',
        port: 50052,
        containerPort: 50051,
      );
      expect(t, contains('      - "50052:50051"\n'));
      expect(isLegacyCompose(t), isTrue);
    });
  });

  test('imageSupportsPortFile', () {
    expect(imageSupportsPortFile('facesnap2:2.0.23-arm64'), isFalse);
    // R15: 2.0.24-2.0.27 are head-turn test images without the port reader
    // (2.0.27 still runs on the Odroid).
    expect(imageSupportsPortFile('facesnap2:2.0.24-arm64'), isFalse);
    expect(imageSupportsPortFile('facesnap2:2.0.27-arm64'), isFalse);
    expect(imageSupportsPortFile('facesnap2:2.0.28-arm64'), isTrue);
    expect(imageSupportsPortFile('facesnap2:2.0.28-up1-arm64'), isTrue);
    expect(imageSupportsPortFile('facesnap2:2.1.0-arm64'), isTrue);
    expect(imageSupportsPortFile('face_snap_server:1.1.24'), isFalse);
    expect(imageSupportsPortFile('face_snap_server:1.1.25'), isTrue);
    expect(imageSupportsPortFile('face_snap_server:1.2.0-arm64'), isTrue);
    expect(imageSupportsPortFile('ubuntu:22.04'), isFalse);
    expect(imageSupportsPortFile('face_snap:1.4.3'), isFalse);
    expect(imageSupportsPortFile('facesnap2:arm64'), isFalse);
    expect(imageSupportsPortFile('facesnap2'), isFalse);
    expect(imageSupportsPortFile(''), isFalse);
  });

  test('avahiService', () {
    expect(avahiService(50051), '''
<?xml version="1.0" standalone="no"?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">FaceSnap kiosk on %h</name>
  <service>
    <type>_facesnap._tcp</type>
    <port>50051</port>
  </service>
</service-group>
''');
    expect(avahiService(50052), contains('<port>50052</port>'));
    expect(avahiService(50052), isNot(contains('50051')));
  });

  group('windowsPs', () {
    test('the encoded command round-trips (UTF-16LE)', () {
      const script =
          r"$x = 'Café €'; Write-Output ([Environment]::OSVersion.Platform)";
      final command = windowsPs(script);
      expect(
        command,
        startsWith(
          'powershell -NoProfile -NonInteractive '
          '-ExecutionPolicy Bypass -EncodedCommand ',
        ),
      );
      expect(decodePs(command), script);
    });

    test('2,500 characters are fine, 2,501 are refused', () {
      expect(decodePs(windowsPs('a' * 2500)), 'a' * 2500);
      expect(() => windowsPs('a' * 2501), throwsArgumentError);
    });
  });

  group('identifyTarget', () {
    test('Linux board', () async {
      final ssh = ScriptedSsh({
        RegExp(r'^uname -s -m$'): CmdResult(0, 'Linux aarch64\n', ''),
        RegExp('/proc/device-tree/model'): CmdResult(
          0,
          'Hardkernel ODROID-N2Plus',
          '',
        ),
      });
      final t = await identifyTarget(ssh);
      expect(t.kind, TargetKind.linuxBoard);
      expect(t.arch, 'aarch64');
      expect(t.model, 'Hardkernel ODROID-N2Plus');
      expect(ssh.commands.where((c) => c.startsWith('powershell')), isEmpty);
    });

    test(
      'Linux without a device tree: the model is the architecture',
      () async {
        final ssh = ScriptedSsh({
          RegExp(r'^uname -s -m$'): CmdResult(0, 'Linux x86_64\n', ''),
          RegExp('/proc/device-tree/model'): CmdResult(1, '', ''),
        });
        final t = await identifyTarget(ssh);
        expect(t.kind, TargetKind.linuxBoard);
        expect((t.arch, t.model), ('x86_64', 'x86_64'));
      },
    );

    test('Windows PC (cmd.exe does not know uname)', () async {
      final ssh = ScriptedSsh({
        RegExp(r'^uname'): CmdResult(
          1,
          '',
          "'uname' is not recognized as an internal or external command,\r\n",
        ),
        RegExp(
          r'^powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass '
          r'-EncodedCommand ',
        ): CmdResult(
          0,
          'Win32NT\r\nDELL-KIOSK\r\nAMD64\r\n',
          '',
        ),
      });
      final t = await identifyTarget(ssh);
      expect(t.kind, TargetKind.windowsPc);
      expect(t.model, 'DELL-KIOSK');
      expect(t.arch, 'AMD64');
      final ps = ssh.commands.last;
      expect(decodePs(ps), contains('[Environment]::OSVersion.Platform'));
    });

    test('Windows PC without a computer name: "Windows PC"', () async {
      final ssh = ScriptedSsh({
        RegExp(r'^uname'): CmdResult(1, '', ''),
        RegExp(r'^powershell '): CmdResult(0, 'Win32NT\r\n', ''),
      });
      final t = await identifyTarget(ssh);
      expect(t.kind, TargetKind.windowsPc);
      expect(t.model, 'Windows PC');
    });

    test('Git for Windows uname (MINGW) is not a Linux board', () async {
      final ssh = ScriptedSsh({
        RegExp(r'^uname'): CmdResult(0, 'MINGW64_NT-10.0-26100 x86_64\n', ''),
        RegExp(r'^powershell '): CmdResult(
          0,
          'Win32NT\r\nPC1\r\nAMD64\r\n',
          '',
        ),
      });
      expect((await identifyTarget(ssh)).kind, TargetKind.windowsPc);
    });

    test('unknown: neither uname nor PowerShell answer', () async {
      final ssh = ScriptedSsh(); // everything exits 127
      final t = await identifyTarget(ssh);
      expect(t.kind, TargetKind.unknown);
    });

    test('unknown: PowerShell answers something else', () async {
      final ssh = ScriptedSsh({
        RegExp(r'^uname'): CmdResult(0, 'Darwin arm64\n', ''),
        RegExp(r'^powershell '): CmdResult(0, 'Unix\n', ''),
      });
      final t = await identifyTarget(ssh);
      expect(t.kind, TargetKind.unknown);
      expect(t.model, 'Darwin arm64');
    });

    test('I3: a PowerShell probe that never answers ends at its timeout', () async {
      final ssh = ScriptedSsh({
        RegExp(r'^uname'): CmdResult(1, '', "'uname' is not recognized"),
      })..hangPs(RegExp('OSVersion'));
      await expectLater(identifyTarget(ssh, probeTimeout: Duration.zero),
          throwsA(isA<TimeoutException>()));
      expect(ssh.scripts, hasLength(1), reason: 'the probe was sent');
      expect(kWindowsQueryTimeout, const Duration(seconds: 30));
    });
  });

  group('readBoardPort', () {
    ScriptedSsh board(CmdResult portFile) =>
        ScriptedSsh({RegExp(RegExp.escape(kBoardPortFile)): portFile});

    test('missing file: 50051, no warning', () async {
      final warnings = <String>[];
      final ssh = board(CmdResult(1, '', ''));
      expect(await readBoardPort(ssh, onWarning: warnings.add), 50051);
      expect(warnings, isEmpty);
      expect(ssh.commands.single, contains('cat $kBoardPortFile'));
    });

    test('valid file', () async {
      final warnings = <String>[];
      expect(
        await readBoardPort(
          board(CmdResult(0, '{"grpc_port": 50052}\n', '')),
          onWarning: warnings.add,
        ),
        50052,
      );
      // No whitespace is fine too.
      expect(
        await readBoardPort(board(CmdResult(0, '{"grpc_port":50060}', ''))),
        50060,
      );
      expect(warnings, isEmpty);
    });

    test('invalid content: 50051 with one warning', () async {
      for (final text in [
        '{"grpc_port": 80}',
        '{"grpc_port": "50052"}',
        '{"grpc_port": 50052.0}',
        'garbage',
        '',
        '\uFEFF{"grpc_port": 50052}', // a second BOM: the server rejects it
        '{"grpc_port": 50052, "x": "\uFFFD"}', // not valid UTF-8 on the board
      ]) {
        final warnings = <String>[];
        expect(
          await readBoardPort(
            board(CmdResult(0, text, '')),
            onWarning: warnings.add,
          ),
          50051,
          reason: text,
        );
        expect(warnings, hasLength(1), reason: text);
        expect(warnings.single, contains('50051'));
      }
    });
  });

  test('version helpers are public', () {
    expect(versionCore('2.0.11-arm64'), '2.0.11');
    expect(versionCore('arm64'), isNull);
    expect(compareVersions('2.0.24', '2.0.9'), greaterThan(0));
    expect(compareVersions('1.1.25', '1.1.25'), 0);
    expect(compareVersions('1.1', '1.1.1'), lessThan(0));
  });

  group('ScriptedSsh', () {
    test(
      'first match wins, unmatched exits 127, writes are recorded',
      () async {
        final ssh = ScriptedSsh({
          RegExp('^echo a'): CmdResult(0, 'first', ''),
          RegExp('^echo'): CmdResult(0, 'second', ''),
        });
        expect((await ssh.run('echo a')).stdout, 'first');
        expect((await ssh.run('echo b')).stdout, 'second');
        expect((await ssh.run('ls')).exitCode, 127);
        await ssh.writeRemoteFile('/tmp/x', 'hello');
        expect(ssh.writes, {'/tmp/x': 'hello'});
        expect(ssh.commands, ['echo a', 'echo b', 'ls', 'write /tmp/x']);
      },
    );

    test('failAfter: later calls throw', () async {
      final ssh = ScriptedSsh({RegExp('restart'): CmdResult(0, '', '')})
        ..failAfter(RegExp('restart'));
      expect((await ssh.run('systemctl restart x')).ok, isTrue);
      await expectLater(ssh.run('echo'), throwsA(anything));
      await expectLater(ssh.writeRemoteFile('/a', 'b'), throwsA(anything));
      expect(ssh.lost, isTrue);
    });
  });
}
