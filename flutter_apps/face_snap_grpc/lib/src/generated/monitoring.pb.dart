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

import 'monitoring.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'monitoring.pbenum.dart';

class KioskStatusResponse extends $pb.GeneratedMessage {
  factory KioskStatusResponse({
    $core.String? description,
    $core.String? status,
  }) {
    final result = create();
    if (description != null) result.description = description;
    if (status != null) result.status = status;
    return result;
  }

  KioskStatusResponse._();

  factory KioskStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KioskStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KioskStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'monitoring'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'description')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KioskStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KioskStatusResponse copyWith(void Function(KioskStatusResponse) updates) =>
      super.copyWith((message) => updates(message as KioskStatusResponse))
          as KioskStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KioskStatusResponse create() => KioskStatusResponse._();
  @$core.override
  KioskStatusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static KioskStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KioskStatusResponse>(create);
  static KioskStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get description => $_getSZ(0);
  @$pb.TagNumber(1)
  set description($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDescription() => $_has(0);
  @$pb.TagNumber(1)
  void clearDescription() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

class UsageResponse extends $pb.GeneratedMessage {
  factory UsageResponse({
    UsageType? usageType,
    $core.String? usage,
  }) {
    final result = create();
    if (usageType != null) result.usageType = usageType;
    if (usage != null) result.usage = usage;
    return result;
  }

  UsageResponse._();

  factory UsageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UsageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UsageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'monitoring'),
      createEmptyInstance: create)
    ..aE<UsageType>(1, _omitFieldNames ? '' : 'usageType',
        enumValues: UsageType.values)
    ..aOS(2, _omitFieldNames ? '' : 'usage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UsageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UsageResponse copyWith(void Function(UsageResponse) updates) =>
      super.copyWith((message) => updates(message as UsageResponse))
          as UsageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UsageResponse create() => UsageResponse._();
  @$core.override
  UsageResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UsageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UsageResponse>(create);
  static UsageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  UsageType get usageType => $_getN(0);
  @$pb.TagNumber(1)
  set usageType(UsageType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUsageType() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsageType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get usage => $_getSZ(1);
  @$pb.TagNumber(2)
  set usage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsage() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsage() => $_clearField(2);
}

/// One OPT4048 reading. When available is false the sensor (or the LED board)
/// could not be read and error says why; the numeric fields are then meaningless.
class LightMeasurementResponse extends $pb.GeneratedMessage {
  factory LightMeasurementResponse({
    $core.bool? available,
    $core.double? lux,
    $core.double? cct,
    $core.double? cieX,
    $core.double? cieY,
    $core.String? error,
  }) {
    final result = create();
    if (available != null) result.available = available;
    if (lux != null) result.lux = lux;
    if (cct != null) result.cct = cct;
    if (cieX != null) result.cieX = cieX;
    if (cieY != null) result.cieY = cieY;
    if (error != null) result.error = error;
    return result;
  }

  LightMeasurementResponse._();

  factory LightMeasurementResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LightMeasurementResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LightMeasurementResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'monitoring'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'available')
    ..aD(2, _omitFieldNames ? '' : 'lux', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'cct', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'cieX', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'cieY', fieldType: $pb.PbFieldType.OF)
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightMeasurementResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightMeasurementResponse copyWith(
          void Function(LightMeasurementResponse) updates) =>
      super.copyWith((message) => updates(message as LightMeasurementResponse))
          as LightMeasurementResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LightMeasurementResponse create() => LightMeasurementResponse._();
  @$core.override
  LightMeasurementResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LightMeasurementResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LightMeasurementResponse>(create);
  static LightMeasurementResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get available => $_getBF(0);
  @$pb.TagNumber(1)
  set available($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAvailable() => $_has(0);
  @$pb.TagNumber(1)
  void clearAvailable() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lux => $_getN(1);
  @$pb.TagNumber(2)
  set lux($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLux() => $_has(1);
  @$pb.TagNumber(2)
  void clearLux() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get cct => $_getN(2);
  @$pb.TagNumber(3)
  set cct($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCct() => $_has(2);
  @$pb.TagNumber(3)
  void clearCct() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get cieX => $_getN(3);
  @$pb.TagNumber(4)
  set cieX($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCieX() => $_has(3);
  @$pb.TagNumber(4)
  void clearCieX() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get cieY => $_getN(4);
  @$pb.TagNumber(5)
  set cieY($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCieY() => $_has(4);
  @$pb.TagNumber(5)
  void clearCieY() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
