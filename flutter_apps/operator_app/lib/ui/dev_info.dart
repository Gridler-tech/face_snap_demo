// Developer mode: small </> badges next to SDK-backed controls that open a
// popup explaining how to implement that functionality with the FaceSnap SDKs
// (C# facesnap-sdk / Dart face_snap_grpc), with copyable snippets and a link
// into the SDK documentation. Badges only render while DevMode.enabled is on;
// the preference persists in config.json (AppConfig.devMode).
//
// Adding a topic = one _DevTopic entry in _devTopics + a DevInfoBadge('<id>')
// next to the control. Each entry describes what ITS card does. Keep the
// snippets REAL: they are raw strings (no Dart interpolation) and were
// compiled against the SDKs — C# with `using GrpcLibrary; using
// GrpcLibrary.Dto;` in scope (a DTO whose generated protobuf twin has the same
// name, e.g. CheckResult, is written GrpcLibrary.Dto.X), Dart with
// `package:face_snap_grpc` imported.
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

/// The topic ids that have an entry (for tests: every DevInfoBadge on a page
/// must name one of these).
@visibleForTesting
Iterable<String> get devTopicIds => _devTopics.keys;

final Map<String, _DevTopic> _devTopics = {
  // ---- Kiosk page ---------------------------------------------------------
  'discovery': _DevTopic(
    title: 'Finding and connecting to kiosks',
    rpc: 'mDNS _facesnap._tcp + GetKioskInfo / LoadSettings',
    summary: 'The list merges four sources: a FaceSnap server on this PC '
        '(it announces nothing, so 127.0.0.1:<port> — 50051, or the port '
        'chosen in the setup — is probed directly and '
        'listed first); provisioned kiosk boards, found with a one-shot mDNS '
        'PTR query for _facesnap._tcp (the SRV record carries the gRPC port); '
        'clean, not yet provisioned boards, found by their stock host names '
        '(odroid / radxa over mDNS and LLMNR) and, on a deliberate search, by '
        'a subnet sweep that recognises the boards by MAC prefix; and the '
        'remembered server, listed even when a scan misses it. "Add an '
        'address…" connects to a host:port you type. The list re-scans every '
        '30 s (without the sweep) and pings each row with GetKioskInfo under a '
        '2 s deadline — it opens no camera and takes no capture gate. '
        'Connecting points the shared channel at the row (a provisioned kiosk '
        'by its facesnap-<mac>.local NAME, which survives DHCP moves; this PC '
        'and clean boards by IP) and proves it with LoadSettings under a 5 s '
        'deadline before the address is saved. Plain HTTP/2 (h2c), no TLS.',
    snippets: {
      'C# — facesnap-sdk': r'''
// Ping a candidate without moving the shared channel: a processor built
// with its own address talks to that kiosk only (until SetAddress).
var probe = new KioskProcessor("http://facesnap-001e0644278f.local:50051");
var info = await probe.GetKioskInfo().WaitAsync(TimeSpan.FromSeconds(2));
Console.WriteLine($"{info.kioskData.numberOfCameras} cameras");

// Connect: point the shared channel at the kiosk; every processor follows.
GrpcChannelProvider.SetAddress("http://facesnap-001e0644278f.local:50051");
var snapshot = await new SettingsProcessor().LoadSettings()
    .WaitAsync(TimeSpan.FromSeconds(5));          // proves the server answers''',
      'Dart — face_snap_grpc': r'''
// discoverKiosks() is this app's own code (operator_app/lib/services/
// discovery.dart, also in the demo repo), not part of face_snap_grpc.
final kiosks = await discoverKiosks();
for (final kiosk in kiosks) {
  // Ping on an independent channel; the shared one stays where it is.
  final channel =
      GrpcChannelProvider.openChannel(kiosk.hostName, kiosk.port ?? 50051);
  try {
    final info = await KioskClient(channel).getKioskInfo(Empty(),
        options: CallOptions(timeout: const Duration(seconds: 2)));
    print('${kiosk.hostName}: ${info.kioskInfo.numberOfCameras} cameras');
  } finally {
    await channel.shutdown();
  }
}

// Connect by the .local NAME on the announced port, then prove it.
final kiosk = kiosks.first;
await GrpcChannelProvider.setAddress(kiosk.hostName, kiosk.port ?? 50051);
await SettingsClient(GrpcChannelProvider.channel).loadSettings(Empty(),
    options: CallOptions(timeout: const Duration(seconds: 5)));''',
      'Protocol': r'''
this PC   : TCP connect 127.0.0.1:<port>  (a local server announces nothing;
            <port> = 50051, or the port chosen in the setup)
kiosks    : PTR _facesnap._tcp.local      (multicast 224.0.0.251:5353, one-shot)
            SRV facesnap-<mac>._facesnap._tcp.local -> port, target host
            A   facesnap-<mac>.local                -> 192.168.x.x
clean     : A odroid.local / radxa.local (mDNS), odroid / radxa (LLMNR 5355)
            + subnet sweep (port 22), boards recognised by MAC prefix
ping      : Kiosk.GetKioskInfo, 2 s deadline  (every row, every 30 s)
connect   : Settings.LoadSettings, 5 s deadline, then save host:port
transport : gRPC over plain HTTP/2 (h2c), no TLS - keep kiosks on a
            trusted network''',
    },
    docsUrl: '$_docsBase/docs/getting-started.html',
  ),
  'server-local': _DevTopic(
    title: 'Managing a server on this PC',
    rpc: 'ServerProcessManager (C#)',
    summary: 'This card controls the FaceSnap server installed on this Windows '
        'PC: whether it runs (is its gRPC port — 50051, or the port chosen in '
        'the setup — listening?), Start / Stop, and '
        '"start at logon" — a "FaceSnap Server.lnk" shortcut in the Windows '
        'Startup folder. Lifecycle is not an RPC. The C# SDK has '
        'ServerProcessManager(serverAddress, executablePath): IsRunningAsync() '
        'checks the port; EnsureRunningAsync(timeout) starts the exe when the '
        'port is closed and returns true once it answers (true at once for a '
        'running server; for a remote address it only reports whether the '
        'port is open; false when the exe is missing or did not come up in '
        'time); Stop() kills only a process this manager started; '
        'StopAnyAsync(timeout) stops whichever process owns the port (the '
        'logon autostart, a developer\'s server). Without the service, this '
        'card\'s Stop first sets the event `Global\\FaceSnapServerStop` and '
        'waits up to 10 s for the port to close (a developer\'s server run '
        'from source shuts down cleanly that way; a 1.1.24 server has no '
        'event); only a server still listening then is stopped like '
        'StopAnyAsync, with two extras: both backlights are switched off '
        'first (a killed server skips its own shutdown) and the port\'s owner '
        'is killed only when it is face_snap_server.exe. The autostart '
        'shortcut has no SDK helper. On a service install (1.1.25+) Start/Stop drive the '
        'Windows service `FaceSnapServer`; the service\'s pre-stop hook sets '
        'the event `Global\\FaceSnapServerStop` so the server shuts down '
        'cleanly before NSSM ends it.',
    snippets: {
      'C# — facesnap-sdk': r'''
using var manager = new ServerProcessManager(
    "http://localhost:50051",
    @"C:\Program Files\FaceSnapServer\face_snap_server.exe");

bool running = await manager.IsRunningAsync();           // port listening?
if (!await manager.EnsureRunningAsync(TimeSpan.FromSeconds(30)))
    Console.WriteLine("not started: exe missing or no answer within 30 s");

// ... use the processors against localhost:50051 ...

manager.Stop();                                          // only a server it started
await manager.StopAnyAsync(TimeSpan.FromSeconds(10));    // whoever owns the port''',
      'Dart (this app)': r'''
// face_snap_grpc has no lifecycle helper; this app runs PowerShell
// (operator_app/lib/services/server_manager.dart):
//   running   : Get-NetTCPConnection -LocalPort <port> -State Listen
//               (<port> = LocalServerConfig.port: 50051, or the port chosen
//               in the setup, "grpc_port" in
//               %ProgramData%\FaceSnap\server_config.json)
//   service   : Get-Service FaceSnapServer (exists on a 1.1.25+ install)
// Service install:
//   start     : Start-Service FaceSnapServer
//   stop      : Stop-Service FaceSnapServer (its pre-stop hook sets Global\FaceSnapServerStop and waits for the port to close)
// Without the service (1.1.24 and older, or a server run from source):
//   start     : Start-Process face_snap_server.exe -WindowStyle Minimized
//   stop      : both backlights off over gRPC, set Global\FaceSnapServerStop
//               and wait up to 10 s; if still listening, Stop-Process on the
//               port's owner - only when its path is face_snap_server.exe
//   autostart : "FaceSnap Server.lnk" in [Environment]::GetFolderPath("Startup")
final result = await Process.run('powershell', [
  '-NoProfile',
  '-Command',
  'if (Get-NetTCPConnection -LocalPort ${LocalServerConfig.port} -State Listen '
      '-ErrorAction SilentlyContinue) { "True" } else { "False" }',
]);
final running = (result.stdout as String).trim() == 'True';
print(running ? 'Server is running' : 'Server is not running');''',
    },
    docsUrl: '$_docsBase/api/GrpcLibrary.ServerProcessManager.html',
  ),
  'server-board': _DevTopic(
    title: 'Controlling a kiosk board\'s server',
    rpc: 'systemctl over SSH',
    summary: 'On an ARM kiosk board (Odroid / Radxa) the server is a Docker '
        'container run by the face-snap-docker-compose.service systemd unit. '
        'Its lifecycle is not an RPC (a stopped server cannot start itself), '
        'so this card works over SSH with the user and password from this '
        'app\'s config.json (board_user / board_password; without them the '
        'card says to set them first). The state is `systemctl is-active`; Start, '
        'Stop and Restart are `systemctl start|stop|restart` (start returns '
        'once docker compose up has). A stopped server disconnects every app '
        'until it is started again. "Change FaceSnap server password…" logs '
        'in with the current password (which proves it), sets the new one for '
        'board_user with chpasswd, and on success stores it as board_password '
        'in config.json.',
    snippets: {
      'Shell / SSH': r'''
# <user> / password = board_user / board_password from the app's config.json
ssh <user>@<board> systemctl is-active face-snap-docker-compose.service
ssh <user>@<board> systemctl start     face-snap-docker-compose.service
ssh <user>@<board> systemctl stop      face-snap-docker-compose.service
ssh <user>@<board> systemctl restart   face-snap-docker-compose.service

# Change the login password: "user:newpassword" into chpasswd. The app
# base64-encodes it so no character reaches the remote shell parser.
ssh <user>@<board> "echo '<base64 of user:newpassword>' | base64 -d | chpasswd"''',
      'Dart — dartssh2': r'''
// boardUser / boardPassword = board_user / board_password (config.json).
final client = SSHClient(
  await SSHSocket.connect(host, 22, timeout: const Duration(seconds: 15)),
  username: boardUser,
  onPasswordRequest: () => boardPassword,
);
try {
  final out = await client
      .run('systemctl is-active face-snap-docker-compose.service');
  final running = utf8.decode(out).trim() == 'active';
  if (!running) {
    await client.run('systemctl start face-snap-docker-compose.service');
  }
} finally {
  client.close();
}''',
    },
    docsUrl: '$_docsBase/docs/concepts.html',
  ),

  // ---- Capture page -------------------------------------------------------
  'capture': _DevTopic(
    title: 'Automatic & manual capture',
    rpc: 'Kiosk.StartAutomaticProcess / StartManualProcess',
    summary: 'Automatic: the server picks the best camera, runs the gates and '
        'the enabled checks and streams ONE photo. Manual: one full-frame photo '
        'per camera, top camera first — no selection, no checks, no crop, no '
        'background erasing. Both take the capture gate: a second caller (a '
        'capture, a calibration, GetKioskStatus) gets RESOURCE_EXHAUSTED '
        '"capture in progress" at once — nothing queues — and a running '
        'preview stops itself. The automatic stream: progress lines first ("Best '
        'Camera was determined", "Live person check: …", "Live person check (face angle): …", "Taking a high res '
        'photo using camera N"), then "Distance in cm" and the own-check rows, '
        'the photo, then the OFIQ / ICAO / advice rows, and the head-turn row '
        'last. After every check row it also carries a structured '
        'CheckResult (C#: a Dto.CheckResult item; Dart: a CaptureCheck event) — '
        'key on those, not on the texts. Only three refusals carry status '
        'ERROR (no cameras, not calibrated, no face; Server 2.0 also "Capture '
        'failed, Please try again"). A give-up ("Could not take the photo with '
        'camera N: …") is status OK and the stream simply ends WITHOUT a photo '
        '— check whether one arrived. Cancel by leaving the loop or cancelling '
        'the token (C#) / the subscription (Dart): the server stops, darkens '
        'the column and releases the camera. With the head turn on, the photo '
        'frame is taken first (the first valid frame, kept) and the head turn '
        'runs on the frames after it; its instructions come after "Taking a '
        'high res photo using camera N" and before anything of the photo, '
        'which is processed and sent only after the head turn ends (C#: a '
        'Dto.CaptureInstruction item; Dart: a CaptureInstruction event). A '
        'server with per-capture settings starts every stream with the '
        'settings the capture runs with (C#: a Dto.CaptureSettingsUsed item; '
        'Dart: a CaptureSettingsReport event) — see "Settings for one '
        'capture" for StartAutomaticCapture / StartManualCapture.',
    snippets: {
      'C# — facesnap-sdk': r'''
var kiosk = new KioskProcessor();
using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(60));
ImageData? photo = null;
try
{
    await foreach (var item in kiosk.StartAutomaticProcess(cts.Token))
    {
        switch (item)
        {
            case ProcessStatus s:             // the row text; may change
                Console.WriteLine($"{s.description} [{s.status}]");
                if (s.status == Status.ERROR) Console.WriteLine("refused");
                break;
            case GrpcLibrary.Dto.CheckResult c
                when c.Verdict == GrpcLibrary.Dto.CheckVerdict.Failed:
                Console.WriteLine($"{c.Kind} {c.Name} failed");   // stable name
                break;
            case GrpcLibrary.Dto.CaptureInstruction step:   // the head turn
                Console.WriteLine($"{step.Kind}: {step.Text}");
                break;
            case ImageData img:               // the photo, chunks assembled
                photo = img;
                break;
        }
    }
}
catch (Grpc.Core.RpcException e)
    when (e.StatusCode == Grpc.Core.StatusCode.ResourceExhausted)
{
    Console.WriteLine("another capture is running");   // no queue: retry later
}
if (photo is { } p) File.WriteAllBytes("photo.jpg", p.data);
else Console.WriteLine("no photo (refused or gave up)");

// Manual: one ImageData per camera, index = calibrated position (1 = bottom).
await foreach (var item in kiosk.StartManualProcess(cts.Token))
    if (item is ImageData img) File.WriteAllBytes($"camera{img.index}.jpg", img.data);''',
      'Dart — face_snap_grpc': r'''
CapturePhoto? photo;
try {
  await for (final event in startAutomaticCapture()) {  // or startManualCapture()
    switch (event) {
      case CaptureStatus(:final description, :final status):  // 'OK' / 'ERROR'
        print('$description [$status]');
      case CaptureCheck(:final result):        // after each check row (automatic)
        if (result.verdict == CheckVerdict.FAILED) print('${result.name} failed');
      case CaptureInstruction(:final kind, :final text):  // the head turn (automatic)
        print('${kind.name}: $text');
      case CapturePhoto():                     // automatic: the one photo
        photo = event;
      case CameraPhoto(:final cameraIndex, :final bytes):  // manual: per camera
        File('camera$cameraIndex.jpg').writeAsBytesSync(bytes);
      case CaptureSettingsReport(:final values, :final overridden):  // always first
        print('format ${values.photoFormat}, ICAO report ${values.icaoReport}'
            '${overridden.isEmpty ? '' : '; only this capture: ${overridden.join(', ')}'}');
    }
    if (stopPressed) break;  // leaving the loop cancels the call on the server
  }
} on GrpcError catch (e) {
  print('${e.code}: ${e.message}');  // RESOURCE_EXHAUSTED = capture in progress
}
if (photo == null) print('no photo (refused or gave up)');''',
    },
    docsUrl: '$_docsBase/docs/automatic-capture.html',
  ),
  'capture-photos': _DevTopic(
    title: 'The delivered photos',
    rpc: 'ImageData · GetHighResolutionImage…FromCameraIndex',
    summary: 'This card shows the photos the capture stream delivered — the '
        'automatic capture\'s one photo or the manual capture\'s one per camera '
        '— with their pixel size; click one to zoom, "Save as…" to keep it. It '
        'requests nothing itself: the bytes are the capture\'s ImageData (C#) '
        'or CapturePhoto / CameraPhoto (Dart), a JPEG with the chunks already '
        'assembled. To get one photo from a camera YOU choose there are two '
        'single-camera RPCs. GetHighResolutionImageWithIcaoChecksFromCamera'
        'Index(index, timeoutInMs, eyesCheck, lipsCheck) only accepts a frame '
        'with a face at a valid distance and — per the REQUEST\'s eyesCheck / '
        'lipsCheck, not the settings — open eyes and a closed mouth; it is '
        'always cropped and now returns the photo\'s check results '
        '(ImageData.Checks in C#, HighResImageResponse.checks on the first '
        'item in Dart: distance, eyes / lips, the kiosk checks, OFIQ / ICAO per '
        'the settings; no liveness). GetHighResolutionImageFromCameraIndex(index, '
        'timeoutInMs) takes the first usable frame and is never cropped. Both '
        'erase the background, send NO LED command (light the column '
        'yourself), keep the backlights on for the whole call and take the '
        'capture gate (RESOURCE_EXHAUSTED during a capture); timeoutInMs <= 0 '
        'means 30 000 ms. A failure is ONE empty item with statusType ERROR or '
        'TIMEOUT (no frame passed in time): the C# SDK throws "Error '
        'statusType is: Timeout", in Dart check statusType yourself.',
    snippets: {
      'C# — facesnap-sdk': r'''
var kiosk = new KioskProcessor();
try
{
    // Gated and cropped; eyes/lips per THIS request, not the settings.
    ImageData photo = await kiosk.GetHighResolutionImageWithIcaoChecksFromCameraIndex(
        3, 15000, eyesCheck: true, lipsCheck: true);
    File.WriteAllBytes("camera3.jpg", photo.data);   // photo.width x photo.height
    foreach (GrpcLibrary.Dto.CheckResult c in photo.Checks)     // distance, eyes, lips, ...
        Console.WriteLine($"{c.Name}: {c.Verdict} {c.Value}{c.Unit}");

    // Plain: the first usable frame, never cropped; Checks stays empty.
    ImageData raw = await kiosk.GetHighResolutionImageFromCameraIndex(3, 15000);
}
catch (Grpc.Core.RpcException e)
    when (e.StatusCode == Grpc.Core.StatusCode.ResourceExhausted)
{
    Console.WriteLine("a capture is running");
}
catch (Exception e)
{
    Console.WriteLine(e.Message);   // "Error statusType is: Timeout" / "...: Error"
}''',
      'Dart — face_snap_grpc': r'''
final kiosk = KioskClient(GrpcChannelProvider.channel);
final jpeg = BytesBuilder(copy: false);
final checks = <CheckResult>[];
var status = StatusType.OK;
await for (final message in kiosk.getHighResolutionImageWithIcaoChecksFromCameraIndex(
    HighResIcaoImageRequest(
        index: 3, timeoutInMs: 15000, eyesCheck: true, lipsCheck: true))) {
  checks.addAll(message.checks);       // first item only
  status = message.statusType;
  if (status != StatusType.OK) break;  // ERROR / TIMEOUT: one empty item
  jpeg.add(message.processImageData.chunkData);
}
if (status == StatusType.OK && jpeg.length > 0) {
  File('camera3.jpg').writeAsBytesSync(jpeg.takeBytes());
}
for (final c in checks) {
  print('${c.name}: ${c.verdict.name}');
}''',
    },
    docsUrl: '$_docsBase/docs/blocks/photo-from-camera.html',
  ),
  'capture-results': _DevTopic(
    title: 'The capture results',
    rpc: 'ProcessStatus + CheckResult',
    summary: 'The rows on this card are the capture stream as it arrives. Each '
        'is a ProcessStatus {index, description, status}. status is OK on every '
        'progress, check and give-up row — a check\'s verdict is IN THE TEXT '
        '("Glasses detected: False (certainty 3%)"); there is no "NOK". Only '
        'the refusals carry ERROR: "No cameras detected - check the camera '
        'connections", "Cameras are not calibrated - run the calibration page '
        'first", "Determine best camera failed, please retry" (Server 2.0 also '
        '"Capture failed, Please try again"). In the automatic flow index is '
        'the selected camera\'s NATIVE (OS) index (0 on the refusals); the '
        'calibrated position is only in the "using camera N" text. Before the '
        'photo: the progress rows, the live person depth and face-angle checks, "Distance in '
        'cm" and the own-check rows (head size last; red eyes on a face with '
        'a colour cast add an "Advice: …" row right after the red-eye row). '
        'After the photo: the '
        'OFIQ rows, "ICAO compliance: …" with one row per requirement, the '
        '"Advice: …" rows, and the head-turn row last. A '
        'give-up ("Could not take the photo with camera N: the eyes were '
        'closed in K of T frames…") ends the stream with no photo. NEW: right '
        'after each check row the automatic stream carries a CheckResult — '
        'kind GATE / KIOSK_CHECK / LIVENESS / OFIQ / ICAO, a stable name '
        '("distance", "eyes", "head_pose", "liveness_face_angle", '
        '"ofiq.Sharpness", "icao.compliance", …), verdict PASSED / FAILED / '
        'NOT_CHECKED, gates_photo, value / min / max / unit and the row\'s text. '
        'Program against those and only show the texts; progress, advice and '
        'give-up rows have none. Liveness results exist only in the automatic '
        'capture. A server with per-capture settings sends the settings used '
        'first (C#: Dto.CaptureSettingsUsed; Dart: CaptureSettingsReport): the '
        'checks this capture really runs, to seed the checklist from.',
    snippets: {
      'C# — facesnap-sdk': r'''
await foreach (var item in new KioskProcessor().StartAutomaticProcess())
{
    switch (item)
    {
        case ProcessStatus s:
            // Show it. status is OK on every row except the three refusals.
            AddRow(s.description, refused: s.status == Status.ERROR);
            break;
        case GrpcLibrary.Dto.CheckResult c:
            // c.Kind: Gate / KioskCheck / Liveness / Ofiq / Icao; c.Name is stable.
            bool failed = c.Verdict == GrpcLibrary.Dto.CheckVerdict.Failed;
            if (c.Name == "icao.compliance" && failed)
                Console.WriteLine("ICAO: attention");
            if (c.Kind == GrpcLibrary.Dto.CheckKind.Liveness && failed)
                Console.WriteLine($"{c.Name}: not live?");
            if (c.Value is double v)
                Console.WriteLine($"{c.Name} = {v}{c.Unit} (min {c.Min}, max {c.Max})");
            break;
        case ImageData img:
            break;   // own-check rows came before it; OFIQ/ICAO/advice/head-turn rows follow
    }
}''',
      'Dart — face_snap_grpc': r'''
await for (final event in startAutomaticCapture()) {
  switch (event) {
    case CaptureStatus(:final description, :final status):
      addRow(description, refused: status == 'ERROR');  // all other rows: 'OK'
    case CaptureCheck(:final result):
      // result.kind: GATE / KIOSK_CHECK / LIVENESS / OFIQ / ICAO; name is stable.
      final failed = result.verdict == CheckVerdict.FAILED;
      if (result.name == 'icao.compliance' && failed) print('ICAO: attention');
      if (result.kind == CheckKind.LIVENESS && failed) print('${result.name}: not live?');
      if (result.hasValue()) {
        print('${result.name} = ${result.value}${result.unit}'
            '${result.hasMin() ? ' (min ${result.min})' : ''}');
      }
    case CaptureSettingsReport(:final values):
      // First: the checks THIS capture runs (an override can switch them), so
      // the checklist can be seeded before the first row arrives.
      seedChecklist(icao: values.icaoReport, ofiq: values.ofiqChecks,
          eyes: values.eyesCheck, lips: values.lipsCheck);
    case CaptureInstruction():
    case CapturePhoto():
    case CameraPhoto():
      break;
  }
}''',
      'Stream (example)': r'''
row (status OK unless noted)                         structured result after it
Best Camera was determined                           -
Live person check: passed (3D face confirmed ...)    LIVENESS liveness_depth
Live person check (face angle): passed               LIVENESS liveness_face_angle
Taking a high res photo using camera 3               -   (3 = calibrated position)
  (head turn on: the photo frame is taken first, then the head turn on the next frames)
Turn your head to the left                           -   + Instruction TURN_LEFT (progress items follow)
Turn your head to the right                          -   + Instruction TURN_RIGHT
Look straight ahead                                  -   + Instruction LOOK_STRAIGHT
  (no row)                                           -     Instruction DONE: the photo is processed now
Distance in cm: 52                                   GATE distance  52 cm, min/max
Lips are closed (certainty 97%)                      GATE lips
Both eyes are opened (certainty 99%)                 GATE eyes
Glasses detected: False (certainty 4%)               KIOSK_CHECK glasses
Head size/position OK: True (head 71%, ...)          KIOSK_CHECK head_size
<the photo>
OFIQ overall quality: 71/100 - passed (min 40)       OFIQ ofiq.UnifiedQualityScore
ICAO compliance: attention (1 of 19 ...: Glasses)    ICAO icao.compliance  FAILED
ICAO Glasses: attention (...)                        ICAO icao.<requirement>
Advice: ...                                          -
Live person check (head turn): passed                LIVENESS liveness_head_turn

refusal (status ERROR, only item): No cameras detected - check the camera connections
give-up (status OK, no photo):     Could not take the photo with camera 3: ...''',
    },
    docsUrl: '$_docsBase/docs/reference/status-texts.html',
  ),
  'capture-instruction': _DevTopic(
    title: 'The head turn',
    rpc: 'ProcessAutomaticResponse.instruction',
    summary: 'With the live person check\'s head turn on (SetLivenessChecks '
        'headTurnCheck, under the master switch) the automatic stream carries '
        'Instruction items between the photo frame and the photo: the photo '
        'frame is taken first (the first valid frame, kept), the head turn runs '
        'on the frames after it, and the photo is processed and sent once it '
        'ends - nothing of the photo arrives before DONE. Kind '
        'TURN_LEFT / TURN_RIGHT / LOOK_STRAIGHT / DONE, progress 0..1 towards '
        'the 20 degree turn, repeat (the second ask), seconds_left (the time '
        'left of the ask when the item was SENT) and the English text. One per '
        'new instruction, in between when the progress moved 5 points (at most '
        '~10 per second) - a person who does not move gets no new item, so '
        'seconds_left is a snapshot: count it down locally from the item\'s '
        'arrival and restart from the next item\'s value. Every new '
        'instruction is ALSO a status row with the same text, so a client '
        'that skips the item still shows it. Left is the person\'s own left: '
        'on the kiosk screen the person faces, the screen\'s left. DONE ends '
        'it; after the photo the row "Live person check (head turn): passed", '
        '"failed - no head turn to the left / right / left and right" or '
        '"skipped (face not measurable)" with the CheckResult '
        'liveness_head_turn. Informational: it never blocks the photo.',
    snippets: {
      'C# — facesnap-sdk': r'''
var kiosk = new KioskProcessor();
await foreach (var item in kiosk.StartAutomaticProcess())
{
    if (item is GrpcLibrary.Dto.CaptureInstruction step)
    {
        // Kind: TurnLeft / TurnRight / LookStraight / Done (the person's own left)
        if (step.Kind == GrpcLibrary.Dto.CaptureInstructionKind.Done) { HideArrow(); continue; }
        // SecondsLeft is a snapshot at send time and items come only on a change:
        // count down locally to this deadline (a UI timer); the next item restarts it.
        DateTime deadline = DateTime.UtcNow.AddSeconds(step.SecondsLeft);
        ShowArrow(step.Kind, step.Progress, step.Repeat, deadline, step.Text);
    }
}''',
      'Dart — face_snap_grpc': r'''
await for (final event in startAutomaticCapture()) {
  if (event is CaptureInstruction) {
    // kind: TURN_LEFT / TURN_RIGHT / LOOK_STRAIGHT / DONE (the person's own left)
    if (event.kind == InstructionKind.DONE) {
      hideArrow();
    } else {
      // secondsLeft is a snapshot at send time and items come only on a change:
      // count down locally to this deadline (a UI timer); the next item restarts it.
      final deadline = DateTime.now()
          .add(Duration(milliseconds: (event.secondsLeft * 1000).round()));
      showArrow(event.kind, event.progress, event.repeat, deadline, event.text);
    }
  }
}''',
    },
    docsUrl: '$_docsBase/docs/automatic-capture.html',
  ),

  'capture-overrides': _DevTopic(
    title: 'Settings for one capture',
    rpc: 'Kiosk.StartAutomaticCapture / StartManualCapture (CaptureRequest)',
    summary: 'The "Only for this capture" panel sends its values WITH the '
        'capture command; they apply to that capture only and nothing is '
        'saved: no Set… call, no settings file, no column profile change, also '
        'after an error or a cancel. A field you leave unset keeps the kiosk\'s '
        'value. CaptureSettings has 28 optional fields, most named after the kiosk '
        'settings: photo_format, crop, crop_width, jpeg_quality, '
        'background_method / _color / _strength, glare_free_light (off / '
        'glasses / everyone), photo_light (all / neighbours), '
        'leds_off_for_photo, the ten check switches, ofiq_checks, '
        'icao_report, liveness_check, liveness_head_turn_check, distance_min, '
        'distance_max, colour_correction (the photo colour matrices) and lap '
        '(a child on a parent\'s lap: LAP_CHILD photographs the lower face, '
        'LAP_BABY also turns the eyes / lips / distance / expression gates into '
        'advice and the head turn off; automatic capture only). A '
        'manual capture uses only jpeg_quality, glare_free_light, photo_light, '
        'leds_off_for_photo and colour_correction and refuses any other. Refusals come before any light or camera is touched: a value '
        'outside its rule, an unknown field or a field a manual capture does '
        'not use is INVALID_ARGUMENT with the server\'s text ("per-capture '
        'setting jpeg_quality: jpeg quality should be between 50 and 100"); a '
        'server from before per-capture settings answers UNIMPLEMENTED (C#: '
        'NotSupportedException; Dart: PerCaptureSettingsNotSupported). Every '
        'stream starts with the settings used: the values in force (28 fields '
        'automatic, 5 manual) and the names that came from the request — the '
        '"Settings used" card, overrides marked ◆. Without settings, call '
        'StartAutomaticProcess / StartManualProcess (Dart: no settings '
        'argument) as before.',
    snippets: {
      'C# — facesnap-sdk': r'''
var kiosk = new KioskProcessor();
// Only for this capture; the kiosk's own settings stay as they are.
var settings = new CaptureSettings { PhotoFormat = "us_2x2", BackgroundStrength = 2, IcaoReport = true };
try
{
    await foreach (var item in kiosk.StartAutomaticCapture(settings))
    {
        switch (item)
        {
            case GrpcLibrary.Dto.CaptureSettingsUsed used:   // always the first item
                Console.WriteLine($"format {used.Values.PhotoFormat}; " +
                    $"only this capture: {string.Join(", ", used.Overridden)}");
                break;
            case ProcessStatus s:
                Console.WriteLine(s.description);
                break;
            case ImageData img:
                File.WriteAllBytes("passport.jpg", img.data);
                break;
        }
    }
    // Manual: only JpegQuality, GlareFreeLight, PhotoLight, LedsOffForPhoto and ColourCorrection.
    var glareFree = new CaptureSettings { GlareFreeLight = "everyone" };
    await foreach (var item in kiosk.StartManualCapture(glareFree))
        if (item is ImageData photo) File.WriteAllBytes($"camera{photo.index}.jpg", photo.data);
}
catch (NotSupportedException e)
{
    Console.WriteLine(e.Message);         // the server predates per-capture settings
}
catch (Grpc.Core.RpcException e) when (e.StatusCode == Grpc.Core.StatusCode.InvalidArgument)
{
    Console.WriteLine(e.Status.Detail);   // "per-capture setting jpeg_quality: ..."
}''',
      'Dart — face_snap_grpc': r'''
// Only for this capture; the kiosk's own settings stay as they are.
final settings =
    CaptureSettings(photoFormat: 'us_2x2', backgroundStrength: 2, icaoReport: true);
try {
  await for (final event in startAutomaticCapture(settings: settings)) {
    switch (event) {
      case CaptureSettingsReport(:final values, :final overridden):  // always first
        print('format ${values.photoFormat}; only this capture: ${overridden.join(', ')}');
      case CaptureStatus(:final description):
        print(description);
      case CapturePhoto(:final bytes):
        File('passport.jpg').writeAsBytesSync(bytes);
      case CaptureCheck():
      case CaptureInstruction():
      case CameraPhoto():
        break;
    }
  }
  // A child on a parent's lap: the lower face is the subject (LAP_BABY: relaxed checks).
  final child = CaptureSettings(lap: LapSubject.LAP_CHILD);
  await for (final event in startAutomaticCapture(settings: child)) {
    if (event is CapturePhoto) File('child.jpg').writeAsBytesSync(event.bytes);
  }
  // Manual: only jpegQuality, glareFreeLight, photoLight, ledsOffForPhoto and colourCorrection.
  final glareFree = CaptureSettings(glareFreeLight: 'everyone');
  await for (final event in startManualCapture(settings: glareFree)) {
    if (event is CameraPhoto) {
      File('camera${event.cameraIndex}.jpg').writeAsBytesSync(event.bytes);
    }
  }
} on PerCaptureSettingsNotSupported catch (e) {
  print(e);          // the server predates per-capture settings
} on GrpcError catch (e) {
  print(e.message);  // INVALID_ARGUMENT: "per-capture setting jpeg_quality: ..."
}''',
      'Protocol': r'''
rpc StartAutomaticCapture(CaptureRequest) returns (stream ProcessAutomaticResponse)
rpc StartManualCapture(CaptureRequest)    returns (stream ProcessManualResponse)
CaptureRequest { CaptureSettings settings = 1 }   every field optional; unset = kiosk
  1 photo_format  2 crop  3 crop_width  4 jpeg_quality*  5 background_method
  6 background_color  7 background_strength  8 glare_free_light*  9 photo_light*
  10 leds_off_for_photo*  11-20 the check switches  21 ofiq_checks  22 icao_report
  23 liveness_check  24 liveness_head_turn_check  25 distance_min  26 distance_max
  27 colour_correction*  28 lap (LapSubject: LAP_NONE / LAP_CHILD / LAP_BABY)
  (* = used by a manual capture; any other field there is INVALID_ARGUMENT)
first item: settings_used { values (28 automatic / 5 manual), overridden [names] }
refusals  : INVALID_ARGUMENT (rule, unknown field, manual field), UNIMPLEMENTED
            (older server), RESOURCE_EXHAUSTED (capture in progress)''',
    },
    docsUrl: '$_docsBase/docs/per-capture-settings.html',
  ),

  // ---- Photo page ---------------------------------------------------------
  'photo-adjustment': _DevTopic(
    title: 'Photo format & processing',
    rpc: 'SetCrop / SetPhotoFormat / SetCropResolution / SetBackground… / '
        'SetJpegQuality',
    summary: 'Each control is an immediate unary setter, stored on the server '
        'and applied to the next photo. Crop photo (SetCrop, default on): crop '
        'to the face per the format; off = the whole frame at the camera '
        'resolution. Photo format (SetPhotoFormat): icao_35x45 (7:9, default), '
        'us_2x2 (1:1), ca_50x70 (5:7) or iso_enrolment (3:4) — the aspect AND '
        'the face framing; an unknown key falls back to the default; the reply '
        'carries the key and the crop_height the server derived from the '
        'stored crop width. Crop width (SetCropResolution): this field takes '
        '100–3000 px and sends the height that follows from the format. '
        'Background erasing (SetBackgroundMethod): none (default since 1.1.27) / '
        'mediapipe / modnet / withoutbg / gridler (the Gridler eraser); "rembg" is '
        'accepted and stored as "withoutbg" '
        '(the reply is what was set); anything else is INVALID_ARGUMENT. Colour '
        '(SetBackgroundColor): surrounding spaces and a leading # are dropped, '
        'lower case is accepted, it is stored upper-cased; anything else is '
        'INVALID_ARGUMENT "background colour must be RRGGBB hex" and the stored '
        'colour stays. Erasing strength (SetBackgroundStrength): 1 mild – 5 '
        'heavy, 3 = standard (an older server reports 0, which means 3). JPEG '
        'quality (SetJpegQuality): 50–100, default 95. Strength or quality out '
        'of range: INVALID_ARGUMENT.',
    snippets: {
      'C# — facesnap-sdk': r'''
var settings = new SettingsProcessor();
await settings.SetCrop(true);
await settings.SetCropResolution(700, 900);          // width 100-3000 on this card
PhotoFormat format = await settings.SetPhotoFormat("icao_35x45");
// format.cropHeight = the height the server derived from the stored width
BackgroundMethod method = await settings.SetBackgroundMethod("withoutbg");
BackgroundColor color = await settings.SetBackgroundColor("#f0f0f0");  // stored "F0F0F0"
await settings.SetBackgroundStrength(3);             // 1 mild - 5 heavy
await settings.SetJpegQuality(95);                   // 50-100
// A refused value: RpcException INVALID_ARGUMENT, the stored value is kept.''',
      'Dart — face_snap_grpc': r'''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setCrop(CropRequest(value: true));
await c.setCropResolution(CropResolutionRequest(width: 700, height: 900));
final format = await c.setPhotoFormat(PhotoFormatRequest(value: 'icao_35x45'));
print(format.cropHeight);                            // derived by the server
final method =
    await c.setBackgroundMethod(BackgroundMethodRequest(method: 'withoutbg'));
print(method.method);                                // what was set
await c.setBackgroundColor(BackgroundColorRequest(color: 'F0F0F0'));
await c.setBackgroundStrength(BackgroundStrengthRequest(value: 3)); // 1-5
await c.setJpegQuality(JpegQualityRequest(value: 95));              // 50-100''',
    },
    docsUrl: '$_docsBase/docs/commissioning/photo-output.html',
  ),
  'quality-checks': _DevTopic(
    title: 'Checks policy: gates, checks and reports',
    rpc: 'Set…Check / SetLivenessChecks / SetOfiqChecks / SetIcaoReport',
    summary: 'One unary setter per control, stored on the server and used by '
        'the next automatic capture. GATES — a frame that fails is rejected '
        'and the next one tried; after 30 rejected frames the capture gives up: '
        'Eyes (SetEyesCheck) and Lips (SetLipsCheck), both on by default; the '
        'third gate is the distance window (Camera page). INFORMATIONAL — one '
        'row each, never block the photo, off by default: Glasses '
        '(SetEyeGlassesCheck), Head pose (SetHeadPoseCheck), Sharpness '
        '(SetSharpnessCheck), Red eye (SetRedEyeDetectionCheck), Head '
        'size/position (SetHeadSizeCheck, on the cropped photo), Expression '
        '(SetExpressionCheck), Gaze (SetGazeCheck), Lighting evenness '
        '(SetLightingEvennessCheck). REPORTS — OFIQ (SetOfiqChecks) scores the '
        'delivered photo per ISO/IEC 29794-5 and replaces the informational '
        'rows (eyes and lips still gate); its rows follow the photo, and '
        'without the OFIQ binaries the row says "OFIQ scoring unavailable". '
        'ICAO report (SetIcaoReport) wins over OFIQ: after the photo, "ICAO '
        'compliance: passed / attention / incomplete" and one verdict per ICAO '
        'portrait requirement, from OFIQ plus the kiosk\'s own checks, which '
        'then run whatever their switches say; it needs OFIQ installed, and an '
        'older server answers UNIMPLEMENTED. LIVE PERSON CHECK — the master '
        '(default off since 1.1.27: the depth and face-angle checks over the '
        'camera scan) and '
        'the head turn under it are ONE call, SetLivenessChecks(livenessCheck) '
        'or SetLivenessChecks(livenessCheck, headTurnCheck). '
        'The head turn (default off) asks the person to turn the head to the '
        'left and to the right, just after the photo frame is taken and before '
        'the photo is sent, on the kiosk screen and the LED column. '
        'Every check that ran also yields a CheckResult in the capture stream.',
    snippets: {
      'C# — facesnap-sdk': r'''
var settings = new SettingsProcessor();
// Gates (the third is the distance window, Camera page)
await settings.SetEyesCheck(true);
await settings.SetLipsCheck(true);
// Informational: one row + one CheckResult each, never block the photo
await settings.SetEyeGlassesCheck(true);
await settings.SetHeadPoseCheck(true);
await settings.SetSharpnessCheck(true);
await settings.SetRedEyeDetectionCheck(false);
await settings.SetHeadSizeCheck(true);
await settings.SetExpressionCheck(false);
await settings.SetGazeCheck(false);
await settings.SetLightingEvennessCheck(false);
// Reports (ICAO wins over OFIQ; both need OFIQ on the server)
await settings.SetOfiqChecks(false);
await settings.SetIcaoReport(true);
// Live person check: the master switch and the head turn under it, in ONE call
LivenessChecks live = await settings.SetLivenessChecks(livenessCheck: true, headTurnCheck: true);''',
      'Dart — face_snap_grpc': r'''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setEyesCheck(EyesCheckRequest(value: true));              // gate
await c.setLipsCheck(LipsCheckRequest(value: true));              // gate
await c.setEyeGlassesCheck(EyeGlassesCheckRequest(value: true));
await c.setHeadPoseCheck(HeadPoseCheckRequest(value: true));
await c.setSharpnessCheck(SharpnessCheckRequest(value: true));
await c.setRedEyeDetectionCheck(RedEyeDetectionCheckRequest(value: false));
await c.setHeadSizeCheck(HeadSizeCheckRequest(value: true));
await c.setExpressionCheck(ExpressionCheckRequest(value: false));
await c.setGazeCheck(GazeCheckRequest(value: false));
await c.setLightingEvennessCheck(LightingEvennessCheckRequest(value: false));
await c.setOfiqChecks(OfiqChecksRequest(value: false));
await c.setIcaoReport(IcaoReportRequest(value: true));
await c.setLivenessChecks(LivenessChecksRequest(livenessCheck: true, headTurnCheck: true));''',
    },
    docsUrl: '$_docsBase/docs/commissioning/checks-policy.html',
  ),

  'capture-warm-up': _DevTopic(
    title: 'Loading models at server start',
    rpc: 'Settings.SetCaptureWarmUp / LoadSettings.capture_warm_up',
    summary: 'A capture that needs a model the server has not loaded yet '
        'loads it first and says so in a status row: "Loading the background '
        'method withoutbg (first use, a few seconds)" or "Loading OFIQ (first '
        'use, about 8 s)". That happens when a per-capture setting (or a '
        'changed kiosk setting) asks for a background method or the OFIQ / '
        'ICAO report the kiosk does not normally use. The kiosk setting '
        'capture_warm_up lists the models the server loads in the background '
        'at its start: names from modnet, withoutbg, gridler (the Gridler eraser, '
        'from release 1.1.27 on) and ofiq, empty by default (the card\'s "None"). '
        'SetCaptureWarmUp replaces the whole list, loads a newly listed model '
        'at once and answers with the stored list (in that order, without '
        'duplicates); an unknown name refuses the whole list with '
        'INVALID_ARGUMENT and nothing is stored. LoadSettings returns the list '
        'in capture_warm_up. A listed model stays in memory from the start, '
        'used or not — mind the memory on an Odroid. On Server 2.0 ofiq adds '
        'nothing (OFIQ starts at every start there). An older server answers '
        'UNIMPLEMENTED. It is a server setting, not a column setting.',
    snippets: {
      'C# — facesnap-sdk': r'''
var settings = new SettingsProcessor();
// Names from "modnet", "withoutbg", "gridler", "ofiq"; an unknown name refuses the whole list.
CaptureWarmUp stored = await settings.SetCaptureWarmUp(new[] { "withoutbg", "ofiq" });
Console.WriteLine(string.Join(", ", stored.captureWarmUp));   // the stored list
IReadOnlyList<string> atStart = (await settings.LoadSettings()).captureWarmUp;
await settings.SetCaptureWarmUp(Array.Empty<string>());      // the default: nothing extra''',
      'Dart — face_snap_grpc': r'''
final c = SettingsClient(GrpcChannelProvider.channel);
// Names from 'modnet', 'withoutbg', 'gridler', 'ofiq'; an unknown name refuses the whole list.
final stored =
    await c.setCaptureWarmUp(CaptureWarmUpRequest(items: ['withoutbg', 'ofiq']));
print(stored.items);                                   // the stored list
final atStart = (await c.loadSettings(Empty())).captureWarmUp;
print(atStart);
await c.setCaptureWarmUp(CaptureWarmUpRequest());      // the default: nothing extra''',
    },
    docsUrl: '$_docsBase/docs/per-capture-settings.html',
  ),

  // ---- Lighting page ------------------------------------------------------
  'kiosk-lighting': _DevTopic(
    title: 'Lighting settings',
    rpc: 'SetLighting / SetIntensity… / SetFocusLight / SetLedLayout / '
        'SetBoardGbl / SetPhotoLight / …',
    summary: 'Stored settings the automatic capture lights the column with; '
        'one setter per control. Lighting (SetLighting) is the master switch: '
        'off, every photo-light pattern of a capture stays dark. Intensity '
        'Red / Green / Blue (SetIntensityRed/Green/Blue): the photo light\'s '
        'colour mix, 0–255 per channel (default 160 / 230 / 200 for strips, '
        '200 / 200 / 200 for rings; SetLedLayout switches an untouched mix to '
        'the new layout\'s default and leaves one you changed alone — reload '
        'the page to see it). Focus light colour and '
        'intensity (SetFocusLight("RRGGBB", 0–100)): the ring or strip section '
        'that marks the person\'s camera; it reaches the board at once, so '
        'while you pick this card lights the top camera (highest position from '
        'GetCalibration) with SetLightAtCameraIndex and switches it off again '
        'with SetLightOffAtCameraIndex; a bad colour or intensity is '
        'INVALID_ARGUMENT. LED hardware (SetLedLayout "strip" / "ring") decides '
        'which MicroPython files the server writes to the Plasma board; the '
        'board reboots (~10 s); an unknown layout is ignored (the reply carries '
        'the layout in force). The LED geometry gbl.py (GetBoardGbl / '
        'SetBoardGbl) is edited on the Column page; SetBoardGbl validates it — '
        '"rejected: …" in message and nothing stored, or stored and written to '
        'the board, which reboots; empty content puts the shipped file back. '
        'Photo light (SetPhotoLight): '
        '"all", or the "neighbours" (the camera\'s ring and one each side; the '
        'camera scan then runs at half intensity); an unknown value is ignored. '
        'Glare-free light (SetGlareFreeLight: GlareFreeLight.Off / Glasses / '
        'Everyone): the normal light; for glasses, when the first valid frame '
        'shows glasses, the photo is lit from above the next camera up and by the '
        'backlights; for everyone, that light for every photo (a face that stays '
        'too dark gets the normal light). Its camera white balance in Kelvin: '
        'SetGlareFreeWhiteBalance (0 = the camera\'s own value). The old '
        'SetGlassesLightsOff(bool) sets Glasses or Off. In every light but '
        'lights-off the chosen camera\'s ring fades out for the photo and back in '
        'after it. Lights off for the '
        'photo (SetLedsOffForPhoto): the ring shows 1 s, then every LED goes '
        'dark and the backlights light the photo. Photo colour correction '
        '(SetColourCorrectionEnabled(bool)): the kiosk-wide switch for the colour '
        'matrices of the Calibration page\'s Photo colour card; off, no photo is '
        'corrected (a server without it answers UNIMPLEMENTED and sends no '
        'colour_corrections in LoadSettings). In every mode, from the photo '
        'taken until it is delivered (cropping, background, reports), the column '
        'shows the comet of the camera scan at the same brightness (rings and '
        'strips: a slow comet whose tail fades to blue), then goes dark; '
        'dark throughout with Lighting off.',
    snippets: {
      'C# — facesnap-sdk': r'''
var settings = new SettingsProcessor();
await settings.SetLighting(true);                          // master switch
await settings.SetIntensityRed(200);                       // 0-255 per channel
await settings.SetIntensityGreen(200);
await settings.SetIntensityBlue(200);
FocusLight focus = await settings.SetFocusLight("00FF00", 78);  // RRGGBB, 0-100 %

LedLayout layout = await settings.SetLedLayout("strip");  // or "ring"; board reboots
BoardGbl current = await settings.GetBoardGbl("strip");    // .content, .custom
BoardGbl stored = await settings.SetBoardGbl("strip", File.ReadAllText("gbl.py"));
if (stored.message.StartsWith("rejected")) Console.WriteLine(stored.message);
await settings.SetBoardGbl("strip", "");                   // back to the shipped file

await settings.SetPhotoLight("neighbours");                // or "all"
await settings.SetGlareFreeLight(GlareFreeLight.Everyone);   // Off / Glasses / Everyone
await settings.SetGlareFreeWhiteBalance(5300);              // Kelvin; 0 = the camera's own
await settings.SetLedsOffForPhoto(false);
await settings.SetColourCorrectionEnabled(true);          // the photo colour matrices

// Live focus-colour preview, as this card does: light the top camera.
var lights = new LightProcessor();
int top = (await new CalibrationProcessor().GetCalibration())
    .Select(c => c.calibratedCameraIndex).DefaultIfEmpty(6).Max();
await lights.SetLightAtCameraIndex(top);
await settings.SetFocusLight("FF8800", 78);                // follows live
await lights.SetLightOffAtCameraIndex(top);''',
      'Dart — face_snap_grpc': r'''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setLighting(LightingRequest(value: true));
await c.setIntensityRed(IntensityRequest(value: 200));      // 0-255
await c.setFocusLight(FocusLightRequest(color: '00FF00', intensity: 78));
await c.setLedLayout(LedLayoutRequest(value: 'strip'));     // board reboots ~10 s

final gbl = await c.getBoardGbl(BoardGblLayoutRequest(layout: 'strip'));
final stored = await c.setBoardGbl(
    BoardGblRequest(layout: 'strip', content: gbl.content));
if (stored.message.startsWith('rejected')) print(stored.message);
await c.setBoardGbl(BoardGblRequest(layout: 'strip', content: ''));  // default

await c.setPhotoLight(PhotoLightRequest(value: 'neighbours'));
await c.setGlareFreeLight(
    GlareFreeLightRequest(value: GlareFreeLight.GLARE_FREE_LIGHT_EVERYONE));
await c.setGlareFreeWhiteBalance(GlareFreeWhiteBalanceRequest(value: 5300));
await c.setLedsOffForPhoto(LedsOffForPhotoRequest(value: false));
await c.setColourCorrectionEnabled(
    ColourCorrectionEnabledRequest(value: true));          // the photo colour matrices''',
    },
    docsUrl: '$_docsBase/docs/commissioning/led-column.html',
  ),
  'lights': _DevTopic(
    title: 'Driving the LEDs directly',
    rpc: 'Lights.SetAllLights / SetLightAtCameraIndex / '
        'SetLightOffAtCameraIndex',
    summary: 'The buttons drive the LED column by hand; nothing is stored. All '
        'lights on / off (SetAllLights(true | false)): the whole column at the '
        'photo intensity, no focus ring — dark instead when the Lighting master '
        'switch is off; false darkens every LED. Focus light on 1–6 '
        '(SetLightAtCameraIndex(i)): the LEDs at calibrated camera i in the '
        'focus colour (the whole ring, or the strip section at that camera); '
        'other LEDs keep their state, and it ignores the master switch. Focus '
        'light off 1–6 (SetLightOffAtCameraIndex(i)): those LEDs dark again. '
        'All return Empty: no readback, and no error for a board that is down '
        '(the server logs it) or an index the layout lacks. None takes the '
        'capture gate, so they work at any time — but a capture that starts '
        'afterwards overwrites the column with its own patterns. Not on this '
        'card: SetGlareSafeLights(i) (only the LEDs above camera i, for a '
        'subject with glasses; honours the master switch) and '
        'AutoTuneWhitePoint (closed-loop R/G/B tune with the light sensor, '
        'hidden in this app).',
    snippets: {
      'C# — facesnap-sdk': r'''
var lights = new LightProcessor();
await lights.SetAllLights(true);            // whole column (dark if Lighting is off)
await lights.SetLightAtCameraIndex(3);      // camera 3 in the focus colour
await lights.SetLightOffAtCameraIndex(3);   // and dark again
await lights.SetAllLights(false);           // every LED dark

// Not on this card:
await lights.SetGlareSafeLights(3);         // only the LEDs above camera 3''',
      'Dart — face_snap_grpc': r'''
final lights = LightsClient(GrpcChannelProvider.channel);
await lights.setAllLights(AllLightsRequest(status: true));
await lights.setLightAtCameraIndex(LightIndexRequest(index: 3));
await lights.setLightOffAtCameraIndex(LightIndexRequest(index: 3));
await lights.setAllLights(AllLightsRequest(status: false));
// Not on this card:
await lights.setGlareSafeLights(LightIndexRequest(index: 3));''',
    },
    docsUrl: '$_docsBase/docs/blocks/column-lights.html',
  ),
  'backlights': _DevTopic(
    title: 'The two LED backlights',
    rpc: 'Lights.SetBacklight / GetBacklights / SetBacklightBrightness',
    summary: 'Two LED backlights (bottom and top) on one of two outputs, chosen by the '
        'server: the LED board (dimmable, on the Qw/ST pins or the header A0/A1 pins, '
        'found by the board files) or a USB relay module (relay 1 = bottom, relay 2 = top, '
        'on or off only); the board wins when both are there. BacklightStatus.source says '
        'which: board_qwst, board_header, relay or none; bottom_percent / top_percent are '
        'the levels now (a relay reports 0 or 100) and brightness the stored brightness '
        'per light, standard then glare_free (the column setting backlight_brightness, '
        'saved with the column; default 100 %). A capture turns both on for the '
        'high-resolution photo at the brightness of its light (the glare-free light uses '
        'glare_free, every other light standard) and off as soon as it is taken; the '
        'single-camera photo RPCs keep them on for the whole call, and server start and '
        'stop switch them off. This card switches each by hand for testing, Refresh '
        're-reads them; per light a Bottom and a Top slider (0-100 % in steps of 5) '
        'previews the level live through SetBacklight with percent while that backlight '
        'is on and stores it on release through SetBacklightBrightness(light, bottom, top), '
        'which switches nothing. On a relay or none the sliders are greyed out '
        '("Dimming needs backlights on the LED board"; a relay takes any percent > 0 as on). '
        'GetBacklights never fails for missing backlights: connected = false, source '
        'none. SetBacklight answers the state read back: FAILED_PRECONDITION when nothing '
        'is connected, INVALID_ARGUMENT for BACKLIGHT_UNSPECIFIED or a percent outside '
        '0-100, UNAVAILABLE "LED board backlight command failed: …" / "USB relay module '
        'write failed: …". SetBacklightBrightness: INVALID_ARGUMENT "backlight light must '
        'be standard or glare_free, not \'…\'" / "backlight brightness must be 0-100, got '
        '…". Switching: server 1.1.15 / image 2.0.14 or newer (older: UNIMPLEMENTED); a '
        'server from before the dimming sends no source and no brightness and answers '
        'SetBacklightBrightness UNIMPLEMENTED (the card hides the sliders).',
    snippets: {
      'C# — facesnap-sdk': r'''
var lights = new LightProcessor();
var state = await lights.GetBacklights();   // no error without backlights
Console.WriteLine($"{state.source}: bottom {state.bottomPercent} %, top {state.topPercent} %");
foreach (var b in state.brightness)          // standard, then glare_free
    Console.WriteLine($"{b.light}: bottom {b.bottom} %, top {b.top} %");
try
{
    state = await lights.SetBacklight(Backlight.Bottom, true, 60);   // live, at 60 %
    var stored = await lights.SetBacklightBrightness("glare_free", 80, 100);   // SDK 1.5.5
    state = await lights.SetBacklight(Backlight.Top, true);   // at the stored standard level
}
catch (Grpc.Core.RpcException e)
    when (e.StatusCode == Grpc.Core.StatusCode.FailedPrecondition)
{
    // nothing connected (Unavailable = the board or relay command failed,
    // InvalidArgument = a refused light or level)
}''',
      'Dart — face_snap_grpc': r'''
final lights = LightsClient(GrpcChannelProvider.channel);
var state = await lights.getBacklights(Empty());
print('${state.source}: bottom ${state.bottomPercent} %, top ${state.topPercent} %');
if (state.connected) {
  try {
    state = await lights.setBacklight(BacklightRequest(
        backlight: Backlight.BACKLIGHT_BOTTOM, on: true, percent: 60));
    final stored = await lights.setBacklightBrightness(BacklightBrightnessRequest(
        light: 'glare_free', bottom: 80, top: 100));
    print('${stored.brightness.light}: ${stored.brightness.bottom} %');
  } on GrpcError catch (e) {
    print('${e.code}: ${e.message}');  // FAILED_PRECONDITION / UNAVAILABLE / INVALID_ARGUMENT
  }
}''',
    },
    docsUrl: '$_docsBase/docs/blocks/backlights.html',
  ),

  // ---- Camera page --------------------------------------------------------
  'camera-resolution': _DevTopic(
    title: 'Photo resolution',
    rpc: 'SettingsProcessor.SetResolution',
    summary: 'The size the server opens a camera with for the photo when no '
        'crop applies — so it decides the size of an UNCROPPED photo (crop '
        'off, the plain single-camera photo, the manual capture). A cropped '
        'photo\'s size is the crop resolution (Photo page); the camera scan and '
        'the preview always run at 640×480. Offer only the modes LoadSettings '
        'lists in cameraResolutions. This card marks 3840×2160 as native and '
        'recommended and every mode that is not 16:9 as "distorts, avoid" '
        '(the image is stretched, and the distance reads wrong). Default '
        '1280×720.',
    snippets: {
      'C# — facesnap-sdk': r'''
var settings = new SettingsProcessor();
var snapshot = await settings.LoadSettings();
foreach (var r in snapshot.cameraResolutions)          // what the cameras offer
    Console.WriteLine($"{r.width}x{r.height}" +
        (r.width * 9 == r.height * 16 ? "" : "  (not 16:9 - avoid)"));
var applied = await settings.SetResolution(3840, 2160); // uncropped photo size''',
      'Dart — face_snap_grpc': r'''
final c = SettingsClient(GrpcChannelProvider.channel);
final s = await c.loadSettings(Empty());
for (final r in s.cameraResolutions) {
  final note = r.width * 9 == r.height * 16 ? '' : '  (not 16:9 - avoid)';
  print('${r.width}x${r.height}$note');
}
await c.setResolution(ResolutionRequest(width: 3840, height: 2160));''',
    },
    docsUrl: '$_docsBase/docs/commissioning/camera-image.html',
  ),
  'camera-preview': _DevTopic(
    title: 'Live camera preview',
    rpc: 'Kiosk.StreamPreview',
    summary: 'StreamPreview(calibrated index, 1 = bottom; maxSeconds, 0 = 60 s) '
        'streams 640×480 JPEG frames (quality 70, about 15 fps, one complete '
        'JPEG per message) from ONE camera until you stop it, maxSeconds '
        'passes or the camera stops. This card asks for 300 s and stops by '
        'cancelling the call, which releases the camera at once. The preview '
        'never holds the capture gate, but starting one while a capture, a '
        'calibration or GetKioskStatus holds it is refused with '
        'RESOURCE_EXHAUSTED; when one of those takes the gate DURING a preview, '
        'the server stops the preview itself and the stream ends NORMALLY (no '
        'error) — start a new one afterwards. Errors: INVALID_ARGUMENT "No '
        'camera at calibrated index N", UNAVAILABLE "Could not open camera N", '
        'FAILED_PRECONDITION "Camera N is not delivering frames…" after 5 s '
        'without a frame. The photo settings do not apply to preview frames.',
    snippets: {
      'C# — facesnap-sdk': r'''
var kiosk = new KioskProcessor();
using var cts = new CancellationTokenSource();       // cts.Cancel() = Stop preview
try
{
    await foreach (ImageData frame in kiosk.StreamPreview(2, 300, cts.Token))
        ShowJpeg(frame.data);                         // one 640x480 JPEG
    // Ended normally: maxSeconds passed, or a capture took the cameras.
}
catch (Grpc.Core.RpcException e)
    when (e.StatusCode == Grpc.Core.StatusCode.Cancelled) { }   // stopped
catch (Grpc.Core.RpcException e)
{
    Console.WriteLine($"{e.StatusCode}: {e.Status.Detail}");  // e.g. ResourceExhausted
}''',
      'Dart — face_snap_grpc': r'''
final kiosk = KioskClient(GrpcChannelProvider.channel);
final subscription = kiosk
    .streamPreview(PreviewRequest(cameraIndex: 2, maxSeconds: 300))
    .listen(
      (frame) => showJpeg(frame.chunkData),          // one 640x480 JPEG
      onError: (Object e) => print('preview failed: $e'),  // GrpcError
      onDone: () => print('ended: maxSeconds, or a capture took the gate'),
    );
// Stop preview: cancelling releases the camera on the server at once.
await subscription.cancel();''',
    },
    docsUrl: '$_docsBase/docs/blocks/preview.html',
  ),
  'camera-properties': _DevTopic(
    title: 'Camera properties',
    rpc: 'CameraProcessor.LoadSettings / Set…',
    summary: 'Camera.LoadSettings returns the current values, propertyRanges '
        '(min / max / step / default the attached camera really accepts) and '
        'unsupportedProperties (controls it lacks — this card hides those). '
        'Windows servers ask DirectShow; kiosk boards (Linux) ask the V4L2 '
        'driver, so they report the supported controls too (both lists stay '
        'empty when no camera can be opened, and every slider shows). The card '
        'shows the three switches with brightness, white balance temperature, '
        'exposure and focus; contrast, saturation, hue, gamma, sharpness, zoom '
        'and — on a camera that has them — gain, backlight compensation, pan '
        'and tilt sit under the collapsed Advanced row, which is left out when '
        'the camera has none of them. Each Set… applies to ALL cameras of the column, is stored, and is '
        're-applied every time a camera is opened. When the server first '
        'learns the camera\'s ranges, a stored value outside them is set to '
        'the camera\'s default and logged ("Camera setting gamma 100 is '
        'outside this camera\'s range 0-64; set to the camera\'s default '
        '32"); LoadSettings returns the corrected value. Out of range is '
        'INVALID_ARGUMENT "<name> should be between <min> and <max>" (ELP '
        'cameras: brightness −64…64, contrast 0…64, saturation 0…128, exposure '
        '10…1250 in 100 µs units, focus 0…120). The three switches: automatic '
        'white balance (SetWhiteBalanceTemperatureAuto; off is recommended '
        'under the LED light, then SetWhiteBalanceTemperature applies — Windows '
        'servers up to 1.1.15 do not apply a hand-set temperature); automatic '
        'exposure (SetExposureAutoPriority: on, the capture "exposes for the '
        'face" with up to three corrections before the photo; off, '
        'SetExposureAbsolute applies); autofocus (SetAutofocus: off, '
        'SetFocusAbsolute applies). The manual exposure and focus sliders are '
        'greyed out while their automatic mode is on.',
    snippets: {
      'C# — facesnap-sdk': r'''
var camera = new CameraProcessor();
CameraSettings s = await camera.LoadSettings();
if (s.propertyRanges.TryGetValue("brightness", out var range) && range.supported)
    Console.WriteLine($"brightness {range.min}..{range.max} step {range.step}");
bool showGain = !s.unsupportedProperties.Contains("gain");   // hide what is missing

await camera.SetBrightness(20);                      // ELP: -64..64
await camera.SetWhiteBalanceTemperatureAuto(false);  // then the temperature applies
await camera.SetWhiteBalanceTemperature(6500);
await camera.SetExposureAutoPriority(true);          // on: exposes for the face
await camera.SetExposureAbsolute(330);               // 10..1250, used while auto is off
await camera.SetAutofocus(false);
await camera.SetFocusAbsolute(40);                   // used while autofocus is off
// Out of range: RpcException INVALID_ARGUMENT "brightness should be between ..."''',
      'Dart — face_snap_grpc': r'''
final c = CameraClient(GrpcChannelProvider.channel);
final s = await c.loadSettings(Empty());
final ranges = {for (final r in s.propertyRanges) r.name: r};
final brightness = ranges['brightness'];
if (brightness != null && brightness.supported) {
  print('brightness ${brightness.min}..${brightness.max}');
}
print('hide: ${s.unsupportedProperties.join(', ')}');

await c.setBrightness(BrightnessRequest(value: 20));      // ELP: -64..64
await c.setWhiteBalanceTemperatureAuto(
    WhiteBalanceTemperatureAutoRequest(value: false));
await c.setExposureAutoPriority(ExposureAutoPriorityRequest(value: true));
await c.setAutofocus(AutofocusRequest(value: false));
await c.setFocusAbsolute(FocusAbsoluteRequest(value: 40));''',
    },
    docsUrl: '$_docsBase/docs/commissioning/camera-image.html',
  ),
  'camera-distance': _DevTopic(
    title: 'Subject distance window',
    rpc: 'SetDistanceMin / SetDistanceMax',
    summary: 'The allowed subject distance in cm (defaults 0 and 200), '
        'estimated from the iris width in the frame. Distance is a GATE, like '
        'eyes and lips: a frame outside the window is rejected and the next '
        'one tried; after 30 rejected frames, mostly for distance, the capture '
        'gives up with "Could not take the photo with camera N: the distance to '
        'the camera was out of range in K of T frames, Please try again" '
        '(status OK, no photo). It gates '
        'GetHighResolutionImageWithIcaoChecksFromCameraIndex the same way (no '
        'frame in range within the timeout = TIMEOUT). The accepted frame '
        'shows as "Distance in cm: D", and as the GATE CheckResult named '
        '"distance" (value in cm, min / max = this window).',
    snippets: {
      'C# — facesnap-sdk': r'''
var settings = new SettingsProcessor();
await settings.SetDistanceMin(40);   // cm; default 0
await settings.SetDistanceMax(90);   // cm; default 200

// In the capture stream: the accepted frame's distance, structured.
await foreach (var item in new KioskProcessor().StartAutomaticProcess())
    if (item is GrpcLibrary.Dto.CheckResult { Name: "distance" } d)
        Console.WriteLine($"{d.Value} {d.Unit} (window {d.Min}-{d.Max})");''',
      'Dart — face_snap_grpc': r'''
final c = SettingsClient(GrpcChannelProvider.channel);
await c.setDistanceMin(DistanceMinRequest(value: 40));   // cm; default 0
await c.setDistanceMax(DistanceMaxRequest(value: 90));   // cm; default 200

await for (final event in startAutomaticCapture()) {
  if (event is CaptureCheck && event.result.name == 'distance') {
    final d = event.result;
    print('${d.value} ${d.unit} (window ${d.min}-${d.max})');
  }
}''',
    },
    docsUrl: '$_docsBase/docs/commissioning/checks-policy.html',
  ),
  'camera-windows': _DevTopic(
    title: 'Fast camera selection (Windows)',
    rpc: 'SettingsProcessor.SetMsmfSelection',
    summary: 'This card\'s one switch: on a Windows-hosted server the '
        'best-camera scan opens the cameras through Media Foundation (about '
        '0.6 s per camera) instead of DirectShow (about 1.7 s). Only the scan '
        'uses it: the photo is always taken through DirectShow, so its exposure '
        'is unchanged, and a camera MSMF cannot open falls back to DirectShow '
        'by itself. The FACE_SNAP_MSMF_SELECTION environment variable on the '
        'server overrides the setting; a kiosk board ignores it. Default on. '
        'The switch is greyed out while the app is connected to a remote host. '
        '(The camera ordering moved to the Calibration page: '
        'SetCameraOrderingMode("manual" | "automatic" | "person").)',
    snippets: {
      'C# — facesnap-sdk': r'''
var settings = new SettingsProcessor();
MsmfSelection msmf = await settings.SetMsmfSelection(true);   // Windows servers only
bool current = (await settings.LoadSettings()).msmfSelection;''',
      'Dart — face_snap_grpc': r'''
final c = SettingsClient(GrpcChannelProvider.channel);
final reply = await c.setMsmfSelection(MsmfSelectionRequest(enabled: true));
print(reply.enabled);   // the stored value''',
    },
    docsUrl: '$_docsBase/docs/commissioning/selection-behaviour.html',
  ),

  // ---- Calibration page ---------------------------------------------------
  'calibration-positions': _DevTopic(
    title: 'Camera positions',
    rpc: 'GetCalibration / SetCalibration / CalibrateByPerson / '
        'CalibrateBySurroundings + SetCameraOrderingMode / '
        'SetCameraHubUpsideDown',
    summary: 'Which physical camera is at which height (1 = bottom). '
        'GetCalibration returns one entry per ATTACHED camera — idModelId, '
        'linuxCameraIndex (the device index) and calibratedCameraIndex (0 = no '
        'position yet); this card shows them in the position boxes and Refresh '
        'cameras reads them again. SetCalibration stores each entry\'s '
        'calibratedCameraIndex (not its place in the list); the server adds '
        'the camera\'s USB port, so a position follows the SOCKET and a '
        'replacement camera in the same port needs no recalibration. Without a '
        'position for every attached camera every capture is refused '
        '("Cameras are not calibrated - run the calibration page first"). '
        '"Calibrate by a person" calls CalibrateByPerson: a person stands at '
        'the normal distance while the server scans the column three times '
        '(about 10 s; this card allows 180 s) and returns a PROPOSAL — success '
        'with a proposed position per camera, or success = false and a message '
        'saying what to change. The card fills the boxes; nothing is stored '
        'until Save positions (SetCalibration; in C# proposal.ToCalibration()). '
        'It scans the cameras, so it takes the capture gate (RESOURCE_EXHAUSTED '
        'during a capture); an older server answers UNIMPLEMENTED. The ordering '
        'selector is SetCameraOrderingMode: "manual" (the saved positions), '
        '"person" (the same, worked out by CalibrateByPerson), "surroundings" '
        '(the same, worked out by CalibrateBySurroundings) or "automatic" '
        '(from the USB socket via the standard-hub map, no calibration; the '
        'saved positions for a socket it does not know). '
        '"From the surroundings" calls CalibrateBySurroundings: with NOBODY in '
        'front of the column the server compares neighbouring cameras\' views '
        'twice (about 8-22 s for six cameras; this card allows 180 s) and '
        'returns the same kind of proposal, with each camera\'s fitted '
        'vertical offset in pixels instead of a face height; a plain backdrop '
        'gives success = false. It needs server 1.1.25 or newer (Server 2.0: the '
        'matching image). The switch '
        'under the selector is SetCameraHubUpsideDown: on, the automatic '
        'order is mirrored (position p becomes N + 1 - p of the matched '
        'wiring) for a column whose USB hub is mounted upside down; the reply '
        'carries the value the server applied, LoadSettings reports it as '
        'cameraHubUpsideDown, and it is a column setting (hub_upside_down). An '
        'older server answers UNIMPLEMENTED.',
    snippets: {
      'C# — facesnap-sdk': r'''
var calibration = new CalibrationProcessor();
List<CalibrationData> rows = await calibration.GetCalibration();   // per attached camera
foreach (var r in rows)
    Console.WriteLine($"device {r.linuxCameraIndex}: position {r.calibratedCameraIndex}");

// A person stands in front of the column; the server proposes the positions.
PersonCalibrationResult proposal = await calibration.CalibrateByPerson();
if (!proposal.success) { Console.WriteLine(proposal.message); return; }
CalibratedResponse saved = await calibration.SetCalibration(proposal.ToCalibration());
Console.WriteLine(saved.success ? "stored" : saved.message);

// The ordering selector: "manual", "automatic", "person" or "surroundings".
var settings = new SettingsProcessor();
CameraOrderingMode mode = await settings.SetCameraOrderingMode("person");

// Nobody in front of the column: the server proposes from what the cameras see.
SurroundingsCalibrationResult fromView = await calibration.CalibrateBySurroundings();
if (fromView.success) await calibration.SetCalibration(fromView.ToCalibration());
else Console.WriteLine(fromView.message);   // e.g. a plain backdrop
await settings.SetCameraOrderingMode("surroundings");

// The column's USB hub is mounted upside down: mirror the automatic order.
CameraHubUpsideDown hub = await settings.SetCameraHubUpsideDown(true);
Console.WriteLine(hub.upsideDown);   // the value the server applied''',
      'Dart — face_snap_grpc': r'''
final calibration = CalibrationClient(GrpcChannelProvider.channel);
final rows = (await calibration.getCalibration(Empty())).calibrate.toList();

final proposal = await calibration.calibrateByPerson(Empty(),
    options: CallOptions(timeout: const Duration(seconds: 180)));
if (proposal.success) {
  final byDevice = {
    for (final cam in proposal.cameras) cam.linuxCameraIndex: cam.proposedPosition,
  };
  for (final row in rows) {
    row.calibratedCameraIndex =
        byDevice[row.linuxCameraIndex] ?? row.calibratedCameraIndex;
  }
  final saved = await calibration.setCalibration(CalibrateRequest(calibrate: rows));
  print(saved.success ? 'stored' : saved.message);
} else {
  print(proposal.message);   // what to change, then try again
}

// Send the old flag too, so an older server understands "automatic".
final settings = SettingsClient(GrpcChannelProvider.channel);
await settings.setCameraOrderingMode(
    CameraOrderingModeRequest(mode: 'person', automatic: false));

// Nobody in front of the column: the same proposal from what the cameras see
// (cam.offset = the fitted vertical offset in pixels).
final fromView = await calibration.calibrateBySurroundings(Empty(),
    options: CallOptions(timeout: const Duration(seconds: 180)));
print(fromView.success ? fromView.cameras : fromView.message);

// The column's USB hub is mounted upside down: mirror the automatic order.
final hub = await settings.setCameraHubUpsideDown(
    CameraHubUpsideDownRequest(upsideDown: true));
print(hub.upsideDown);   // the value the server applied''',
    },
    docsUrl: '$_docsBase/docs/commissioning/calibration.html',
  ),
  'expected-cameras': _DevTopic(
    title: 'Expected camera count',
    rpc: 'SetExpectedCameras',
    summary: 'How many cameras the kiosk is built with, 1–6, or 0 (automatic) '
        'to derive the count from the calibration file. It drives the server\'s '
        'hardware watcher, not the capture: when fewer cameras are attached '
        'than expected, the watcher power-cycles the camera USB hub. A value '
        'outside 0–6 is refused with INVALID_ARGUMENT "expected cameras should '
        'be between 0 (automatic) and 6". LoadSettings reads it back '
        '(expectedCameras).',
    snippets: {
      'C# — facesnap-sdk': r'''
var settings = new SettingsProcessor();
ExpectedCameras applied = await settings.SetExpectedCameras(4);   // 0 = automatic
// 7 or -1: RpcException INVALID_ARGUMENT''',
      'Dart — face_snap_grpc': r'''
final c = SettingsClient(GrpcChannelProvider.channel);
final reply = await c.setExpectedCameras(ExpectedCamerasRequest(value: 4));
print(reply.message);   // the stored count; 0 = automatic''',
    },
    docsUrl: '$_docsBase/docs/commissioning/calibration.html',
  ),
  'calibrate-focus': _DevTopic(
    title: 'Focus calibration (sharpness sweep)',
    rpc: 'SetFocusAbsolute + StartAutomaticProcess · Camera.CalibrateFocus',
    summary: 'This card\'s button does NOT call CalibrateFocus: it runs a '
        'sharpness sweep in the app, with a person standing at the marking. It '
        'switches autofocus off (SetAutofocus(false)) and, when it is on, the '
        'live person check\'s head turn off (SetLivenessChecks with '
        'headTurnCheck false, switched back on afterwards; headTurnCheck is '
        'sent explicitly, as unset keeps the stored value; stored off, the '
        'sweep sends no SetLivenessChecks), then per focus value: '
        'SetFocusLight in a colour that runs '
        'from red to green as the search converges, SetFocusAbsolute(value), '
        'ONE automatic capture, and a Laplacian-variance sharpness score of the '
        'photo\'s centre computed in Dart. A coarse pass over 0–120 in steps of '
        '20, a fine pass ±10 around the best in steps of 5, a pinpoint pass ±4 '
        'in steps of 2; then SetFocusAbsolute(best), stored for all cameras, '
        'and a flourish (the column green through SetIntensityRed/Green/Blue + '
        'SetAllLights, faded out, the intensities restored). The one-call '
        'server alternative is Camera.CalibrateFocus(cameraIndex): it lights '
        'the column, lets that camera\'s autofocus settle, stores the locked '
        'position as the fixed focus, switches autofocus back off and answers '
        'the value, or −1 without a lock; about 4–8 s (the C# call sets a 60 s '
        'deadline); cameraIndex = calibrated index, 0 = the best camera; it '
        'takes the capture gate (RESOURCE_EXHAUSTED during a capture), and an '
        'unknown index is INVALID_ARGUMENT.',
    snippets: {
      'C# — facesnap-sdk': r'''
var camera = new CameraProcessor();

// The one-call server alternative (this card does not use it):
FocusAbsolute locked = await camera.CalibrateFocus(0);   // 0 = best camera
if (locked.focusAbsolute < 0) Console.WriteLine("no focus lock, try again");

// What this card does: a sharpness sweep over SetFocusAbsolute.
var settings = new SettingsProcessor();
var before = await settings.LoadSettings();
bool headTurn = before.livenessHeadTurnCheck;
if (headTurn)
    await settings.SetLivenessChecks(before.livenessCheck, headTurnCheck: false);   // head turn off
await camera.SetAutofocus(false);
var kiosk = new KioskProcessor();
var scores = new Dictionary<int, double>();
foreach (int focus in new[] { 0, 20, 40, 60, 80, 100, 120 })   // then ±10/5, ±4/2
{
    await camera.SetFocusAbsolute(focus);
    await foreach (var item in kiosk.StartAutomaticProcess())
        if (item is ImageData photo) scores[focus] = Sharpness(photo.data);  // your scorer
}
await camera.SetFocusAbsolute(scores.MaxBy(kv => kv.Value).Key);
if (headTurn)
    await settings.SetLivenessChecks(before.livenessCheck, headTurnCheck: true);   // back on''',
      'Dart — face_snap_grpc': r'''
final camera = CameraClient(GrpcChannelProvider.channel);
final settings = SettingsClient(GrpcChannelProvider.channel);

// The one-call server alternative (this card does not use it):
final locked = await camera.calibrateFocus(CalibrateFocusRequest(cameraIndex: 0),
    options: CallOptions(timeout: const Duration(seconds: 60)));
if (locked.message < 0) print('no focus lock');

// This card's sweep (calibration_page.dart).
final s = await settings.loadSettings(Empty());
final headTurn = s.livenessHeadTurnCheck;   // stored off: no SetLivenessChecks at all
if (headTurn) {
  await settings.setLivenessChecks(LivenessChecksRequest(
      livenessCheck: s.livenessCheck,
      headTurnCheck: false));   // present false: unset keeps the stored value
}
await camera.setAutofocus(AutofocusRequest(value: false));
final scores = <int, double>{};
for (var focus = 0; focus <= 120; focus += 20) {     // then ±10/5, ±4/2
  await settings.setFocusLight(FocusLightRequest(
      color: sweepColour(focus), intensity: s.focusIntensity));  // red -> green
  await camera.setFocusAbsolute(FocusAbsoluteRequest(value: focus));
  await for (final event in startAutomaticCapture()) {
    if (event is CapturePhoto) scores[focus] = faceSharpness(event.bytes);
  }
}
final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
await camera.setFocusAbsolute(FocusAbsoluteRequest(value: best));
if (headTurn) {
  await settings.setLivenessChecks(LivenessChecksRequest(
      livenessCheck: s.livenessCheck, headTurnCheck: true));   // back on, present
}''',
    },
    docsUrl: '$_docsBase/docs/commissioning/camera-image.html',
  ),
  'photo-colour': _DevTopic(
    title: 'Photo colour (measuring a kiosk)',
    rpc: 'StartManualCapture + Settings.SetColourCorrection',
    summary: 'Every photo\'s colours are corrected with a 3×3 matrix (row-major, '
        'R G B, linear light) per light: "all", "neighbours" and "glare_free"; '
        'the photo light "off" is never corrected. LoadSettings reports the '
        'kiosk-wide switch (colour_correction) and per light the matrix in force '
        '(colour_corrections: source "shipped" for the LED hardware, or "kiosk" '
        'with its measurement); a server without the feature sends none of them. '
        'Measure runs a manual capture with CaptureSettings colour_correction '
        'false and that light (photo_light "all" / "neighbours" with '
        'glare_free_light "off", or glare_free_light "everyone"), checks the '
        'settings used (correction on, or LEDs off for the photo: refused), '
        'shows the middle camera\'s photo, and the operator taps the centres of '
        'the SpyderCheckr 24\'s four corner patches (1E, 1H, 6H, 6E, any order). '
        'The app reads the 24 patches, leaves clipped ones out, fits the matrix '
        'with every row summing to 1 (white stays white) and shows the mean and '
        'worst ΔE2000 before → after; a white patch clipped, patches under 17 px, '
        'taps that do not match the card or a fit that would not improve the '
        'colours are refused and nothing is stored. Save sends '
        'SetColourCorrection(light, matrix, measurement); Back to shipped sends '
        'it with clear. A matrix the server refuses is INVALID_ARGUMENT with its '
        'reason (9 finite numbers within ±4, rows summing to 1 ± 0.05, '
        'invertible). It is a column setting (colour_correction in the column '
        'profile): the matrices travel with the column\'s LED board.',
    snippets: {
      'C# — facesnap-sdk': r'''
var settings = new SettingsProcessor();
var kiosk = new KioskProcessor();
var snapshot = await settings.LoadSettings();
foreach (var state in snapshot.colourCorrections)   // empty: a server without it
    Console.WriteLine($"{state.light}: {state.source}");

// The photo for the measurement: uncorrected, in the light measured.
var request = new CaptureSettings { ColourCorrection = false, PhotoLight = "all", GlareFreeLight = "off" };
byte[]? photo = null;
await foreach (var item in kiosk.StartManualCapture(request))
{
    if (item is GrpcLibrary.Dto.CaptureSettingsUsed used && used.Values.ColourCorrection)
        throw new InvalidOperationException("the correction could not be switched off");
    if (item is ImageData img && img.index == 3) photo = img.data;   // the middle camera
}

// Fit the matrix from the chart in the photo (your code, or cc_probe.py --fit), then:
double[] matrix = Fit(photo!);                       // 9 numbers, each row sums to 1
await settings.SetColourCorrection("all", matrix, new ColourMeasurementDto
{
    measured = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ"),
    camera = 3, chart = "spyder24", meanDeBefore = 6.0, meanDeAfter = 2.0,
});
await settings.ClearColourCorrection("all");         // back to the shipped matrix
await settings.SetColourCorrectionEnabled(true);     // the kiosk-wide switch''',
      'Dart — face_snap_grpc': r'''
final settings = SettingsClient(GrpcChannelProvider.channel);
final snapshot = await settings.loadSettings(Empty());
for (final state in snapshot.colourCorrections) {    // empty: a server without it
  print('${state.light}: ${state.source}');
}

// The photo for the measurement: uncorrected, in the light measured.
final photos = <CameraPhoto>[];
await for (final event in startManualCapture(
    settings: CaptureSettings(colourCorrection: false, glareFreeLight: 'everyone'))) {
  if (event is CaptureSettingsReport && event.values.colourCorrection) {
    throw StateError('the correction could not be switched off');
  }
  if (event is CameraPhoto) photos.add(event);
}

// This app: readChart (four taps) + fitColourMatrixGuarded (lib/util/colour_fit.dart)
// against the card's reference (lib/util/card_reference.dart): skin weight 3, 6, 12, 24, 48
// until no skin patch gets more than 0.5 dE worse; save only what is not refused.
final reference = await loadCardReference('spyder24');
final fit = fitColourMatrixGuarded(patchMeans, usable, reference: reference);
if (colourFitRefusal(fit, reference: reference) != null) return;
await settings.setColourCorrection(ColourCorrectionRequest(
    light: 'glare_free',
    matrix: fit.matrix,
    measurement: ColourMeasurement(
        measured: '2026-10-20T14:05:00Z', camera: 3, chart: 'spyder24',
        meanDeBefore: fit.meanDeBefore, meanDeAfter: fit.meanDeAfter)));
await settings.setColourCorrection(
    ColourCorrectionRequest(light: 'glare_free', clear_4: true));   // shipped''',
      'Protocol': r'''
rpc SetColourCorrection (ColourCorrectionRequest) returns (ColourCorrectionResponse)
rpc SetColourCorrectionEnabled (ColourCorrectionEnabledRequest)
                                returns (ColourCorrectionEnabledResponse)
ColourCorrectionRequest { light, repeated double matrix (9), ColourMeasurement
                          measurement, bool clear }
ColourMeasurement { measured (ISO 8601 UTC), camera, chart "spyder24",
                    mean_de_before, mean_de_after }
LoadSettingsResponse: bool colour_correction = 52;
                      repeated ColourCorrectionState colour_corrections = 53;
                      (all, neighbours, glare_free; source "kiosk" / "shipped")
CaptureSettings.colour_correction = 27   (optional; a manual capture may use it)''',
    },
    docsUrl: '$_docsBase/docs/commissioning/photo-colour.html',
  ),

  // ---- Face recognition page ----------------------------------------------
  'face-recognition': _DevTopic(
    title: 'Comparing two photos',
    rpc: 'Kiosk.FaceRecognition',
    summary: 'Compares two encoded images (JPEG / PNG bytes) — on this page '
        'the photos of the last 10 captures (kept on this PC, also after a '
        'restart) or one loaded with "Load photo from this PC…", e.g. a '
        'passport scan. The server first cuts the face out of each image (no '
        'face found: the whole image is '
        'compared — expect a larger distance), embeds both with the chosen '
        'model (Dlib or SFace; the first call per model also loads it; the '
        'retired Facenet512 is refused with INVALID_ARGUMENT) and measures '
        'the distance with the chosen metric (cosine, '
        'euclidean, euclidean_l2): verified = distance <= threshold. Threshold '
        '0 = the server\'s default for the model and metric (cosine: Dlib 0.07, '
        'SFace 0.593). This card always sends its own '
        'threshold from the slider, which starts at values measured on kiosk '
        'photos (SFace · cosine 0.45, the card\'s default). A failure is '
        'NOT a gRPC error: status ERROR with verified = false — check status '
        'first. The card allows 120 s (the first call loads the model). No '
        'capture gate, no camera, no lights.',
    snippets: {
      'C# — facesnap-sdk': r'''
var kiosk = new KioskProcessor();
var result = await kiosk.FaceRecognition(new GrpcLibrary.Dto.FaceRecognitionRequest
{
    image1 = File.ReadAllBytes("capture.jpg"),
    image2 = File.ReadAllBytes("passport.jpg"),
    model = Model.Sface,                         // Dlib, Sface (Facenet512 retired)
    similarity_metric = DistanceMetric.Cosine,   // Cosine, Euclidean, EuclideanL2
    threshold = 0.45,                            // 0 = server default (0.593 here)
});
if (result.status != GrpcLibrary.StatusType.Ok)   // not the global StatusType
    Console.WriteLine("comparison failed");      // verified is false then
else
    Console.WriteLine($"{(result.verified ? "same" : "different")} person: " +
        $"distance {result.distance:F3} vs {result.threshold:F3} ({result.time:F2} s)");''',
      'Dart — face_snap_grpc': r'''
final kiosk = KioskClient(GrpcChannelProvider.channel);
final result = await kiosk.faceRecognition(
  FaceRecognitionRequest(
    image1: captureJpeg,
    image2: passportJpeg,
    model: Model.SFACE,
    similarityMetric: DistanceMetric.COSINE,
    threshold: 0.45,                 // 0 = server default
  ),
  options: CallOptions(timeout: const Duration(seconds: 120)),
);
if (result.status != StatusType.OK) {
  print('comparison failed');        // verified is false then
} else {
  print('${result.verified ? 'same' : 'different'} person, '
      'distance ${result.distance.toStringAsFixed(3)} vs ${result.threshold}');
}''',
    },
    docsUrl: '$_docsBase/docs/blocks/verify-face.html',
  ),

  // ---- Monitoring page ----------------------------------------------------
  'monitoring-status': _DevTopic(
    title: 'Kiosk status check',
    rpc: 'Monitoring.GetKioskStatus',
    summary: 'A camera self-test streamed as (description, status) lines: '
        '"Found a total of N camera\'s", "Resetting camera\'s", per camera '
        '"Camera index i successfully checked" or "Something went wrong with '
        'camera index i" (i = calibrated index), "Releasing camera\'s", "Kiosk '
        'status Finalized" — four lines plus one per camera, then the stream '
        'ends. status is the string "OK" on EVERY line; the verdict is in the '
        'text. It opens every camera at full resolution, one at a time, so it '
        'takes the capture gate: refused with RESOURCE_EXHAUSTED "capture in '
        'progress" while a capture or calibration runs, captures are refused '
        'while it runs, and a running preview stops itself. Run it only while '
        'the kiosk is idle. Leaving the loop or cancelling the token (C#) / the '
        'call (Dart) ends it on the server.',
    snippets: {
      'C# — facesnap-sdk': r'''
var monitoring = new MonitoringProcessor();
using var cts = new CancellationTokenSource(TimeSpan.FromMinutes(2));
try
{
    await foreach (var (description, status) in monitoring.GetKioskStatus(cts.Token))
    {
        bool failed = description.StartsWith("Something went wrong with camera index");
        Console.WriteLine($"{(failed ? "FAIL" : "ok  ")} {description}");  // status: "OK"
    }
}
catch (Grpc.Core.RpcException e)
    when (e.StatusCode == Grpc.Core.StatusCode.ResourceExhausted)
{
    Console.WriteLine("a capture is running - try again when the kiosk is idle");
}''',
      'Dart — face_snap_grpc': r'''
final call = MonitoringClient(GrpcChannelProvider.channel).getKioskStatus(Empty());
try {
  await for (final line in call) {          // call.cancel() stops it early
    final failed =
        line.description.startsWith('Something went wrong with camera index');
    print('${failed ? 'FAIL' : 'ok  '} ${line.description}');  // status: 'OK'
  }
} on GrpcError catch (e) {
  print('${e.code}: ${e.message}');  // RESOURCE_EXHAUSTED: a capture is running
}''',
    },
    docsUrl: '$_docsBase/docs/blocks/kiosk-status.html#getkioskstatus',
  ),
  'kiosk-info': _DevTopic(
    title: 'Kiosk information',
    rpc: 'Kiosk.GetKioskInfo',
    summary: 'One cheap unary call: serverIpAddress (the host\'s own address), '
        'port (the port it listens on: 50051, or the port chosen in the '
        'setup), numberOfCameras (attached cameras) and '
        'cameraInfo — one entry per attached camera with its CALIBRATED index '
        '(0 = no position). It enumerates the cameras without opening one and '
        'takes no capture gate, so it answers during a capture; the Kiosk page '
        'uses it as the ping of every server row.',
    snippets: {
      'C# — facesnap-sdk': r'''
var info = await new KioskProcessor().GetKioskInfo();
Console.WriteLine($"{info.kioskData.serverIpAddress}:{info.kioskData.port}, " +
    $"{info.kioskData.numberOfCameras} cameras, positions " +
    string.Join(", ", info.cameraData.Select(c => c.index)));   // 0 = uncalibrated''',
      'Dart — face_snap_grpc': r'''
final info = await KioskClient(GrpcChannelProvider.channel).getKioskInfo(
    Empty(), options: CallOptions(timeout: const Duration(seconds: 2)));
print('${info.kioskInfo.serverIpAddress}:${info.kioskInfo.port}, '
    '${info.kioskInfo.numberOfCameras} cameras, positions '
    '${info.cameraInfo.map((c) => c.index).join(', ')}');  // 0 = uncalibrated''',
    },
    docsUrl: '$_docsBase/docs/blocks/kiosk-status.html#getkioskinfo',
  ),
  'light-measurement': _DevTopic(
    title: 'Reading the light sensor',
    rpc: 'Monitoring.GetLightMeasurement',
    summary: 'One reading from the OPT4048 sensor on the LED board: '
        'illuminance (lux), correlated colour temperature (Kelvin) and CIE '
        '1931 x / y. Without the sensor or the LED board, available is false '
        'and error says why — a normal configuration, not a gRPC error; the '
        'numbers mean nothing then. No capture gate; milliseconds.',
    snippets: {
      'C# — facesnap-sdk': r'''
var m = await new MonitoringProcessor().GetLightMeasurement();
Console.WriteLine(m.available
    ? $"{m.lux:F0} lx, {m.cct:F0} K, x {m.cieX:F4} y {m.cieY:F4}"
    : $"light sensor unavailable: {m.error}");''',
      'Dart — face_snap_grpc': r'''
final m = await MonitoringClient(GrpcChannelProvider.channel)
    .getLightMeasurement(Empty());
print(m.available
    ? '${m.lux.toStringAsFixed(1)} lx, ${m.cct.round()} K'
    : 'light sensor unavailable: ${m.error}');''',
    },
    docsUrl: '$_docsBase/docs/blocks/kiosk-status.html#getlightmeasurement',
  ),
  'usage-stream': _DevTopic(
    title: 'System usage stream',
    rpc: 'Monitoring.OdroidUsage',
    summary: 'One UsageResponse per second, cycling six types: CPU (load %), '
        'MEMORY (in use %), CPU_COUNT (logical CPUs), NET_IF_ADDRS (primary '
        'IPv4 address), NET_IO_COUNTERS (bytes received), BOOT_TIME '
        '("YYYY-MM-DD HH:MM:SS"); usage is a preformatted string. No '
        'temperature. It never ends by itself: Stop monitoring cancels the '
        'subscription (C#: leave the loop or cancel the token), or the server '
        'keeps streaming. This card shows CPU, memory, cores and boot time.',
    snippets: {
      'C# — facesnap-sdk': r'''
var monitoring = new MonitoringProcessor();
using var cts = new CancellationTokenSource();   // cts.Cancel() = Stop monitoring
try
{
    await foreach (Usage u in monitoring.OdroidUsage(cts.Token))
    {
        if (u.usageType == UsageType.Cpu) Console.WriteLine($"CPU {u.usage} %");
        else if (u.usageType == UsageType.Memory) Console.WriteLine($"memory {u.usage} %");
        else if (u.usageType == UsageType.CpuCount) Console.WriteLine($"{u.usage} cores");
        else if (u.usageType == UsageType.BootTime) Console.WriteLine($"booted {u.usage}");
    }
}
catch (Grpc.Core.RpcException e)
    when (e.StatusCode == Grpc.Core.StatusCode.Cancelled) { }   // stopped''',
      'Dart — face_snap_grpc': r'''
final latest = <UsageType, String>{};
final subscription = MonitoringClient(GrpcChannelProvider.channel)
    .odroidUsage(Empty())
    .listen((u) => latest[u.usageType] = u.usage);  // CPU, MEMORY, CPU_COUNT, ...
// Stop monitoring (and when the page closes):
await subscription.cancel();''',
    },
    docsUrl: '$_docsBase/docs/blocks/kiosk-status.html#odroidusage',
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
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
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

              // ---- summary with the RPC chip (scrolls when it is long, so
              // the code block always keeps room) ----
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  child: Text.rich(
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
                                  fontFamilyFallback: [
                                    'Courier New',
                                    'monospace'
                                  ],
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
                ),
              ),
              const SizedBox(height: 12),

              // ---- tabs (wrap onto a second line when they do not fit) ----
              Wrap(spacing: 4, runSpacing: 4, children: [
                for (var i = 0; i < labels.length; i++)
                  InkWell(
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
                  child: const Text('Open the SDK documentation ↗',
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
