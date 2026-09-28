using PhotoColumnApp.ViewModels;

namespace PhotoColumnApp;

// Shares the KioskViewModel singleton: the face recognition commands, model list and
// results have always lived there, so moving the UI to its own tab needs no VM changes.
public partial class FaceRecognitionPage : ContentPage
{
    public FaceRecognitionPage(KioskViewModel vm)
    {
        InitializeComponent();
        BindingContext = vm;
    }
}
