// This is a generated file - do not edit.
//
// Generated from settings.proto.

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

@$core.Deprecated('Use glareFreeLightDescriptor instead')
const GlareFreeLight$json = {
  '1': 'GlareFreeLight',
  '2': [
    {'1': 'GLARE_FREE_LIGHT_OFF', '2': 0},
    {'1': 'GLARE_FREE_LIGHT_GLASSES', '2': 1},
    {'1': 'GLARE_FREE_LIGHT_EVERYONE', '2': 2},
  ],
};

/// Descriptor for `GlareFreeLight`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List glareFreeLightDescriptor = $convert.base64Decode(
    'Cg5HbGFyZUZyZWVMaWdodBIYChRHTEFSRV9GUkVFX0xJR0hUX09GRhAAEhwKGEdMQVJFX0ZSRU'
    'VfTElHSFRfR0xBU1NFUxABEh0KGUdMQVJFX0ZSRUVfTElHSFRfRVZFUllPTkUQAg==');

@$core.Deprecated('Use columnSaveOutcomeDescriptor instead')
const ColumnSaveOutcome$json = {
  '1': 'ColumnSaveOutcome',
  '2': [
    {'1': 'COLUMN_SAVE_OUTCOME_WRITTEN', '2': 0},
    {'1': 'COLUMN_SAVE_OUTCOME_PENDING', '2': 1},
    {'1': 'COLUMN_SAVE_OUTCOME_NOTHING', '2': 2},
  ],
};

/// Descriptor for `ColumnSaveOutcome`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List columnSaveOutcomeDescriptor = $convert.base64Decode(
    'ChFDb2x1bW5TYXZlT3V0Y29tZRIfChtDT0xVTU5fU0FWRV9PVVRDT01FX1dSSVRURU4QABIfCh'
    'tDT0xVTU5fU0FWRV9PVVRDT01FX1BFTkRJTkcQARIfChtDT0xVTU5fU0FWRV9PVVRDT01FX05P'
    'VEhJTkcQAg==');

@$core.Deprecated('Use columnFactorySourceDescriptor instead')
const ColumnFactorySource$json = {
  '1': 'ColumnFactorySource',
  '2': [
    {'1': 'COLUMN_FACTORY_SOURCE_STANDARD', '2': 0},
    {'1': 'COLUMN_FACTORY_SOURCE_VALUES_IN_FORCE', '2': 1},
  ],
};

/// Descriptor for `ColumnFactorySource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List columnFactorySourceDescriptor = $convert.base64Decode(
    'ChNDb2x1bW5GYWN0b3J5U291cmNlEiIKHkNPTFVNTl9GQUNUT1JZX1NPVVJDRV9TVEFOREFSRB'
    'AAEikKJUNPTFVNTl9GQUNUT1JZX1NPVVJDRV9WQUxVRVNfSU5fRk9SQ0UQAQ==');

@$core.Deprecated('Use cameraResolutionDescriptor instead')
const CameraResolution$json = {
  '1': 'CameraResolution',
  '2': [
    {'1': 'width', '3': 1, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 2, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `CameraResolution`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraResolutionDescriptor = $convert.base64Decode(
    'ChBDYW1lcmFSZXNvbHV0aW9uEhQKBXdpZHRoGAEgASgFUgV3aWR0aBIWCgZoZWlnaHQYAiABKA'
    'VSBmhlaWdodA==');

@$core.Deprecated('Use saveSettingsRequestDescriptor instead')
const SaveSettingsRequest$json = {
  '1': 'SaveSettingsRequest',
  '2': [
    {'1': 'width', '3': 1, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 2, '4': 1, '5': 5, '10': 'height'},
    {'1': 'crop', '3': 3, '4': 1, '5': 8, '10': 'crop'},
    {'1': 'crop_width', '3': 4, '4': 1, '5': 5, '10': 'cropWidth'},
    {'1': 'crop_height', '3': 5, '4': 1, '5': 5, '10': 'cropHeight'},
    {'1': 'eyes_check', '3': 6, '4': 1, '5': 8, '10': 'eyesCheck'},
    {'1': 'lips_check', '3': 7, '4': 1, '5': 8, '10': 'lipsCheck'},
    {'1': 'lighting', '3': 8, '4': 1, '5': 8, '10': 'lighting'},
    {'1': 'intensity_red', '3': 9, '4': 1, '5': 5, '10': 'intensityRed'},
    {'1': 'intensity_green', '3': 10, '4': 1, '5': 5, '10': 'intensityGreen'},
    {'1': 'intensity_blue', '3': 11, '4': 1, '5': 5, '10': 'intensityBlue'},
    {'1': 'distance_min', '3': 12, '4': 1, '5': 5, '10': 'distanceMin'},
    {'1': 'distance_max', '3': 13, '4': 1, '5': 5, '10': 'distanceMax'},
    {'1': 'blur_background', '3': 14, '4': 1, '5': 8, '10': 'blurBackground'},
  ],
};

/// Descriptor for `SaveSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveSettingsRequestDescriptor = $convert.base64Decode(
    'ChNTYXZlU2V0dGluZ3NSZXF1ZXN0EhQKBXdpZHRoGAEgASgFUgV3aWR0aBIWCgZoZWlnaHQYAi'
    'ABKAVSBmhlaWdodBISCgRjcm9wGAMgASgIUgRjcm9wEh0KCmNyb3Bfd2lkdGgYBCABKAVSCWNy'
    'b3BXaWR0aBIfCgtjcm9wX2hlaWdodBgFIAEoBVIKY3JvcEhlaWdodBIdCgpleWVzX2NoZWNrGA'
    'YgASgIUglleWVzQ2hlY2sSHQoKbGlwc19jaGVjaxgHIAEoCFIJbGlwc0NoZWNrEhoKCGxpZ2h0'
    'aW5nGAggASgIUghsaWdodGluZxIjCg1pbnRlbnNpdHlfcmVkGAkgASgFUgxpbnRlbnNpdHlSZW'
    'QSJwoPaW50ZW5zaXR5X2dyZWVuGAogASgFUg5pbnRlbnNpdHlHcmVlbhIlCg5pbnRlbnNpdHlf'
    'Ymx1ZRgLIAEoBVINaW50ZW5zaXR5Qmx1ZRIhCgxkaXN0YW5jZV9taW4YDCABKAVSC2Rpc3Rhbm'
    'NlTWluEiEKDGRpc3RhbmNlX21heBgNIAEoBVILZGlzdGFuY2VNYXgSJwoPYmx1cl9iYWNrZ3Jv'
    'dW5kGA4gASgIUg5ibHVyQmFja2dyb3VuZA==');

@$core.Deprecated('Use saveSettingsResponseDescriptor instead')
const SaveSettingsResponse$json = {
  '1': 'SaveSettingsResponse',
  '2': [
    {'1': 'width', '3': 1, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 2, '4': 1, '5': 5, '10': 'height'},
    {'1': 'crop', '3': 3, '4': 1, '5': 8, '10': 'crop'},
    {'1': 'crop_width', '3': 4, '4': 1, '5': 5, '10': 'cropWidth'},
    {'1': 'crop_height', '3': 5, '4': 1, '5': 5, '10': 'cropHeight'},
    {'1': 'eyes_check', '3': 6, '4': 1, '5': 8, '10': 'eyesCheck'},
    {'1': 'lips_check', '3': 7, '4': 1, '5': 8, '10': 'lipsCheck'},
    {'1': 'lighting', '3': 8, '4': 1, '5': 8, '10': 'lighting'},
    {'1': 'intensity_red', '3': 9, '4': 1, '5': 5, '10': 'intensityRed'},
    {'1': 'intensity_green', '3': 10, '4': 1, '5': 5, '10': 'intensityGreen'},
    {'1': 'intensity_blue', '3': 11, '4': 1, '5': 5, '10': 'intensityBlue'},
    {'1': 'distance_min', '3': 12, '4': 1, '5': 5, '10': 'distanceMin'},
    {'1': 'distance_max', '3': 13, '4': 1, '5': 5, '10': 'distanceMax'},
    {'1': 'blur_background', '3': 14, '4': 1, '5': 8, '10': 'blurBackground'},
  ],
};

/// Descriptor for `SaveSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveSettingsResponseDescriptor = $convert.base64Decode(
    'ChRTYXZlU2V0dGluZ3NSZXNwb25zZRIUCgV3aWR0aBgBIAEoBVIFd2lkdGgSFgoGaGVpZ2h0GA'
    'IgASgFUgZoZWlnaHQSEgoEY3JvcBgDIAEoCFIEY3JvcBIdCgpjcm9wX3dpZHRoGAQgASgFUglj'
    'cm9wV2lkdGgSHwoLY3JvcF9oZWlnaHQYBSABKAVSCmNyb3BIZWlnaHQSHQoKZXllc19jaGVjax'
    'gGIAEoCFIJZXllc0NoZWNrEh0KCmxpcHNfY2hlY2sYByABKAhSCWxpcHNDaGVjaxIaCghsaWdo'
    'dGluZxgIIAEoCFIIbGlnaHRpbmcSIwoNaW50ZW5zaXR5X3JlZBgJIAEoBVIMaW50ZW5zaXR5Um'
    'VkEicKD2ludGVuc2l0eV9ncmVlbhgKIAEoBVIOaW50ZW5zaXR5R3JlZW4SJQoOaW50ZW5zaXR5'
    'X2JsdWUYCyABKAVSDWludGVuc2l0eUJsdWUSIQoMZGlzdGFuY2VfbWluGAwgASgFUgtkaXN0YW'
    '5jZU1pbhIhCgxkaXN0YW5jZV9tYXgYDSABKAVSC2Rpc3RhbmNlTWF4EicKD2JsdXJfYmFja2dy'
    'b3VuZBgOIAEoCFIOYmx1ckJhY2tncm91bmQ=');

@$core.Deprecated('Use loadSettingsResponseDescriptor instead')
const LoadSettingsResponse$json = {
  '1': 'LoadSettingsResponse',
  '2': [
    {'1': 'width', '3': 1, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 2, '4': 1, '5': 5, '10': 'height'},
    {'1': 'crop', '3': 3, '4': 1, '5': 8, '10': 'crop'},
    {'1': 'crop_width', '3': 4, '4': 1, '5': 5, '10': 'cropWidth'},
    {'1': 'crop_height', '3': 5, '4': 1, '5': 5, '10': 'cropHeight'},
    {'1': 'eyes_check', '3': 6, '4': 1, '5': 8, '10': 'eyesCheck'},
    {'1': 'lips_check', '3': 7, '4': 1, '5': 8, '10': 'lipsCheck'},
    {'1': 'lighting', '3': 8, '4': 1, '5': 8, '10': 'lighting'},
    {'1': 'intensity_red', '3': 9, '4': 1, '5': 5, '10': 'intensityRed'},
    {'1': 'intensity_green', '3': 10, '4': 1, '5': 5, '10': 'intensityGreen'},
    {'1': 'intensity_blue', '3': 11, '4': 1, '5': 5, '10': 'intensityBlue'},
    {'1': 'distance_min', '3': 12, '4': 1, '5': 5, '10': 'distanceMin'},
    {'1': 'distance_max', '3': 13, '4': 1, '5': 5, '10': 'distanceMax'},
    {'1': 'blur_background', '3': 14, '4': 1, '5': 8, '10': 'blurBackground'},
    {
      '1': 'camera_resolutions',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.settings.CameraResolution',
      '10': 'cameraResolutions'
    },
    {
      '1': 'camera_ordering_automatic',
      '3': 16,
      '4': 1,
      '5': 8,
      '10': 'cameraOrderingAutomatic'
    },
    {'1': 'msmf_selection', '3': 17, '4': 1, '5': 8, '10': 'msmfSelection'},
    {'1': 'background_color', '3': 19, '4': 1, '5': 9, '10': 'backgroundColor'},
    {
      '1': 'background_method',
      '3': 20,
      '4': 1,
      '5': 9,
      '10': 'backgroundMethod'
    },
    {
      '1': 'eye_glasses_check',
      '3': 21,
      '4': 1,
      '5': 8,
      '10': 'eyeGlassesCheck'
    },
    {'1': 'head_pose_check', '3': 22, '4': 1, '5': 8, '10': 'headPoseCheck'},
    {'1': 'sharpness_check', '3': 23, '4': 1, '5': 8, '10': 'sharpnessCheck'},
    {
      '1': 'red_eye_detection_check',
      '3': 24,
      '4': 1,
      '5': 8,
      '10': 'redEyeDetectionCheck'
    },
    {'1': 'head_size_check', '3': 25, '4': 1, '5': 8, '10': 'headSizeCheck'},
    {'1': 'expression_check', '3': 26, '4': 1, '5': 8, '10': 'expressionCheck'},
    {'1': 'gaze_check', '3': 27, '4': 1, '5': 8, '10': 'gazeCheck'},
    {
      '1': 'lighting_evenness_check',
      '3': 28,
      '4': 1,
      '5': 8,
      '10': 'lightingEvennessCheck'
    },
    {'1': 'photo_format', '3': 29, '4': 1, '5': 9, '10': 'photoFormat'},
    {'1': 'jpeg_quality', '3': 30, '4': 1, '5': 5, '10': 'jpegQuality'},
    {
      '1': 'glasses_lights_off',
      '3': 34,
      '4': 1,
      '5': 8,
      '10': 'glassesLightsOff'
    },
    {'1': 'ofiq_checks', '3': 35, '4': 1, '5': 8, '10': 'ofiqChecks'},
    {'1': 'led_layout', '3': 36, '4': 1, '5': 9, '10': 'ledLayout'},
    {'1': 'focus_color', '3': 37, '4': 1, '5': 9, '10': 'focusColor'},
    {'1': 'focus_intensity', '3': 38, '4': 1, '5': 5, '10': 'focusIntensity'},
    {'1': 'expected_cameras', '3': 39, '4': 1, '5': 5, '10': 'expectedCameras'},
    {
      '1': 'background_strength',
      '3': 40,
      '4': 1,
      '5': 5,
      '10': 'backgroundStrength'
    },
    {
      '1': 'leds_off_for_photo',
      '3': 41,
      '4': 1,
      '5': 8,
      '10': 'ledsOffForPhoto'
    },
    {
      '1': 'camera_ordering_mode',
      '3': 42,
      '4': 1,
      '5': 9,
      '10': 'cameraOrderingMode'
    },
    {'1': 'icao_report', '3': 43, '4': 1, '5': 8, '10': 'icaoReport'},
    {'1': 'liveness_check', '3': 44, '4': 1, '5': 8, '10': 'livenessCheck'},
    {'1': 'photo_light', '3': 47, '4': 1, '5': 9, '10': 'photoLight'},
    {
      '1': 'liveness_head_turn_check',
      '3': 48,
      '4': 1,
      '5': 8,
      '10': 'livenessHeadTurnCheck'
    },
    {
      '1': 'glare_free_light',
      '3': 49,
      '4': 1,
      '5': 14,
      '6': '.settings.GlareFreeLight',
      '10': 'glareFreeLight'
    },
    {
      '1': 'glare_free_white_balance',
      '3': 50,
      '4': 1,
      '5': 5,
      '10': 'glareFreeWhiteBalance'
    },
    {'1': 'capture_warm_up', '3': 51, '4': 3, '5': 9, '10': 'captureWarmUp'},
    {
      '1': 'colour_correction',
      '3': 52,
      '4': 1,
      '5': 8,
      '10': 'colourCorrection'
    },
    {
      '1': 'colour_corrections',
      '3': 53,
      '4': 3,
      '5': 11,
      '6': '.settings.ColourCorrectionState',
      '10': 'colourCorrections'
    },
    {
      '1': 'camera_hub_upside_down',
      '3': 54,
      '4': 1,
      '5': 8,
      '10': 'cameraHubUpsideDown'
    },
  ],
  '9': [
    {'1': 18, '2': 19},
    {'1': 31, '2': 32},
    {'1': 32, '2': 33},
    {'1': 33, '2': 34},
    {'1': 45, '2': 46},
    {'1': 46, '2': 47},
  ],
  '10': ['liveness_shading_check', 'liveness_colour_check'],
};

/// Descriptor for `LoadSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loadSettingsResponseDescriptor = $convert.base64Decode(
    'ChRMb2FkU2V0dGluZ3NSZXNwb25zZRIUCgV3aWR0aBgBIAEoBVIFd2lkdGgSFgoGaGVpZ2h0GA'
    'IgASgFUgZoZWlnaHQSEgoEY3JvcBgDIAEoCFIEY3JvcBIdCgpjcm9wX3dpZHRoGAQgASgFUglj'
    'cm9wV2lkdGgSHwoLY3JvcF9oZWlnaHQYBSABKAVSCmNyb3BIZWlnaHQSHQoKZXllc19jaGVjax'
    'gGIAEoCFIJZXllc0NoZWNrEh0KCmxpcHNfY2hlY2sYByABKAhSCWxpcHNDaGVjaxIaCghsaWdo'
    'dGluZxgIIAEoCFIIbGlnaHRpbmcSIwoNaW50ZW5zaXR5X3JlZBgJIAEoBVIMaW50ZW5zaXR5Um'
    'VkEicKD2ludGVuc2l0eV9ncmVlbhgKIAEoBVIOaW50ZW5zaXR5R3JlZW4SJQoOaW50ZW5zaXR5'
    'X2JsdWUYCyABKAVSDWludGVuc2l0eUJsdWUSIQoMZGlzdGFuY2VfbWluGAwgASgFUgtkaXN0YW'
    '5jZU1pbhIhCgxkaXN0YW5jZV9tYXgYDSABKAVSC2Rpc3RhbmNlTWF4EicKD2JsdXJfYmFja2dy'
    'b3VuZBgOIAEoCFIOYmx1ckJhY2tncm91bmQSSQoSY2FtZXJhX3Jlc29sdXRpb25zGA8gAygLMh'
    'ouc2V0dGluZ3MuQ2FtZXJhUmVzb2x1dGlvblIRY2FtZXJhUmVzb2x1dGlvbnMSOgoZY2FtZXJh'
    'X29yZGVyaW5nX2F1dG9tYXRpYxgQIAEoCFIXY2FtZXJhT3JkZXJpbmdBdXRvbWF0aWMSJQoObX'
    'NtZl9zZWxlY3Rpb24YESABKAhSDW1zbWZTZWxlY3Rpb24SKQoQYmFja2dyb3VuZF9jb2xvchgT'
    'IAEoCVIPYmFja2dyb3VuZENvbG9yEisKEWJhY2tncm91bmRfbWV0aG9kGBQgASgJUhBiYWNrZ3'
    'JvdW5kTWV0aG9kEioKEWV5ZV9nbGFzc2VzX2NoZWNrGBUgASgIUg9leWVHbGFzc2VzQ2hlY2sS'
    'JgoPaGVhZF9wb3NlX2NoZWNrGBYgASgIUg1oZWFkUG9zZUNoZWNrEicKD3NoYXJwbmVzc19jaG'
    'VjaxgXIAEoCFIOc2hhcnBuZXNzQ2hlY2sSNQoXcmVkX2V5ZV9kZXRlY3Rpb25fY2hlY2sYGCAB'
    'KAhSFHJlZEV5ZURldGVjdGlvbkNoZWNrEiYKD2hlYWRfc2l6ZV9jaGVjaxgZIAEoCFINaGVhZF'
    'NpemVDaGVjaxIpChBleHByZXNzaW9uX2NoZWNrGBogASgIUg9leHByZXNzaW9uQ2hlY2sSHQoK'
    'Z2F6ZV9jaGVjaxgbIAEoCFIJZ2F6ZUNoZWNrEjYKF2xpZ2h0aW5nX2V2ZW5uZXNzX2NoZWNrGB'
    'wgASgIUhVsaWdodGluZ0V2ZW5uZXNzQ2hlY2sSIQoMcGhvdG9fZm9ybWF0GB0gASgJUgtwaG90'
    'b0Zvcm1hdBIhCgxqcGVnX3F1YWxpdHkYHiABKAVSC2pwZWdRdWFsaXR5EiwKEmdsYXNzZXNfbG'
    'lnaHRzX29mZhgiIAEoCFIQZ2xhc3Nlc0xpZ2h0c09mZhIfCgtvZmlxX2NoZWNrcxgjIAEoCFIK'
    'b2ZpcUNoZWNrcxIdCgpsZWRfbGF5b3V0GCQgASgJUglsZWRMYXlvdXQSHwoLZm9jdXNfY29sb3'
    'IYJSABKAlSCmZvY3VzQ29sb3ISJwoPZm9jdXNfaW50ZW5zaXR5GCYgASgFUg5mb2N1c0ludGVu'
    'c2l0eRIpChBleHBlY3RlZF9jYW1lcmFzGCcgASgFUg9leHBlY3RlZENhbWVyYXMSLwoTYmFja2'
    'dyb3VuZF9zdHJlbmd0aBgoIAEoBVISYmFja2dyb3VuZFN0cmVuZ3RoEisKEmxlZHNfb2ZmX2Zv'
    'cl9waG90bxgpIAEoCFIPbGVkc09mZkZvclBob3RvEjAKFGNhbWVyYV9vcmRlcmluZ19tb2RlGC'
    'ogASgJUhJjYW1lcmFPcmRlcmluZ01vZGUSHwoLaWNhb19yZXBvcnQYKyABKAhSCmljYW9SZXBv'
    'cnQSJQoObGl2ZW5lc3NfY2hlY2sYLCABKAhSDWxpdmVuZXNzQ2hlY2sSHwoLcGhvdG9fbGlnaH'
    'QYLyABKAlSCnBob3RvTGlnaHQSNwoYbGl2ZW5lc3NfaGVhZF90dXJuX2NoZWNrGDAgASgIUhVs'
    'aXZlbmVzc0hlYWRUdXJuQ2hlY2sSQgoQZ2xhcmVfZnJlZV9saWdodBgxIAEoDjIYLnNldHRpbm'
    'dzLkdsYXJlRnJlZUxpZ2h0Ug5nbGFyZUZyZWVMaWdodBI3ChhnbGFyZV9mcmVlX3doaXRlX2Jh'
    'bGFuY2UYMiABKAVSFWdsYXJlRnJlZVdoaXRlQmFsYW5jZRImCg9jYXB0dXJlX3dhcm1fdXAYMy'
    'ADKAlSDWNhcHR1cmVXYXJtVXASKwoRY29sb3VyX2NvcnJlY3Rpb24YNCABKAhSEGNvbG91ckNv'
    'cnJlY3Rpb24STgoSY29sb3VyX2NvcnJlY3Rpb25zGDUgAygLMh8uc2V0dGluZ3MuQ29sb3VyQ2'
    '9ycmVjdGlvblN0YXRlUhFjb2xvdXJDb3JyZWN0aW9ucxIzChZjYW1lcmFfaHViX3Vwc2lkZV9k'
    'b3duGDYgASgIUhNjYW1lcmFIdWJVcHNpZGVEb3duSgQIEhATSgQIHxAgSgQIIBAhSgQIIRAiSg'
    'QILRAuSgQILhAvUhZsaXZlbmVzc19zaGFkaW5nX2NoZWNrUhVsaXZlbmVzc19jb2xvdXJfY2hl'
    'Y2s=');

@$core.Deprecated('Use resolutionRequestDescriptor instead')
const ResolutionRequest$json = {
  '1': 'ResolutionRequest',
  '2': [
    {'1': 'width', '3': 1, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 2, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `ResolutionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resolutionRequestDescriptor = $convert.base64Decode(
    'ChFSZXNvbHV0aW9uUmVxdWVzdBIUCgV3aWR0aBgBIAEoBVIFd2lkdGgSFgoGaGVpZ2h0GAIgAS'
    'gFUgZoZWlnaHQ=');

@$core.Deprecated('Use resolutionResponseDescriptor instead')
const ResolutionResponse$json = {
  '1': 'ResolutionResponse',
  '2': [
    {'1': 'width', '3': 1, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 2, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `ResolutionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resolutionResponseDescriptor = $convert.base64Decode(
    'ChJSZXNvbHV0aW9uUmVzcG9uc2USFAoFd2lkdGgYASABKAVSBXdpZHRoEhYKBmhlaWdodBgCIA'
    'EoBVIGaGVpZ2h0');

@$core.Deprecated('Use cropResolutionRequestDescriptor instead')
const CropResolutionRequest$json = {
  '1': 'CropResolutionRequest',
  '2': [
    {'1': 'width', '3': 1, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 2, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `CropResolutionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cropResolutionRequestDescriptor = $convert.base64Decode(
    'ChVDcm9wUmVzb2x1dGlvblJlcXVlc3QSFAoFd2lkdGgYASABKAVSBXdpZHRoEhYKBmhlaWdodB'
    'gCIAEoBVIGaGVpZ2h0');

@$core.Deprecated('Use cropResolutionResponseDescriptor instead')
const CropResolutionResponse$json = {
  '1': 'CropResolutionResponse',
  '2': [
    {'1': 'width', '3': 1, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 2, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `CropResolutionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cropResolutionResponseDescriptor =
    $convert.base64Decode(
        'ChZDcm9wUmVzb2x1dGlvblJlc3BvbnNlEhQKBXdpZHRoGAEgASgFUgV3aWR0aBIWCgZoZWlnaH'
        'QYAiABKAVSBmhlaWdodA==');

@$core.Deprecated('Use cropRequestDescriptor instead')
const CropRequest$json = {
  '1': 'CropRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `CropRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cropRequestDescriptor =
    $convert.base64Decode('CgtDcm9wUmVxdWVzdBIUCgV2YWx1ZRgBIAEoCFIFdmFsdWU=');

@$core.Deprecated('Use cropResponseDescriptor instead')
const CropResponse$json = {
  '1': 'CropResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `CropResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cropResponseDescriptor = $convert
    .base64Decode('CgxDcm9wUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCFIHbWVzc2FnZQ==');

@$core.Deprecated('Use eyesCheckRequestDescriptor instead')
const EyesCheckRequest$json = {
  '1': 'EyesCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `EyesCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eyesCheckRequestDescriptor = $convert
    .base64Decode('ChBFeWVzQ2hlY2tSZXF1ZXN0EhQKBXZhbHVlGAEgASgIUgV2YWx1ZQ==');

@$core.Deprecated('Use eyesCheckResponseDescriptor instead')
const EyesCheckResponse$json = {
  '1': 'EyesCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `EyesCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eyesCheckResponseDescriptor = $convert.base64Decode(
    'ChFFeWVzQ2hlY2tSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgIUgdtZXNzYWdl');

@$core.Deprecated('Use lipsCheckRequestDescriptor instead')
const LipsCheckRequest$json = {
  '1': 'LipsCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `LipsCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lipsCheckRequestDescriptor = $convert
    .base64Decode('ChBMaXBzQ2hlY2tSZXF1ZXN0EhQKBXZhbHVlGAEgASgIUgV2YWx1ZQ==');

@$core.Deprecated('Use lipsCheckResponseDescriptor instead')
const LipsCheckResponse$json = {
  '1': 'LipsCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `LipsCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lipsCheckResponseDescriptor = $convert.base64Decode(
    'ChFMaXBzQ2hlY2tSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgIUgdtZXNzYWdl');

@$core.Deprecated('Use lightingRequestDescriptor instead')
const LightingRequest$json = {
  '1': 'LightingRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `LightingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lightingRequestDescriptor = $convert
    .base64Decode('Cg9MaWdodGluZ1JlcXVlc3QSFAoFdmFsdWUYASABKAhSBXZhbHVl');

@$core.Deprecated('Use lightingResponseDescriptor instead')
const LightingResponse$json = {
  '1': 'LightingResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `LightingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lightingResponseDescriptor = $convert.base64Decode(
    'ChBMaWdodGluZ1Jlc3BvbnNlEhgKB21lc3NhZ2UYASABKAhSB21lc3NhZ2U=');

@$core.Deprecated('Use intensityRequestDescriptor instead')
const IntensityRequest$json = {
  '1': 'IntensityRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `IntensityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List intensityRequestDescriptor = $convert
    .base64Decode('ChBJbnRlbnNpdHlSZXF1ZXN0EhQKBXZhbHVlGAEgASgFUgV2YWx1ZQ==');

@$core.Deprecated('Use intensityResponseDescriptor instead')
const IntensityResponse$json = {
  '1': 'IntensityResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `IntensityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List intensityResponseDescriptor = $convert.base64Decode(
    'ChFJbnRlbnNpdHlSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgFUgdtZXNzYWdl');

@$core.Deprecated('Use distanceMinRequestDescriptor instead')
const DistanceMinRequest$json = {
  '1': 'DistanceMinRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `DistanceMinRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List distanceMinRequestDescriptor = $convert
    .base64Decode('ChJEaXN0YW5jZU1pblJlcXVlc3QSFAoFdmFsdWUYASABKAVSBXZhbHVl');

@$core.Deprecated('Use distanceMinResponseDescriptor instead')
const DistanceMinResponse$json = {
  '1': 'DistanceMinResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `DistanceMinResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List distanceMinResponseDescriptor =
    $convert.base64Decode(
        'ChNEaXN0YW5jZU1pblJlc3BvbnNlEhgKB21lc3NhZ2UYASABKAVSB21lc3NhZ2U=');

@$core.Deprecated('Use distanceMaxRequestDescriptor instead')
const DistanceMaxRequest$json = {
  '1': 'DistanceMaxRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `DistanceMaxRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List distanceMaxRequestDescriptor = $convert
    .base64Decode('ChJEaXN0YW5jZU1heFJlcXVlc3QSFAoFdmFsdWUYASABKAVSBXZhbHVl');

@$core.Deprecated('Use distanceMaxResponseDescriptor instead')
const DistanceMaxResponse$json = {
  '1': 'DistanceMaxResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `DistanceMaxResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List distanceMaxResponseDescriptor =
    $convert.base64Decode(
        'ChNEaXN0YW5jZU1heFJlc3BvbnNlEhgKB21lc3NhZ2UYASABKAVSB21lc3NhZ2U=');

@$core.Deprecated('Use cameraOrderingModeRequestDescriptor instead')
const CameraOrderingModeRequest$json = {
  '1': 'CameraOrderingModeRequest',
  '2': [
    {'1': 'automatic', '3': 1, '4': 1, '5': 8, '10': 'automatic'},
    {'1': 'mode', '3': 2, '4': 1, '5': 9, '10': 'mode'},
  ],
};

/// Descriptor for `CameraOrderingModeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraOrderingModeRequestDescriptor =
    $convert.base64Decode(
        'ChlDYW1lcmFPcmRlcmluZ01vZGVSZXF1ZXN0EhwKCWF1dG9tYXRpYxgBIAEoCFIJYXV0b21hdG'
        'ljEhIKBG1vZGUYAiABKAlSBG1vZGU=');

@$core.Deprecated('Use cameraOrderingModeResponseDescriptor instead')
const CameraOrderingModeResponse$json = {
  '1': 'CameraOrderingModeResponse',
  '2': [
    {'1': 'automatic', '3': 1, '4': 1, '5': 8, '10': 'automatic'},
    {'1': 'mode', '3': 2, '4': 1, '5': 9, '10': 'mode'},
  ],
};

/// Descriptor for `CameraOrderingModeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraOrderingModeResponseDescriptor =
    $convert.base64Decode(
        'ChpDYW1lcmFPcmRlcmluZ01vZGVSZXNwb25zZRIcCglhdXRvbWF0aWMYASABKAhSCWF1dG9tYX'
        'RpYxISCgRtb2RlGAIgASgJUgRtb2Rl');

@$core.Deprecated('Use cameraHubUpsideDownRequestDescriptor instead')
const CameraHubUpsideDownRequest$json = {
  '1': 'CameraHubUpsideDownRequest',
  '2': [
    {'1': 'upside_down', '3': 1, '4': 1, '5': 8, '10': 'upsideDown'},
  ],
};

/// Descriptor for `CameraHubUpsideDownRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraHubUpsideDownRequestDescriptor =
    $convert.base64Decode(
        'ChpDYW1lcmFIdWJVcHNpZGVEb3duUmVxdWVzdBIfCgt1cHNpZGVfZG93bhgBIAEoCFIKdXBzaW'
        'RlRG93bg==');

@$core.Deprecated('Use cameraHubUpsideDownResponseDescriptor instead')
const CameraHubUpsideDownResponse$json = {
  '1': 'CameraHubUpsideDownResponse',
  '2': [
    {'1': 'upside_down', '3': 1, '4': 1, '5': 8, '10': 'upsideDown'},
  ],
};

/// Descriptor for `CameraHubUpsideDownResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraHubUpsideDownResponseDescriptor =
    $convert.base64Decode(
        'ChtDYW1lcmFIdWJVcHNpZGVEb3duUmVzcG9uc2USHwoLdXBzaWRlX2Rvd24YASABKAhSCnVwc2'
        'lkZURvd24=');

@$core.Deprecated('Use msmfSelectionRequestDescriptor instead')
const MsmfSelectionRequest$json = {
  '1': 'MsmfSelectionRequest',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `MsmfSelectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List msmfSelectionRequestDescriptor =
    $convert.base64Decode(
        'ChRNc21mU2VsZWN0aW9uUmVxdWVzdBIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVk');

@$core.Deprecated('Use msmfSelectionResponseDescriptor instead')
const MsmfSelectionResponse$json = {
  '1': 'MsmfSelectionResponse',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `MsmfSelectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List msmfSelectionResponseDescriptor =
    $convert.base64Decode(
        'ChVNc21mU2VsZWN0aW9uUmVzcG9uc2USGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZA==');

@$core.Deprecated('Use backgroundMethodRequestDescriptor instead')
const BackgroundMethodRequest$json = {
  '1': 'BackgroundMethodRequest',
  '2': [
    {'1': 'method', '3': 1, '4': 1, '5': 9, '10': 'method'},
  ],
};

/// Descriptor for `BackgroundMethodRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backgroundMethodRequestDescriptor =
    $convert.base64Decode(
        'ChdCYWNrZ3JvdW5kTWV0aG9kUmVxdWVzdBIWCgZtZXRob2QYASABKAlSBm1ldGhvZA==');

@$core.Deprecated('Use backgroundMethodResponseDescriptor instead')
const BackgroundMethodResponse$json = {
  '1': 'BackgroundMethodResponse',
  '2': [
    {'1': 'method', '3': 1, '4': 1, '5': 9, '10': 'method'},
  ],
};

/// Descriptor for `BackgroundMethodResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backgroundMethodResponseDescriptor =
    $convert.base64Decode(
        'ChhCYWNrZ3JvdW5kTWV0aG9kUmVzcG9uc2USFgoGbWV0aG9kGAEgASgJUgZtZXRob2Q=');

@$core.Deprecated('Use backgroundColorRequestDescriptor instead')
const BackgroundColorRequest$json = {
  '1': 'BackgroundColorRequest',
  '2': [
    {'1': 'color', '3': 1, '4': 1, '5': 9, '10': 'color'},
  ],
};

/// Descriptor for `BackgroundColorRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backgroundColorRequestDescriptor =
    $convert.base64Decode(
        'ChZCYWNrZ3JvdW5kQ29sb3JSZXF1ZXN0EhQKBWNvbG9yGAEgASgJUgVjb2xvcg==');

@$core.Deprecated('Use backgroundColorResponseDescriptor instead')
const BackgroundColorResponse$json = {
  '1': 'BackgroundColorResponse',
  '2': [
    {'1': 'color', '3': 1, '4': 1, '5': 9, '10': 'color'},
  ],
};

/// Descriptor for `BackgroundColorResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backgroundColorResponseDescriptor =
    $convert.base64Decode(
        'ChdCYWNrZ3JvdW5kQ29sb3JSZXNwb25zZRIUCgVjb2xvchgBIAEoCVIFY29sb3I=');

@$core.Deprecated('Use eyeGlassesCheckRequestDescriptor instead')
const EyeGlassesCheckRequest$json = {
  '1': 'EyeGlassesCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `EyeGlassesCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eyeGlassesCheckRequestDescriptor =
    $convert.base64Decode(
        'ChZFeWVHbGFzc2VzQ2hlY2tSZXF1ZXN0EhQKBXZhbHVlGAEgASgIUgV2YWx1ZQ==');

@$core.Deprecated('Use eyeGlassesCheckResponseDescriptor instead')
const EyeGlassesCheckResponse$json = {
  '1': 'EyeGlassesCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `EyeGlassesCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eyeGlassesCheckResponseDescriptor =
    $convert.base64Decode(
        'ChdFeWVHbGFzc2VzQ2hlY2tSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgIUgdtZXNzYWdl');

@$core.Deprecated('Use headPoseCheckRequestDescriptor instead')
const HeadPoseCheckRequest$json = {
  '1': 'HeadPoseCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `HeadPoseCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headPoseCheckRequestDescriptor =
    $convert.base64Decode(
        'ChRIZWFkUG9zZUNoZWNrUmVxdWVzdBIUCgV2YWx1ZRgBIAEoCFIFdmFsdWU=');

@$core.Deprecated('Use headPoseCheckResponseDescriptor instead')
const HeadPoseCheckResponse$json = {
  '1': 'HeadPoseCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `HeadPoseCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headPoseCheckResponseDescriptor =
    $convert.base64Decode(
        'ChVIZWFkUG9zZUNoZWNrUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCFIHbWVzc2FnZQ==');

@$core.Deprecated('Use sharpnessCheckRequestDescriptor instead')
const SharpnessCheckRequest$json = {
  '1': 'SharpnessCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `SharpnessCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sharpnessCheckRequestDescriptor =
    $convert.base64Decode(
        'ChVTaGFycG5lc3NDaGVja1JlcXVlc3QSFAoFdmFsdWUYASABKAhSBXZhbHVl');

@$core.Deprecated('Use sharpnessCheckResponseDescriptor instead')
const SharpnessCheckResponse$json = {
  '1': 'SharpnessCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `SharpnessCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sharpnessCheckResponseDescriptor =
    $convert.base64Decode(
        'ChZTaGFycG5lc3NDaGVja1Jlc3BvbnNlEhgKB21lc3NhZ2UYASABKAhSB21lc3NhZ2U=');

@$core.Deprecated('Use redEyeDetectionCheckRequestDescriptor instead')
const RedEyeDetectionCheckRequest$json = {
  '1': 'RedEyeDetectionCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `RedEyeDetectionCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List redEyeDetectionCheckRequestDescriptor =
    $convert.base64Decode(
        'ChtSZWRFeWVEZXRlY3Rpb25DaGVja1JlcXVlc3QSFAoFdmFsdWUYASABKAhSBXZhbHVl');

@$core.Deprecated('Use redEyeDetectionCheckResponseDescriptor instead')
const RedEyeDetectionCheckResponse$json = {
  '1': 'RedEyeDetectionCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `RedEyeDetectionCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List redEyeDetectionCheckResponseDescriptor =
    $convert.base64Decode(
        'ChxSZWRFeWVEZXRlY3Rpb25DaGVja1Jlc3BvbnNlEhgKB21lc3NhZ2UYASABKAhSB21lc3NhZ2'
        'U=');

@$core.Deprecated('Use headSizeCheckRequestDescriptor instead')
const HeadSizeCheckRequest$json = {
  '1': 'HeadSizeCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `HeadSizeCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headSizeCheckRequestDescriptor =
    $convert.base64Decode(
        'ChRIZWFkU2l6ZUNoZWNrUmVxdWVzdBIUCgV2YWx1ZRgBIAEoCFIFdmFsdWU=');

@$core.Deprecated('Use headSizeCheckResponseDescriptor instead')
const HeadSizeCheckResponse$json = {
  '1': 'HeadSizeCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `HeadSizeCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headSizeCheckResponseDescriptor =
    $convert.base64Decode(
        'ChVIZWFkU2l6ZUNoZWNrUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCFIHbWVzc2FnZQ==');

@$core.Deprecated('Use expressionCheckRequestDescriptor instead')
const ExpressionCheckRequest$json = {
  '1': 'ExpressionCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `ExpressionCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List expressionCheckRequestDescriptor =
    $convert.base64Decode(
        'ChZFeHByZXNzaW9uQ2hlY2tSZXF1ZXN0EhQKBXZhbHVlGAEgASgIUgV2YWx1ZQ==');

@$core.Deprecated('Use expressionCheckResponseDescriptor instead')
const ExpressionCheckResponse$json = {
  '1': 'ExpressionCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `ExpressionCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List expressionCheckResponseDescriptor =
    $convert.base64Decode(
        'ChdFeHByZXNzaW9uQ2hlY2tSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgIUgdtZXNzYWdl');

@$core.Deprecated('Use gazeCheckRequestDescriptor instead')
const GazeCheckRequest$json = {
  '1': 'GazeCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `GazeCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gazeCheckRequestDescriptor = $convert
    .base64Decode('ChBHYXplQ2hlY2tSZXF1ZXN0EhQKBXZhbHVlGAEgASgIUgV2YWx1ZQ==');

@$core.Deprecated('Use gazeCheckResponseDescriptor instead')
const GazeCheckResponse$json = {
  '1': 'GazeCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `GazeCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gazeCheckResponseDescriptor = $convert.base64Decode(
    'ChFHYXplQ2hlY2tSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgIUgdtZXNzYWdl');

@$core.Deprecated('Use lightingEvennessCheckRequestDescriptor instead')
const LightingEvennessCheckRequest$json = {
  '1': 'LightingEvennessCheckRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `LightingEvennessCheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lightingEvennessCheckRequestDescriptor =
    $convert.base64Decode(
        'ChxMaWdodGluZ0V2ZW5uZXNzQ2hlY2tSZXF1ZXN0EhQKBXZhbHVlGAEgASgIUgV2YWx1ZQ==');

@$core.Deprecated('Use lightingEvennessCheckResponseDescriptor instead')
const LightingEvennessCheckResponse$json = {
  '1': 'LightingEvennessCheckResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `LightingEvennessCheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lightingEvennessCheckResponseDescriptor =
    $convert.base64Decode(
        'Ch1MaWdodGluZ0V2ZW5uZXNzQ2hlY2tSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgIUgdtZXNzYW'
        'dl');

@$core.Deprecated('Use photoFormatRequestDescriptor instead')
const PhotoFormatRequest$json = {
  '1': 'PhotoFormatRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `PhotoFormatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoFormatRequestDescriptor = $convert
    .base64Decode('ChJQaG90b0Zvcm1hdFJlcXVlc3QSFAoFdmFsdWUYASABKAlSBXZhbHVl');

@$core.Deprecated('Use photoFormatResponseDescriptor instead')
const PhotoFormatResponse$json = {
  '1': 'PhotoFormatResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
    {'1': 'crop_height', '3': 2, '4': 1, '5': 5, '10': 'cropHeight'},
  ],
};

/// Descriptor for `PhotoFormatResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoFormatResponseDescriptor = $convert.base64Decode(
    'ChNQaG90b0Zvcm1hdFJlc3BvbnNlEhgKB21lc3NhZ2UYASABKAlSB21lc3NhZ2USHwoLY3JvcF'
    '9oZWlnaHQYAiABKAVSCmNyb3BIZWlnaHQ=');

@$core.Deprecated('Use jpegQualityRequestDescriptor instead')
const JpegQualityRequest$json = {
  '1': 'JpegQualityRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `JpegQualityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jpegQualityRequestDescriptor = $convert
    .base64Decode('ChJKcGVnUXVhbGl0eVJlcXVlc3QSFAoFdmFsdWUYASABKAVSBXZhbHVl');

@$core.Deprecated('Use jpegQualityResponseDescriptor instead')
const JpegQualityResponse$json = {
  '1': 'JpegQualityResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `JpegQualityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jpegQualityResponseDescriptor =
    $convert.base64Decode(
        'ChNKcGVnUXVhbGl0eVJlc3BvbnNlEhgKB21lc3NhZ2UYASABKAVSB21lc3NhZ2U=');

@$core.Deprecated('Use glassesLightsOffRequestDescriptor instead')
const GlassesLightsOffRequest$json = {
  '1': 'GlassesLightsOffRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `GlassesLightsOffRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List glassesLightsOffRequestDescriptor =
    $convert.base64Decode(
        'ChdHbGFzc2VzTGlnaHRzT2ZmUmVxdWVzdBIUCgV2YWx1ZRgBIAEoCFIFdmFsdWU=');

@$core.Deprecated('Use glassesLightsOffResponseDescriptor instead')
const GlassesLightsOffResponse$json = {
  '1': 'GlassesLightsOffResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `GlassesLightsOffResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List glassesLightsOffResponseDescriptor =
    $convert.base64Decode(
        'ChhHbGFzc2VzTGlnaHRzT2ZmUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCFIHbWVzc2FnZQ==');

@$core.Deprecated('Use ledsOffForPhotoRequestDescriptor instead')
const LedsOffForPhotoRequest$json = {
  '1': 'LedsOffForPhotoRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `LedsOffForPhotoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ledsOffForPhotoRequestDescriptor =
    $convert.base64Decode(
        'ChZMZWRzT2ZmRm9yUGhvdG9SZXF1ZXN0EhQKBXZhbHVlGAEgASgIUgV2YWx1ZQ==');

@$core.Deprecated('Use ledsOffForPhotoResponseDescriptor instead')
const LedsOffForPhotoResponse$json = {
  '1': 'LedsOffForPhotoResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `LedsOffForPhotoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ledsOffForPhotoResponseDescriptor =
    $convert.base64Decode(
        'ChdMZWRzT2ZmRm9yUGhvdG9SZXNwb25zZRIYCgdtZXNzYWdlGAEgASgIUgdtZXNzYWdl');

@$core.Deprecated('Use ofiqChecksRequestDescriptor instead')
const OfiqChecksRequest$json = {
  '1': 'OfiqChecksRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `OfiqChecksRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ofiqChecksRequestDescriptor = $convert
    .base64Decode('ChFPZmlxQ2hlY2tzUmVxdWVzdBIUCgV2YWx1ZRgBIAEoCFIFdmFsdWU=');

@$core.Deprecated('Use ofiqChecksResponseDescriptor instead')
const OfiqChecksResponse$json = {
  '1': 'OfiqChecksResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `OfiqChecksResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ofiqChecksResponseDescriptor =
    $convert.base64Decode(
        'ChJPZmlxQ2hlY2tzUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCFIHbWVzc2FnZQ==');

@$core.Deprecated('Use icaoReportRequestDescriptor instead')
const IcaoReportRequest$json = {
  '1': 'IcaoReportRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `IcaoReportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List icaoReportRequestDescriptor = $convert
    .base64Decode('ChFJY2FvUmVwb3J0UmVxdWVzdBIUCgV2YWx1ZRgBIAEoCFIFdmFsdWU=');

@$core.Deprecated('Use icaoReportResponseDescriptor instead')
const IcaoReportResponse$json = {
  '1': 'IcaoReportResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `IcaoReportResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List icaoReportResponseDescriptor =
    $convert.base64Decode(
        'ChJJY2FvUmVwb3J0UmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCFIHbWVzc2FnZQ==');

@$core.Deprecated('Use livenessChecksRequestDescriptor instead')
const LivenessChecksRequest$json = {
  '1': 'LivenessChecksRequest',
  '2': [
    {'1': 'liveness_check', '3': 1, '4': 1, '5': 8, '10': 'livenessCheck'},
    {
      '1': 'head_turn_check',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'headTurnCheck',
      '17': true
    },
  ],
  '8': [
    {'1': '_head_turn_check'},
  ],
  '9': [
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
  ],
  '10': ['shading_check', 'colour_check'],
};

/// Descriptor for `LivenessChecksRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List livenessChecksRequestDescriptor = $convert.base64Decode(
    'ChVMaXZlbmVzc0NoZWNrc1JlcXVlc3QSJQoObGl2ZW5lc3NfY2hlY2sYASABKAhSDWxpdmVuZX'
    'NzQ2hlY2sSKwoPaGVhZF90dXJuX2NoZWNrGAQgASgISABSDWhlYWRUdXJuQ2hlY2uIAQFCEgoQ'
    'X2hlYWRfdHVybl9jaGVja0oECAIQA0oECAMQBFINc2hhZGluZ19jaGVja1IMY29sb3VyX2NoZW'
    'Nr');

@$core.Deprecated('Use livenessChecksResponseDescriptor instead')
const LivenessChecksResponse$json = {
  '1': 'LivenessChecksResponse',
  '2': [
    {'1': 'liveness_check', '3': 1, '4': 1, '5': 8, '10': 'livenessCheck'},
    {'1': 'head_turn_check', '3': 4, '4': 1, '5': 8, '10': 'headTurnCheck'},
  ],
  '9': [
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
  ],
  '10': ['shading_check', 'colour_check'],
};

/// Descriptor for `LivenessChecksResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List livenessChecksResponseDescriptor = $convert.base64Decode(
    'ChZMaXZlbmVzc0NoZWNrc1Jlc3BvbnNlEiUKDmxpdmVuZXNzX2NoZWNrGAEgASgIUg1saXZlbm'
    'Vzc0NoZWNrEiYKD2hlYWRfdHVybl9jaGVjaxgEIAEoCFINaGVhZFR1cm5DaGVja0oECAIQA0oE'
    'CAMQBFINc2hhZGluZ19jaGVja1IMY29sb3VyX2NoZWNr');

@$core.Deprecated('Use photoLightRequestDescriptor instead')
const PhotoLightRequest$json = {
  '1': 'PhotoLightRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `PhotoLightRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoLightRequestDescriptor = $convert
    .base64Decode('ChFQaG90b0xpZ2h0UmVxdWVzdBIUCgV2YWx1ZRgBIAEoCVIFdmFsdWU=');

@$core.Deprecated('Use photoLightResponseDescriptor instead')
const PhotoLightResponse$json = {
  '1': 'PhotoLightResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `PhotoLightResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoLightResponseDescriptor =
    $convert.base64Decode(
        'ChJQaG90b0xpZ2h0UmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use ledLayoutRequestDescriptor instead')
const LedLayoutRequest$json = {
  '1': 'LedLayoutRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `LedLayoutRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ledLayoutRequestDescriptor = $convert
    .base64Decode('ChBMZWRMYXlvdXRSZXF1ZXN0EhQKBXZhbHVlGAEgASgJUgV2YWx1ZQ==');

@$core.Deprecated('Use ledLayoutResponseDescriptor instead')
const LedLayoutResponse$json = {
  '1': 'LedLayoutResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `LedLayoutResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ledLayoutResponseDescriptor = $convert.base64Decode(
    'ChFMZWRMYXlvdXRSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use boardGblRequestDescriptor instead')
const BoardGblRequest$json = {
  '1': 'BoardGblRequest',
  '2': [
    {'1': 'layout', '3': 1, '4': 1, '5': 9, '10': 'layout'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `BoardGblRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boardGblRequestDescriptor = $convert.base64Decode(
    'Cg9Cb2FyZEdibFJlcXVlc3QSFgoGbGF5b3V0GAEgASgJUgZsYXlvdXQSGAoHY29udGVudBgCIA'
    'EoCVIHY29udGVudA==');

@$core.Deprecated('Use boardGblLayoutRequestDescriptor instead')
const BoardGblLayoutRequest$json = {
  '1': 'BoardGblLayoutRequest',
  '2': [
    {'1': 'layout', '3': 1, '4': 1, '5': 9, '10': 'layout'},
  ],
};

/// Descriptor for `BoardGblLayoutRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boardGblLayoutRequestDescriptor =
    $convert.base64Decode(
        'ChVCb2FyZEdibExheW91dFJlcXVlc3QSFgoGbGF5b3V0GAEgASgJUgZsYXlvdXQ=');

@$core.Deprecated('Use boardGblResponseDescriptor instead')
const BoardGblResponse$json = {
  '1': 'BoardGblResponse',
  '2': [
    {'1': 'layout', '3': 1, '4': 1, '5': 9, '10': 'layout'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {'1': 'custom', '3': 3, '4': 1, '5': 8, '10': 'custom'},
    {'1': 'message', '3': 4, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `BoardGblResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boardGblResponseDescriptor = $convert.base64Decode(
    'ChBCb2FyZEdibFJlc3BvbnNlEhYKBmxheW91dBgBIAEoCVIGbGF5b3V0EhgKB2NvbnRlbnQYAi'
    'ABKAlSB2NvbnRlbnQSFgoGY3VzdG9tGAMgASgIUgZjdXN0b20SGAoHbWVzc2FnZRgEIAEoCVIH'
    'bWVzc2FnZQ==');

@$core.Deprecated('Use focusLightRequestDescriptor instead')
const FocusLightRequest$json = {
  '1': 'FocusLightRequest',
  '2': [
    {'1': 'color', '3': 1, '4': 1, '5': 9, '10': 'color'},
    {'1': 'intensity', '3': 2, '4': 1, '5': 5, '10': 'intensity'},
  ],
};

/// Descriptor for `FocusLightRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List focusLightRequestDescriptor = $convert.base64Decode(
    'ChFGb2N1c0xpZ2h0UmVxdWVzdBIUCgVjb2xvchgBIAEoCVIFY29sb3ISHAoJaW50ZW5zaXR5GA'
    'IgASgFUglpbnRlbnNpdHk=');

@$core.Deprecated('Use focusLightResponseDescriptor instead')
const FocusLightResponse$json = {
  '1': 'FocusLightResponse',
  '2': [
    {'1': 'color', '3': 1, '4': 1, '5': 9, '10': 'color'},
    {'1': 'intensity', '3': 2, '4': 1, '5': 5, '10': 'intensity'},
  ],
};

/// Descriptor for `FocusLightResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List focusLightResponseDescriptor = $convert.base64Decode(
    'ChJGb2N1c0xpZ2h0UmVzcG9uc2USFAoFY29sb3IYASABKAlSBWNvbG9yEhwKCWludGVuc2l0eR'
    'gCIAEoBVIJaW50ZW5zaXR5');

@$core.Deprecated('Use expectedCamerasRequestDescriptor instead')
const ExpectedCamerasRequest$json = {
  '1': 'ExpectedCamerasRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `ExpectedCamerasRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List expectedCamerasRequestDescriptor =
    $convert.base64Decode(
        'ChZFeHBlY3RlZENhbWVyYXNSZXF1ZXN0EhQKBXZhbHVlGAEgASgFUgV2YWx1ZQ==');

@$core.Deprecated('Use expectedCamerasResponseDescriptor instead')
const ExpectedCamerasResponse$json = {
  '1': 'ExpectedCamerasResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `ExpectedCamerasResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List expectedCamerasResponseDescriptor =
    $convert.base64Decode(
        'ChdFeHBlY3RlZENhbWVyYXNSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgFUgdtZXNzYWdl');

@$core.Deprecated('Use backgroundStrengthRequestDescriptor instead')
const BackgroundStrengthRequest$json = {
  '1': 'BackgroundStrengthRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `BackgroundStrengthRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backgroundStrengthRequestDescriptor =
    $convert.base64Decode(
        'ChlCYWNrZ3JvdW5kU3RyZW5ndGhSZXF1ZXN0EhQKBXZhbHVlGAEgASgFUgV2YWx1ZQ==');

@$core.Deprecated('Use backgroundStrengthResponseDescriptor instead')
const BackgroundStrengthResponse$json = {
  '1': 'BackgroundStrengthResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `BackgroundStrengthResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backgroundStrengthResponseDescriptor =
    $convert.base64Decode(
        'ChpCYWNrZ3JvdW5kU3RyZW5ndGhSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgFUgdtZXNzYWdl');

@$core.Deprecated('Use glareFreeLightRequestDescriptor instead')
const GlareFreeLightRequest$json = {
  '1': 'GlareFreeLightRequest',
  '2': [
    {
      '1': 'value',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.settings.GlareFreeLight',
      '10': 'value'
    },
  ],
};

/// Descriptor for `GlareFreeLightRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List glareFreeLightRequestDescriptor = $convert.base64Decode(
    'ChVHbGFyZUZyZWVMaWdodFJlcXVlc3QSLgoFdmFsdWUYASABKA4yGC5zZXR0aW5ncy5HbGFyZU'
    'ZyZWVMaWdodFIFdmFsdWU=');

@$core.Deprecated('Use glareFreeLightResponseDescriptor instead')
const GlareFreeLightResponse$json = {
  '1': 'GlareFreeLightResponse',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.settings.GlareFreeLight',
      '10': 'message'
    },
  ],
};

/// Descriptor for `GlareFreeLightResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List glareFreeLightResponseDescriptor =
    $convert.base64Decode(
        'ChZHbGFyZUZyZWVMaWdodFJlc3BvbnNlEjIKB21lc3NhZ2UYASABKA4yGC5zZXR0aW5ncy5HbG'
        'FyZUZyZWVMaWdodFIHbWVzc2FnZQ==');

@$core.Deprecated('Use glareFreeWhiteBalanceRequestDescriptor instead')
const GlareFreeWhiteBalanceRequest$json = {
  '1': 'GlareFreeWhiteBalanceRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `GlareFreeWhiteBalanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List glareFreeWhiteBalanceRequestDescriptor =
    $convert.base64Decode(
        'ChxHbGFyZUZyZWVXaGl0ZUJhbGFuY2VSZXF1ZXN0EhQKBXZhbHVlGAEgASgFUgV2YWx1ZQ==');

@$core.Deprecated('Use glareFreeWhiteBalanceResponseDescriptor instead')
const GlareFreeWhiteBalanceResponse$json = {
  '1': 'GlareFreeWhiteBalanceResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 5, '10': 'message'},
  ],
};

/// Descriptor for `GlareFreeWhiteBalanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List glareFreeWhiteBalanceResponseDescriptor =
    $convert.base64Decode(
        'Ch1HbGFyZUZyZWVXaGl0ZUJhbGFuY2VSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgFUgdtZXNzYW'
        'dl');

@$core.Deprecated('Use captureWarmUpRequestDescriptor instead')
const CaptureWarmUpRequest$json = {
  '1': 'CaptureWarmUpRequest',
  '2': [
    {'1': 'items', '3': 1, '4': 3, '5': 9, '10': 'items'},
  ],
};

/// Descriptor for `CaptureWarmUpRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureWarmUpRequestDescriptor =
    $convert.base64Decode(
        'ChRDYXB0dXJlV2FybVVwUmVxdWVzdBIUCgVpdGVtcxgBIAMoCVIFaXRlbXM=');

@$core.Deprecated('Use captureWarmUpResponseDescriptor instead')
const CaptureWarmUpResponse$json = {
  '1': 'CaptureWarmUpResponse',
  '2': [
    {'1': 'items', '3': 1, '4': 3, '5': 9, '10': 'items'},
  ],
};

/// Descriptor for `CaptureWarmUpResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureWarmUpResponseDescriptor =
    $convert.base64Decode(
        'ChVDYXB0dXJlV2FybVVwUmVzcG9uc2USFAoFaXRlbXMYASADKAlSBWl0ZW1z');

@$core.Deprecated('Use colourMeasurementDescriptor instead')
const ColourMeasurement$json = {
  '1': 'ColourMeasurement',
  '2': [
    {'1': 'measured', '3': 1, '4': 1, '5': 9, '10': 'measured'},
    {'1': 'camera', '3': 2, '4': 1, '5': 5, '10': 'camera'},
    {'1': 'chart', '3': 3, '4': 1, '5': 9, '10': 'chart'},
    {'1': 'mean_de_before', '3': 4, '4': 1, '5': 1, '10': 'meanDeBefore'},
    {'1': 'mean_de_after', '3': 5, '4': 1, '5': 1, '10': 'meanDeAfter'},
    {'1': 'method', '3': 6, '4': 1, '5': 9, '10': 'method'},
    {'1': 'led_red', '3': 7, '4': 1, '5': 5, '10': 'ledRed'},
    {'1': 'led_green', '3': 8, '4': 1, '5': 5, '10': 'ledGreen'},
    {'1': 'led_blue', '3': 9, '4': 1, '5': 5, '10': 'ledBlue'},
    {'1': 'score_after', '3': 10, '4': 1, '5': 1, '10': 'scoreAfter'},
    {'1': 'white_balance', '3': 11, '4': 1, '5': 5, '10': 'whiteBalance'},
    {'1': 'card_version', '3': 12, '4': 1, '5': 9, '10': 'cardVersion'},
  ],
};

/// Descriptor for `ColourMeasurement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colourMeasurementDescriptor = $convert.base64Decode(
    'ChFDb2xvdXJNZWFzdXJlbWVudBIaCghtZWFzdXJlZBgBIAEoCVIIbWVhc3VyZWQSFgoGY2FtZX'
    'JhGAIgASgFUgZjYW1lcmESFAoFY2hhcnQYAyABKAlSBWNoYXJ0EiQKDm1lYW5fZGVfYmVmb3Jl'
    'GAQgASgBUgxtZWFuRGVCZWZvcmUSIgoNbWVhbl9kZV9hZnRlchgFIAEoAVILbWVhbkRlQWZ0ZX'
    'ISFgoGbWV0aG9kGAYgASgJUgZtZXRob2QSFwoHbGVkX3JlZBgHIAEoBVIGbGVkUmVkEhsKCWxl'
    'ZF9ncmVlbhgIIAEoBVIIbGVkR3JlZW4SGQoIbGVkX2JsdWUYCSABKAVSB2xlZEJsdWUSHwoLc2'
    'NvcmVfYWZ0ZXIYCiABKAFSCnNjb3JlQWZ0ZXISIwoNd2hpdGVfYmFsYW5jZRgLIAEoBVIMd2hp'
    'dGVCYWxhbmNlEiEKDGNhcmRfdmVyc2lvbhgMIAEoCVILY2FyZFZlcnNpb24=');

@$core.Deprecated('Use colourCorrectionRequestDescriptor instead')
const ColourCorrectionRequest$json = {
  '1': 'ColourCorrectionRequest',
  '2': [
    {'1': 'light', '3': 1, '4': 1, '5': 9, '10': 'light'},
    {'1': 'matrix', '3': 2, '4': 3, '5': 1, '10': 'matrix'},
    {
      '1': 'measurement',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.settings.ColourMeasurement',
      '10': 'measurement'
    },
    {'1': 'clear', '3': 4, '4': 1, '5': 8, '10': 'clear'},
  ],
};

/// Descriptor for `ColourCorrectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colourCorrectionRequestDescriptor = $convert.base64Decode(
    'ChdDb2xvdXJDb3JyZWN0aW9uUmVxdWVzdBIUCgVsaWdodBgBIAEoCVIFbGlnaHQSFgoGbWF0cm'
    'l4GAIgAygBUgZtYXRyaXgSPQoLbWVhc3VyZW1lbnQYAyABKAsyGy5zZXR0aW5ncy5Db2xvdXJN'
    'ZWFzdXJlbWVudFILbWVhc3VyZW1lbnQSFAoFY2xlYXIYBCABKAhSBWNsZWFy');

@$core.Deprecated('Use colourCorrectionStateDescriptor instead')
const ColourCorrectionState$json = {
  '1': 'ColourCorrectionState',
  '2': [
    {'1': 'light', '3': 1, '4': 1, '5': 9, '10': 'light'},
    {'1': 'matrix', '3': 2, '4': 3, '5': 1, '10': 'matrix'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'measurement',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.settings.ColourMeasurement',
      '10': 'measurement'
    },
  ],
};

/// Descriptor for `ColourCorrectionState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colourCorrectionStateDescriptor = $convert.base64Decode(
    'ChVDb2xvdXJDb3JyZWN0aW9uU3RhdGUSFAoFbGlnaHQYASABKAlSBWxpZ2h0EhYKBm1hdHJpeB'
    'gCIAMoAVIGbWF0cml4EhYKBnNvdXJjZRgDIAEoCVIGc291cmNlEj0KC21lYXN1cmVtZW50GAQg'
    'ASgLMhsuc2V0dGluZ3MuQ29sb3VyTWVhc3VyZW1lbnRSC21lYXN1cmVtZW50');

@$core.Deprecated('Use colourCorrectionResponseDescriptor instead')
const ColourCorrectionResponse$json = {
  '1': 'ColourCorrectionResponse',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.settings.ColourCorrectionState',
      '10': 'state'
    },
  ],
};

/// Descriptor for `ColourCorrectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colourCorrectionResponseDescriptor =
    $convert.base64Decode(
        'ChhDb2xvdXJDb3JyZWN0aW9uUmVzcG9uc2USNQoFc3RhdGUYASABKAsyHy5zZXR0aW5ncy5Db2'
        'xvdXJDb3JyZWN0aW9uU3RhdGVSBXN0YXRl');

@$core.Deprecated('Use colourCorrectionEnabledRequestDescriptor instead')
const ColourCorrectionEnabledRequest$json = {
  '1': 'ColourCorrectionEnabledRequest',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `ColourCorrectionEnabledRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colourCorrectionEnabledRequestDescriptor =
    $convert.base64Decode(
        'Ch5Db2xvdXJDb3JyZWN0aW9uRW5hYmxlZFJlcXVlc3QSFAoFdmFsdWUYASABKAhSBXZhbHVl');

@$core.Deprecated('Use colourCorrectionEnabledResponseDescriptor instead')
const ColourCorrectionEnabledResponse$json = {
  '1': 'ColourCorrectionEnabledResponse',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `ColourCorrectionEnabledResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colourCorrectionEnabledResponseDescriptor =
    $convert.base64Decode(
        'Ch9Db2xvdXJDb3JyZWN0aW9uRW5hYmxlZFJlc3BvbnNlEhQKBXZhbHVlGAEgASgIUgV2YWx1ZQ'
        '==');

@$core.Deprecated('Use columnSettingDescriptor instead')
const ColumnSetting$json = {
  '1': 'ColumnSetting',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'factory_value', '3': 2, '4': 1, '5': 9, '10': 'factoryValue'},
    {'1': 'standard_value', '3': 3, '4': 1, '5': 9, '10': 'standardValue'},
    {'1': 'current_value', '3': 4, '4': 1, '5': 9, '10': 'currentValue'},
    {'1': 'changed', '3': 5, '4': 1, '5': 8, '10': 'changed'},
  ],
};

/// Descriptor for `ColumnSetting`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnSettingDescriptor = $convert.base64Decode(
    'Cg1Db2x1bW5TZXR0aW5nEhIKBG5hbWUYASABKAlSBG5hbWUSIwoNZmFjdG9yeV92YWx1ZRgCIA'
    'EoCVIMZmFjdG9yeVZhbHVlEiUKDnN0YW5kYXJkX3ZhbHVlGAMgASgJUg1zdGFuZGFyZFZhbHVl'
    'EiMKDWN1cnJlbnRfdmFsdWUYBCABKAlSDGN1cnJlbnRWYWx1ZRIYCgdjaGFuZ2VkGAUgASgIUg'
    'djaGFuZ2Vk');

@$core.Deprecated('Use columnProfileResponseDescriptor instead')
const ColumnProfileResponse$json = {
  '1': 'ColumnProfileResponse',
  '2': [
    {
      '1': 'settings',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.settings.ColumnSetting',
      '10': 'settings'
    },
    {'1': 'board_id', '3': 2, '4': 1, '5': 9, '10': 'boardId'},
    {'1': 'board_connected', '3': 3, '4': 1, '5': 8, '10': 'boardConnected'},
    {'1': 'revision', '3': 4, '4': 1, '5': 5, '10': 'revision'},
    {'1': 'adopted_from', '3': 5, '4': 1, '5': 9, '10': 'adoptedFrom'},
    {'1': 'has_factory', '3': 6, '4': 1, '5': 8, '10': 'hasFactory'},
    {'1': 'save_pending', '3': 7, '4': 1, '5': 8, '10': 'savePending'},
    {'1': 'notice', '3': 8, '4': 1, '5': 9, '10': 'notice'},
  ],
};

/// Descriptor for `ColumnProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnProfileResponseDescriptor = $convert.base64Decode(
    'ChVDb2x1bW5Qcm9maWxlUmVzcG9uc2USMwoIc2V0dGluZ3MYASADKAsyFy5zZXR0aW5ncy5Db2'
    'x1bW5TZXR0aW5nUghzZXR0aW5ncxIZCghib2FyZF9pZBgCIAEoCVIHYm9hcmRJZBInCg9ib2Fy'
    'ZF9jb25uZWN0ZWQYAyABKAhSDmJvYXJkQ29ubmVjdGVkEhoKCHJldmlzaW9uGAQgASgFUghyZX'
    'Zpc2lvbhIhCgxhZG9wdGVkX2Zyb20YBSABKAlSC2Fkb3B0ZWRGcm9tEh8KC2hhc19mYWN0b3J5'
    'GAYgASgIUgpoYXNGYWN0b3J5EiEKDHNhdmVfcGVuZGluZxgHIAEoCFILc2F2ZVBlbmRpbmcSFg'
    'oGbm90aWNlGAggASgJUgZub3RpY2U=');

@$core.Deprecated('Use columnSettingsRequestDescriptor instead')
const ColumnSettingsRequest$json = {
  '1': 'ColumnSettingsRequest',
  '2': [
    {'1': 'names', '3': 1, '4': 3, '5': 9, '10': 'names'},
  ],
};

/// Descriptor for `ColumnSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnSettingsRequestDescriptor =
    $convert.base64Decode(
        'ChVDb2x1bW5TZXR0aW5nc1JlcXVlc3QSFAoFbmFtZXMYASADKAlSBW5hbWVz');

@$core.Deprecated('Use columnSaveResponseDescriptor instead')
const ColumnSaveResponse$json = {
  '1': 'ColumnSaveResponse',
  '2': [
    {
      '1': 'outcome',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.settings.ColumnSaveOutcome',
      '10': 'outcome'
    },
    {'1': 'names', '3': 2, '4': 3, '5': 9, '10': 'names'},
    {
      '1': 'profile',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.settings.ColumnProfileResponse',
      '10': 'profile'
    },
  ],
};

/// Descriptor for `ColumnSaveResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnSaveResponseDescriptor = $convert.base64Decode(
    'ChJDb2x1bW5TYXZlUmVzcG9uc2USNQoHb3V0Y29tZRgBIAEoDjIbLnNldHRpbmdzLkNvbHVtbl'
    'NhdmVPdXRjb21lUgdvdXRjb21lEhQKBW5hbWVzGAIgAygJUgVuYW1lcxI5Cgdwcm9maWxlGAMg'
    'ASgLMh8uc2V0dGluZ3MuQ29sdW1uUHJvZmlsZVJlc3BvbnNlUgdwcm9maWxl');

@$core.Deprecated('Use writeColumnFactoryRequestDescriptor instead')
const WriteColumnFactoryRequest$json = {
  '1': 'WriteColumnFactoryRequest',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'source',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.settings.ColumnFactorySource',
      '10': 'source'
    },
  ],
};

/// Descriptor for `WriteColumnFactoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List writeColumnFactoryRequestDescriptor =
    $convert.base64Decode(
        'ChlXcml0ZUNvbHVtbkZhY3RvcnlSZXF1ZXN0EhAKA2tleRgBIAEoCVIDa2V5EjUKBnNvdXJjZR'
        'gCIAEoDjIdLnNldHRpbmdzLkNvbHVtbkZhY3RvcnlTb3VyY2VSBnNvdXJjZQ==');
