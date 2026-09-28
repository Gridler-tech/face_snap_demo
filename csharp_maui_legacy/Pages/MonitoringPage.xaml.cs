using System.Threading.Tasks;
using CommunityToolkit.Maui.Converters;
using GrpcLibrary;
using Microsoft.Maui.Controls.Shapes;
using PhotoColumnApp.ViewModels;

namespace PhotoColumnApp;

public partial class MonitoringPage : ContentPage
{
    private readonly KioskViewModel kioskViewModel;

    public MonitoringPage(MonitoringViewModel vm, KioskViewModel kioskVm)
    {
        InitializeComponent();
        BindingContext = vm;

        // The kiosk info (camera count, IP, port, indexes) lives on the shared
        // KioskViewModel; only this section binds to it.
        kioskViewModel = kioskVm;
        KioskInfoSection.BindingContext = kioskVm;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        // Populate the kiosk info when the tab opens, instead of requiring a button.
        if (kioskViewModel.GetKioskInfoCommand.CanExecute(null))
            kioskViewModel.GetKioskInfoCommand.Execute(null);
    }
}
