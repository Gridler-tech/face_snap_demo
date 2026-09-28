using PhotoColumnApp.ViewModels;

namespace PhotoColumnApp;

public partial class CalibrationPage : ContentPage
{
    public CalibrationPage(CalibrationViewModel vm)
    {
        InitializeComponent();
        BindingContext = vm;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        // Reflect the mode and, in manual mode, auto-populate the camera table.
        if (BindingContext is CalibrationViewModel vm)
            await vm.OnAppearingAsync();
    }
}
