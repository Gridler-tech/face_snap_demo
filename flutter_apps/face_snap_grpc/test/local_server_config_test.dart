// The port of the FaceSnap server on this PC, read from server_config.json in
// %ProgramData%\FaceSnap (written by the setup). The reader must read every file
// exactly as the server does (server/server_config.py) and its stop scripts
// (server/tests/test_stop_scripts.py: VALID_FILES / INVALID_FILES, mirrored
// below): strict UTF-8 with or without a BOM, a JSON object with the exact key
// "grpc_port", an integer 1024-65535; anything else means 50051.
import 'dart:convert';
import 'dart:io';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:test/test.dart';

const _port50099 = '{"grpc_port": 50099}';
const _bom = [0xEF, 0xBB, 0xBF];

List<int> _utf8(String s) => utf8.encode(s);

List<int> _utf16le(String s) => [
      for (final unit in s.codeUnits) ...[unit & 0xFF, unit >> 8],
    ];

/// Files the server rejects (INVALID_FILES), as the exact bytes on disk.
final Map<String, List<int>> _invalidFiles = {
  'bad-json': _utf8('not json {'),
  'empty': _utf8(''),
  'no-key': _utf8('{}'),
  'string': _utf8('{"grpc_port": "50099"}'),
  'fraction': _utf8('{"grpc_port": 50099.5}'),
  'integral-float': _utf8('{"grpc_port": 50099.0}'),
  'exponent': _utf8('{"grpc_port": 5.0099e4}'),
  'bool': _utf8('{"grpc_port": true}'),
  'null': _utf8('{"grpc_port": null}'),
  '1023': _utf8('{"grpc_port": 1023}'),
  '65536': _utf8('{"grpc_port": 65536}'),
  'zero': _utf8('{"grpc_port": 0}'),
  'negative': _utf8('{"grpc_port": -50099}'),
  'array': _utf8('[{"grpc_port": 50099}]'),
  'bare-number': _utf8('50099'),
  // what PowerShell 5.1's > and Out-File write: UTF-16LE with a BOM
  'utf16le-bom': [0xFF, 0xFE, ..._utf16le(_port50099)],
  'utf16le-no-bom': _utf16le(_port50099),
  // an ANSI (Latin-1) byte elsewhere in an otherwise valid file: not UTF-8
  'latin1-byte': latin1.encode('{"grpc_port": 50099, "site": "caf\u00e9"}'),
  'key-upper-case': _utf8('{"GRPC_PORT": 50099}'),
  'key-mixed-case': _utf8('{"Grpc_Port": 50099}'),
  'single-quoted-key': _utf8("{'grpc_port': 50099}"),
  'unquoted-key': _utf8('{grpc_port: 50099}'),
  'leading-zero': _utf8('{"grpc_port": 050099}'),
  'plus-sign': _utf8('{"grpc_port": +50099}'),
  'two-boms': [..._bom, ..._bom, ..._utf8(_port50099)],
  'unquoted-other-key': _utf8('{"grpc_port": 50099, other: 1}'),
  'single-quoted-other-value': _utf8('{"grpc_port": 50099, "site": \'x\'}'),
  'trailing-comma': _utf8('{"grpc_port": 50099,}'),
  'comment': _utf8('{"grpc_port": 50099 /* port */}'),
  'trailing-text': _utf8('{"grpc_port": 50099} x'),
  'nested-only': _utf8('{"site": {"grpc_port": 50099}}'),
};

/// Files the server accepts (VALID_FILES), with the port it reads.
final Map<String, (List<int>, int)> _validFiles = {
  'plain': (_utf8(_port50099), 50099),
  'utf8-bom': ([..._bom, ..._utf8(_port50099)], 50099),
  '1024': (_utf8('{"grpc_port": 1024}'), 1024),
  '65535': (_utf8('{"grpc_port": 65535}'), 65535),
  'pretty-crlf': (_utf8('{\r\n    "grpc_port": 50099\r\n}\r\n'), 50099),
  'other-keys-and-utf8-text': (
    _utf8('{"other": {"grpc_port": 1}, "grpc_port": 50099, "site": "caf\u00e9"}'),
    50099
  ),
  'escapes-and-other-values': (
    _utf8(r'{"grpc_port": 50099, "site": "a\"b\\c\u00e9", "list": [1, true, null, 2.5e3]}'),
    50099
  ),
};

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('local_server_config_test');
    LocalServerConfig.port = LocalServerConfig.defaultPort;
  });

  tearDown(() async {
    LocalServerConfig.port = LocalServerConfig.defaultPort;
    await dir.delete(recursive: true);
  });

  Future<String> configFile(List<int> bytes) async {
    final file = File('${dir.path}${Platform.pathSeparator}server_config.json');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// The port load() reads from a file holding [bytes]. The port is set to a
  /// value no fixture holds first, so a load that leaves it alone shows.
  Future<int> loadedPort(List<int> bytes) async {
    LocalServerConfig.port = 1;
    await LocalServerConfig.load(path: await configFile(bytes));
    return LocalServerConfig.port;
  }

  test('the default port is 50051', () {
    expect(LocalServerConfig.defaultPort, 50051);
    expect(LocalServerConfig.port, 50051);
  });

  group('parsePort', () {
    test('a valid file gives its port', () {
      expect(LocalServerConfig.parsePort(_port50099), 50099);
    });

    test('a BOM in front reads the same as none', () {
      expect(LocalServerConfig.parsePort('\uFEFF$_port50099'), 50099);
    });

    test('two BOMs are not a valid file', () {
      expect(LocalServerConfig.parsePort('\uFEFF\uFEFF$_port50099'), 50051);
    });

    test('invalid JSON gives the default', () {
      expect(LocalServerConfig.parsePort('not json {'), 50051);
      expect(LocalServerConfig.parsePort(''), 50051);
    });

    test('a missing key gives the default', () {
      expect(LocalServerConfig.parsePort('{}'), 50051);
      expect(LocalServerConfig.parsePort('{"port": 50099}'), 50051);
    });

    test('a string gives the default', () {
      expect(LocalServerConfig.parsePort('{"grpc_port": "50099"}'), 50051);
    });

    test('out of range gives the default; the limits are accepted', () {
      for (final p in [0, 1023, 65536, -50099]) {
        expect(LocalServerConfig.parsePort('{"grpc_port": $p}'), 50051, reason: '$p');
      }
      expect(LocalServerConfig.parsePort('{"grpc_port": 1024}'), 1024);
      expect(LocalServerConfig.parsePort('{"grpc_port": 65535}'), 65535);
    });

    test('a float, even an integral one, is not an integer', () {
      expect(LocalServerConfig.parsePort('{"grpc_port": 50099.0}'), 50051);
      expect(LocalServerConfig.parsePort('{"grpc_port": 5.0099e4}'), 50051);
    });
  });

  group('load(path:) reads every file as the server does', () {
    for (final MapEntry(key: id, value: (bytes, port)) in _validFiles.entries) {
      test('valid: $id -> $port', () async {
        expect(await loadedPort(bytes), port);
      });
    }

    for (final MapEntry(key: id, value: bytes) in _invalidFiles.entries) {
      test('invalid: $id -> 50051', () async {
        expect(await loadedPort(bytes), 50051);
      });
    }

    test('a missing file gives the default', () async {
      LocalServerConfig.port = 1;
      await LocalServerConfig.load(
          path: '${dir.path}${Platform.pathSeparator}no_such_file.json');
      expect(LocalServerConfig.port, 50051);
    });

    test('a later load replaces an earlier port', () async {
      await LocalServerConfig.load(path: await configFile(_utf8(_port50099)));
      expect(LocalServerConfig.port, 50099);
      await LocalServerConfig.load(path: await configFile(_utf8('{}')));
      expect(LocalServerConfig.port, 50051);
    });
  });

  test('the default path is %ProgramData%\\FaceSnap\\server_config.json on Windows',
      () {
    if (Platform.isWindows) {
      final programData = Platform.environment['PROGRAMDATA'] ?? r'C:\ProgramData';
      expect(LocalServerConfig.defaultPath, '$programData\\FaceSnap\\server_config.json');
    } else {
      expect(File(LocalServerConfig.defaultPath).existsSync(), isFalse);
    }
  });

  test('isLocalHost: localhost, 127.0.0.1 and ::1 only', () {
    for (final h in ['localhost', '127.0.0.1', '::1']) {
      expect(LocalServerConfig.isLocalHost(h), isTrue, reason: h);
    }
    for (final h in [
      '',
      '192.168.3.198',
      'facesnap-001e0644278f.local',
      'odroid',
      '127.0.0.2',
      'localhost.example.com',
    ]) {
      expect(LocalServerConfig.isLocalHost(h), isFalse, reason: h);
    }
  });
}
