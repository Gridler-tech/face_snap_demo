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

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CameraResolution extends $pb.GeneratedMessage {
  factory CameraResolution({
    $core.int? width,
    $core.int? height,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    return result;
  }

  CameraResolution._();

  factory CameraResolution.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CameraResolution.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CameraResolution',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'width')
    ..aI(2, _omitFieldNames ? '' : 'height')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraResolution clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraResolution copyWith(void Function(CameraResolution) updates) =>
      super.copyWith((message) => updates(message as CameraResolution))
          as CameraResolution;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CameraResolution create() => CameraResolution._();
  @$core.override
  CameraResolution createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CameraResolution getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CameraResolution>(create);
  static CameraResolution? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);
}

class SaveSettingsRequest extends $pb.GeneratedMessage {
  factory SaveSettingsRequest({
    $core.int? width,
    $core.int? height,
    $core.bool? crop,
    $core.int? cropWidth,
    $core.int? cropHeight,
    $core.bool? eyesCheck,
    $core.bool? lipsCheck,
    $core.bool? lighting,
    $core.int? intensityRed,
    $core.int? intensityGreen,
    $core.int? intensityBlue,
    $core.int? distanceMin,
    $core.int? distanceMax,
    $core.bool? blurBackground,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (crop != null) result.crop = crop;
    if (cropWidth != null) result.cropWidth = cropWidth;
    if (cropHeight != null) result.cropHeight = cropHeight;
    if (eyesCheck != null) result.eyesCheck = eyesCheck;
    if (lipsCheck != null) result.lipsCheck = lipsCheck;
    if (lighting != null) result.lighting = lighting;
    if (intensityRed != null) result.intensityRed = intensityRed;
    if (intensityGreen != null) result.intensityGreen = intensityGreen;
    if (intensityBlue != null) result.intensityBlue = intensityBlue;
    if (distanceMin != null) result.distanceMin = distanceMin;
    if (distanceMax != null) result.distanceMax = distanceMax;
    if (blurBackground != null) result.blurBackground = blurBackground;
    return result;
  }

  SaveSettingsRequest._();

  factory SaveSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'width')
    ..aI(2, _omitFieldNames ? '' : 'height')
    ..aOB(3, _omitFieldNames ? '' : 'crop')
    ..aI(4, _omitFieldNames ? '' : 'cropWidth')
    ..aI(5, _omitFieldNames ? '' : 'cropHeight')
    ..aOB(6, _omitFieldNames ? '' : 'eyesCheck')
    ..aOB(7, _omitFieldNames ? '' : 'lipsCheck')
    ..aOB(8, _omitFieldNames ? '' : 'lighting')
    ..aI(9, _omitFieldNames ? '' : 'intensityRed')
    ..aI(10, _omitFieldNames ? '' : 'intensityGreen')
    ..aI(11, _omitFieldNames ? '' : 'intensityBlue')
    ..aI(12, _omitFieldNames ? '' : 'distanceMin')
    ..aI(13, _omitFieldNames ? '' : 'distanceMax')
    ..aOB(14, _omitFieldNames ? '' : 'blurBackground')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSettingsRequest copyWith(void Function(SaveSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as SaveSettingsRequest))
          as SaveSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveSettingsRequest create() => SaveSettingsRequest._();
  @$core.override
  SaveSettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveSettingsRequest>(create);
  static SaveSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get crop => $_getBF(2);
  @$pb.TagNumber(3)
  set crop($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCrop() => $_has(2);
  @$pb.TagNumber(3)
  void clearCrop() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get cropWidth => $_getIZ(3);
  @$pb.TagNumber(4)
  set cropWidth($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCropWidth() => $_has(3);
  @$pb.TagNumber(4)
  void clearCropWidth() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get cropHeight => $_getIZ(4);
  @$pb.TagNumber(5)
  set cropHeight($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCropHeight() => $_has(4);
  @$pb.TagNumber(5)
  void clearCropHeight() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get eyesCheck => $_getBF(5);
  @$pb.TagNumber(6)
  set eyesCheck($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEyesCheck() => $_has(5);
  @$pb.TagNumber(6)
  void clearEyesCheck() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get lipsCheck => $_getBF(6);
  @$pb.TagNumber(7)
  set lipsCheck($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLipsCheck() => $_has(6);
  @$pb.TagNumber(7)
  void clearLipsCheck() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get lighting => $_getBF(7);
  @$pb.TagNumber(8)
  set lighting($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLighting() => $_has(7);
  @$pb.TagNumber(8)
  void clearLighting() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get intensityRed => $_getIZ(8);
  @$pb.TagNumber(9)
  set intensityRed($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIntensityRed() => $_has(8);
  @$pb.TagNumber(9)
  void clearIntensityRed() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get intensityGreen => $_getIZ(9);
  @$pb.TagNumber(10)
  set intensityGreen($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIntensityGreen() => $_has(9);
  @$pb.TagNumber(10)
  void clearIntensityGreen() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get intensityBlue => $_getIZ(10);
  @$pb.TagNumber(11)
  set intensityBlue($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasIntensityBlue() => $_has(10);
  @$pb.TagNumber(11)
  void clearIntensityBlue() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get distanceMin => $_getIZ(11);
  @$pb.TagNumber(12)
  set distanceMin($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDistanceMin() => $_has(11);
  @$pb.TagNumber(12)
  void clearDistanceMin() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get distanceMax => $_getIZ(12);
  @$pb.TagNumber(13)
  set distanceMax($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDistanceMax() => $_has(12);
  @$pb.TagNumber(13)
  void clearDistanceMax() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get blurBackground => $_getBF(13);
  @$pb.TagNumber(14)
  set blurBackground($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasBlurBackground() => $_has(13);
  @$pb.TagNumber(14)
  void clearBlurBackground() => $_clearField(14);
}

class SaveSettingsResponse extends $pb.GeneratedMessage {
  factory SaveSettingsResponse({
    $core.int? width,
    $core.int? height,
    $core.bool? crop,
    $core.int? cropWidth,
    $core.int? cropHeight,
    $core.bool? eyesCheck,
    $core.bool? lipsCheck,
    $core.bool? lighting,
    $core.int? intensityRed,
    $core.int? intensityGreen,
    $core.int? intensityBlue,
    $core.int? distanceMin,
    $core.int? distanceMax,
    $core.bool? blurBackground,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (crop != null) result.crop = crop;
    if (cropWidth != null) result.cropWidth = cropWidth;
    if (cropHeight != null) result.cropHeight = cropHeight;
    if (eyesCheck != null) result.eyesCheck = eyesCheck;
    if (lipsCheck != null) result.lipsCheck = lipsCheck;
    if (lighting != null) result.lighting = lighting;
    if (intensityRed != null) result.intensityRed = intensityRed;
    if (intensityGreen != null) result.intensityGreen = intensityGreen;
    if (intensityBlue != null) result.intensityBlue = intensityBlue;
    if (distanceMin != null) result.distanceMin = distanceMin;
    if (distanceMax != null) result.distanceMax = distanceMax;
    if (blurBackground != null) result.blurBackground = blurBackground;
    return result;
  }

  SaveSettingsResponse._();

  factory SaveSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'width')
    ..aI(2, _omitFieldNames ? '' : 'height')
    ..aOB(3, _omitFieldNames ? '' : 'crop')
    ..aI(4, _omitFieldNames ? '' : 'cropWidth')
    ..aI(5, _omitFieldNames ? '' : 'cropHeight')
    ..aOB(6, _omitFieldNames ? '' : 'eyesCheck')
    ..aOB(7, _omitFieldNames ? '' : 'lipsCheck')
    ..aOB(8, _omitFieldNames ? '' : 'lighting')
    ..aI(9, _omitFieldNames ? '' : 'intensityRed')
    ..aI(10, _omitFieldNames ? '' : 'intensityGreen')
    ..aI(11, _omitFieldNames ? '' : 'intensityBlue')
    ..aI(12, _omitFieldNames ? '' : 'distanceMin')
    ..aI(13, _omitFieldNames ? '' : 'distanceMax')
    ..aOB(14, _omitFieldNames ? '' : 'blurBackground')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSettingsResponse copyWith(void Function(SaveSettingsResponse) updates) =>
      super.copyWith((message) => updates(message as SaveSettingsResponse))
          as SaveSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveSettingsResponse create() => SaveSettingsResponse._();
  @$core.override
  SaveSettingsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveSettingsResponse>(create);
  static SaveSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get crop => $_getBF(2);
  @$pb.TagNumber(3)
  set crop($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCrop() => $_has(2);
  @$pb.TagNumber(3)
  void clearCrop() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get cropWidth => $_getIZ(3);
  @$pb.TagNumber(4)
  set cropWidth($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCropWidth() => $_has(3);
  @$pb.TagNumber(4)
  void clearCropWidth() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get cropHeight => $_getIZ(4);
  @$pb.TagNumber(5)
  set cropHeight($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCropHeight() => $_has(4);
  @$pb.TagNumber(5)
  void clearCropHeight() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get eyesCheck => $_getBF(5);
  @$pb.TagNumber(6)
  set eyesCheck($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEyesCheck() => $_has(5);
  @$pb.TagNumber(6)
  void clearEyesCheck() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get lipsCheck => $_getBF(6);
  @$pb.TagNumber(7)
  set lipsCheck($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLipsCheck() => $_has(6);
  @$pb.TagNumber(7)
  void clearLipsCheck() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get lighting => $_getBF(7);
  @$pb.TagNumber(8)
  set lighting($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLighting() => $_has(7);
  @$pb.TagNumber(8)
  void clearLighting() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get intensityRed => $_getIZ(8);
  @$pb.TagNumber(9)
  set intensityRed($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIntensityRed() => $_has(8);
  @$pb.TagNumber(9)
  void clearIntensityRed() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get intensityGreen => $_getIZ(9);
  @$pb.TagNumber(10)
  set intensityGreen($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIntensityGreen() => $_has(9);
  @$pb.TagNumber(10)
  void clearIntensityGreen() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get intensityBlue => $_getIZ(10);
  @$pb.TagNumber(11)
  set intensityBlue($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasIntensityBlue() => $_has(10);
  @$pb.TagNumber(11)
  void clearIntensityBlue() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get distanceMin => $_getIZ(11);
  @$pb.TagNumber(12)
  set distanceMin($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDistanceMin() => $_has(11);
  @$pb.TagNumber(12)
  void clearDistanceMin() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get distanceMax => $_getIZ(12);
  @$pb.TagNumber(13)
  set distanceMax($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDistanceMax() => $_has(12);
  @$pb.TagNumber(13)
  void clearDistanceMax() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get blurBackground => $_getBF(13);
  @$pb.TagNumber(14)
  set blurBackground($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasBlurBackground() => $_has(13);
  @$pb.TagNumber(14)
  void clearBlurBackground() => $_clearField(14);
}

class LoadSettingsResponse extends $pb.GeneratedMessage {
  factory LoadSettingsResponse({
    $core.int? width,
    $core.int? height,
    $core.bool? crop,
    $core.int? cropWidth,
    $core.int? cropHeight,
    $core.bool? eyesCheck,
    $core.bool? lipsCheck,
    $core.bool? lighting,
    $core.int? intensityRed,
    $core.int? intensityGreen,
    $core.int? intensityBlue,
    $core.int? distanceMin,
    $core.int? distanceMax,
    $core.bool? blurBackground,
    $core.Iterable<CameraResolution>? cameraResolutions,
    $core.bool? cameraOrderingAutomatic,
    $core.bool? msmfSelection,
    $core.String? backgroundColor,
    $core.String? backgroundMethod,
    $core.bool? eyeGlassesCheck,
    $core.bool? headPoseCheck,
    $core.bool? sharpnessCheck,
    $core.bool? redEyeDetectionCheck,
    $core.bool? headSizeCheck,
    $core.bool? expressionCheck,
    $core.bool? gazeCheck,
    $core.bool? lightingEvennessCheck,
    $core.String? photoFormat,
    $core.int? jpegQuality,
    $core.bool? glassesLightsOff,
    $core.bool? ofiqChecks,
    $core.String? ledLayout,
    $core.String? focusColor,
    $core.int? focusIntensity,
    $core.int? expectedCameras,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (crop != null) result.crop = crop;
    if (cropWidth != null) result.cropWidth = cropWidth;
    if (cropHeight != null) result.cropHeight = cropHeight;
    if (eyesCheck != null) result.eyesCheck = eyesCheck;
    if (lipsCheck != null) result.lipsCheck = lipsCheck;
    if (lighting != null) result.lighting = lighting;
    if (intensityRed != null) result.intensityRed = intensityRed;
    if (intensityGreen != null) result.intensityGreen = intensityGreen;
    if (intensityBlue != null) result.intensityBlue = intensityBlue;
    if (distanceMin != null) result.distanceMin = distanceMin;
    if (distanceMax != null) result.distanceMax = distanceMax;
    if (blurBackground != null) result.blurBackground = blurBackground;
    if (cameraResolutions != null)
      result.cameraResolutions.addAll(cameraResolutions);
    if (cameraOrderingAutomatic != null)
      result.cameraOrderingAutomatic = cameraOrderingAutomatic;
    if (msmfSelection != null) result.msmfSelection = msmfSelection;
    if (backgroundColor != null) result.backgroundColor = backgroundColor;
    if (backgroundMethod != null) result.backgroundMethod = backgroundMethod;
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
    if (photoFormat != null) result.photoFormat = photoFormat;
    if (jpegQuality != null) result.jpegQuality = jpegQuality;
    if (glassesLightsOff != null) result.glassesLightsOff = glassesLightsOff;
    if (ofiqChecks != null) result.ofiqChecks = ofiqChecks;
    if (ledLayout != null) result.ledLayout = ledLayout;
    if (focusColor != null) result.focusColor = focusColor;
    if (focusIntensity != null) result.focusIntensity = focusIntensity;
    if (expectedCameras != null) result.expectedCameras = expectedCameras;
    return result;
  }

  LoadSettingsResponse._();

  factory LoadSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoadSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoadSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'width')
    ..aI(2, _omitFieldNames ? '' : 'height')
    ..aOB(3, _omitFieldNames ? '' : 'crop')
    ..aI(4, _omitFieldNames ? '' : 'cropWidth')
    ..aI(5, _omitFieldNames ? '' : 'cropHeight')
    ..aOB(6, _omitFieldNames ? '' : 'eyesCheck')
    ..aOB(7, _omitFieldNames ? '' : 'lipsCheck')
    ..aOB(8, _omitFieldNames ? '' : 'lighting')
    ..aI(9, _omitFieldNames ? '' : 'intensityRed')
    ..aI(10, _omitFieldNames ? '' : 'intensityGreen')
    ..aI(11, _omitFieldNames ? '' : 'intensityBlue')
    ..aI(12, _omitFieldNames ? '' : 'distanceMin')
    ..aI(13, _omitFieldNames ? '' : 'distanceMax')
    ..aOB(14, _omitFieldNames ? '' : 'blurBackground')
    ..pPM<CameraResolution>(15, _omitFieldNames ? '' : 'cameraResolutions',
        subBuilder: CameraResolution.create)
    ..aOB(16, _omitFieldNames ? '' : 'cameraOrderingAutomatic')
    ..aOB(17, _omitFieldNames ? '' : 'msmfSelection')
    ..aOS(19, _omitFieldNames ? '' : 'backgroundColor')
    ..aOS(20, _omitFieldNames ? '' : 'backgroundMethod')
    ..aOB(21, _omitFieldNames ? '' : 'eyeGlassesCheck')
    ..aOB(22, _omitFieldNames ? '' : 'headPoseCheck')
    ..aOB(23, _omitFieldNames ? '' : 'sharpnessCheck')
    ..aOB(24, _omitFieldNames ? '' : 'redEyeDetectionCheck')
    ..aOB(25, _omitFieldNames ? '' : 'headSizeCheck')
    ..aOB(26, _omitFieldNames ? '' : 'expressionCheck')
    ..aOB(27, _omitFieldNames ? '' : 'gazeCheck')
    ..aOB(28, _omitFieldNames ? '' : 'lightingEvennessCheck')
    ..aOS(29, _omitFieldNames ? '' : 'photoFormat')
    ..aI(30, _omitFieldNames ? '' : 'jpegQuality')
    ..aOB(34, _omitFieldNames ? '' : 'glassesLightsOff')
    ..aOB(35, _omitFieldNames ? '' : 'ofiqChecks')
    ..aOS(36, _omitFieldNames ? '' : 'ledLayout')
    ..aOS(37, _omitFieldNames ? '' : 'focusColor')
    ..aI(38, _omitFieldNames ? '' : 'focusIntensity')
    ..aI(39, _omitFieldNames ? '' : 'expectedCameras')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadSettingsResponse copyWith(void Function(LoadSettingsResponse) updates) =>
      super.copyWith((message) => updates(message as LoadSettingsResponse))
          as LoadSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoadSettingsResponse create() => LoadSettingsResponse._();
  @$core.override
  LoadSettingsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoadSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoadSettingsResponse>(create);
  static LoadSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get crop => $_getBF(2);
  @$pb.TagNumber(3)
  set crop($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCrop() => $_has(2);
  @$pb.TagNumber(3)
  void clearCrop() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get cropWidth => $_getIZ(3);
  @$pb.TagNumber(4)
  set cropWidth($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCropWidth() => $_has(3);
  @$pb.TagNumber(4)
  void clearCropWidth() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get cropHeight => $_getIZ(4);
  @$pb.TagNumber(5)
  set cropHeight($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCropHeight() => $_has(4);
  @$pb.TagNumber(5)
  void clearCropHeight() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get eyesCheck => $_getBF(5);
  @$pb.TagNumber(6)
  set eyesCheck($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEyesCheck() => $_has(5);
  @$pb.TagNumber(6)
  void clearEyesCheck() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get lipsCheck => $_getBF(6);
  @$pb.TagNumber(7)
  set lipsCheck($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLipsCheck() => $_has(6);
  @$pb.TagNumber(7)
  void clearLipsCheck() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get lighting => $_getBF(7);
  @$pb.TagNumber(8)
  set lighting($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLighting() => $_has(7);
  @$pb.TagNumber(8)
  void clearLighting() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get intensityRed => $_getIZ(8);
  @$pb.TagNumber(9)
  set intensityRed($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIntensityRed() => $_has(8);
  @$pb.TagNumber(9)
  void clearIntensityRed() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get intensityGreen => $_getIZ(9);
  @$pb.TagNumber(10)
  set intensityGreen($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIntensityGreen() => $_has(9);
  @$pb.TagNumber(10)
  void clearIntensityGreen() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get intensityBlue => $_getIZ(10);
  @$pb.TagNumber(11)
  set intensityBlue($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasIntensityBlue() => $_has(10);
  @$pb.TagNumber(11)
  void clearIntensityBlue() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get distanceMin => $_getIZ(11);
  @$pb.TagNumber(12)
  set distanceMin($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDistanceMin() => $_has(11);
  @$pb.TagNumber(12)
  void clearDistanceMin() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get distanceMax => $_getIZ(12);
  @$pb.TagNumber(13)
  set distanceMax($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDistanceMax() => $_has(12);
  @$pb.TagNumber(13)
  void clearDistanceMax() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get blurBackground => $_getBF(13);
  @$pb.TagNumber(14)
  set blurBackground($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasBlurBackground() => $_has(13);
  @$pb.TagNumber(14)
  void clearBlurBackground() => $_clearField(14);

  @$pb.TagNumber(15)
  $pb.PbList<CameraResolution> get cameraResolutions => $_getList(14);

  /// true = automatic camera ordering (positions from USB port via the standard-hub map);
  /// false = manual calibration.
  @$pb.TagNumber(16)
  $core.bool get cameraOrderingAutomatic => $_getBF(15);
  @$pb.TagNumber(16)
  set cameraOrderingAutomatic($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCameraOrderingAutomatic() => $_has(15);
  @$pb.TagNumber(16)
  void clearCameraOrderingAutomatic() => $_clearField(16);

  /// true = use the faster Media Foundation backend for the selection scan (Windows).
  @$pb.TagNumber(17)
  $core.bool get msmfSelection => $_getBF(16);
  @$pb.TagNumber(17)
  set msmfSelection($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasMsmfSelection() => $_has(16);
  @$pb.TagNumber(17)
  void clearMsmfSelection() => $_clearField(17);

  @$pb.TagNumber(19)
  $core.String get backgroundColor => $_getSZ(17);
  @$pb.TagNumber(19)
  set backgroundColor($core.String value) => $_setString(17, value);
  @$pb.TagNumber(19)
  $core.bool hasBackgroundColor() => $_has(17);
  @$pb.TagNumber(19)
  void clearBackgroundColor() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get backgroundMethod => $_getSZ(18);
  @$pb.TagNumber(20)
  set backgroundMethod($core.String value) => $_setString(18, value);
  @$pb.TagNumber(20)
  $core.bool hasBackgroundMethod() => $_has(18);
  @$pb.TagNumber(20)
  void clearBackgroundMethod() => $_clearField(20);

  /// Extra ICAO checks on/off (informational).
  @$pb.TagNumber(21)
  $core.bool get eyeGlassesCheck => $_getBF(19);
  @$pb.TagNumber(21)
  set eyeGlassesCheck($core.bool value) => $_setBool(19, value);
  @$pb.TagNumber(21)
  $core.bool hasEyeGlassesCheck() => $_has(19);
  @$pb.TagNumber(21)
  void clearEyeGlassesCheck() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.bool get headPoseCheck => $_getBF(20);
  @$pb.TagNumber(22)
  set headPoseCheck($core.bool value) => $_setBool(20, value);
  @$pb.TagNumber(22)
  $core.bool hasHeadPoseCheck() => $_has(20);
  @$pb.TagNumber(22)
  void clearHeadPoseCheck() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.bool get sharpnessCheck => $_getBF(21);
  @$pb.TagNumber(23)
  set sharpnessCheck($core.bool value) => $_setBool(21, value);
  @$pb.TagNumber(23)
  $core.bool hasSharpnessCheck() => $_has(21);
  @$pb.TagNumber(23)
  void clearSharpnessCheck() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.bool get redEyeDetectionCheck => $_getBF(22);
  @$pb.TagNumber(24)
  set redEyeDetectionCheck($core.bool value) => $_setBool(22, value);
  @$pb.TagNumber(24)
  $core.bool hasRedEyeDetectionCheck() => $_has(22);
  @$pb.TagNumber(24)
  void clearRedEyeDetectionCheck() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.bool get headSizeCheck => $_getBF(23);
  @$pb.TagNumber(25)
  set headSizeCheck($core.bool value) => $_setBool(23, value);
  @$pb.TagNumber(25)
  $core.bool hasHeadSizeCheck() => $_has(23);
  @$pb.TagNumber(25)
  void clearHeadSizeCheck() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.bool get expressionCheck => $_getBF(24);
  @$pb.TagNumber(26)
  set expressionCheck($core.bool value) => $_setBool(24, value);
  @$pb.TagNumber(26)
  $core.bool hasExpressionCheck() => $_has(24);
  @$pb.TagNumber(26)
  void clearExpressionCheck() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.bool get gazeCheck => $_getBF(25);
  @$pb.TagNumber(27)
  set gazeCheck($core.bool value) => $_setBool(25, value);
  @$pb.TagNumber(27)
  $core.bool hasGazeCheck() => $_has(25);
  @$pb.TagNumber(27)
  void clearGazeCheck() => $_clearField(27);

  @$pb.TagNumber(28)
  $core.bool get lightingEvennessCheck => $_getBF(26);
  @$pb.TagNumber(28)
  set lightingEvennessCheck($core.bool value) => $_setBool(26, value);
  @$pb.TagNumber(28)
  $core.bool hasLightingEvennessCheck() => $_has(26);
  @$pb.TagNumber(28)
  void clearLightingEvennessCheck() => $_clearField(28);

  /// Photo format key ("icao_35x45"/"us_2x2"/"ca_50x70"): decides the aspect ratio and
  /// the face framing/head-size bands.
  @$pb.TagNumber(29)
  $core.String get photoFormat => $_getSZ(27);
  @$pb.TagNumber(29)
  set photoFormat($core.String value) => $_setString(27, value);
  @$pb.TagNumber(29)
  $core.bool hasPhotoFormat() => $_has(27);
  @$pb.TagNumber(29)
  void clearPhotoFormat() => $_clearField(29);

  /// JPEG encoding quality for delivered photos (50-100; OpenCV default was 95).
  @$pb.TagNumber(30)
  $core.int get jpegQuality => $_getIZ(28);
  @$pb.TagNumber(30)
  set jpegQuality($core.int value) => $_setSignedInt32(28, value);
  @$pb.TagNumber(30)
  $core.bool hasJpegQuality() => $_has(28);
  @$pb.TagNumber(30)
  void clearJpegQuality() => $_clearField(30);

  /// Glasses mode: take the high-res photo with ALL LEDs off when the subject
  /// wears glasses, so nothing can reflect in the lenses.
  @$pb.TagNumber(34)
  $core.bool get glassesLightsOff => $_getBF(29);
  @$pb.TagNumber(34)
  set glassesLightsOff($core.bool value) => $_setBool(29, value);
  @$pb.TagNumber(34)
  $core.bool hasGlassesLightsOff() => $_has(29);
  @$pb.TagNumber(34)
  void clearGlassesLightsOff() => $_clearField(34);

  /// Score delivered photos with OFIQ (ISO/IEC 29794-5) instead of the kiosk's
  /// own informational quality checks.
  @$pb.TagNumber(35)
  $core.bool get ofiqChecks => $_getBF(30);
  @$pb.TagNumber(35)
  set ofiqChecks($core.bool value) => $_setBool(30, value);
  @$pb.TagNumber(35)
  $core.bool hasOfiqChecks() => $_has(30);
  @$pb.TagNumber(35)
  void clearOfiqChecks() => $_clearField(35);

  /// LED hardware layout on the Plasma board: "strip" (vertical strips) or
  /// "ring" (one LED ring per camera). Decides which MicroPython files the
  /// server provisions onto the board.
  @$pb.TagNumber(36)
  $core.String get ledLayout => $_getSZ(31);
  @$pb.TagNumber(36)
  set ledLayout($core.String value) => $_setString(31, value);
  @$pb.TagNumber(36)
  $core.bool hasLedLayout() => $_has(31);
  @$pb.TagNumber(36)
  void clearLedLayout() => $_clearField(36);

  /// Focus light (the per-camera indicator): colour as RRGGBB hex and
  /// intensity as a percentage 0-100.
  @$pb.TagNumber(37)
  $core.String get focusColor => $_getSZ(32);
  @$pb.TagNumber(37)
  set focusColor($core.String value) => $_setString(32, value);
  @$pb.TagNumber(37)
  $core.bool hasFocusColor() => $_has(32);
  @$pb.TagNumber(37)
  void clearFocusColor() => $_clearField(37);

  @$pb.TagNumber(38)
  $core.int get focusIntensity => $_getIZ(33);
  @$pb.TagNumber(38)
  set focusIntensity($core.int value) => $_setSignedInt32(33, value);
  @$pb.TagNumber(38)
  $core.bool hasFocusIntensity() => $_has(33);
  @$pb.TagNumber(38)
  void clearFocusIntensity() => $_clearField(38);

  /// How many cameras this kiosk is built with. 0 = derive from the
  /// calibration file (the historical behaviour). The hardware watcher's
  /// camera self-heal compares the attached count against this.
  @$pb.TagNumber(39)
  $core.int get expectedCameras => $_getIZ(34);
  @$pb.TagNumber(39)
  set expectedCameras($core.int value) => $_setSignedInt32(34, value);
  @$pb.TagNumber(39)
  $core.bool hasExpectedCameras() => $_has(34);
  @$pb.TagNumber(39)
  void clearExpectedCameras() => $_clearField(39);
}

/// The request message containing the resolution value.
class ResolutionRequest extends $pb.GeneratedMessage {
  factory ResolutionRequest({
    $core.int? width,
    $core.int? height,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    return result;
  }

  ResolutionRequest._();

  factory ResolutionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResolutionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResolutionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'width')
    ..aI(2, _omitFieldNames ? '' : 'height')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolutionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolutionRequest copyWith(void Function(ResolutionRequest) updates) =>
      super.copyWith((message) => updates(message as ResolutionRequest))
          as ResolutionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolutionRequest create() => ResolutionRequest._();
  @$core.override
  ResolutionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResolutionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResolutionRequest>(create);
  static ResolutionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);
}

/// The response message containing the resolution value.
class ResolutionResponse extends $pb.GeneratedMessage {
  factory ResolutionResponse({
    $core.int? width,
    $core.int? height,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    return result;
  }

  ResolutionResponse._();

  factory ResolutionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResolutionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResolutionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'width')
    ..aI(2, _omitFieldNames ? '' : 'height')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolutionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolutionResponse copyWith(void Function(ResolutionResponse) updates) =>
      super.copyWith((message) => updates(message as ResolutionResponse))
          as ResolutionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolutionResponse create() => ResolutionResponse._();
  @$core.override
  ResolutionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResolutionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResolutionResponse>(create);
  static ResolutionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);
}

/// The request message containing the crop resolution value.
class CropResolutionRequest extends $pb.GeneratedMessage {
  factory CropResolutionRequest({
    $core.int? width,
    $core.int? height,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    return result;
  }

  CropResolutionRequest._();

  factory CropResolutionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CropResolutionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CropResolutionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'width')
    ..aI(2, _omitFieldNames ? '' : 'height')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CropResolutionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CropResolutionRequest copyWith(
          void Function(CropResolutionRequest) updates) =>
      super.copyWith((message) => updates(message as CropResolutionRequest))
          as CropResolutionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CropResolutionRequest create() => CropResolutionRequest._();
  @$core.override
  CropResolutionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CropResolutionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CropResolutionRequest>(create);
  static CropResolutionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);
}

/// The response message containing the crop resolution value.
class CropResolutionResponse extends $pb.GeneratedMessage {
  factory CropResolutionResponse({
    $core.int? width,
    $core.int? height,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    return result;
  }

  CropResolutionResponse._();

  factory CropResolutionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CropResolutionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CropResolutionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'width')
    ..aI(2, _omitFieldNames ? '' : 'height')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CropResolutionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CropResolutionResponse copyWith(
          void Function(CropResolutionResponse) updates) =>
      super.copyWith((message) => updates(message as CropResolutionResponse))
          as CropResolutionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CropResolutionResponse create() => CropResolutionResponse._();
  @$core.override
  CropResolutionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CropResolutionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CropResolutionResponse>(create);
  static CropResolutionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);
}

/// The request message containing the crop value.
class CropRequest extends $pb.GeneratedMessage {
  factory CropRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  CropRequest._();

  factory CropRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CropRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CropRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CropRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CropRequest copyWith(void Function(CropRequest) updates) =>
      super.copyWith((message) => updates(message as CropRequest))
          as CropRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CropRequest create() => CropRequest._();
  @$core.override
  CropRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CropRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CropRequest>(create);
  static CropRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the crop value.
class CropResponse extends $pb.GeneratedMessage {
  factory CropResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  CropResponse._();

  factory CropResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CropResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CropResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CropResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CropResponse copyWith(void Function(CropResponse) updates) =>
      super.copyWith((message) => updates(message as CropResponse))
          as CropResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CropResponse create() => CropResponse._();
  @$core.override
  CropResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CropResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CropResponse>(create);
  static CropResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the eyes check value.
class EyesCheckRequest extends $pb.GeneratedMessage {
  factory EyesCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  EyesCheckRequest._();

  factory EyesCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EyesCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EyesCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EyesCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EyesCheckRequest copyWith(void Function(EyesCheckRequest) updates) =>
      super.copyWith((message) => updates(message as EyesCheckRequest))
          as EyesCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EyesCheckRequest create() => EyesCheckRequest._();
  @$core.override
  EyesCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EyesCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EyesCheckRequest>(create);
  static EyesCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the eyes check value.
class EyesCheckResponse extends $pb.GeneratedMessage {
  factory EyesCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  EyesCheckResponse._();

  factory EyesCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EyesCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EyesCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EyesCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EyesCheckResponse copyWith(void Function(EyesCheckResponse) updates) =>
      super.copyWith((message) => updates(message as EyesCheckResponse))
          as EyesCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EyesCheckResponse create() => EyesCheckResponse._();
  @$core.override
  EyesCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EyesCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EyesCheckResponse>(create);
  static EyesCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the lips check value.
class LipsCheckRequest extends $pb.GeneratedMessage {
  factory LipsCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  LipsCheckRequest._();

  factory LipsCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LipsCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LipsCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LipsCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LipsCheckRequest copyWith(void Function(LipsCheckRequest) updates) =>
      super.copyWith((message) => updates(message as LipsCheckRequest))
          as LipsCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LipsCheckRequest create() => LipsCheckRequest._();
  @$core.override
  LipsCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LipsCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LipsCheckRequest>(create);
  static LipsCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the lips check value.
class LipsCheckResponse extends $pb.GeneratedMessage {
  factory LipsCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  LipsCheckResponse._();

  factory LipsCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LipsCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LipsCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LipsCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LipsCheckResponse copyWith(void Function(LipsCheckResponse) updates) =>
      super.copyWith((message) => updates(message as LipsCheckResponse))
          as LipsCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LipsCheckResponse create() => LipsCheckResponse._();
  @$core.override
  LipsCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LipsCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LipsCheckResponse>(create);
  static LipsCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the lighting value.
class LightingRequest extends $pb.GeneratedMessage {
  factory LightingRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  LightingRequest._();

  factory LightingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LightingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LightingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightingRequest copyWith(void Function(LightingRequest) updates) =>
      super.copyWith((message) => updates(message as LightingRequest))
          as LightingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LightingRequest create() => LightingRequest._();
  @$core.override
  LightingRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LightingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LightingRequest>(create);
  static LightingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the lighting value.
class LightingResponse extends $pb.GeneratedMessage {
  factory LightingResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  LightingResponse._();

  factory LightingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LightingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LightingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightingResponse copyWith(void Function(LightingResponse) updates) =>
      super.copyWith((message) => updates(message as LightingResponse))
          as LightingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LightingResponse create() => LightingResponse._();
  @$core.override
  LightingResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LightingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LightingResponse>(create);
  static LightingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the intensity value.
class IntensityRequest extends $pb.GeneratedMessage {
  factory IntensityRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  IntensityRequest._();

  factory IntensityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IntensityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IntensityRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntensityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntensityRequest copyWith(void Function(IntensityRequest) updates) =>
      super.copyWith((message) => updates(message as IntensityRequest))
          as IntensityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IntensityRequest create() => IntensityRequest._();
  @$core.override
  IntensityRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IntensityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IntensityRequest>(create);
  static IntensityRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the intensity value.
class IntensityResponse extends $pb.GeneratedMessage {
  factory IntensityResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  IntensityResponse._();

  factory IntensityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IntensityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IntensityResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntensityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntensityResponse copyWith(void Function(IntensityResponse) updates) =>
      super.copyWith((message) => updates(message as IntensityResponse))
          as IntensityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IntensityResponse create() => IntensityResponse._();
  @$core.override
  IntensityResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IntensityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IntensityResponse>(create);
  static IntensityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the distance min value.
class DistanceMinRequest extends $pb.GeneratedMessage {
  factory DistanceMinRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  DistanceMinRequest._();

  factory DistanceMinRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DistanceMinRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DistanceMinRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DistanceMinRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DistanceMinRequest copyWith(void Function(DistanceMinRequest) updates) =>
      super.copyWith((message) => updates(message as DistanceMinRequest))
          as DistanceMinRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DistanceMinRequest create() => DistanceMinRequest._();
  @$core.override
  DistanceMinRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DistanceMinRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DistanceMinRequest>(create);
  static DistanceMinRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the distance min value.
class DistanceMinResponse extends $pb.GeneratedMessage {
  factory DistanceMinResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  DistanceMinResponse._();

  factory DistanceMinResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DistanceMinResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DistanceMinResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DistanceMinResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DistanceMinResponse copyWith(void Function(DistanceMinResponse) updates) =>
      super.copyWith((message) => updates(message as DistanceMinResponse))
          as DistanceMinResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DistanceMinResponse create() => DistanceMinResponse._();
  @$core.override
  DistanceMinResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DistanceMinResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DistanceMinResponse>(create);
  static DistanceMinResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the distance max value.
class DistanceMaxRequest extends $pb.GeneratedMessage {
  factory DistanceMaxRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  DistanceMaxRequest._();

  factory DistanceMaxRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DistanceMaxRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DistanceMaxRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DistanceMaxRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DistanceMaxRequest copyWith(void Function(DistanceMaxRequest) updates) =>
      super.copyWith((message) => updates(message as DistanceMaxRequest))
          as DistanceMaxRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DistanceMaxRequest create() => DistanceMaxRequest._();
  @$core.override
  DistanceMaxRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DistanceMaxRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DistanceMaxRequest>(create);
  static DistanceMaxRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the distance max value.
class DistanceMaxResponse extends $pb.GeneratedMessage {
  factory DistanceMaxResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  DistanceMaxResponse._();

  factory DistanceMaxResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DistanceMaxResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DistanceMaxResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DistanceMaxResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DistanceMaxResponse copyWith(void Function(DistanceMaxResponse) updates) =>
      super.copyWith((message) => updates(message as DistanceMaxResponse))
          as DistanceMaxResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DistanceMaxResponse create() => DistanceMaxResponse._();
  @$core.override
  DistanceMaxResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DistanceMaxResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DistanceMaxResponse>(create);
  static DistanceMaxResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the camera ordering mode.
/// true = automatic (derive positions from USB ports); false = manual calibration.
class CameraOrderingModeRequest extends $pb.GeneratedMessage {
  factory CameraOrderingModeRequest({
    $core.bool? automatic,
  }) {
    final result = create();
    if (automatic != null) result.automatic = automatic;
    return result;
  }

  CameraOrderingModeRequest._();

  factory CameraOrderingModeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CameraOrderingModeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CameraOrderingModeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'automatic')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraOrderingModeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraOrderingModeRequest copyWith(
          void Function(CameraOrderingModeRequest) updates) =>
      super.copyWith((message) => updates(message as CameraOrderingModeRequest))
          as CameraOrderingModeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CameraOrderingModeRequest create() => CameraOrderingModeRequest._();
  @$core.override
  CameraOrderingModeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CameraOrderingModeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CameraOrderingModeRequest>(create);
  static CameraOrderingModeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get automatic => $_getBF(0);
  @$pb.TagNumber(1)
  set automatic($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAutomatic() => $_has(0);
  @$pb.TagNumber(1)
  void clearAutomatic() => $_clearField(1);
}

/// The response message containing the camera ordering mode.
class CameraOrderingModeResponse extends $pb.GeneratedMessage {
  factory CameraOrderingModeResponse({
    $core.bool? automatic,
  }) {
    final result = create();
    if (automatic != null) result.automatic = automatic;
    return result;
  }

  CameraOrderingModeResponse._();

  factory CameraOrderingModeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CameraOrderingModeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CameraOrderingModeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'automatic')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraOrderingModeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraOrderingModeResponse copyWith(
          void Function(CameraOrderingModeResponse) updates) =>
      super.copyWith(
              (message) => updates(message as CameraOrderingModeResponse))
          as CameraOrderingModeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CameraOrderingModeResponse create() => CameraOrderingModeResponse._();
  @$core.override
  CameraOrderingModeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CameraOrderingModeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CameraOrderingModeResponse>(create);
  static CameraOrderingModeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get automatic => $_getBF(0);
  @$pb.TagNumber(1)
  set automatic($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAutomatic() => $_has(0);
  @$pb.TagNumber(1)
  void clearAutomatic() => $_clearField(1);
}

/// The request message containing whether MSMF is used for the selection scan.
class MsmfSelectionRequest extends $pb.GeneratedMessage {
  factory MsmfSelectionRequest({
    $core.bool? enabled,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  MsmfSelectionRequest._();

  factory MsmfSelectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MsmfSelectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MsmfSelectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MsmfSelectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MsmfSelectionRequest copyWith(void Function(MsmfSelectionRequest) updates) =>
      super.copyWith((message) => updates(message as MsmfSelectionRequest))
          as MsmfSelectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MsmfSelectionRequest create() => MsmfSelectionRequest._();
  @$core.override
  MsmfSelectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MsmfSelectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MsmfSelectionRequest>(create);
  static MsmfSelectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);
}

/// The response message containing whether MSMF is used for the selection scan.
class MsmfSelectionResponse extends $pb.GeneratedMessage {
  factory MsmfSelectionResponse({
    $core.bool? enabled,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  MsmfSelectionResponse._();

  factory MsmfSelectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MsmfSelectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MsmfSelectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MsmfSelectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MsmfSelectionResponse copyWith(
          void Function(MsmfSelectionResponse) updates) =>
      super.copyWith((message) => updates(message as MsmfSelectionResponse))
          as MsmfSelectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MsmfSelectionResponse create() => MsmfSelectionResponse._();
  @$core.override
  MsmfSelectionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MsmfSelectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MsmfSelectionResponse>(create);
  static MsmfSelectionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);
}

/// The request/response for the background erasing method
/// ("none"/"mediapipe"/"modnet").
class BackgroundMethodRequest extends $pb.GeneratedMessage {
  factory BackgroundMethodRequest({
    $core.String? method,
  }) {
    final result = create();
    if (method != null) result.method = method;
    return result;
  }

  BackgroundMethodRequest._();

  factory BackgroundMethodRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BackgroundMethodRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BackgroundMethodRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'method')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackgroundMethodRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackgroundMethodRequest copyWith(
          void Function(BackgroundMethodRequest) updates) =>
      super.copyWith((message) => updates(message as BackgroundMethodRequest))
          as BackgroundMethodRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BackgroundMethodRequest create() => BackgroundMethodRequest._();
  @$core.override
  BackgroundMethodRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BackgroundMethodRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BackgroundMethodRequest>(create);
  static BackgroundMethodRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get method => $_getSZ(0);
  @$pb.TagNumber(1)
  set method($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMethod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMethod() => $_clearField(1);
}

class BackgroundMethodResponse extends $pb.GeneratedMessage {
  factory BackgroundMethodResponse({
    $core.String? method,
  }) {
    final result = create();
    if (method != null) result.method = method;
    return result;
  }

  BackgroundMethodResponse._();

  factory BackgroundMethodResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BackgroundMethodResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BackgroundMethodResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'method')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackgroundMethodResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackgroundMethodResponse copyWith(
          void Function(BackgroundMethodResponse) updates) =>
      super.copyWith((message) => updates(message as BackgroundMethodResponse))
          as BackgroundMethodResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BackgroundMethodResponse create() => BackgroundMethodResponse._();
  @$core.override
  BackgroundMethodResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BackgroundMethodResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BackgroundMethodResponse>(create);
  static BackgroundMethodResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get method => $_getSZ(0);
  @$pb.TagNumber(1)
  set method($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMethod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMethod() => $_clearField(1);
}

/// The request/response for the background fill colour (RRGGBB hex).
class BackgroundColorRequest extends $pb.GeneratedMessage {
  factory BackgroundColorRequest({
    $core.String? color,
  }) {
    final result = create();
    if (color != null) result.color = color;
    return result;
  }

  BackgroundColorRequest._();

  factory BackgroundColorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BackgroundColorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BackgroundColorRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'color')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackgroundColorRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackgroundColorRequest copyWith(
          void Function(BackgroundColorRequest) updates) =>
      super.copyWith((message) => updates(message as BackgroundColorRequest))
          as BackgroundColorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BackgroundColorRequest create() => BackgroundColorRequest._();
  @$core.override
  BackgroundColorRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BackgroundColorRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BackgroundColorRequest>(create);
  static BackgroundColorRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get color => $_getSZ(0);
  @$pb.TagNumber(1)
  set color($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColor() => $_has(0);
  @$pb.TagNumber(1)
  void clearColor() => $_clearField(1);
}

class BackgroundColorResponse extends $pb.GeneratedMessage {
  factory BackgroundColorResponse({
    $core.String? color,
  }) {
    final result = create();
    if (color != null) result.color = color;
    return result;
  }

  BackgroundColorResponse._();

  factory BackgroundColorResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BackgroundColorResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BackgroundColorResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'color')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackgroundColorResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackgroundColorResponse copyWith(
          void Function(BackgroundColorResponse) updates) =>
      super.copyWith((message) => updates(message as BackgroundColorResponse))
          as BackgroundColorResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BackgroundColorResponse create() => BackgroundColorResponse._();
  @$core.override
  BackgroundColorResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BackgroundColorResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BackgroundColorResponse>(create);
  static BackgroundColorResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get color => $_getSZ(0);
  @$pb.TagNumber(1)
  set color($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColor() => $_has(0);
  @$pb.TagNumber(1)
  void clearColor() => $_clearField(1);
}

/// The request/response for the ICAO "no glasses" check.
class EyeGlassesCheckRequest extends $pb.GeneratedMessage {
  factory EyeGlassesCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  EyeGlassesCheckRequest._();

  factory EyeGlassesCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EyeGlassesCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EyeGlassesCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EyeGlassesCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EyeGlassesCheckRequest copyWith(
          void Function(EyeGlassesCheckRequest) updates) =>
      super.copyWith((message) => updates(message as EyeGlassesCheckRequest))
          as EyeGlassesCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EyeGlassesCheckRequest create() => EyeGlassesCheckRequest._();
  @$core.override
  EyeGlassesCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EyeGlassesCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EyeGlassesCheckRequest>(create);
  static EyeGlassesCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class EyeGlassesCheckResponse extends $pb.GeneratedMessage {
  factory EyeGlassesCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  EyeGlassesCheckResponse._();

  factory EyeGlassesCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EyeGlassesCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EyeGlassesCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EyeGlassesCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EyeGlassesCheckResponse copyWith(
          void Function(EyeGlassesCheckResponse) updates) =>
      super.copyWith((message) => updates(message as EyeGlassesCheckResponse))
          as EyeGlassesCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EyeGlassesCheckResponse create() => EyeGlassesCheckResponse._();
  @$core.override
  EyeGlassesCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EyeGlassesCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EyeGlassesCheckResponse>(create);
  static EyeGlassesCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the frontal head-pose check.
class HeadPoseCheckRequest extends $pb.GeneratedMessage {
  factory HeadPoseCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  HeadPoseCheckRequest._();

  factory HeadPoseCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HeadPoseCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeadPoseCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadPoseCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadPoseCheckRequest copyWith(void Function(HeadPoseCheckRequest) updates) =>
      super.copyWith((message) => updates(message as HeadPoseCheckRequest))
          as HeadPoseCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeadPoseCheckRequest create() => HeadPoseCheckRequest._();
  @$core.override
  HeadPoseCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HeadPoseCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeadPoseCheckRequest>(create);
  static HeadPoseCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class HeadPoseCheckResponse extends $pb.GeneratedMessage {
  factory HeadPoseCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  HeadPoseCheckResponse._();

  factory HeadPoseCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HeadPoseCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeadPoseCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadPoseCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadPoseCheckResponse copyWith(
          void Function(HeadPoseCheckResponse) updates) =>
      super.copyWith((message) => updates(message as HeadPoseCheckResponse))
          as HeadPoseCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeadPoseCheckResponse create() => HeadPoseCheckResponse._();
  @$core.override
  HeadPoseCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HeadPoseCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeadPoseCheckResponse>(create);
  static HeadPoseCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the sharpness/focus check.
class SharpnessCheckRequest extends $pb.GeneratedMessage {
  factory SharpnessCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  SharpnessCheckRequest._();

  factory SharpnessCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SharpnessCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SharpnessCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharpnessCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharpnessCheckRequest copyWith(
          void Function(SharpnessCheckRequest) updates) =>
      super.copyWith((message) => updates(message as SharpnessCheckRequest))
          as SharpnessCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SharpnessCheckRequest create() => SharpnessCheckRequest._();
  @$core.override
  SharpnessCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SharpnessCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SharpnessCheckRequest>(create);
  static SharpnessCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class SharpnessCheckResponse extends $pb.GeneratedMessage {
  factory SharpnessCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  SharpnessCheckResponse._();

  factory SharpnessCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SharpnessCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SharpnessCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharpnessCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharpnessCheckResponse copyWith(
          void Function(SharpnessCheckResponse) updates) =>
      super.copyWith((message) => updates(message as SharpnessCheckResponse))
          as SharpnessCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SharpnessCheckResponse create() => SharpnessCheckResponse._();
  @$core.override
  SharpnessCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SharpnessCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SharpnessCheckResponse>(create);
  static SharpnessCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the red-eye detection check.
class RedEyeDetectionCheckRequest extends $pb.GeneratedMessage {
  factory RedEyeDetectionCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  RedEyeDetectionCheckRequest._();

  factory RedEyeDetectionCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RedEyeDetectionCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RedEyeDetectionCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RedEyeDetectionCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RedEyeDetectionCheckRequest copyWith(
          void Function(RedEyeDetectionCheckRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RedEyeDetectionCheckRequest))
          as RedEyeDetectionCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RedEyeDetectionCheckRequest create() =>
      RedEyeDetectionCheckRequest._();
  @$core.override
  RedEyeDetectionCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RedEyeDetectionCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RedEyeDetectionCheckRequest>(create);
  static RedEyeDetectionCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class RedEyeDetectionCheckResponse extends $pb.GeneratedMessage {
  factory RedEyeDetectionCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  RedEyeDetectionCheckResponse._();

  factory RedEyeDetectionCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RedEyeDetectionCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RedEyeDetectionCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RedEyeDetectionCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RedEyeDetectionCheckResponse copyWith(
          void Function(RedEyeDetectionCheckResponse) updates) =>
      super.copyWith(
              (message) => updates(message as RedEyeDetectionCheckResponse))
          as RedEyeDetectionCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RedEyeDetectionCheckResponse create() =>
      RedEyeDetectionCheckResponse._();
  @$core.override
  RedEyeDetectionCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RedEyeDetectionCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RedEyeDetectionCheckResponse>(create);
  static RedEyeDetectionCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the head-size/position check.
class HeadSizeCheckRequest extends $pb.GeneratedMessage {
  factory HeadSizeCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  HeadSizeCheckRequest._();

  factory HeadSizeCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HeadSizeCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeadSizeCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadSizeCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadSizeCheckRequest copyWith(void Function(HeadSizeCheckRequest) updates) =>
      super.copyWith((message) => updates(message as HeadSizeCheckRequest))
          as HeadSizeCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeadSizeCheckRequest create() => HeadSizeCheckRequest._();
  @$core.override
  HeadSizeCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HeadSizeCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeadSizeCheckRequest>(create);
  static HeadSizeCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class HeadSizeCheckResponse extends $pb.GeneratedMessage {
  factory HeadSizeCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  HeadSizeCheckResponse._();

  factory HeadSizeCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HeadSizeCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeadSizeCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadSizeCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadSizeCheckResponse copyWith(
          void Function(HeadSizeCheckResponse) updates) =>
      super.copyWith((message) => updates(message as HeadSizeCheckResponse))
          as HeadSizeCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeadSizeCheckResponse create() => HeadSizeCheckResponse._();
  @$core.override
  HeadSizeCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HeadSizeCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeadSizeCheckResponse>(create);
  static HeadSizeCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the neutral-expression check.
class ExpressionCheckRequest extends $pb.GeneratedMessage {
  factory ExpressionCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  ExpressionCheckRequest._();

  factory ExpressionCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExpressionCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExpressionCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpressionCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpressionCheckRequest copyWith(
          void Function(ExpressionCheckRequest) updates) =>
      super.copyWith((message) => updates(message as ExpressionCheckRequest))
          as ExpressionCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExpressionCheckRequest create() => ExpressionCheckRequest._();
  @$core.override
  ExpressionCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExpressionCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExpressionCheckRequest>(create);
  static ExpressionCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class ExpressionCheckResponse extends $pb.GeneratedMessage {
  factory ExpressionCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  ExpressionCheckResponse._();

  factory ExpressionCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExpressionCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExpressionCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpressionCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpressionCheckResponse copyWith(
          void Function(ExpressionCheckResponse) updates) =>
      super.copyWith((message) => updates(message as ExpressionCheckResponse))
          as ExpressionCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExpressionCheckResponse create() => ExpressionCheckResponse._();
  @$core.override
  ExpressionCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExpressionCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExpressionCheckResponse>(create);
  static ExpressionCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the gaze-direction check.
class GazeCheckRequest extends $pb.GeneratedMessage {
  factory GazeCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  GazeCheckRequest._();

  factory GazeCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GazeCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GazeCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GazeCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GazeCheckRequest copyWith(void Function(GazeCheckRequest) updates) =>
      super.copyWith((message) => updates(message as GazeCheckRequest))
          as GazeCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GazeCheckRequest create() => GazeCheckRequest._();
  @$core.override
  GazeCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GazeCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GazeCheckRequest>(create);
  static GazeCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class GazeCheckResponse extends $pb.GeneratedMessage {
  factory GazeCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  GazeCheckResponse._();

  factory GazeCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GazeCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GazeCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GazeCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GazeCheckResponse copyWith(void Function(GazeCheckResponse) updates) =>
      super.copyWith((message) => updates(message as GazeCheckResponse))
          as GazeCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GazeCheckResponse create() => GazeCheckResponse._();
  @$core.override
  GazeCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GazeCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GazeCheckResponse>(create);
  static GazeCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the lighting-evenness check.
class LightingEvennessCheckRequest extends $pb.GeneratedMessage {
  factory LightingEvennessCheckRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  LightingEvennessCheckRequest._();

  factory LightingEvennessCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LightingEvennessCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LightingEvennessCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightingEvennessCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightingEvennessCheckRequest copyWith(
          void Function(LightingEvennessCheckRequest) updates) =>
      super.copyWith(
              (message) => updates(message as LightingEvennessCheckRequest))
          as LightingEvennessCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LightingEvennessCheckRequest create() =>
      LightingEvennessCheckRequest._();
  @$core.override
  LightingEvennessCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LightingEvennessCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LightingEvennessCheckRequest>(create);
  static LightingEvennessCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class LightingEvennessCheckResponse extends $pb.GeneratedMessage {
  factory LightingEvennessCheckResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  LightingEvennessCheckResponse._();

  factory LightingEvennessCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LightingEvennessCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LightingEvennessCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightingEvennessCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightingEvennessCheckResponse copyWith(
          void Function(LightingEvennessCheckResponse) updates) =>
      super.copyWith(
              (message) => updates(message as LightingEvennessCheckResponse))
          as LightingEvennessCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LightingEvennessCheckResponse create() =>
      LightingEvennessCheckResponse._();
  @$core.override
  LightingEvennessCheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LightingEvennessCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LightingEvennessCheckResponse>(create);
  static LightingEvennessCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the photo format ("icao_35x45"/"us_2x2"/"ca_50x70").
/// The response echoes the accepted key and the crop height derived from the stored
/// crop width and the format's aspect ratio.
class PhotoFormatRequest extends $pb.GeneratedMessage {
  factory PhotoFormatRequest({
    $core.String? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  PhotoFormatRequest._();

  factory PhotoFormatRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PhotoFormatRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PhotoFormatRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoFormatRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoFormatRequest copyWith(void Function(PhotoFormatRequest) updates) =>
      super.copyWith((message) => updates(message as PhotoFormatRequest))
          as PhotoFormatRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PhotoFormatRequest create() => PhotoFormatRequest._();
  @$core.override
  PhotoFormatRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PhotoFormatRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PhotoFormatRequest>(create);
  static PhotoFormatRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class PhotoFormatResponse extends $pb.GeneratedMessage {
  factory PhotoFormatResponse({
    $core.String? message,
    $core.int? cropHeight,
  }) {
    final result = create();
    if (message != null) result.message = message;
    if (cropHeight != null) result.cropHeight = cropHeight;
    return result;
  }

  PhotoFormatResponse._();

  factory PhotoFormatResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PhotoFormatResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PhotoFormatResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..aI(2, _omitFieldNames ? '' : 'cropHeight')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoFormatResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PhotoFormatResponse copyWith(void Function(PhotoFormatResponse) updates) =>
      super.copyWith((message) => updates(message as PhotoFormatResponse))
          as PhotoFormatResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PhotoFormatResponse create() => PhotoFormatResponse._();
  @$core.override
  PhotoFormatResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PhotoFormatResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PhotoFormatResponse>(create);
  static PhotoFormatResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get cropHeight => $_getIZ(1);
  @$pb.TagNumber(2)
  set cropHeight($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCropHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearCropHeight() => $_clearField(2);
}

/// The request message containing the JPEG quality (50-100).
class JpegQualityRequest extends $pb.GeneratedMessage {
  factory JpegQualityRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  JpegQualityRequest._();

  factory JpegQualityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JpegQualityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JpegQualityRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JpegQualityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JpegQualityRequest copyWith(void Function(JpegQualityRequest) updates) =>
      super.copyWith((message) => updates(message as JpegQualityRequest))
          as JpegQualityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JpegQualityRequest create() => JpegQualityRequest._();
  @$core.override
  JpegQualityRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JpegQualityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JpegQualityRequest>(create);
  static JpegQualityRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the applied JPEG quality.
class JpegQualityResponse extends $pb.GeneratedMessage {
  factory JpegQualityResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  JpegQualityResponse._();

  factory JpegQualityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JpegQualityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JpegQualityResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JpegQualityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JpegQualityResponse copyWith(void Function(JpegQualityResponse) updates) =>
      super.copyWith((message) => updates(message as JpegQualityResponse))
          as JpegQualityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JpegQualityResponse create() => JpegQualityResponse._();
  @$core.override
  JpegQualityResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JpegQualityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JpegQualityResponse>(create);
  static JpegQualityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the glasses mode (all LEDs off for the photo when
/// the subject wears glasses).
class GlassesLightsOffRequest extends $pb.GeneratedMessage {
  factory GlassesLightsOffRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  GlassesLightsOffRequest._();

  factory GlassesLightsOffRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GlassesLightsOffRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GlassesLightsOffRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GlassesLightsOffRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GlassesLightsOffRequest copyWith(
          void Function(GlassesLightsOffRequest) updates) =>
      super.copyWith((message) => updates(message as GlassesLightsOffRequest))
          as GlassesLightsOffRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GlassesLightsOffRequest create() => GlassesLightsOffRequest._();
  @$core.override
  GlassesLightsOffRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GlassesLightsOffRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GlassesLightsOffRequest>(create);
  static GlassesLightsOffRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class GlassesLightsOffResponse extends $pb.GeneratedMessage {
  factory GlassesLightsOffResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  GlassesLightsOffResponse._();

  factory GlassesLightsOffResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GlassesLightsOffResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GlassesLightsOffResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GlassesLightsOffResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GlassesLightsOffResponse copyWith(
          void Function(GlassesLightsOffResponse) updates) =>
      super.copyWith((message) => updates(message as GlassesLightsOffResponse))
          as GlassesLightsOffResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GlassesLightsOffResponse create() => GlassesLightsOffResponse._();
  @$core.override
  GlassesLightsOffResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GlassesLightsOffResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GlassesLightsOffResponse>(create);
  static GlassesLightsOffResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the OFIQ quality-report mode.
class OfiqChecksRequest extends $pb.GeneratedMessage {
  factory OfiqChecksRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  OfiqChecksRequest._();

  factory OfiqChecksRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OfiqChecksRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OfiqChecksRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OfiqChecksRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OfiqChecksRequest copyWith(void Function(OfiqChecksRequest) updates) =>
      super.copyWith((message) => updates(message as OfiqChecksRequest))
          as OfiqChecksRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OfiqChecksRequest create() => OfiqChecksRequest._();
  @$core.override
  OfiqChecksRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OfiqChecksRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OfiqChecksRequest>(create);
  static OfiqChecksRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class OfiqChecksResponse extends $pb.GeneratedMessage {
  factory OfiqChecksResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  OfiqChecksResponse._();

  factory OfiqChecksResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OfiqChecksResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OfiqChecksResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OfiqChecksResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OfiqChecksResponse copyWith(void Function(OfiqChecksResponse) updates) =>
      super.copyWith((message) => updates(message as OfiqChecksResponse))
          as OfiqChecksResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OfiqChecksResponse create() => OfiqChecksResponse._();
  @$core.override
  OfiqChecksResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OfiqChecksResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OfiqChecksResponse>(create);
  static OfiqChecksResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the LED hardware layout ("strip"/"ring").
class LedLayoutRequest extends $pb.GeneratedMessage {
  factory LedLayoutRequest({
    $core.String? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  LedLayoutRequest._();

  factory LedLayoutRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LedLayoutRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LedLayoutRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LedLayoutRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LedLayoutRequest copyWith(void Function(LedLayoutRequest) updates) =>
      super.copyWith((message) => updates(message as LedLayoutRequest))
          as LedLayoutRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LedLayoutRequest create() => LedLayoutRequest._();
  @$core.override
  LedLayoutRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LedLayoutRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LedLayoutRequest>(create);
  static LedLayoutRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class LedLayoutResponse extends $pb.GeneratedMessage {
  factory LedLayoutResponse({
    $core.String? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  LedLayoutResponse._();

  factory LedLayoutResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LedLayoutResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LedLayoutResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LedLayoutResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LedLayoutResponse copyWith(void Function(LedLayoutResponse) updates) =>
      super.copyWith((message) => updates(message as LedLayoutResponse))
          as LedLayoutResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LedLayoutResponse create() => LedLayoutResponse._();
  @$core.override
  LedLayoutResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LedLayoutResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LedLayoutResponse>(create);
  static LedLayoutResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request/response for the focus light (colour RRGGBB + intensity 0-100%).
class FocusLightRequest extends $pb.GeneratedMessage {
  factory FocusLightRequest({
    $core.String? color,
    $core.int? intensity,
  }) {
    final result = create();
    if (color != null) result.color = color;
    if (intensity != null) result.intensity = intensity;
    return result;
  }

  FocusLightRequest._();

  factory FocusLightRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FocusLightRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FocusLightRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'color')
    ..aI(2, _omitFieldNames ? '' : 'intensity')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusLightRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusLightRequest copyWith(void Function(FocusLightRequest) updates) =>
      super.copyWith((message) => updates(message as FocusLightRequest))
          as FocusLightRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FocusLightRequest create() => FocusLightRequest._();
  @$core.override
  FocusLightRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FocusLightRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FocusLightRequest>(create);
  static FocusLightRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get color => $_getSZ(0);
  @$pb.TagNumber(1)
  set color($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColor() => $_has(0);
  @$pb.TagNumber(1)
  void clearColor() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get intensity => $_getIZ(1);
  @$pb.TagNumber(2)
  set intensity($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIntensity() => $_has(1);
  @$pb.TagNumber(2)
  void clearIntensity() => $_clearField(2);
}

class FocusLightResponse extends $pb.GeneratedMessage {
  factory FocusLightResponse({
    $core.String? color,
    $core.int? intensity,
  }) {
    final result = create();
    if (color != null) result.color = color;
    if (intensity != null) result.intensity = intensity;
    return result;
  }

  FocusLightResponse._();

  factory FocusLightResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FocusLightResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FocusLightResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'color')
    ..aI(2, _omitFieldNames ? '' : 'intensity')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusLightResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusLightResponse copyWith(void Function(FocusLightResponse) updates) =>
      super.copyWith((message) => updates(message as FocusLightResponse))
          as FocusLightResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FocusLightResponse create() => FocusLightResponse._();
  @$core.override
  FocusLightResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FocusLightResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FocusLightResponse>(create);
  static FocusLightResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get color => $_getSZ(0);
  @$pb.TagNumber(1)
  set color($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColor() => $_has(0);
  @$pb.TagNumber(1)
  void clearColor() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get intensity => $_getIZ(1);
  @$pb.TagNumber(2)
  set intensity($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIntensity() => $_has(1);
  @$pb.TagNumber(2)
  void clearIntensity() => $_clearField(2);
}

/// The request/response for the expected camera count (0 = derive from the
/// calibration file).
class ExpectedCamerasRequest extends $pb.GeneratedMessage {
  factory ExpectedCamerasRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  ExpectedCamerasRequest._();

  factory ExpectedCamerasRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExpectedCamerasRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExpectedCamerasRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpectedCamerasRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpectedCamerasRequest copyWith(
          void Function(ExpectedCamerasRequest) updates) =>
      super.copyWith((message) => updates(message as ExpectedCamerasRequest))
          as ExpectedCamerasRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExpectedCamerasRequest create() => ExpectedCamerasRequest._();
  @$core.override
  ExpectedCamerasRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExpectedCamerasRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExpectedCamerasRequest>(create);
  static ExpectedCamerasRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class ExpectedCamerasResponse extends $pb.GeneratedMessage {
  factory ExpectedCamerasResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  ExpectedCamerasResponse._();

  factory ExpectedCamerasResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExpectedCamerasResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExpectedCamerasResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'settings'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpectedCamerasResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpectedCamerasResponse copyWith(
          void Function(ExpectedCamerasResponse) updates) =>
      super.copyWith((message) => updates(message as ExpectedCamerasResponse))
          as ExpectedCamerasResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExpectedCamerasResponse create() => ExpectedCamerasResponse._();
  @$core.override
  ExpectedCamerasResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExpectedCamerasResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExpectedCamerasResponse>(create);
  static ExpectedCamerasResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
