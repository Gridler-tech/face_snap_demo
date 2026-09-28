using System;
namespace PhotoColumnApp.Globals;

static class KioskConfiguration
{
    private static string kioskConfigurationFileName { get; } = "kiosk_ip_address.txt";

    public static string kioskServerIpAddress { get; set; } = "http://localhost:50051";

    // Path to the local server executable, launched by the client when the server runs
    // on this same machine (co-located deployment). Defaults to the installer location;
    // if the file is not found the client just doesn't launch a server (dev / remote).
    public static string serverExecutablePath { get; set; } =
        System.IO.Path.Combine(
            System.Environment.GetFolderPath(System.Environment.SpecialFolder.ProgramFiles),
            "FaceSnapServer", "face_snap_server.exe");


    public static async Task<string> LoadKioskIpAddressAsync()
    {
        string mainDir = FileSystem.Current.CacheDirectory;
        //string  = System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal);

        string fileName = kioskServerIpAddress;
        string filePath = System.IO.Path.Combine(mainDir, fileName);

        // Read the source file
        try
        {
            using Stream fileStream = System.IO.File.OpenRead(filePath);
            using StreamReader reader = new StreamReader(fileStream);

            string content = await reader.ReadToEndAsync();
            return content;
        }
        catch (Exception e)
        {
            Console.WriteLine($"Error while loading ip address of server: {e.Message}");
            throw;
        }
    }

    public static async Task SaveKioskIpAddressAsync(string ipAddress)
    {
        // Write the file content to the app data directory
        try
        {
            string content = ipAddress;

            //string path = System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal);
            //string targetFile = System.IO.Path.Combine(path, kioskConfigurationFileName);
            string targetFile = System.IO.Path.Combine(FileSystem.Current.CacheDirectory, kioskConfigurationFileName);
            using FileStream outputStream = System.IO.File.OpenWrite(targetFile);
            using StreamWriter streamWriter = new StreamWriter(outputStream);
            await streamWriter.WriteAsync(content);

            kioskServerIpAddress = ipAddress;
        }
        catch(Exception e)
        {
            Console.WriteLine($"Error while saving ip address of server: {e.Message}");
            throw;
        }
    }
}