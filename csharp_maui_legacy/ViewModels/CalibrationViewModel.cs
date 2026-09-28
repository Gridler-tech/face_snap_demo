using System.Collections.ObjectModel;
using CommunityToolkit.Maui.Core;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Grpc.Core;
using GrpcLibrary.Dto;
using PhotoColumnApp.Globals;
using PhotoColumnApp.Helpers;
using PhotoColumnApp.Services;

namespace PhotoColumnApp.ViewModels;

public partial class CalibrationViewModel : ObservableObject
{
    private readonly IDataService dataService;

    // Camera ordering mode. When automatic, positions come from the physical USB port via
    // the standard-hub map and no manual calibration is needed, so the manual controls are
    // hidden (ShowManualCalibration). Loaded from the server; guarded so loading the value
    // doesn't fire a redundant SetCameraOrderingMode back to the server.
    [ObservableProperty] private bool automaticOrdering;
    private bool suppressOrderingChange;

    public bool ShowManualCalibration => !AutomaticOrdering;

    // The position table (one row per physical position), ordered TOP first ... BOTTOM
    // last. Each row's Camera dropdown picks which detected camera sits at that position.
    [ObservableProperty] private ObservableCollection<CalibrationSlot> slots = new();

    // All detected cameras — the shared item source for every row's dropdown.
    [ObservableProperty] private ObservableCollection<CameraOption> cameraOptions = new();

    // Guards the swap logic while we assign selections programmatically (load / swap).
    private bool suppressSlotChange;

    public CalibrationViewModel(IDataService dataService)
    {
        this.dataService = dataService;
    }

    // Called when the page appears: reflect the mode and, in manual mode, populate the
    // table straight away so the operator doesn't have to press "Search cameras" first.
    // ---------- focus calibration (one value for all cameras: the flow always selects
    // the camera at the person's face height, so the subject distance is constant) ----------

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(NotCalibrating))]
    private bool calibrating;

    public bool NotCalibrating => !Calibrating;

    [ObservableProperty]
    private int currentFocusValue = CameraSettingsGlobal.focusAbsolute;

    [RelayCommand]
    async Task CalibrateFocus()
    {
        Calibrating = true;
        try
        {
            // 0 = the server selects the best camera automatically (same as the photo flow).
            FocusAbsolute result = await dataService.CalibrateFocus(0);
            if (result.focusAbsolute >= 0)
            {
                CameraSettingsGlobal.focusAbsolute = result.focusAbsolute;
                CurrentFocusValue = result.focusAbsolute;
                ToastMessage.Show($"Focus calibrated: {result.focusAbsolute} (autofocus switched off)", 18, ToastDuration.Long, null);
            }
            else
            {
                ToastMessage.Show("Focus calibration did not lock - is someone standing in front of the camera?", 18, ToastDuration.Long, null);
            }
        }
        catch (Grpc.Core.RpcException e)
        {
            Console.WriteLine($"CalibrateFocus server error {e.Message}");
            ToastMessage.Show($"Calibrate focus server error {e.Message}", 18, ToastDuration.Long, null);
        }
        finally
        {
            Calibrating = false;
        }
    }

    public async Task OnAppearingAsync()
    {
        CurrentFocusValue = CameraSettingsGlobal.focusAbsolute;
        await LoadOrderingMode();
        if (!AutomaticOrdering)
            await LoadCameras();
    }

    public async Task LoadOrderingMode()
    {
        try
        {
            var settings = await dataService.LoadSettings();
            suppressOrderingChange = true;
            AutomaticOrdering = settings.cameraOrderingAutomatic;
            suppressOrderingChange = false;
        }
        catch (RpcException e)
        {
            Console.WriteLine($"Load ordering mode server error {e.Message}");
        }
    }

    partial void OnAutomaticOrderingChanged(bool value)
    {
        OnPropertyChanged(nameof(ShowManualCalibration));

        if (suppressOrderingChange)
            return;

        _ = SetOrderingMode(value);
        if (!value)
            _ = LoadCameras();   // switched back to manual — refresh the table
    }

    private async Task SetOrderingMode(bool automatic)
    {
        try
        {
            await dataService.SetCameraOrderingMode(automatic);
            ToastMessage.Show(
                automatic ? "Automatic camera ordering (standard hub)" : "Manual calibration",
                18, ToastDuration.Short, null);
        }
        catch (RpcException e)
        {
            Console.WriteLine($"Set ordering mode server error {e.Message}");
            ToastMessage.Show($"Set ordering mode server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    // Fetch the detected cameras and build the position table, preselecting each row from
    // the stored calibration. Exposed as a command so the page can also offer a manual
    // "Search cameras again" refresh (e.g. after re-plugging).
    [RelayCommand]
    public async Task LoadCameras()
    {
        try
        {
            var cameras = (await dataService.GetCalibration()).ToList();

            CameraOptions = new ObservableCollection<CameraOption>(cameras.Select(c => new CameraOption
            {
                modelId = c.idModelId,
                linuxCameraIndex = c.linuxCameraIndex,
                display = $"Camera {c.idModelId}"
            }));

            int count = CameraOptions.Count;

            // Build rows top -> bottom. Physical position (calibrated_camera_index) is
            // 1 at the bottom and `count` at the top, so the top row carries `count`.
            var newSlots = new ObservableCollection<CalibrationSlot>();
            for (int row = 0; row < count; row++)
            {
                int position = count - row;
                string suffix = row == 0 ? " (top)" : row == count - 1 ? " (bottom)" : "";
                newSlots.Add(new CalibrationSlot
                {
                    position = position,
                    label = $"Position {position}{suffix}"
                });
            }

            AssignInitialSelection(cameras, newSlots);

            // Wire the swap handler after the initial assignment so it doesn't fire during load.
            foreach (var slot in newSlots)
                slot.SelectionChanged = HandleSlotSwap;

            Slots = newSlots;
        }
        catch (RpcException e)
        {
            Console.WriteLine($"Get Calibration server error {e.Message}");
            ToastMessage.Show($"Get Calibration server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    // Preselect each row from the stored calibration where valid+unique, then fill any
    // remaining rows with the leftover cameras so the table always starts as a complete,
    // duplicate-free assignment.
    private void AssignInitialSelection(List<CalibrationData> cameras, ObservableCollection<CalibrationSlot> targetSlots)
    {
        var optionByModel = CameraOptions.ToDictionary(o => o.modelId);
        var byPosition = new Dictionary<int, CameraOption>();
        var used = new HashSet<string>();

        foreach (var c in cameras)
        {
            if (c.calibratedCameraIndex >= 1 && c.calibratedCameraIndex <= targetSlots.Count
                && !byPosition.ContainsKey(c.calibratedCameraIndex)
                && !used.Contains(c.idModelId)
                && optionByModel.TryGetValue(c.idModelId, out var option))
            {
                byPosition[c.calibratedCameraIndex] = option;
                used.Add(c.idModelId);
            }
        }

        var leftovers = new Queue<CameraOption>(CameraOptions.Where(o => !used.Contains(o.modelId)));

        suppressSlotChange = true;
        foreach (var slot in targetSlots)
            slot.SelectedCamera = byPosition.TryGetValue(slot.position, out var cam)
                ? cam
                : (leftovers.Count > 0 ? leftovers.Dequeue() : null);
        suppressSlotChange = false;
    }

    // Keep the assignment a permutation: if a camera is picked in a row where it's already
    // used by another row, the other row takes over this row's previous camera (a swap),
    // so no camera is ever selected twice and every position stays filled.
    private void HandleSlotSwap(CalibrationSlot changed, CameraOption previous)
    {
        if (suppressSlotChange || changed.SelectedCamera == null)
            return;

        var other = Slots.FirstOrDefault(s => s != changed && s.SelectedCamera == changed.SelectedCamera);
        if (other == null)
            return;

        suppressSlotChange = true;
        other.SelectedCamera = previous;
        suppressSlotChange = false;
    }

    [RelayCommand]
    private async Task SaveCalibration()
    {
        if (Slots.Count == 0)
        {
            ToastMessage.Show("No cameras to calibrate", 18, ToastDuration.Long, null);
            return;
        }

        if (Slots.Any(s => s.SelectedCamera == null))
        {
            ToastMessage.Show("Please assign a camera to every position", 18, ToastDuration.Long, null);
            return;
        }

        // The swap logic keeps selections unique, but guard the save anyway.
        if (Slots.Select(s => s.SelectedCamera.modelId).Distinct().Count() != Slots.Count)
        {
            ToastMessage.Show("Each camera may be selected only once", 18, ToastDuration.Long, null);
            return;
        }

        try
        {
            var calibrationData = Slots.Select(s => new CalibrationData
            {
                idModelId = s.SelectedCamera.modelId,
                linuxCameraIndex = s.SelectedCamera.linuxCameraIndex,
                calibratedCameraIndex = s.position
            }).ToList();

            var result = await dataService.SetCalibration(calibrationData);
            ToastMessage.Show(result.message, 18, ToastDuration.Long, null);
        }
        catch (RpcException e)
        {
            Console.WriteLine($"Set Calibration server error {e.Message}");
            ToastMessage.Show($"Set Calibration server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }
}

// One physical position in the column and the camera assigned to it.
public partial class CalibrationSlot : ObservableObject
{
    public int position { get; set; }        // calibrated_camera_index (1 = bottom)
    public string label { get; set; }         // e.g. "Position 6 (top)"

    [ObservableProperty] private CameraOption selectedCamera;

    // Invoked with (this, previousCamera) when the selection changes, so the view model
    // can keep the overall assignment unique.
    public Action<CalibrationSlot, CameraOption> SelectionChanged;

    partial void OnSelectedCameraChanged(CameraOption oldValue, CameraOption newValue)
    {
        SelectionChanged?.Invoke(this, oldValue);
    }
}

// A detected camera offered in the dropdowns.
public class CameraOption
{
    public string modelId { get; set; }
    public int linuxCameraIndex { get; set; }
    public string display { get; set; }
}
