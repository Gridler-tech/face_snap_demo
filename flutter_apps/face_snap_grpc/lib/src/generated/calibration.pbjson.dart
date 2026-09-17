// This is a generated file - do not edit.
//
// Generated from calibration.proto.

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

@$core.Deprecated('Use calibrateTypeDescriptor instead')
const CalibrateType$json = {
  '1': 'CalibrateType',
  '2': [
    {'1': 'id_model_id', '3': 1, '4': 1, '5': 9, '10': 'idModelId'},
    {
      '1': 'linux_camera_index',
      '3': 2,
      '4': 1,
      '5': 5,
      '10': 'linuxCameraIndex'
    },
    {
      '1': 'calibrated_camera_index',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'calibratedCameraIndex'
    },
  ],
};

/// Descriptor for `CalibrateType`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calibrateTypeDescriptor = $convert.base64Decode(
    'Cg1DYWxpYnJhdGVUeXBlEh4KC2lkX21vZGVsX2lkGAEgASgJUglpZE1vZGVsSWQSLAoSbGludX'
    'hfY2FtZXJhX2luZGV4GAIgASgFUhBsaW51eENhbWVyYUluZGV4EjYKF2NhbGlicmF0ZWRfY2Ft'
    'ZXJhX2luZGV4GAMgASgFUhVjYWxpYnJhdGVkQ2FtZXJhSW5kZXg=');

@$core.Deprecated('Use calibrationSettingsResponseDescriptor instead')
const CalibrationSettingsResponse$json = {
  '1': 'CalibrationSettingsResponse',
  '2': [
    {
      '1': 'calibrate',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.calibration.CalibrateType',
      '10': 'calibrate'
    },
  ],
};

/// Descriptor for `CalibrationSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calibrationSettingsResponseDescriptor =
    $convert.base64Decode(
        'ChtDYWxpYnJhdGlvblNldHRpbmdzUmVzcG9uc2USOAoJY2FsaWJyYXRlGAEgAygLMhouY2FsaW'
        'JyYXRpb24uQ2FsaWJyYXRlVHlwZVIJY2FsaWJyYXRl');

@$core.Deprecated('Use calibrateRequestDescriptor instead')
const CalibrateRequest$json = {
  '1': 'CalibrateRequest',
  '2': [
    {
      '1': 'calibrate',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.calibration.CalibrateType',
      '10': 'calibrate'
    },
  ],
};

/// Descriptor for `CalibrateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calibrateRequestDescriptor = $convert.base64Decode(
    'ChBDYWxpYnJhdGVSZXF1ZXN0EjgKCWNhbGlicmF0ZRgBIAMoCzIaLmNhbGlicmF0aW9uLkNhbG'
    'licmF0ZVR5cGVSCWNhbGlicmF0ZQ==');

@$core.Deprecated('Use calibrateResponseDescriptor instead')
const CalibrateResponse$json = {
  '1': 'CalibrateResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `CalibrateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calibrateResponseDescriptor = $convert.base64Decode(
    'ChFDYWxpYnJhdGVSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2'
    'UYAiABKAlSB21lc3NhZ2U=');
