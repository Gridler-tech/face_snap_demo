using GrpcLibrary;
using GrpcLibrary.Dto;
using FaceRecognitionRequest = GrpcLibrary.Dto.FaceRecognitionRequest;
using FaceRecognitionResponse = GrpcLibrary.Dto.FaceRecognitionResponse;
using KioskInfo = GrpcLibrary.Dto.KioskInfo;

namespace PhotoColumnApp.Services;

public class DataService : IDataService
{
    private readonly ICalibrationProcessor calibrationProcessor;
    private readonly ICameraProcessor cameraProcessor;
    private readonly IKioskProcessor kioskProcessor;
    private readonly ILightProcessor lightProcessor;
    private readonly IMonitoringProcessor monitoringProcessor;
    private readonly ISettingsProcessor settingsProcessor;

    public DataService(
        IKioskProcessor kioskProcessor,
        ILightProcessor lightProcessor,
        ICameraProcessor cameraProcessor,
        IMonitoringProcessor monitoringProcessor,
        ISettingsProcessor settingsProcessor,
        ICalibrationProcessor calibrationProcessor
    )
    {
        this.kioskProcessor = kioskProcessor;
        this.lightProcessor = lightProcessor;
        this.cameraProcessor = cameraProcessor;
        this.monitoringProcessor = monitoringProcessor;
        this.settingsProcessor = settingsProcessor;
        this.calibrationProcessor = calibrationProcessor;
    }

    // Kiosk functions
    public async IAsyncEnumerable<dynamic> StartAutomaticProcess()
    {
        await foreach (var item in kioskProcessor.StartAutomaticProcess()) yield return item;
    }

    public async IAsyncEnumerable<dynamic> StartManualProcess()
    {
        await foreach (var item in kioskProcessor.StartManualProcess()) yield return item;
    }

    public async Task<FocusedCamera> GetFocusedCameraIndex(int timeout)
    {
        return await kioskProcessor.GetFocusedCameraIndex(timeout);
    }

    public async Task<KioskInfo> GetKioskInfo()
    {
        return await kioskProcessor.GetKioskInfo();
    }

    public async Task<ImageData> GetHighResolutionImageFromCameraIndex(int index, int timeout)
    {
        return await kioskProcessor.GetHighResolutionImageFromCameraIndex(index, timeout);
    }

    public async Task<ImageData> GetHighResolutionImageWithIcaoChecksFromCameraIndex(int index, int timeout,
        bool eyesCheck, bool lipsCheck)
    {
        return await kioskProcessor.GetHighResolutionImageWithIcaoChecksFromCameraIndex(index, timeout, eyesCheck,
            lipsCheck);
    }

    public async Task<FaceRecognitionResponse> FaceRecognition(FaceRecognitionRequest faceRecognitionRequest)
    {
        //throw new NotImplementedException();

        var result = await kioskProcessor.FaceRecognition(faceRecognitionRequest);

        FaceRecognitionResponse faceRecognitionResponse = new()
        {
            verified = result.verified,
            distance = result.distance,
            threshold = result.threshold,
            model = result.model,
            similarity_metric = result.similarity_metric,
            time = result.time,
            status = result.status
        };

        return faceRecognitionResponse;
    }


    // Light functions
    public async Task SetAllLights(bool value)
    {
        await lightProcessor.SetAllLights(value);
    }

    public async Task SetLightAtCameraIndex(int value)
    {
        await lightProcessor.SetLightAtCameraIndex(value);
    }

    public async Task SetLightOffAtCameraIndex(int value)
    {
        await lightProcessor.SetLightOffAtCameraIndex(value);
    }

    //Settings functions
    public async Task<KioskSettingsDto> SaveSettings(
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
        bool redEyeDetectionCheck
    )
    {
        return await settingsProcessor.SaveSettings(
            width,
            height,
            crop,
            cropWidth,
            cropHeight,
            eyesCheck,
            lipsCheck,
            lighting,
            intensityRed,
            intensityGreen,
            intensityBlue,
            distanceMin,
            distanceMax,
            blurBackground,
            eyeGlassesCheck,
            redEyeDetectionCheck
        );
    }

    public async Task<CameraSettings> LoadCameraSettings()
    {
        return await cameraProcessor.LoadSettings();
    }

    public async Task<KioskSettingsDto> LoadSettings()
    {
        return await settingsProcessor.LoadSettings();
    }

    public async Task<Resolution> SetResolution(int width, int height)
    {
        return await settingsProcessor.SetResolution(width, height);
    }

    public async Task<Crop> SetCrop(bool value)
    {
        return await settingsProcessor.SetCrop(value);
    }

    public async Task<Resolution> SetCropResolution(int width, int height)
    {
        return await settingsProcessor.SetCropResolution(width, height);
    }

    public async Task<EyesCheck> SetEyesCheck(bool value)
    {
        return await settingsProcessor.SetEyesCheck(value);
    }

    public async Task<LipsCheck> SetLipsCheck(bool value)
    {
        return await settingsProcessor.SetLipsCheck(value);
    }

    public async Task<Lighting> SetLighting(bool value)
    {
        return await settingsProcessor.SetLighting(value);
    }

    public async Task<BlurBackground> SetBlurBackground(bool value)
    {
        return await settingsProcessor.SetBlurBackground(value);
    }

    public async Task<CameraOrderingMode> SetCameraOrderingMode(bool automatic)
    {
        return await settingsProcessor.SetCameraOrderingMode(automatic);
    }

    public async Task<MsmfSelection> SetMsmfSelection(bool enabled)
    {
        return await settingsProcessor.SetMsmfSelection(enabled);
    }

    public async Task<BackgroundMethod> SetBackgroundMethod(string method)
    {
        return await settingsProcessor.SetBackgroundMethod(method);
    }

    public async Task<HeadPoseCheck> SetHeadPoseCheck(bool value)
    {
        return await settingsProcessor.SetHeadPoseCheck(value);
    }

    public async Task<SharpnessCheck> SetSharpnessCheck(bool value)
    {
        return await settingsProcessor.SetSharpnessCheck(value);
    }

    public async Task<HeadSizeCheck> SetHeadSizeCheck(bool value)
    {
        return await settingsProcessor.SetHeadSizeCheck(value);
    }

    public async Task<ExpressionCheck> SetExpressionCheck(bool value)
    {
        return await settingsProcessor.SetExpressionCheck(value);
    }

    public async Task<GazeCheck> SetGazeCheck(bool value)
    {
        return await settingsProcessor.SetGazeCheck(value);
    }

    public async Task<LightingEvennessCheck> SetLightingEvennessCheck(bool value)
    {
        return await settingsProcessor.SetLightingEvennessCheck(value);
    }

    public async Task<PhotoFormat> SetPhotoFormat(string value)
    {
        return await settingsProcessor.SetPhotoFormat(value);
    }

    public async Task<BackgroundColor> SetBackgroundColor(string color)
    {
        return await settingsProcessor.SetBackgroundColor(color);
    }

    public async Task<EyeGlassesCheck> SetEyeGlassesCheck(bool value)
    {
        return await settingsProcessor.SetEyeGlassesCheck(value);
    }

    public async Task<RedEyeDetectionCheck> SetRedEyeDetectionCheck(bool value)
    {
        return await settingsProcessor.SetRedEyeDetectionCheck(value);
    }

    public async Task<Intensity> SetIntensityRed(int value)
    {
        return await settingsProcessor.SetIntensityRed(value);
    }

    public async Task<Intensity> SetIntensityGreen(int value)
    {
        return await settingsProcessor.SetIntensityGreen(value);
    }

    public async Task<Intensity> SetIntensityBlue(int value)
    {
        return await settingsProcessor.SetIntensityBlue(value);
    }

    public async Task<JpegQuality> SetJpegQuality(int value)
    {
        return await settingsProcessor.SetJpegQuality(value);
    }

    public async Task<Distance> SetDistanceMin(int value)
    {
        return await settingsProcessor.SetDistanceMin(value);
    }

    public async Task<Distance> SetDistanceMax(int value)
    {
        return await settingsProcessor.SetDistanceMax(value);
    }

    // Monitoring functions
    public async IAsyncEnumerable<(string, string)> GetKioskStatus()
    {
        //return await kioskProcessor.GetKioskStatus();
        await foreach (var item in monitoringProcessor.GetKioskStatus()) yield return item;
    }

    public async IAsyncEnumerable<Usage> OdroidUsage()
    {
        await foreach (var item in monitoringProcessor.OdroidUsage()) yield return item;
    }

    // Calibration functions
    public async Task<List<CalibrationData>> GetCalibration()
    {
        return await calibrationProcessor.GetCalibration();
    }

    public async Task<CalibratedResponse> SetCalibration(List<CalibrationData> calibrationData)
    {
        return await calibrationProcessor.SetCalibration(calibrationData);
    }

    // Camera functions
    public async Task<Brightness> SetBrightness(int value)
    {
        return await cameraProcessor.SetBrightness(value);
    }

    public async Task<Contrast> SetContrast(int value)
    {
        return await cameraProcessor.SetContrast(value);
    }

    public async Task<Saturation> SetSaturation(int value)
    {
        return await cameraProcessor.SetSaturation(value);
    }

    public async Task<Hue> SetHue(int value)
    {
        return await cameraProcessor.SetHue(value);
    }

    public async Task<WhiteBalanceTemperatureAuto> SetWhiteBalanceTemperatureAuto(bool value)
    {
        return await cameraProcessor.SetWhiteBalanceTemperatureAuto(value);
    }

    public async Task<Gamma> SetGamma(int value)
    {
        return await cameraProcessor.SetGamma(value);
    }

    public async Task<Gain> SetGain(int value)
    {
        return await cameraProcessor.SetGain(value);
    }

    public async Task<WhiteBalanceTemperature> SetWhiteBalanceTemperature(int value)
    {
        return await cameraProcessor.SetWhiteBalanceTemperature(value);
    }

    public async Task<Sharpness> SetSharpness(int value)
    {
        return await cameraProcessor.SetSharpness(value);
    }

    public async Task<BacklightCompensation> SetBacklightCompensation(int value)
    {
        return await cameraProcessor.SetBacklightCompensation(value);
    }

    public async Task<ExposureAutoPriority> SetExposureAutoPriority(bool value)
    {
        return await cameraProcessor.SetExposureAutoPriority(value);
    }

    public async Task<Autofocus> SetAutofocus(bool value)
    {
        return await cameraProcessor.SetAutofocus(value);
    }

    public async Task<PanAbsolute> SetPanAbsolute(int value)
    {
        return await cameraProcessor.SetPanAbsolute(value);
    }

    public async Task<TiltAbsolute> SetTiltAbsolute(int value)
    {
        return await cameraProcessor.SetTiltAbsolute(value);
    }

    public async Task<ZoomAbsolute> SetZoomAbsolute(int value)
    {
        return await cameraProcessor.SetZoomAbsolute(value);
    }

    public async Task<FocusAbsolute> SetFocusAbsolute(int value)
    {
        return await cameraProcessor.SetFocusAbsolute(value);
    }

    public async Task<FocusAbsolute> CalibrateFocus(int cameraIndex)
    {
        return await cameraProcessor.CalibrateFocus(cameraIndex);
    }

    public async Task<ExposureAbsolute> SetExposureAbsolute(int value)
    {
        return await cameraProcessor.SetExposureAbsolute(value);
    }
}