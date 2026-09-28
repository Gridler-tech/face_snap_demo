using PhotoColumnApp.ViewModels;

namespace PhotoColumnApp;

public partial class LoginPage : ContentPage
{
    public LoginPage(LoginViewModel vm)
    {
        InitializeComponent();
        BindingContext = vm;
    }
}
