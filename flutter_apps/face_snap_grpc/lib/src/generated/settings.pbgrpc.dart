// This is a generated file - do not edit.
//
// Generated from settings.proto.

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

import 'settings.pb.dart' as $0;

export 'settings.pb.dart';

/// The settings service definition.
@$pb.GrpcServiceName('settings.Settings')
class SettingsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SettingsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SaveSettingsResponse> saveSettings(
    $0.SaveSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.LoadSettingsResponse> loadSettings(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$loadSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.ResolutionResponse> setResolution(
    $0.ResolutionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setResolution, request, options: options);
  }

  $grpc.ResponseFuture<$0.CropResponse> setCrop(
    $0.CropRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setCrop, request, options: options);
  }

  $grpc.ResponseFuture<$0.CropResolutionResponse> setCropResolution(
    $0.CropResolutionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setCropResolution, request, options: options);
  }

  $grpc.ResponseFuture<$0.EyesCheckResponse> setEyesCheck(
    $0.EyesCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setEyesCheck, request, options: options);
  }

  $grpc.ResponseFuture<$0.LipsCheckResponse> setLipsCheck(
    $0.LipsCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setLipsCheck, request, options: options);
  }

  $grpc.ResponseFuture<$0.LightingResponse> setLighting(
    $0.LightingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setLighting, request, options: options);
  }

  $grpc.ResponseFuture<$0.IntensityResponse> setIntensityRed(
    $0.IntensityRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setIntensityRed, request, options: options);
  }

  $grpc.ResponseFuture<$0.IntensityResponse> setIntensityGreen(
    $0.IntensityRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setIntensityGreen, request, options: options);
  }

  $grpc.ResponseFuture<$0.IntensityResponse> setIntensityBlue(
    $0.IntensityRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setIntensityBlue, request, options: options);
  }

  $grpc.ResponseFuture<$0.DistanceMinResponse> setDistanceMin(
    $0.DistanceMinRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setDistanceMin, request, options: options);
  }

  $grpc.ResponseFuture<$0.DistanceMaxResponse> setDistanceMax(
    $0.DistanceMaxRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setDistanceMax, request, options: options);
  }

  $grpc.ResponseFuture<$0.CameraOrderingModeResponse> setCameraOrderingMode(
    $0.CameraOrderingModeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setCameraOrderingMode, request, options: options);
  }

  $grpc.ResponseFuture<$0.MsmfSelectionResponse> setMsmfSelection(
    $0.MsmfSelectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setMsmfSelection, request, options: options);
  }

  $grpc.ResponseFuture<$0.BackgroundMethodResponse> setBackgroundMethod(
    $0.BackgroundMethodRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setBackgroundMethod, request, options: options);
  }

  $grpc.ResponseFuture<$0.BackgroundColorResponse> setBackgroundColor(
    $0.BackgroundColorRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setBackgroundColor, request, options: options);
  }

  $grpc.ResponseFuture<$0.EyeGlassesCheckResponse> setEyeGlassesCheck(
    $0.EyeGlassesCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setEyeGlassesCheck, request, options: options);
  }

  $grpc.ResponseFuture<$0.HeadPoseCheckResponse> setHeadPoseCheck(
    $0.HeadPoseCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setHeadPoseCheck, request, options: options);
  }

  $grpc.ResponseFuture<$0.SharpnessCheckResponse> setSharpnessCheck(
    $0.SharpnessCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setSharpnessCheck, request, options: options);
  }

  $grpc.ResponseFuture<$0.RedEyeDetectionCheckResponse> setRedEyeDetectionCheck(
    $0.RedEyeDetectionCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setRedEyeDetectionCheck, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.HeadSizeCheckResponse> setHeadSizeCheck(
    $0.HeadSizeCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setHeadSizeCheck, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExpressionCheckResponse> setExpressionCheck(
    $0.ExpressionCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setExpressionCheck, request, options: options);
  }

  $grpc.ResponseFuture<$0.GazeCheckResponse> setGazeCheck(
    $0.GazeCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setGazeCheck, request, options: options);
  }

  $grpc.ResponseFuture<$0.LightingEvennessCheckResponse>
      setLightingEvennessCheck(
    $0.LightingEvennessCheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setLightingEvennessCheck, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.PhotoFormatResponse> setPhotoFormat(
    $0.PhotoFormatRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setPhotoFormat, request, options: options);
  }

  $grpc.ResponseFuture<$0.JpegQualityResponse> setJpegQuality(
    $0.JpegQualityRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setJpegQuality, request, options: options);
  }

  $grpc.ResponseFuture<$0.GlassesLightsOffResponse> setGlassesLightsOff(
    $0.GlassesLightsOffRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setGlassesLightsOff, request, options: options);
  }

  $grpc.ResponseFuture<$0.OfiqChecksResponse> setOfiqChecks(
    $0.OfiqChecksRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setOfiqChecks, request, options: options);
  }

  $grpc.ResponseFuture<$0.LedLayoutResponse> setLedLayout(
    $0.LedLayoutRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setLedLayout, request, options: options);
  }

  $grpc.ResponseFuture<$0.FocusLightResponse> setFocusLight(
    $0.FocusLightRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setFocusLight, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExpectedCamerasResponse> setExpectedCameras(
    $0.ExpectedCamerasRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setExpectedCameras, request, options: options);
  }

  // method descriptors

  static final _$saveSettings =
      $grpc.ClientMethod<$0.SaveSettingsRequest, $0.SaveSettingsResponse>(
          '/settings.Settings/SaveSettings',
          ($0.SaveSettingsRequest value) => value.writeToBuffer(),
          $0.SaveSettingsResponse.fromBuffer);
  static final _$loadSettings =
      $grpc.ClientMethod<$1.Empty, $0.LoadSettingsResponse>(
          '/settings.Settings/LoadSettings',
          ($1.Empty value) => value.writeToBuffer(),
          $0.LoadSettingsResponse.fromBuffer);
  static final _$setResolution =
      $grpc.ClientMethod<$0.ResolutionRequest, $0.ResolutionResponse>(
          '/settings.Settings/SetResolution',
          ($0.ResolutionRequest value) => value.writeToBuffer(),
          $0.ResolutionResponse.fromBuffer);
  static final _$setCrop = $grpc.ClientMethod<$0.CropRequest, $0.CropResponse>(
      '/settings.Settings/SetCrop',
      ($0.CropRequest value) => value.writeToBuffer(),
      $0.CropResponse.fromBuffer);
  static final _$setCropResolution =
      $grpc.ClientMethod<$0.CropResolutionRequest, $0.CropResolutionResponse>(
          '/settings.Settings/SetCropResolution',
          ($0.CropResolutionRequest value) => value.writeToBuffer(),
          $0.CropResolutionResponse.fromBuffer);
  static final _$setEyesCheck =
      $grpc.ClientMethod<$0.EyesCheckRequest, $0.EyesCheckResponse>(
          '/settings.Settings/SetEyesCheck',
          ($0.EyesCheckRequest value) => value.writeToBuffer(),
          $0.EyesCheckResponse.fromBuffer);
  static final _$setLipsCheck =
      $grpc.ClientMethod<$0.LipsCheckRequest, $0.LipsCheckResponse>(
          '/settings.Settings/SetLipsCheck',
          ($0.LipsCheckRequest value) => value.writeToBuffer(),
          $0.LipsCheckResponse.fromBuffer);
  static final _$setLighting =
      $grpc.ClientMethod<$0.LightingRequest, $0.LightingResponse>(
          '/settings.Settings/SetLighting',
          ($0.LightingRequest value) => value.writeToBuffer(),
          $0.LightingResponse.fromBuffer);
  static final _$setIntensityRed =
      $grpc.ClientMethod<$0.IntensityRequest, $0.IntensityResponse>(
          '/settings.Settings/SetIntensityRed',
          ($0.IntensityRequest value) => value.writeToBuffer(),
          $0.IntensityResponse.fromBuffer);
  static final _$setIntensityGreen =
      $grpc.ClientMethod<$0.IntensityRequest, $0.IntensityResponse>(
          '/settings.Settings/SetIntensityGreen',
          ($0.IntensityRequest value) => value.writeToBuffer(),
          $0.IntensityResponse.fromBuffer);
  static final _$setIntensityBlue =
      $grpc.ClientMethod<$0.IntensityRequest, $0.IntensityResponse>(
          '/settings.Settings/SetIntensityBlue',
          ($0.IntensityRequest value) => value.writeToBuffer(),
          $0.IntensityResponse.fromBuffer);
  static final _$setDistanceMin =
      $grpc.ClientMethod<$0.DistanceMinRequest, $0.DistanceMinResponse>(
          '/settings.Settings/SetDistanceMin',
          ($0.DistanceMinRequest value) => value.writeToBuffer(),
          $0.DistanceMinResponse.fromBuffer);
  static final _$setDistanceMax =
      $grpc.ClientMethod<$0.DistanceMaxRequest, $0.DistanceMaxResponse>(
          '/settings.Settings/SetDistanceMax',
          ($0.DistanceMaxRequest value) => value.writeToBuffer(),
          $0.DistanceMaxResponse.fromBuffer);
  static final _$setCameraOrderingMode = $grpc.ClientMethod<
          $0.CameraOrderingModeRequest, $0.CameraOrderingModeResponse>(
      '/settings.Settings/SetCameraOrderingMode',
      ($0.CameraOrderingModeRequest value) => value.writeToBuffer(),
      $0.CameraOrderingModeResponse.fromBuffer);
  static final _$setMsmfSelection =
      $grpc.ClientMethod<$0.MsmfSelectionRequest, $0.MsmfSelectionResponse>(
          '/settings.Settings/SetMsmfSelection',
          ($0.MsmfSelectionRequest value) => value.writeToBuffer(),
          $0.MsmfSelectionResponse.fromBuffer);
  static final _$setBackgroundMethod = $grpc.ClientMethod<
          $0.BackgroundMethodRequest, $0.BackgroundMethodResponse>(
      '/settings.Settings/SetBackgroundMethod',
      ($0.BackgroundMethodRequest value) => value.writeToBuffer(),
      $0.BackgroundMethodResponse.fromBuffer);
  static final _$setBackgroundColor =
      $grpc.ClientMethod<$0.BackgroundColorRequest, $0.BackgroundColorResponse>(
          '/settings.Settings/SetBackgroundColor',
          ($0.BackgroundColorRequest value) => value.writeToBuffer(),
          $0.BackgroundColorResponse.fromBuffer);
  static final _$setEyeGlassesCheck =
      $grpc.ClientMethod<$0.EyeGlassesCheckRequest, $0.EyeGlassesCheckResponse>(
          '/settings.Settings/SetEyeGlassesCheck',
          ($0.EyeGlassesCheckRequest value) => value.writeToBuffer(),
          $0.EyeGlassesCheckResponse.fromBuffer);
  static final _$setHeadPoseCheck =
      $grpc.ClientMethod<$0.HeadPoseCheckRequest, $0.HeadPoseCheckResponse>(
          '/settings.Settings/SetHeadPoseCheck',
          ($0.HeadPoseCheckRequest value) => value.writeToBuffer(),
          $0.HeadPoseCheckResponse.fromBuffer);
  static final _$setSharpnessCheck =
      $grpc.ClientMethod<$0.SharpnessCheckRequest, $0.SharpnessCheckResponse>(
          '/settings.Settings/SetSharpnessCheck',
          ($0.SharpnessCheckRequest value) => value.writeToBuffer(),
          $0.SharpnessCheckResponse.fromBuffer);
  static final _$setRedEyeDetectionCheck = $grpc.ClientMethod<
          $0.RedEyeDetectionCheckRequest, $0.RedEyeDetectionCheckResponse>(
      '/settings.Settings/SetRedEyeDetectionCheck',
      ($0.RedEyeDetectionCheckRequest value) => value.writeToBuffer(),
      $0.RedEyeDetectionCheckResponse.fromBuffer);
  static final _$setHeadSizeCheck =
      $grpc.ClientMethod<$0.HeadSizeCheckRequest, $0.HeadSizeCheckResponse>(
          '/settings.Settings/SetHeadSizeCheck',
          ($0.HeadSizeCheckRequest value) => value.writeToBuffer(),
          $0.HeadSizeCheckResponse.fromBuffer);
  static final _$setExpressionCheck =
      $grpc.ClientMethod<$0.ExpressionCheckRequest, $0.ExpressionCheckResponse>(
          '/settings.Settings/SetExpressionCheck',
          ($0.ExpressionCheckRequest value) => value.writeToBuffer(),
          $0.ExpressionCheckResponse.fromBuffer);
  static final _$setGazeCheck =
      $grpc.ClientMethod<$0.GazeCheckRequest, $0.GazeCheckResponse>(
          '/settings.Settings/SetGazeCheck',
          ($0.GazeCheckRequest value) => value.writeToBuffer(),
          $0.GazeCheckResponse.fromBuffer);
  static final _$setLightingEvennessCheck = $grpc.ClientMethod<
          $0.LightingEvennessCheckRequest, $0.LightingEvennessCheckResponse>(
      '/settings.Settings/SetLightingEvennessCheck',
      ($0.LightingEvennessCheckRequest value) => value.writeToBuffer(),
      $0.LightingEvennessCheckResponse.fromBuffer);
  static final _$setPhotoFormat =
      $grpc.ClientMethod<$0.PhotoFormatRequest, $0.PhotoFormatResponse>(
          '/settings.Settings/SetPhotoFormat',
          ($0.PhotoFormatRequest value) => value.writeToBuffer(),
          $0.PhotoFormatResponse.fromBuffer);
  static final _$setJpegQuality =
      $grpc.ClientMethod<$0.JpegQualityRequest, $0.JpegQualityResponse>(
          '/settings.Settings/SetJpegQuality',
          ($0.JpegQualityRequest value) => value.writeToBuffer(),
          $0.JpegQualityResponse.fromBuffer);
  static final _$setGlassesLightsOff = $grpc.ClientMethod<
          $0.GlassesLightsOffRequest, $0.GlassesLightsOffResponse>(
      '/settings.Settings/SetGlassesLightsOff',
      ($0.GlassesLightsOffRequest value) => value.writeToBuffer(),
      $0.GlassesLightsOffResponse.fromBuffer);
  static final _$setOfiqChecks =
      $grpc.ClientMethod<$0.OfiqChecksRequest, $0.OfiqChecksResponse>(
          '/settings.Settings/SetOfiqChecks',
          ($0.OfiqChecksRequest value) => value.writeToBuffer(),
          $0.OfiqChecksResponse.fromBuffer);
  static final _$setLedLayout =
      $grpc.ClientMethod<$0.LedLayoutRequest, $0.LedLayoutResponse>(
          '/settings.Settings/SetLedLayout',
          ($0.LedLayoutRequest value) => value.writeToBuffer(),
          $0.LedLayoutResponse.fromBuffer);
  static final _$setFocusLight =
      $grpc.ClientMethod<$0.FocusLightRequest, $0.FocusLightResponse>(
          '/settings.Settings/SetFocusLight',
          ($0.FocusLightRequest value) => value.writeToBuffer(),
          $0.FocusLightResponse.fromBuffer);
  static final _$setExpectedCameras =
      $grpc.ClientMethod<$0.ExpectedCamerasRequest, $0.ExpectedCamerasResponse>(
          '/settings.Settings/SetExpectedCameras',
          ($0.ExpectedCamerasRequest value) => value.writeToBuffer(),
          $0.ExpectedCamerasResponse.fromBuffer);
}

@$pb.GrpcServiceName('settings.Settings')
abstract class SettingsServiceBase extends $grpc.Service {
  $core.String get $name => 'settings.Settings';

  SettingsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.SaveSettingsRequest, $0.SaveSettingsResponse>(
            'SaveSettings',
            saveSettings_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SaveSettingsRequest.fromBuffer(value),
            ($0.SaveSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.LoadSettingsResponse>(
        'LoadSettings',
        loadSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.LoadSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ResolutionRequest, $0.ResolutionResponse>(
        'SetResolution',
        setResolution_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ResolutionRequest.fromBuffer(value),
        ($0.ResolutionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CropRequest, $0.CropResponse>(
        'SetCrop',
        setCrop_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CropRequest.fromBuffer(value),
        ($0.CropResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CropResolutionRequest,
            $0.CropResolutionResponse>(
        'SetCropResolution',
        setCropResolution_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CropResolutionRequest.fromBuffer(value),
        ($0.CropResolutionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EyesCheckRequest, $0.EyesCheckResponse>(
        'SetEyesCheck',
        setEyesCheck_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EyesCheckRequest.fromBuffer(value),
        ($0.EyesCheckResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LipsCheckRequest, $0.LipsCheckResponse>(
        'SetLipsCheck',
        setLipsCheck_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LipsCheckRequest.fromBuffer(value),
        ($0.LipsCheckResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LightingRequest, $0.LightingResponse>(
        'SetLighting',
        setLighting_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LightingRequest.fromBuffer(value),
        ($0.LightingResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IntensityRequest, $0.IntensityResponse>(
        'SetIntensityRed',
        setIntensityRed_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IntensityRequest.fromBuffer(value),
        ($0.IntensityResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IntensityRequest, $0.IntensityResponse>(
        'SetIntensityGreen',
        setIntensityGreen_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IntensityRequest.fromBuffer(value),
        ($0.IntensityResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IntensityRequest, $0.IntensityResponse>(
        'SetIntensityBlue',
        setIntensityBlue_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IntensityRequest.fromBuffer(value),
        ($0.IntensityResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DistanceMinRequest, $0.DistanceMinResponse>(
            'SetDistanceMin',
            setDistanceMin_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DistanceMinRequest.fromBuffer(value),
            ($0.DistanceMinResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DistanceMaxRequest, $0.DistanceMaxResponse>(
            'SetDistanceMax',
            setDistanceMax_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DistanceMaxRequest.fromBuffer(value),
            ($0.DistanceMaxResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CameraOrderingModeRequest,
            $0.CameraOrderingModeResponse>(
        'SetCameraOrderingMode',
        setCameraOrderingMode_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CameraOrderingModeRequest.fromBuffer(value),
        ($0.CameraOrderingModeResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.MsmfSelectionRequest, $0.MsmfSelectionResponse>(
            'SetMsmfSelection',
            setMsmfSelection_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.MsmfSelectionRequest.fromBuffer(value),
            ($0.MsmfSelectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.BackgroundMethodRequest,
            $0.BackgroundMethodResponse>(
        'SetBackgroundMethod',
        setBackgroundMethod_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.BackgroundMethodRequest.fromBuffer(value),
        ($0.BackgroundMethodResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.BackgroundColorRequest,
            $0.BackgroundColorResponse>(
        'SetBackgroundColor',
        setBackgroundColor_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.BackgroundColorRequest.fromBuffer(value),
        ($0.BackgroundColorResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EyeGlassesCheckRequest,
            $0.EyeGlassesCheckResponse>(
        'SetEyeGlassesCheck',
        setEyeGlassesCheck_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.EyeGlassesCheckRequest.fromBuffer(value),
        ($0.EyeGlassesCheckResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.HeadPoseCheckRequest, $0.HeadPoseCheckResponse>(
            'SetHeadPoseCheck',
            setHeadPoseCheck_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.HeadPoseCheckRequest.fromBuffer(value),
            ($0.HeadPoseCheckResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SharpnessCheckRequest,
            $0.SharpnessCheckResponse>(
        'SetSharpnessCheck',
        setSharpnessCheck_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SharpnessCheckRequest.fromBuffer(value),
        ($0.SharpnessCheckResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RedEyeDetectionCheckRequest,
            $0.RedEyeDetectionCheckResponse>(
        'SetRedEyeDetectionCheck',
        setRedEyeDetectionCheck_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RedEyeDetectionCheckRequest.fromBuffer(value),
        ($0.RedEyeDetectionCheckResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.HeadSizeCheckRequest, $0.HeadSizeCheckResponse>(
            'SetHeadSizeCheck',
            setHeadSizeCheck_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.HeadSizeCheckRequest.fromBuffer(value),
            ($0.HeadSizeCheckResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExpressionCheckRequest,
            $0.ExpressionCheckResponse>(
        'SetExpressionCheck',
        setExpressionCheck_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ExpressionCheckRequest.fromBuffer(value),
        ($0.ExpressionCheckResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GazeCheckRequest, $0.GazeCheckResponse>(
        'SetGazeCheck',
        setGazeCheck_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GazeCheckRequest.fromBuffer(value),
        ($0.GazeCheckResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LightingEvennessCheckRequest,
            $0.LightingEvennessCheckResponse>(
        'SetLightingEvennessCheck',
        setLightingEvennessCheck_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.LightingEvennessCheckRequest.fromBuffer(value),
        ($0.LightingEvennessCheckResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.PhotoFormatRequest, $0.PhotoFormatResponse>(
            'SetPhotoFormat',
            setPhotoFormat_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.PhotoFormatRequest.fromBuffer(value),
            ($0.PhotoFormatResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.JpegQualityRequest, $0.JpegQualityResponse>(
            'SetJpegQuality',
            setJpegQuality_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.JpegQualityRequest.fromBuffer(value),
            ($0.JpegQualityResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GlassesLightsOffRequest,
            $0.GlassesLightsOffResponse>(
        'SetGlassesLightsOff',
        setGlassesLightsOff_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GlassesLightsOffRequest.fromBuffer(value),
        ($0.GlassesLightsOffResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.OfiqChecksRequest, $0.OfiqChecksResponse>(
        'SetOfiqChecks',
        setOfiqChecks_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.OfiqChecksRequest.fromBuffer(value),
        ($0.OfiqChecksResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LedLayoutRequest, $0.LedLayoutResponse>(
        'SetLedLayout',
        setLedLayout_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LedLayoutRequest.fromBuffer(value),
        ($0.LedLayoutResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FocusLightRequest, $0.FocusLightResponse>(
        'SetFocusLight',
        setFocusLight_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FocusLightRequest.fromBuffer(value),
        ($0.FocusLightResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExpectedCamerasRequest,
            $0.ExpectedCamerasResponse>(
        'SetExpectedCameras',
        setExpectedCameras_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ExpectedCamerasRequest.fromBuffer(value),
        ($0.ExpectedCamerasResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SaveSettingsResponse> saveSettings_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SaveSettingsRequest> $request) async {
    return saveSettings($call, await $request);
  }

  $async.Future<$0.SaveSettingsResponse> saveSettings(
      $grpc.ServiceCall call, $0.SaveSettingsRequest request);

  $async.Future<$0.LoadSettingsResponse> loadSettings_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return loadSettings($call, await $request);
  }

  $async.Future<$0.LoadSettingsResponse> loadSettings(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.ResolutionResponse> setResolution_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ResolutionRequest> $request) async {
    return setResolution($call, await $request);
  }

  $async.Future<$0.ResolutionResponse> setResolution(
      $grpc.ServiceCall call, $0.ResolutionRequest request);

  $async.Future<$0.CropResponse> setCrop_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.CropRequest> $request) async {
    return setCrop($call, await $request);
  }

  $async.Future<$0.CropResponse> setCrop(
      $grpc.ServiceCall call, $0.CropRequest request);

  $async.Future<$0.CropResolutionResponse> setCropResolution_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CropResolutionRequest> $request) async {
    return setCropResolution($call, await $request);
  }

  $async.Future<$0.CropResolutionResponse> setCropResolution(
      $grpc.ServiceCall call, $0.CropResolutionRequest request);

  $async.Future<$0.EyesCheckResponse> setEyesCheck_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EyesCheckRequest> $request) async {
    return setEyesCheck($call, await $request);
  }

  $async.Future<$0.EyesCheckResponse> setEyesCheck(
      $grpc.ServiceCall call, $0.EyesCheckRequest request);

  $async.Future<$0.LipsCheckResponse> setLipsCheck_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LipsCheckRequest> $request) async {
    return setLipsCheck($call, await $request);
  }

  $async.Future<$0.LipsCheckResponse> setLipsCheck(
      $grpc.ServiceCall call, $0.LipsCheckRequest request);

  $async.Future<$0.LightingResponse> setLighting_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LightingRequest> $request) async {
    return setLighting($call, await $request);
  }

  $async.Future<$0.LightingResponse> setLighting(
      $grpc.ServiceCall call, $0.LightingRequest request);

  $async.Future<$0.IntensityResponse> setIntensityRed_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.IntensityRequest> $request) async {
    return setIntensityRed($call, await $request);
  }

  $async.Future<$0.IntensityResponse> setIntensityRed(
      $grpc.ServiceCall call, $0.IntensityRequest request);

  $async.Future<$0.IntensityResponse> setIntensityGreen_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.IntensityRequest> $request) async {
    return setIntensityGreen($call, await $request);
  }

  $async.Future<$0.IntensityResponse> setIntensityGreen(
      $grpc.ServiceCall call, $0.IntensityRequest request);

  $async.Future<$0.IntensityResponse> setIntensityBlue_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.IntensityRequest> $request) async {
    return setIntensityBlue($call, await $request);
  }

  $async.Future<$0.IntensityResponse> setIntensityBlue(
      $grpc.ServiceCall call, $0.IntensityRequest request);

  $async.Future<$0.DistanceMinResponse> setDistanceMin_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DistanceMinRequest> $request) async {
    return setDistanceMin($call, await $request);
  }

  $async.Future<$0.DistanceMinResponse> setDistanceMin(
      $grpc.ServiceCall call, $0.DistanceMinRequest request);

  $async.Future<$0.DistanceMaxResponse> setDistanceMax_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DistanceMaxRequest> $request) async {
    return setDistanceMax($call, await $request);
  }

  $async.Future<$0.DistanceMaxResponse> setDistanceMax(
      $grpc.ServiceCall call, $0.DistanceMaxRequest request);

  $async.Future<$0.CameraOrderingModeResponse> setCameraOrderingMode_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CameraOrderingModeRequest> $request) async {
    return setCameraOrderingMode($call, await $request);
  }

  $async.Future<$0.CameraOrderingModeResponse> setCameraOrderingMode(
      $grpc.ServiceCall call, $0.CameraOrderingModeRequest request);

  $async.Future<$0.MsmfSelectionResponse> setMsmfSelection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.MsmfSelectionRequest> $request) async {
    return setMsmfSelection($call, await $request);
  }

  $async.Future<$0.MsmfSelectionResponse> setMsmfSelection(
      $grpc.ServiceCall call, $0.MsmfSelectionRequest request);

  $async.Future<$0.BackgroundMethodResponse> setBackgroundMethod_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.BackgroundMethodRequest> $request) async {
    return setBackgroundMethod($call, await $request);
  }

  $async.Future<$0.BackgroundMethodResponse> setBackgroundMethod(
      $grpc.ServiceCall call, $0.BackgroundMethodRequest request);

  $async.Future<$0.BackgroundColorResponse> setBackgroundColor_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.BackgroundColorRequest> $request) async {
    return setBackgroundColor($call, await $request);
  }

  $async.Future<$0.BackgroundColorResponse> setBackgroundColor(
      $grpc.ServiceCall call, $0.BackgroundColorRequest request);

  $async.Future<$0.EyeGlassesCheckResponse> setEyeGlassesCheck_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.EyeGlassesCheckRequest> $request) async {
    return setEyeGlassesCheck($call, await $request);
  }

  $async.Future<$0.EyeGlassesCheckResponse> setEyeGlassesCheck(
      $grpc.ServiceCall call, $0.EyeGlassesCheckRequest request);

  $async.Future<$0.HeadPoseCheckResponse> setHeadPoseCheck_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.HeadPoseCheckRequest> $request) async {
    return setHeadPoseCheck($call, await $request);
  }

  $async.Future<$0.HeadPoseCheckResponse> setHeadPoseCheck(
      $grpc.ServiceCall call, $0.HeadPoseCheckRequest request);

  $async.Future<$0.SharpnessCheckResponse> setSharpnessCheck_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SharpnessCheckRequest> $request) async {
    return setSharpnessCheck($call, await $request);
  }

  $async.Future<$0.SharpnessCheckResponse> setSharpnessCheck(
      $grpc.ServiceCall call, $0.SharpnessCheckRequest request);

  $async.Future<$0.RedEyeDetectionCheckResponse> setRedEyeDetectionCheck_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RedEyeDetectionCheckRequest> $request) async {
    return setRedEyeDetectionCheck($call, await $request);
  }

  $async.Future<$0.RedEyeDetectionCheckResponse> setRedEyeDetectionCheck(
      $grpc.ServiceCall call, $0.RedEyeDetectionCheckRequest request);

  $async.Future<$0.HeadSizeCheckResponse> setHeadSizeCheck_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.HeadSizeCheckRequest> $request) async {
    return setHeadSizeCheck($call, await $request);
  }

  $async.Future<$0.HeadSizeCheckResponse> setHeadSizeCheck(
      $grpc.ServiceCall call, $0.HeadSizeCheckRequest request);

  $async.Future<$0.ExpressionCheckResponse> setExpressionCheck_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExpressionCheckRequest> $request) async {
    return setExpressionCheck($call, await $request);
  }

  $async.Future<$0.ExpressionCheckResponse> setExpressionCheck(
      $grpc.ServiceCall call, $0.ExpressionCheckRequest request);

  $async.Future<$0.GazeCheckResponse> setGazeCheck_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GazeCheckRequest> $request) async {
    return setGazeCheck($call, await $request);
  }

  $async.Future<$0.GazeCheckResponse> setGazeCheck(
      $grpc.ServiceCall call, $0.GazeCheckRequest request);

  $async.Future<$0.LightingEvennessCheckResponse> setLightingEvennessCheck_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.LightingEvennessCheckRequest> $request) async {
    return setLightingEvennessCheck($call, await $request);
  }

  $async.Future<$0.LightingEvennessCheckResponse> setLightingEvennessCheck(
      $grpc.ServiceCall call, $0.LightingEvennessCheckRequest request);

  $async.Future<$0.PhotoFormatResponse> setPhotoFormat_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PhotoFormatRequest> $request) async {
    return setPhotoFormat($call, await $request);
  }

  $async.Future<$0.PhotoFormatResponse> setPhotoFormat(
      $grpc.ServiceCall call, $0.PhotoFormatRequest request);

  $async.Future<$0.JpegQualityResponse> setJpegQuality_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.JpegQualityRequest> $request) async {
    return setJpegQuality($call, await $request);
  }

  $async.Future<$0.JpegQualityResponse> setJpegQuality(
      $grpc.ServiceCall call, $0.JpegQualityRequest request);

  $async.Future<$0.GlassesLightsOffResponse> setGlassesLightsOff_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GlassesLightsOffRequest> $request) async {
    return setGlassesLightsOff($call, await $request);
  }

  $async.Future<$0.GlassesLightsOffResponse> setGlassesLightsOff(
      $grpc.ServiceCall call, $0.GlassesLightsOffRequest request);

  $async.Future<$0.OfiqChecksResponse> setOfiqChecks_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.OfiqChecksRequest> $request) async {
    return setOfiqChecks($call, await $request);
  }

  $async.Future<$0.OfiqChecksResponse> setOfiqChecks(
      $grpc.ServiceCall call, $0.OfiqChecksRequest request);

  $async.Future<$0.LedLayoutResponse> setLedLayout_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LedLayoutRequest> $request) async {
    return setLedLayout($call, await $request);
  }

  $async.Future<$0.LedLayoutResponse> setLedLayout(
      $grpc.ServiceCall call, $0.LedLayoutRequest request);

  $async.Future<$0.FocusLightResponse> setFocusLight_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.FocusLightRequest> $request) async {
    return setFocusLight($call, await $request);
  }

  $async.Future<$0.FocusLightResponse> setFocusLight(
      $grpc.ServiceCall call, $0.FocusLightRequest request);

  $async.Future<$0.ExpectedCamerasResponse> setExpectedCameras_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExpectedCamerasRequest> $request) async {
    return setExpectedCameras($call, await $request);
  }

  $async.Future<$0.ExpectedCamerasResponse> setExpectedCameras(
      $grpc.ServiceCall call, $0.ExpectedCamerasRequest request);
}
