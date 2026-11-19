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

class LedMix extends $pb.GeneratedMessage {
  factory LedMix({
    $core.int? red,
    $core.int? green,
    $core.int? blue,
  }) {
    final result = create();
    if (red != null) result.red = red;
    if (green != null) result.green = green;
    if (blue != null) result.blue = blue;
    return result;
  }

  LedMix._();

  factory LedMix.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LedMix.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LedMix',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'red')
    ..aI(2, _omitFieldNames ? '' : 'green')
    ..aI(3, _omitFieldNames ? '' : 'blue')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LedMix clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LedMix copyWith(void Function(LedMix) updates) =>
      super.copyWith((message) => updates(message as LedMix)) as LedMix;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LedMix create() => LedMix._();
  @$core.override
  LedMix createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LedMix getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LedMix>(create);
  static LedMix? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get red => $_getIZ(0);
  @$pb.TagNumber(1)
  set red($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRed() => $_has(0);
  @$pb.TagNumber(1)
  void clearRed() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get green => $_getIZ(1);
  @$pb.TagNumber(2)
  set green($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGreen() => $_has(1);
  @$pb.TagNumber(2)
  void clearGreen() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get blue => $_getIZ(2);
  @$pb.TagNumber(3)
  set blue($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBlue() => $_has(2);
  @$pb.TagNumber(3)
  void clearBlue() => $_clearField(3);
}

class ColourCardRequest extends $pb.GeneratedMessage {
  factory ColourCardRequest({
    $core.String? light,
    $core.int? camera,
    $core.String? card,
    LedMix? ledMix,
    $core.int? whiteBalance,
    $core.int? exposure,
  }) {
    final result = create();
    if (light != null) result.light = light;
    if (camera != null) result.camera = camera;
    if (card != null) result.card = card;
    if (ledMix != null) result.ledMix = ledMix;
    if (whiteBalance != null) result.whiteBalance = whiteBalance;
    if (exposure != null) result.exposure = exposure;
    return result;
  }

  ColourCardRequest._();

  factory ColourCardRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ColourCardRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColourCardRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'light')
    ..aI(2, _omitFieldNames ? '' : 'camera')
    ..aOS(3, _omitFieldNames ? '' : 'card')
    ..aOM<LedMix>(4, _omitFieldNames ? '' : 'ledMix', subBuilder: LedMix.create)
    ..aI(5, _omitFieldNames ? '' : 'whiteBalance')
    ..aI(6, _omitFieldNames ? '' : 'exposure')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColourCardRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColourCardRequest copyWith(void Function(ColourCardRequest) updates) =>
      super.copyWith((message) => updates(message as ColourCardRequest))
          as ColourCardRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ColourCardRequest create() => ColourCardRequest._();
  @$core.override
  ColourCardRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ColourCardRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColourCardRequest>(create);
  static ColourCardRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get light => $_getSZ(0);
  @$pb.TagNumber(1)
  set light($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLight() => $_has(0);
  @$pb.TagNumber(1)
  void clearLight() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get camera => $_getIZ(1);
  @$pb.TagNumber(2)
  set camera($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCamera() => $_has(1);
  @$pb.TagNumber(2)
  void clearCamera() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get card => $_getSZ(2);
  @$pb.TagNumber(3)
  set card($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCard() => $_has(2);
  @$pb.TagNumber(3)
  void clearCard() => $_clearField(3);

  @$pb.TagNumber(4)
  LedMix get ledMix => $_getN(3);
  @$pb.TagNumber(4)
  set ledMix(LedMix value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLedMix() => $_has(3);
  @$pb.TagNumber(4)
  void clearLedMix() => $_clearField(4);
  @$pb.TagNumber(4)
  LedMix ensureLedMix() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.int get whiteBalance => $_getIZ(4);
  @$pb.TagNumber(5)
  set whiteBalance($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWhiteBalance() => $_has(4);
  @$pb.TagNumber(5)
  void clearWhiteBalance() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get exposure => $_getIZ(5);
  @$pb.TagNumber(6)
  set exposure($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasExposure() => $_has(5);
  @$pb.TagNumber(6)
  void clearExposure() => $_clearField(6);
}

class ColourPatch extends $pb.GeneratedMessage {
  factory ColourPatch({
    $core.String? id,
    $core.double? r,
    $core.double? g,
    $core.double? b,
    $core.bool? clipped,
    $core.double? x,
    $core.double? y,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (r != null) result.r = r;
    if (g != null) result.g = g;
    if (b != null) result.b = b;
    if (clipped != null) result.clipped = clipped;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    return result;
  }

  ColourPatch._();

  factory ColourPatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ColourPatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColourPatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aD(2, _omitFieldNames ? '' : 'r')
    ..aD(3, _omitFieldNames ? '' : 'g')
    ..aD(4, _omitFieldNames ? '' : 'b')
    ..aOB(5, _omitFieldNames ? '' : 'clipped')
    ..aD(6, _omitFieldNames ? '' : 'x')
    ..aD(7, _omitFieldNames ? '' : 'y')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColourPatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColourPatch copyWith(void Function(ColourPatch) updates) =>
      super.copyWith((message) => updates(message as ColourPatch))
          as ColourPatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ColourPatch create() => ColourPatch._();
  @$core.override
  ColourPatch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ColourPatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColourPatch>(create);
  static ColourPatch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get r => $_getN(1);
  @$pb.TagNumber(2)
  set r($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasR() => $_has(1);
  @$pb.TagNumber(2)
  void clearR() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get g => $_getN(2);
  @$pb.TagNumber(3)
  set g($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasG() => $_has(2);
  @$pb.TagNumber(3)
  void clearG() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get b => $_getN(3);
  @$pb.TagNumber(4)
  set b($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasB() => $_has(3);
  @$pb.TagNumber(4)
  void clearB() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get clipped => $_getBF(4);
  @$pb.TagNumber(5)
  set clipped($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClipped() => $_has(4);
  @$pb.TagNumber(5)
  void clearClipped() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get x => $_getN(5);
  @$pb.TagNumber(6)
  set x($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasX() => $_has(5);
  @$pb.TagNumber(6)
  void clearX() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get y => $_getN(6);
  @$pb.TagNumber(7)
  set y($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasY() => $_has(6);
  @$pb.TagNumber(7)
  void clearY() => $_clearField(7);
}

class ColourCardResponse extends $pb.GeneratedMessage {
  factory ColourCardResponse({
    $core.bool? found,
    $core.Iterable<ColourPatch>? patches,
    $core.double? patchSizePx,
    $core.int? exposure,
    $core.int? camera,
    $core.List<$core.int>? photo,
    $core.String? note,
  }) {
    final result = create();
    if (found != null) result.found = found;
    if (patches != null) result.patches.addAll(patches);
    if (patchSizePx != null) result.patchSizePx = patchSizePx;
    if (exposure != null) result.exposure = exposure;
    if (camera != null) result.camera = camera;
    if (photo != null) result.photo = photo;
    if (note != null) result.note = note;
    return result;
  }

  ColourCardResponse._();

  factory ColourCardResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ColourCardResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColourCardResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'found')
    ..pPM<ColourPatch>(2, _omitFieldNames ? '' : 'patches',
        subBuilder: ColourPatch.create)
    ..aD(3, _omitFieldNames ? '' : 'patchSizePx')
    ..aI(4, _omitFieldNames ? '' : 'exposure')
    ..aI(5, _omitFieldNames ? '' : 'camera')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'photo', $pb.PbFieldType.OY)
    ..aOS(7, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColourCardResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColourCardResponse copyWith(void Function(ColourCardResponse) updates) =>
      super.copyWith((message) => updates(message as ColourCardResponse))
          as ColourCardResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ColourCardResponse create() => ColourCardResponse._();
  @$core.override
  ColourCardResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ColourCardResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColourCardResponse>(create);
  static ColourCardResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get found => $_getBF(0);
  @$pb.TagNumber(1)
  set found($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFound() => $_has(0);
  @$pb.TagNumber(1)
  void clearFound() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ColourPatch> get patches => $_getList(1);

  @$pb.TagNumber(3)
  $core.double get patchSizePx => $_getN(2);
  @$pb.TagNumber(3)
  set patchSizePx($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPatchSizePx() => $_has(2);
  @$pb.TagNumber(3)
  void clearPatchSizePx() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get exposure => $_getIZ(3);
  @$pb.TagNumber(4)
  set exposure($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExposure() => $_has(3);
  @$pb.TagNumber(4)
  void clearExposure() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get camera => $_getIZ(4);
  @$pb.TagNumber(5)
  set camera($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCamera() => $_has(4);
  @$pb.TagNumber(5)
  void clearCamera() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get photo => $_getN(5);
  @$pb.TagNumber(6)
  set photo($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPhoto() => $_has(5);
  @$pb.TagNumber(6)
  void clearPhoto() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get note => $_getSZ(6);
  @$pb.TagNumber(7)
  set note($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNote() => $_has(6);
  @$pb.TagNumber(7)
  void clearNote() => $_clearField(7);
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

/// The request of StartAutomaticCapture / StartManualCapture.
class CaptureRequest extends $pb.GeneratedMessage {
  factory CaptureRequest({
    CaptureSettings? settings,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    return result;
  }

  CaptureRequest._();

  factory CaptureRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CaptureRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOM<CaptureSettings>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: CaptureSettings.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureRequest copyWith(void Function(CaptureRequest) updates) =>
      super.copyWith((message) => updates(message as CaptureRequest))
          as CaptureRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CaptureRequest create() => CaptureRequest._();
  @$core.override
  CaptureRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CaptureRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CaptureRequest>(create);
  static CaptureRequest? _defaultInstance;

  @$pb.TagNumber(1)
  CaptureSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(CaptureSettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  CaptureSettings ensureSettings() => $_ensure(0);
}

/// The names follow the kiosk_settings.json keys (lap is per-capture only).
class CaptureSettings extends $pb.GeneratedMessage {
  factory CaptureSettings({
    $core.String? photoFormat,
    $core.bool? crop,
    $core.int? cropWidth,
    $core.int? jpegQuality,
    $core.String? backgroundMethod,
    $core.String? backgroundColor,
    $core.int? backgroundStrength,
    $core.String? glareFreeLight,
    $core.String? photoLight,
    $core.bool? ledsOffForPhoto,
    $core.bool? eyesCheck,
    $core.bool? lipsCheck,
    $core.bool? eyeGlassesCheck,
    $core.bool? headPoseCheck,
    $core.bool? sharpnessCheck,
    $core.bool? redEyeDetectionCheck,
    $core.bool? headSizeCheck,
    $core.bool? expressionCheck,
    $core.bool? gazeCheck,
    $core.bool? lightingEvennessCheck,
    $core.bool? ofiqChecks,
    $core.bool? icaoReport,
    $core.bool? livenessCheck,
    $core.bool? livenessHeadTurnCheck,
    $core.int? distanceMin,
    $core.int? distanceMax,
    $core.bool? colourCorrection,
    LapSubject? lap,
  }) {
    final result = create();
    if (photoFormat != null) result.photoFormat = photoFormat;
    if (crop != null) result.crop = crop;
    if (cropWidth != null) result.cropWidth = cropWidth;
    if (jpegQuality != null) result.jpegQuality = jpegQuality;
    if (backgroundMethod != null) result.backgroundMethod = backgroundMethod;
    if (backgroundColor != null) result.backgroundColor = backgroundColor;
    if (backgroundStrength != null)
      result.backgroundStrength = backgroundStrength;
    if (glareFreeLight != null) result.glareFreeLight = glareFreeLight;
    if (photoLight != null) result.photoLight = photoLight;
    if (ledsOffForPhoto != null) result.ledsOffForPhoto = ledsOffForPhoto;
    if (eyesCheck != null) result.eyesCheck = eyesCheck;
    if (lipsCheck != null) result.lipsCheck = lipsCheck;
    if (eyeGlassesCheck != null) result.eyeGlassesCheck = eyeGlassesCheck;
    if (headPoseCheck != null) result.headPoseCheck = headPoseCheck;
    if (sharpnessCheck != null) result.sharpnessCheck = sharpnessCheck;
    if (redEyeDetectionCheck != null)
      result.redEyeDetectionCheck = redEyeDetectionCheck;
    if (headSizeCheck != null) result.headSizeCheck = headSizeCheck;
    if (expressionCheck != null) result.expressionCheck = expressionCheck;
    if (gazeCheck != null) result.gazeCheck = gazeCheck;
    if (lightingEvennessCheck != null)
      result.lightingEvennessCheck = lightingEvennessCheck;
    if (ofiqChecks != null) result.ofiqChecks = ofiqChecks;
    if (icaoReport != null) result.icaoReport = icaoReport;
    if (livenessCheck != null) result.livenessCheck = livenessCheck;
    if (livenessHeadTurnCheck != null)
      result.livenessHeadTurnCheck = livenessHeadTurnCheck;
    if (distanceMin != null) result.distanceMin = distanceMin;
    if (distanceMax != null) result.distanceMax = distanceMax;
    if (colourCorrection != null) result.colourCorrection = colourCorrection;
    if (lap != null) result.lap = lap;
    return result;
  }

  CaptureSettings._();

  factory CaptureSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CaptureSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'photoFormat')
    ..aOB(2, _omitFieldNames ? '' : 'crop')
    ..aI(3, _omitFieldNames ? '' : 'cropWidth')
    ..aI(4, _omitFieldNames ? '' : 'jpegQuality')
    ..aOS(5, _omitFieldNames ? '' : 'backgroundMethod')
    ..aOS(6, _omitFieldNames ? '' : 'backgroundColor')
    ..aI(7, _omitFieldNames ? '' : 'backgroundStrength')
    ..aOS(8, _omitFieldNames ? '' : 'glareFreeLight')
    ..aOS(9, _omitFieldNames ? '' : 'photoLight')
    ..aOB(10, _omitFieldNames ? '' : 'ledsOffForPhoto')
    ..aOB(11, _omitFieldNames ? '' : 'eyesCheck')
    ..aOB(12, _omitFieldNames ? '' : 'lipsCheck')
    ..aOB(13, _omitFieldNames ? '' : 'eyeGlassesCheck')
    ..aOB(14, _omitFieldNames ? '' : 'headPoseCheck')
    ..aOB(15, _omitFieldNames ? '' : 'sharpnessCheck')
    ..aOB(16, _omitFieldNames ? '' : 'redEyeDetectionCheck')
    ..aOB(17, _omitFieldNames ? '' : 'headSizeCheck')
    ..aOB(18, _omitFieldNames ? '' : 'expressionCheck')
    ..aOB(19, _omitFieldNames ? '' : 'gazeCheck')
    ..aOB(20, _omitFieldNames ? '' : 'lightingEvennessCheck')
    ..aOB(21, _omitFieldNames ? '' : 'ofiqChecks')
    ..aOB(22, _omitFieldNames ? '' : 'icaoReport')
    ..aOB(23, _omitFieldNames ? '' : 'livenessCheck')
    ..aOB(24, _omitFieldNames ? '' : 'livenessHeadTurnCheck')
    ..aI(25, _omitFieldNames ? '' : 'distanceMin')
    ..aI(26, _omitFieldNames ? '' : 'distanceMax')
    ..aOB(27, _omitFieldNames ? '' : 'colourCorrection')
    ..aE<LapSubject>(28, _omitFieldNames ? '' : 'lap',
        enumValues: LapSubject.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureSettings copyWith(void Function(CaptureSettings) updates) =>
      super.copyWith((message) => updates(message as CaptureSettings))
          as CaptureSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CaptureSettings create() => CaptureSettings._();
  @$core.override
  CaptureSettings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CaptureSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CaptureSettings>(create);
  static CaptureSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get photoFormat => $_getSZ(0);
  @$pb.TagNumber(1)
  set photoFormat($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPhotoFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhotoFormat() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get crop => $_getBF(1);
  @$pb.TagNumber(2)
  set crop($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCrop() => $_has(1);
  @$pb.TagNumber(2)
  void clearCrop() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get cropWidth => $_getIZ(2);
  @$pb.TagNumber(3)
  set cropWidth($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCropWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearCropWidth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get jpegQuality => $_getIZ(3);
  @$pb.TagNumber(4)
  set jpegQuality($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasJpegQuality() => $_has(3);
  @$pb.TagNumber(4)
  void clearJpegQuality() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get backgroundMethod => $_getSZ(4);
  @$pb.TagNumber(5)
  set backgroundMethod($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBackgroundMethod() => $_has(4);
  @$pb.TagNumber(5)
  void clearBackgroundMethod() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get backgroundColor => $_getSZ(5);
  @$pb.TagNumber(6)
  set backgroundColor($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBackgroundColor() => $_has(5);
  @$pb.TagNumber(6)
  void clearBackgroundColor() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get backgroundStrength => $_getIZ(6);
  @$pb.TagNumber(7)
  set backgroundStrength($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBackgroundStrength() => $_has(6);
  @$pb.TagNumber(7)
  void clearBackgroundStrength() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get glareFreeLight => $_getSZ(7);
  @$pb.TagNumber(8)
  set glareFreeLight($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasGlareFreeLight() => $_has(7);
  @$pb.TagNumber(8)
  void clearGlareFreeLight() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get photoLight => $_getSZ(8);
  @$pb.TagNumber(9)
  set photoLight($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPhotoLight() => $_has(8);
  @$pb.TagNumber(9)
  void clearPhotoLight() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get ledsOffForPhoto => $_getBF(9);
  @$pb.TagNumber(10)
  set ledsOffForPhoto($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLedsOffForPhoto() => $_has(9);
  @$pb.TagNumber(10)
  void clearLedsOffForPhoto() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get eyesCheck => $_getBF(10);
  @$pb.TagNumber(11)
  set eyesCheck($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasEyesCheck() => $_has(10);
  @$pb.TagNumber(11)
  void clearEyesCheck() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get lipsCheck => $_getBF(11);
  @$pb.TagNumber(12)
  set lipsCheck($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasLipsCheck() => $_has(11);
  @$pb.TagNumber(12)
  void clearLipsCheck() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get eyeGlassesCheck => $_getBF(12);
  @$pb.TagNumber(13)
  set eyeGlassesCheck($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasEyeGlassesCheck() => $_has(12);
  @$pb.TagNumber(13)
  void clearEyeGlassesCheck() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get headPoseCheck => $_getBF(13);
  @$pb.TagNumber(14)
  set headPoseCheck($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasHeadPoseCheck() => $_has(13);
  @$pb.TagNumber(14)
  void clearHeadPoseCheck() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.bool get sharpnessCheck => $_getBF(14);
  @$pb.TagNumber(15)
  set sharpnessCheck($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasSharpnessCheck() => $_has(14);
  @$pb.TagNumber(15)
  void clearSharpnessCheck() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get redEyeDetectionCheck => $_getBF(15);
  @$pb.TagNumber(16)
  set redEyeDetectionCheck($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasRedEyeDetectionCheck() => $_has(15);
  @$pb.TagNumber(16)
  void clearRedEyeDetectionCheck() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get headSizeCheck => $_getBF(16);
  @$pb.TagNumber(17)
  set headSizeCheck($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasHeadSizeCheck() => $_has(16);
  @$pb.TagNumber(17)
  void clearHeadSizeCheck() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.bool get expressionCheck => $_getBF(17);
  @$pb.TagNumber(18)
  set expressionCheck($core.bool value) => $_setBool(17, value);
  @$pb.TagNumber(18)
  $core.bool hasExpressionCheck() => $_has(17);
  @$pb.TagNumber(18)
  void clearExpressionCheck() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.bool get gazeCheck => $_getBF(18);
  @$pb.TagNumber(19)
  set gazeCheck($core.bool value) => $_setBool(18, value);
  @$pb.TagNumber(19)
  $core.bool hasGazeCheck() => $_has(18);
  @$pb.TagNumber(19)
  void clearGazeCheck() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.bool get lightingEvennessCheck => $_getBF(19);
  @$pb.TagNumber(20)
  set lightingEvennessCheck($core.bool value) => $_setBool(19, value);
  @$pb.TagNumber(20)
  $core.bool hasLightingEvennessCheck() => $_has(19);
  @$pb.TagNumber(20)
  void clearLightingEvennessCheck() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.bool get ofiqChecks => $_getBF(20);
  @$pb.TagNumber(21)
  set ofiqChecks($core.bool value) => $_setBool(20, value);
  @$pb.TagNumber(21)
  $core.bool hasOfiqChecks() => $_has(20);
  @$pb.TagNumber(21)
  void clearOfiqChecks() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.bool get icaoReport => $_getBF(21);
  @$pb.TagNumber(22)
  set icaoReport($core.bool value) => $_setBool(21, value);
  @$pb.TagNumber(22)
  $core.bool hasIcaoReport() => $_has(21);
  @$pb.TagNumber(22)
  void clearIcaoReport() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.bool get livenessCheck => $_getBF(22);
  @$pb.TagNumber(23)
  set livenessCheck($core.bool value) => $_setBool(22, value);
  @$pb.TagNumber(23)
  $core.bool hasLivenessCheck() => $_has(22);
  @$pb.TagNumber(23)
  void clearLivenessCheck() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.bool get livenessHeadTurnCheck => $_getBF(23);
  @$pb.TagNumber(24)
  set livenessHeadTurnCheck($core.bool value) => $_setBool(23, value);
  @$pb.TagNumber(24)
  $core.bool hasLivenessHeadTurnCheck() => $_has(23);
  @$pb.TagNumber(24)
  void clearLivenessHeadTurnCheck() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.int get distanceMin => $_getIZ(24);
  @$pb.TagNumber(25)
  set distanceMin($core.int value) => $_setSignedInt32(24, value);
  @$pb.TagNumber(25)
  $core.bool hasDistanceMin() => $_has(24);
  @$pb.TagNumber(25)
  void clearDistanceMin() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.int get distanceMax => $_getIZ(25);
  @$pb.TagNumber(26)
  set distanceMax($core.int value) => $_setSignedInt32(25, value);
  @$pb.TagNumber(26)
  $core.bool hasDistanceMax() => $_has(25);
  @$pb.TagNumber(26)
  void clearDistanceMax() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.bool get colourCorrection => $_getBF(26);
  @$pb.TagNumber(27)
  set colourCorrection($core.bool value) => $_setBool(26, value);
  @$pb.TagNumber(27)
  $core.bool hasColourCorrection() => $_has(26);
  @$pb.TagNumber(27)
  void clearColourCorrection() => $_clearField(27);

  @$pb.TagNumber(28)
  LapSubject get lap => $_getN(27);
  @$pb.TagNumber(28)
  set lap(LapSubject value) => $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasLap() => $_has(27);
  @$pb.TagNumber(28)
  void clearLap() => $_clearField(28);
}

/// The first message of every capture stream, on all four capture RPCs: the settings this
/// capture runs with. An automatic capture fills all 28 fields, a manual capture the five
/// it uses. background_method is the normalised name (withoutbg, never rembg).
class CaptureSettingsUsed extends $pb.GeneratedMessage {
  factory CaptureSettingsUsed({
    CaptureSettings? values,
    $core.Iterable<$core.String>? overridden,
  }) {
    final result = create();
    if (values != null) result.values = values;
    if (overridden != null) result.overridden.addAll(overridden);
    return result;
  }

  CaptureSettingsUsed._();

  factory CaptureSettingsUsed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CaptureSettingsUsed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CaptureSettingsUsed',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aOM<CaptureSettings>(1, _omitFieldNames ? '' : 'values',
        subBuilder: CaptureSettings.create)
    ..pPS(2, _omitFieldNames ? '' : 'overridden')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureSettingsUsed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CaptureSettingsUsed copyWith(void Function(CaptureSettingsUsed) updates) =>
      super.copyWith((message) => updates(message as CaptureSettingsUsed))
          as CaptureSettingsUsed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CaptureSettingsUsed create() => CaptureSettingsUsed._();
  @$core.override
  CaptureSettingsUsed createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CaptureSettingsUsed getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CaptureSettingsUsed>(create);
  static CaptureSettingsUsed? _defaultInstance;

  @$pb.TagNumber(1)
  CaptureSettings get values => $_getN(0);
  @$pb.TagNumber(1)
  set values(CaptureSettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasValues() => $_has(0);
  @$pb.TagNumber(1)
  void clearValues() => $_clearField(1);
  @$pb.TagNumber(1)
  CaptureSettings ensureValues() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get overridden => $_getList(1);
}

enum ProcessAutomaticResponse_Result {
  processStatus,
  imageData,
  checkResult,
  instruction,
  settingsUsed,
  notSet
}

class ProcessAutomaticResponse extends $pb.GeneratedMessage {
  factory ProcessAutomaticResponse({
    ProcessStepStatus? processStatus,
    ProcessImageData? imageData,
    CheckResult? checkResult,
    Instruction? instruction,
    CaptureSettingsUsed? settingsUsed,
  }) {
    final result = create();
    if (processStatus != null) result.processStatus = processStatus;
    if (imageData != null) result.imageData = imageData;
    if (checkResult != null) result.checkResult = checkResult;
    if (instruction != null) result.instruction = instruction;
    if (settingsUsed != null) result.settingsUsed = settingsUsed;
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
    3: ProcessAutomaticResponse_Result.checkResult,
    4: ProcessAutomaticResponse_Result.instruction,
    5: ProcessAutomaticResponse_Result.settingsUsed,
    0: ProcessAutomaticResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProcessAutomaticResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOM<ProcessStepStatus>(1, _omitFieldNames ? '' : 'processStatus',
        protoName: 'processStatus', subBuilder: ProcessStepStatus.create)
    ..aOM<ProcessImageData>(2, _omitFieldNames ? '' : 'imageData',
        protoName: 'imageData', subBuilder: ProcessImageData.create)
    ..aOM<CheckResult>(3, _omitFieldNames ? '' : 'checkResult',
        protoName: 'checkResult', subBuilder: CheckResult.create)
    ..aOM<Instruction>(4, _omitFieldNames ? '' : 'instruction',
        subBuilder: Instruction.create)
    ..aOM<CaptureSettingsUsed>(5, _omitFieldNames ? '' : 'settingsUsed',
        subBuilder: CaptureSettingsUsed.create)
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
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  ProcessAutomaticResponse_Result whichResult() =>
      _ProcessAutomaticResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
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

  /// One structured result per check, sent right after the check's text row
  /// (the text rows are unchanged). Clients that do not know this field skip it.
  @$pb.TagNumber(3)
  CheckResult get checkResult => $_getN(2);
  @$pb.TagNumber(3)
  set checkResult(CheckResult value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCheckResult() => $_has(2);
  @$pb.TagNumber(3)
  void clearCheckResult() => $_clearField(3);
  @$pb.TagNumber(3)
  CheckResult ensureCheckResult() => $_ensure(2);

  /// The live person check's head turn (kiosk setting liveness_head_turn_check):
  /// what the person is asked to do now. Each new instruction is ALSO sent as a
  /// ProcessStepStatus text, so a client that skips this field still shows it.
  @$pb.TagNumber(4)
  Instruction get instruction => $_getN(3);
  @$pb.TagNumber(4)
  set instruction(Instruction value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasInstruction() => $_has(3);
  @$pb.TagNumber(4)
  void clearInstruction() => $_clearField(4);
  @$pb.TagNumber(4)
  Instruction ensureInstruction() => $_ensure(3);

  /// The settings this capture runs with: the FIRST message of the stream
  /// (spec 2026-10-11). Clients that do not know this field skip it.
  @$pb.TagNumber(5)
  CaptureSettingsUsed get settingsUsed => $_getN(4);
  @$pb.TagNumber(5)
  set settingsUsed(CaptureSettingsUsed value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSettingsUsed() => $_has(4);
  @$pb.TagNumber(5)
  void clearSettingsUsed() => $_clearField(5);
  @$pb.TagNumber(5)
  CaptureSettingsUsed ensureSettingsUsed() => $_ensure(4);
}

/// One head-turn instruction. Sent when the instruction changes, and in between when
/// the progress moved 5 points or more, at most ~10 per second.
class Instruction extends $pb.GeneratedMessage {
  factory Instruction({
    $core.int? index,
    InstructionKind? kind,
    $core.double? progress,
    $core.bool? repeat,
    $core.double? secondsLeft,
    $core.String? text,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (kind != null) result.kind = kind;
    if (progress != null) result.progress = progress;
    if (repeat != null) result.repeat = repeat;
    if (secondsLeft != null) result.secondsLeft = secondsLeft;
    if (text != null) result.text = text;
    return result;
  }

  Instruction._();

  factory Instruction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Instruction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Instruction',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aE<InstructionKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: InstructionKind.values)
    ..aD(3, _omitFieldNames ? '' : 'progress', fieldType: $pb.PbFieldType.OF)
    ..aOB(4, _omitFieldNames ? '' : 'repeat')
    ..aD(5, _omitFieldNames ? '' : 'secondsLeft', fieldType: $pb.PbFieldType.OF)
    ..aOS(6, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Instruction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Instruction copyWith(void Function(Instruction) updates) =>
      super.copyWith((message) => updates(message as Instruction))
          as Instruction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Instruction create() => Instruction._();
  @$core.override
  Instruction createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Instruction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Instruction>(create);
  static Instruction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  InstructionKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(InstructionKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get progress => $_getN(2);
  @$pb.TagNumber(3)
  set progress($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProgress() => $_has(2);
  @$pb.TagNumber(3)
  void clearProgress() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get repeat => $_getBF(3);
  @$pb.TagNumber(4)
  set repeat($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRepeat() => $_has(3);
  @$pb.TagNumber(4)
  void clearRepeat() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get secondsLeft => $_getN(4);
  @$pb.TagNumber(5)
  set secondsLeft($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSecondsLeft() => $_has(4);
  @$pb.TagNumber(5)
  void clearSecondsLeft() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get text => $_getSZ(5);
  @$pb.TagNumber(6)
  set text($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasText() => $_has(5);
  @$pb.TagNumber(6)
  void clearText() => $_clearField(6);
}

/// A machine-readable check result. `name` is stable and documented; the text in
/// `description` is the same sentence as the human-readable status row and may change.
class CheckResult extends $pb.GeneratedMessage {
  factory CheckResult({
    $core.int? index,
    CheckKind? kind,
    $core.String? name,
    CheckVerdict? verdict,
    $core.bool? gatesPhoto,
    $core.double? value,
    $core.double? min,
    $core.double? max,
    $core.String? unit,
    $core.String? description,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (kind != null) result.kind = kind;
    if (name != null) result.name = name;
    if (verdict != null) result.verdict = verdict;
    if (gatesPhoto != null) result.gatesPhoto = gatesPhoto;
    if (value != null) result.value = value;
    if (min != null) result.min = min;
    if (max != null) result.max = max;
    if (unit != null) result.unit = unit;
    if (description != null) result.description = description;
    return result;
  }

  CheckResult._();

  factory CheckResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CheckResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aE<CheckKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: CheckKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<CheckVerdict>(4, _omitFieldNames ? '' : 'verdict',
        enumValues: CheckVerdict.values)
    ..aOB(5, _omitFieldNames ? '' : 'gatesPhoto')
    ..aD(6, _omitFieldNames ? '' : 'value')
    ..aD(7, _omitFieldNames ? '' : 'min')
    ..aD(8, _omitFieldNames ? '' : 'max')
    ..aOS(9, _omitFieldNames ? '' : 'unit')
    ..aOS(10, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckResult copyWith(void Function(CheckResult) updates) =>
      super.copyWith((message) => updates(message as CheckResult))
          as CheckResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckResult create() => CheckResult._();
  @$core.override
  CheckResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CheckResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckResult>(create);
  static CheckResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  CheckKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(CheckKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  CheckVerdict get verdict => $_getN(3);
  @$pb.TagNumber(4)
  set verdict(CheckVerdict value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasVerdict() => $_has(3);
  @$pb.TagNumber(4)
  void clearVerdict() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get gatesPhoto => $_getBF(4);
  @$pb.TagNumber(5)
  set gatesPhoto($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGatesPhoto() => $_has(4);
  @$pb.TagNumber(5)
  void clearGatesPhoto() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get value => $_getN(5);
  @$pb.TagNumber(6)
  set value($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearValue() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get min => $_getN(6);
  @$pb.TagNumber(7)
  set min($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMin() => $_has(6);
  @$pb.TagNumber(7)
  void clearMin() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get max => $_getN(7);
  @$pb.TagNumber(8)
  set max($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMax() => $_has(7);
  @$pb.TagNumber(8)
  void clearMax() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get unit => $_getSZ(8);
  @$pb.TagNumber(9)
  set unit($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUnit() => $_has(8);
  @$pb.TagNumber(9)
  void clearUnit() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get description => $_getSZ(9);
  @$pb.TagNumber(10)
  set description($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDescription() => $_has(9);
  @$pb.TagNumber(10)
  void clearDescription() => $_clearField(10);
}

enum ProcessManualResponse_Result {
  processStatus,
  imageData,
  settingsUsed,
  notSet
}

class ProcessManualResponse extends $pb.GeneratedMessage {
  factory ProcessManualResponse({
    ProcessStepStatus? processStatus,
    ProcessImageData? imageData,
    CaptureSettingsUsed? settingsUsed,
  }) {
    final result = create();
    if (processStatus != null) result.processStatus = processStatus;
    if (imageData != null) result.imageData = imageData;
    if (settingsUsed != null) result.settingsUsed = settingsUsed;
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
    3: ProcessManualResponse_Result.settingsUsed,
    0: ProcessManualResponse_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProcessManualResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'kiosk'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<ProcessStepStatus>(1, _omitFieldNames ? '' : 'processStatus',
        protoName: 'processStatus', subBuilder: ProcessStepStatus.create)
    ..aOM<ProcessImageData>(2, _omitFieldNames ? '' : 'imageData',
        protoName: 'imageData', subBuilder: ProcessImageData.create)
    ..aOM<CaptureSettingsUsed>(3, _omitFieldNames ? '' : 'settingsUsed',
        subBuilder: CaptureSettingsUsed.create)
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
  @$pb.TagNumber(3)
  ProcessManualResponse_Result whichResult() =>
      _ProcessManualResponse_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
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

  /// The settings this capture runs with: the FIRST message of the stream
  /// (spec 2026-10-11). Clients that do not know this field skip it.
  @$pb.TagNumber(3)
  CaptureSettingsUsed get settingsUsed => $_getN(2);
  @$pb.TagNumber(3)
  set settingsUsed(CaptureSettingsUsed value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSettingsUsed() => $_has(2);
  @$pb.TagNumber(3)
  void clearSettingsUsed() => $_clearField(3);
  @$pb.TagNumber(3)
  CaptureSettingsUsed ensureSettingsUsed() => $_ensure(2);
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
    $core.Iterable<CheckResult>? checks,
  }) {
    final result = create();
    if (processImageData != null) result.processImageData = processImageData;
    if (statusType != null) result.statusType = statusType;
    if (checks != null) result.checks.addAll(checks);
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
    ..pPM<CheckResult>(3, _omitFieldNames ? '' : 'checks',
        subBuilder: CheckResult.create)
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

  /// GetHighResolutionImageWithIcaoChecksFromCameraIndex only: the check results of
  /// the photo, on the FIRST item of the stream (empty on the later chunks and on the
  /// plain GetHighResolutionImageFromCameraIndex).
  @$pb.TagNumber(3)
  $pb.PbList<CheckResult> get checks => $_getList(2);
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
