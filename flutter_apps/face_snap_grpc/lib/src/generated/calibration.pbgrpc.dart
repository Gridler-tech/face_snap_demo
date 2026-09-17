// This is a generated file - do not edit.
//
// Generated from calibration.proto.

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

import 'calibration.pb.dart' as $1;

export 'calibration.pb.dart';

/// The calibration service definition.
@$pb.GrpcServiceName('calibration.Calibration')
class CalibrationClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CalibrationClient(super.channel, {super.options, super.interceptors});

  /// Get calibration settings for all camera's'
  $grpc.ResponseFuture<$1.CalibrationSettingsResponse> getCalibration(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCalibration, request, options: options);
  }

  /// Set calibration for all camera's
  $grpc.ResponseFuture<$1.CalibrateResponse> setCalibration(
    $1.CalibrateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setCalibration, request, options: options);
  }

  // method descriptors

  static final _$getCalibration =
      $grpc.ClientMethod<$0.Empty, $1.CalibrationSettingsResponse>(
          '/calibration.Calibration/GetCalibration',
          ($0.Empty value) => value.writeToBuffer(),
          $1.CalibrationSettingsResponse.fromBuffer);
  static final _$setCalibration =
      $grpc.ClientMethod<$1.CalibrateRequest, $1.CalibrateResponse>(
          '/calibration.Calibration/SetCalibration',
          ($1.CalibrateRequest value) => value.writeToBuffer(),
          $1.CalibrateResponse.fromBuffer);
}

@$pb.GrpcServiceName('calibration.Calibration')
abstract class CalibrationServiceBase extends $grpc.Service {
  $core.String get $name => 'calibration.Calibration';

  CalibrationServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.CalibrationSettingsResponse>(
        'GetCalibration',
        getCalibration_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.CalibrationSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.CalibrateRequest, $1.CalibrateResponse>(
        'SetCalibration',
        setCalibration_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.CalibrateRequest.fromBuffer(value),
        ($1.CalibrateResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.CalibrationSettingsResponse> getCalibration_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getCalibration($call, await $request);
  }

  $async.Future<$1.CalibrationSettingsResponse> getCalibration(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.CalibrateResponse> setCalibration_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.CalibrateRequest> $request) async {
    return setCalibration($call, await $request);
  }

  $async.Future<$1.CalibrateResponse> setCalibration(
      $grpc.ServiceCall call, $1.CalibrateRequest request);
}
