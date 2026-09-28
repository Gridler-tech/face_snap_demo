using System.Globalization;

namespace PhotoColumnApp.Helpers;

/// <summary>
/// Converts an "RRGGBB" hex string (no leading #) to a Color, for showing a live
/// swatch next to the background-colour entry. Invalid or incomplete input while
/// typing renders as transparent instead of throwing.
/// </summary>
public class HexColorConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        var hex = value as string;
        if (string.IsNullOrWhiteSpace(hex))
            return Colors.Transparent;

        hex = hex.TrimStart('#');
        if (hex.Length != 6 || !int.TryParse(hex, NumberStyles.HexNumber, CultureInfo.InvariantCulture, out _))
            return Colors.Transparent;

        return Color.FromArgb("#" + hex);
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => throw new NotImplementedException();
}
