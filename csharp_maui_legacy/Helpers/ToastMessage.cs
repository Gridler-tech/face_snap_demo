using System.Diagnostics;
using CommunityToolkit.Maui.Core;
using CommunityToolkit.Maui.Alerts;

namespace PhotoColumnApp.Helpers;

public static class ToastMessage
{
	public static void Show(string message, double fontSize, ToastDuration duration, ShellNavigationState navState)
	{
        MainThread.BeginInvokeOnMainThread(async () =>
        {
            // Toasts require package identity on Windows; this app now runs UNPACKAGED
            // (WindowsPackageType=None), where Toast.Show throws E_ACCESSDENIED from an
            // async-void context and crashes the whole app (stowed exception). Never let
            // a notification take the app down - fall back to the debug log.
            try
            {
                CancellationTokenSource cancellationTokenSource = new CancellationTokenSource();
                var toast = Toast.Make(message, ToastDuration.Long, 18);
                await toast.Show(cancellationTokenSource.Token);
            }
            catch (Exception e)
            {
                Debug.WriteLine($"Toast suppressed ({e.GetType().Name}): {message}");
            }

            try
            {
                if (navState != null)
                {
                    await Shell.Current.GoToAsync(navState);
                }
            }
            catch (Exception e)
            {
                Debug.WriteLine($"Toast navigation failed: {e.Message}");
            }
        });
    }
}
