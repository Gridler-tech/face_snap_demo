namespace PhotoColumnApp;
using PhotoColumnApp.ViewModels;

public partial class SettingsPage : ContentPage
{
    public SettingsPage(SettingsViewModel vm)
    {
        InitializeComponent();
        BindingContext = vm;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        // The view model is a singleton that may be constructed before the settings
        // loaded at login; re-read all values so the controls show the real state.
        if (BindingContext is SettingsViewModel vm)
        {
            vm.RefreshValues();
            await vm.RefreshServerStateAsync();
        }
    }
}
