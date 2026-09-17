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

import 'kiosk.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'kiosk.pbenum.dart';

class PreviewRequest extends $pb.GeneratedMessage {
  factory PreviewRequest({
    $core.int? cameraIndex,
    $core.int? maxSeconds,
  }) {
    final result = create();
    if (cameraIndex != null) result.cameraIndex = cameraIndex;
    if (maxSeconds != null) result.maxSeconds = maxSeconds;
    return result;
  }

  PreviewRequest._();

  factory PreviewRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'cameraIndex')
    ..aI(2, _omitFieldNames ? '' : 'maxSeconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewRequest copyWith(void Function(PreviewRequest) updates) =>
      super.copyWith((message) => updates(message as PreviewRequest))
          as PreviewRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewRequest create() => PreviewRequest._();
  @$core.override
  PreviewRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewRequest>(create);
  static PreviewRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get cameraIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set cameraIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCameraIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearCameraIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get maxSeconds => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxSeconds($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxSeconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxSeconds() => $_clearField(2);
}

class FaceRecognitionRequest extends $pb.GeneratedMessage {
  factory FaceRecognitionRequest({
    $core.List<$core.int>? image1,
    $core.List<$core.int>? image2,
    $core.double? threshold,
    Model? model,
    DistanceMetric? similarityMetric,
  }) {
    final result = create();
    if (image1 != null) result.image1 = image1;
    if (image2 != null) result.image2 = image2;
    if (threshold != null) result.threshold = threshold;
    if (model != null) result.model = model;
    if (similarityMetric != null) result.similarityMetric = similarityMetric;
    return result;
  }

  FaceRecognitionRequest._();

  factory FaceRecognitionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FaceRecognitionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FaceRecognitionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'image1', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'image2', $pb.PbFieldType.OY)
    ..aD(3, _omitFieldNames ? '' : 'threshold')
    ..aE<Model>(4, _omitFieldNames ? '' : 'model', enumValues: Model.values)
    ..aE<DistanceMetric>(5, _omitFieldNames ? '' : 'similarityMetric',
        enumValues: DistanceMetric.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FaceRecognitionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FaceRecognitionRequest copyWith(
          void Function(FaceRecognitionRequest) updates) =>
      super.copyWith((message) => updates(message as FaceRecognitionRequest))
          as FaceRecognitionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FaceRecognitionRequest create() => FaceRecognitionRequest._();
  @$core.override
  FaceRecognitionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FaceRecognitionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FaceRecognitionRequest>(create);
  static FaceRecognitionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get image1 => $_getN(0);
  @$pb.TagNumber(1)
  set image1($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasImage1() => $_has(0);
  @$pb.TagNumber(1)
  void clearImage1() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get image2 => $_getN(1);
  @$pb.TagNumber(2)
  set image2($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasImage2() => $_has(1);
  @$pb.TagNumber(2)
  void clearImage2() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get threshold => $_getN(2);
  @$pb.TagNumber(3)
  set threshold($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasThreshold() => $_has(2);
  @$pb.TagNumber(3)
  void clearThreshold() => $_clearField(3);

  @$pb.TagNumber(4)
  Model get model => $_getN(3);
  @$pb.TagNumber(4)
  set model(Model value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearModel() => $_clearField(4);

  @$pb.TagNumber(5)
  DistanceMetric get similarityMetric => $_getN(4);
  @$pb.TagNumber(5)
  set similarityMetric(DistanceMetric value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSimilarityMetric() => $_has(4);
  @$pb.TagNumber(5)
  void clearSimilarityMetric() => $_clearField(5);
}

class FaceRecognitionResponse extends $pb.GeneratedMessage {
  factory FaceRecognitionResponse({
    $core.bool? verified,
    $core.double? distance,
    $core.double? threshold,
    Model? model,
    DistanceMetric? similarityMetric,
    $core.double? time,
    StatusType? status,
  }) {
    final result = create();
    if (verified != null) result.verified = verified;
    if (distance != null) result.distance = distance;
    if (threshold != null) result.threshold = threshold;
    if (model != null) result.model = model;
    if (similarityMetric != null) result.similarityMetric = similarityMetric;
    if (time != null) result.time = time;
    if (status != null) result.status = status;
    return result;
  }

  FaceRecognitionResponse._();

  factory FaceRecognitionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FaceRecognitionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FaceRecognitionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'verified')
    ..aD(2, _omitFieldNames ? '' : 'distance')
    ..aD(3, _omitFieldNames ? '' : 'threshold')
    ..aE<Model>(4, _omitFieldNames ? '' : 'model', enumValues: Model.values)
    ..aE<DistanceMetric>(5, _omitFieldNames ? '' : 'similarityMetric',
        enumValues: DistanceMetric.values)
    ..aD(6, _omitFieldNames ? '' : 'time')
    ..aE<StatusType>(7, _omitFieldNames ? '' : 'status',
        enumValues: StatusType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FaceRecognitionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FaceRecognitionResponse copyWith(
          void Function(FaceRecognitionResponse) updates) =>
      super.copyWith((message) => updates(message as FaceRecognitionResponse))
          as FaceRecognitionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FaceRecognitionResponse create() => FaceRecognitionResponse._();
  @$core.override
  FaceRecognitionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FaceRecognitionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FaceRecognitionResponse>(create);
  static FaceRecognitionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get verified => $_getBF(0);
  @$pb.TagNumber(1)
  set verified($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVerified() => $_has(0);
  @$pb.TagNumber(1)
  void clearVerified() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get distance => $_getN(1);
  @$pb.TagNumber(2)
  set distance($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDistance() => $_has(1);
  @$pb.TagNumber(2)
  void clearDistance() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get threshold => $_getN(2);
  @$pb.TagNumber(3)
  set threshold($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasThreshold() => $_has(2);
  @$pb.TagNumber(3)
  void clearThreshold() => $_clearField(3);

  @$pb.TagNumber(4)
  Model get model => $_getN(3);
  @$pb.TagNumber(4)
  set model(Model value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearModel() => $_clearField(4);

  @$pb.TagNumber(5)
  DistanceMetric get similarityMetric => $_getN(4);
  @$pb.TagNumber(5)
  set similarityMetric(DistanceMetric value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSimilarityMetric() => $_has(4);
  @$pb.TagNumber(5)
  void clearSimilarityMetric() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get time => $_getN(5);
  @$pb.TagNumber(6)
  set time($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearTime() => $_clearField(6);

  @$pb.TagNumber(7)
  StatusType get status => $_getN(6);
  @$pb.TagNumber(7)
  set status(StatusType value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasStatus() => $_has(6);
  @$pb.TagNumber(7)
  void clearStatus() => $_clearField(7);
}

class KioskInfoResponse extends $pb.GeneratedMessage {
  factory KioskInfoResponse({
    KioskInfo? kioskInfo,
    $core.Iterable<CameraInfo>? cameraInfo,
  }) {
    final result = create();
    if (kioskInfo != null) result.kioskInfo = kioskInfo;
    if (cameraInfo != null) result.cameraInfo.addAll(cameraInfo);
    return result;
  }

  KioskInfoResponse._();

  factory KioskInfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KioskInfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KioskInfoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOM<KioskInfo>(1, _omitFieldNames ? '' : 'kioskInfo',
        protoName: 'kioskInfo', subBuilder: KioskInfo.create)
    ..pPM<CameraInfo>(2, _omitFieldNames ? '' : 'cameraInfo',
        protoName: 'cameraInfo', subBuilder: CameraInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KioskInfoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KioskInfoResponse copyWith(void Function(KioskInfoResponse) updates) =>
      super.copyWith((message) => updates(message as KioskInfoResponse))
          as KioskInfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KioskInfoResponse create() => KioskInfoResponse._();
  @$core.override
  KioskInfoResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static KioskInfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KioskInfoResponse>(create);
  static KioskInfoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  KioskInfo get kioskInfo => $_getN(0);
  @$pb.TagNumber(1)
  set kioskInfo(KioskInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKioskInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearKioskInfo() => $_clearField(1);
  @$pb.TagNumber(1)
  KioskInfo ensureKioskInfo() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<CameraInfo> get cameraInfo => $_getList(1);
}

class KioskInfo extends $pb.GeneratedMessage {
  factory KioskInfo({
    $core.String? serverIpAddress,
    $core.String? port,
    $core.int? numberOfCameras,
  }) {
    final result = create();
    if (serverIpAddress != null) result.serverIpAddress = serverIpAddress;
    if (port != null) result.port = port;
    if (numberOfCameras != null) result.numberOfCameras = numberOfCameras;
    return result;
  }

  KioskInfo._();

  factory KioskInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KioskInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KioskInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverIpAddress',
        protoName: 'serverIpAddress')
    ..aOS(2, _omitFieldNames ? '' : 'port')
    ..aI(3, _omitFieldNames ? '' : 'numberOfCameras',
        protoName: 'numberOfCameras')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KioskInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KioskInfo copyWith(void Function(KioskInfo) updates) =>
      super.copyWith((message) => updates(message as KioskInfo)) as KioskInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KioskInfo create() => KioskInfo._();
  @$core.override
  KioskInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static KioskInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<KioskInfo>(create);
  static KioskInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverIpAddress => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverIpAddress($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerIpAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerIpAddress() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get port => $_getSZ(1);
  @$pb.TagNumber(2)
  set port($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearPort() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get numberOfCameras => $_getIZ(2);
  @$pb.TagNumber(3)
  set numberOfCameras($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNumberOfCameras() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumberOfCameras() => $_clearField(3);
}

class CameraInfo extends $pb.GeneratedMessage {
  factory CameraInfo({
    $core.int? index,
  }) {
    final result = create();
    if (index != null) result.index = index;
    return result;
  }

  CameraInfo._();

  factory CameraInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CameraInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CameraInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraInfo copyWith(void Function(CameraInfo) updates) =>
      super.copyWith((message) => updates(message as CameraInfo)) as CameraInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CameraInfo create() => CameraInfo._();
  @$core.override
  CameraInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CameraInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CameraInfo>(create);
  static CameraInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);
}

class ProcessStepStatus extends $pb.GeneratedMessage {
  factory ProcessStepStatus({
    $core.int? index,
    $core.String? description,
    StatusType? status,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (description != null) result.description = description;
    if (status != null) result.status = status;
    return result;
  }

  ProcessStepStatus._();

  factory ProcessStepStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProcessStepStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProcessStepStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aE<StatusType>(3, _omitFieldNames ? '' : 'status',
        enumValues: StatusType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessStepStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessStepStatus copyWith(void Function(ProcessStepStatus) updates) =>
      super.copyWith((message) => updates(message as ProcessStepStatus))
          as ProcessStepStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProcessStepStatus create() => ProcessStepStatus._();
  @$core.override
  ProcessStepStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProcessStepStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProcessStepStatus>(create);
  static ProcessStepStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  StatusType get status => $_getN(2);
  @$pb.TagNumber(3)
  set status(StatusType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);
}

class ProcessImageData extends $pb.GeneratedMessage {
  factory ProcessImageData({
    $core.int? index,
    $core.int? width,
    $core.int? height,
    $core.String? format,
    $core.List<$core.int>? chunkData,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (format != null) result.format = format;
    if (chunkData != null) result.chunkData = chunkData;
    return result;
  }

  ProcessImageData._();

  factory ProcessImageData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProcessImageData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProcessImageData',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aI(2, _omitFieldNames ? '' : 'width')
    ..aI(3, _omitFieldNames ? '' : 'height')
    ..aOS(4, _omitFieldNames ? '' : 'format')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'chunkData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessImageData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessImageData copyWith(void Function(ProcessImageData) updates) =>
      super.copyWith((message) => updates(message as ProcessImageData))
          as ProcessImageData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProcessImageData create() => ProcessImageData._();
  @$core.override
  ProcessImageData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProcessImageData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProcessImageData>(create);
  static ProcessImageData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get width => $_getIZ(1);
  @$pb.TagNumber(2)
  set width($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWidth() => $_has(1);
  @$pb.TagNumber(2)
  void clearWidth() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get format => $_getSZ(3);
  @$pb.TagNumber(4)
  set format($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFormat() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormat() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get chunkData => $_getN(4);
  @$pb.TagNumber(5)
  set chunkData($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasChunkData() => $_has(4);
  @$pb.TagNumber(5)
  void clearChunkData() => $_clearField(5);
}

enum ProcessAutomaticResponse_Result { processStatus, imageData, notSet }

class ProcessAutomaticResponse extends $pb.GeneratedMessage {
  factory ProcessAutomaticResponse({
    ProcessStepStatus? processStatus,
    ProcessImageData? imageData,
  }) {
    final result = create();
    if (processStatus != null) result.processStatus = processStatus;
    if (imageData != null) result.imageData = imageData;
    return result;
  }

  ProcessAutomaticResponse._();

  factory ProcessAutomaticResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProcessAutomaticResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProcessAutomaticResponse_Result>
      _ProcessAutomaticResponse_ResultByTag = {
    1: ProcessAutomaticResponse_Result.processStatus,
    2: ProcessAutomaticResponse_Result.imageData,
    0: ProcessAutomaticResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProcessAutomaticResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProcessStepStatus>(1, _omitFieldNames ? '' : 'processStatus',
        protoName: 'processStatus', subBuilder: ProcessStepStatus.create)
    ..aOM<ProcessImageData>(2, _omitFieldNames ? '' : 'imageData',
        protoName: 'imageData', subBuilder: ProcessImageData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessAutomaticResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessAutomaticResponse copyWith(
          void Function(ProcessAutomaticResponse) updates) =>
      super.copyWith((message) => updates(message as ProcessAutomaticResponse))
          as ProcessAutomaticResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProcessAutomaticResponse create() => ProcessAutomaticResponse._();
  @$core.override
  ProcessAutomaticResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProcessAutomaticResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProcessAutomaticResponse>(create);
  static ProcessAutomaticResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProcessAutomaticResponse_Result whichResult() =>
      _ProcessAutomaticResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProcessStepStatus get processStatus => $_getN(0);
  @$pb.TagNumber(1)
  set processStatus(ProcessStepStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProcessStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearProcessStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  ProcessStepStatus ensureProcessStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  ProcessImageData get imageData => $_getN(1);
  @$pb.TagNumber(2)
  set imageData(ProcessImageData value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasImageData() => $_has(1);
  @$pb.TagNumber(2)
  void clearImageData() => $_clearField(2);
  @$pb.TagNumber(2)
  ProcessImageData ensureImageData() => $_ensure(1);
}

enum ProcessManualResponse_Result { processStatus, imageData, notSet }

class ProcessManualResponse extends $pb.GeneratedMessage {
  factory ProcessManualResponse({
    ProcessStepStatus? processStatus,
    ProcessImageData? imageData,
  }) {
    final result = create();
    if (processStatus != null) result.processStatus = processStatus;
    if (imageData != null) result.imageData = imageData;
    return result;
  }

  ProcessManualResponse._();

  factory ProcessManualResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProcessManualResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProcessManualResponse_Result>
      _ProcessManualResponse_ResultByTag = {
    1: ProcessManualResponse_Result.processStatus,
    2: ProcessManualResponse_Result.imageData,
    0: ProcessManualResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProcessManualResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProcessStepStatus>(1, _omitFieldNames ? '' : 'processStatus',
        protoName: 'processStatus', subBuilder: ProcessStepStatus.create)
    ..aOM<ProcessImageData>(2, _omitFieldNames ? '' : 'imageData',
        protoName: 'imageData', subBuilder: ProcessImageData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessManualResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessManualResponse copyWith(
          void Function(ProcessManualResponse) updates) =>
      super.copyWith((message) => updates(message as ProcessManualResponse))
          as ProcessManualResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProcessManualResponse create() => ProcessManualResponse._();
  @$core.override
  ProcessManualResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProcessManualResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProcessManualResponse>(create);
  static ProcessManualResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProcessManualResponse_Result whichResult() =>
      _ProcessManualResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProcessStepStatus get processStatus => $_getN(0);
  @$pb.TagNumber(1)
  set processStatus(ProcessStepStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProcessStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearProcessStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  ProcessStepStatus ensureProcessStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  ProcessImageData get imageData => $_getN(1);
  @$pb.TagNumber(2)
  set imageData(ProcessImageData value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasImageData() => $_has(1);
  @$pb.TagNumber(2)
  void clearImageData() => $_clearField(2);
  @$pb.TagNumber(2)
  ProcessImageData ensureImageData() => $_ensure(1);
}

class FocusedCameraRequest extends $pb.GeneratedMessage {
  factory FocusedCameraRequest({
    $core.int? timeoutInMs,
  }) {
    final result = create();
    if (timeoutInMs != null) result.timeoutInMs = timeoutInMs;
    return result;
  }

  FocusedCameraRequest._();

  factory FocusedCameraRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FocusedCameraRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FocusedCameraRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'timeoutInMs', protoName: 'timeoutInMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusedCameraRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusedCameraRequest copyWith(void Function(FocusedCameraRequest) updates) =>
      super.copyWith((message) => updates(message as FocusedCameraRequest))
          as FocusedCameraRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FocusedCameraRequest create() => FocusedCameraRequest._();
  @$core.override
  FocusedCameraRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FocusedCameraRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FocusedCameraRequest>(create);
  static FocusedCameraRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get timeoutInMs => $_getIZ(0);
  @$pb.TagNumber(1)
  set timeoutInMs($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimeoutInMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimeoutInMs() => $_clearField(1);
}

class FocusedCameraResponse extends $pb.GeneratedMessage {
  factory FocusedCameraResponse({
    $core.int? index,
    StatusType? status,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (status != null) result.status = status;
    return result;
  }

  FocusedCameraResponse._();

  factory FocusedCameraResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FocusedCameraResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FocusedCameraResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aE<StatusType>(2, _omitFieldNames ? '' : 'status',
        enumValues: StatusType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusedCameraResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusedCameraResponse copyWith(
          void Function(FocusedCameraResponse) updates) =>
      super.copyWith((message) => updates(message as FocusedCameraResponse))
          as FocusedCameraResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FocusedCameraResponse create() => FocusedCameraResponse._();
  @$core.override
  FocusedCameraResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FocusedCameraResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FocusedCameraResponse>(create);
  static FocusedCameraResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  StatusType get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(StatusType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

class HighResImageRequest extends $pb.GeneratedMessage {
  factory HighResImageRequest({
    $core.int? index,
    $core.int? timeoutInMs,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (timeoutInMs != null) result.timeoutInMs = timeoutInMs;
    return result;
  }

  HighResImageRequest._();

  factory HighResImageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HighResImageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HighResImageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aI(2, _omitFieldNames ? '' : 'timeoutInMs', protoName: 'timeoutInMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HighResImageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HighResImageRequest copyWith(void Function(HighResImageRequest) updates) =>
      super.copyWith((message) => updates(message as HighResImageRequest))
          as HighResImageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HighResImageRequest create() => HighResImageRequest._();
  @$core.override
  HighResImageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HighResImageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HighResImageRequest>(create);
  static HighResImageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get timeoutInMs => $_getIZ(1);
  @$pb.TagNumber(2)
  set timeoutInMs($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimeoutInMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimeoutInMs() => $_clearField(2);
}

class HighResImageResponse extends $pb.GeneratedMessage {
  factory HighResImageResponse({
    ProcessImageData? processImageData,
    StatusType? statusType,
  }) {
    final result = create();
    if (processImageData != null) result.processImageData = processImageData;
    if (statusType != null) result.statusType = statusType;
    return result;
  }

  HighResImageResponse._();

  factory HighResImageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HighResImageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HighResImageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOM<ProcessImageData>(1, _omitFieldNames ? '' : 'processImageData',
        protoName: 'processImageData', subBuilder: ProcessImageData.create)
    ..aE<StatusType>(2, _omitFieldNames ? '' : 'statusType',
        protoName: 'statusType', enumValues: StatusType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HighResImageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HighResImageResponse copyWith(void Function(HighResImageResponse) updates) =>
      super.copyWith((message) => updates(message as HighResImageResponse))
          as HighResImageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HighResImageResponse create() => HighResImageResponse._();
  @$core.override
  HighResImageResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HighResImageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HighResImageResponse>(create);
  static HighResImageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ProcessImageData get processImageData => $_getN(0);
  @$pb.TagNumber(1)
  set processImageData(ProcessImageData value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProcessImageData() => $_has(0);
  @$pb.TagNumber(1)
  void clearProcessImageData() => $_clearField(1);
  @$pb.TagNumber(1)
  ProcessImageData ensureProcessImageData() => $_ensure(0);

  @$pb.TagNumber(2)
  StatusType get statusType => $_getN(1);
  @$pb.TagNumber(2)
  set statusType(StatusType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatusType() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatusType() => $_clearField(2);
}

class HighResIcaoImageRequest extends $pb.GeneratedMessage {
  factory HighResIcaoImageRequest({
    $core.int? index,
    $core.int? timeoutInMs,
    $core.bool? eyesCheck,
    $core.bool? lipsCheck,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (timeoutInMs != null) result.timeoutInMs = timeoutInMs;
    if (eyesCheck != null) result.eyesCheck = eyesCheck;
    if (lipsCheck != null) result.lipsCheck = lipsCheck;
    return result;
  }

  HighResIcaoImageRequest._();

  factory HighResIcaoImageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HighResIcaoImageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HighResIcaoImageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aI(2, _omitFieldNames ? '' : 'timeoutInMs', protoName: 'timeoutInMs')
    ..aOB(3, _omitFieldNames ? '' : 'eyesCheck', protoName: 'eyesCheck')
    ..aOB(4, _omitFieldNames ? '' : 'lipsCheck', protoName: 'lipsCheck')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HighResIcaoImageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HighResIcaoImageRequest copyWith(
          void Function(HighResIcaoImageRequest) updates) =>
      super.copyWith((message) => updates(message as HighResIcaoImageRequest))
          as HighResIcaoImageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HighResIcaoImageRequest create() => HighResIcaoImageRequest._();
  @$core.override
  HighResIcaoImageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HighResIcaoImageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HighResIcaoImageRequest>(create);
  static HighResIcaoImageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get timeoutInMs => $_getIZ(1);
  @$pb.TagNumber(2)
  set timeoutInMs($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimeoutInMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimeoutInMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get eyesCheck => $_getBF(2);
  @$pb.TagNumber(3)
  set eyesCheck($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEyesCheck() => $_has(2);
  @$pb.TagNumber(3)
  void clearEyesCheck() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get lipsCheck => $_getBF(3);
  @$pb.TagNumber(4)
  set lipsCheck($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLipsCheck() => $_has(3);
  @$pb.TagNumber(4)
  void clearLipsCheck() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
