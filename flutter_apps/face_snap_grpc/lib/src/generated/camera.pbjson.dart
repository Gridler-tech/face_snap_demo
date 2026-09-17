// This is a generated file - do not edit.
//
// Generated from camera.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use loadCameraSettingsResponseDescriptor instead')
const LoadCameraSettingsResponse$json = {
  '1': 'LoadCameraSettingsResponse',
  '2': [
    {'1': 'brightness', '3': 1, '4': 1, '5': 5, '10': 'brightness'},
    {'1': 'contrast', '3': 2, '4': 1, '5': 5, '10': 'contrast'},
    {'1': 'saturation', '3': 3, '4': 1, '5': 5, '10': 'saturation'},
    {'1': 'hue', '3': 4, '4': 1, '5': 5, '10': 'hue'},
    {
      '1': 'white_balance_temperature_auto',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'whiteBalanceTemperatureAuto'
    },
    {'1': 'gamma', '3': 6, '4': 1, '5': 5, '10': 'gamma'},
    {'1': 'gain', '3': 7, '4': 1, '5': 5, '10': 'gain'},
    {
      '1': 'white_balance_temperature',
      '3': 8,
      '4': 1,
      '5': 5,
      '10': 'whiteBalanceTemperature'
    },
    {'1': 'sharpness', '3': 9, '4': 1, '5': 5, '10': 'sharpness'},
    {
      '1': 'backlight_compensation',
      '3': 10,
      '4': 1,
      '5': 5,
      '10': 'backlightCompensation'
    },
    {
      '1': 'exposure_auto_priority',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'exposureAutoPriority'
    },
    {'1': 'pan_absolute', '3': 12, '4': 1, '5': 5, '10': 'panAbsolute'},
    {'1': 'tilt_absolute', '3': 13, '4': 1, '5': 5, '10': 'tiltAbsolute'},
    {'1': 'zoom_absolute', '3': 14, '4': 1, '5': 5, '10': 'zoomAbsolute'},
    {
      '1': 'exposure_absolute',
      '3': 15,
      '4': 1,
      '5': 5,
      '10': 'exposureAbsolute'
    },
    {'1': 'autofocus', '3': 16, '4': 1, '5': 8, '10': 'autofocus'},
    {
      '1': 'unsupported_properties',
      '3': 17,
      '4': 3,
      '5': 9,
      '10': 'unsupportedProperties'
    },
    {
      '1': 'property_ranges',
      '3': 18,
      '4': 3,
      '5': 11,
      '6': '.camera.CameraPropertyRange',
      '10': 'propertyRanges'
    },
    {'1': 'focus_absolute', '3': 19, '4': 1, '5': 5, '10': 'focusAbsolute'},
  ],
};

/// Descriptor for `LoadCameraSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loadCameraSettingsResponseDescriptor = $convert.base64Decode(
    'ChpMb2FkQ2FtZXJhU2V0dGluZ3NSZXNwb25zZRIeCgpicmlnaHRuZXNzGAEgASgFUgpicmlnaH'
    'RuZXNzEhoKCGNvbnRyYXN0GAIgASgFUghjb250cmFzdBIeCgpzYXR1cmF0aW9uGAMgASgFUgpz'
    'YXR1cmF0aW9uEhAKA2h1ZRgEIAEoBVIDaHVlEkMKHndoaXRlX2JhbGFuY2VfdGVtcGVyYXR1cm'
    'VfYXV0bxgFIAEoCFIbd2hpdGVCYWxhbmNlVGVtcGVyYXR1cmVBdXRvEhQKBWdhbW1hGAYgASgF'
    'UgVnYW1tYRISCgRnYWluGAcgASgFUgRnYWluEjoKGXdoaXRlX2JhbGFuY2VfdGVtcGVyYXR1cm'
    'UYCCABKAVSF3doaXRlQmFsYW5jZVRlbXBlcmF0dXJlEhwKCXNoYXJwbmVzcxgJIAEoBVIJc2hh'
    'cnBuZXNzEjUKFmJhY2tsaWdodF9jb21wZW5zYXRpb24YCiABKAVSFWJhY2tsaWdodENvbXBlbn'
    'NhdGlvbhI0ChZleHBvc3VyZV9hdXRvX3ByaW9yaXR5GAsgASgIUhRleHBvc3VyZUF1dG9Qcmlv'
    'cml0eRIhCgxwYW5fYWJzb2x1dGUYDCABKAVSC3BhbkFic29sdXRlEiMKDXRpbHRfYWJzb2x1dG'
    'UYDSABKAVSDHRpbHRBYnNvbHV0ZRIjCg16b29tX2Fic29sdXRlGA4gASgFUgx6b29tQWJzb2x1'
    'dGUSKwoRZXhwb3N1cmVfYWJzb2x1dGUYDyABKAVSEGV4cG9zdXJlQWJzb2x1dGUSHAoJYXV0b2'
    'ZvY3VzGBAgASgIUglhdXRvZm9jdXMSNQoWdW5zdXBwb3J0ZWRfcHJvcGVydGllcxgRIAMoCVIV'
    'dW5zdXBwb3J0ZWRQcm9wZXJ0aWVzEkQKD3Byb3BlcnR5X3JhbmdlcxgSIAMoCzIbLmNhbWVyYS'
    '5DYW1lcmFQcm9wZXJ0eVJhbmdlUg5wcm9wZXJ0eVJhbmdlcxIlCg5mb2N1c19hYnNvbHV0ZRgT'
    'IAEoBVINZm9jdXNBYnNvbHV0ZQ==');

@$core.Deprecated('Use cameraPropertyRangeDescriptor instead')
const CameraPropertyRange$json = {
  '1': 'CameraPropertyRange',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'min', '3': 2, '4': 1, '5': 5, '10': 'min'},
    {'1': 'max', '3': 3, '4': 1, '5': 5, '10': 'max'},
    {'1': 'step', '3': 4, '4': 1, '5': 5, '10': 'step'},
    {'1': 'default_value', '3': 5, '4': 1, '5': 5, '10': 'defaultValue'},
    {'1': 'supported', '3': 6, '4': 1, '5': 8, '10': 'supported'},
  ],
};

/// Descriptor for `CameraPropertyRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraPropertyRangeDescriptor = $convert.base64Decode(
    'ChNDYW1lcmFQcm9wZXJ0eVJhbmdlEhIKBG5hbWUYASABKAlSBG5hbWUSEAoDbWluGAIgASgFUg'
    'NtaW4SEAoDbWF4GAMgASgFUgNtYXgSEgoEc3RlcBgEIAEoBVIEc3RlcBIjCg1kZWZhdWx0X3Zh'
    'bHVlGAUgASgFUgxkZWZhdWx0VmFsdWUSHAoJc3VwcG9ydGVkGAYgASgIUglzdXBwb3J0ZWQ=');

@$core.Deprecated('Use brightnessRequestDescriptor instead')
const BrightnessRequest$json = {
  '1': 'BrightnessRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `BrightnessRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List brightnessRequestDescriptor = $convert
    .base64Decode('ChFCcmlnaHRuZXNzUmVxdWVzdBIUCgV2YWx1ZRgBIAEoBVIFdmFsdWU=');

@$core.Deprecated('Use brightnessResponseDescriptor instead')
const BrightnessResponse$json = {
  '1': 'BrightnessResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `BrightnessResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List brightnessResponseDescriptor =
    $convert.base64Decode(
        'ChJCcmlnaHRuZXNzUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoBVIHbWVzc2FnZQ==');

@$core.Deprecated('Use contrastRequestDescriptor instead')
const ContrastRequest$json = {
  '1': 'ContrastRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `ContrastRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contrastRequestDescriptor = $convert
    .base64Decode('Cg9Db250cmFzdFJlcXVlc3QSFAoFdmFsdWUYASABKAVSBXZhbHVl');

@$core.Deprecated('Use contrastResponseDescriptor instead')
const ContrastResponse$json = {
  '1': 'ContrastResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `ContrastResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contrastResponseDescriptor = $convert.base64Decode(
    'ChBDb250cmFzdFJlc3BvbnNlEhgKB21lc3NhZ2UYASABKAVSB21lc3NhZ2U=');

@$core.Deprecated('Use saturationRequestDescriptor instead')
const SaturationRequest$json = {
  '1': 'SaturationRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `SaturationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saturationRequestDescriptor = $convert
    .base64Decode('ChFTYXR1cmF0aW9uUmVxdWVzdBIUCgV2YWx1ZRgBIAEoBVIFdmFsdWU=');

@$core.Deprecated('Use saturationResponseDescriptor instead')
const SaturationResponse$json = {
  '1': 'SaturationResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `SaturationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saturationResponseDescriptor =
    $convert.base64Decode(
        'ChJTYXR1cmF0aW9uUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoBVIHbWVzc2FnZQ==');

@$core.Deprecated('Use hueRequestDescriptor instead')
const HueRequest$json = {
  '1': 'HueRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `HueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hueRequestDescriptor =
    $convert.base64Decode('CgpIdWVSZXF1ZXN0EhQKBXZhbHVlGAEgASgFUgV2YWx1ZQ==');

@$core.Deprecated('Use hueResponseDescriptor instead')
const HueResponse$json = {
  '1': 'HueResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `HueResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hueResponseDescriptor = $convert
    .base64Decode('CgtIdWVSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgFUgdtZXNzYWdl');

@$core.Deprecated('Use whiteBalanceTemperatureAutoRequestDescriptor instead')
const WhiteBalanceTemperatureAutoRequest$json = {
  '1': 'WhiteBalanceTemperatureAutoRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `WhiteBalanceTemperatureAutoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List whiteBalanceTemperatureAutoRequestDescriptor =
    $convert.base64Decode(
        'CiJXaGl0ZUJhbGFuY2VUZW1wZXJhdHVyZUF1dG9SZXF1ZXN0EhQKBXZhbHVlGAEgASgIUgV2YW'
        'x1ZQ==');

@$core.Deprecated('Use whiteBalanceTemperatureAutoResponseDescriptor instead')
const WhiteBalanceTemperatureAutoResponse$json = {
  '1': 'WhiteBalanceTemperatureAutoResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `WhiteBalanceTemperatureAutoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List whiteBalanceTemperatureAutoResponseDescriptor =
    $convert.base64Decode(
        'CiNXaGl0ZUJhbGFuY2VUZW1wZXJhdHVyZUF1dG9SZXNwb25zZRIYCgdtZXNzYWdlGAEgASgIUg'
        'dtZXNzYWdl');

@$core.Deprecated('Use gammaRequestDescriptor instead')
const GammaRequest$json = {
  '1': 'GammaRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `GammaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gammaRequestDescriptor =
    $convert.base64Decode('CgxHYW1tYVJlcXVlc3QSFAoFdmFsdWUYASABKAVSBXZhbHVl');

@$core.Deprecated('Use gammaResponseDescriptor instead')
const GammaResponse$json = {
  '1': 'GammaResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `GammaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gammaResponseDescriptor = $convert
    .base64Decode('Cg1HYW1tYVJlc3BvbnNlEhgKB21lc3NhZ2UYASABKAVSB21lc3NhZ2U=');

@$core.Deprecated('Use gainRequestDescriptor instead')
const GainRequest$json = {
  '1': 'GainRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `GainRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gainRequestDescriptor =
    $convert.base64Decode('CgtHYWluUmVxdWVzdBIUCgV2YWx1ZRgBIAEoBVIFdmFsdWU=');

@$core.Deprecated('Use gainResponseDescriptor instead')
const GainResponse$json = {
  '1': 'GainResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `GainResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gainResponseDescriptor = $convert
    .base64Decode('CgxHYWluUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoBVIHbWVzc2FnZQ==');

@$core.Deprecated('Use whiteBalanceTemperatureRequestDescriptor instead')
const WhiteBalanceTemperatureRequest$json = {
  '1': 'WhiteBalanceTemperatureRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `WhiteBalanceTemperatureRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List whiteBalanceTemperatureRequestDescriptor =
    $convert.base64Decode(
        'Ch5XaGl0ZUJhbGFuY2VUZW1wZXJhdHVyZVJlcXVlc3QSFAoFdmFsdWUYASABKAVSBXZhbHVl');

@$core.Deprecated('Use whiteBalanceTemperatureResponseDescriptor instead')
const WhiteBalanceTemperatureResponse$json = {
  '1': 'WhiteBalanceTemperatureResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `WhiteBalanceTemperatureResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List whiteBalanceTemperatureResponseDescriptor =
    $convert.base64Decode(
        'Ch9XaGl0ZUJhbGFuY2VUZW1wZXJhdHVyZVJlc3BvbnNlEhgKB21lc3NhZ2UYASABKAVSB21lc3'
        'NhZ2U=');

@$core.Deprecated('Use sharpnessRequestDescriptor instead')
const SharpnessRequest$json = {
  '1': 'SharpnessRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `SharpnessRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sharpnessRequestDescriptor = $convert
    .base64Decode('ChBTaGFycG5lc3NSZXF1ZXN0EhQKBXZhbHVlGAEgASgFUgV2YWx1ZQ==');

@$core.Deprecated('Use sharpnessResponseDescriptor instead')
const SharpnessResponse$json = {
  '1': 'SharpnessResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `SharpnessResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sharpnessResponseDescriptor = $convert.base64Decode(
    'ChFTaGFycG5lc3NSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgFUgdtZXNzYWdl');

@$core.Deprecated('Use backlightCompensationRequestDescriptor instead')
const BacklightCompensationRequest$json = {
  '1': 'BacklightCompensationRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `BacklightCompensationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backlightCompensationRequestDescriptor =
    $convert.base64Decode(
        'ChxCYWNrbGlnaHRDb21wZW5zYXRpb25SZXF1ZXN0EhQKBXZhbHVlGAEgASgFUgV2YWx1ZQ==');

@$core.Deprecated('Use backlightCompensationResponseDescriptor instead')
const BacklightCompensationResponse$json = {
  '1': 'BacklightCompensationResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `BacklightCompensationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backlightCompensationResponseDescriptor =
    $convert.base64Decode(
        'Ch1CYWNrbGlnaHRDb21wZW5zYXRpb25SZXNwb25zZRIYCgdtZXNzYWdlGAEgASgFUgdtZXNzYW'
        'dl');

@$core.Deprecated('Use exposureAutoPriorityRequestDescriptor instead')
const ExposureAutoPriorityRequest$json = {
  '1': 'ExposureAutoPriorityRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `ExposureAutoPriorityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exposureAutoPriorityRequestDescriptor =
    $convert.base64Decode(
        'ChtFeHBvc3VyZUF1dG9Qcmlvcml0eVJlcXVlc3QSFAoFdmFsdWUYASABKAhSBXZhbHVl');

@$core.Deprecated('Use exposureAutoPriorityResponseDescriptor instead')
const ExposureAutoPriorityResponse$json = {
  '1': 'ExposureAutoPriorityResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `ExposureAutoPriorityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exposureAutoPriorityResponseDescriptor =
    $convert.base64Decode(
        'ChxFeHBvc3VyZUF1dG9Qcmlvcml0eVJlc3BvbnNlEhgKB21lc3NhZ2UYASABKAhSB21lc3NhZ2'
        'U=');

@$core.Deprecated('Use panAbsoluteRequestDescriptor instead')
const PanAbsoluteRequest$json = {
  '1': 'PanAbsoluteRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `PanAbsoluteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List panAbsoluteRequestDescriptor = $convert
    .base64Decode('ChJQYW5BYnNvbHV0ZVJlcXVlc3QSFAoFdmFsdWUYASABKAVSBXZhbHVl');

@$core.Deprecated('Use panAbsoluteResponseDescriptor instead')
const PanAbsoluteResponse$json = {
  '1': 'PanAbsoluteResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `PanAbsoluteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List panAbsoluteResponseDescriptor =
    $convert.base64Decode(
        'ChNQYW5BYnNvbHV0ZVJlc3BvbnNlEhgKB21lc3NhZ2UYASABKAVSB21lc3NhZ2U=');

@$core.Deprecated('Use tiltAbsoluteRequestDescriptor instead')
const TiltAbsoluteRequest$json = {
  '1': 'TiltAbsoluteRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `TiltAbsoluteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tiltAbsoluteRequestDescriptor =
    $convert.base64Decode(
        'ChNUaWx0QWJzb2x1dGVSZXF1ZXN0EhQKBXZhbHVlGAEgASgFUgV2YWx1ZQ==');

@$core.Deprecated('Use tiltAbsoluteResponseDescriptor instead')
const TiltAbsoluteResponse$json = {
  '1': 'TiltAbsoluteResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `TiltAbsoluteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tiltAbsoluteResponseDescriptor =
    $convert.base64Decode(
        'ChRUaWx0QWJzb2x1dGVSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgFUgdtZXNzYWdl');

@$core.Deprecated('Use zoomAbsoluteRequestDescriptor instead')
const ZoomAbsoluteRequest$json = {
  '1': 'ZoomAbsoluteRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `ZoomAbsoluteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List zoomAbsoluteRequestDescriptor =
    $convert.base64Decode(
        'ChNab29tQWJzb2x1dGVSZXF1ZXN0EhQKBXZhbHVlGAEgASgFUgV2YWx1ZQ==');

@$core.Deprecated('Use zoomAbsoluteResponseDescriptor instead')
const ZoomAbsoluteResponse$json = {
  '1': 'ZoomAbsoluteResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `ZoomAbsoluteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List zoomAbsoluteResponseDescriptor =
    $convert.base64Decode(
        'ChRab29tQWJzb2x1dGVSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgFUgdtZXNzYWdl');

@$core.Deprecated('Use exposureAbsoluteRequestDescriptor instead')
const ExposureAbsoluteRequest$json = {
  '1': 'ExposureAbsoluteRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `ExposureAbsoluteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exposureAbsoluteRequestDescriptor =
    $convert.base64Decode(
        'ChdFeHBvc3VyZUFic29sdXRlUmVxdWVzdBIUCgV2YWx1ZRgBIAEoBVIFdmFsdWU=');

@$core.Deprecated('Use exposureAbsoluteResponseDescriptor instead')
const ExposureAbsoluteResponse$json = {
  '1': 'ExposureAbsoluteResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `ExposureAbsoluteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exposureAbsoluteResponseDescriptor =
    $convert.base64Decode(
        'ChhFeHBvc3VyZUFic29sdXRlUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoBVIHbWVzc2FnZQ==');

@$core.Deprecated('Use autofocusRequestDescriptor instead')
const AutofocusRequest$json = {
  '1': 'AutofocusRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `AutofocusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List autofocusRequestDescriptor = $convert
    .base64Decode('ChBBdXRvZm9jdXNSZXF1ZXN0EhQKBXZhbHVlGAEgASgIUgV2YWx1ZQ==');

@$core.Deprecated('Use autofocusResponseDescriptor instead')
const AutofocusResponse$json = {
  '1': 'AutofocusResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `AutofocusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List autofocusResponseDescriptor = $convert.base64Decode(
    'ChFBdXRvZm9jdXNSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgIUgdtZXNzYWdl');

@$core.Deprecated('Use focusAbsoluteRequestDescriptor instead')
const FocusAbsoluteRequest$json = {
  '1': 'FocusAbsoluteRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `FocusAbsoluteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List focusAbsoluteRequestDescriptor =
    $convert.base64Decode(
        'ChRGb2N1c0Fic29sdXRlUmVxdWVzdBIUCgV2YWx1ZRgBIAEoBVIFdmFsdWU=');

@$core.Deprecated('Use focusAbsoluteResponseDescriptor instead')
const FocusAbsoluteResponse$json = {
  '1': 'FocusAbsoluteResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `FocusAbsoluteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List focusAbsoluteResponseDescriptor =
    $convert.base64Decode(
        'ChVGb2N1c0Fic29sdXRlUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoBVIHbWVzc2FnZQ==');

@$core.Deprecated('Use calibrateFocusRequestDescriptor instead')
const CalibrateFocusRequest$json = {
  '1': 'CalibrateFocusRequest',
  '2': [
    {'1': 'camera_index', '3': 1, '4': 1, '5': 5, '10': 'cameraIndex'},
  ],
};

/// Descriptor for `CalibrateFocusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calibrateFocusRequestDescriptor = $convert.base64Decode(
    'ChVDYWxpYnJhdGVGb2N1c1JlcXVlc3QSIQoMY2FtZXJhX2luZGV4GAEgASgFUgtjYW1lcmFJbm'
    'RleA==');

@$core.Deprecated('Use calibrateFocusResponseDescriptor instead')
const CalibrateFocusResponse$json = {
  '1': 'CalibrateFocusResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `CalibrateFocusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calibrateFocusResponseDescriptor =
    $convert.base64Decode(
        'ChZDYWxpYnJhdGVGb2N1c1Jlc3BvbnNlEhgKB21lc3NhZ2UYASABKAVSB21lc3NhZ2U=');
