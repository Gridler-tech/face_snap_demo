// This is a generated file - do not edit.
//
// Generated from lights.proto.

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
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $1;

import 'lights.pb.dart' as $0;

export 'lights.pb.dart';

/// The lights service definition.
@$pb.GrpcServiceName('lights.Lights')
class LightsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  LightsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.Empty> setAllLights(
    $0.AllLightsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setAllLights, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> setLightAtCameraIndex(
    $0.LightIndexRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setLightAtCameraIndex, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> setLightOffAtCameraIndex(
    $0.LightIndexRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setLightOffAtCameraIndex, request,
        options: options);
  }

  /// All-on lighting for a subject wearing glasses: only the LEDs above the
  /// given camera's height are lit, so no source sits at the mirror angle of
  /// the lenses (lights above eye level reflect downward, past the camera).
  $grpc.ResponseFuture<$1.Empty> setGlareSafeLights(
    $0.LightIndexRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setGlareSafeLights, request, options: options);
  }

  /// Closed-loop white-point tuning: measures each LED channel's colour
  /// contribution with the OPT4048 sensor, then solves for the R/G/B intensity
  /// mix whose light (ambient subtracted) hits the target white point (6000 K
  /// neutral) at the current brightness. Streams one update per step; the last
  /// one has done=true. The sensor must face the strip from the subject position.
  $grpc.ResponseStream<$0.AutoTuneUpdate> autoTuneWhitePoint(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$autoTuneWhitePoint, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$setAllLights =
      $grpc.ClientMethod<$0.AllLightsRequest, $1.Empty>(
          '/lights.Lights/SetAllLights',
          ($0.AllLightsRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$setLightAtCameraIndex =
      $grpc.ClientMethod<$0.LightIndexRequest, $1.Empty>(
          '/lights.Lights/SetLightAtCameraIndex',
          ($0.LightIndexRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$setLightOffAtCameraIndex =
      $grpc.ClientMethod<$0.LightIndexRequest, $1.Empty>(
          '/lights.Lights/SetLightOffAtCameraIndex',
          ($0.LightIndexRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$setGlareSafeLights =
      $grpc.ClientMethod<$0.LightIndexRequest, $1.Empty>(
          '/lights.Lights/SetGlareSafeLights',
          ($0.LightIndexRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$autoTuneWhitePoint =
      $grpc.ClientMethod<$1.Empty, $0.AutoTuneUpdate>(
          '/lights.Lights/AutoTuneWhitePoint',
          ($1.Empty value) => value.writeToBuffer(),
          $0.AutoTuneUpdate.fromBuffer);
}

@$pb.GrpcServiceName('lights.Lights')
abstract class LightsServiceBase extends $grpc.Service {
  $core.String get $name => 'lights.Lights';

  LightsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.AllLightsRequest, $1.Empty>(
        'SetAllLights',
        setAllLights_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AllLightsRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LightIndexRequest, $1.Empty>(
        'SetLightAtCameraIndex',
        setLightAtCameraIndex_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LightIndexRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LightIndexRequest, $1.Empty>(
        'SetLightOffAtCameraIndex',
        setLightOffAtCameraIndex_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LightIndexRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LightIndexRequest, $1.Empty>(
        'SetGlareSafeLights',
        setGlareSafeLights_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LightIndexRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.AutoTuneUpdate>(
        'AutoTuneWhitePoint',
        autoTuneWhitePoint_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.AutoTuneUpdate value) => value.writeToBuffer()));
  }

  $async.Future<$1.Empty> setAllLights_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AllLightsRequest> $request) async {
    return setAllLights($call, await $request);
  }

  $async.Future<$1.Empty> setAllLights(
      $grpc.ServiceCall call, $0.AllLightsRequest request);

  $async.Future<$1.Empty> setLightAtCameraIndex_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LightIndexRequest> $request) async {
    return setLightAtCameraIndex($call, await $request);
  }

  $async.Future<$1.Empty> setLightAtCameraIndex(
      $grpc.ServiceCall call, $0.LightIndexRequest request);

  $async.Future<$1.Empty> setLightOffAtCameraIndex_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LightIndexRequest> $request) async {
    return setLightOffAtCameraIndex($call, await $request);
  }

  $async.Future<$1.Empty> setLightOffAtCameraIndex(
      $grpc.ServiceCall call, $0.LightIndexRequest request);

  $async.Future<$1.Empty> setGlareSafeLights_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LightIndexRequest> $request) async {
    return setGlareSafeLights($call, await $request);
  }

  $async.Future<$1.Empty> setGlareSafeLights(
      $grpc.ServiceCall call, $0.LightIndexRequest request);

  $async.Stream<$0.AutoTuneUpdate> autoTuneWhitePoint_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async* {
    yield* autoTuneWhitePoint($call, await $request);
  }

  $async.Stream<$0.AutoTuneUpdate> autoTuneWhitePoint(
      $grpc.ServiceCall call, $1.Empty request);
}
