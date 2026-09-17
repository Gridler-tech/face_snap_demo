// This is a generated file - do not edit.
//
// Generated from monitoring.proto.

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

@$core.Deprecated('Use usageTypeDescriptor instead')
const UsageType$json = {
  '1': 'UsageType',
  '2': [
    {'1': 'CPU', '2': 0},
    {'1': 'MEMORY', '2': 1},
    {'1': 'CPU_COUNT', '2': 2},
    {'1': 'NET_IF_ADDRS', '2': 3},
    {'1': 'NET_IO_COUNTERS', '2': 4},
    {'1': 'BOOT_TIME', '2': 5},
  ],
};

/// Descriptor for `UsageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List usageTypeDescriptor = $convert.base64Decode(
    'CglVc2FnZVR5cGUSBwoDQ1BVEAASCgoGTUVNT1JZEAESDQoJQ1BVX0NPVU5UEAISEAoMTkVUX0'
    'lGX0FERFJTEAMSEwoPTkVUX0lPX0NPVU5URVJTEAQSDQoJQk9PVF9USU1FEAU=');

@$core.Deprecated('Use kioskStatusResponseDescriptor instead')
const KioskStatusResponse$json = {
  '1': 'KioskStatusResponse',
  '2': [
    {'1': 'description', '3': 1, '4': 1, '5': 9, '10': 'description'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `KioskStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List kioskStatusResponseDescriptor = $convert.base64Decode(
    'ChNLaW9za1N0YXR1c1Jlc3BvbnNlEiAKC2Rlc2NyaXB0aW9uGAEgASgJUgtkZXNjcmlwdGlvbh'
    'IWCgZzdGF0dXMYAiABKAlSBnN0YXR1cw==');

@$core.Deprecated('Use usageResponseDescriptor instead')
const UsageResponse$json = {
  '1': 'UsageResponse',
  '2': [
    {
      '1': 'usage_type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.monitoring.UsageType',
      '10': 'usageType'
    },
    {'1': 'usage', '3': 2, '4': 1, '5': 9, '10': 'usage'},
  ],
};

/// Descriptor for `UsageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List usageResponseDescriptor = $convert.base64Decode(
    'Cg1Vc2FnZVJlc3BvbnNlEjQKCnVzYWdlX3R5cGUYASABKA4yFS5tb25pdG9yaW5nLlVzYWdlVH'
    'lwZVIJdXNhZ2VUeXBlEhQKBXVzYWdlGAIgASgJUgV1c2FnZQ==');

@$core.Deprecated('Use lightMeasurementResponseDescriptor instead')
const LightMeasurementResponse$json = {
  '1': 'LightMeasurementResponse',
  '2': [
    {'1': 'available', '3': 1, '4': 1, '5': 8, '10': 'available'},
    {'1': 'lux', '3': 2, '4': 1, '5': 2, '10': 'lux'},
    {'1': 'cct', '3': 3, '4': 1, '5': 2, '10': 'cct'},
    {'1': 'cie_x', '3': 4, '4': 1, '5': 2, '10': 'cieX'},
    {'1': 'cie_y', '3': 5, '4': 1, '5': 2, '10': 'cieY'},
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `LightMeasurementResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lightMeasurementResponseDescriptor = $convert.base64Decode(
    'ChhMaWdodE1lYXN1cmVtZW50UmVzcG9uc2USHAoJYXZhaWxhYmxlGAEgASgIUglhdmFpbGFibG'
    'USEAoDbHV4GAIgASgCUgNsdXgSEAoDY2N0GAMgASgCUgNjY3QSEwoFY2llX3gYBCABKAJSBGNp'
    'ZVgSEwoFY2llX3kYBSABKAJSBGNpZVkSFAoFZXJyb3IYBiABKAlSBWVycm9y');
