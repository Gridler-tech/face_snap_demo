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

import 'lights.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'lights.pbenum.dart';

/// Progress of one white-point tuning run. On the final update (done=true):
/// success means the tuned R/G/B intensities are stored in the lighting
/// settings; on failure the originals were restored and error says why.
class AutoTuneUpdate extends $pb.GeneratedMessage {
  factory AutoTuneUpdate({
    $core.String? message,
    $core.int? red,
    $core.int? green,
    $core.int? blue,
    $core.double? stripLux,
    $core.double? distance,
    $core.bool? done,
    $core.bool? success,
    $core.String? error,
  }) {
    final result = create();
    if (message != null) result.message = message;
    if (red != null) result.red = red;
    if (green != null) result.green = green;
    if (blue != null) result.blue = blue;
    if (stripLux != null) result.stripLux = stripLux;
    if (distance != null) result.distance = distance;
    if (done != null) result.done = done;
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  AutoTuneUpdate._();

  factory AutoTuneUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AutoTuneUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AutoTuneUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'lights'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..aI(2, _omitFieldNames ? '' : 'red')
    ..aI(3, _omitFieldNames ? '' : 'green')
    ..aI(4, _omitFieldNames ? '' : 'blue')
    ..aD(5, _omitFieldNames ? '' : 'stripLux', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'distance', fieldType: $pb.PbFieldType.OF)
    ..aOB(7, _omitFieldNames ? '' : 'done')
    ..aOB(8, _omitFieldNames ? '' : 'success')
    ..aOS(9, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AutoTuneUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AutoTuneUpdate copyWith(void Function(AutoTuneUpdate) updates) =>
      super.copyWith((message) => updates(message as AutoTuneUpdate))
          as AutoTuneUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AutoTuneUpdate create() => AutoTuneUpdate._();
  @$core.override
  AutoTuneUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AutoTuneUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AutoTuneUpdate>(create);
  static AutoTuneUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get red => $_getIZ(1);
  @$pb.TagNumber(2)
  set red($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRed() => $_has(1);
  @$pb.TagNumber(2)
  void clearRed() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get green => $_getIZ(2);
  @$pb.TagNumber(3)
  set green($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGreen() => $_has(2);
  @$pb.TagNumber(3)
  void clearGreen() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get blue => $_getIZ(3);
  @$pb.TagNumber(4)
  set blue($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBlue() => $_has(3);
  @$pb.TagNumber(4)
  void clearBlue() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get stripLux => $_getN(4);
  @$pb.TagNumber(5)
  set stripLux($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStripLux() => $_has(4);
  @$pb.TagNumber(5)
  void clearStripLux() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get distance => $_getN(5);
  @$pb.TagNumber(6)
  set distance($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDistance() => $_has(5);
  @$pb.TagNumber(6)
  void clearDistance() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get done => $_getBF(6);
  @$pb.TagNumber(7)
  set done($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDone() => $_has(6);
  @$pb.TagNumber(7)
  void clearDone() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get success => $_getBF(7);
  @$pb.TagNumber(8)
  set success($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSuccess() => $_has(7);
  @$pb.TagNumber(8)
  void clearSuccess() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get error => $_getSZ(8);
  @$pb.TagNumber(9)
  set error($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasError() => $_has(8);
  @$pb.TagNumber(9)
  void clearError() => $_clearField(9);
}

/// request which sets the lights on or off
class AllLightsRequest extends $pb.GeneratedMessage {
  factory AllLightsRequest({
    $core.bool? status,
  }) {
    final result = create();
    if (status != null) result.status = status;
    return result;
  }

  AllLightsRequest._();

  factory AllLightsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AllLightsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AllLightsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'lights'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AllLightsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AllLightsRequest copyWith(void Function(AllLightsRequest) updates) =>
      super.copyWith((message) => updates(message as AllLightsRequest))
          as AllLightsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AllLightsRequest create() => AllLightsRequest._();
  @$core.override
  AllLightsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AllLightsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AllLightsRequest>(create);
  static AllLightsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get status => $_getBF(0);
  @$pb.TagNumber(1)
  set status($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
}

/// request which sets the light at a specific camera index
class LightIndexRequest extends $pb.GeneratedMessage {
  factory LightIndexRequest({
    $core.int? index,
  }) {
    final result = create();
    if (index != null) result.index = index;
    return result;
  }

  LightIndexRequest._();

  factory LightIndexRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LightIndexRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LightIndexRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'lights'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightIndexRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightIndexRequest copyWith(void Function(LightIndexRequest) updates) =>
      super.copyWith((message) => updates(message as LightIndexRequest))
          as LightIndexRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LightIndexRequest create() => LightIndexRequest._();
  @$core.override
  LightIndexRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LightIndexRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LightIndexRequest>(create);
  static LightIndexRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);
}

class BacklightRequest extends $pb.GeneratedMessage {
  factory BacklightRequest({
    Backlight? backlight,
    $core.bool? on,
  }) {
    final result = create();
    if (backlight != null) result.backlight = backlight;
    if (on != null) result.on = on;
    return result;
  }

  BacklightRequest._();

  factory BacklightRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BacklightRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BacklightRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'lights'),
      createEmptyInstance: create)
    ..aE<Backlight>(1, _omitFieldNames ? '' : 'backlight',
        enumValues: Backlight.values)
    ..aOB(2, _omitFieldNames ? '' : 'on')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacklightRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacklightRequest copyWith(void Function(BacklightRequest) updates) =>
      super.copyWith((message) => updates(message as BacklightRequest))
          as BacklightRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BacklightRequest create() => BacklightRequest._();
  @$core.override
  BacklightRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BacklightRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BacklightRequest>(create);
  static BacklightRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Backlight get backlight => $_getN(0);
  @$pb.TagNumber(1)
  set backlight(Backlight value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBacklight() => $_has(0);
  @$pb.TagNumber(1)
  void clearBacklight() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get on => $_getBF(1);
  @$pb.TagNumber(2)
  set on($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOn() => $_has(1);
  @$pb.TagNumber(2)
  void clearOn() => $_clearField(2);
}

/// connected = the USB relay module is attached; the two states are read back
/// from the module (both false while it is not connected).
class BacklightStatus extends $pb.GeneratedMessage {
  factory BacklightStatus({
    $core.bool? connected,
    $core.bool? backlightBottom,
    $core.bool? backlightTop,
  }) {
    final result = create();
    if (connected != null) result.connected = connected;
    if (backlightBottom != null) result.backlightBottom = backlightBottom;
    if (backlightTop != null) result.backlightTop = backlightTop;
    return result;
  }

  BacklightStatus._();

  factory BacklightStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BacklightStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BacklightStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'lights'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'connected')
    ..aOB(2, _omitFieldNames ? '' : 'backlightBottom')
    ..aOB(3, _omitFieldNames ? '' : 'backlightTop')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacklightStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacklightStatus copyWith(void Function(BacklightStatus) updates) =>
      super.copyWith((message) => updates(message as BacklightStatus))
          as BacklightStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BacklightStatus create() => BacklightStatus._();
  @$core.override
  BacklightStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BacklightStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BacklightStatus>(create);
  static BacklightStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get connected => $_getBF(0);
  @$pb.TagNumber(1)
  set connected($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnected() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnected() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get backlightBottom => $_getBF(1);
  @$pb.TagNumber(2)
  set backlightBottom($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBacklightBottom() => $_has(1);
  @$pb.TagNumber(2)
  void clearBacklightBottom() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get backlightTop => $_getBF(2);
  @$pb.TagNumber(3)
  set backlightTop($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBacklightTop() => $_has(2);
  @$pb.TagNumber(3)
  void clearBacklightTop() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
