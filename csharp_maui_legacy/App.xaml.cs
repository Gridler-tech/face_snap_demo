using GrpcLibrary;
using PhotoColumnApp.Globals;

namespace PhotoColumnApp;

public partial class App : Application
{
    private ServerProcessManager? serverManager;

    public App()
    {
        InitializeComponent();

        MainPage = new AppShell();
    }

    protected override Window CreateWindow(IActivationState activationState)
    {
        Window window = base.CreateWindow(activationState);

        // Manipulate Window object
        window.MinimumWidth = 800;
        window.MinimumHeight = 600;

        // Connect-only: in production the server auto-starts at logon (installer task)
        // and is owned by no app. Launch-if-absent is kept as a development convenience
        // (no-op when the server is remote, already running, or the exe isn't installed),
        // but the operator app must NEVER stop the server - the kiosk app depends on it.
        window.Created += async (s, e) =>
        {
            serverManager = new ServerProcessManager(
                KioskConfiguration.kioskServerIpAddress,
                KioskConfiguration.serverExecutablePath);
            await serverManager.EnsureRunningAsync(TimeSpan.FromSeconds(60));
        };

        return window;
    }

}

