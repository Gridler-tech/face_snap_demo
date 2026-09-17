// This is a generated file - do not edit.
//
// Generated from camera.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// The response message containing the camera settings.
class LoadCameraSettingsResponse extends $pb.GeneratedMessage {
  factory LoadCameraSettingsResponse({
    $core.int? brightness,
    $core.int? contrast,
    $core.int? saturation,
    $core.int? hue,
    $core.bool? whiteBalanceTemperatureAuto,
    $core.int? gamma,
    $core.int? gain,
    $core.int? whiteBalanceTemperature,
    $core.int? sharpness,
    $core.int? backlightCompensation,
    $core.bool? exposureAutoPriority,
    $core.int? panAbsolute,
    $core.int? tiltAbsolute,
    $core.int? zoomAbsolute,
    $core.int? exposureAbsolute,
    $core.bool? autofocus,
    $core.Iterable<$core.String>? unsupportedProperties,
    $core.Iterable<CameraPropertyRange>? propertyRanges,
    $core.int? focusAbsolute,
  }) {
    final result = create();
    if (brightness != null) result.brightness = brightness;
    if (contrast != null) result.contrast = contrast;
    if (saturation != null) result.saturation = saturation;
    if (hue != null) result.hue = hue;
    if (whiteBalanceTemperatureAuto != null)
      result.whiteBalanceTemperatureAuto = whiteBalanceTemperatureAuto;
    if (gamma != null) result.gamma = gamma;
    if (gain != null) result.gain = gain;
    if (whiteBalanceTemperature != null)
      result.whiteBalanceTemperature = whiteBalanceTemperature;
    if (sharpness != null) result.sharpness = sharpness;
    if (backlightCompensation != null)
      result.backlightCompensation = backlightCompensation;
    if (exposureAutoPriority != null)
      result.exposureAutoPriority = exposureAutoPriority;
    if (panAbsolute != null) result.panAbsolute = panAbsolute;
    if (tiltAbsolute != null) result.tiltAbsolute = tiltAbsolute;
    if (zoomAbsolute != null) result.zoomAbsolute = zoomAbsolute;
    if (exposureAbsolute != null) result.exposureAbsolute = exposureAbsolute;
    if (autofocus != null) result.autofocus = autofocus;
    if (unsupportedProperties != null)
      result.unsupportedProperties.addAll(unsupportedProperties);
    if (propertyRanges != null) result.propertyRanges.addAll(propertyRanges);
    if (focusAbsolute != null) result.focusAbsolute = focusAbsolute;
    return result;
  }

  LoadCameraSettingsResponse._();

  factory LoadCameraSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoadCameraSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoadCameraSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'brightness')
    ..aI(2, _omitFieldNames ? '' : 'contrast')
    ..aI(3, _omitFieldNames ? '' : 'saturation')
    ..aI(4, _omitFieldNames ? '' : 'hue')
    ..aOB(5, _omitFieldNames ? '' : 'whiteBalanceTemperatureAuto')
    ..aI(6, _omitFieldNames ? '' : 'gamma')
    ..aI(7, _omitFieldNames ? '' : 'gain')
    ..aI(8, _omitFieldNames ? '' : 'whiteBalanceTemperature')
    ..aI(9, _omitFieldNames ? '' : 'sharpness')
    ..aI(10, _omitFieldNames ? '' : 'backlightCompensation')
    ..aOB(11, _omitFieldNames ? '' : 'exposureAutoPriority')
    ..aI(12, _omitFieldNames ? '' : 'panAbsolute')
    ..aI(13, _omitFieldNames ? '' : 'tiltAbsolute')
    ..aI(14, _omitFieldNames ? '' : 'zoomAbsolute')
    ..aI(15, _omitFieldNames ? '' : 'exposureAbsolute')
    ..aOB(16, _omitFieldNames ? '' : 'autofocus')
    ..pPS(17, _omitFieldNames ? '' : 'unsupportedProperties')
    ..pPM<CameraPropertyRange>(18, _omitFieldNames ? '' : 'propertyRanges',
        subBuilder: CameraPropertyRange.create)
    ..aI(19, _omitFieldNames ? '' : 'focusAbsolute')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadCameraSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadCameraSettingsResponse copyWith(
          void Function(LoadCameraSettingsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as LoadCameraSettingsResponse))
          as LoadCameraSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoadCameraSettingsResponse create() => LoadCameraSettingsResponse._();
  @$core.override
  LoadCameraSettingsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoadCameraSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoadCameraSettingsResponse>(create);
  static LoadCameraSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get brightness => $_getIZ(0);
  @$pb.TagNumber(1)
  set brightness($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBrightness() => $_has(0);
  @$pb.TagNumber(1)
  void clearBrightness() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get contrast => $_getIZ(1);
  @$pb.TagNumber(2)
  set contrast($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContrast() => $_has(1);
  @$pb.TagNumber(2)
  void clearContrast() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get saturation => $_getIZ(2);
  @$pb.TagNumber(3)
  set saturation($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSaturation() => $_has(2);
  @$pb.TagNumber(3)
  void clearSaturation() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get hue => $_getIZ(3);
  @$pb.TagNumber(4)
  set hue($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHue() => $_has(3);
  @$pb.TagNumber(4)
  void clearHue() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get whiteBalanceTemperatureAuto => $_getBF(4);
  @$pb.TagNumber(5)
  set whiteBalanceTemperatureAuto($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWhiteBalanceTemperatureAuto() => $_has(4);
  @$pb.TagNumber(5)
  void clearWhiteBalanceTemperatureAuto() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get gamma => $_getIZ(5);
  @$pb.TagNumber(6)
  set gamma($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGamma() => $_has(5);
  @$pb.TagNumber(6)
  void clearGamma() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get gain => $_getIZ(6);
  @$pb.TagNumber(7)
  set gain($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasGain() => $_has(6);
  @$pb.TagNumber(7)
  void clearGain() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get whiteBalanceTemperature => $_getIZ(7);
  @$pb.TagNumber(8)
  set whiteBalanceTemperature($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWhiteBalanceTemperature() => $_has(7);
  @$pb.TagNumber(8)
  void clearWhiteBalanceTemperature() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get sharpness => $_getIZ(8);
  @$pb.TagNumber(9)
  set sharpness($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSharpness() => $_has(8);
  @$pb.TagNumber(9)
  void clearSharpness() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get backlightCompensation => $_getIZ(9);
  @$pb.TagNumber(10)
  set backlightCompensation($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasBacklightCompensation() => $_has(9);
  @$pb.TagNumber(10)
  void clearBacklightCompensation() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get exposureAutoPriority => $_getBF(10);
  @$pb.TagNumber(11)
  set exposureAutoPriority($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasExposureAutoPriority() => $_has(10);
  @$pb.TagNumber(11)
  void clearExposureAutoPriority() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get panAbsolute => $_getIZ(11);
  @$pb.TagNumber(12)
  set panAbsolute($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPanAbsolute() => $_has(11);
  @$pb.TagNumber(12)
  void clearPanAbsolute() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get tiltAbsolute => $_getIZ(12);
  @$pb.TagNumber(13)
  set tiltAbsolute($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTiltAbsolute() => $_has(12);
  @$pb.TagNumber(13)
  void clearTiltAbsolute() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get zoomAbsolute => $_getIZ(13);
  @$pb.TagNumber(14)
  set zoomAbsolute($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasZoomAbsolute() => $_has(13);
  @$pb.TagNumber(14)
  void clearZoomAbsolute() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.int get exposureAbsolute => $_getIZ(14);
  @$pb.TagNumber(15)
  set exposureAbsolute($core.int value) => $_setSignedInt32(14, value);
  @$pb.TagNumber(15)
  $core.bool hasExposureAbsolute() => $_has(14);
  @$pb.TagNumber(15)
  void clearExposureAbsolute() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get autofocus => $_getBF(15);
  @$pb.TagNumber(16)
  set autofocus($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasAutofocus() => $_has(15);
  @$pb.TagNumber(16)
  void clearAutofocus() => $_clearField(16);

  /// Setting names the camera/back-end does not support (read back as unsupported),
  /// so the client can hide the controls that would silently do nothing.
  @$pb.TagNumber(17)
  $pb.PbList<$core.String> get unsupportedProperties => $_getList(16);

  /// Per-property capability + limits probed from the actual camera at runtime, so the
  /// client can size each slider (min/max/step) to what this camera really accepts
  /// instead of hard-coded ranges. Properties not listed here fall back to client
  /// defaults. A range with supported=false means the camera has no such control.
  @$pb.TagNumber(18)
  $pb.PbList<CameraPropertyRange> get propertyRanges => $_getList(17);

  /// Manual focus position, applied only when autofocus is off (fixed focus gives
  /// repeatable sharpness at the kiosk's fixed subject distance).
  @$pb.TagNumber(19)
  $core.int get focusAbsolute => $_getIZ(18);
  @$pb.TagNumber(19)
  set focusAbsolute($core.int value) => $_setSignedInt32(18, value);
  @$pb.TagNumber(19)
  $core.bool hasFocusAbsolute() => $_has(18);
  @$pb.TagNumber(19)
  void clearFocusAbsolute() => $_clearField(19);
}

/// Capability and limits of a single camera property, probed at runtime.
class CameraPropertyRange extends $pb.GeneratedMessage {
  factory CameraPropertyRange({
    $core.String? name,
    $core.int? min,
    $core.int? max,
    $core.int? step,
    $core.int? defaultValue,
    $core.bool? supported,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (min != null) result.min = min;
    if (max != null) result.max = max;
    if (step != null) result.step = step;
    if (defaultValue != null) result.defaultValue = defaultValue;
    if (supported != null) result.supported = supported;
    return result;
  }

  CameraPropertyRange._();

  factory CameraPropertyRange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CameraPropertyRange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CameraPropertyRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aI(2, _omitFieldNames ? '' : 'min')
    ..aI(3, _omitFieldNames ? '' : 'max')
    ..aI(4, _omitFieldNames ? '' : 'step')
    ..aI(5, _omitFieldNames ? '' : 'defaultValue')
    ..aOB(6, _omitFieldNames ? '' : 'supported')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraPropertyRange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraPropertyRange copyWith(void Function(CameraPropertyRange) updates) =>
      super.copyWith((message) => updates(message as CameraPropertyRange))
          as CameraPropertyRange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CameraPropertyRange create() => CameraPropertyRange._();
  @$core.override
  CameraPropertyRange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CameraPropertyRange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CameraPropertyRange>(create);
  static CameraPropertyRange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get min => $_getIZ(1);
  @$pb.TagNumber(2)
  set min($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMin() => $_has(1);
  @$pb.TagNumber(2)
  void clearMin() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get max => $_getIZ(2);
  @$pb.TagNumber(3)
  set max($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMax() => $_has(2);
  @$pb.TagNumber(3)
  void clearMax() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get step => $_getIZ(3);
  @$pb.TagNumber(4)
  set step($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStep() => $_has(3);
  @$pb.TagNumber(4)
  void clearStep() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get defaultValue => $_getIZ(4);
  @$pb.TagNumber(5)
  set defaultValue($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDefaultValue() => $_has(4);
  @$pb.TagNumber(5)
  void clearDefaultValue() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get supported => $_getBF(5);
  @$pb.TagNumber(6)
  set supported($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSupported() => $_has(5);
  @$pb.TagNumber(6)
  void clearSupported() => $_clearField(6);
}

/// The request message containing the brightness.
class BrightnessRequest extends $pb.GeneratedMessage {
  factory BrightnessRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  BrightnessRequest._();

  factory BrightnessRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BrightnessRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BrightnessRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BrightnessRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BrightnessRequest copyWith(void Function(BrightnessRequest) updates) =>
      super.copyWith((message) => updates(message as BrightnessRequest))
          as BrightnessRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BrightnessRequest create() => BrightnessRequest._();
  @$core.override
  BrightnessRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BrightnessRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BrightnessRequest>(create);
  static BrightnessRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the brightness.
class BrightnessResponse extends $pb.GeneratedMessage {
  factory BrightnessResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  BrightnessResponse._();

  factory BrightnessResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BrightnessResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BrightnessResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BrightnessResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BrightnessResponse copyWith(void Function(BrightnessResponse) updates) =>
      super.copyWith((message) => updates(message as BrightnessResponse))
          as BrightnessResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BrightnessResponse create() => BrightnessResponse._();
  @$core.override
  BrightnessResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BrightnessResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BrightnessResponse>(create);
  static BrightnessResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the contrast.
class ContrastRequest extends $pb.GeneratedMessage {
  factory ContrastRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  ContrastRequest._();

  factory ContrastRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContrastRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContrastRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContrastRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContrastRequest copyWith(void Function(ContrastRequest) updates) =>
      super.copyWith((message) => updates(message as ContrastRequest))
          as ContrastRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContrastRequest create() => ContrastRequest._();
  @$core.override
  ContrastRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContrastRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContrastRequest>(create);
  static ContrastRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the contrast.
class ContrastResponse extends $pb.GeneratedMessage {
  factory ContrastResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  ContrastResponse._();

  factory ContrastResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContrastResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContrastResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContrastResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContrastResponse copyWith(void Function(ContrastResponse) updates) =>
      super.copyWith((message) => updates(message as ContrastResponse))
          as ContrastResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContrastResponse create() => ContrastResponse._();
  @$core.override
  ContrastResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContrastResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContrastResponse>(create);
  static ContrastResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the saturation.
class SaturationRequest extends $pb.GeneratedMessage {
  factory SaturationRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  SaturationRequest._();

  factory SaturationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaturationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaturationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaturationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaturationRequest copyWith(void Function(SaturationRequest) updates) =>
      super.copyWith((message) => updates(message as SaturationRequest))
          as SaturationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaturationRequest create() => SaturationRequest._();
  @$core.override
  SaturationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaturationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaturationRequest>(create);
  static SaturationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the saturation.
class SaturationResponse extends $pb.GeneratedMessage {
  factory SaturationResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  SaturationResponse._();

  factory SaturationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaturationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaturationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaturationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaturationResponse copyWith(void Function(SaturationResponse) updates) =>
      super.copyWith((message) => updates(message as SaturationResponse))
          as SaturationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaturationResponse create() => SaturationResponse._();
  @$core.override
  SaturationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaturationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaturationResponse>(create);
  static SaturationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the hue.
class HueRequest extends $pb.GeneratedMessage {
  factory HueRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  HueRequest._();

  factory HueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HueRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HueRequest copyWith(void Function(HueRequest) updates) =>
      super.copyWith((message) => updates(message as HueRequest)) as HueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HueRequest create() => HueRequest._();
  @$core.override
  HueRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HueRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HueRequest>(create);
  static HueRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the hue.
class HueResponse extends $pb.GeneratedMessage {
  factory HueResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  HueResponse._();

  factory HueResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HueResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HueResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HueResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HueResponse copyWith(void Function(HueResponse) updates) =>
      super.copyWith((message) => updates(message as HueResponse))
          as HueResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HueResponse create() => HueResponse._();
  @$core.override
  HueResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HueResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HueResponse>(create);
  static HueResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the white balance temperature auto.
class WhiteBalanceTemperatureAutoRequest extends $pb.GeneratedMessage {
  factory WhiteBalanceTemperatureAutoRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  WhiteBalanceTemperatureAutoRequest._();

  factory WhiteBalanceTemperatureAutoRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WhiteBalanceTemperatureAutoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WhiteBalanceTemperatureAutoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhiteBalanceTemperatureAutoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhiteBalanceTemperatureAutoRequest copyWith(
          void Function(WhiteBalanceTemperatureAutoRequest) updates) =>
      super.copyWith((message) =>
              updates(message as WhiteBalanceTemperatureAutoRequest))
          as WhiteBalanceTemperatureAutoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WhiteBalanceTemperatureAutoRequest create() =>
      WhiteBalanceTemperatureAutoRequest._();
  @$core.override
  WhiteBalanceTemperatureAutoRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WhiteBalanceTemperatureAutoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WhiteBalanceTemperatureAutoRequest>(
          create);
  static WhiteBalanceTemperatureAutoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the white balance temperature auto.
class WhiteBalanceTemperatureAutoResponse extends $pb.GeneratedMessage {
  factory WhiteBalanceTemperatureAutoResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  WhiteBalanceTemperatureAutoResponse._();

  factory WhiteBalanceTemperatureAutoResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WhiteBalanceTemperatureAutoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WhiteBalanceTemperatureAutoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhiteBalanceTemperatureAutoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhiteBalanceTemperatureAutoResponse copyWith(
          void Function(WhiteBalanceTemperatureAutoResponse) updates) =>
      super.copyWith((message) =>
              updates(message as WhiteBalanceTemperatureAutoResponse))
          as WhiteBalanceTemperatureAutoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WhiteBalanceTemperatureAutoResponse create() =>
      WhiteBalanceTemperatureAutoResponse._();
  @$core.override
  WhiteBalanceTemperatureAutoResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WhiteBalanceTemperatureAutoResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          WhiteBalanceTemperatureAutoResponse>(create);
  static WhiteBalanceTemperatureAutoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the gamma.
class GammaRequest extends $pb.GeneratedMessage {
  factory GammaRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  GammaRequest._();

  factory GammaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GammaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GammaRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GammaRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GammaRequest copyWith(void Function(GammaRequest) updates) =>
      super.copyWith((message) => updates(message as GammaRequest))
          as GammaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GammaRequest create() => GammaRequest._();
  @$core.override
  GammaRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GammaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GammaRequest>(create);
  static GammaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the gamma.
class GammaResponse extends $pb.GeneratedMessage {
  factory GammaResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  GammaResponse._();

  factory GammaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GammaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GammaResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GammaResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GammaResponse copyWith(void Function(GammaResponse) updates) =>
      super.copyWith((message) => updates(message as GammaResponse))
          as GammaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GammaResponse create() => GammaResponse._();
  @$core.override
  GammaResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GammaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GammaResponse>(create);
  static GammaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the gain.
class GainRequest extends $pb.GeneratedMessage {
  factory GainRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  GainRequest._();

  factory GainRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GainRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GainRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GainRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GainRequest copyWith(void Function(GainRequest) updates) =>
      super.copyWith((message) => updates(message as GainRequest))
          as GainRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GainRequest create() => GainRequest._();
  @$core.override
  GainRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GainRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GainRequest>(create);
  static GainRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the gain.
class GainResponse extends $pb.GeneratedMessage {
  factory GainResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  GainResponse._();

  factory GainResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GainResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GainResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GainResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GainResponse copyWith(void Function(GainResponse) updates) =>
      super.copyWith((message) => updates(message as GainResponse))
          as GainResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GainResponse create() => GainResponse._();
  @$core.override
  GainResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GainResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GainResponse>(create);
  static GainResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the white balance temperature.
class WhiteBalanceTemperatureRequest extends $pb.GeneratedMessage {
  factory WhiteBalanceTemperatureRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  WhiteBalanceTemperatureRequest._();

  factory WhiteBalanceTemperatureRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WhiteBalanceTemperatureRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WhiteBalanceTemperatureRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhiteBalanceTemperatureRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhiteBalanceTemperatureRequest copyWith(
          void Function(WhiteBalanceTemperatureRequest) updates) =>
      super.copyWith(
              (message) => updates(message as WhiteBalanceTemperatureRequest))
          as WhiteBalanceTemperatureRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WhiteBalanceTemperatureRequest create() =>
      WhiteBalanceTemperatureRequest._();
  @$core.override
  WhiteBalanceTemperatureRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WhiteBalanceTemperatureRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WhiteBalanceTemperatureRequest>(create);
  static WhiteBalanceTemperatureRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the white balance temperature.
class WhiteBalanceTemperatureResponse extends $pb.GeneratedMessage {
  factory WhiteBalanceTemperatureResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  WhiteBalanceTemperatureResponse._();

  factory WhiteBalanceTemperatureResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WhiteBalanceTemperatureResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WhiteBalanceTemperatureResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhiteBalanceTemperatureResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhiteBalanceTemperatureResponse copyWith(
          void Function(WhiteBalanceTemperatureResponse) updates) =>
      super.copyWith(
              (message) => updates(message as WhiteBalanceTemperatureResponse))
          as WhiteBalanceTemperatureResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WhiteBalanceTemperatureResponse create() =>
      WhiteBalanceTemperatureResponse._();
  @$core.override
  WhiteBalanceTemperatureResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WhiteBalanceTemperatureResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WhiteBalanceTemperatureResponse>(
          create);
  static WhiteBalanceTemperatureResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the sharpness.
class SharpnessRequest extends $pb.GeneratedMessage {
  factory SharpnessRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  SharpnessRequest._();

  factory SharpnessRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SharpnessRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SharpnessRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharpnessRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharpnessRequest copyWith(void Function(SharpnessRequest) updates) =>
      super.copyWith((message) => updates(message as SharpnessRequest))
          as SharpnessRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SharpnessRequest create() => SharpnessRequest._();
  @$core.override
  SharpnessRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SharpnessRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SharpnessRequest>(create);
  static SharpnessRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the sharpness.
class SharpnessResponse extends $pb.GeneratedMessage {
  factory SharpnessResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  SharpnessResponse._();

  factory SharpnessResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SharpnessResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SharpnessResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharpnessResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharpnessResponse copyWith(void Function(SharpnessResponse) updates) =>
      super.copyWith((message) => updates(message as SharpnessResponse))
          as SharpnessResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SharpnessResponse create() => SharpnessResponse._();
  @$core.override
  SharpnessResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SharpnessResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SharpnessResponse>(create);
  static SharpnessResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the backlight compensation.
class BacklightCompensationRequest extends $pb.GeneratedMessage {
  factory BacklightCompensationRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  BacklightCompensationRequest._();

  factory BacklightCompensationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BacklightCompensationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BacklightCompensationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacklightCompensationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacklightCompensationRequest copyWith(
          void Function(BacklightCompensationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as BacklightCompensationRequest))
          as BacklightCompensationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BacklightCompensationRequest create() =>
      BacklightCompensationRequest._();
  @$core.override
  BacklightCompensationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BacklightCompensationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BacklightCompensationRequest>(create);
  static BacklightCompensationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the backlight compensation.
class BacklightCompensationResponse extends $pb.GeneratedMessage {
  factory BacklightCompensationResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  BacklightCompensationResponse._();

  factory BacklightCompensationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BacklightCompensationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BacklightCompensationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacklightCompensationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BacklightCompensationResponse copyWith(
          void Function(BacklightCompensationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as BacklightCompensationResponse))
          as BacklightCompensationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BacklightCompensationResponse create() =>
      BacklightCompensationResponse._();
  @$core.override
  BacklightCompensationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BacklightCompensationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BacklightCompensationResponse>(create);
  static BacklightCompensationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the exposure auto priority.
class ExposureAutoPriorityRequest extends $pb.GeneratedMessage {
  factory ExposureAutoPriorityRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  ExposureAutoPriorityRequest._();

  factory ExposureAutoPriorityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExposureAutoPriorityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExposureAutoPriorityRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExposureAutoPriorityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExposureAutoPriorityRequest copyWith(
          void Function(ExposureAutoPriorityRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ExposureAutoPriorityRequest))
          as ExposureAutoPriorityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExposureAutoPriorityRequest create() =>
      ExposureAutoPriorityRequest._();
  @$core.override
  ExposureAutoPriorityRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExposureAutoPriorityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExposureAutoPriorityRequest>(create);
  static ExposureAutoPriorityRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the exposure auto priority.
class ExposureAutoPriorityResponse extends $pb.GeneratedMessage {
  factory ExposureAutoPriorityResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  ExposureAutoPriorityResponse._();

  factory ExposureAutoPriorityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExposureAutoPriorityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExposureAutoPriorityResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExposureAutoPriorityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExposureAutoPriorityResponse copyWith(
          void Function(ExposureAutoPriorityResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ExposureAutoPriorityResponse))
          as ExposureAutoPriorityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExposureAutoPriorityResponse create() =>
      ExposureAutoPriorityResponse._();
  @$core.override
  ExposureAutoPriorityResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExposureAutoPriorityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExposureAutoPriorityResponse>(create);
  static ExposureAutoPriorityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the pan absolute.
class PanAbsoluteRequest extends $pb.GeneratedMessage {
  factory PanAbsoluteRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  PanAbsoluteRequest._();

  factory PanAbsoluteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PanAbsoluteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PanAbsoluteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PanAbsoluteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PanAbsoluteRequest copyWith(void Function(PanAbsoluteRequest) updates) =>
      super.copyWith((message) => updates(message as PanAbsoluteRequest))
          as PanAbsoluteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PanAbsoluteRequest create() => PanAbsoluteRequest._();
  @$core.override
  PanAbsoluteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PanAbsoluteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PanAbsoluteRequest>(create);
  static PanAbsoluteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the pan absolute.
class PanAbsoluteResponse extends $pb.GeneratedMessage {
  factory PanAbsoluteResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  PanAbsoluteResponse._();

  factory PanAbsoluteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PanAbsoluteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PanAbsoluteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PanAbsoluteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PanAbsoluteResponse copyWith(void Function(PanAbsoluteResponse) updates) =>
      super.copyWith((message) => updates(message as PanAbsoluteResponse))
          as PanAbsoluteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PanAbsoluteResponse create() => PanAbsoluteResponse._();
  @$core.override
  PanAbsoluteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PanAbsoluteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PanAbsoluteResponse>(create);
  static PanAbsoluteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the tilt absolute.
class TiltAbsoluteRequest extends $pb.GeneratedMessage {
  factory TiltAbsoluteRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  TiltAbsoluteRequest._();

  factory TiltAbsoluteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TiltAbsoluteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TiltAbsoluteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TiltAbsoluteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TiltAbsoluteRequest copyWith(void Function(TiltAbsoluteRequest) updates) =>
      super.copyWith((message) => updates(message as TiltAbsoluteRequest))
          as TiltAbsoluteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TiltAbsoluteRequest create() => TiltAbsoluteRequest._();
  @$core.override
  TiltAbsoluteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TiltAbsoluteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TiltAbsoluteRequest>(create);
  static TiltAbsoluteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the tilt absolute.
class TiltAbsoluteResponse extends $pb.GeneratedMessage {
  factory TiltAbsoluteResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  TiltAbsoluteResponse._();

  factory TiltAbsoluteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TiltAbsoluteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TiltAbsoluteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TiltAbsoluteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TiltAbsoluteResponse copyWith(void Function(TiltAbsoluteResponse) updates) =>
      super.copyWith((message) => updates(message as TiltAbsoluteResponse))
          as TiltAbsoluteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TiltAbsoluteResponse create() => TiltAbsoluteResponse._();
  @$core.override
  TiltAbsoluteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TiltAbsoluteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TiltAbsoluteResponse>(create);
  static TiltAbsoluteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the zoom absolute.
class ZoomAbsoluteRequest extends $pb.GeneratedMessage {
  factory ZoomAbsoluteRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  ZoomAbsoluteRequest._();

  factory ZoomAbsoluteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ZoomAbsoluteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ZoomAbsoluteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZoomAbsoluteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZoomAbsoluteRequest copyWith(void Function(ZoomAbsoluteRequest) updates) =>
      super.copyWith((message) => updates(message as ZoomAbsoluteRequest))
          as ZoomAbsoluteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ZoomAbsoluteRequest create() => ZoomAbsoluteRequest._();
  @$core.override
  ZoomAbsoluteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ZoomAbsoluteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ZoomAbsoluteRequest>(create);
  static ZoomAbsoluteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the zoom absolute.
class ZoomAbsoluteResponse extends $pb.GeneratedMessage {
  factory ZoomAbsoluteResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  ZoomAbsoluteResponse._();

  factory ZoomAbsoluteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ZoomAbsoluteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ZoomAbsoluteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZoomAbsoluteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZoomAbsoluteResponse copyWith(void Function(ZoomAbsoluteResponse) updates) =>
      super.copyWith((message) => updates(message as ZoomAbsoluteResponse))
          as ZoomAbsoluteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ZoomAbsoluteResponse create() => ZoomAbsoluteResponse._();
  @$core.override
  ZoomAbsoluteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ZoomAbsoluteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ZoomAbsoluteResponse>(create);
  static ZoomAbsoluteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the zoom absolute.
class ExposureAbsoluteRequest extends $pb.GeneratedMessage {
  factory ExposureAbsoluteRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  ExposureAbsoluteRequest._();

  factory ExposureAbsoluteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExposureAbsoluteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExposureAbsoluteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExposureAbsoluteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExposureAbsoluteRequest copyWith(
          void Function(ExposureAbsoluteRequest) updates) =>
      super.copyWith((message) => updates(message as ExposureAbsoluteRequest))
          as ExposureAbsoluteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExposureAbsoluteRequest create() => ExposureAbsoluteRequest._();
  @$core.override
  ExposureAbsoluteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExposureAbsoluteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExposureAbsoluteRequest>(create);
  static ExposureAbsoluteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The request message containing the exposure absolute.
class ExposureAbsoluteResponse extends $pb.GeneratedMessage {
  factory ExposureAbsoluteResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  ExposureAbsoluteResponse._();

  factory ExposureAbsoluteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExposureAbsoluteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExposureAbsoluteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExposureAbsoluteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExposureAbsoluteResponse copyWith(
          void Function(ExposureAbsoluteResponse) updates) =>
      super.copyWith((message) => updates(message as ExposureAbsoluteResponse))
          as ExposureAbsoluteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExposureAbsoluteResponse create() => ExposureAbsoluteResponse._();
  @$core.override
  ExposureAbsoluteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExposureAbsoluteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExposureAbsoluteResponse>(create);
  static ExposureAbsoluteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing autofocus on/off.
class AutofocusRequest extends $pb.GeneratedMessage {
  factory AutofocusRequest({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  AutofocusRequest._();

  factory AutofocusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AutofocusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AutofocusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AutofocusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AutofocusRequest copyWith(void Function(AutofocusRequest) updates) =>
      super.copyWith((message) => updates(message as AutofocusRequest))
          as AutofocusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AutofocusRequest create() => AutofocusRequest._();
  @$core.override
  AutofocusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AutofocusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AutofocusRequest>(create);
  static AutofocusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing autofocus on/off.
class AutofocusResponse extends $pb.GeneratedMessage {
  factory AutofocusResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  AutofocusResponse._();

  factory AutofocusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AutofocusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AutofocusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AutofocusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AutofocusResponse copyWith(void Function(AutofocusResponse) updates) =>
      super.copyWith((message) => updates(message as AutofocusResponse))
          as AutofocusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AutofocusResponse create() => AutofocusResponse._();
  @$core.override
  AutofocusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AutofocusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AutofocusResponse>(create);
  static AutofocusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// The request message containing the manual focus position.
class FocusAbsoluteRequest extends $pb.GeneratedMessage {
  factory FocusAbsoluteRequest({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  FocusAbsoluteRequest._();

  factory FocusAbsoluteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FocusAbsoluteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FocusAbsoluteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusAbsoluteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusAbsoluteRequest copyWith(void Function(FocusAbsoluteRequest) updates) =>
      super.copyWith((message) => updates(message as FocusAbsoluteRequest))
          as FocusAbsoluteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FocusAbsoluteRequest create() => FocusAbsoluteRequest._();
  @$core.override
  FocusAbsoluteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FocusAbsoluteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FocusAbsoluteRequest>(create);
  static FocusAbsoluteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// The response message containing the manual focus position.
class FocusAbsoluteResponse extends $pb.GeneratedMessage {
  factory FocusAbsoluteResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  FocusAbsoluteResponse._();

  factory FocusAbsoluteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FocusAbsoluteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FocusAbsoluteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusAbsoluteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FocusAbsoluteResponse copyWith(
          void Function(FocusAbsoluteResponse) updates) =>
      super.copyWith((message) => updates(message as FocusAbsoluteResponse))
          as FocusAbsoluteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FocusAbsoluteResponse create() => FocusAbsoluteResponse._();
  @$core.override
  FocusAbsoluteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FocusAbsoluteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FocusAbsoluteResponse>(create);
  static FocusAbsoluteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get message => $_getIZ(0);
  @$pb.TagNumber(1)
  set message($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Focus calibration assistant: lights on, autofocus settles on the subject, the locked
/// position is stored as focus_absolute and autofocus is switched back off.
class CalibrateFocusRequest extends $pb.GeneratedMessage {
  factory CalibrateFocusRequest({
    $core.int? cameraIndex,
  }) {
    final result = create();
    if (cameraIndex != null) result.cameraIndex = cameraIndex;
    return result;
  }

  CalibrateFocusRequest._();

  factory CalibrateFocusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CalibrateFocusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CalibrateFocusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'cameraIndex')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateFocusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateFocusRequest copyWith(
          void Function(CalibrateFocusRequest) updates) =>
      super.copyWith((message) => updates(message as CalibrateFocusRequest))
          as CalibrateFocusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CalibrateFocusRequest create() => CalibrateFocusRequest._();
  @$core.override
  CalibrateFocusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CalibrateFocusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CalibrateFocusRequest>(create);
  static CalibrateFocusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get cameraIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set cameraIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCameraIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearCameraIndex() => $_clearField(1);
}

class CalibrateFocusResponse extends $pb.GeneratedMessage {
  factory CalibrateFocusResponse({
    $core.int? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  CalibrateFocusResponse._();

  factory CalibrateFocusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CalibrateFocusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CalibrateFocusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'camera'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateFocusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CalibrateFocusResponse copyWith(
          void Function(CalibrateFocusResponse) updates) =>
      super.copyWith((message) => updates(message as CalibrateFocusResponse))
          as CalibrateFocusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CalibrateFocusResponse create() => CalibrateFocusResponse._();
  @$core.override
  CalibrateFocusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CalibrateFocusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CalibrateFocusResponse>(create);
  static CalibrateFocusResponse? _defaultInstance;

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
