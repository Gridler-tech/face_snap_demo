// This is a generated file - do not edit.
//
// Generated from lights.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Backlight extends $pb.ProtobufEnum {
  static const Backlight BACKLIGHT_UNSPECIFIED =
      Backlight._(0, _omitEnumNames ? '' : 'BACKLIGHT_UNSPECIFIED');
  static const Backlight BACKLIGHT_BOTTOM =
      Backlight._(1, _omitEnumNames ? '' : 'BACKLIGHT_BOTTOM');
  static const Backlight BACKLIGHT_TOP =
      Backlight._(2, _omitEnumNames ? '' : 'BACKLIGHT_TOP');

  static const $core.List<Backlight> values = <Backlight>[
    BACKLIGHT_UNSPECIFIED,
    BACKLIGHT_BOTTOM,
    BACKLIGHT_TOP,
  ];

  static final $core.List<Backlight?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Backlight? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Backlight._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
