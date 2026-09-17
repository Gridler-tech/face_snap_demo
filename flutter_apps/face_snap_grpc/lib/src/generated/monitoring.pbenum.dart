// This is a generated file - do not edit.
//
// Generated from monitoring.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class UsageType extends $pb.ProtobufEnum {
  static const UsageType CPU = UsageType._(0, _omitEnumNames ? '' : 'CPU');
  static const UsageType MEMORY =
      UsageType._(1, _omitEnumNames ? '' : 'MEMORY');
  static const UsageType CPU_COUNT =
      UsageType._(2, _omitEnumNames ? '' : 'CPU_COUNT');
  static const UsageType NET_IF_ADDRS =
      UsageType._(3, _omitEnumNames ? '' : 'NET_IF_ADDRS');
  static const UsageType NET_IO_COUNTERS =
      UsageType._(4, _omitEnumNames ? '' : 'NET_IO_COUNTERS');
  static const UsageType BOOT_TIME =
      UsageType._(5, _omitEnumNames ? '' : 'BOOT_TIME');

  static const $core.List<UsageType> values = <UsageType>[
    CPU,
    MEMORY,
    CPU_COUNT,
    NET_IF_ADDRS,
    NET_IO_COUNTERS,
    BOOT_TIME,
  ];

  static final $core.List<UsageType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static UsageType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const UsageType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
