// This is a generated file - do not edit.
//
// Generated from kiosk.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $0;

import 'kiosk.pb.dart' as $1;

export 'kiosk.pb.dart';

/// The kiosk service definition.
@$pb.GrpcServiceName('kiosk.Kiosk')
class KioskClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  KioskClient(super.channel, {super.options, super.interceptors});

  /// Start automatic kiosk process
  $grpc.ResponseStream<$1.ProcessAutomaticResponse> startAutomaticProcess(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$startAutomaticProcess, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Start manual kiosk process
  $grpc.ResponseStream<$1.ProcessManualResponse> startManualProcess(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$startManualProcess, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Get focused camera index
  $grpc.ResponseFuture<$1.FocusedCameraResponse> getFocusedCameraIndex(
    $1.FocusedCameraRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getFocusedCameraIndex, request, options: options);
  }

  /// Request a high resolution image from the camera at the given index
  $grpc.ResponseStream<$1.HighResImageResponse>
      getHighResolutionImageFromCameraIndex(
    $1.HighResImageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$getHighResolutionImageFromCameraIndex,
        $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Request a high resolution image with icao checks at the given index
  $grpc.ResponseStream<$1.HighResImageResponse>
      getHighResolutionImageWithIcaoChecksFromCameraIndex(
    $1.HighResIcaoImageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$getHighResolutionImageWithIcaoChecksFromCameraIndex,
        $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Get kiosk info
  $grpc.ResponseFuture<$1.KioskInfoResponse> getKioskInfo(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getKioskInfo, request, options: options);
  }

  /// Face recognition
  $grpc.ResponseFuture<$1.FaceRecognitionResponse> faceRecognition(
    $1.FaceRecognitionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$faceRecognition, request, options: options);
  }

  /// Live preview: stream JPEG frames from one camera until the client cancels
  /// or max_seconds elapses. One camera at a time - USB2 bandwidth is shared
  /// with captures.
  $grpc.ResponseStream<$1.ProcessImageData> streamPreview(
    $1.PreviewRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamPreview, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$startAutomaticProcess =
      $grpc.ClientMethod<$0.Empty, $1.ProcessAutomaticResponse>(
          '/kiosk.Kiosk/StartAutomaticProcess',
          ($0.Empty value) => value.writeToBuffer(),
          $1.ProcessAutomaticResponse.fromBuffer);
  static final _$startManualProcess =
      $grpc.ClientMethod<$0.Empty, $1.ProcessManualResponse>(
          '/kiosk.Kiosk/StartManualProcess',
          ($0.Empty value) => value.writeToBuffer(),
          $1.ProcessManualResponse.fromBuffer);
  static final _$getFocusedCameraIndex =
      $grpc.ClientMethod<$1.FocusedCameraRequest, $1.FocusedCameraResponse>(
          '/kiosk.Kiosk/GetFocusedCameraIndex',
          ($1.FocusedCameraRequest value) => value.writeToBuffer(),
          $1.FocusedCameraResponse.fromBuffer);
  static final _$getHighResolutionImageFromCameraIndex =
      $grpc.ClientMethod<$1.HighResImageRequest, $1.HighResImageResponse>(
          '/kiosk.Kiosk/GetHighResolutionImageFromCameraIndex',
          ($1.HighResImageRequest value) => value.writeToBuffer(),
          $1.HighResImageResponse.fromBuffer);
  static final _$getHighResolutionImageWithIcaoChecksFromCameraIndex =
      $grpc.ClientMethod<$1.HighResIcaoImageRequest, $1.HighResImageResponse>(
          '/kiosk.Kiosk/GetHighResolutionImageWithIcaoChecksFromCameraIndex',
          ($1.HighResIcaoImageRequest value) => value.writeToBuffer(),
          $1.HighResImageResponse.fromBuffer);
  static final _$getKioskInfo =
      $grpc.ClientMethod<$0.Empty, $1.KioskInfoResponse>(
          '/kiosk.Kiosk/GetKioskInfo',
          ($0.Empty value) => value.writeToBuffer(),
          $1.KioskInfoResponse.fromBuffer);
  static final _$faceRecognition =
      $grpc.ClientMethod<$1.FaceRecognitionRequest, $1.FaceRecognitionResponse>(
          '/kiosk.Kiosk/FaceRecognition',
          ($1.FaceRecognitionRequest value) => value.writeToBuffer(),
          $1.FaceRecognitionResponse.fromBuffer);
  static final _$streamPreview =
      $grpc.ClientMethod<$1.PreviewRequest, $1.ProcessImageData>(
          '/kiosk.Kiosk/StreamPreview',
          ($1.PreviewRequest value) => value.writeToBuffer(),
          $1.ProcessImageData.fromBuffer);
}

@$pb.GrpcServiceName('kiosk.Kiosk')
abstract class KioskServiceBase extends $grpc.Service {
  $core.String get $name => 'kiosk.Kiosk';

  KioskServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.ProcessAutomaticResponse>(
        'StartAutomaticProcess',
        startAutomaticProcess_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.ProcessAutomaticResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.ProcessManualResponse>(
        'StartManualProcess',
        startManualProcess_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.ProcessManualResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.FocusedCameraRequest, $1.FocusedCameraResponse>(
            'GetFocusedCameraIndex',
            getFocusedCameraIndex_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.FocusedCameraRequest.fromBuffer(value),
            ($1.FocusedCameraResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.HighResImageRequest, $1.HighResImageResponse>(
            'GetHighResolutionImageFromCameraIndex',
            getHighResolutionImageFromCameraIndex_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $1.HighResImageRequest.fromBuffer(value),
            ($1.HighResImageResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.HighResIcaoImageRequest,
            $1.HighResImageResponse>(
        'GetHighResolutionImageWithIcaoChecksFromCameraIndex',
        getHighResolutionImageWithIcaoChecksFromCameraIndex_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $1.HighResIcaoImageRequest.fromBuffer(value),
        ($1.HighResImageResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.KioskInfoResponse>(
        'GetKioskInfo',
        getKioskInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.KioskInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.FaceRecognitionRequest,
            $1.FaceRecognitionResponse>(
        'FaceRecognition',
        faceRecognition_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.FaceRecognitionRequest.fromBuffer(value),
        ($1.FaceRecognitionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.PreviewRequest, $1.ProcessImageData>(
        'StreamPreview',
        streamPreview_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.PreviewRequest.fromBuffer(value),
        ($1.ProcessImageData value) => value.writeToBuffer()));
  }

  $async.Stream<$1.ProcessAutomaticResponse> startAutomaticProcess_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* startAutomaticProcess($call, await $request);
  }

  $async.Stream<$1.ProcessAutomaticResponse> startAutomaticProcess(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$1.ProcessManualResponse> startManualProcess_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* startManualProcess($call, await $request);
  }

  $async.Stream<$1.ProcessManualResponse> startManualProcess(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.FocusedCameraResponse> getFocusedCameraIndex_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.FocusedCameraRequest> $request) async {
    return getFocusedCameraIndex($call, await $request);
  }

  $async.Future<$1.FocusedCameraResponse> getFocusedCameraIndex(
      $grpc.ServiceCall call, $1.FocusedCameraRequest request);

  $async.Stream<$1.HighResImageResponse>
      getHighResolutionImageFromCameraIndex_Pre($grpc.ServiceCall $call,
          $async.Future<$1.HighResImageRequest> $request) async* {
    yield* getHighResolutionImageFromCameraIndex($call, await $request);
  }

  $async.Stream<$1.HighResImageResponse> getHighResolutionImageFromCameraIndex(
      $grpc.ServiceCall call, $1.HighResImageRequest request);

  $async.Stream<$1.HighResImageResponse>
      getHighResolutionImageWithIcaoChecksFromCameraIndex_Pre(
          $grpc.ServiceCall $call,
          $async.Future<$1.HighResIcaoImageRequest> $request) async* {
    yield* getHighResolutionImageWithIcaoChecksFromCameraIndex(
        $call, await $request);
  }

  $async.Stream<$1.HighResImageResponse>
      getHighResolutionImageWithIcaoChecksFromCameraIndex(
          $grpc.ServiceCall call, $1.HighResIcaoImageRequest request);

  $async.Future<$1.KioskInfoResponse> getKioskInfo_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getKioskInfo($call, await $request);
  }

  $async.Future<$1.KioskInfoResponse> getKioskInfo(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.FaceRecognitionResponse> faceRecognition_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.FaceRecognitionRequest> $request) async {
    return faceRecognition($call, await $request);
  }

  $async.Future<$1.FaceRecognitionResponse> faceRecognition(
      $grpc.ServiceCall call, $1.FaceRecognitionRequest request);

  $async.Stream<$1.ProcessImageData> streamPreview_Pre($grpc.ServiceCall $call,
      $async.Future<$1.PreviewRequest> $request) async* {
    yield* streamPreview($call, await $request);
  }

  $async.Stream<$1.ProcessImageData> streamPreview(
      $grpc.ServiceCall call, $1.PreviewRequest request);
}
