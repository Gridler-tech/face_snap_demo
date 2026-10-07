// "Copy as Dart" / "Copy as C#": a recorded call (RpcCall) turned back into
// the code that makes exactly that call — with this package's generated
// clients (Dart) or the generated Grpc.Net clients the C# SDK (GrpcLibrary)
// is built on. The request comes from the recorded proto3 JSON plus the
// message's static metadata (BuilderInfo), so field types (double vs float,
// enum, nested message, repeated) are known. A bytes field becomes a
// placeholder variable (`image1Bytes`) the caller supplies.
//
// The C# names follow protoc's C# generator: properties are the proto field
// name in PascalCase (`cie_x` -> CieX, `image1` -> Image1), enum values drop
// the enum-name prefix and become PascalCase (BACKLIGHT_TOP in enum Backlight
// -> Backlight.Top), services are `Settings.SettingsClient` in namespace
// GrpcLibrary (csharp_namespace of every .proto), Empty is
// Google.Protobuf.WellKnownTypes.Empty.
import 'package:protobuf/protobuf.dart';

import 'rpc_trace.dart';

/// The proto packages of the FaceSnap services; message names are qualified
/// with one of these (or google.protobuf for Empty).
const _packages = [
  'google.protobuf',
  'calibration',
  'camera',
  'kiosk',
  'lights',
  'monitoring',
  'settings',
];

/// Dart code for [call]: the generated client on the shared channel.
String rpcCallAsDart(RpcCall call) {
  final client = '${call.serviceName}Client(GrpcChannelProvider.channel)';
  final method = _lowerFirst(call.method);
  final request = _requestOf(call);
  final arg = request == null
      ? '/* request not recorded */ Empty()'
      : _dartMessage(request.info, request.json, request.type);
  final placeholders = <String>{};
  if (request != null) _collectBytes(request.info, request.json, placeholders);
  final b = StringBuffer();
  for (final p in placeholders) {
    b.writeln('// $p: the bytes to send (List<int>, e.g. File(...).readAsBytesSync())');
  }
  switch (call.kind) {
    case RpcKind.serverStreaming:
      b.writeln('await for (final reply in $client.$method($arg)) {');
      b.writeln('  print(reply);');
      b.write('}');
    case RpcKind.clientStreaming || RpcKind.bidiStreaming:
      b.writeln('// ${call.kind.name}: the recorded first request is shown');
      b.writeln('await for (final reply in $client.$method(Stream.value($arg))) {');
      b.writeln('  print(reply);');
      b.write('}');
    case RpcKind.unary || RpcKind.unknown:
      if (call.responseType == 'Empty') {
        b.write('await $client.$method($arg);');
      } else {
        b.write('final reply = await $client.$method($arg);');
      }
  }
  return b.toString();
}

/// C# code for [call]: the generated Grpc.Net client (namespace GrpcLibrary)
/// on the C# SDK's shared channel.
String rpcCallAsCSharp(RpcCall call) {
  final client =
      'new ${call.serviceName}.${call.serviceName}Client(GrpcChannelProvider.Channel)';
  final request = _requestOf(call);
  final arg = request == null
      ? '/* request not recorded */ new Empty()'
      : _csMessage(request.info, request.json, request.type, '');
  final placeholders = <String>{};
  if (request != null) _collectBytes(request.info, request.json, placeholders);
  final b = StringBuffer();
  b.writeln('// using GrpcLibrary; using Google.Protobuf; '
      'using Google.Protobuf.WellKnownTypes; using Grpc.Core;');
  for (final p in placeholders) {
    b.writeln('// $p: the bytes to send (byte[], e.g. File.ReadAllBytes(...))');
  }
  switch (call.kind) {
    case RpcKind.serverStreaming:
      b.writeln('using var call = $client.${call.method}($arg);');
      b.writeln('await foreach (var reply in call.ResponseStream.ReadAllAsync())');
      b.writeln('{');
      b.writeln('    Console.WriteLine(reply);');
      b.write('}');
    case RpcKind.clientStreaming || RpcKind.bidiStreaming:
      b.writeln('// ${call.kind.name}: the recorded first request is shown');
      b.writeln('using var call = $client.${call.method}();');
      b.writeln('await call.RequestStream.WriteAsync($arg);');
      b.write('await call.RequestStream.CompleteAsync();');
    case RpcKind.unary || RpcKind.unknown:
      if (call.responseType == 'Empty') {
        b.write('await $client.${call.method}Async($arg);');
      } else {
        b.write('var reply = await $client.${call.method}Async($arg);');
      }
  }
  return b.toString();
}

RpcMessage? _requestOf(RpcCall call) {
  if (call.requests.isEmpty) return null;
  final r = call.requests.first;
  return r.info == null ? null : r;
}

// ---- names ------------------------------------------------------------------

String _lowerFirst(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

/// `settings.CropRequest` -> [`CropRequest`]; nested `pkg.Outer.Inner` ->
/// [`Outer`, `Inner`].
List<String> _localName(String qualified) {
  for (final p in _packages) {
    if (qualified.startsWith('$p.')) {
      return qualified.substring(p.length + 1).split('.');
    }
  }
  return qualified.split('.');
}

String _dartTypeName(String qualified) => _localName(qualified).join('_');

String _csTypeName(String qualified) => _localName(qualified).join('.Types.');

/// protoc's C# property name: `cie_x` -> CieX, `image1` -> Image1,
/// `timeoutInMs` -> TimeoutInMs.
String csPropertyName(String protoName) {
  final b = StringBuffer();
  var capNext = true;
  for (var i = 0; i < protoName.length; i++) {
    final c = protoName[i];
    final code = c.codeUnitAt(0);
    final lower = code >= 0x61 && code <= 0x7A;
    final upper = code >= 0x41 && code <= 0x5A;
    final digit = code >= 0x30 && code <= 0x39;
    if (lower) {
      b.write(capNext ? c.toUpperCase() : c);
      capNext = false;
    } else if (upper) {
      b.write(c);
      capNext = false;
    } else if (digit) {
      b.write(c);
      capNext = true;
    } else {
      capNext = true;
    }
  }
  return b.toString();
}

/// protoc's C# enum value name: the enum-name prefix removed, then
/// SHOUTY_CASE -> PascalCase (BACKLIGHT_TOP in Backlight -> Top,
/// EUCLIDEAN_L2 -> EuclideanL2, FACENET512 -> Facenet512).
String csEnumValueName(String enumName, String valueName) {
  var name = _removePrefix(enumName, valueName);
  final b = StringBuffer();
  var previous = '_';
  bool alnum(String c) => RegExp(r'[A-Za-z0-9]').hasMatch(c);
  bool isDigit(String c) => RegExp(r'[0-9]').hasMatch(c);
  bool isLower(String c) => RegExp(r'[a-z]').hasMatch(c);
  for (var i = 0; i < name.length; i++) {
    final c = name[i];
    if (!alnum(c)) {
      previous = c;
      continue;
    }
    if (!alnum(previous) || isDigit(previous)) {
      b.write(c.toUpperCase());
    } else if (isLower(previous)) {
      b.write(c);
    } else {
      b.write(c.toLowerCase());
    }
    previous = c;
  }
  name = b.toString();
  if (name.isNotEmpty && isDigit(name[0])) name = '_$name';
  return name;
}

String _removePrefix(String prefix, String value) {
  final p = prefix.replaceAll('_', '').toLowerCase();
  var i = 0;
  var j = 0;
  while (i < value.length && j < p.length) {
    if (value[i] == '_') {
      i++;
      continue;
    }
    if (value[i].toLowerCase() != p[j]) return value;
    i++;
    j++;
  }
  if (j < p.length) return value;
  while (i < value.length && value[i] == '_') {
    i++;
  }
  return i == value.length ? value : value.substring(i);
}

// ---- values -----------------------------------------------------------------

int _base(int type) => PbFieldType.baseType(type);

bool _isBytes(int type) => _base(type) == PbFieldType.BYTES_BIT;
bool _isFloat(int type) => _base(type) == PbFieldType.FLOAT_BIT;
bool _isDouble(int type) => _base(type) == PbFieldType.DOUBLE_BIT;
bool _isString(int type) => _base(type) == PbFieldType.STRING_BIT;
bool _is64(int type) => const {
      PbFieldType.INT64_BIT,
      PbFieldType.SINT64_BIT,
      PbFieldType.UINT64_BIT,
      PbFieldType.FIXED64_BIT,
      PbFieldType.SFIXED64_BIT,
    }.contains(_base(type));

/// Placeholder variable for a bytes field: `image1Bytes`.
String _bytesVar(FieldInfo<dynamic> fi) => '${fi.name}Bytes';

void _collectBytes(BuilderInfo? info, Object? json, Set<String> out) {
  if (info == null || json is! Map) return;
  for (final e in json.entries) {
    final fi = info.byName[e.key];
    if (fi == null) continue;
    if (_isBytes(fi.type)) {
      out.add(_bytesVar(fi));
    } else if (fi.isGroupOrMessage && !fi.isMapField) {
      final sub = fi.subBuilder?.call().info_;
      final values = fi.isRepeated ? (e.value as List) : [e.value];
      for (final v in values) {
        _collectBytes(sub, v, out);
      }
    }
  }
}

String _enumTypeName(FieldInfo<dynamic> fi) {
  final values = fi.enumValues;
  if (values != null && values.isNotEmpty) {
    return values.first.runtimeType.toString();
  }
  return 'int';
}

String _dartString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return "'$escaped'";
}

String _csString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return '"$escaped"';
}

/// Float fields went through 32 bits: print the shortest round value.
String _floatText(num v) {
  final d = v.toDouble();
  var t = double.parse(d.toStringAsPrecision(7)).toString();
  if (t.contains('e')) t = d.toString();
  return t;
}

String _dartMessage(BuilderInfo? info, Object? json, String qualified) {
  final cls = _dartTypeName(qualified);
  if (info == null || json is! Map || json.isEmpty) return '$cls()';
  final args = <String>[];
  for (final e in json.entries) {
    final fi = info.byName[e.key];
    if (fi == null) continue;
    final String value;
    if (fi is MapFieldInfo) {
      final m = e.value as Map;
      value = '{${m.entries.map((x) => '${_dartMapKey(fi.keyFieldType, x.key)}: '
          '${_dartScalar(fi.valueFieldInfo, x.value)}').join(', ')}}.entries';
    } else if (fi.isRepeated) {
      value = '[${(e.value as List).map((v) => _dartScalar(fi, v)).join(', ')}]';
    } else {
      value = _dartScalar(fi, e.value);
    }
    args.add('${fi.name}: $value');
  }
  return '$cls(${args.join(', ')})';
}

String _dartMapKey(int keyType, Object? key) {
  if (_isString(keyType)) return _dartString('$key');
  if (_is64(keyType)) return "Int64.parseInt('$key')";
  return '$key';
}

String _dartScalar(FieldInfo<dynamic> fi, Object? v) {
  final type = fi.type;
  if (fi.isGroupOrMessage) {
    final sub = fi.subBuilder?.call();
    return _dartMessage(
        sub?.info_, v, sub?.info_.qualifiedMessageName ?? 'Object');
  }
  if (fi.isEnum) return '${_enumTypeName(fi)}.$v';
  if (_isBytes(type)) return _bytesVar(fi);
  if (_isString(type)) return _dartString('$v');
  if (_isFloat(type) || _isDouble(type)) {
    if (v == 'NaN') return 'double.nan';
    if (v == 'Infinity') return 'double.infinity';
    if (v == '-Infinity') return 'double.negativeInfinity';
    final n = v as num;
    if (_isFloat(type)) return _floatText(n);
    return n is int ? '$n.0' : '$n';
  }
  if (_is64(type)) return "Int64.parseInt('$v')";
  return '$v';
}

String _csMessage(
    BuilderInfo? info, Object? json, String qualified, String indent) {
  final cls = _csTypeName(qualified);
  if (info == null || json is! Map || json.isEmpty) return 'new $cls()';
  final parts = <String>[];
  for (final e in json.entries) {
    final fi = info.byName[e.key];
    if (fi == null) continue;
    final prop = csPropertyName(fi.protoName);
    if (fi is MapFieldInfo) {
      final m = e.value as Map;
      final items = m.entries
          .map((x) => '[${_csMapKey(fi.keyFieldType, x.key)}] = '
              '${_csScalar(fi.valueFieldInfo, x.value, indent)}')
          .join(', ');
      parts.add('$prop = { $items }');
    } else if (fi.isRepeated) {
      final items = (e.value as List)
          .map((v) => _csScalar(fi, v, '$indent    '))
          .toList();
      if (fi.isGroupOrMessage && items.isNotEmpty) {
        parts.add('$prop =\n$indent    {\n'
            '${items.map((i) => '$indent        $i').join(',\n')}\n'
            '$indent    }');
      } else {
        parts.add('$prop = { ${items.join(', ')} }');
      }
    } else {
      parts.add('$prop = ${_csScalar(fi, e.value, indent)}');
    }
  }
  return 'new $cls { ${parts.join(', ')} }';
}

String _csMapKey(int keyType, Object? key) {
  if (_isString(keyType)) return _csString('$key');
  if (_is64(keyType)) return '${key}L';
  return '$key';
}

String _csScalar(FieldInfo<dynamic> fi, Object? v, String indent) {
  final type = fi.type;
  if (fi.isGroupOrMessage) {
    final sub = fi.subBuilder?.call();
    return _csMessage(
        sub?.info_, v, sub?.info_.qualifiedMessageName ?? 'object', indent);
  }
  if (fi.isEnum) {
    final enumType = _enumTypeName(fi);
    final csType = _csTypeName(enumType.replaceAll('_', '.'));
    return '$csType.${csEnumValueName(enumType.split('_').last, '$v')}';
  }
  if (_isBytes(type)) return 'ByteString.CopyFrom(${_bytesVar(fi)})';
  if (_isString(type)) return _csString('$v');
  if (v is bool) return v ? 'true' : 'false';
  if (_isFloat(type) || _isDouble(type)) {
    final t = _isFloat(type) ? 'float' : 'double';
    if (v == 'NaN') return '$t.NaN';
    if (v == 'Infinity') return '$t.PositiveInfinity';
    if (v == '-Infinity') return '$t.NegativeInfinity';
    final n = v as num;
    return _isFloat(type) ? '${_floatText(n)}f' : '$n';
  }
  if (_is64(type)) return '${v}L';
  return '$v';
}
