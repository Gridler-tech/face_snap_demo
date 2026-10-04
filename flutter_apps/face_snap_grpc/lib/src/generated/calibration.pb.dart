// This is a generated file - do not edit.
//
// Generated from calibration.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CalibrateType extends $pb.GeneratedMessage {
  factory CalibrateType({
    $core.String? idModelId,
    $core.int? linuxCameraIndex,
    $core.int? calibratedCameraIndex,
  }) {
    final result = create();
    if (idModelId != null) result.idModelId = idModelId;
    if (linuxCameraIndex != null) result.linuxCameraIndex = linuxCameraIndex;
    if (calibratedCameraIndex != null)
      result.calibratedCameraIndex = calibratedCameraIndex;
    return result;
  }

  CalibrateType._();

  factory CalibrateType.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CalibrateType.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CalibrateType',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calibration'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idModelId')
    ..aI(2, _omitFieldNames ? '' : 'linuxCameraIndex')
    ..aI(3, _omitFieldNames ? '' : 'calibratedCameraIndex')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateType clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateType copyWith(void Function(CalibrateType) updates) =>
      super.copyWith((message) => updates(message as CalibrateType))
          as CalibrateType;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CalibrateType create() => CalibrateType._();
  @$core.override
  CalibrateType createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CalibrateType getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CalibrateType>(create);
  static CalibrateType? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get idModelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set idModelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get linuxCameraIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set linuxCameraIndex($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLinuxCameraIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearLinuxCameraIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get calibratedCameraIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set calibratedCameraIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCalibratedCameraIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearCalibratedCameraIndex() => $_clearField(3);
}

class CalibrationSettingsResponse extends $pb.GeneratedMessage {
  factory CalibrationSettingsResponse({
    $core.Iterable<CalibrateType>? calibrate,
  }) {
    final result = create();
    if (calibrate != null) result.calibrate.addAll(calibrate);
    return result;
  }

  CalibrationSettingsResponse._();

  factory CalibrationSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CalibrationSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CalibrationSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calibration'),
      createEmptyInstance: create)
    ..pPM<CalibrateType>(1, _omitFieldNames ? '' : 'calibrate',
        subBuilder: CalibrateType.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrationSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrationSettingsResponse copyWith(
          void Function(CalibrationSettingsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as CalibrationSettingsResponse))
          as CalibrationSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CalibrationSettingsResponse create() =>
      CalibrationSettingsResponse._();
  @$core.override
  CalibrationSettingsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CalibrationSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CalibrationSettingsResponse>(create);
  static CalibrationSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CalibrateType> get calibrate => $_getList(0);
}

class CalibrateRequest extends $pb.GeneratedMessage {
  factory CalibrateRequest({
    $core.Iterable<CalibrateType>? calibrate,
  }) {
    final result = create();
    if (calibrate != null) result.calibrate.addAll(calibrate);
    return result;
  }

  CalibrateRequest._();

  factory CalibrateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CalibrateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CalibrateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calibration'),
      createEmptyInstance: create)
    ..pPM<CalibrateType>(1, _omitFieldNames ? '' : 'calibrate',
        subBuilder: CalibrateType.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateRequest copyWith(void Function(CalibrateRequest) updates) =>
      super.copyWith((message) => updates(message as CalibrateRequest))
          as CalibrateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CalibrateRequest create() => CalibrateRequest._();
  @$core.override
  CalibrateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CalibrateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CalibrateRequest>(create);
  static CalibrateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CalibrateType> get calibrate => $_getList(0);
}

class CalibrateResponse extends $pb.GeneratedMessage {
  factory CalibrateResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  CalibrateResponse._();

  factory CalibrateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CalibrateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CalibrateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calibration'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateResponse copyWith(void Function(CalibrateResponse) updates) =>
      super.copyWith((message) => updates(message as CalibrateResponse))
          as CalibrateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CalibrateResponse create() => CalibrateResponse._();
  @$core.override
  CalibrateResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CalibrateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CalibrateResponse>(create);
  static CalibrateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

/// One attached camera in the result of CalibrateByPerson.
class PersonCalibrationCamera extends $pb.GeneratedMessage {
  factory PersonCalibrationCamera({
    $core.String? idModelId,
    $core.int? linuxCameraIndex,
    $core.int? proposedPosition,
    $core.double? faceHeight,
    $core.int? roundsSeen,
  }) {
    final result = create();
    if (idModelId != null) result.idModelId = idModelId;
    if (linuxCameraIndex != null) result.linuxCameraIndex = linuxCameraIndex;
    if (proposedPosition != null) result.proposedPosition = proposedPosition;
    if (faceHeight != null) result.faceHeight = faceHeight;
    if (roundsSeen != null) result.roundsSeen = roundsSeen;
    return result;
  }

  PersonCalibrationCamera._();

  factory PersonCalibrationCamera.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PersonCalibrationCamera.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PersonCalibrationCamera',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calibration'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idModelId')
    ..aI(2, _omitFieldNames ? '' : 'linuxCameraIndex')
    ..aI(3, _omitFieldNames ? '' : 'proposedPosition')
    ..aD(4, _omitFieldNames ? '' : 'faceHeight')
    ..aI(5, _omitFieldNames ? '' : 'roundsSeen')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PersonCalibrationCamera clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PersonCalibrationCamera copyWith(
          void Function(PersonCalibrationCamera) updates) =>
      super.copyWith((message) => updates(message as PersonCalibrationCamera))
          as PersonCalibrationCamera;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PersonCalibrationCamera create() => PersonCalibrationCamera._();
  @$core.override
  PersonCalibrationCamera createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PersonCalibrationCamera getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PersonCalibrationCamera>(create);
  static PersonCalibrationCamera? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get idModelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set idModelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get linuxCameraIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set linuxCameraIndex($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLinuxCameraIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearLinuxCameraIndex() => $_clearField(2);

  /// 1 = bottom. 0 = no position proposed (the calibration did not succeed).
  @$pb.TagNumber(3)
  $core.int get proposedPosition => $_getIZ(2);
  @$pb.TagNumber(3)
  set proposedPosition($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProposedPosition() => $_has(2);
  @$pb.TagNumber(3)
  void clearProposedPosition() => $_clearField(3);

  /// Where the face was seen in this camera's image: 0 = top, 1 = bottom (median of
  /// the rounds). -1 = the camera never saw the face.
  @$pb.TagNumber(4)
  $core.double get faceHeight => $_getN(3);
  @$pb.TagNumber(4)
  set faceHeight($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFaceHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearFaceHeight() => $_clearField(4);

  /// In how many of the rounds this camera saw the face.
  @$pb.TagNumber(5)
  $core.int get roundsSeen => $_getIZ(4);
  @$pb.TagNumber(5)
  set roundsSeen($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRoundsSeen() => $_has(4);
  @$pb.TagNumber(5)
  void clearRoundsSeen() => $_clearField(5);
}

class PersonCalibrationResponse extends $pb.GeneratedMessage {
  factory PersonCalibrationResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<PersonCalibrationCamera>? cameras,
    $core.int? rounds,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (cameras != null) result.cameras.addAll(cameras);
    if (rounds != null) result.rounds = rounds;
    return result;
  }

  PersonCalibrationResponse._();

  factory PersonCalibrationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PersonCalibrationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PersonCalibrationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calibration'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPM<PersonCalibrationCamera>(3, _omitFieldNames ? '' : 'cameras',
        subBuilder: PersonCalibrationCamera.create)
    ..aI(4, _omitFieldNames ? '' : 'rounds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PersonCalibrationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PersonCalibrationResponse copyWith(
          void Function(PersonCalibrationResponse) updates) =>
      super.copyWith((message) => updates(message as PersonCalibrationResponse))
          as PersonCalibrationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PersonCalibrationResponse create() => PersonCalibrationResponse._();
  @$core.override
  PersonCalibrationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PersonCalibrationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PersonCalibrationResponse>(create);
  static PersonCalibrationResponse? _defaultInstance;

  /// true = every camera has a proposed_position. false = nothing is proposed and
  /// message says what to change.
  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<PersonCalibrationCamera> get cameras => $_getList(2);

  @$pb.TagNumber(4)
  $core.int get rounds => $_getIZ(3);
  @$pb.TagNumber(4)
  set rounds($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRounds() => $_has(3);
  @$pb.TagNumber(4)
  void clearRounds() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
