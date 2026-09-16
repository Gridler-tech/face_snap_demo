// FaceSnap SDK sample — a minimal console client for GrpcLibrary that walks the
// getting-started flow against a running Face Snap server: read the kiosk info
// and settings, run one automatic capture, save the photo, and verify it with
// face recognition.
//
//   dotnet run --project csharp_sample -- [server] [reference-photo]
//
//   server           gRPC address of the kiosk server (default http://localhost:50051)
//   reference-photo  optional image file to verify the captured photo against
//                    (a passport photo, say); when omitted the captured photo is
//                    compared with itself to demonstrate the call
//
// Full API reference: https://gridler-tech.github.io/face_snap/
using Grpc.Core;
using GrpcLibrary;
using Dto = GrpcLibrary.Dto;

var address = args.Length > 0 ? args[0] : "http://localhost:50051";
var referencePath = args.Length > 1 ? args[1] : null;

try
{
    // All processors share one channel; constructing the first one sets the
    // address (it can be changed later with GrpcChannelProvider.SetAddress).
    var kiosk = new KioskProcessor(address);
    var settingsProcessor = new SettingsProcessor();

    // 1. Kiosk info — proves the connection and shows what the server detected.
    Dto.KioskInfo info = await kiosk.GetKioskInfo();
    Console.WriteLine($"Connected to {info.kioskData.serverIpAddress}:{info.kioskData.port} " +
                      $"({info.kioskData.numberOfCameras} cameras).");

    // 2. The current kiosk settings.
    Dto.KioskSettingsDto settings = await settingsProcessor.LoadSettings();
    var expected = settings.expectedCameras == 0 ? "automatic" : settings.expectedCameras.ToString();
    Console.WriteLine($"Photo format {settings.photoFormat}, capture {settings.width}x{settings.height}, " +
                      $"lighting {(settings.lighting ? "on" : "off")}, expected cameras {expected}.");

    // 3. One automatic capture: the server selects the best camera, runs the
    //    enabled ICAO quality checks, streams a status line per step and
    //    finally the finished photo.
    Console.WriteLine("Starting the automatic capture — stand at the floor marking...");
    byte[]? photo = null;
    await foreach (var message in kiosk.StartAutomaticProcess())
    {
        if (message is Dto.ProcessStatus status)
        {
            Console.WriteLine($"  [{status.status}] {status.description}");
        }
        else if (message is Dto.ImageData image)
        {
            photo = image.data;
            Console.WriteLine($"  Photo received: {image.width}x{image.height} {image.format}, " +
                              $"{image.data.Length} bytes.");
        }
    }

    if (photo is null || photo.Length == 0)
    {
        Console.WriteLine("No photo was delivered — see the status lines above.");
        return 1;
    }

    var photoPath = Path.GetFullPath("facesnap_photo.jpg");
    await File.WriteAllBytesAsync(photoPath, photo);
    Console.WriteLine($"Saved {photoPath}.");

    // 4. Face recognition: verify the captured photo against the reference
    //    photo. Threshold 0 uses the model's default for the chosen metric;
    //    models are Dlib (default), Facenet512 and Sface.
    var reference = referencePath is null ? photo : await File.ReadAllBytesAsync(referencePath);
    Dto.FaceRecognitionResponse result = await kiosk.FaceRecognition(new Dto.FaceRecognitionRequest
    {
        image1 = photo,
        image2 = reference,
        threshold = 0,
        model = Model.Dlib,
        similarity_metric = DistanceMetric.Cosine,
    });
    Console.WriteLine($"Face recognition ({result.model}, {result.similarity_metric}): " +
                      $"{(result.verified ? "same person" : "different person")} " +
                      $"(distance {result.distance:F3}, threshold {result.threshold:F3}).");
    return 0;
}
catch (RpcException e)
{
    Console.Error.WriteLine($"gRPC call failed ({e.StatusCode}): {e.Status.Detail}");
    Console.Error.WriteLine($"Is a Face Snap server running and reachable at {address}?");
    return 1;
}
