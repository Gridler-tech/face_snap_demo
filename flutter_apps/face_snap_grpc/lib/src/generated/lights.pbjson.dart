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
