using System;
using System.Collections.Generic;
using GrpcLibrary.Dto;

namespace PhotoColumnApp.Globals;

static class CameraSettingsGlobal
{
    public static int brightness { get; set; }
    public static int contrast { get; set; }
    public static int saturation { get; set; }
    public static int hue { get; set; }
    public static bool whiteBalanceTemperatureAuto { get; set; }
    public static int gamma { get; set; }
    public static int gain { get; set; }
    public static int whiteBalanceTemperature { get; set; }
    public static int sharpness { get; set; }
    public static int backlightCompensation { get; set; }
    public static bool exposureAutoPriority { get; set; }
    public static int panAbsolute { get; set; }
    public static int tiltAbsolute { get; set; }
    public static int zoomAbsolute { get; set; }

    public static int focusAbsolute { get; set; }
    public static int exposureAbsolute { get; set; }
    public static bool autofocus { get; set; }
    // Setting names the camera does not support; those controls are hidden in the UI.
    public static List<string> unsupportedProperties { get; set; } = new List<string>();
    // Per-property limits probed from the actual camera at runtime, keyed by setting name.
    // Drives each slider's min/max; absent entries fall back to the client defaults.
    public static Dictionary<string, PropertyRange> propertyRanges { get; set; } = new Dictionary<string, PropertyRange>();
}