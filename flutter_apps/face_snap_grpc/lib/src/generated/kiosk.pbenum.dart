// This is a generated file - do not edit.
//
// Generated from kiosk.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Face recognition models. Only models whose WEIGHTS are commercially
/// usable are offered (VGG-Face and ArcFace were removed 2026-07: their
/// weights are non-commercial / require a separate InsightFace license).
class Model extends $pb.ProtobufEnum {
  static const Model DLIB = Model._(0, _omitEnumNames ? '' : 'DLIB');
  static const Model FACENET512 =
      Model._(1, _omitEnumNames ? '' : 'FACENET512');
  static const Model SFACE = Model._(2, _omitEnumNames ? '' : 'SFACE');

  static const $core.List<Model> values = <Model>[
    DLIB,
    FACENET512,
    SFACE,
  ];

  static final $core.List<Model?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Model? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Model._(super.value, super.name);
}

class DistanceMetric extends $pb.ProtobufEnum {
  static const DistanceMetric COSINE =
      DistanceMetric._(0, _omitEnumNames ? '' : 'COSINE');
  static const DistanceMetric EUCLIDEAN =
      DistanceMetric._(1, _omitEnumNames ? '' : 'EUCLIDEAN');
  static const DistanceMetric EUCLIDEAN_L2 =
      DistanceMetric._(2, _omitEnumNames ? '' : 'EUCLIDEAN_L2');

  static const $core.List<DistanceMetric> values = <DistanceMetric>[
    COSINE,
    EUCLIDEAN,
    EUCLIDEAN_L2,
  ];

  static final $core.List<DistanceMetric?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static DistanceMetric? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DistanceMetric._(super.value, super.name);
}

class StatusType extends $pb.ProtobufEnum {
  static const StatusType OK = StatusType._(0, _omitEnumNames ? '' : 'OK');
  static const StatusType ERROR =
      StatusType._(1, _omitEnumNames ? '' : 'ERROR');
  static const StatusType TIMEOUT =
      StatusType._(3, _omitEnumNames ? '' : 'TIMEOUT');
  static const StatusType UNKNOWN =
      StatusType._(4, _omitEnumNames ? '' : 'UNKNOWN');

  static const $core.List<StatusType> values = <StatusType>[
    OK,
    ERROR,
    TIMEOUT,
    UNKNOWN,
  ];

  static final $core.List<StatusType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static StatusType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StatusType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
