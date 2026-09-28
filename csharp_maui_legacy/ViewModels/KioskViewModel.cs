using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Globalization;
using CommunityToolkit.Maui.Core;
using CommunityToolkit.Maui.Storage;
using CommunityToolkit.Maui.Views;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Grpc.Core;
using GrpcLibrary;
using GrpcLibrary.Dto;
using PhotoColumnApp.Globals;
using PhotoColumnApp.Helpers;
using PhotoColumnApp.Services;
using Application = Microsoft.Maui.Controls.Application;
using FaceRecognitionRequest = GrpcLibrary.Dto.FaceRecognitionRequest;

namespace PhotoColumnApp.ViewModels;

public partial class KioskViewModel : ObservableObject
{
    private const double imageCropFactor = 0.5;
    private readonly IDataService dataService;


    [ObservableProperty] private int cameraCount;

    [ObservableProperty] private ObservableCollection<int> cameraIndexes = new();
    [ObservableProperty] private string distance;

    // Face Recognition
    [ObservableProperty] private byte[] fileBytes1;
    [ObservableProperty] private byte[] fileBytes2;


    [ObservableProperty] private int focusedCameraIndex;

    [ObservableProperty] private int lightCameraIndex;

    [ObservableProperty] private ObservableCollection<PhotoItemViewModel> manualPhotos;

    // Face Recognition
    [ObservableProperty] private string pickImage1BtnText = "Load image 1 from file";
    [ObservableProperty] private string pickImage2BtnText = "Load image 2 from file";

    // Face Recognition
    [ObservableProperty] private Model selectedRecognitionModel;


    [ObservableProperty] private string serverIpAddress;

    [ObservableProperty] private string serverPort;
    [ObservableProperty] private string status;

    [ObservableProperty] private ObservableCollection<StatusItem> statusItems;
    [ObservableProperty] private string threshold;

    [ObservableProperty] private string time;

    // Face Recognition
    [ObservableProperty] private string verified;


    // True while no capture has produced a photo yet; shows the placeholder card.
    public bool ShowPhotoPlaceholder => ManualPhotos.Count == 0;

    // Header chip: tells the operator at a glance whether the server is reachable.
    private readonly ServerProcessManager serverManager = new(
        KioskConfiguration.kioskServerIpAddress,
        KioskConfiguration.serverExecutablePath);

    [ObservableProperty] private bool serverOnline;
    [ObservableProperty] private string serverChipText = "Checking server…";

    public async Task RefreshServerOnlineAsync()
    {
        ServerOnline = await serverManager.IsRunningAsync();
        ServerChipText = ServerOnline ? "Server online" : "Server offline";
    }

    public KioskViewModel(IDataService dataService)
    {
        this.dataService = dataService;
        statusItems = new ObservableCollection<StatusItem>();
        manualPhotos = new ObservableCollection<PhotoItemViewModel>();
        manualPhotos.CollectionChanged += (_, _) => OnPropertyChanged(nameof(ShowPhotoPlaceholder));

        // Face Recognition
        // recognitionModels = new ObservableCollection<RecognitionModel>();

        RecognitionModels.Add(new RecognitionModel { modelName = "Dlib", recognitionModel = Model.Dlib });
        RecognitionModels.Add(new RecognitionModel { modelName = "Facenet512", recognitionModel = Model.Facenet512 });
        RecognitionModels.Add(new RecognitionModel { modelName = "SFace", recognitionModel = Model.Sface });
    }

    // Face Recognition
    public ObservableCollection<RecognitionModel> RecognitionModels { get; } = new();

    // Keyless process messages are inserted above the pre-populated check rows,
    // in arrival order; this tracks where the next one goes.
    private int processRowCount;

    // Show every ENABLED check as a neutral white row up front; results replace
    // them in place as the server streams them in. Public: the page also calls it
    // on first appearance so the operator sees the checklist before any capture.
    public void PrepareChecklist()
    {
        processRowCount = 0;
        StatusItems.Clear();

        StatusItems.Add(StatusItem.Placeholder("distance", "Distance"));
        if (KioskSettings.lipsCheck) StatusItems.Add(StatusItem.Placeholder("lips", "Lips closed"));
        if (KioskSettings.eyesCheck) StatusItems.Add(StatusItem.Placeholder("eyes", "Eyes open"));
        if (KioskSettings.eyeGlassesCheck) StatusItems.Add(StatusItem.Placeholder("glasses", "Glasses"));
        if (KioskSettings.headPoseCheck) StatusItems.Add(StatusItem.Placeholder("head_pose", "Head pose (frontal)"));
        if (KioskSettings.sharpnessCheck) StatusItems.Add(StatusItem.Placeholder("sharpness", "Sharpness"));
        if (KioskSettings.redEyeDetectionCheck) StatusItems.Add(StatusItem.Placeholder("red_eye", "Red eye"));
        if (KioskSettings.expressionCheck) StatusItems.Add(StatusItem.Placeholder("expression", "Neutral expression"));
        if (KioskSettings.gazeCheck) StatusItems.Add(StatusItem.Placeholder("gaze", "Gaze direction"));
        if (KioskSettings.lightingEvennessCheck) StatusItems.Add(StatusItem.Placeholder("lighting", "Lighting evenness"));
        if (KioskSettings.headSizeCheck) StatusItems.Add(StatusItem.Placeholder("head_size", "Head size/position"));
    }

    private void AddServerStatus(string description, int status)
    {
        var item = StatusItem.FromServerMessage(description, status);

        if (item.Key != null)
            for (var i = 0; i < StatusItems.Count; i++)
                if (StatusItems[i].Key == item.Key)
                {
                    StatusItems[i] = item;
                    return;
                }

        StatusItems.Insert(Math.Min(processRowCount++, StatusItems.Count), item);
    }


    [RelayCommand]
    private async Task StartAutomaticProcess()
    {
        PrepareChecklist();
        ManualPhotos.Clear();

        var imageManagerDiskCache = Path.Combine(FileSystem.CacheDirectory, "image_manager_disk_cache");

        if (Directory.Exists(imageManagerDiskCache))
            foreach (var imageCacheFile in Directory.EnumerateFiles(imageManagerDiskCache))
            {
                Debug.WriteLine($"Deleting {imageCacheFile}");
                File.Delete(imageCacheFile);
            }

        var currentWindow = Application.Current.Windows.FirstOrDefault();
        var pageHeight = currentWindow.Height;
        var pageWidth = currentWindow.Width;

        var width = Math.Round(pageWidth * 0.9);
        var height = Math.Round(pageHeight * 0.9);

        try
        {
            await foreach (var message in dataService.StartAutomaticProcess())
            {
                if (message is ProcessStatus)
                {
                    ProcessStatus status = message;

                    AddServerStatus(status.description, (int)status.status);
                }

                if (message is ImageData)
                {
                    ImageData imageData = message;
                    if (imageData.data.Length != 0)
                        ManualPhotos.Add(new PhotoItemViewModel
                        {
                            index = imageData.index,
                            showPhoto = imageData.data.Length == 0 ? false : true,
                            showError = imageData.data.Length == 0 ? true : false,
                            photoBytes = imageData.data,
                            width = imageData.width,
                            height = imageData.height,
                            widthFrame = (int)Math.Abs(imageData.width * imageCropFactor),
                            heightFrame = (int)Math.Abs(imageData.height * imageCropFactor),
                            photoImage = new Image
                            {
                                Source = ImageSource.FromStream(() => new MemoryStream(imageData.data)),
                                Aspect = Aspect.Center,
                                HeightRequest = imageData.height,
                                WidthRequest = imageData.width,
                                HorizontalOptions = LayoutOptions.Center,
                                VerticalOptions = LayoutOptions.Center,
                                ZIndex = 1000
                            }
                        });
                }
            }
        }
        catch (RpcException e)
        {
            Console.WriteLine($"Automatic Process stream cancelled. {e.Message}");
            ToastMessage.Show($"Automatic Process stream cancelled. {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    private async Task AllLightsOn()
    {
        try
        {
            await dataService.SetAllLights(true);
        }
        catch (RpcException e)
        {
            Console.WriteLine($"SetAllLights error {e.Message}");
            ToastMessage.Show($"SetAllLights server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    private async Task AllLightsOff()
    {
        try
        {
            await dataService.SetAllLights(false);
        }
        catch (RpcException e)
        {
            Console.WriteLine($"SetAllLights error {e.Message}");
            ToastMessage.Show($"SetAllLights server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    // Set light at camera index

    [RelayCommand]
    private async Task SetLightAtCameraIndex(string index)
    {
        var idx = int.Parse(index);

        try
        {
            await dataService.SetLightAtCameraIndex(idx);
        }
        catch (RpcException e)
        {
            Console.WriteLine($"SetLightAtCameraIndex {index} error {e.Message}");
            ToastMessage.Show($"SetLightAtCameraIndex {index} server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }


    // Set light off at camera index
    [RelayCommand]
    private async Task SetLightOffAtCameraIndex(string index)
    {
        var idx = int.Parse(index);

        try
        {
            await dataService.SetLightOffAtCameraIndex(idx);
        }
        catch (RpcException e)
        {
            Console.WriteLine($"SetLightOffAtCameraIndex {index} error {e.Message}");
            ToastMessage.Show($"SetLightOffAtCameraIndex {index} server error {e.Message}", 18, ToastDuration.Long,
                null);
        }
    }


    [RelayCommand]
    private async Task GetKioskInfo()
    {
        try
        {
            var kioskInfo = await dataService.GetKioskInfo();

            CameraCount = kioskInfo.kioskData.numberOfCameras;
            ServerIpAddress = kioskInfo.kioskData.serverIpAddress;
            ServerPort = kioskInfo.kioskData.port;

            CameraIndexes = new ObservableCollection<int>(kioskInfo.cameraData.Select(camera => camera.index));
        }
        catch (RpcException e)
        {
            Console.WriteLine($"GetKioskInfo error {e.Message}");
            ToastMessage.Show($"GetKioskInfo server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }


    [RelayCommand]
    private async Task GetFocusedCameraIndex()
    {
        try
        {
            var focusedCameraIndex = await dataService.GetFocusedCameraIndex(10000);

            FocusedCameraIndex = focusedCameraIndex.index;
        }
        catch (RpcException e)
        {
            Console.WriteLine($"GetKioskInfo error {e.Message}");
            ToastMessage.Show($"GetKioskInfo server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    private async Task GetHighResolutionImageFromCameraIndex(string index)
    {
        var idx = int.Parse(index);

        StatusItems.Clear();
        ManualPhotos.Clear();

        try
        {
            var imageData = await dataService.GetHighResolutionImageFromCameraIndex(idx, 10000);

            // show image
            if (imageData.data.Length != 0)
                ManualPhotos.Add(new PhotoItemViewModel
                {
                    index = imageData.index,
                    showPhoto = imageData.data.Length == 0 ? false : true,
                    showError = imageData.data.Length == 0 ? true : false,
                    photoBytes = imageData.data,
                    width = imageData.width,
                    height = imageData.height,
                    widthFrame = (int)Math.Abs(imageData.width * imageCropFactor),
                    heightFrame = (int)Math.Abs(imageData.height * imageCropFactor),
                    photoImage = new Image
                    {
                        Source = ImageSource.FromStream(() => new MemoryStream(imageData.data)),
                        Aspect = Aspect.Center,
                        HeightRequest = imageData.height,
                        WidthRequest = imageData.width,
                        HorizontalOptions = LayoutOptions.Center,
                        VerticalOptions = LayoutOptions.Center,
                        ZIndex = 1000
                    }
                });
        }
        catch (RpcException e)
        {
            Console.WriteLine($"GetKioskInfo error {e.Message}");
            ToastMessage.Show($"GetKioskInfo server error {e.Message}", 18, ToastDuration.Long, null);
        }
        catch (Exception e)
        {
            Console.WriteLine($"GetKioskInfo error {e.Message}");
            ToastMessage.Show($"GetKioskInfo server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    private async Task GetHighResolutionImageWithIcaoChecksFromCameraIndex(string index)
    {
        var idx = int.Parse(index);

        StatusItems.Clear();
        ManualPhotos.Clear();

        try
        {
            var imageData =
                await dataService.GetHighResolutionImageWithIcaoChecksFromCameraIndex(idx, 10000, true, true);

            // show image
            if (imageData.data.Length != 0)
                ManualPhotos.Add(new PhotoItemViewModel
                {
                    index = imageData.index,
                    showPhoto = imageData.data.Length == 0 ? false : true,
                    showError = imageData.data.Length == 0 ? true : false,
                    photoBytes = imageData.data,
                    width = imageData.width,
                    height = imageData.height,
                    widthFrame = (int)Math.Abs(imageData.width * imageCropFactor),
                    heightFrame = (int)Math.Abs(imageData.height * imageCropFactor),
                    photoImage = new Image
                    {
                        Source = ImageSource.FromStream(() => new MemoryStream(imageData.data)),
                        Aspect = Aspect.Center,
                        HeightRequest = imageData.height,
                        WidthRequest = imageData.width,
                        HorizontalOptions = LayoutOptions.Center,
                        VerticalOptions = LayoutOptions.Center,
                        ZIndex = 1000
                    }
                });
        }
        catch (RpcException e)
        {
            Console.WriteLine($"GetKioskInfo error {e.Message}");
            ToastMessage.Show($"GetKioskInfo server error {e.Message}", 18, ToastDuration.Long, null);
        }
        catch (Exception e)
        {
            Console.WriteLine($"GetKioskInfo error {e.Message}");
            ToastMessage.Show($"GetKioskInfo server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    private async Task StartManualProcess()
    {
        // No ICAO checks in manual mode - a plain streaming list, no placeholders.
        processRowCount = 0;
        StatusItems.Clear();
        ManualPhotos.Clear();

        try
        {
            await foreach (var message in dataService.StartManualProcess())
            {
                if (message is ProcessStatus)
                {
                    ProcessStatus status = message;

                    AddServerStatus(status.description, (int)status.status);
                }

                if (message is ImageData)
                {
                    ImageData imageData = message;
                    if (imageData.data.Length != 0)
                        ManualPhotos.Add(new PhotoItemViewModel
                        {
                            index = imageData.index,
                            showPhoto = true,
                            showError = false,
                            photoBytes = imageData.data,
                            width = imageData.width,
                            height = imageData.height,
                            widthFrame = (int)Math.Abs(imageData.width * imageCropFactor),
                            heightFrame = (int)Math.Abs(imageData.height * imageCropFactor),
                            photoImage = new Image
                            {
                                Source = ImageSource.FromStream(() => new MemoryStream(imageData.data)),
                                Aspect = Aspect.Center,
                                HeightRequest = imageData.height,
                                WidthRequest = imageData.width,
                                HorizontalOptions = LayoutOptions.Center,
                                VerticalOptions = LayoutOptions.Center,
                                ZIndex = 1000
                            }
                        });
                }
            }
        }
        catch (RpcException e)
        {
            Console.WriteLine($"Manual Process stream cancelled. {e.Message}");
            ToastMessage.Show($"Manual Process stream cancelled. {e.Message}", 18, ToastDuration.Long, null);
        }
    }


    [RelayCommand]
    private async Task PickImage1()
    {
        try
        {
            var result = await FilePicker.Default.PickAsync(new PickOptions
            {
                PickerTitle = "Please select an image file",
                FileTypes = new FilePickerFileType(
                    new Dictionary<DevicePlatform, IEnumerable<string>>
                    {
                        { DevicePlatform.iOS, new[] { "public.png", "public.jpeg" } }, // UTType values
                        { DevicePlatform.Android, new[] { "image/jpeg", "image/png" } }, // MIME type
                        { DevicePlatform.WinUI, new[] { ".jpg", ".jpeg", ".png" } }, // file extension
                        { DevicePlatform.MacCatalyst, new[] { "public.png", "public.jpeg" } } // UTType values
                    })
            });
            if (result != null)
                if (result.FileName.EndsWith("jpg", StringComparison.OrdinalIgnoreCase) ||
                    result.FileName.EndsWith("jpeg", StringComparison.OrdinalIgnoreCase) ||
                    result.FileName.EndsWith("png", StringComparison.OrdinalIgnoreCase))
                {
                    await using var stream = await result.OpenReadAsync();
                    using var ms = new MemoryStream();
                    await stream.CopyToAsync(ms);
                    FileBytes1 = ms.ToArray();
                    PickImage1BtnText = result.FileName;
                }
        }
        catch (Exception e)
        {
            Console.WriteLine($"PickImage1 error {e.Message}");
            ToastMessage.Show($"PickImage1 server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    private async Task PickImage2()
    {
        try
        {
            var result = await FilePicker.Default.PickAsync(new PickOptions
            {
                PickerTitle = "Please select an image file",
                FileTypes = new FilePickerFileType(
                    new Dictionary<DevicePlatform, IEnumerable<string>>
                    {
                        { DevicePlatform.iOS, new[] { "public.png", "public.jpeg" } }, // UTType values
                        { DevicePlatform.Android, new[] { "image/jpeg", "image/png" } }, // MIME type
                        { DevicePlatform.WinUI, new[] { ".jpg", ".jpeg", ".png" } }, // file extension
                        { DevicePlatform.MacCatalyst, new[] { "public.png", "public.jpeg" } } // UTType values
                    })
            });
            if (result != null)
                if (result.FileName.EndsWith("jpg", StringComparison.OrdinalIgnoreCase) ||
                    result.FileName.EndsWith("jpeg", StringComparison.OrdinalIgnoreCase) ||
                    result.FileName.EndsWith("png", StringComparison.OrdinalIgnoreCase))
                {
                    await using var stream = await result.OpenReadAsync();
                    using var ms = new MemoryStream();
                    await stream.CopyToAsync(ms);
                    FileBytes2 = ms.ToArray();
                    PickImage2BtnText = result.FileName;
                }
        }
        catch (Exception e)
        {
            Console.WriteLine($"PickImage1 error {e.Message}");
            ToastMessage.Show($"PickImage1 server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }

    partial void OnSelectedRecognitionModelChanged(Model value)
    {
        selectedRecognitionModel = value;
    }

    [RelayCommand]
    private async Task ExecuteFaceRecognition()
    {
        try
        {
            // Build the request
            // threshold is optional, if not set, it will be 0.0
            var faceRecognitionRequest = new FaceRecognitionRequest
            {
                image1 = FileBytes1,
                image2 = FileBytes2,
                model = selectedRecognitionModel != null ? selectedRecognitionModel : Model.Dlib,
                threshold = string.IsNullOrEmpty(Threshold)
                    ? 0.0
                    : double.Parse(Threshold, CultureInfo.InvariantCulture)
            };

            var faceRecognitionResponse = await dataService.FaceRecognition(faceRecognitionRequest);


            Verified = faceRecognitionResponse.verified ? "Verified" : "Not verified";
            Distance = faceRecognitionResponse.distance.ToString();
            Status = faceRecognitionResponse.status.ToString();
            Time = faceRecognitionResponse.time.ToString();
        }
        catch (ArgumentNullException e)
        {
            Console.WriteLine($"Execute Face Recognition error {e.Message}");
            ToastMessage.Show("Execute Face Recognition error: no threshold.", 18, ToastDuration.Long, null);
        }
        catch (FormatException e)
        {
            Console.WriteLine($"ExecuteFaceRecognition error {e.Message}");
            ToastMessage.Show($"ExecuteFaceRecognition server error {e.Message}", 18, ToastDuration.Long, null);
        }
        catch (OverflowException e)
        {
            Console.WriteLine($"ExecuteFaceRecognition error {e.Message}");
            ToastMessage.Show($"ExecuteFaceRecognition server error {e.Message}", 18, ToastDuration.Long, null);
        }
        catch (Exception e)
        {
            Console.WriteLine($"PickImage1 error {e.Message}");
            ToastMessage.Show($"PickImage1 server error {e.Message}", 18, ToastDuration.Long, null);
        }
    }
}

public partial class PhotoItemViewModel : ObservableObject
{
    private readonly CancellationTokenSource cancellationTokenSource = new();

    public int index { get; set; }
    public bool showPhoto { get; set; }
    public bool showError { get; set; }
    public byte[] photoBytes { get; set; }
    public Image photoImage { get; set; }
    public int width { get; set; }
    public int height { get; set; }
    public int widthFrame { get; set; }
    public int heightFrame { get; set; }

    [RelayCommand]
    private async Task SavePhoto()
    {
        try
        {
            var stream = new MemoryStream(photoBytes);
            var path = await FileSaver.Default.SaveAsync("foto.jpg", stream, cancellationTokenSource.Token);
        }
        catch
        {
            // Exception thrown when user cancels
            ToastMessage.Show("Save photo cancelled.", 18, ToastDuration.Long, null);
        }
    }

    [RelayCommand]
    private void ShowPhoto()
    {
        var currentWindow = Application.Current.Windows.FirstOrDefault();
        var pageHeight = currentWindow.Height;
        var pageWidth = currentWindow.Width;

        double popupWidth = 0;
        double popupHeight = 0;
        var ratio = 0.8;
        var photoWiderThanApplicationWindow = width > pageWidth * ratio;
        var photoWidthSmallerOrEqualThanApplicationWindow = width <= pageWidth * ratio;
        var photoHigherThanApplicationWindow = height > pageHeight * ratio;
        var photoHeightSmallerOrEqualThanApplicationWindow = height <= pageHeight * ratio;


        if (photoWiderThanApplicationWindow || photoHigherThanApplicationWindow)
        {
            // If the image is large than the application, the app crashes
            if (photoWiderThanApplicationWindow && photoHigherThanApplicationWindow)
            {
                popupWidth = pageWidth * ratio;
                popupHeight = pageHeight * ratio;
            }

            if (photoWiderThanApplicationWindow && photoHeightSmallerOrEqualThanApplicationWindow)
            {
                popupWidth = pageWidth * ratio;
                popupHeight = height;
            }

            if (photoWidthSmallerOrEqualThanApplicationWindow && photoHigherThanApplicationWindow)
            {
                popupHeight = pageHeight * ratio;
                popupWidth = width;
            }
        }
        else
        {
            // photo fits in application window
            popupWidth = width;
            popupHeight = height;
        }

        var popup = new Popup
        {
            Size = new Size(popupWidth, popupHeight),
            Content = new ScrollView
            {
                Orientation = ScrollOrientation.Both,
                MaximumHeightRequest = height,
                MaximumWidthRequest = width,
                HorizontalScrollBarVisibility = ScrollBarVisibility.Always,
                VerticalScrollBarVisibility = ScrollBarVisibility.Always,
                Content = new Image
                {
                    Source = photoImage.Source,
                    Aspect = photoImage.Aspect,
                    HeightRequest = photoImage.HeightRequest,
                    WidthRequest = photoImage.WidthRequest,
                    HorizontalOptions = photoImage.HorizontalOptions,
                    VerticalOptions = photoImage.VerticalOptions,
                    ZIndex = photoImage.ZIndex
                }
            }
        };

        Shell.Current.CurrentPage.ShowPopup(popup);
    }
}

public class StatusItem
{
    public string Description { get; set; }
    public string Status { get; set; }
    public Color Color { get; set; }
    public Color TintColor { get; set; } = Colors.Transparent;

    // Identifies which ICAO check a row belongs to, so a streamed result can replace
    // the pre-populated neutral placeholder of the same check. Null = process message.
    public string Key { get; set; }

    // Kiosk-app palette: pass green / fail red / warn amber / neutral process info,
    // each with the soft row tint the kiosk check list uses.
    private static readonly Color PassColor = Color.FromArgb("#3E9142");
    private static readonly Color FailColor = Color.FromArgb("#C6413D");
    private static readonly Color WarnColor = Color.FromArgb("#C77D2A");
    private static readonly Color InfoColor = Color.FromArgb("#5B6673");
    private static readonly Color PendingColor = Color.FromArgb("#B9C2CA");
    private static readonly Color PassTint = Color.FromArgb("#E4EFE0");
    private static readonly Color FailTint = Color.FromArgb("#F7E3E1");
    private static readonly Color WarnTint = Color.FromArgb("#F8EBDC");
    // Neutral rows (process steps + pending checks) stay on a plain white row.
    private static readonly Color NeutralTint = Colors.White;

    // Server message prefix -> check key. Prefixes must match the server's exact
    // wording (constants.py Yields + automatic_process_flow yield strings).
    private static readonly (string Prefix, string Key)[] CheckPrefixes =
    {
        ("Distance in cm", "distance"),
        ("Lips are closed", "lips"),
        ("Both eyes are opened", "eyes"),
        ("Glasses detected", "glasses"),
        ("Head pose frontal", "head_pose"),
        ("Sharpness OK", "sharpness"),
        ("Red eye detected", "red_eye"),
        ("Expression neutral", "expression"),
        ("Looking at camera", "gaze"),
        ("Lighting even", "lighting"),
        ("Head size/position OK", "head_size"),
    };

    // Badge symbols are plain Unicode rendered with the system font: this app runs
    // UNPACKAGED on Windows, where MAUI does not load custom fonts (the FontAwesome
    // glyphs used elsewhere render as boxes - including the tab bar icons).
    private const string GlyphPending = "";
    private const string GlyphPass = "✓";   // check mark
    private const string GlyphFail = "✕";   // multiplication x
    private const string GlyphWarn = "!";
    private const string GlyphInfo = "i";

    /// <summary>A neutral white row shown before the check's result has arrived.</summary>
    public static StatusItem Placeholder(string key, string title) =>
        new()
        {
            Key = key,
            Description = title,
            Status = GlyphPending,
            Color = PendingColor,
            TintColor = NeutralTint
        };

    /// <summary>
    /// Builds a result row from a streamed server message. The server marks every
    /// step it streams as OK (only hard errors carry another status), so the real
    /// outcome of an ICAO check is derived from the message text itself.
    /// </summary>
    public static StatusItem FromServerMessage(string description, int serverStatus)
    {
        var d = description ?? "";
        var key = CheckPrefixes.FirstOrDefault(p => d.StartsWith(p.Prefix)).Key;

        if (serverStatus != 0)
            return Fail(d, key);

        // ICAO checks are phrased "<check>: True/False (details)".
        if (d.Contains(": True") || d.Contains(": False"))
        {
            var value = d.Contains(": True");
            // For these checks a "True" is the bad outcome.
            var trueIsBad = d.StartsWith("Glasses detected") || d.StartsWith("Red eye detected");
            var pass = trueIsBad ? !value : value;

            // Glasses are permitted on many passport photos - flag, don't fail.
            if (!pass && d.StartsWith("Glasses detected"))
                return Make(d, GlyphWarn, WarnColor, WarnTint, key);

            return pass ? Pass(d, key) : Fail(d, key);
        }

        // Measurements and gate checks that only appear once the frame was accepted.
        if (key != null)
            return Pass(d, key);

        // Failure messages streamed with an OK status.
        if (d.StartsWith("Could not find landmarks") || d.Contains("stopped delivering frames")
            || d.Contains("failed") || d.Contains("Please try again"))
            return Fail(d, null);

        // Everything else is a process step (camera selected, taking photo...).
        return Make(d, GlyphInfo, InfoColor, NeutralTint, null);
    }

    private static StatusItem Pass(string d, string key) =>
        Make(d, GlyphPass, PassColor, PassTint, key);

    private static StatusItem Fail(string d, string key) =>
        Make(d, GlyphFail, FailColor, FailTint, key);

    private static StatusItem Make(string d, string glyph, Color color, Color tint, string key) =>
        new() { Description = d, Status = glyph, Color = color, TintColor = tint, Key = key };
}

public class RecognitionModel : ObservableObject
{
    public string modelName { get; set; }
    public Model recognitionModel { get; set; }
}

public interface IPopupService
{
    void ShowPopup(Popup popup);
}

public class PopupService : IPopupService
{
    public void ShowPopup(Popup popup)
    {
        var page = Application.Current?.MainPage ?? throw new NullReferenceException();
        page.ShowPopup(popup);
    }
}
