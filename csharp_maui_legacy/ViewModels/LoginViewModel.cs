using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using PhotoColumnApp.Services;
using PhotoColumnApp.Globals;
using CommunityToolkit.Maui.Core;
using GrpcLibrary.Dto;
using PhotoColumnApp.Helpers;

namespace PhotoColumnApp.ViewModels;

public partial class LoginViewModel : ObservableObject
{
    private readonly IDataService dataService;

    public LoginViewModel(IDataService dataService)
    {
        this.dataService = dataService;

        // Init kiosk / Health check
        Task.Run(async () => await this.LoadSettings());
        Task.Run(async () => await this.LoadCameraSettings());
    }

    [RelayCommand]
    static async Task Navigate(string uri)
    {
        await Shell.Current.GoToAsync(uri);
    }

    private async Task LoadCameraSettings()
    {
        try
        {
            CameraSettings result = await dataService.LoadCameraSettings();

            CameraSettingsGlobal.brightness = result.brightness;
            CameraSettingsGlobal.contrast = result.contrast;
            CameraSettingsGlobal.saturation = result.saturation;
            CameraSettingsGlobal.hue = result.hue;
            CameraSettingsGlobal.whiteBalanceTemperatureAuto = result.whiteBalanceTemperatureAuto;
            CameraSettingsGlobal.gamma = result.gamma;
            CameraSettingsGlobal.gain = result.gain;
            CameraSettingsGlobal.whiteBalanceTemperature = result.whiteBalanceTemperature;
            CameraSettingsGlobal.sharpness = result.sharpness;
            CameraSettingsGlobal.backlightCompensation = result.backlightCompensation;
            CameraSettingsGlobal.exposureAutoPriority = result.exposureAutoPriority;
            CameraSettingsGlobal.panAbsolute = result.panAbsolute;
            CameraSettingsGlobal.tiltAbsolute = result.tiltAbsolute;
            CameraSettingsGlobal.zoomAbsolute = result.zoomAbsolute;
            CameraSettingsGlobal.focusAbsolute = result.focusAbsolute;
            CameraSettingsGlobal.exposureAbsolute = result.exposureAbsolute;
            CameraSettingsGlobal.autofocus = result.autofocus;
            CameraSettingsGlobal.unsupportedProperties = result.unsupportedProperties ?? new System.Collections.Generic.List<string>();
            CameraSettingsGlobal.propertyRanges = result.propertyRanges ?? new System.Collections.Generic.Dictionary<string, GrpcLibrary.Dto.PropertyRange>();
        }

        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Load Camera settings server error {e.Message}");
            SemanticScreenReader.Announce($"Camera settings could not be loaded error");

            //Show toast and navigate to settings page so the server ip address can be changed
            ToastMessage.Show("Server could not be reached, please change ip address and restart application", 18, ToastDuration.Long, "//SettingsPage");
        }
    }

    private async Task LoadSettings()
    {
        try
        {
            KioskSettingsDto result = await dataService.LoadSettings();

            // When save succesful
            KioskSettings.width = result.width;
            KioskSettings.height = result.height;
            KioskSettings.crop = result.crop;
            KioskSettings.cropWidth = result.cropWidth;
            KioskSettings.cropHeight = result.cropHeight;
            KioskSettings.eyesCheck = result.eyesCheck;
            KioskSettings.lipsCheck = result.lipsCheck;
            KioskSettings.lighting = result.lighting;
            KioskSettings.intensityRed = result.intensityRed;
            KioskSettings.intensityGreen = result.intensityGreen;
            KioskSettings.intensityBlue = result.intensityBlue;
            KioskSettings.distanceMin = result.distanceMin;
            KioskSettings.distanceMax = result.distanceMax;
            KioskSettings.msmfSelection = result.msmfSelection;
            KioskSettings.backgroundMethod = string.IsNullOrEmpty(result.backgroundMethod) ? "none" : result.backgroundMethod;
            KioskSettings.backgroundColor = result.backgroundColor;
            KioskSettings.jpegQuality = result.jpegQuality;
            KioskSettings.eyeGlassesCheck = result.eyeGlassesCheck;
            KioskSettings.headPoseCheck = result.headPoseCheck;
            KioskSettings.sharpnessCheck = result.sharpnessCheck;
            KioskSettings.redEyeDetectionCheck = result.redEyeDetectionCheck;
            KioskSettings.headSizeCheck = result.headSizeCheck;
            KioskSettings.expressionCheck = result.expressionCheck;
            KioskSettings.gazeCheck = result.gazeCheck;
            KioskSettings.lightingEvennessCheck = result.lightingEvennessCheck;
            KioskSettings.photoFormat = string.IsNullOrEmpty(result.photoFormat) ? "icao_35x45" : result.photoFormat;
            KioskSettings.cameraResolutions = result.cameraResolutions;
        }

        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Load kiosk settings server error {e.Message}");
            SemanticScreenReader.Announce($"Kios error. settings could not be loaded");

            //Show toast and navigate to settings page so the server ip address can be changed
            ToastMessage.Show("Server could not be reached, please change ip address and restart application", 18, ToastDuration.Long, "//SettingsPage");

        }
    }
}


