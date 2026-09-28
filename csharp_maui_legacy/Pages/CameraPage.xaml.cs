using System.Threading.Tasks;
using CommunityToolkit.Maui.Converters;
using GrpcLibrary;
using Microsoft.Maui.Controls.Shapes;
using PhotoColumnApp.ViewModels;

namespace PhotoColumnApp;

public partial class CameraPage : ContentPage
{
    public CameraPage(CameraViewModel vm)
    {
        InitializeComponent();
        BindingContext = vm;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        // Repopulate the resolution dropdown from the settings loaded at login.
        (BindingContext as CameraViewModel)?.RefreshResolutions();
    }
}
