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
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `ProcessAutomaticResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List processAutomaticResponseDescriptor = $convert.base64Decode(
    'ChhQcm9jZXNzQXV0b21hdGljUmVzcG9uc2USQAoNcHJvY2Vzc1N0YXR1cxgBIAEoCzIYLmtpb3'
    'NrLlByb2Nlc3NTdGVwU3RhdHVzSABSDXByb2Nlc3NTdGF0dXMSNwoJaW1hZ2VEYXRhGAIgASgL'
    'Mhcua2lvc2suUHJvY2Vzc0ltYWdlRGF0YUgAUglpbWFnZURhdGFCCAoGcmVzdWx0');

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
  ],
  '8': [
    {'1': 'result'},
  ],
};

/// Descriptor for `ProcessManualResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List processManualResponseDescriptor = $convert.base64Decode(
    'ChVQcm9jZXNzTWFudWFsUmVzcG9uc2USQAoNcHJvY2Vzc1N0YXR1cxgBIAEoCzIYLmtpb3NrLl'
    'Byb2Nlc3NTdGVwU3RhdHVzSABSDXByb2Nlc3NTdGF0dXMSNwoJaW1hZ2VEYXRhGAIgASgLMhcu'
    'a2lvc2suUHJvY2Vzc0ltYWdlRGF0YUgAUglpbWFnZURhdGFCCAoGcmVzdWx0');

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
  ],
};

/// Descriptor for `HighResImageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List highResImageResponseDescriptor = $convert.base64Decode(
    'ChRIaWdoUmVzSW1hZ2VSZXNwb25zZRJDChBwcm9jZXNzSW1hZ2VEYXRhGAEgASgLMhcua2lvc2'
    'suUHJvY2Vzc0ltYWdlRGF0YVIQcHJvY2Vzc0ltYWdlRGF0YRIxCgpzdGF0dXNUeXBlGAIgASgO'
    'MhEua2lvc2suU3RhdHVzVHlwZVIKc3RhdHVzVHlwZQ==');

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
