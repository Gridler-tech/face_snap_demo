using System.Reflection;

namespace PhotoColumnApp.Helpers;

/// <summary>
/// Lets the operator turn "start the server at logon" on or off. Implemented as a
/// shortcut in the STARTUP folder (the same mechanism the installer's optional
/// autostart task uses), so no admin rights or registry access are needed:
///  - On:  a shortcut is created in the current user's Startup folder.
///  - Off: the per-user shortcut is removed; the installer's machine-wide shortcut
///         (all-users Startup) is also removed when we have the rights, otherwise the
///         caller gets a warning to remove it via an elevated shell / reinstall.
/// Windows-only, like the rest of the kiosk deployment.
/// </summary>
public static class ServerAutostart
{
    private const string ShortcutFileName = "FaceSnap Server.lnk";

    private static string UserShortcutPath =>
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Startup), ShortcutFileName);

    private static string CommonShortcutPath =>
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonStartup), ShortcutFileName);

    public static bool IsEnabled =>
        File.Exists(UserShortcutPath) || File.Exists(CommonShortcutPath);

    /// <summary>Create the per-user logon shortcut. Returns an error message or null.</summary>
    public static string? Enable(string serverExecutablePath)
    {
        if (string.IsNullOrWhiteSpace(serverExecutablePath) || !File.Exists(serverExecutablePath))
            return $"Server executable not found at '{serverExecutablePath}'. Install the server first.";

        try
        {
            // WScript.Shell via late-bound COM: the only dependency-free way to write a
            // .lnk file. WindowStyle 7 = minimized, so the server console stays in the
            // taskbar under the kiosk app.
            var shellType = Type.GetTypeFromProgID("WScript.Shell")
                            ?? throw new InvalidOperationException("WScript.Shell not available");
            var shell = Activator.CreateInstance(shellType)!;
            var shortcut = shellType.InvokeMember(
                "CreateShortcut", BindingFlags.InvokeMethod, null, shell, new object[] { UserShortcutPath })!;

            var shortcutType = shortcut.GetType();
            shortcutType.InvokeMember("TargetPath", BindingFlags.SetProperty, null, shortcut,
                new object[] { serverExecutablePath });
            shortcutType.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, shortcut,
                new object[] { Path.GetDirectoryName(serverExecutablePath)! });
            shortcutType.InvokeMember("WindowStyle", BindingFlags.SetProperty, null, shortcut,
                new object[] { 7 });
            shortcutType.InvokeMember("Save", BindingFlags.InvokeMethod, null, shortcut, null);
            return null;
        }
        catch (Exception e)
        {
            return $"Could not create the logon shortcut: {e.Message}";
        }
    }

    /// <summary>Remove the logon shortcut(s). Returns a warning message or null.</summary>
    public static string? Disable()
    {
        try
        {
            if (File.Exists(UserShortcutPath))
                File.Delete(UserShortcutPath);
        }
        catch (Exception e)
        {
            return $"Could not remove the logon shortcut: {e.Message}";
        }

        // The installer's optional autostart task writes an all-users shortcut; deleting
        // it needs admin rights, so this is best-effort with an honest warning.
        if (File.Exists(CommonShortcutPath))
        {
            try
            {
                File.Delete(CommonShortcutPath);
            }
            catch
            {
                return "The machine-wide autostart entry (all-users Startup folder) could not be " +
                       "removed without administrator rights. Delete 'FaceSnap Server' from " +
                       "shell:common startup in an elevated session.";
            }
        }
        return null;
    }
}
