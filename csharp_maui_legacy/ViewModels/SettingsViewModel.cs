using System.Collections.ObjectModel;
using CommunityToolkit.Maui.Core;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using GrpcLibrary;
using GrpcLibrary.Dto;
using PhotoColumnApp.Globals;
using PhotoColumnApp.Helpers;
using PhotoColumnApp.Services;

namespace PhotoColumnApp.ViewModels;

public partial class SettingsViewModel : ObservableObject
{
    private readonly IDataService dataService;
    private readonly ServerProcessManager serverManager = new(
        KioskConfiguration.kioskServerIpAddress,
        KioskConfiguration.serverExecutablePath);
    private int width;
    private int height;

    private bool suppressBackgroundMethodChange;
    // True while RefreshValues() re-reads the loaded settings, so the checkbox/entry
    // change handlers do not echo those values back to the server.
    private bool suppressValueRefresh;
    private bool suppressPhotoFormatChange;
    private bool suppressStartAtLogonChange;

    public SettingsViewModel(IDataService dataService)
    {
        this.dataService = dataService;

        this.cameraResolutions = this.GetConvertedResolutionCollection();

        // Preselect the current background method without echoing it back to the server.
        suppressBackgroundMethodChange = true;
        SelectedBackgroundMethod = BackgroundMethods.FirstOrDefault(m => m.code == KioskSettings.backgroundMethod)
                                   ?? BackgroundMethods[0];
        suppressBackgroundMethodChange = false;

        // Preselect the current photo format without echoing it back to the server.
        suppressPhotoFormatChange = true;
        SelectedPhotoFormat = PhotoFormats.FirstOrDefault(f => f.code == KioskSettings.photoFormat)
                              ?? PhotoFormats[0];
        suppressPhotoFormatChange = false;
    }

    [ObservableProperty]
    private ObservableCollection<CameraResolution> cameraResolutions;

    // The address is stored as one "http://host:port" string; the UI edits
    // host and port separately and SaveIpAddress recomposes them.
    [ObservableProperty]
    private string serverHost = ParseServerHost(KioskConfiguration.kioskServerIpAddress);

    [ObservableProperty]
    private string serverPort = ParseServerPort(KioskConfiguration.kioskServerIpAddress);

    private static string ParseServerHost(string address) =>
        Uri.TryCreate(address, UriKind.Absolute, out var uri) ? uri.Host : "localhost";

    private static string ParseServerPort(string address) =>
        Uri.TryCreate(address, UriKind.Absolute, out var uri) ? uri.Port.ToString() : "50051";

    [ObservableProperty]
    private string photoResolution = KioskSettings.getResolution(KioskSettings.width, KioskSettings.height);
    [ObservableProperty]
    private bool crop = KioskSettings.crop;
    [ObservableProperty]
    private int cropWidth = KioskSettings.cropWidth;
    [ObservableProperty]
    private int cropHeight = KioskSettings.cropHeight;
    [ObservableProperty]
    private bool eyesCheck = KioskSettings.eyesCheck;
    [ObservableProperty]
    private bool lipsCheck = KioskSettings.lipsCheck;
    [ObservableProperty]
    private bool lighting = KioskSettings.lighting;
    [ObservableProperty]
    private bool blurBackground = KioskSettings.blurBackground;
    [ObservableProperty]
    private bool eyeGlassesCheck = KioskSettings.eyeGlassesCheck;
    [ObservableProperty]
    private bool headPoseCheck = KioskSettings.headPoseCheck;
    [ObservableProperty]
    private bool sharpnessCheck = KioskSettings.sharpnessCheck;
    [ObservableProperty]
    private bool headSizeCheck = KioskSettings.headSizeCheck;
    [ObservableProperty]
    private bool expressionCheck = KioskSettings.expressionCheck;
    [ObservableProperty]
    private bool gazeCheck = KioskSettings.gazeCheck;
    [ObservableProperty]
    private bool lightingEvennessCheck = KioskSettings.lightingEvennessCheck;
    [ObservableProperty]
    private bool redEyeDetectionCheck = KioskSettings.redEyeDetectionCheck;
    [ObservableProperty]
    private int intensityRed = KioskSettings.intensityRed;
    [ObservableProperty]
    private int intensityGreen = KioskSettings.intensityGreen;
    [ObservableProperty]
    private int intensityBlue = KioskSettings.intensityBlue;
    [ObservableProperty]
    private int distanceMin = KioskSettings.distanceMin;
    [ObservableProperty]
    private int distanceMax = KioskSettings.distanceMax;
    [ObservableProperty]
    private int jpegQuality = KioskSettings.jpegQuality;
    [ObservableProperty]
    private bool msmfSelection = KioskSettings.msmfSelection;
    [ObservableProperty]
    private string backgroundColor = KioskSettings.backgroundColor;

    // Background erasing method: display options for the picker, mapped to the codes the
    // server understands ("none"/"mediapipe"/"modnet"/"rembg").
    public ObservableCollection<BackgroundMethodOption> BackgroundMethods { get; } = new()
    {
        new BackgroundMethodOption { code = "none", display = "No background erasing" },
        new BackgroundMethodOption { code = "mediapipe", display = "MediaPipe (fast)" },
        new BackgroundMethodOption { code = "modnet", display = "MODNet (portrait matting)" },
        new BackgroundMethodOption { code = "rembg", display = "rembg (best quality, slower)" },
    };

    [ObservableProperty]
    private BackgroundMethodOption selectedBackgroundMethod;

    // Show the colour entry only when a method is active.
    public bool ShowBackgroundColor => SelectedBackgroundMethod != null && SelectedBackgroundMethod.code != "none";

    // Photo format: the aspect ratio and face framing of the final image. The crop
    // height is derived from the crop width and the format's aspect ratio.
    public ObservableCollection<PhotoFormatOption> PhotoFormats { get; } = new()
    {
        new PhotoFormatOption { code = "icao_35x45", display = "35 × 45 mm (7:9) — international" },
        new PhotoFormatOption { code = "us_2x2", display = "2 × 2 in (1:1) — USA / India" },
        new PhotoFormatOption { code = "ca_50x70", display = "50 × 70 mm (5:7) — Canada" },
    };

    [ObservableProperty]
    private PhotoFormatOption selectedPhotoFormat;


    [RelayCommand]
    async Task SaveIpAddress()
    {
        // Tolerate a pasted full address in the host field.
        var host = (ServerHost ?? string.Empty).Trim()
            .Replace("http://", string.Empty)
            .Replace("https://", string.Empty)
            .TrimEnd('/');
        if (host.Length == 0 || !int.TryParse(ServerPort, out var port) || port < 1 || port > 65535)
            return;

        var address = $"http://{host}:{port}";
        await KioskConfiguration.SaveKioskIpAddressAsync(address);
        // Repoint the shared gRPC channel so the new address is used
        // immediately, without restarting the application.
        GrpcChannelProvider.SetAddress(address);
    }

    // ----- Server control (start/stop + start at logon) -----

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(ServerActionText))]
    private bool serverRunning;

    [ObservableProperty]
    private bool serverBusy;

    [ObservableProperty]
    private string serverStatusText = "Checking...";

    [ObservableProperty]
    private bool startAtLogon;

    // Errors/warnings from the server controls; toasts are suppressed in this
    // unpackaged app, so problems are shown in a label right next to the controls.
    [ObservableProperty]
    private string serverMessage = "";

    public string ServerActionText => ServerRunning ? "Stop server" : "Start server";

    public async Task RefreshServerStateAsync()
    {
        ServerRunning = await serverManager.IsRunningAsync();
        ServerStatusText = ServerRunning ? "Server is running" : "Server is not running";

        suppressStartAtLogonChange = true;
        StartAtLogon = ServerAutostart.IsEnabled;
        suppressStartAtLogonChange = false;
    }

    [RelayCommand]
    async Task ToggleServer()
    {
        if (ServerBusy) return;
        ServerBusy = true;
        ServerMessage = "";
        try
        {
            if (ServerRunning)
            {
                ServerStatusText = "Stopping server...";
                var stopped = await serverManager.StopAnyAsync(TimeSpan.FromSeconds(15));
                if (!stopped)
                    ServerMessage = "The server could not be stopped.";
            }
            else
            {
                ServerStatusText = "Starting server... (this can take a minute)";
                var started = await serverManager.EnsureRunningAsync(TimeSpan.FromSeconds(90));
                if (!started)
                    ServerMessage = "The server did not start. Is it installed? " +
                                    $"Expected at: {KioskConfiguration.serverExecutablePath}";
            }
        }
        finally
        {
            await RefreshServerStateAsync();
            ServerBusy = false;
        }
    }

    partial void OnStartAtLogonChanged(bool value)
    {
        if (suppressStartAtLogonChange) return;

        var error = value
            ? ServerAutostart.Enable(KioskConfiguration.serverExecutablePath)
            : ServerAutostart.Disable();

        if (error != null)
        {
            // Revert the switch so it keeps showing the true state.
            suppressStartAtLogonChange = true;
            StartAtLogon = ServerAutostart.IsEnabled;
            suppressStartAtLogonChange = false;
        }
        ServerMessage = error ?? "";
    }

    // This singleton is often constructed BEFORE the login sequence has loaded the kiosk
    // settings, so the field initializers snapshot stale defaults. Re-read everything
    // from the loaded globals whenever the page appears; suppressValueRefresh stops the
    // change handlers from echoing these values back to the server.
    public void RefreshValues()
    {
        suppressValueRefresh = true;
        Crop = KioskSettings.crop;
        CropWidth = KioskSettings.cropWidth;
        CropHeight = KioskSettings.cropHeight;
        EyesCheck = KioskSettings.eyesCheck;
        LipsCheck = KioskSettings.lipsCheck;
        Lighting = KioskSettings.lighting;
        BlurBackground = KioskSettings.blurBackground;
        EyeGlassesCheck = KioskSettings.eyeGlassesCheck;
        HeadPoseCheck = KioskSettings.headPoseCheck;
        SharpnessCheck = KioskSettings.sharpnessCheck;
        HeadSizeCheck = KioskSettings.headSizeCheck;
        ExpressionCheck = KioskSettings.expressionCheck;
        GazeCheck = KioskSettings.gazeCheck;
        LightingEvennessCheck = KioskSettings.lightingEvennessCheck;
        RedEyeDetectionCheck = KioskSettings.redEyeDetectionCheck;
        MsmfSelection = KioskSettings.msmfSelection;
        IntensityRed = KioskSettings.intensityRed;
        IntensityGreen = KioskSettings.intensityGreen;
        IntensityBlue = KioskSettings.intensityBlue;
        DistanceMin = KioskSettings.distanceMin;
        DistanceMax = KioskSettings.distanceMax;
        JpegQuality = KioskSettings.jpegQuality;
        BackgroundColor = KioskSettings.backgroundColor;
        suppressValueRefresh = false;

        suppressBackgroundMethodChange = true;
        SelectedBackgroundMethod = BackgroundMethods.FirstOrDefault(m => m.code == KioskSettings.backgroundMethod)
                                   ?? BackgroundMethods[0];
        suppressBackgroundMethodChange = false;

        suppressPhotoFormatChange = true;
        SelectedPhotoFormat = PhotoFormats.FirstOrDefault(f => f.code == KioskSettings.photoFormat)
                              ?? PhotoFormats[0];
        suppressPhotoFormatChange = false;
    }

    partial void OnCropChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetCrop(value);
    }

    partial void OnCropWidthChanged(int value)
    {
        if (suppressValueRefresh) return;
        this.SetCropWidth(value);
    }

    partial void OnEyesCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetEyesCheck(value);
    }

    partial void OnLipsCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetLipsCheck(value);
    }

    partial void OnLightingChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetLighting(value);
    }

    partial void OnBlurBackgroundChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetBlurBackground(value);
    }

    partial void OnEyeGlassesCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetEyeGlassesCheck(value);
    }

    partial void OnHeadPoseCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetHeadPoseCheck(value);
    }

    partial void OnSharpnessCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetSharpnessCheck(value);
    }

    partial void OnHeadSizeCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetHeadSizeCheck(value);
    }

    partial void OnExpressionCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetExpressionCheck(value);
    }

    partial void OnGazeCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetGazeCheck(value);
    }

    partial void OnLightingEvennessCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetLightingEvennessCheck(value);
    }

    partial void OnRedEyeDetectionCheckChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetRedEyeDetectionCheck(value);
    }

    partial void OnMsmfSelectionChanged(bool value)
    {
        if (suppressValueRefresh) return;
        this.SetMsmfSelection(value);
    }

    partial void OnSelectedBackgroundMethodChanged(BackgroundMethodOption value)
    {
        OnPropertyChanged(nameof(ShowBackgroundColor));

        if (suppressBackgroundMethodChange || value == null)
            return;

        this.SetBackgroundMethod(value.code);
    }

    partial void OnSelectedPhotoFormatChanged(PhotoFormatOption value)
    {
        if (suppressPhotoFormatChange || value == null)
            return;

        this.SetPhotoFormat(value.code);
    }

    private async void SetPhotoFormat(string code)
    {
        try
        {
            PhotoFormat result = await dataService.SetPhotoFormat(code);
            KioskSettings.photoFormat = result.photoFormat;

            // The server derives the crop height from the stored width and the new
            // format's aspect ratio; mirror it in the UI.
            KioskSettings.cropHeight = result.cropHeight;
            this.CropHeight = result.cropHeight;
            SemanticScreenReader.Announce($"Photo format was set to {code}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Photo Format server error {e.Message}");
            ToastMessage.Show($"Set Photo Format server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task IntensityRedDragCompleted()
    {
        try
        {
            Intensity result = await dataService.SetIntensityRed(IntensityRed);
            KioskSettings.intensityRed = IntensityRed;
            SemanticScreenReader.Announce($"SetIntensityRed was set to {IntensityRed}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Intensity Red server error {e.Message}");
            ToastMessage.Show($"Set Intensity Red server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task IntensityGreenDragCompleted()
    {
        try
        {
            Intensity result = await dataService.SetIntensityGreen(IntensityGreen);
            KioskSettings.intensityGreen = IntensityGreen;
            SemanticScreenReader.Announce($"SetIntensityGreen was set to {IntensityGreen}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Intensity Green server error {e.Message}");
            ToastMessage.Show($"Set Intensity Green server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task IntensityBlueDragCompleted()
    {
        try
        {
            Intensity result = await dataService.SetIntensityBlue(IntensityBlue);
            KioskSettings.intensityBlue = IntensityBlue;
            SemanticScreenReader.Announce($"SetIntensityBlue was set to {IntensityBlue}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Intensity Blue server error {e.Message}");
            ToastMessage.Show($"Set Intensity Blue server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task JpegQualityDragCompleted()
    {
        try
        {
            JpegQuality result = await dataService.SetJpegQuality(JpegQuality);
            KioskSettings.jpegQuality = JpegQuality;
            SemanticScreenReader.Announce($"SetJpegQuality was set to {JpegQuality}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Jpeg Quality server error {e.Message}");
            ToastMessage.Show($"Set Jpeg Quality server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task DistanceMinDragCompleted()
    {
        try
        {
            Distance result = await dataService.SetDistanceMin(DistanceMin);
            KioskSettings.distanceMin = DistanceMin;
            SemanticScreenReader.Announce($"SetDistanceMin was set to {DistanceMin}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Distance Min server error {e.Message}");
            ToastMessage.Show($"Set Distance Min server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task DistanceMaxDragCompleted()
    {
        try
        {
            Distance result = await dataService.SetDistanceMax(DistanceMax);
            KioskSettings.distanceMax = DistanceMax;
            SemanticScreenReader.Announce($"SetDistanceMax was set to {DistanceMax}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Distance Max server error {e.Message}");
            ToastMessage.Show($"Set Distance Max server error {e.Message}", 18, ToastDuration.Long, null);
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

    private async void SetCrop(bool value)
    {
        try
        {
            KioskSettings.crop = value;
            Crop result = await dataService.SetCrop(value);
            SemanticScreenReader.Announce($"SetCrop was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Crop server error {e.Message}");
            ToastMessage.Show($"Set Crop server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetCropWidth(int cropWidth)
    {
        try
        {
            int cropHeight = KioskSettings.getCropHeight(cropWidth);

            Resolution result = await dataService.SetCropResolution(cropWidth, cropHeight);
            KioskSettings.cropWidth = cropWidth;
            KioskSettings.cropHeight = cropHeight;
            this.CropHeight = cropHeight;
            SemanticScreenReader.Announce($"SetCrop was set to {cropWidth}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Crop Width server error {e.Message}");
            ToastMessage.Show($"Set Crop Width server error {e.Message}", 18, ToastDuration.Long, null);
        }
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

    private async void SetEyesCheck(bool value)
    {
        try
        {
            KioskSettings.eyesCheck = value;
            EyesCheck result = await dataService.SetEyesCheck(value);
            SemanticScreenReader.Announce($"SetEyesCheck was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Eyes Check server error {e.Message}");
            ToastMessage.Show($"Set Eyes Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetLipsCheck(bool value)
    {
        try
        {
            KioskSettings.lipsCheck = value;
            LipsCheck result = await dataService.SetLipsCheck(value);
            SemanticScreenReader.Announce($"SetLipsCheck was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Lips Check server error {e.Message}");
            ToastMessage.Show($"Set Lips Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetLighting(bool value)
    {
        try
        {
            KioskSettings.lighting = value;
            Lighting result = await dataService.SetLighting(value);
            SemanticScreenReader.Announce($"SetLighting was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Lighting server error {e.Message}");
            ToastMessage.Show($"Set Lighting server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetBlurBackground(bool value)
    {
        try
        {
            KioskSettings.blurBackground = value;
            BlurBackground result = await dataService.SetBlurBackground(value);
            SemanticScreenReader.Announce($"Set Blur Background was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Blur Background server error {e.Message}");
            ToastMessage.Show($"Set Blur Background server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetEyeGlassesCheck(bool value)
    {
        try
        {
            KioskSettings.eyeGlassesCheck = value;
            EyeGlassesCheck result = await dataService.SetEyeGlassesCheck(value);
            SemanticScreenReader.Announce($"Set eye glasses Check was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Eye Glasses Check server error {e.Message}");
            ToastMessage.Show($"Set Eye Glasses Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetHeadPoseCheck(bool value)
    {
        try
        {
            KioskSettings.headPoseCheck = value;
            HeadPoseCheck result = await dataService.SetHeadPoseCheck(value);
            SemanticScreenReader.Announce($"Head pose check was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Head Pose Check server error {e.Message}");
            ToastMessage.Show($"Set Head Pose Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetSharpnessCheck(bool value)
    {
        try
        {
            KioskSettings.sharpnessCheck = value;
            SharpnessCheck result = await dataService.SetSharpnessCheck(value);
            SemanticScreenReader.Announce($"Sharpness check was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Sharpness Check server error {e.Message}");
            ToastMessage.Show($"Set Sharpness Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetHeadSizeCheck(bool value)
    {
        try
        {
            KioskSettings.headSizeCheck = value;
            HeadSizeCheck result = await dataService.SetHeadSizeCheck(value);
            SemanticScreenReader.Announce($"Head size check was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Head Size Check server error {e.Message}");
            ToastMessage.Show($"Set Head Size Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetExpressionCheck(bool value)
    {
        try
        {
            KioskSettings.expressionCheck = value;
            ExpressionCheck result = await dataService.SetExpressionCheck(value);
            SemanticScreenReader.Announce($"Expression check was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Expression Check server error {e.Message}");
            ToastMessage.Show($"Set Expression Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetGazeCheck(bool value)
    {
        try
        {
            KioskSettings.gazeCheck = value;
            GazeCheck result = await dataService.SetGazeCheck(value);
            SemanticScreenReader.Announce($"Gaze check was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Gaze Check server error {e.Message}");
            ToastMessage.Show($"Set Gaze Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetLightingEvennessCheck(bool value)
    {
        try
        {
            KioskSettings.lightingEvennessCheck = value;
            LightingEvennessCheck result = await dataService.SetLightingEvennessCheck(value);
            SemanticScreenReader.Announce($"Lighting evenness check was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Lighting Evenness Check server error {e.Message}");
            ToastMessage.Show($"Set Lighting Evenness Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetRedEyeDetectionCheck(bool value)
    {
        try
        {
            KioskSettings.redEyeDetectionCheck = value;
            RedEyeDetectionCheck result = await dataService.SetRedEyeDetectionCheck(value);
            SemanticScreenReader.Announce($"Red Eye Detection Check was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Red Eye Detection Check server error {e.Message}");
            ToastMessage.Show($"Set Red Eye Detection Check server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetMsmfSelection(bool value)
    {
        try
        {
            KioskSettings.msmfSelection = value;
            MsmfSelection result = await dataService.SetMsmfSelection(value);
            SemanticScreenReader.Announce($"MSMF selection was set to {value}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set MSMF selection server error {e.Message}");
            ToastMessage.Show($"Set MSMF selection server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    private async void SetBackgroundMethod(string method)
    {
        try
        {
            KioskSettings.backgroundMethod = method;
            BackgroundMethod result = await dataService.SetBackgroundMethod(method);
            SemanticScreenReader.Announce($"Background method was set to {method}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Background method server error {e.Message}");
            ToastMessage.Show($"Set Background method server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    // Applied when the operator confirms the colour entry (Return), not on every keystroke.
    [RelayCommand]
    async Task ApplyBackgroundColor()
    {
        try
        {
            BackgroundColor result = await dataService.SetBackgroundColor(this.BackgroundColor);
            KioskSettings.backgroundColor = result.color;
            SemanticScreenReader.Announce($"Background color was set to {this.BackgroundColor}");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Set Background color server error {e.Message}");
            ToastMessage.Show($"Set Background color server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    async Task SaveSettings()
    {
        try
        {
            KioskSettingsDto result = await dataService.SaveSettings(
                width: this.width,
                height: this.height,
                crop: this.Crop,
                cropWidth: this.CropWidth,
                cropHeight: this.CropHeight,
                eyesCheck: this.EyesCheck,
                lipsCheck: this.LipsCheck,
                lighting: this.Lighting,
                intensityRed: this.IntensityRed,
                intensityGreen: this.IntensityGreen,
                intensityBlue: this.IntensityBlue,
                distanceMin: this.DistanceMin,
                distanceMax: this.DistanceMax,
                blurBackground: this.BlurBackground,
                eyeGlassesCheck: this.EyeGlassesCheck,
                redEyeDetectionCheck: this.RedEyeDetectionCheck
                );

            // When save succesful
            KioskSettings.width = result.width;
            KioskSettings.height = result.height;
            KioskSettings.crop = result.crop;
            KioskSettings.eyesCheck = result.eyesCheck;
            KioskSettings.lipsCheck = result.lipsCheck;
            KioskSettings.lighting = result.lighting;
            KioskSettings.intensityRed = result.intensityRed;
            KioskSettings.intensityGreen = result.intensityGreen;
            KioskSettings.intensityBlue = result.intensityBlue;
            KioskSettings.distanceMin = result.distanceMin;
            KioskSettings.distanceMax = result.distanceMax;
            KioskSettings.blurBackground = result.blurBackground;
            KioskSettings.eyeGlassesCheck = result.eyeGlassesCheck;
            KioskSettings.redEyeDetectionCheck = result.redEyeDetectionCheck;

            SemanticScreenReader.Announce($"Kiosk settings where saved");
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"Save kiosk settings server error {e.Message}");
            ToastMessage.Show($"Save kiosk settings server error {e.Message}", 18, ToastDuration.Long, null);
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

}

// One entry in the background-method picker: the server code and its display text.
public class BackgroundMethodOption
{
    public string code { get; set; }
    public string display { get; set; }
}

// One entry in the photo-format picker: the server format key and its display text.
public class PhotoFormatOption
{
    public string code { get; set; }
    public string display { get; set; }
}