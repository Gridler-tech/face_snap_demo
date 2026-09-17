// This is a generated file - do not edit.
//
// Generated from camera.proto.

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

import 'camera.pb.dart' as $1;

export 'camera.pb.dart';

/// The camera service definition.
@$pb.GrpcServiceName('camera.Camera')
class CameraClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CameraClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$1.LoadCameraSettingsResponse> loadSettings(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$loadSettings, request, options: options);
  }

  $grpc.ResponseFuture<$1.BrightnessResponse> setBrightness(
    $1.BrightnessRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setBrightness, request, options: options);
  }

  $grpc.ResponseFuture<$1.ContrastResponse> setContrast(
    $1.ContrastRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setContrast, request, options: options);
  }

  $grpc.ResponseFuture<$1.SaturationResponse> setSaturation(
    $1.SaturationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setSaturation, request, options: options);
  }

  $grpc.ResponseFuture<$1.HueResponse> setHue(
    $1.HueRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setHue, request, options: options);
  }

  $grpc.ResponseFuture<$1.WhiteBalanceTemperatureAutoResponse>
      setWhiteBalanceTemperatureAuto(
    $1.WhiteBalanceTemperatureAutoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setWhiteBalanceTemperatureAuto, request,
        options: options);
  }

  $grpc.ResponseFuture<$1.GammaResponse> setGamma(
    $1.GammaRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setGamma, request, options: options);
  }

  $grpc.ResponseFuture<$1.GainResponse> setGain(
    $1.GainRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setGain, request, options: options);
  }

  $grpc.ResponseFuture<$1.WhiteBalanceTemperatureResponse>
      setWhiteBalanceTemperature(
    $1.WhiteBalanceTemperatureRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setWhiteBalanceTemperature, request,
        options: options);
  }

  $grpc.ResponseFuture<$1.SharpnessResponse> setSharpness(
    $1.SharpnessRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setSharpness, request, options: options);
  }

  $grpc.ResponseFuture<$1.BacklightCompensationResponse>
      setBacklightCompensation(
    $1.BacklightCompensationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setBacklightCompensation, request,
        options: options);
  }

  $grpc.ResponseFuture<$1.ExposureAutoPriorityResponse> setExposureAutoPriority(
    $1.ExposureAutoPriorityRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setExposureAutoPriority, request,
        options: options);
  }

  $grpc.ResponseFuture<$1.PanAbsoluteResponse> setPanAbsolute(
    $1.PanAbsoluteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setPanAbsolute, request, options: options);
  }

  $grpc.ResponseFuture<$1.TiltAbsoluteResponse> setTiltAbsolute(
    $1.TiltAbsoluteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setTiltAbsolute, request, options: options);
  }

  $grpc.ResponseFuture<$1.ZoomAbsoluteResponse> setZoomAbsolute(
    $1.ZoomAbsoluteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setZoomAbsolute, request, options: options);
  }

  $grpc.ResponseFuture<$1.ExposureAbsoluteResponse> setExposureAbsolute(
    $1.ExposureAbsoluteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setExposureAbsolute, request, options: options);
  }

  $grpc.ResponseFuture<$1.AutofocusResponse> setAutofocus(
    $1.AutofocusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setAutofocus, request, options: options);
  }

  $grpc.ResponseFuture<$1.FocusAbsoluteResponse> setFocusAbsolute(
    $1.FocusAbsoluteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setFocusAbsolute, request, options: options);
  }

  $grpc.ResponseFuture<$1.CalibrateFocusResponse> calibrateFocus(
    $1.CalibrateFocusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$calibrateFocus, request, options: options);
  }

  // method descriptors

  static final _$loadSettings =
      $grpc.ClientMethod<$0.Empty, $1.LoadCameraSettingsResponse>(
          '/camera.Camera/LoadSettings',
          ($0.Empty value) => value.writeToBuffer(),
          $1.LoadCameraSettingsResponse.fromBuffer);
  static final _$setBrightness =
      $grpc.ClientMethod<$1.BrightnessRequest, $1.BrightnessResponse>(
          '/camera.Camera/SetBrightness',
          ($1.BrightnessRequest value) => value.writeToBuffer(),
          $1.BrightnessResponse.fromBuffer);
  static final _$setContrast =
      $grpc.ClientMethod<$1.ContrastRequest, $1.ContrastResponse>(
          '/camera.Camera/SetContrast',
          ($1.ContrastRequest value) => value.writeToBuffer(),
          $1.ContrastResponse.fromBuffer);
  static final _$setSaturation =
      $grpc.ClientMethod<$1.SaturationRequest, $1.SaturationResponse>(
          '/camera.Camera/SetSaturation',
          ($1.SaturationRequest value) => value.writeToBuffer(),
          $1.SaturationResponse.fromBuffer);
  static final _$setHue = $grpc.ClientMethod<$1.HueRequest, $1.HueResponse>(
      '/camera.Camera/SetHue',
      ($1.HueRequest value) => value.writeToBuffer(),
      $1.HueResponse.fromBuffer);
  static final _$setWhiteBalanceTemperatureAuto = $grpc.ClientMethod<
          $1.WhiteBalanceTemperatureAutoRequest,
          $1.WhiteBalanceTemperatureAutoResponse>(
      '/camera.Camera/SetWhiteBalanceTemperatureAuto',
      ($1.WhiteBalanceTemperatureAutoRequest value) => value.writeToBuffer(),
      $1.WhiteBalanceTemperatureAutoResponse.fromBuffer);
  static final _$setGamma =
      $grpc.ClientMethod<$1.GammaRequest, $1.GammaResponse>(
          '/camera.Camera/SetGamma',
          ($1.GammaRequest value) => value.writeToBuffer(),
          $1.GammaResponse.fromBuffer);
  static final _$setGain = $grpc.ClientMethod<$1.GainRequest, $1.GainResponse>(
      '/camera.Camera/SetGain',
      ($1.GainRequest value) => value.writeToBuffer(),
      $1.GainResponse.fromBuffer);
  static final _$setWhiteBalanceTemperature = $grpc.ClientMethod<
          $1.WhiteBalanceTemperatureRequest,
          $1.WhiteBalanceTemperatureResponse>(
      '/camera.Camera/SetWhiteBalanceTemperature',
      ($1.WhiteBalanceTemperatureRequest value) => value.writeToBuffer(),
      $1.WhiteBalanceTemperatureResponse.fromBuffer);
  static final _$setSharpness =
      $grpc.ClientMethod<$1.SharpnessRequest, $1.SharpnessResponse>(
          '/camera.Camera/SetSharpness',
          ($1.SharpnessRequest value) => value.writeToBuffer(),
          $1.SharpnessResponse.fromBuffer);
  static final _$setBacklightCompensation = $grpc.ClientMethod<
          $1.BacklightCompensationRequest, $1.BacklightCompensationResponse>(
      '/camera.Camera/SetBacklightCompensation',
      ($1.BacklightCompensationRequest value) => value.writeToBuffer(),
      $1.BacklightCompensationResponse.fromBuffer);
  static final _$setExposureAutoPriority = $grpc.ClientMethod<
          $1.ExposureAutoPriorityRequest, $1.ExposureAutoPriorityResponse>(
      '/camera.Camera/SetExposureAutoPriority',
      ($1.ExposureAutoPriorityRequest value) => value.writeToBuffer(),
      $1.ExposureAutoPriorityResponse.fromBuffer);
  static final _$setPanAbsolute =
      $grpc.ClientMethod<$1.PanAbsoluteRequest, $1.PanAbsoluteResponse>(
          '/camera.Camera/SetPanAbsolute',
          ($1.PanAbsoluteRequest value) => value.writeToBuffer(),
          $1.PanAbsoluteResponse.fromBuffer);
  static final _$setTiltAbsolute =
      $grpc.ClientMethod<$1.TiltAbsoluteRequest, $1.TiltAbsoluteResponse>(
          '/camera.Camera/SetTiltAbsolute',
          ($1.TiltAbsoluteRequest value) => value.writeToBuffer(),
          $1.TiltAbsoluteResponse.fromBuffer);
  static final _$setZoomAbsolute =
      $grpc.ClientMethod<$1.ZoomAbsoluteRequest, $1.ZoomAbsoluteResponse>(
          '/camera.Camera/SetZoomAbsolute',
          ($1.ZoomAbsoluteRequest value) => value.writeToBuffer(),
          $1.ZoomAbsoluteResponse.fromBuffer);
  static final _$setExposureAbsolute = $grpc.ClientMethod<
          $1.ExposureAbsoluteRequest, $1.ExposureAbsoluteResponse>(
      '/camera.Camera/SetExposureAbsolute',
      ($1.ExposureAbsoluteRequest value) => value.writeToBuffer(),
      $1.ExposureAbsoluteResponse.fromBuffer);
  static final _$setAutofocus =
      $grpc.ClientMethod<$1.AutofocusRequest, $1.AutofocusResponse>(
          '/camera.Camera/SetAutofocus',
          ($1.AutofocusRequest value) => value.writeToBuffer(),
          $1.AutofocusResponse.fromBuffer);
  static final _$setFocusAbsolute =
      $grpc.ClientMethod<$1.FocusAbsoluteRequest, $1.FocusAbsoluteResponse>(
          '/camera.Camera/SetFocusAbsolute',
          ($1.FocusAbsoluteRequest value) => value.writeToBuffer(),
          $1.FocusAbsoluteResponse.fromBuffer);
  static final _$calibrateFocus =
      $grpc.ClientMethod<$1.CalibrateFocusRequest, $1.CalibrateFocusResponse>(
          '/camera.Camera/CalibrateFocus',
          ($1.CalibrateFocusRequest value) => value.writeToBuffer(),
          $1.CalibrateFocusResponse.fromBuffer);
}

@$pb.GrpcServiceName('camera.Camera')
abstract class CameraServiceBase extends $grpc.Service {
  $core.String get $name => 'camera.Camera';

  CameraServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.LoadCameraSettingsResponse>(
        'LoadSettings',
        loadSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.LoadCameraSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BrightnessRequest, $1.BrightnessResponse>(
        'SetBrightness',
        setBrightness_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.BrightnessRequest.fromBuffer(value),
        ($1.BrightnessResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ContrastRequest, $1.ContrastResponse>(
        'SetContrast',
        setContrast_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.ContrastRequest.fromBuffer(value),
        ($1.ContrastResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SaturationRequest, $1.SaturationResponse>(
        'SetSaturation',
        setSaturation_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.SaturationRequest.fromBuffer(value),
        ($1.SaturationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.HueRequest, $1.HueResponse>(
        'SetHue',
        setHue_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.HueRequest.fromBuffer(value),
        ($1.HueResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.WhiteBalanceTemperatureAutoRequest,
            $1.WhiteBalanceTemperatureAutoResponse>(
        'SetWhiteBalanceTemperatureAuto',
        setWhiteBalanceTemperatureAuto_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.WhiteBalanceTemperatureAutoRequest.fromBuffer(value),
        ($1.WhiteBalanceTemperatureAutoResponse value) =>
            value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GammaRequest, $1.GammaResponse>(
        'SetGamma',
        setGamma_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GammaRequest.fromBuffer(value),
        ($1.GammaResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GainRequest, $1.GainResponse>(
        'SetGain',
        setGain_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.GainRequest.fromBuffer(value),
        ($1.GainResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.WhiteBalanceTemperatureRequest,
            $1.WhiteBalanceTemperatureResponse>(
        'SetWhiteBalanceTemperature',
        setWhiteBalanceTemperature_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.WhiteBalanceTemperatureRequest.fromBuffer(value),
        ($1.WhiteBalanceTemperatureResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SharpnessRequest, $1.SharpnessResponse>(
        'SetSharpness',
        setSharpness_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.SharpnessRequest.fromBuffer(value),
        ($1.SharpnessResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.BacklightCompensationRequest,
            $1.BacklightCompensationResponse>(
        'SetBacklightCompensation',
        setBacklightCompensation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.BacklightCompensationRequest.fromBuffer(value),
        ($1.BacklightCompensationResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ExposureAutoPriorityRequest,
            $1.ExposureAutoPriorityResponse>(
        'SetExposureAutoPriority',
        setExposureAutoPriority_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.ExposureAutoPriorityRequest.fromBuffer(value),
        ($1.ExposureAutoPriorityResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.PanAbsoluteRequest, $1.PanAbsoluteResponse>(
            'SetPanAbsolute',
            setPanAbsolute_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.PanAbsoluteRequest.fromBuffer(value),
            ($1.PanAbsoluteResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.TiltAbsoluteRequest, $1.TiltAbsoluteResponse>(
            'SetTiltAbsolute',
            setTiltAbsolute_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.TiltAbsoluteRequest.fromBuffer(value),
            ($1.TiltAbsoluteResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.ZoomAbsoluteRequest, $1.ZoomAbsoluteResponse>(
            'SetZoomAbsolute',
            setZoomAbsolute_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.ZoomAbsoluteRequest.fromBuffer(value),
            ($1.ZoomAbsoluteResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ExposureAbsoluteRequest,
            $1.ExposureAbsoluteResponse>(
        'SetExposureAbsolute',
        setExposureAbsolute_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.ExposureAbsoluteRequest.fromBuffer(value),
        ($1.ExposureAbsoluteResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.AutofocusRequest, $1.AutofocusResponse>(
        'SetAutofocus',
        setAutofocus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.AutofocusRequest.fromBuffer(value),
        ($1.AutofocusResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.FocusAbsoluteRequest, $1.FocusAbsoluteResponse>(
            'SetFocusAbsolute',
            setFocusAbsolute_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.FocusAbsoluteRequest.fromBuffer(value),
            ($1.FocusAbsoluteResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.CalibrateFocusRequest,
            $1.CalibrateFocusResponse>(
        'CalibrateFocus',
        calibrateFocus_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.CalibrateFocusRequest.fromBuffer(value),
        ($1.CalibrateFocusResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.LoadCameraSettingsResponse> loadSettings_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return loadSettings($call, await $request);
  }

  $async.Future<$1.LoadCameraSettingsResponse> loadSettings(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.BrightnessResponse> setBrightness_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.BrightnessRequest> $request) async {
    return setBrightness($call, await $request);
  }

  $async.Future<$1.BrightnessResponse> setBrightness(
      $grpc.ServiceCall call, $1.BrightnessRequest request);

  $async.Future<$1.ContrastResponse> setContrast_Pre($grpc.ServiceCall $call,
      $async.Future<$1.ContrastRequest> $request) async {
    return setContrast($call, await $request);
  }

  $async.Future<$1.ContrastResponse> setContrast(
      $grpc.ServiceCall call, $1.ContrastRequest request);

  $async.Future<$1.SaturationResponse> setSaturation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.SaturationRequest> $request) async {
    return setSaturation($call, await $request);
  }

  $async.Future<$1.SaturationResponse> setSaturation(
      $grpc.ServiceCall call, $1.SaturationRequest request);

  $async.Future<$1.HueResponse> setHue_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.HueRequest> $request) async {
    return setHue($call, await $request);
  }

  $async.Future<$1.HueResponse> setHue(
      $grpc.ServiceCall call, $1.HueRequest request);

  $async.Future<$1.WhiteBalanceTemperatureAutoResponse>
      setWhiteBalanceTemperatureAuto_Pre($grpc.ServiceCall $call,
          $async.Future<$1.WhiteBalanceTemperatureAutoRequest> $request) async {
    return setWhiteBalanceTemperatureAuto($call, await $request);
  }

  $async.Future<$1.WhiteBalanceTemperatureAutoResponse>
      setWhiteBalanceTemperatureAuto($grpc.ServiceCall call,
          $1.WhiteBalanceTemperatureAutoRequest request);

  $async.Future<$1.GammaResponse> setGamma_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.GammaRequest> $request) async {
    return setGamma($call, await $request);
  }

  $async.Future<$1.GammaResponse> setGamma(
      $grpc.ServiceCall call, $1.GammaRequest request);

  $async.Future<$1.GainResponse> setGain_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.GainRequest> $request) async {
    return setGain($call, await $request);
  }

  $async.Future<$1.GainResponse> setGain(
      $grpc.ServiceCall call, $1.GainRequest request);

  $async.Future<$1.WhiteBalanceTemperatureResponse>
      setWhiteBalanceTemperature_Pre($grpc.ServiceCall $call,
          $async.Future<$1.WhiteBalanceTemperatureRequest> $request) async {
    return setWhiteBalanceTemperature($call, await $request);
  }

  $async.Future<$1.WhiteBalanceTemperatureResponse> setWhiteBalanceTemperature(
      $grpc.ServiceCall call, $1.WhiteBalanceTemperatureRequest request);

  $async.Future<$1.SharpnessResponse> setSharpness_Pre($grpc.ServiceCall $call,
      $async.Future<$1.SharpnessRequest> $request) async {
    return setSharpness($call, await $request);
  }

  $async.Future<$1.SharpnessResponse> setSharpness(
      $grpc.ServiceCall call, $1.SharpnessRequest request);

  $async.Future<$1.BacklightCompensationResponse> setBacklightCompensation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.BacklightCompensationRequest> $request) async {
    return setBacklightCompensation($call, await $request);
  }

  $async.Future<$1.BacklightCompensationResponse> setBacklightCompensation(
      $grpc.ServiceCall call, $1.BacklightCompensationRequest request);

  $async.Future<$1.ExposureAutoPriorityResponse> setExposureAutoPriority_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.ExposureAutoPriorityRequest> $request) async {
    return setExposureAutoPriority($call, await $request);
  }

  $async.Future<$1.ExposureAutoPriorityResponse> setExposureAutoPriority(
      $grpc.ServiceCall call, $1.ExposureAutoPriorityRequest request);

  $async.Future<$1.PanAbsoluteResponse> setPanAbsolute_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.PanAbsoluteRequest> $request) async {
    return setPanAbsolute($call, await $request);
  }

  $async.Future<$1.PanAbsoluteResponse> setPanAbsolute(
      $grpc.ServiceCall call, $1.PanAbsoluteRequest request);

  $async.Future<$1.TiltAbsoluteResponse> setTiltAbsolute_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.TiltAbsoluteRequest> $request) async {
    return setTiltAbsolute($call, await $request);
  }

  $async.Future<$1.TiltAbsoluteResponse> setTiltAbsolute(
      $grpc.ServiceCall call, $1.TiltAbsoluteRequest request);

  $async.Future<$1.ZoomAbsoluteResponse> setZoomAbsolute_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.ZoomAbsoluteRequest> $request) async {
    return setZoomAbsolute($call, await $request);
  }

  $async.Future<$1.ZoomAbsoluteResponse> setZoomAbsolute(
      $grpc.ServiceCall call, $1.ZoomAbsoluteRequest request);

  $async.Future<$1.ExposureAbsoluteResponse> setExposureAbsolute_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.ExposureAbsoluteRequest> $request) async {
    return setExposureAbsolute($call, await $request);
  }

  $async.Future<$1.ExposureAbsoluteResponse> setExposureAbsolute(
      $grpc.ServiceCall call, $1.ExposureAbsoluteRequest request);

  $async.Future<$1.AutofocusResponse> setAutofocus_Pre($grpc.ServiceCall $call,
      $async.Future<$1.AutofocusRequest> $request) async {
    return setAutofocus($call, await $request);
  }

  $async.Future<$1.AutofocusResponse> setAutofocus(
      $grpc.ServiceCall call, $1.AutofocusRequest request);

  $async.Future<$1.FocusAbsoluteResponse> setFocusAbsolute_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.FocusAbsoluteRequest> $request) async {
    return setFocusAbsolute($call, await $request);
  }

  $async.Future<$1.FocusAbsoluteResponse> setFocusAbsolute(
      $grpc.ServiceCall call, $1.FocusAbsoluteRequest request);

  $async.Future<$1.CalibrateFocusResponse> calibrateFocus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.CalibrateFocusRequest> $request) async {
    return calibrateFocus($call, await $request);
  }

  $async.Future<$1.CalibrateFocusResponse> calibrateFocus(
      $grpc.ServiceCall call, $1.CalibrateFocusRequest request);
}
