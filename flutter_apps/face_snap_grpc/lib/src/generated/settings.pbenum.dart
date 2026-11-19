// This is a generated file - do not edit.
//
// Generated from settings.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Which light lights the photo (kiosk setting glare_free_light). The glare-free
/// light: the rings above the next camera up and the backlights, the camera's ring
/// breathing; one natural catchlight instead of a row of LED dots.
class GlareFreeLight extends $pb.ProtobufEnum {
  static const GlareFreeLight GLARE_FREE_LIGHT_OFF =
      GlareFreeLight._(0, _omitEnumNames ? '' : 'GLARE_FREE_LIGHT_OFF');
  static const GlareFreeLight GLARE_FREE_LIGHT_GLASSES =
      GlareFreeLight._(1, _omitEnumNames ? '' : 'GLARE_FREE_LIGHT_GLASSES');
  static const GlareFreeLight GLARE_FREE_LIGHT_EVERYONE =
      GlareFreeLight._(2, _omitEnumNames ? '' : 'GLARE_FREE_LIGHT_EVERYONE');

  static const $core.List<GlareFreeLight> values = <GlareFreeLight>[
    GLARE_FREE_LIGHT_OFF,
    GLARE_FREE_LIGHT_GLASSES,
    GLARE_FREE_LIGHT_EVERYONE,
  ];

  static final $core.List<GlareFreeLight?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static GlareFreeLight? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GlareFreeLight._(super.value, super.name);
}

class ColumnSaveOutcome extends $pb.ProtobufEnum {
  static const ColumnSaveOutcome COLUMN_SAVE_OUTCOME_WRITTEN =
      ColumnSaveOutcome._(
          0, _omitEnumNames ? '' : 'COLUMN_SAVE_OUTCOME_WRITTEN');
  static const ColumnSaveOutcome COLUMN_SAVE_OUTCOME_PENDING =
      ColumnSaveOutcome._(
          1, _omitEnumNames ? '' : 'COLUMN_SAVE_OUTCOME_PENDING');
  static const ColumnSaveOutcome COLUMN_SAVE_OUTCOME_NOTHING =
      ColumnSaveOutcome._(
          2, _omitEnumNames ? '' : 'COLUMN_SAVE_OUTCOME_NOTHING');

  static const $core.List<ColumnSaveOutcome> values = <ColumnSaveOutcome>[
    COLUMN_SAVE_OUTCOME_WRITTEN,
    COLUMN_SAVE_OUTCOME_PENDING,
    COLUMN_SAVE_OUTCOME_NOTHING,
  ];

  static final $core.List<ColumnSaveOutcome?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ColumnSaveOutcome? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ColumnSaveOutcome._(super.value, super.name);
}

class ColumnFactorySource extends $pb.ProtobufEnum {
  static const ColumnFactorySource COLUMN_FACTORY_SOURCE_STANDARD =
      ColumnFactorySource._(
          0, _omitEnumNames ? '' : 'COLUMN_FACTORY_SOURCE_STANDARD');
  static const ColumnFactorySource COLUMN_FACTORY_SOURCE_VALUES_IN_FORCE =
      ColumnFactorySource._(
          1, _omitEnumNames ? '' : 'COLUMN_FACTORY_SOURCE_VALUES_IN_FORCE');

  static const $core.List<ColumnFactorySource> values = <ColumnFactorySource>[
    COLUMN_FACTORY_SOURCE_STANDARD,
    COLUMN_FACTORY_SOURCE_VALUES_IN_FORCE,
  ];

  static final $core.List<ColumnFactorySource?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static ColumnFactorySource? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ColumnFactorySource._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
