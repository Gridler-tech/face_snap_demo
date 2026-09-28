using System;
using GrpcLibrary.Dto;

namespace PhotoColumnApp.Globals;

static class KioskSettings
{
    public static int width { get; set; }

    public static int height { get; set; }

    public static bool crop { get; set; }

    public static int cropWidth { get; set; }

    public static int cropHeight { get; set; }

    public static bool eyesCheck { get; set; }

    public static bool lipsCheck { get; set; }

    public static bool blurBackground { get; set; }

    public static bool eyeGlassesCheck { get; set; }

    public static bool headPoseCheck { get; set; }

    public static bool sharpnessCheck { get; set; }

    public static bool headSizeCheck { get; set; }

    public static bool expressionCheck { get; set; }

    public static bool gazeCheck { get; set; }

    public static bool lightingEvennessCheck { get; set; }

    public static bool redEyeDetectionCheck { get; set; }

    public static bool horizontalCheck { get; set; }

    public static bool verticalCheck { get; set; }

    public static bool lighting { get; set; }

    public static int intensityRed { get; set; }

    public static int intensityGreen { get; set; }

    public static int intensityBlue { get; set; }

    public static int distanceMin { get; set; }

    public static int distanceMax { get; set; }

    // true = selection scan uses the faster Media Foundation backend (Windows).
    public static bool msmfSelection { get; set; } = true;

    // How the photo background is erased ("none"/"mediapipe"/"modnet") and the
    // fill colour (RRGGBB hex) used when a method is active.
    public static string backgroundMethod { get; set; } = "modnet";
    public static string backgroundColor { get; set; } = "FFFFFF";

    // JPEG encoding quality of delivered photos (50-100).
    public static int jpegQuality { get; set; } = 95;

    // Photo format key ("icao_35x45"/"us_2x2"/"ca_50x70"): decides the aspect ratio (crop
    // height is derived from the width) and the face framing on the server.
    public static string photoFormat { get; set; } = "icao_35x45";

    public static List<CameraResolution> cameraResolutions { get; set; } = new List<CameraResolution>();


    public static string getResolution(int width, int height)
    {
        return $"{width.ToString()} x {height.ToString()}";
    }

    public static (int width, int height) getResolution(string resolution)
    {
        string[] tokens = resolution.Split(' ');

        try
        {
            int width = Int32.Parse(tokens[0]);
            int height = Int32.Parse(tokens[2]);
            return (width, height);
        }
        catch (FormatException)
        {
            Console.WriteLine("Unable to parse resolution");
        }

        return (1280, 720);
    }

    // Height/width factor of the selected photo format (35x45 = 9:7 portrait, 2x2
    // square, 50x70 = 7:5 portrait). Must match the server's photo_formats.py.
    public static double getAspectFactor()
    {
        switch (photoFormat)
        {
            case "us_2x2": return 1.0;
            case "ca_50x70": return (double)70 / (double)50;
            default: return (double)45 / (double)35;
        }
    }

    public static int getCropHeight(int cropWidth)
    {
        var result = (int)Math.Round(cropWidth * getAspectFactor());

        return result;
    }
}

