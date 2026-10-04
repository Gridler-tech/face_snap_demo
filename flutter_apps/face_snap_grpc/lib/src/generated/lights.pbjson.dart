// This is a generated file - do not edit.
//
// Generated from lights.proto.

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

@$core.Deprecated('Use backlightDescriptor instead')
const Backlight$json = {
  '1': 'Backlight',
  '2': [
    {'1': 'BACKLIGHT_UNSPECIFIED', '2': 0},
    {'1': 'BACKLIGHT_BOTTOM', '2': 1},
    {'1': 'BACKLIGHT_TOP', '2': 2},
  ],
};

/// Descriptor for `Backlight`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List backlightDescriptor = $convert.base64Decode(
    'CglCYWNrbGlnaHQSGQoVQkFDS0xJR0hUX1VOU1BFQ0lGSUVEEAASFAoQQkFDS0xJR0hUX0JPVF'
    'RPTRABEhEKDUJBQ0tMSUdIVF9UT1AQAg==');

@$core.Deprecated('Use autoTuneUpdateDescriptor instead')
const AutoTuneUpdate$json = {
  '1': 'AutoTuneUpdate',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
    {'1': 'red', '3': 2, '4': 1, '5': 5, '10': 'red'},
    {'1': 'green', '3': 3, '4': 1, '5': 5, '10': 'green'},
    {'1': 'blue', '3': 4, '4': 1, '5': 5, '10': 'blue'},
    {'1': 'strip_lux', '3': 5, '4': 1, '5': 2, '10': 'stripLux'},
    {'1': 'distance', '3': 6, '4': 1, '5': 2, '10': 'distance'},
    {'1': 'done', '3': 7, '4': 1, '5': 8, '10': 'done'},
    {'1': 'success', '3': 8, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 9, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `AutoTuneUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List autoTuneUpdateDescriptor = $convert.base64Decode(
    'Cg5BdXRvVHVuZVVwZGF0ZRIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdlEhAKA3JlZBgCIAEoBV'
    'IDcmVkEhQKBWdyZWVuGAMgASgFUgVncmVlbhISCgRibHVlGAQgASgFUgRibHVlEhsKCXN0cmlw'
    'X2x1eBgFIAEoAlIIc3RyaXBMdXgSGgoIZGlzdGFuY2UYBiABKAJSCGRpc3RhbmNlEhIKBGRvbm'
    'UYByABKAhSBGRvbmUSGAoHc3VjY2VzcxgIIAEoCFIHc3VjY2VzcxIUCgVlcnJvchgJIAEoCVIF'
    'ZXJyb3I=');

@$core.Deprecated('Use allLightsRequestDescriptor instead')
const AllLightsRequest$json = {
  '1': 'AllLightsRequest',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 8, '10': 'status'},
  ],
};

/// Descriptor for `AllLightsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List allLightsRequestDescriptor = $convert
    .base64Decode('ChBBbGxMaWdodHNSZXF1ZXN0EhYKBnN0YXR1cxgBIAEoCFIGc3RhdHVz');

@$core.Deprecated('Use lightIndexRequestDescriptor instead')
const LightIndexRequest$json = {
  '1': 'LightIndexRequest',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
  ],
};

/// Descriptor for `LightIndexRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lightIndexRequestDescriptor = $convert
    .base64Decode('ChFMaWdodEluZGV4UmVxdWVzdBIUCgVpbmRleBgBIAEoBVIFaW5kZXg=');

@$core.Deprecated('Use backlightRequestDescriptor instead')
const BacklightRequest$json = {
  '1': 'BacklightRequest',
  '2': [
    {
      '1': 'backlight',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.lights.Backlight',
      '10': 'backlight'
    },
    {'1': 'on', '3': 2, '4': 1, '5': 8, '10': 'on'},
  ],
};

/// Descriptor for `BacklightRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backlightRequestDescriptor = $convert.base64Decode(
    'ChBCYWNrbGlnaHRSZXF1ZXN0Ei8KCWJhY2tsaWdodBgBIAEoDjIRLmxpZ2h0cy5CYWNrbGlnaH'
    'RSCWJhY2tsaWdodBIOCgJvbhgCIAEoCFICb24=');

@$core.Deprecated('Use backlightStatusDescriptor instead')
const BacklightStatus$json = {
  '1': 'BacklightStatus',
  '2': [
    {'1': 'connected', '3': 1, '4': 1, '5': 8, '10': 'connected'},
    {'1': 'backlight_bottom', '3': 2, '4': 1, '5': 8, '10': 'backlightBottom'},
    {'1': 'backlight_top', '3': 3, '4': 1, '5': 8, '10': 'backlightTop'},
  ],
};

/// Descriptor for `BacklightStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backlightStatusDescriptor = $convert.base64Decode(
    'Cg9CYWNrbGlnaHRTdGF0dXMSHAoJY29ubmVjdGVkGAEgASgIUgljb25uZWN0ZWQSKQoQYmFja2'
    'xpZ2h0X2JvdHRvbRgCIAEoCFIPYmFja2xpZ2h0Qm90dG9tEiMKDWJhY2tsaWdodF90b3AYAyAB'
    'KAhSDGJhY2tsaWdodFRvcA==');
