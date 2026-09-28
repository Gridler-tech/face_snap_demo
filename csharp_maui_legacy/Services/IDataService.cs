using GrpcLibrary.Dto;

namespace PhotoColumnApp.Services;

public interface IDataService
{
    // Kiosk functions
    IAsyncEnumerable<dynamic> StartAutomaticProcess();
    IAsyncEnumerable<dynamic> StartManualProcess();
    Task<KioskInfo> GetKioskInfo();
    Task<FocusedCamera> GetFocusedCameraIndex(int timeout);
    Task<ImageData> GetHighResolutionImageFromCameraIndex(int index, int timeout);

    Task<ImageData> GetHighResolutionImageWithIcaoChecksFromCameraIndex(int index, int timeout, bool eyesCheck,
        bool lipsCheck);

    Task<FaceRecognitionResponse> FaceRecognition(FaceRecognitionRequest faceRecognitionRequest);

    // Light functions
    Task SetAllLights(bool status);
    Task SetLightAtCameraIndex(int index);
    Task SetLightOffAtCameraIndex(int index);

    //Settings functions
    Task<KioskSettingsDto> SaveSettings(
        int width,
        int height,
        bool crop,
        int cropWidth,
        int cropHeight,
        bool eyesCheck,
        bool lipsCheck,
        bool lighting,
        int intensityRed,
        int intensityGreen,
        int intensityBlue,
        int distanceMin,
        int distanceMax,
        bool blurBackground,
        bool eyeGlassesCheck,
        bool redEyeDetectionCheck);

    Task<CameraSettings> LoadCameraSettings();
    Task<KioskSettingsDto> LoadSettings();

    Task<Resolution> SetResolution(int width, int height);
    Task<Crop> SetCrop(bool value);
    Task<Resolution> SetCropResolution(int width, int height);
    Task<EyesCheck> SetEyesCheck(bool value);
    Task<LipsCheck> SetLipsCheck(bool value);
    Task<Lighting> SetLighting(bool value);
    Task<Intensity> SetIntensityRed(int value);
    Task<Intensity> SetIntensityGreen(int value);
    Task<Intensity> SetIntensityBlue(int value);
    Task<JpegQuality> SetJpegQuality(int value);
    Task<Distance> SetDistanceMin(int value);
    Task<Distance> SetDistanceMax(int value);
    Task<BlurBackground> SetBlurBackground(bool value);
    Task<EyeGlassesCheck> SetEyeGlassesCheck(bool value);
    Task<RedEyeDetectionCheck> SetRedEyeDetectionCheck(bool value);
    Task<CameraOrderingMode> SetCameraOrderingMode(bool automatic);
    Task<MsmfSelection> SetMsmfSelection(bool enabled);
    Task<BackgroundMethod> SetBackgroundMethod(string method);
    Task<BackgroundColor> SetBackgroundColor(string color);
    Task<HeadPoseCheck> SetHeadPoseCheck(bool value);
    Task<SharpnessCheck> SetSharpnessCheck(bool value);
    Task<HeadSizeCheck> SetHeadSizeCheck(bool value);
    Task<ExpressionCheck> SetExpressionCheck(bool value);
    Task<GazeCheck> SetGazeCheck(bool value);
    Task<LightingEvennessCheck> SetLightingEvennessCheck(bool value);
    Task<PhotoFormat> SetPhotoFormat(string value);

    // Monitoring functions
    IAsyncEnumerable<(string, string)> GetKioskStatus();
    IAsyncEnumerable<Usage> OdroidUsage();

    // Calibration functions
    Task<List<CalibrationData>> GetCalibration();
    Task<CalibratedResponse> SetCalibration(List<CalibrationData> calibrationData);

    // Camera functions
    Task<Brightness> SetBrightness(int value);
    Task<Contrast> SetContrast(int value);
    Task<Saturation> SetSaturation(int value);
    Task<Hue> SetHue(int value);
    Task<WhiteBalanceTemperatureAuto> SetWhiteBalanceTemperatureAuto(bool value);
    Task<Gamma> SetGamma(int value);
    Task<Gain> SetGain(int value);
    Task<WhiteBalanceTemperature> SetWhiteBalanceTemperature(int value);
    Task<Sharpness> SetSharpness(int value);
    Task<BacklightCompensation> SetBacklightCompensation(int value);
    Task<ExposureAutoPriority> SetExposureAutoPriority(bool value);
    Task<PanAbsolute> SetPanAbsolute(int value);
    Task<TiltAbsolute> SetTiltAbsolute(int value);
    Task<ZoomAbsolute> SetZoomAbsolute(int value);
    Task<FocusAbsolute> SetFocusAbsolute(int value);
    Task<FocusAbsolute> CalibrateFocus(int cameraIndex);
    Task<ExposureAbsolute> SetExposureAbsolute(int value);
    Task<Autofocus> SetAutofocus(bool value);
}