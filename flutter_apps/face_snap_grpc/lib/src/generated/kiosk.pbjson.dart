// This is a generated file - do not edit.
//
// Generated from kiosk.proto.

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

@$core.Deprecated('Use modelDescriptor instead')
const Model$json = {
  '1': 'Model',
  '2': [
    {'1': 'DLIB', '2': 0},
    {'1': 'FACENET512', '2': 1},
    {'1': 'SFACE', '2': 2},
  ],
};

/// Descriptor for `Model`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modelDescriptor = $convert.base64Decode(
    'CgVNb2RlbBIICgRETElCEAASDgoKRkFDRU5FVDUxMhABEgkKBVNGQUNFEAI=');

@$core.Deprecated('Use distanceMetricDescriptor instead')
const DistanceMetric$json = {
  '1': 'DistanceMetric',
  '2': [
    {'1': 'COSINE', '2': 0},
    {'1': 'EUCLIDEAN', '2': 1},
    {'1': 'EUCLIDEAN_L2', '2': 2},
  ],
};

/// Descriptor for `DistanceMetric`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List distanceMetricDescriptor = $convert.base64Decode(
    'Cg5EaXN0YW5jZU1ldHJpYxIKCgZDT1NJTkUQABINCglFVUNMSURFQU4QARIQCgxFVUNMSURFQU'
    '5fTDIQAg==');

@$core.Deprecated('Use statusTypeDescriptor instead')
const StatusType$json = {
  '1': 'StatusType',
  '2': [
    {'1': 'OK', '2': 0},
    {'1': 'ERROR', '2': 1},
    {'1': 'TIMEOUT', '2': 3},
    {'1': 'UNKNOWN', '2': 4},
  ],
};

/// Descriptor for `StatusType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List statusTypeDescriptor = $convert.base64Decode(
    'CgpTdGF0dXNUeXBlEgYKAk9LEAASCQoFRVJST1IQARILCgdUSU1FT1VUEAMSCwoHVU5LTk9XTh'
    'AE');

@$core.Deprecated('Use lapSubjectDescriptor instead')
const LapSubject$json = {
  '1': 'LapSubject',
  '2': [
    {'1': 'LAP_NONE', '2': 0},
    {'1': 'LAP_CHILD', '2': 1},
    {'1': 'LAP_BABY', '2': 2},
  ],
};

/// Descriptor for `LapSubject`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List lapSubjectDescriptor = $convert.base64Decode(
    'CgpMYXBTdWJqZWN0EgwKCExBUF9OT05FEAASDQoJTEFQX0NISUxEEAESDAoITEFQX0JBQlkQAg'
    '==');

@$core.Deprecated('Use instructionKindDescriptor instead')
const InstructionKind$json = {
  '1': 'InstructionKind',
  '2': [
    {'1': 'INSTRUCTION_UNKNOWN', '2': 0},
    {'1': 'TURN_LEFT', '2': 1},
    {'1': 'TURN_RIGHT', '2': 2},
    {'1': 'LOOK_STRAIGHT', '2': 3},
    {'1': 'DONE', '2': 4},
  ],
};

/// Descriptor for `InstructionKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List instructionKindDescriptor = $convert.base64Decode(
    'Cg9JbnN0cnVjdGlvbktpbmQSFwoTSU5TVFJVQ1RJT05fVU5LTk9XThAAEg0KCVRVUk5fTEVGVB'
    'ABEg4KClRVUk5fUklHSFQQAhIRCg1MT09LX1NUUkFJR0hUEAMSCAoERE9ORRAE');

@$core.Deprecated('Use checkKindDescriptor instead')
const CheckKind$json = {
  '1': 'CheckKind',
  '2': [
    {'1': 'CHECK_KIND_UNSPECIFIED', '2': 0},
    {'1': 'GATE', '2': 1},
    {'1': 'KIOSK_CHECK', '2': 2},
    {'1': 'LIVENESS', '2': 3},
    {'1': 'OFIQ', '2': 4},
    {'1': 'ICAO', '2': 5},
  ],
};

/// Descriptor for `CheckKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List checkKindDescriptor = $convert.base64Decode(
    'CglDaGVja0tpbmQSGgoWQ0hFQ0tfS0lORF9VTlNQRUNJRklFRBAAEggKBEdBVEUQARIPCgtLSU'
    '9TS19DSEVDSxACEgwKCExJVkVORVNTEAMSCAoET0ZJURAEEggKBElDQU8QBQ==');

@$core.Deprecated('Use checkVerdictDescriptor instead')
const CheckVerdict$json = {
  '1': 'CheckVerdict',
  '2': [
    {'1': 'VERDICT_UNSPECIFIED', '2': 0},
    {'1': 'PASSED', '2': 1},
    {'1': 'FAILED', '2': 2},
    {'1': 'NOT_CHECKED', '2': 3},
  ],
};

/// Descriptor for `CheckVerdict`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List checkVerdictDescriptor = $convert.base64Decode(
    'CgxDaGVja1ZlcmRpY3QSFwoTVkVSRElDVF9VTlNQRUNJRklFRBAAEgoKBlBBU1NFRBABEgoKBk'
    'ZBSUxFRBACEg8KC05PVF9DSEVDS0VEEAM=');

@$core.Deprecated('Use previewRequestDescriptor instead')
const PreviewRequest$json = {
  '1': 'PreviewRequest',
  '2': [
    {'1': 'camera_index', '3': 1, '4': 1, '5': 5, '10': 'cameraIndex'},
    {'1': 'max_seconds', '3': 2, '4': 1, '5': 5, '10': 'maxSeconds'},
  ],
};

/// Descriptor for `PreviewRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewRequestDescriptor = $convert.base64Decode(
    'Cg5QcmV2aWV3UmVxdWVzdBIhCgxjYW1lcmFfaW5kZXgYASABKAVSC2NhbWVyYUluZGV4Eh8KC2'
    '1heF9zZWNvbmRzGAIgASgFUgptYXhTZWNvbmRz');

@$core.Deprecated('Use ledMixDescriptor instead')
const LedMix$json = {
  '1': 'LedMix',
  '2': [
    {'1': 'red', '3': 1, '4': 1, '5': 5, '10': 'red'},
    {'1': 'green', '3': 2, '4': 1, '5': 5, '10': 'green'},
    {'1': 'blue', '3': 3, '4': 1, '5': 5, '10': 'blue'},
  ],
};

/// Descriptor for `LedMix`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ledMixDescriptor = $convert.base64Decode(
    'CgZMZWRNaXgSEAoDcmVkGAEgASgFUgNyZWQSFAoFZ3JlZW4YAiABKAVSBWdyZWVuEhIKBGJsdW'
    'UYAyABKAVSBGJsdWU=');

@$core.Deprecated('Use colourCardRequestDescriptor instead')
const ColourCardRequest$json = {
  '1': 'ColourCardRequest',
  '2': [
    {'1': 'light', '3': 1, '4': 1, '5': 9, '10': 'light'},
    {'1': 'camera', '3': 2, '4': 1, '5': 5, '10': 'camera'},
    {'1': 'card', '3': 3, '4': 1, '5': 9, '10': 'card'},
    {
      '1': 'led_mix',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.kiosk.LedMix',
      '9': 0,
      '10': 'ledMix',
      '17': true
    },
    {
      '1': 'white_balance',
      '3': 5,
      '4': 1,
      '5': 5,
      '9': 1,
      '10': 'whiteBalance',
      '17': true
    },
    {
      '1': 'exposure',
      '3': 6,
      '4': 1,
      '5': 5,
      '9': 2,
      '10': 'exposure',
      '17': true
    },
  ],
  '8': [
    {'1': '_led_mix'},
    {'1': '_white_balance'},
    {'1': '_exposure'},
  ],
};

/// Descriptor for `ColourCardRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colourCardRequestDescriptor = $convert.base64Decode(
    'ChFDb2xvdXJDYXJkUmVxdWVzdBIUCgVsaWdodBgBIAEoCVIFbGlnaHQSFgoGY2FtZXJhGAIgAS'
    'gFUgZjYW1lcmESEgoEY2FyZBgDIAEoCVIEY2FyZBIrCgdsZWRfbWl4GAQgASgLMg0ua2lvc2su'
    'TGVkTWl4SABSBmxlZE1peIgBARIoCg13aGl0ZV9iYWxhbmNlGAUgASgFSAFSDHdoaXRlQmFsYW'
    '5jZYgBARIfCghleHBvc3VyZRgGIAEoBUgCUghleHBvc3VyZYgBAUIKCghfbGVkX21peEIQCg5f'
    'd2hpdGVfYmFsYW5jZUILCglfZXhwb3N1cmU=');

@$core.Deprecated('Use colourPatchDescriptor instead')
const ColourPatch$json = {
  '1': 'ColourPatch',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'r', '3': 2, '4': 1, '5': 1, '10': 'r'},
    {'1': 'g', '3': 3, '4': 1, '5': 1, '10': 'g'},
    {'1': 'b', '3': 4, '4': 1, '5': 1, '10': 'b'},
    {'1': 'clipped', '3': 5, '4': 1, '5': 8, '10': 'clipped'},
    {'1': 'x', '3': 6, '4': 1, '5': 1, '10': 'x'},
    {'1': 'y', '3': 7, '4': 1, '5': 1, '10': 'y'},
  ],
};

/// Descriptor for `ColourPatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colourPatchDescriptor = $convert.base64Decode(
    'CgtDb2xvdXJQYXRjaBIOCgJpZBgBIAEoCVICaWQSDAoBchgCIAEoAVIBchIMCgFnGAMgASgBUg'
    'FnEgwKAWIYBCABKAFSAWISGAoHY2xpcHBlZBgFIAEoCFIHY2xpcHBlZBIMCgF4GAYgASgBUgF4'
    'EgwKAXkYByABKAFSAXk=');

@$core.Deprecated('Use colourCardResponseDescriptor instead')
const ColourCardResponse$json = {
  '1': 'ColourCardResponse',
  '2': [
    {'1': 'found', '3': 1, '4': 1, '5': 8, '10': 'found'},
    {
      '1': 'patches',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.kiosk.ColourPatch',
      '10': 'patches'
    },
    {'1': 'patch_size_px', '3': 3, '4': 1, '5': 1, '10': 'patchSizePx'},
    {'1': 'exposure', '3': 4, '4': 1, '5': 5, '10': 'exposure'},
    {'1': 'camera', '3': 5, '4': 1, '5': 5, '10': 'camera'},
    {'1': 'photo', '3': 6, '4': 1, '5': 12, '10': 'photo'},
    {'1': 'note', '3': 7, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `ColourCardResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colourCardResponseDescriptor = $convert.base64Decode(
    'ChJDb2xvdXJDYXJkUmVzcG9uc2USFAoFZm91bmQYASABKAhSBWZvdW5kEiwKB3BhdGNoZXMYAi'
    'ADKAsyEi5raW9zay5Db2xvdXJQYXRjaFIHcGF0Y2hlcxIiCg1wYXRjaF9zaXplX3B4GAMgASgB'
    'UgtwYXRjaFNpemVQeBIaCghleHBvc3VyZRgEIAEoBVIIZXhwb3N1cmUSFgoGY2FtZXJhGAUgAS'
    'gFUgZjYW1lcmESFAoFcGhvdG8YBiABKAxSBXBob3RvEhIKBG5vdGUYByABKAlSBG5vdGU=');

@$core.Deprecated('Use faceRecognitionRequestDescriptor instead')
const FaceRecognitionRequest$json = {
  '1': 'FaceRecognitionRequest',
  '2': [
    {'1': 'image1', '3': 1, '4': 1, '5': 12, '10': 'image1'},
    {'1': 'image2', '3': 2, '4': 1, '5': 12, '10': 'image2'},
    {'1': 'threshold', '3': 3, '4': 1, '5': 1, '10': 'threshold'},
    {'1': 'model', '3': 4, '4': 1, '5': 14, '6': '.kiosk.Model', '10': 'model'},
    {
      '1': 'similarity_metric',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.kiosk.DistanceMetric',
      '10': 'similarityMetric'
    },
  ],
};

/// Descriptor for `FaceRecognitionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List faceRecognitionRequestDescriptor = $convert.base64Decode(
    'ChZGYWNlUmVjb2duaXRpb25SZXF1ZXN0EhYKBmltYWdlMRgBIAEoDFIGaW1hZ2UxEhYKBmltYW'
    'dlMhgCIAEoDFIGaW1hZ2UyEhwKCXRocmVzaG9sZBgDIAEoAVIJdGhyZXNob2xkEiIKBW1vZGVs'
    'GAQgASgOMgwua2lvc2suTW9kZWxSBW1vZGVsEkIKEXNpbWlsYXJpdHlfbWV0cmljGAUgASgOMh'
    'Uua2lvc2suRGlzdGFuY2VNZXRyaWNSEHNpbWlsYXJpdHlNZXRyaWM=');

@$core.Deprecated('Use faceRecognitionResponseDescriptor instead')
const FaceRecognitionResponse$json = {
  '1': 'FaceRecognitionResponse',
  '2': [
    {'1': 'verified', '3': 1, '4': 1, '5': 8, '10': 'verified'},
    {'1': 'distance', '3': 2, '4': 1, '5': 1, '10': 'distance'},
    {'1': 'threshold', '3': 3, '4': 1, '5': 1, '10': 'threshold'},
    {'1': 'model', '3': 4, '4': 1, '5': 14, '6': '.kiosk.Model', '10': 'model'},
    {
      '1': 'similarity_metric',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.kiosk.DistanceMetric',
      '10': 'similarityMetric'
    },
    {'1': 'time', '3': 6, '4': 1, '5': 1, '10': 'time'},
    {
      '1': 'status',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.kiosk.StatusType',
      '10': 'status'
    },
  ],
};

/// Descriptor for `FaceRecognitionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List faceRecognitionResponseDescriptor = $convert.base64Decode(
    'ChdGYWNlUmVjb2duaXRpb25SZXNwb25zZRIaCgh2ZXJpZmllZBgBIAEoCFIIdmVyaWZpZWQSGg'
    'oIZGlzdGFuY2UYAiABKAFSCGRpc3RhbmNlEhwKCXRocmVzaG9sZBgDIAEoAVIJdGhyZXNob2xk'
    'EiIKBW1vZGVsGAQgASgOMgwua2lvc2suTW9kZWxSBW1vZGVsEkIKEXNpbWlsYXJpdHlfbWV0cm'
    'ljGAUgASgOMhUua2lvc2suRGlzdGFuY2VNZXRyaWNSEHNpbWlsYXJpdHlNZXRyaWMSEgoEdGlt'
    'ZRgGIAEoAVIEdGltZRIpCgZzdGF0dXMYByABKA4yES5raW9zay5TdGF0dXNUeXBlUgZzdGF0dX'
    'M=');

@$core.Deprecated('Use kioskInfoResponseDescriptor instead')
const KioskInfoResponse$json = {
  '1': 'KioskInfoResponse',
  '2': [
    {
      '1': 'kioskInfo',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.kiosk.KioskInfo',
      '10': 'kioskInfo'
    },
    {
      '1': 'cameraInfo',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.kiosk.CameraInfo',
      '10': 'cameraInfo'
    },
  ],
};

/// Descriptor for `KioskInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List kioskInfoResponseDescriptor = $convert.base64Decode(
    'ChFLaW9za0luZm9SZXNwb25zZRIuCglraW9za0luZm8YASABKAsyEC5raW9zay5LaW9za0luZm'
    '9SCWtpb3NrSW5mbxIxCgpjYW1lcmFJbmZvGAIgAygLMhEua2lvc2suQ2FtZXJhSW5mb1IKY2Ft'
    'ZXJhSW5mbw==');

@$core.Deprecated('Use kioskInfoDescriptor instead')
const KioskInfo$json = {
  '1': 'KioskInfo',
  '2': [
    {'1': 'serverIpAddress', '3': 1, '4': 1, '5': 9, '10': 'serverIpAddress'},
    {'1': 'port', '3': 2, '4': 1, '5': 9, '10': 'port'},
    {'1': 'numberOfCameras', '3': 3, '4': 1, '5': 5, '10': 'numberOfCameras'},
  ],
};

/// Descriptor for `KioskInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List kioskInfoDescriptor = $convert.base64Decode(
    'CglLaW9za0luZm8SKAoPc2VydmVySXBBZGRyZXNzGAEgASgJUg9zZXJ2ZXJJcEFkZHJlc3MSEg'
    'oEcG9ydBgCIAEoCVIEcG9ydBIoCg9udW1iZXJPZkNhbWVyYXMYAyABKAVSD251bWJlck9mQ2Ft'
    'ZXJhcw==');

@$core.Deprecated('Use cameraInfoDescriptor instead')
const CameraInfo$json = {
  '1': 'CameraInfo',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
  ],
};

/// Descriptor for `CameraInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraInfoDescriptor =
    $convert.base64Decode('CgpDYW1lcmFJbmZvEhQKBWluZGV4GAEgASgFUgVpbmRleA==');

@$core.Deprecated('Use processStepStatusDescriptor instead')
const ProcessStepStatus$json = {
  '1': 'ProcessStepStatus',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'status',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.kiosk.StatusType',
      '10': 'status'
    },
  ],
};

/// Descriptor for `ProcessStepStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List processStepStatusDescriptor = $convert.base64Decode(
    'ChFQcm9jZXNzU3RlcFN0YXR1cxIUCgVpbmRleBgBIAEoBVIFaW5kZXgSIAoLZGVzY3JpcHRpb2'
    '4YAiABKAlSC2Rlc2NyaXB0aW9uEikKBnN0YXR1cxgDIAEoDjIRLmtpb3NrLlN0YXR1c1R5cGVS'
    'BnN0YXR1cw==');

@$core.Deprecated('Use processImageDataDescriptor instead')
const ProcessImageData$json = {
  '1': 'ProcessImageData',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {'1': 'width', '3': 2, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 3, '4': 1, '5': 5, '10': 'height'},
    {'1': 'format', '3': 4, '4': 1, '5': 9, '10': 'format'},
    {'1': 'chunk_data', '3': 5, '4': 1, '5': 12, '10': 'chunkData'},
  ],
};

/// Descriptor for `ProcessImageData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List processImageDataDescriptor = $convert.base64Decode(
    'ChBQcm9jZXNzSW1hZ2VEYXRhEhQKBWluZGV4GAEgASgFUgVpbmRleBIUCgV3aWR0aBgCIAEoBV'
    'IFd2lkdGgSFgoGaGVpZ2h0GAMgASgFUgZoZWlnaHQSFgoGZm9ybWF0GAQgASgJUgZmb3JtYXQS'
    'HQoKY2h1bmtfZGF0YRgFIAEoDFIJY2h1bmtEYXRh');

@$core.Deprecated('Use captureRequestDescriptor instead')
const CaptureRequest$json = {
  '1': 'CaptureRequest',
  '2': [
    {
      '1': 'settings',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.kiosk.CaptureSettings',
      '10': 'settings'
    },
  ],
};

/// Descriptor for `CaptureRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureRequestDescriptor = $convert.base64Decode(
    'Cg5DYXB0dXJlUmVxdWVzdBIyCghzZXR0aW5ncxgBIAEoCzIWLmtpb3NrLkNhcHR1cmVTZXR0aW'
    '5nc1IIc2V0dGluZ3M=');

@$core.Deprecated('Use captureSettingsDescriptor instead')
const CaptureSettings$json = {
  '1': 'CaptureSettings',
  '2': [
    {
      '1': 'photo_format',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'photoFormat',
      '17': true
    },
    {'1': 'crop', '3': 2, '4': 1, '5': 8, '9': 1, '10': 'crop', '17': true},
    {
      '1': 'crop_width',
      '3': 3,
      '4': 1,
      '5': 5,
      '9': 2,
      '10': 'cropWidth',
      '17': true
    },
    {
      '1': 'jpeg_quality',
      '3': 4,
      '4': 1,
      '5': 5,
      '9': 3,
      '10': 'jpegQuality',
      '17': true
    },
    {
      '1': 'background_method',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'backgroundMethod',
      '17': true
    },
    {
      '1': 'background_color',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 5,
      '10': 'backgroundColor',
      '17': true
    },
    {
      '1': 'background_strength',
      '3': 7,
      '4': 1,
      '5': 5,
      '9': 6,
      '10': 'backgroundStrength',
      '17': true
    },
    {
      '1': 'glare_free_light',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 7,
      '10': 'glareFreeLight',
      '17': true
    },
    {
      '1': 'photo_light',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 8,
      '10': 'photoLight',
      '17': true
    },
    {
      '1': 'leds_off_for_photo',
      '3': 10,
      '4': 1,
      '5': 8,
      '9': 9,
      '10': 'ledsOffForPhoto',
      '17': true
    },
    {
      '1': 'eyes_check',
      '3': 11,
      '4': 1,
      '5': 8,
      '9': 10,
      '10': 'eyesCheck',
      '17': true
    },
    {
      '1': 'lips_check',
      '3': 12,
      '4': 1,
      '5': 8,
      '9': 11,
      '10': 'lipsCheck',
      '17': true
    },
    {
      '1': 'eye_glasses_check',
      '3': 13,
      '4': 1,
      '5': 8,
      '9': 12,
      '10': 'eyeGlassesCheck',
      '17': true
    },
    {
      '1': 'head_pose_check',
      '3': 14,
      '4': 1,
      '5': 8,
      '9': 13,
      '10': 'headPoseCheck',
      '17': true
    },
    {
      '1': 'sharpness_check',
      '3': 15,
      '4': 1,
      '5': 8,
      '9': 14,
      '10': 'sharpnessCheck',
      '17': true
    },
    {
      '1': 'red_eye_detection_check',
      '3': 16,
      '4': 1,
      '5': 8,
      '9': 15,
      '10': 'redEyeDetectionCheck',
      '17': true
    },
    {
      '1': 'head_size_check',
      '3': 17,
      '4': 1,
      '5': 8,
      '9': 16,
      '10': 'headSizeCheck',
      '17': true
    },
    {
      '1': 'expression_check',
      '3': 18,
      '4': 1,
      '5': 8,
      '9': 17,
      '10': 'expressionCheck',
      '17': true
    },
    {
      '1': 'gaze_check',
      '3': 19,
      '4': 1,
      '5': 8,
      '9': 18,
      '10': 'gazeCheck',
      '17': true
    },
    {
      '1': 'lighting_evenness_check',
      '3': 20,
      '4': 1,
      '5': 8,
      '9': 19,
      '10': 'lightingEvennessCheck',
      '17': true
    },
    {
      '1': 'ofiq_checks',
      '3': 21,
      '4': 1,
      '5': 8,
      '9': 20,
      '10': 'ofiqChecks',
      '17': true
    },
    {
      '1': 'icao_report',
      '3': 22,
      '4': 1,
      '5': 8,
      '9': 21,
      '10': 'icaoReport',
      '17': true
    },
    {
      '1': 'liveness_check',
      '3': 23,
      '4': 1,
      '5': 8,
      '9': 22,
      '10': 'livenessCheck',
      '17': true
    },
    {
      '1': 'liveness_head_turn_check',
      '3': 24,
      '4': 1,
      '5': 8,
      '9': 23,
      '10': 'livenessHeadTurnCheck',
      '17': true
    },
    {
      '1': 'distance_min',
      '3': 25,
      '4': 1,
      '5': 5,
      '9': 24,
      '10': 'distanceMin',
      '17': true
    },
    {
      '1': 'distance_max',
      '3': 26,
      '4': 1,
      '5': 5,
      '9': 25,
      '10': 'distanceMax',
      '17': true
    },
    {
      '1': 'colour_correction',
      '3': 27,
      '4': 1,
      '5': 8,
      '9': 26,
      '10': 'colourCorrection',
      '17': true
    },
    {
      '1': 'lap',
      '3': 28,
      '4': 1,
      '5': 14,
      '6': '.kiosk.LapSubject',
      '9': 27,
      '10': 'lap',
      '17': true
    },
  ],
  '8': [
    {'1': '_photo_format'},
    {'1': '_crop'},
    {'1': '_crop_width'},
    {'1': '_jpeg_quality'},
    {'1': '_background_method'},
    {'1': '_background_color'},
    {'1': '_background_strength'},
    {'1': '_glare_free_light'},
    {'1': '_photo_light'},
    {'1': '_leds_off_for_photo'},
    {'1': '_eyes_check'},
    {'1': '_lips_check'},
    {'1': '_eye_glasses_check'},
    {'1': '_head_pose_check'},
    {'1': '_sharpness_check'},
    {'1': '_red_eye_detection_check'},
    {'1': '_head_size_check'},
    {'1': '_expression_check'},
    {'1': '_gaze_check'},
    {'1': '_lighting_evenness_check'},
    {'1': '_ofiq_checks'},
    {'1': '_icao_report'},
    {'1': '_liveness_check'},
    {'1': '_liveness_head_turn_check'},
    {'1': '_distance_min'},
    {'1': '_distance_max'},
    {'1': '_colour_correction'},
    {'1': '_lap'},
  ],
};

/// Descriptor for `CaptureSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureSettingsDescriptor = $convert.base64Decode(
    'Cg9DYXB0dXJlU2V0dGluZ3MSJgoMcGhvdG9fZm9ybWF0GAEgASgJSABSC3Bob3RvRm9ybWF0iA'
    'EBEhcKBGNyb3AYAiABKAhIAVIEY3JvcIgBARIiCgpjcm9wX3dpZHRoGAMgASgFSAJSCWNyb3BX'
    'aWR0aIgBARImCgxqcGVnX3F1YWxpdHkYBCABKAVIA1ILanBlZ1F1YWxpdHmIAQESMAoRYmFja2'
    'dyb3VuZF9tZXRob2QYBSABKAlIBFIQYmFja2dyb3VuZE1ldGhvZIgBARIuChBiYWNrZ3JvdW5k'
    'X2NvbG9yGAYgASgJSAVSD2JhY2tncm91bmRDb2xvcogBARI0ChNiYWNrZ3JvdW5kX3N0cmVuZ3'
    'RoGAcgASgFSAZSEmJhY2tncm91bmRTdHJlbmd0aIgBARItChBnbGFyZV9mcmVlX2xpZ2h0GAgg'
    'ASgJSAdSDmdsYXJlRnJlZUxpZ2h0iAEBEiQKC3Bob3RvX2xpZ2h0GAkgASgJSAhSCnBob3RvTG'
    'lnaHSIAQESMAoSbGVkc19vZmZfZm9yX3Bob3RvGAogASgISAlSD2xlZHNPZmZGb3JQaG90b4gB'
    'ARIiCgpleWVzX2NoZWNrGAsgASgISApSCWV5ZXNDaGVja4gBARIiCgpsaXBzX2NoZWNrGAwgAS'
    'gISAtSCWxpcHNDaGVja4gBARIvChFleWVfZ2xhc3Nlc19jaGVjaxgNIAEoCEgMUg9leWVHbGFz'
    'c2VzQ2hlY2uIAQESKwoPaGVhZF9wb3NlX2NoZWNrGA4gASgISA1SDWhlYWRQb3NlQ2hlY2uIAQ'
    'ESLAoPc2hhcnBuZXNzX2NoZWNrGA8gASgISA5SDnNoYXJwbmVzc0NoZWNriAEBEjoKF3JlZF9l'
    'eWVfZGV0ZWN0aW9uX2NoZWNrGBAgASgISA9SFHJlZEV5ZURldGVjdGlvbkNoZWNriAEBEisKD2'
    'hlYWRfc2l6ZV9jaGVjaxgRIAEoCEgQUg1oZWFkU2l6ZUNoZWNriAEBEi4KEGV4cHJlc3Npb25f'
    'Y2hlY2sYEiABKAhIEVIPZXhwcmVzc2lvbkNoZWNriAEBEiIKCmdhemVfY2hlY2sYEyABKAhIEl'
    'IJZ2F6ZUNoZWNriAEBEjsKF2xpZ2h0aW5nX2V2ZW5uZXNzX2NoZWNrGBQgASgISBNSFWxpZ2h0'
    'aW5nRXZlbm5lc3NDaGVja4gBARIkCgtvZmlxX2NoZWNrcxgVIAEoCEgUUgpvZmlxQ2hlY2tziA'
    'EBEiQKC2ljYW9fcmVwb3J0GBYgASgISBVSCmljYW9SZXBvcnSIAQESKgoObGl2ZW5lc3NfY2hl'
    'Y2sYFyABKAhIFlINbGl2ZW5lc3NDaGVja4gBARI8ChhsaXZlbmVzc19oZWFkX3R1cm5fY2hlY2'
    'sYGCABKAhIF1IVbGl2ZW5lc3NIZWFkVHVybkNoZWNriAEBEiYKDGRpc3RhbmNlX21pbhgZIAEo'
    'BUgYUgtkaXN0YW5jZU1pbogBARImCgxkaXN0YW5jZV9tYXgYGiABKAVIGVILZGlzdGFuY2VNYX'
    'iIAQESMAoRY29sb3VyX2NvcnJlY3Rpb24YGyABKAhIGlIQY29sb3VyQ29ycmVjdGlvbogBARIo'
    'CgNsYXAYHCABKA4yES5raW9zay5MYXBTdWJqZWN0SBtSA2xhcIgBAUIPCg1fcGhvdG9fZm9ybW'
    'F0QgcKBV9jcm9wQg0KC19jcm9wX3dpZHRoQg8KDV9qcGVnX3F1YWxpdHlCFAoSX2JhY2tncm91'
    'bmRfbWV0aG9kQhMKEV9iYWNrZ3JvdW5kX2NvbG9yQhYKFF9iYWNrZ3JvdW5kX3N0cmVuZ3RoQh'
    'MKEV9nbGFyZV9mcmVlX2xpZ2h0Qg4KDF9waG90b19saWdodEIVChNfbGVkc19vZmZfZm9yX3Bo'
    'b3RvQg0KC19leWVzX2NoZWNrQg0KC19saXBzX2NoZWNrQhQKEl9leWVfZ2xhc3Nlc19jaGVja0'
    'ISChBfaGVhZF9wb3NlX2NoZWNrQhIKEF9zaGFycG5lc3NfY2hlY2tCGgoYX3JlZF9leWVfZGV0'
    'ZWN0aW9uX2NoZWNrQhIKEF9oZWFkX3NpemVfY2hlY2tCEwoRX2V4cHJlc3Npb25fY2hlY2tCDQ'
    'oLX2dhemVfY2hlY2tCGgoYX2xpZ2h0aW5nX2V2ZW5uZXNzX2NoZWNrQg4KDF9vZmlxX2NoZWNr'
    'c0IOCgxfaWNhb19yZXBvcnRCEQoPX2xpdmVuZXNzX2NoZWNrQhsKGV9saXZlbmVzc19oZWFkX3'
    'R1cm5fY2hlY2tCDwoNX2Rpc3RhbmNlX21pbkIPCg1fZGlzdGFuY2VfbWF4QhQKEl9jb2xvdXJf'
    'Y29ycmVjdGlvbkIGCgRfbGFw');

@$core.Deprecated('Use captureSettingsUsedDescriptor instead')
const CaptureSettingsUsed$json = {
  '1': 'CaptureSettingsUsed',
  '2': [
    {
      '1': 'values',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.kiosk.CaptureSettings',
      '10': 'values'
    },
    {'1': 'overridden', '3': 2, '4': 3, '5': 9, '10': 'overridden'},
  ],
};

/// Descriptor for `CaptureSettingsUsed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List captureSettingsUsedDescriptor = $convert.base64Decode(
    'ChNDYXB0dXJlU2V0dGluZ3NVc2VkEi4KBnZhbHVlcxgBIAEoCzIWLmtpb3NrLkNhcHR1cmVTZX'
    'R0aW5nc1IGdmFsdWVzEh4KCm92ZXJyaWRkZW4YAiADKAlSCm92ZXJyaWRkZW4=');

@$core.Deprecated('Use processAutomaticResponseDescriptor instead')
const ProcessAutomaticResponse$json = {
  '1': 'ProcessAutomaticResponse',
  '2': [
    {
      '1': 'processStatus',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.kiosk.ProcessStepStatus',
      '9': 0,
      '10': 'processStatus'
    },
    {
      '1': 'imageData',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.kiosk.ProcessImageData',
      '9': 0,
      '10': 'imageData'
    },
    {
      '1': 'checkResult',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.kiosk.CheckResult',
      '9': 0,
      '10': 'checkResult'
    },
    {
      '1': 'instruction',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.kiosk.Instruction',
      '9': 0,
      '10': 'instruction'
    },
    {
      '1': 'settings_used',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.kiosk.CaptureSettingsUsed',
      '9': 0,
      '10': 'settingsUsed'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `ProcessAutomaticResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List processAutomaticResponseDescriptor = $convert.base64Decode(
    'ChhQcm9jZXNzQXV0b21hdGljUmVzcG9uc2USQAoNcHJvY2Vzc1N0YXR1cxgBIAEoCzIYLmtpb3'
    'NrLlByb2Nlc3NTdGVwU3RhdHVzSABSDXByb2Nlc3NTdGF0dXMSNwoJaW1hZ2VEYXRhGAIgASgL'
    'Mhcua2lvc2suUHJvY2Vzc0ltYWdlRGF0YUgAUglpbWFnZURhdGESNgoLY2hlY2tSZXN1bHQYAy'
    'ABKAsyEi5raW9zay5DaGVja1Jlc3VsdEgAUgtjaGVja1Jlc3VsdBI2CgtpbnN0cnVjdGlvbhgE'
    'IAEoCzISLmtpb3NrLkluc3RydWN0aW9uSABSC2luc3RydWN0aW9uEkEKDXNldHRpbmdzX3VzZW'
    'QYBSABKAsyGi5raW9zay5DYXB0dXJlU2V0dGluZ3NVc2VkSABSDHNldHRpbmdzVXNlZEIICgZy'
    'ZXN1bHQ=');

@$core.Deprecated('Use instructionDescriptor instead')
const Instruction$json = {
  '1': 'Instruction',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.kiosk.InstructionKind',
      '10': 'kind'
    },
    {'1': 'progress', '3': 3, '4': 1, '5': 2, '10': 'progress'},
    {'1': 'repeat', '3': 4, '4': 1, '5': 8, '10': 'repeat'},
    {'1': 'seconds_left', '3': 5, '4': 1, '5': 2, '10': 'secondsLeft'},
    {'1': 'text', '3': 6, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `Instruction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List instructionDescriptor = $convert.base64Decode(
    'CgtJbnN0cnVjdGlvbhIUCgVpbmRleBgBIAEoBVIFaW5kZXgSKgoEa2luZBgCIAEoDjIWLmtpb3'
    'NrLkluc3RydWN0aW9uS2luZFIEa2luZBIaCghwcm9ncmVzcxgDIAEoAlIIcHJvZ3Jlc3MSFgoG'
    'cmVwZWF0GAQgASgIUgZyZXBlYXQSIQoMc2Vjb25kc19sZWZ0GAUgASgCUgtzZWNvbmRzTGVmdB'
    'ISCgR0ZXh0GAYgASgJUgR0ZXh0');

@$core.Deprecated('Use checkResultDescriptor instead')
const CheckResult$json = {
  '1': 'CheckResult',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.kiosk.CheckKind',
      '10': 'kind'
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'verdict',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.kiosk.CheckVerdict',
      '10': 'verdict'
    },
    {'1': 'gates_photo', '3': 5, '4': 1, '5': 8, '10': 'gatesPhoto'},
    {'1': 'value', '3': 6, '4': 1, '5': 1, '9': 0, '10': 'value', '17': true},
    {'1': 'min', '3': 7, '4': 1, '5': 1, '9': 1, '10': 'min', '17': true},
    {'1': 'max', '3': 8, '4': 1, '5': 1, '9': 2, '10': 'max', '17': true},
    {'1': 'unit', '3': 9, '4': 1, '5': 9, '10': 'unit'},
    {'1': 'description', '3': 10, '4': 1, '5': 9, '10': 'description'},
  ],
  '8': [
    {'1': '_value'},
    {'1': '_min'},
    {'1': '_max'},
  ],
};

/// Descriptor for `CheckResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkResultDescriptor = $convert.base64Decode(
    'CgtDaGVja1Jlc3VsdBIUCgVpbmRleBgBIAEoBVIFaW5kZXgSJAoEa2luZBgCIAEoDjIQLmtpb3'
    'NrLkNoZWNrS2luZFIEa2luZBISCgRuYW1lGAMgASgJUgRuYW1lEi0KB3ZlcmRpY3QYBCABKA4y'
    'Ey5raW9zay5DaGVja1ZlcmRpY3RSB3ZlcmRpY3QSHwoLZ2F0ZXNfcGhvdG8YBSABKAhSCmdhdG'
    'VzUGhvdG8SGQoFdmFsdWUYBiABKAFIAFIFdmFsdWWIAQESFQoDbWluGAcgASgBSAFSA21pbogB'
    'ARIVCgNtYXgYCCABKAFIAlIDbWF4iAEBEhIKBHVuaXQYCSABKAlSBHVuaXQSIAoLZGVzY3JpcH'
    'Rpb24YCiABKAlSC2Rlc2NyaXB0aW9uQggKBl92YWx1ZUIGCgRfbWluQgYKBF9tYXg=');

@$core.Deprecated('Use processManualResponseDescriptor instead')
const ProcessManualResponse$json = {
  '1': 'ProcessManualResponse',
  '2': [
    {
      '1': 'processStatus',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.kiosk.ProcessStepStatus',
      '9': 0,
      '10': 'processStatus'
    },
    {
      '1': 'imageData',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.kiosk.ProcessImageData',
      '9': 0,
      '10': 'imageData'
    },
    {
      '1': 'settings_used',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.kiosk.CaptureSettingsUsed',
      '9': 0,
      '10': 'settingsUsed'
    },
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `ProcessManualResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List processManualResponseDescriptor = $convert.base64Decode(
    'ChVQcm9jZXNzTWFudWFsUmVzcG9uc2USQAoNcHJvY2Vzc1N0YXR1cxgBIAEoCzIYLmtpb3NrLl'
    'Byb2Nlc3NTdGVwU3RhdHVzSABSDXByb2Nlc3NTdGF0dXMSNwoJaW1hZ2VEYXRhGAIgASgLMhcu'
    'a2lvc2suUHJvY2Vzc0ltYWdlRGF0YUgAUglpbWFnZURhdGESQQoNc2V0dGluZ3NfdXNlZBgDIA'
    'EoCzIaLmtpb3NrLkNhcHR1cmVTZXR0aW5nc1VzZWRIAFIMc2V0dGluZ3NVc2VkQggKBnJlc3Vs'
    'dA==');

@$core.Deprecated('Use focusedCameraRequestDescriptor instead')
const FocusedCameraRequest$json = {
  '1': 'FocusedCameraRequest',
  '2': [
    {'1': 'timeoutInMs', '3': 1, '4': 1, '5': 5, '10': 'timeoutInMs'},
  ],
};

/// Descriptor for `FocusedCameraRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List focusedCameraRequestDescriptor = $convert.base64Decode(
    'ChRGb2N1c2VkQ2FtZXJhUmVxdWVzdBIgCgt0aW1lb3V0SW5NcxgBIAEoBVILdGltZW91dEluTX'
    'M=');

@$core.Deprecated('Use focusedCameraResponseDescriptor instead')
const FocusedCameraResponse$json = {
  '1': 'FocusedCameraResponse',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.kiosk.StatusType',
      '10': 'status'
    },
  ],
};

/// Descriptor for `FocusedCameraResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List focusedCameraResponseDescriptor = $convert.base64Decode(
    'ChVGb2N1c2VkQ2FtZXJhUmVzcG9uc2USFAoFaW5kZXgYASABKAVSBWluZGV4EikKBnN0YXR1cx'
    'gCIAEoDjIRLmtpb3NrLlN0YXR1c1R5cGVSBnN0YXR1cw==');

@$core.Deprecated('Use highResImageRequestDescriptor instead')
const HighResImageRequest$json = {
  '1': 'HighResImageRequest',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {'1': 'timeoutInMs', '3': 2, '4': 1, '5': 5, '10': 'timeoutInMs'},
  ],
};

/// Descriptor for `HighResImageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List highResImageRequestDescriptor = $convert.base64Decode(
    'ChNIaWdoUmVzSW1hZ2VSZXF1ZXN0EhQKBWluZGV4GAEgASgFUgVpbmRleBIgCgt0aW1lb3V0SW'
    '5NcxgCIAEoBVILdGltZW91dEluTXM=');

@$core.Deprecated('Use highResImageResponseDescriptor instead')
const HighResImageResponse$json = {
  '1': 'HighResImageResponse',
  '2': [
    {
      '1': 'processImageData',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.kiosk.ProcessImageData',
      '10': 'processImageData'
    },
    {
      '1': 'statusType',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.kiosk.StatusType',
      '10': 'statusType'
    },
    {
      '1': 'checks',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.kiosk.CheckResult',
      '10': 'checks'
    },
  ],
};

/// Descriptor for `HighResImageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List highResImageResponseDescriptor = $convert.base64Decode(
    'ChRIaWdoUmVzSW1hZ2VSZXNwb25zZRJDChBwcm9jZXNzSW1hZ2VEYXRhGAEgASgLMhcua2lvc2'
    'suUHJvY2Vzc0ltYWdlRGF0YVIQcHJvY2Vzc0ltYWdlRGF0YRIxCgpzdGF0dXNUeXBlGAIgASgO'
    'MhEua2lvc2suU3RhdHVzVHlwZVIKc3RhdHVzVHlwZRIqCgZjaGVja3MYAyADKAsyEi5raW9zay'
    '5DaGVja1Jlc3VsdFIGY2hlY2tz');

@$core.Deprecated('Use highResIcaoImageRequestDescriptor instead')
const HighResIcaoImageRequest$json = {
  '1': 'HighResIcaoImageRequest',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {'1': 'timeoutInMs', '3': 2, '4': 1, '5': 5, '10': 'timeoutInMs'},
    {'1': 'eyesCheck', '3': 3, '4': 1, '5': 8, '10': 'eyesCheck'},
    {'1': 'lipsCheck', '3': 4, '4': 1, '5': 8, '10': 'lipsCheck'},
  ],
};

/// Descriptor for `HighResIcaoImageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List highResIcaoImageRequestDescriptor = $convert.base64Decode(
    'ChdIaWdoUmVzSWNhb0ltYWdlUmVxdWVzdBIUCgVpbmRleBgBIAEoBVIFaW5kZXgSIAoLdGltZW'
    '91dEluTXMYAiABKAVSC3RpbWVvdXRJbk1zEhwKCWV5ZXNDaGVjaxgDIAEoCFIJZXllc0NoZWNr'
    'EhwKCWxpcHNDaGVjaxgEIAEoCFIJbGlwc0NoZWNr');
