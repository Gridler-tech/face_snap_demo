using CommunityToolkit.Maui;
using GrpcLibrary;
using Microsoft.Extensions.Logging;
using PhotoColumnApp.Globals;
using PhotoColumnApp.Services;
using PhotoColumnApp.ViewModels;

namespace PhotoColumnApp;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .UseMauiCommunityToolkit()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
                fonts.AddFont("Font Awesome 6 Free-Solid-900.otf", "FontAwesomeSolid");
            });

        // Load ip address from config. If no file is found then save an initial file with a default ip address
        try
        {
            var task = Task.Run(async () => await KioskConfiguration.LoadKioskIpAddressAsync());
            KioskConfiguration.kioskServerIpAddress = task.Result;
        }
        catch (Exception e)
        {
            Console.WriteLine($"KioskConfig file does not exist or error opening ip address config file {e.Message}");
            Console.WriteLine("Trying to create a new kiosk configuration file");
            Task.Run(async () => await KioskConfiguration.SaveKioskIpAddressAsync(KioskConfiguration.kioskServerIpAddress));
        }

        builder.Services.AddSingleton<IKioskProcessor>((e) => new KioskProcessor(KioskConfiguration.kioskServerIpAddress));
        builder.Services.AddSingleton<ILightProcessor>((e) => new LightProcessor(KioskConfiguration.kioskServerIpAddress));
        builder.Services.AddSingleton<ICameraProcessor>((e) => new CameraProcessor(KioskConfiguration.kioskServerIpAddress));
        builder.Services.AddSingleton<IMonitoringProcessor>((e) => new MonitoringProcessor(KioskConfiguration.kioskServerIpAddress));
        builder.Services.AddSingleton<ISettingsProcessor>((e) => new SettingsProcessor(KioskConfiguration.kioskServerIpAddress));
        builder.Services.AddSingleton<ICalibrationProcessor>((e) => new CalibrationProcessor(KioskConfiguration.kioskServerIpAddress));


        builder.Services.AddSingleton<IDataService, DataService>();

        builder.Services.AddSingleton<KioskViewModel>();
        builder.Services.AddSingleton<LoginViewModel>();
        builder.Services.AddSingleton<CameraViewModel>();
        builder.Services.AddSingleton<MonitoringViewModel>();
        builder.Services.AddSingleton<PhotoItemViewModel>();
        builder.Services.AddSingleton<SettingsViewModel>();
        builder.Services.AddSingleton<CalibrationViewModel>();

        builder.Services.AddSingleton<KioskPage>();
        builder.Services.AddSingleton<LoginPage>();
        builder.Services.AddSingleton<CameraPage>();
        builder.Services.AddSingleton<MonitoringPage>();
        builder.Services.AddSingleton<SettingsPage>();
        builder.Services.AddSingleton<CalibrationPage>();
        builder.Services.AddSingleton<FaceRecognitionPage>();


#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }

}

