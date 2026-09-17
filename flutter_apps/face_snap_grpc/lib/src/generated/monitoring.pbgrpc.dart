// This is a generated file - do not edit.
//
// Generated from monitoring.proto.

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

import 'monitoring.pb.dart' as $1;

export 'monitoring.pb.dart';

/// The Usage service definition.
@$pb.GrpcServiceName('monitoring.Monitoring')
class MonitoringClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MonitoringClient(super.channel, {super.options, super.interceptors});

  /// Get kiosk status
  $grpc.ResponseStream<$1.KioskStatusResponse> getKioskStatus(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$getKioskStatus, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Get system usage data fro server
  $grpc.ResponseStream<$1.UsageResponse> odroidUsage(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$odroidUsage, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Read the OPT4048 light sensor on the LED board (lux, chromaticity, CCT).
  $grpc.ResponseFuture<$1.LightMeasurementResponse> getLightMeasurement(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getLightMeasurement, request, options: options);
  }

  // method descriptors

  static final _$getKioskStatus =
      $grpc.ClientMethod<$0.Empty, $1.KioskStatusResponse>(
          '/monitoring.Monitoring/GetKioskStatus',
          ($0.Empty value) => value.writeToBuffer(),
          $1.KioskStatusResponse.fromBuffer);
  static final _$odroidUsage = $grpc.ClientMethod<$0.Empty, $1.UsageResponse>(
      '/monitoring.Monitoring/OdroidUsage',
      ($0.Empty value) => value.writeToBuffer(),
      $1.UsageResponse.fromBuffer);
  static final _$getLightMeasurement =
      $grpc.ClientMethod<$0.Empty, $1.LightMeasurementResponse>(
          '/monitoring.Monitoring/GetLightMeasurement',
          ($0.Empty value) => value.writeToBuffer(),
          $1.LightMeasurementResponse.fromBuffer);
}

@$pb.GrpcServiceName('monitoring.Monitoring')
abstract class MonitoringServiceBase extends $grpc.Service {
  $core.String get $name => 'monitoring.Monitoring';

  MonitoringServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.KioskStatusResponse>(
        'GetKioskStatus',
        getKioskStatus_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.KioskStatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.UsageResponse>(
        'OdroidUsage',
        odroidUsage_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.UsageResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.LightMeasurementResponse>(
        'GetLightMeasurement',
        getLightMeasurement_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.LightMeasurementResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$1.KioskStatusResponse> getKioskStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* getKioskStatus($call, await $request);
  }

  $async.Stream<$1.KioskStatusResponse> getKioskStatus(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$1.UsageResponse> odroidUsage_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* odroidUsage($call, await $request);
  }

  $async.Stream<$1.UsageResponse> odroidUsage(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.LightMeasurementResponse> getLightMeasurement_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getLightMeasurement($call, await $request);
  }

  $async.Future<$1.LightMeasurementResponse> getLightMeasurement(
      $grpc.ServiceCall call, $0.Empty request);
}
