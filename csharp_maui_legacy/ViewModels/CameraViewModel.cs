using CommunityToolkit.Maui.Core;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using GrpcLibrary.Dto;
using PhotoColumnApp.Globals;
using PhotoColumnApp.Helpers;
using PhotoColumnApp.Services;
using System.Collections.ObjectModel;
using System.Linq;

namespace PhotoColumnApp.ViewModels;


public partial class CameraViewModel : ObservableObject
{

    private readonly IDataService dataService;
    private int width;
    private int height;

    public CameraViewModel(IDataService dataService)
    {
        this.dataService = dataService;
        this.cameraResolutions = this.GetConvertedResolutionCollection();
    }

    [ObservableProperty]
    private ObservableCollection<CameraResolution> cameraResolutions;
    [ObservableProperty]
    private CameraResolution selectedResolution;
    private bool suppressResolutionChange;
    // True while RefreshValues() re-reads the loaded settings, so the switch change
    // handlers do not echo those values back to the server.
    private bool suppressValueRefresh;
    [ObservableProperty]
    private string photoResolution = KioskSettings.getResolution(KioskSettings.width, KioskSettings.height);
    [ObservableProperty]
    private int brightness = CameraSettingsGlobal.brightness;
    [ObservableProperty]
    private int contrast = CameraSettingsGlobal.contrast;
    [ObservableProperty]
    private int saturation = CameraSettingsGlobal.saturation;
    [ObservableProperty]
    private int hue = CameraSettingsGlobal.hue;
    [ObservableProperty]
    private int gamma = CameraSettingsGlobal.gamma;
    [ObservableProperty]
    private int gain = CameraSettingsGlobal.gain;
    [ObservableProperty]
    private int whiteBalanceTemperature = CameraSettingsGlobal.whiteBalanceTemperature;
    [ObservableProperty]
    private int sharpness = CameraSettingsGlobal.sharpness;
    [ObservableProperty]
    private int backlightCompensation = CameraSettingsGlobal.backlightCompensation;
    [ObservableProperty]
    private int panAbsolute = CameraSettingsGlobal.panAbsolute;
    [ObservableProperty]
    private int tiltAbsolute = CameraSettingsGlobal.tiltAbsolute;
    [ObservableProperty]
    private int zoomAbsolute = CameraSettingsGlobal.zoomAbsolute;
    [ObservableProperty]
    private int focusAbsolute = CameraSettingsGlobal.focusAbsolute;
    [ObservableProperty]
    private int exposureAbsolute = CameraSettingsGlobal.exposureAbsolute; 
    [ObservableProperty]
    private bool whiteBalanceTemperatureAuto = CameraSettingsGlobal.whiteBalanceTemperatureAuto;
    [ObservableProperty]
    private bool exposureAutoPriority = CameraSettingsGlobal.exposureAutoPriority;
    [ObservableProperty]
    private bool autofocus = CameraSettingsGlobal.autofocus;

    partial void OnWhiteBalanceTemperatureAutoChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetWhiteBalanceTemperatureAuto(value);
    }

    partial void OnExposureAutoPriorityChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetExposureAutoPriority(value);
    }

    partial void OnAutofocusChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetAutofocus(value);
    }

    // Visibility of controls the camera may not support (reported by the server).
    // Hidden so the operator isn't offered sliders that would silently do nothing.
    public bool ShowBrightness => IsSupported("brightness");
    public bool ShowContrast => IsSupported("contrast");
    public bool ShowSaturation => IsSupported("saturation");
    public bool ShowHue => IsSupported("hue");
    public bool ShowGamma => IsSupported("gamma");
    public bool ShowGain => IsSupported("gain");
    public bool ShowWhiteBalanceTemperature => IsSupported("white_balance_temperature");
    public bool ShowSharpness => IsSupported("sharpness");
    public bool ShowBacklightCompensation => IsSupported("backlight_compensation");
    public bool ShowPanAbsolute => IsSupported("pan_absolute");
    public bool ShowTiltAbsolute => IsSupported("tilt_absolute");
    public bool ShowZoomAbsolute => IsSupported("zoom_absolute");
    public bool ShowFocusAbsolute => IsSupported("focus_absolute");

    private static bool IsSupported(string propertyName) =>
        !CameraSettingsGlobal.unsupportedProperties.Contains(propertyName);

    // Per-slider limits, driven by the ranges the server probed from the actual camera.
    // When a property wasn't probed (e.g. Linux/V4L2, or an older server), the client's
    // own default is used, so behaviour is unchanged there. Exposure is intentionally
    // not probed (auto-only on these cameras) and always uses its default range.
    private static double RangeMin(string name, int fallback) =>
        CameraSettingsGlobal.propertyRanges.TryGetValue(name, out var r) && r.supported ? r.min : fallback;
    private static double RangeMax(string name, int fallback) =>
        CameraSettingsGlobal.propertyRanges.TryGetValue(name, out var r) && r.supported ? r.max : fallback;

    public double BrightnessMin => RangeMin("brightness", 0);
    public double BrightnessMax => RangeMax("brightness", 64);
    public double ContrastMin => RangeMin("contrast", 0);
    public double ContrastMax => RangeMax("contrast", 64);
    public double SaturationMin => RangeMin("saturation", 0);
    public double SaturationMax => RangeMax("saturation", 64);
    public double HueMin => RangeMin("hue", 0);
    public double HueMax => RangeMax("hue", 64);
    public double GammaMin => RangeMin("gamma", 72);
    public double GammaMax => RangeMax("gamma", 500);
    public double GainMin => RangeMin("gain", 0);
    public double GainMax => RangeMax("gain", 100);
    public double WhiteBalanceTemperatureMin => RangeMin("white_balance_temperature", 2700);
    public double WhiteBalanceTemperatureMax => RangeMax("white_balance_temperature", 10000);
    public double SharpnessMin => RangeMin("sharpness", 0);
    public double SharpnessMax => RangeMax("sharpness", 64);
    public double BacklightCompensationMin => RangeMin("backlight_compensation", 0);
    public double BacklightCompensationMax => RangeMax("backlight_compensation", 2);
    public double PanAbsoluteMin => RangeMin("pan_absolute", -36000);
    public double PanAbsoluteMax => RangeMax("pan_absolute", 36000);
    public double TiltAbsoluteMin => RangeMin("tilt_absolute", -36000);
    public double TiltAbsoluteMax => RangeMax("tilt_absolute", 36000);
    public double ZoomAbsoluteMin => RangeMin("zoom_absolute", 0);
    public double ZoomAbsoluteMax => RangeMax("zoom_absolute", 9);
    public double FocusAbsoluteMin => RangeMin("focus_absolute", 0);
    public double FocusAbsoluteMax => RangeMax("focus_absolute", 120);

    // The camera page's view model is a long-lived singleton that may be constructed
    // before the settings load. Re-raise the probed visibility/range properties so the
    // sliders resize when the page (re)appears. Called from RefreshResolutions.
    public void RefreshRanges()
    {
        foreach (var p in new[]
        {
            nameof(ShowBrightness), nameof(ShowContrast), nameof(ShowSaturation), nameof(ShowHue),
            nameof(ShowGamma), nameof(ShowGain), nameof(ShowWhiteBalanceTemperature), nameof(ShowSharpness),
            nameof(ShowBacklightCompensation), nameof(ShowPanAbsolute), nameof(ShowTiltAbsolute), nameof(ShowZoomAbsolute),
            nameof(BrightnessMin), nameof(BrightnessMax), nameof(ContrastMin), nameof(ContrastMax),
            nameof(SaturationMin), nameof(SaturationMax), nameof(HueMin), nameof(HueMax),
            nameof(GammaMin), nameof(GammaMax), nameof(GainMin), nameof(GainMax),
            nameof(WhiteBalanceTemperatureMin), nameof(WhiteBalanceTemperatureMax),
            nameof(SharpnessMin), nameof(SharpnessMax), nameof(BacklightCompensationMin), nameof(BacklightCompensationMax),
            nameof(PanAbsoluteMin), nameof(PanAbsoluteMax), nameof(TiltAbsoluteMin), nameof(TiltAbsoluteMax),
            nameof(ZoomAbsoluteMin), nameof(ZoomAbsoluteMax),
            nameof(ShowFocusAbsolute), nameof(FocusAbsoluteMin), nameof(FocusAbsoluteMax),
        })
        {
            OnPropertyChanged(p);
        }
    }

    [RelayCommand]
    async Task BrightnessDragCompleted()
    {
        try
        {
            Brightness result = await dataService.SetBrightness(Brightness);
            SemanticScreenReader.Announce($"Brightness was set to {Brightness}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Brightness server error {e.Message}");
            ToastMessage.Show($"Brightness server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task ContrastDragCompleted()
    {
        try
        {
            Contrast result = await dataService.SetContrast(Contrast);
            SemanticScreenReader.Announce($"Contrast was set to {Contrast}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Contrast server error {e.Message}");
            ToastMessage.Show($"Contrast server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task SaturationDragCompleted()
    {
        try
        {
            Saturation result = await dataService.SetSaturation(Saturation);
            SemanticScreenReader.Announce($"Saturation was set to {Saturation}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Saturation server error {e.Message}");
            ToastMessage.Show($"Saturation server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task HueDragCompleted()
    {
        try
        {
            Hue result = await dataService.SetHue(Hue);
            SemanticScreenReader.Announce($"Hue was set to {Hue}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Hue server error {e.Message}");
            ToastMessage.Show($"Hue server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task GammaDragCompleted()
    {
        try
        {
            Gamma result = await dataService.SetGamma(Gamma);
            SemanticScreenReader.Announce($"Gamma was set to {Gamma}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Gamma server error {e.Message}");
            ToastMessage.Show($"Gamma server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task GainDragCompleted()
    {
        try
        {
            Gain result = await dataService.SetGain(Gain);
            SemanticScreenReader.Announce($"Gain was set to {Gain}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Gain server error {e.Message}");
            ToastMessage.Show($"Gain server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task WhiteBalanceTemperatureDragCompleted()
    {
        try
        {
            WhiteBalanceTemperature result = await dataService.SetWhiteBalanceTemperature(WhiteBalanceTemperature);
            SemanticScreenReader.Announce($"WhiteBalanceTemperature was set to {WhiteBalanceTemperature}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"White Balance Temperature server error {e.Message}");
            ToastMessage.Show($"White Balance Temperature server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task SharpnessDragCompleted()
    {
        try
        {
            Sharpness result = await dataService.SetSharpness(Sharpness);
            SemanticScreenReader.Announce($"Sharpness was set to {Sharpness}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Sharpness server error {e.Message}");
            ToastMessage.Show($"Sharpness server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task BacklightCompensationDragCompleted()
    {
        try
        {
            BacklightCompensation result = await dataService.SetBacklightCompensation(BacklightCompensation);
            SemanticScreenReader.Announce($"BacklightCompensation was set to {BacklightCompensation}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"BacklightCompensation server error {e.Message}");
            ToastMessage.Show($"Backlight Compensation server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task PanAbsoluteDragCompleted()
    {
        try
        {
            PanAbsolute result = await dataService.SetPanAbsolute(PanAbsolute);
            SemanticScreenReader.Announce($"PanAbsolute was set to {PanAbsolute}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"PanAbsolute server error {e.Message}");
            ToastMessage.Show($"Pan Absolute server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task TiltAbsoluteDragCompleted()
    {
        try
        {
            TiltAbsolute result = await dataService.SetTiltAbsolute(TiltAbsolute);
            SemanticScreenReader.Announce($"TiltAbsolute was set to {TiltAbsolute}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"TiltAbsolute server error {e.Message}");
            ToastMessage.Show($"Tilt Absolute server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task FocusAbsoluteDragCompleted()
    {
        try
        {
            FocusAbsolute result = await dataService.SetFocusAbsolute(FocusAbsolute);
            SemanticScreenReader.Announce($"FocusAbsolute was set to {FocusAbsolute}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"FocusAbsolute server error {e.Message}");
            ToastMessage.Show($"Focus Absolute server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task ZoomAbsoluteDragCompleted()
    {
        try
        {
            ZoomAbsolute result = await dataService.SetZoomAbsolute(ZoomAbsolute);
            SemanticScreenReader.Announce($"ZoomAbsolute was set to {ZoomAbsolute}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"ZoomAbsolute server error {e.Message}");
            ToastMessage.Show($"Zoom Absolute server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task ExposureAbsoluteDragCompleted()
    {
        try
        {
            ExposureAbsolute result = await dataService.SetExposureAbsolute(ExposureAbsolute);
            SemanticScreenReader.Announce($"ExposureAbsolute was set to {ExposureAbsolute}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"ExposureAbsolute server error {e.Message}");
            ToastMessage.Show($"Exposure Absolute server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetWhiteBalanceTemperatureAuto(bool value)
    {
        try
        {
            WhiteBalanceTemperatureAuto result = await dataService.SetWhiteBalanceTemperatureAuto(value);
            SemanticScreenReader.Announce($"WhiteBalanceTemperatureAuto was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"White Balance Temperature Auto server error {e.Message}");
            ToastMessage.Show($"White Balance Temperature Auto server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetExposureAutoPriority(bool value)
    {
        try
        {
            ExposureAutoPriority result = await dataService.SetExposureAutoPriority(value);
            SemanticScreenReader.Announce($"SetExposureAutoPriority was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"SetExposureAutoPriority server error {e.Message}");
            ToastMessage.Show($"Set Exposure Auto Priority server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetAutofocus(bool value)
    {
        try
        {
            Autofocus result = await dataService.SetAutofocus(value);
            SemanticScreenReader.Announce($"SetAutofocus was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"SetAutofocus server error {e.Message}");
            ToastMessage.Show($"Set Autofocus server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    // Rebuild the resolution list from the latest server data (fetched at login) and
    // preselect the current one. Called when the camera page appears, because this view
    // model is a long-lived singleton whose constructor may run before the list loads.
    public void RefreshResolutions()
    {
        suppressResolutionChange = true;
        CameraResolutions = GetConvertedResolutionCollection();
        SelectedResolution = CameraResolutions.FirstOrDefault(
            r => r.width == KioskSettings.width && r.height == KioskSettings.height);
        suppressResolutionChange = false;

        // Refresh the probed slider ranges/visibility now that settings are loaded.
        RefreshRanges();
        RefreshValues();
    }

    // This singleton is often constructed BEFORE the login sequence has loaded the
    // settings, so the field initializers snapshot stale defaults. Re-read every value
    // from the loaded globals whenever the page appears. Sliders only push to the server
    // on drag-completed; the switches are guarded by suppressValueRefresh.
    public void RefreshValues()
    {
        suppressValueRefresh = true;
        Brightness = CameraSettingsGlobal.brightness;
        Contrast = CameraSettingsGlobal.contrast;
        Saturation = CameraSettingsGlobal.saturation;
        Hue = CameraSettingsGlobal.hue;
        Gamma = CameraSettingsGlobal.gamma;
        Gain = CameraSettingsGlobal.gain;
        WhiteBalanceTemperature = CameraSettingsGlobal.whiteBalanceTemperature;
        Sharpness = CameraSettingsGlobal.sharpness;
        BacklightCompensation = CameraSettingsGlobal.backlightCompensation;
        PanAbsolute = CameraSettingsGlobal.panAbsolute;
        TiltAbsolute = CameraSettingsGlobal.tiltAbsolute;
        ZoomAbsolute = CameraSettingsGlobal.zoomAbsolute;
        FocusAbsolute = CameraSettingsGlobal.focusAbsolute;
        ExposureAbsolute = CameraSettingsGlobal.exposureAbsolute;
        WhiteBalanceTemperatureAuto = CameraSettingsGlobal.whiteBalanceTemperatureAuto;
        ExposureAutoPriority = CameraSettingsGlobal.exposureAutoPriority;
        Autofocus = CameraSettingsGlobal.autofocus;
        suppressValueRefresh = false;
    }

    async partial void OnSelectedResolutionChanged(CameraResolution value)
    {
        if (suppressResolutionChange || value == null)
            return;

        this.width = value.width;
        this.height = value.height;
        try
        {
            Resolution result = await dataService.SetResolution(value.width, value.height);
            KioskSettings.width = value.width;
            KioskSettings.height = value.height;
            SemanticScreenReader.Announce($"Resolution set to {value.description}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Resolution server error {e.Message}");
            ToastMessage.Show($"Set Resolution server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private ObservableCollection<CameraResolution> GetConvertedResolutionCollection()
    {
        var c = new ObservableCollection<CameraResolution>();
        foreach (var cr in KioskSettings.cameraResolutions)
        {
            var camRes = new CameraResolution
            {
                height = cr.height,
                width = cr.width,
                description = KioskSettings.getResolution(cr.width, cr.height)
            };
            c.Add(camRes);
        }
        return c;
    }

    private async void SetResolution(int width, int height)
    {
        try
        {
            KioskSettings.width = width;
            KioskSettings.height = height;
            Resolution result = await dataService.SetResolution(width, height);
            SemanticScreenReader.Announce($"SetResolution was set to {width}, {height}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Resolution server error {e.Message}");
            ToastMessage.Show($"Set Resolution server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    async partial void OnPhotoResolutionChanged(string value)
    {
        var resolution = KioskSettings.getResolution(value);
        this.width = resolution.width;
        this.height = resolution.height;

        try
        {
            Resolution result = await dataService.SetResolution(this.width, this.height);
            SemanticScreenReader.Announce($"OnPhotoResolutionChanged was set to {value}");
            KioskSettings.width = this.width;
            KioskSettings.height = this.height;
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Photo Resolution Changed server error {e.Message}");
            ToastMessage.Show($"Photo Resolution Changed server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }
}

public partial class CameraResolution : ObservableObject
{
    public string description { get; set; }
    public int width { get; set; }
    public int height { get; set; }
}

