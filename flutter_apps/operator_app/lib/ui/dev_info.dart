// Developer mode: small </> badges next to SDK-backed controls that open a
// popup explaining how to implement that functionality with the FaceSnap SDKs
// (C# facesnap-sdk / Dart face_snap_grpc), with copyable snippets and a link
// into the API reference. Badges only render while DevMode.enabled is on; the
// preference persists in config.json (AppConfig.devMode).
//
// Adding a topic = one _DevTopic entry in _devTopics + a DevInfoBadge('<id>')
// next to the control. Keep snippets REAL (the patterns from the docs site).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_config.dart';
import 'ui.dart';

/// App-wide developer-mode switch; pages listen via ValueListenableBuilder so
/// no page wiring is needed. Initialised from AppConfig in main().
class DevMode {
  DevMode._();

  static final ValueNotifier<bool> enabled = ValueNotifier(false);

  static Future<void> set(bool on) async {
    enabled.value = on;
    AppConfig.devMode = on;
    await AppConfig.save();
  }
}

class _DevTopic {
  const _DevTopic({
    required this.title,
    required this.rpc,
    required this.summary,
    required this.snippets,
    required this.docsUrl,
  });

  final String title;

  /// The RPC / SDK entry point shown as a chip in the summary.
  final String rpc;
  final String summary;

  /// Ordered tab label -> code snippet.
  final Map<String, String> snippets;
  final String docsUrl;
}

const _docsBase = 'https://gridler-tech.github.io/face_snap';

final Map<String, _DevTopic> _devTopics = {
  // ---- Kiosk page ---------------------------------------------------------
  'discovery': _DevTopic(
    title: 'Finding and connecting to kiosks',
    rpc: '_facesnap._tcp (mDNS)',
    summary: 'Every provisioned kiosk announces the _facesnap._tcp mDNS '
        'service: the SRV record carries the gRPC port, the A record the '
        'address. Search sends a one-shot PTR query and lists the answers. '
        'Connecting is then just pointing the shared gRPC channel at the '
        'chosen host:port — plain HTTP/2 (h2c), no TLS.',
    snippets: {
      'C# — facesnap-sdk': '''
// Point the shared channel at a kiosk once; every processor uses it.
GrpcChannelProvider.SetAddress("http://192.168.1.50:50051");

var settings = new SettingsProcessor();
var snapshot = await settings.LoadSettings();   // proves the server answers''',
      'Dart — face_snap_grpc': '''
// One-shot mDNS query; full implementation in the demo repo's
// flutter_apps/operator_app/lib/services/discovery.dart.
final kiosks = await discoverKiosks();
final kiosk = kiosks.first;

// Connect on the port the kiosk ANNOUNCED (its SRV record).
await GrpcChannelProvider.setAddress(kiosk.ip, kiosk.port ?? 50051);''',
      'Protocol': '''
query   : PTR _facesnap._tcp.local        (multicast 224.0.0.251:5353)
answer  : SRV facesnap-<mac>._facesnap._tcp.local  -> port, target host
          A   facesnap-<mac>.local                 -> 192.168.x.x
connect : gRPC over plain HTTP/2 (h2c) on <ip>:<port> — no TLS,
          so keep kiosks on a trusted network''',
    },
    docsUrl: '$_docsBase/docs/getting-started.html',
  ),
  'server-local': _DevTopic(
    title: 'Managing a server on this PC',
    rpc: 'ServerProcessManager',
    summary: 'For a co-located Windows deployment the client owns the '
        "server's lifecycle. The C# SDK ships ServerProcessManager: "
        'EnsureRunningAsync starts the server exe when the gRPC port is not '
        'open (and no-ops for a remote address or an already-running '
        'server); Stop only kills a process it started itself.',
    snippets: {
      'C# — facesnap-sdk': '''
var manager = new ServerProcessManager();
await manager.EnsureRunningAsync(TimeSpan.FromSeconds(30));

// ... use the processors against localhost:50051 ...

manager.Stop();   // only stops a server this manager started''',
      'Dart': '''
// The Dart package has no lifecycle helper; this app shells out to the
// same start/stop/autostart logic instead — see the demo repo's
// flutter_apps/operator_app/lib/services/server_manager.dart.
final result = await Process.run(
    'powershell', ['-NoProfile', '-Command', startServerCommand]);''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.ServerProcessManager.html',
  ),
  'server-board': _DevTopic(
    title: 'Controlling a kiosk board\'s server',
    rpc: 'systemctl over SSH',
    summary: 'On the ARM kiosk boards the server runs as the '
        'face-snap-docker-compose.service systemd unit. Lifecycle is not an '
        'RPC (a stopped server cannot start itself) — control it over SSH. '
        'This app reads the SSH credentials from its config.json.',
    snippets: {
      'Shell / SSH': '''
ssh root@<board> systemctl is-active face-snap-docker-compose.service
ssh root@<board> systemctl restart   face-snap-docker-compose.service''',
      'Dart — dartssh2': '''
// SshRunner: the demo repo's shared SSH wrapper (updater + operator).
final ssh = await SshRunner.connect(host, user, password);
try {
  final out =
      await ssh.run('systemctl is-active face-snap-docker-compose.service');
  final running = out.stdout.trim() == 'active';
} finally {
  ssh.close();
}''',
    },
    docsUrl: '$_docsBase/docs/getting-started.html',
  ),

  // ---- Capture page -------------------------------------------------------
  'capture': _DevTopic(
    title: 'Automatic & manual capture',
    rpc: 'Kiosk.StartAutomaticProcess',
    summary: 'Both flows are server-streaming RPCs. Automatic selects the '
        'best camera, runs the enabled quality checks and returns ONE photo; '
        'manual skips selection and checks and returns a photo per camera. '
        'You receive ProcessStatus items (one per check) followed by the '
        'photo(s) as ImageData chunks.',
    snippets: {
      'C# — facesnap-sdk': '''
var kiosk = new KioskProcessor();

await foreach (var item in kiosk.StartAutomaticProcess())
{
    switch (item)
    {
        case ProcessStatus s:   // one row per quality check
            ShowCheck(s.description, s.status);  break;
        case ImageData img:     // the finished photo
            File.WriteAllBytes("photo.jpg", img.data); break;
    }
}''',
      'Dart — face_snap_grpc': '''
final stream = automatic ? startAutomaticCapture() : startManualCapture();

await for (final event in stream) {
  switch (event) {
    case CaptureStatus(:final description, :final ok):
      showCheck(description, ok);
    case CapturePhoto(:final bytes):            // automatic: one photo
      savePhoto(bytes);
    case CameraPhoto(:final cameraIndex, :final bytes): // manual: per camera
      savePhoto(bytes, camera: cameraIndex);
  }
}''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.KioskProcessor.html',
  ),
  'capture-photos': _DevTopic(
    title: 'Requesting a single photo',
    rpc: 'GetHighResolutionImageFromCameraIndex',
    summary: 'Besides the capture flows you can request one high-resolution '
        'photo from a specific camera — plain, or with the ICAO checks '
        'applied first. The image streams back in chunks; the SDK assembles '
        'them into one ImageData.',
    snippets: {
      'C# — facesnap-sdk': '''
var kiosk = new KioskProcessor();

// Plain photo from camera 2 (timeout in ms):
var img = await kiosk.GetHighResolutionImageFromCameraIndex(2, 15000);

// Or gated on the ICAO checks:
var checked = await kiosk
    .GetHighResolutionImageWithIcaoChecksFromCameraIndex(2, 15000,
        eyesCheck: true, lipsCheck: true);''',
      'Dart — face_snap_grpc': '''
final kiosk = KioskClient(GrpcChannelProvider.channel);
final bytes = <int>[];
await for (final chunk in kiosk.getHighResolutionImageFromCameraIndex(
    HighResImageRequest(index: 2, timeoutInMs: 15000))) {
  bytes.addAll(chunk.processImageData.chunkData);
}''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.KioskProcessor.html',
  ),
  'capture-results': _DevTopic(
    title: 'The quality-check stream',
    rpc: 'ProcessStatus',
    summary: 'During a capture every enabled check yields one ProcessStatus '
        '{index, description, status} on the stream — OK, NOK or an '
        'informational step. Render them as they arrive to give live '
        'guidance; the rows on this card are exactly that stream.',
    snippets: {
      'C# — facesnap-sdk': '''
await foreach (var item in kiosk.StartAutomaticProcess())
{
    if (item is ProcessStatus s)
    {
        // s.index = camera, s.description = "Both eyes are opened", ...
        // s.status = Status.Ok / Status.Nok
        AddChecklistRow(s.description, s.status == Status.Ok);
    }
}''',
      'Dart — face_snap_grpc': '''
await for (final event in startAutomaticCapture()) {
  if (event is CaptureStatus) {
    addChecklistRow(event.description, event.ok);
  }
}''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.KioskProcessor.html',
  ),

  // ---- Photo page ---------------------------------------------------------
  'photo-adjustment': _DevTopic(
    title: 'Photo format & processing',
    rpc: 'SettingsProcessor.SetPhotoFormat',
    summary: 'Each control is an immediate unary setter. The photo format '
        'decides the aspect ratio AND how the face is framed; background '
        'erasing takes a method (none / mediapipe / modnet) plus a fill '
        'colour; JPEG quality applies to delivered photos.',
    snippets: {
      'C# — facesnap-sdk': '''
var settings = new SettingsProcessor();
await settings.SetPhotoFormat("icao_35x45");   // or us_2x2, ca_50x70, ...
await settings.SetCrop(true);
await settings.SetBackgroundMethod("modnet");
await settings.SetBackgroundColor("FFFFFF");
await settings.SetJpegQuality(95);             // 50-100''',
      'Dart — face_snap_grpc': '''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setPhotoFormat(PhotoFormatRequest(value: 'icao_35x45'));
await c.setBackgroundMethod(BackgroundMethodRequest(method: 'modnet'));
await c.setBackgroundColor(BackgroundColorRequest(color: 'FFFFFF'));
await c.setJpegQuality(JpegQualityRequest(value: 95));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.SettingsProcessor.html',
  ),
  'quality-checks': _DevTopic(
    title: 'Enabling quality checks',
    rpc: 'SetEyesCheck / SetOfiqChecks / …',
    summary: 'Every check is a bool setter: eyes, lips, glasses, head pose, '
        'sharpness, red-eye, head size, expression, gaze, lighting evenness '
        '— plus SetOfiqChecks to score with OFIQ (ISO/IEC 29794-5) instead '
        'of the built-in checks. Results come back as ProcessStatus rows in '
        'the capture stream.',
    snippets: {
      'C# — facesnap-sdk': '''
var settings = new SettingsProcessor();
await settings.SetEyesCheck(true);
await settings.SetHeadPoseCheck(true);
await settings.SetSharpnessCheck(true);
await settings.SetOfiqChecks(false);   // true = OFIQ quality report mode''',
      'Dart — face_snap_grpc': '''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setEyesCheck(EyesCheckRequest(value: true));
await c.setHeadPoseCheck(HeadPoseCheckRequest(value: true));
await c.setOfiqChecks(OfiqChecksRequest(value: false));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.SettingsProcessor.html',
  ),

  // ---- Lighting page ------------------------------------------------------
  'kiosk-lighting': _DevTopic(
    title: 'Lighting settings',
    rpc: 'SetIntensityRed / SetLedLayout / SetFocusLight',
    summary: 'LED brightness is set per colour channel (0-200). The LED '
        'hardware layout ("strip" or "ring") decides which MicroPython '
        'files the server provisions onto the Plasma board — changing it '
        're-provisions automatically. The focus light marks the selected '
        'camera: colour as RRGGBB hex plus intensity 0-100%.',
    snippets: {
      'C# — facesnap-sdk': '''
var settings = new SettingsProcessor();
await settings.SetIntensityRed(200);
await settings.SetIntensityGreen(200);
await settings.SetIntensityBlue(200);
await settings.SetLedLayout("ring");          // or "strip"
await settings.SetFocusLight("00FF00", 78);   // colour, intensity %''',
      'Dart — face_snap_grpc': '''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setIntensityRed(IntensityRequest(value: 200));
await c.setLedLayout(LedLayoutRequest(value: 'ring'));
await c.setFocusLight(
    FocusLightRequest(color: '00FF00', intensity: 78));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.SettingsProcessor.html',
  ),
  'lights': _DevTopic(
    title: 'Driving the LEDs directly',
    rpc: 'LightProcessor',
    summary: 'Direct LED control, separate from the stored settings: all '
        'lights on/off, the light at one camera, glare-safe lighting for a '
        'subject wearing glasses, and the closed-loop white-point tune that '
        'measures each channel with the light sensor (streamed progress).',
    snippets: {
      'C# — facesnap-sdk': '''
var lights = new LightProcessor();
await lights.SetAllLights(true);
await lights.SetLightAtCameraIndex(2);
await lights.SetGlareSafeLights(2);      // glasses: no source at eye level

await foreach (var step in lights.AutoTuneWhitePoint())
{
    Show(step.message);                   // step.done ends the run
}''',
      'Dart — face_snap_grpc': '''
final lights = LightsClient(GrpcChannelProvider.channel);
await lights.setAllLights(AllLightsRequest(status: true));
await lights.setLightAtCameraIndex(LightIndexRequest(index: 2));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.LightProcessor.html',
  ),

  // ---- Camera page --------------------------------------------------------
  'camera-resolution': _DevTopic(
    title: 'Capture resolution',
    rpc: 'SettingsProcessor.SetResolution',
    summary: 'Sets the capture resolution for all cameras. The supported '
        'resolutions come from LoadSettings (cameraResolutions), so offer '
        'only those.',
    snippets: {
      'C# — facesnap-sdk': '''
var settings = new SettingsProcessor();
var snapshot = await settings.LoadSettings();
// snapshot.cameraResolutions = what the cameras support
await settings.SetResolution(1280, 720);''',
      'Dart — face_snap_grpc': '''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setResolution(ResolutionRequest(width: 1280, height: 720));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.SettingsProcessor.html',
  ),
  'camera-preview': _DevTopic(
    title: 'Live camera preview',
    rpc: 'Kiosk.StreamPreview',
    summary: 'Streams complete JPEG frames (~15 fps) from ONE camera until '
        'you stop reading or maxSeconds elapses. One camera at a time — '
        'USB2 bandwidth is shared with captures, so stop the preview before '
        'capturing.',
    snippets: {
      'C# — facesnap-sdk': '''
var kiosk = new KioskProcessor();
await foreach (var frame in kiosk.StreamPreview(2, maxSeconds: 300))
{
    ShowJpeg(frame.data);   // one complete JPEG per frame
}''',
      'Dart — face_snap_grpc': '''
final kiosk = KioskClient(GrpcChannelProvider.channel);
await for (final frame in kiosk
    .streamPreview(PreviewRequest(cameraIndex: 2, maxSeconds: 300))) {
  showJpeg(frame.chunkData);   // one complete JPEG per message
}''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.KioskProcessor.html',
  ),
  'camera-properties': _DevTopic(
    title: 'Camera properties',
    rpc: 'CameraProcessor',
    summary: 'LoadSettings returns the current values PLUS the per-property '
        'ranges the camera actually supports (and which properties it does '
        'not) — size your sliders from those. Each Set* applies the value '
        'to all cameras in the column.',
    snippets: {
      'C# — facesnap-sdk': '''
var camera = new CameraProcessor();
var s = await camera.LoadSettings();   // values + propertyRanges

await camera.SetBrightness(128);
await camera.SetExposureAbsolute(-6);
await camera.SetAutofocus(false);
await camera.SetFocusAbsolute(40);''',
      'Dart — face_snap_grpc': '''
final c = CameraClient(GrpcChannelProvider.channel);
final s = await c.loadSettings(Empty());  // values + property_ranges
await c.setBrightness(BrightnessRequest(value: 128));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.CameraProcessor.html',
  ),
  'camera-distance': _DevTopic(
    title: 'Subject distance window',
    rpc: 'SetDistanceMin / SetDistanceMax',
    summary: 'The allowed subject distance in cm. During capture the server '
        'measures the distance from the iris width in the frame and the '
        'distance check passes only inside this window.',
    snippets: {
      'C# — facesnap-sdk': '''
var settings = new SettingsProcessor();
await settings.SetDistanceMin(40);   // cm
await settings.SetDistanceMax(80);''',
      'Dart — face_snap_grpc': '''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setDistanceMin(DistanceMinRequest(value: 40));
await c.setDistanceMax(DistanceMaxRequest(value: 80));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.SettingsProcessor.html',
  ),
  'camera-windows': _DevTopic(
    title: 'Windows host options',
    rpc: 'SetCameraOrderingMode / SetMsmfSelection',
    summary: 'Windows-hosted kiosks only: camera ordering "manual" '
        '(calibrate once, matched by USB port) or "automatic" (derived from '
        'the standard-hub map, no calibration), and whether the best-camera '
        'scan uses the faster Media Foundation backend.',
    snippets: {
      'C# — facesnap-sdk': '''
var settings = new SettingsProcessor();
await settings.SetCameraOrderingMode(automatic: false);
await settings.SetMsmfSelection(enabled: true);''',
      'Dart — face_snap_grpc': '''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setCameraOrderingMode(
    CameraOrderingModeRequest(automatic: false));
await c.setMsmfSelection(MsmfSelectionRequest(enabled: true));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.SettingsProcessor.html',
  ),

  // ---- Calibration page ---------------------------------------------------
  'calibration-positions': _DevTopic(
    title: 'Camera positions',
    rpc: 'Calibration.GetCalibration',
    summary: 'GetCalibration returns one entry per ATTACHED camera with the '
        'position the capture flow resolves for it. SetCalibration rewrites '
        'the calibration in the list order you send (position = index in '
        'the list). Identity is the USB PORT, not the camera unit — a '
        'replacement camera in the same port needs no recalibration.',
    snippets: {
      'C# — facesnap-sdk': '''
var calibration = new CalibrationProcessor();
var entries = await calibration.GetCalibration();

// Reorder as the operator assigned, then save:
await calibration.SetCalibration(orderedEntries);''',
      'Dart — face_snap_grpc': '''
final c = CalibrationClient(GrpcChannelProvider.channel);
final current = await c.getCalibration(Empty());
await c.setCalibration(CalibrateRequest(calibrate: orderedRows));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.CalibrationProcessor.html',
  ),
  'expected-cameras': _DevTopic(
    title: 'Expected camera count',
    rpc: 'SetExpectedCameras',
    summary: 'How many cameras the kiosk is built with (1-6), or 0 to '
        'derive the count from the calibration file. The server\'s hardware '
        'watcher compares the attached count against this and power-cycles '
        'the camera USB hub when cameras are missing.',
    snippets: {
      'C# — facesnap-sdk': '''
var settings = new SettingsProcessor();
await settings.SetExpectedCameras(4);   // 0 = automatic''',
      'Dart — face_snap_grpc': '''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setExpectedCameras(ExpectedCamerasRequest(value: 4));''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.SettingsProcessor.html',
  ),
  'calibrate-focus': _DevTopic(
    title: 'Focus calibration',
    rpc: 'Camera.CalibrateFocus',
    summary: 'Installation-time assistant: lights on, a person stands at '
        'the kiosk marking, the camera\'s autofocus settles and the locked '
        'lens position is stored as the fixed focus (autofocus back off). '
        'Camera index 0 = the server first runs its best-camera selection. '
        'Takes up to ~90 s; returns the settled value or -1 (no lock).',
    snippets: {
      'C# — facesnap-sdk': '''
var camera = new CameraProcessor();
var result = await camera.CalibrateFocus(0);   // 0 = auto-select camera
if (result.focusAbsolute >= 0) { /* stored as fixed focus */ }''',
      'Dart — face_snap_grpc': '''
final c = CameraClient(GrpcChannelProvider.channel);
final response = await c.calibrateFocus(
    CalibrateFocusRequest(cameraIndex: 0),
    options: CallOptions(timeout: const Duration(seconds: 90)));
final settled = response.message;   // -1 = no stable lock''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.CameraProcessor.html',
  ),

  // ---- Face recognition page ----------------------------------------------
  'face-recognition': _DevTopic(
    title: 'Comparing two photos',
    rpc: 'Kiosk.FaceRecognition',
    summary: 'Compares two JPEGs (e.g. a fresh capture against a stored '
        'passport photo). Models: Dlib, Facenet512, SFace; metrics cosine / '
        'euclidean / euclidean_l2. The result is a distance judged against '
        'the threshold — leave the threshold unset to use the model\'s '
        'calibrated default (e.g. Dlib·cosine 0.07).',
    snippets: {
      'C# — facesnap-sdk': '''
var kiosk = new KioskProcessor();
var result = await kiosk.FaceRecognition(new Dto.FaceRecognitionRequest
{
    image1 = photoBytes1,
    image2 = photoBytes2,
    model = Model.Dlib,
    similarity_metric = "cosine",
});
// result.verified, result.distance, result.threshold, result.time''',
      'Dart — face_snap_grpc': '''
final kiosk = KioskClient(GrpcChannelProvider.channel);
final result = await kiosk.faceRecognition(FaceRecognitionRequest(
  image1: bytes1,
  image2: bytes2,
  model: Model.DLIB,
  similarityMetric: 'cosine',
));
// result.verified, result.distance, result.threshold''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.KioskProcessor.html',
  ),

  // ---- Monitoring page ----------------------------------------------------
  'monitoring-status': _DevTopic(
    title: 'Hardware status stream',
    rpc: 'Monitoring.GetKioskStatus',
    summary: 'Server-streaming health report: one (description, status) '
        'row per checked component — cameras, LED board, server. The '
        'stream ends when the report is complete.',
    snippets: {
      'C# — facesnap-sdk': '''
var monitoring = new MonitoringProcessor();
await foreach (var (description, status) in monitoring.GetKioskStatus())
{
    AddRow(description, status);
}''',
      'Dart — face_snap_grpc': '''
final m = MonitoringClient(GrpcChannelProvider.channel);
await for (final line in m.getKioskStatus(Empty())) {
  addRow(line.description, line.status);
}''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.MonitoringProcessor.html',
  ),
  'kiosk-info': _DevTopic(
    title: 'Kiosk information',
    rpc: 'GetKioskInfo',
    summary: 'One unary call with the kiosk\'s identity: server IP address, '
        'gRPC port, number of cameras and per-camera data.',
    snippets: {
      'C# — facesnap-sdk': '''
var kiosk = new KioskProcessor();
var info = await kiosk.GetKioskInfo();
// info.kioskData.serverIpAddress / .port / .numberOfCameras''',
      'Dart — face_snap_grpc': '''
final kiosk = KioskClient(GrpcChannelProvider.channel);
final info = await kiosk.getKioskInfo(Empty());''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.KioskProcessor.html',
  ),
  'light-measurement': _DevTopic(
    title: 'Reading the light sensor',
    rpc: 'GetLightMeasurement',
    summary: 'One reading from the kiosk\'s OPT4048 sensor: illuminance '
        '(lux), correlated colour temperature (Kelvin) and CIE 1931 '
        'chromaticity. available is false when no sensor is attached.',
    snippets: {
      'C# — facesnap-sdk': '''
var monitoring = new MonitoringProcessor();
var light = await monitoring.GetLightMeasurement();
// light.available, light.lux, light.cct, light.cieX / cieY''',
      'Dart — face_snap_grpc': '''
final m = MonitoringClient(GrpcChannelProvider.channel);
final light = await m.getLightMeasurement(Empty());''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.MonitoringProcessor.html',
  ),
  'usage-stream': _DevTopic(
    title: 'System usage stream',
    rpc: 'Monitoring.OdroidUsage',
    summary: 'Continuous stream of usage readings (CPU, memory, network, '
        'temperature) until you cancel the subscription — cancel it when '
        'the page closes or the server keeps streaming.',
    snippets: {
      'C# — facesnap-sdk': '''
var monitoring = new MonitoringProcessor();
await foreach (var usage in monitoring.OdroidUsage())
{
    Show(usage.usageType, usage.usage);
}''',
      'Dart — face_snap_grpc': '''
final m = MonitoringClient(GrpcChannelProvider.channel);
final subscription = m.odroidUsage(Empty()).listen(
    (u) => show(u.usageType, u.usage));
// later: await subscription.cancel();''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.MonitoringProcessor.html',
  ),
};

/// The small </> badge. Renders nothing while developer mode is off.
class DevInfoBadge extends StatelessWidget {
  const DevInfoBadge(this.topicId, {super.key});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DevMode.enabled,
      builder: (context, on, _) {
        if (!on) return const SizedBox.shrink();
        final topic = _devTopics[topicId];
        if (topic == null) return const SizedBox.shrink();
        return Tooltip(
          message: 'How to implement: ${topic.title}',
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _DevInfoDialog(topic),
            ),
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: T.titleBlue, width: 1.5),
              ),
              child: const Text('</>',
                  style: TextStyle(
                      color: T.titleBlue,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      height: 1)),
            ),
          ),
        );
      },
    );
  }
}

/// The "Developer mode" pill with its switch (Kiosk page, top right).
class DevModeToggle extends StatelessWidget {
  const DevModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DevMode.enabled,
      builder: (context, on, _) {
        final color = on ? T.titleBlue : T.muted;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: T.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? T.titleBlue : T.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('</>',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text('Developer mode',
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Switch(
              value: on,
              activeThumbColor: T.titleBlue,
              onChanged: (v) => DevMode.set(v),
            ),
          ]),
        );
      },
    );
  }
}

class _DevInfoDialog extends StatefulWidget {
  const _DevInfoDialog(this.topic);

  final _DevTopic topic;

  @override
  State<_DevInfoDialog> createState() => _DevInfoDialogState();
}

class _DevInfoDialogState extends State<_DevInfoDialog> {
  int _tab = 0;

  static const _codeStyle = TextStyle(
    fontFamily: 'Consolas',
    fontFamilyFallback: ['Courier New', 'monospace'],
    fontSize: 12.5,
    height: 1.65,
    color: Color(0xFFDCE4EC),
  );

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final labels = topic.snippets.keys.toList();
    final code = topic.snippets[labels[_tab]]!.trim();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- header ----
              Row(children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: T.titleBlue, shape: BoxShape.circle),
                  child: const Text('</>',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Implementing: ${topic.title}',
                      style: const TextStyle(
                          color: T.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: T.muted)),
              ]),
              const SizedBox(height: 8),

              // ---- summary with the RPC chip ----
              Text.rich(
                TextSpan(children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3EDF7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(topic.rpc,
                          style: const TextStyle(
                              fontFamily: 'Consolas',
                              fontFamilyFallback: ['Courier New', 'monospace'],
                              color: T.titleBlue,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const TextSpan(text: '   '),
                  TextSpan(text: topic.summary),
                ]),
                style: const TextStyle(
                    color: T.muted, fontSize: 13, height: 1.55),
              ),
              const SizedBox(height: 12),

              // ---- tabs ----
              Row(children: [
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => setState(() => _tab = i),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: i == _tab ? T.ink : const Color(0xFFEFF2F5),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                        ),
                        child: Text(labels[i],
                            style: TextStyle(
                                color: i == _tab ? Colors.white : T.muted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ]),

              // ---- code block ----
              Flexible(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: T.ink,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(code, style: _codeStyle),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ---- footer ----
              Row(children: [
                QuietButton(
                  text: 'Copy code',
                  width: 130,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Snippet copied to the clipboard.')));
                  },
                ),
                const SizedBox(width: 14),
                InkWell(
                  onTap: () => Process.run(
                      'cmd', ['/c', 'start', '', topic.docsUrl],
                      runInShell: false),
                  child: const Text('Open API reference ↗',
                      style: TextStyle(
                          color: T.titleBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                SizedBox(
                  width: 110,
                  child: GoButton(
                      text: 'Got it',
                      onPressed: () => Navigator.of(context).pop()),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
