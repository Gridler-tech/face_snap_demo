using PhotoColumnApp.ViewModels;

namespace PhotoColumnApp;

public partial class KioskPage : ContentPage
{
    public KioskPage(KioskViewModel vm)
    {
        InitializeComponent();
        BindingContext = vm;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        if (BindingContext is KioskViewModel vm)
        {
            // Show the (neutral) checklist right away; keep existing results when the
            // operator merely switches tabs after a capture.
            if (vm.StatusItems.Count == 0)
                vm.PrepareChecklist();

            // Header chip: is the server reachable right now?
            _ = vm.RefreshServerOnlineAsync();
        }
    }

    protected override void OnSizeAllocated(double width, double height)
    {
        base.OnSizeAllocated(width, height);
        // Size BOTH panes explicitly: this MAUI version's grid expands star columns to
        // their desired width, which pushes content off-screen on smaller windows.
        if (width > 0)
        {
            var left = Math.Max(300, width * 0.52);
            var right = Math.Max(280, width - left - 42);
            LeftPane.WidthRequest = left;
            RightPane.WidthRequest = right;
            ChipRow.WidthRequest = right;
        }
    }
}
