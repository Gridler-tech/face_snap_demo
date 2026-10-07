# Face Snap SDK change log



## Version 1.5.4, 07-10-2026

Structured check results, cancellation for every stream, and the settings for the
ICAO report, the live person check, the photo light and the strip layout's own
`gbl.py`. The assembly version stays 1.0.0.0 and the dependencies are those of 1.5.3,
so replace `GrpcLibrary.dll` and `GrpcLibrary.xml` in `library/`; an application built
against 1.5.x keeps working without a rebuild.

- **Structured check results.** `KioskProcessor.StartAutomaticProcess()` now also
  yields a `GrpcLibrary.Dto.CheckResult` right after the status line of each check that
  ran: a stable `Name` ("distance", "eyes", "liveness_colour", "ofiq.Sharpness",
  "icao.compliance", ...), `Kind`, `Verdict` (`Passed`, `Failed`, `NotChecked`),
  `GatesPhoto` and, when the check has them, `Value` / `Min` / `Max` in `Unit`.
  `GetHighResolutionImageWithIcaoChecksFromCameraIndex` returns the photo's results in
  the new `ImageData.Checks` (never null; empty for every other call). Key on `Name`
  and `Verdict`, not on the status text. A `switch` without a `CheckResult` case simply
  skips the items. The generated protobuf types share the names `CheckResult`,
  `CheckKind` and `CheckVerdict`, so alias the ones you use
  (`using CheckResult = GrpcLibrary.Dto.CheckResult;`). The names and values are listed
  in [Check results](https://gridler-tech.github.io/face_snap/docs/reference/check-results.html).
  Needs Windows server 1.1.23 or kiosk image 2.0.20; an older server sends no
  results and everything else works as before.
- **Cancellation for every stream.** `StartAutomaticProcess`, `StartManualProcess`,
  `GetHighResolutionImageFromCameraIndex`,
  `GetHighResolutionImageWithIcaoChecksFromCameraIndex`, `StreamPreview`,
  `LightProcessor.AutoTuneWhitePoint`, `MonitoringProcessor.GetKioskStatus` and
  `OdroidUsage` have an overload with a `CancellationToken` that ends the call on the
  server. Leaving an `await foreach` early (`break`) now also disposes the call, so a
  stopped preview releases the camera. The existing signatures are unchanged.
- **New settings.** `SettingsProcessor.SetIcaoReport(bool)` (after the photo, one
  verdict per ICAO portrait requirement), `SetLivenessChecks(livenessCheck,
  shadingCheck, colourCheck)` (the live person check: the depth check over the
  selection scan, and two optional checks with the kiosk's own light),
  `SetPhotoLight("all" | "neighbours")` (light the photo with every ring, or with the
  selected camera's ring and one on each side) and `GetBoardGbl(layout)` /
  `SetBoardGbl(layout, content)` (the operator's own `gbl.py` for an LED layout, kept
  across layout switches and server updates; empty content restores the shipped file).
  `KioskSettingsDto` reads them back as `icaoReport`, `livenessCheck`,
  `livenessShadingCheck`, `livenessColourCheck` and `photoLight`.
- **`SettingsProcessor.SaveSettings` is `[Obsolete]`.** It never stored anything: both
  servers return the request unchanged. Use the `Set` call of each setting and
  `LoadSettings` to read them back. The RPC stays, so existing code still compiles (with
  a warning) and runs.
- **Fixes.** `StartAutomaticProcess` and `StartManualProcess` no longer yield an
  `ImageData` with 0 bytes when the server gave up: a capture without a photo ends
  after its last `ProcessStatus`. The manual flow keeps each camera's own photo width
  and height. `ImageData.index` is documented as what it is, the camera index (not a
  chunk number).
- The new interface members have default bodies, like those added in 1.5: an
  implementation written against 1.5.3 still loads and throws `NotSupportedException`
  for them, now naming the release that added the member (`CalibrateByPerson`: 1.5.3).

Needs a server that supports these: Windows server 1.1.23 or kiosk image 2.0.20 and
later carry all of it; older servers answer the new RPCs with `UNIMPLEMENTED` and send
no check results.

## Repository note, 07-10-2026 (operator app 1.1.23)

Release 1.5.4 carries `FaceSnapOperatorSetup-1.1.23.exe` (the installer moved from
1.5.3), and the sources in `flutter_apps/` match it. The new check results need Windows server 1.1.23 or later;
older servers still work, the results simply do not appear.

- **Structured check results.** Every check of a capture also arrives as a
  machine-readable `CheckResult` (name, verdict passed / failed / not checked, the
  measured value and its limits, unit). The Capture page shows them with every check
  row and lists what is wrong first. In the Dart SDK the capture stream yields a new
  `CaptureCheck` event (`CaptureEvent` is sealed: an exhaustive `switch` needs a
  `case CaptureCheck()`, see `face_snap_grpc/example/capture_once.dart`).
- **RPC console** (Developer mode). A dock lists every call the app makes to the
  server, with every request field and the answer, and copies any call as Dart or C#
  (`RpcTrace` and the snippet builder live in `face_snap_grpc/lib/src/`).
- **Developer info.** The guides behind the `</>` badges are rewritten for all cards.
- **Capture page.** A Clear button, the last ten captures kept, the selected camera's
  row on top, advice rows for the operator, the live person check rows kept together.
- **Settings.** Switches for the ICAO compliance report, the live person checks
  with the kiosk's own light and the photo light (the selected camera's ring and its
  two neighbours); the Lighting page edits the strip layout's own `gbl.py`. The Dart
  stubs are regenerated for `SetIcaoReport`, `SetLivenessChecks`, `SetPhotoLight`,
  `SetBoardGbl` / `GetBoardGbl`, `CheckKind` and `CheckVerdict`.
- **LED board files v14**, which also work on older Plasma 2040 firmware.

The operator app has 278 tests; `face_snap_grpc` now carries its own test
(`test/rpc_trace_test.dart`, 22 cases).

## Version 1.5.3, 04-10-2026

Backlights, the lights-off photo mode and calibration by a person. The assembly
version stays 1.0.0.0 and everything in 1.5.2 is unchanged — the API only adds.
This time replace **all** DLLs from `library/`, not only `GrpcLibrary.dll` (and
`GrpcLibrary.xml`): the library is now built against current gRPC and Protocol
Buffers packages.

- **Updated dependencies.** `Grpc.Net.Client`, `Grpc.Net.Common` and
  `Grpc.Core.Api` 2.84.0 (were 2.51.0), `Google.Protobuf` 3.36.2 (was 3.21.12),
  `Microsoft.Extensions.Logging.Abstractions` 8.0.1 (was 3.0.3) and, new,
  `Microsoft.Extensions.DependencyInjection.Abstractions` 8.0.1. `GrpcLibrary.dll`
  1.5.3 needs at least these versions: an application that keeps the old
  `Google.Protobuf.dll` next to the new `GrpcLibrary.dll` fails to load it. The
  release's `GrpcLibrary.deps.json` lists the exact set.

- **`LightProcessor.SetBacklight(Backlight backlight, bool on)`** and
  **`GetBacklights()`** switch and read the two LED backlights behind the subject
  (`Backlight.Bottom` = relay 1, `Backlight.Top` = relay 2) on the USB relay module
  attached to the server machine. Both return a `BacklightStatus` (`connected`,
  `backlightBottom`, `backlightTop`). The capture flows switch both backlights on
  right before the high-resolution photo and off as soon as a frame is accepted, so
  these calls are for test switches, not for the photo itself. A server without the
  module answers `SetBacklight` with `FAILED_PRECONDITION` ("USB relay module not
  connected") and reports `connected = false`.
- **`SettingsProcessor.SetLedsOffForPhoto(bool value)`** switches the lights-off
  photo mode: the chosen camera's ring shows for one second, then all column LEDs go
  off before the camera opens and the photo is lit by the backlights only (for
  filtered or polarised setups, and to keep the column out of reflections). It applies
  to the automatic and the manual flow. `LoadSettings` reports it as
  `leds_off_for_photo` (field 41). The existing glasses mode (`SetGlassesLightsOff`)
  is the "only for glasses wearers" variant: with the new mode off, the lights go off
  only once glasses are detected on the first valid frame.
- **`KioskSettingsDto`** (from `LoadSettings`) now also carries `ledsOffForPhoto`,
  and the settings that could only be set, never read back, since 1.5.0:
  `glassesLightsOff`, `ofiqChecks`, `ledLayout`, `focusColor` and
  `focusIntensity`. A server without a field reports the default ("strip",
  "00FF00", 78, false).
- **`CalibrationProcessor.CalibrateByPerson()`** works out the camera positions from a
  person standing in front of the column (server 1.1.15, image 2.0.14). The person
  stands straight at the normal photo distance, looks ahead and holds still; the server
  scans the column three times (about ten seconds) and orders the cameras by where each
  one sees the face. It returns a `PersonCalibrationResult` (`success`, `message`,
  `rounds`, `cameras` with `proposedPosition`, `faceHeight`, `roundsSeen`). The result is
  a proposal: nothing is stored until you send `result.ToCalibration()` to
  `SetCalibration`. When the answer is not unambiguous `success` is false and `message`
  says what to change. An older server answers `UNIMPLEMENTED`.
- **`SettingsProcessor.SetCameraOrderingMode(string mode)`** sets the ordering mode by
  name: `"manual"`, `"automatic"` or `"person"` (the saved positions, worked out with
  `CalibrateByPerson`). The `bool` overload stays. `LoadSettings()` reports
  `cameraOrderingMode`; `CameraOrderingMode` has a `mode` field. Both are empty from an
  older server.
- `ILightProcessor.SetBacklight` / `GetBacklights`,
  `ICalibrationProcessor.CalibrateByPerson` and
  `ISettingsProcessor.SetLedsOffForPhoto` / `SetCameraOrderingMode(string)` have
  default bodies, like the members added in 1.5: an implementation written against
  1.5.2 still loads and throws `NotSupportedException` for them until it implements
  them.
- Server behaviour fix, no API change: `CameraProcessor.SetExposureAutoPriority(true)`
  now really leaves the camera in automatic exposure. Servers before 1.1.15 wrote the
  manual exposure value right after switching to automatic, which put the camera
  straight back to manual. On the kiosk boards the flag now maps to the camera's
  V4L2 menu (3 = aperture priority, 1 = manual); before, `true` selected manual
  and `false` was refused. Fresh server installs now default to automatic exposure
  and automatic white balance, which gave the best photos with filtered lenses,
  lights-off photos and room light; existing installs keep their stored values.
- **Background method `withoutbg` replaces `rembg`** (server 1.1.15, image 2.0.14).
  `SettingsProcessor.SetBackgroundMethod("withoutbg")` selects the withoutBG Open
  Model: the best edges on hair and beard, and it keeps dark clothing that `rembg`
  erased. About 1.5 s per photo on a laptop CPU. `"rembg"` is still accepted and now
  runs withoutBG; the response and `LoadSettings().backgroundMethod` report
  `"withoutbg"`. Servers before 1.1.15 / image 2.0.14 know `"rembg"` but refuse
  `"withoutbg"` with `INVALID_ARGUMENT`. No library change is needed: the method is
  a string. The model is built with DINOv3 (Apache-2.0 + Meta DINOv3 License).
- **Server behaviour change, no API change: face recognition compares the face.**
  `KioskProcessor.FaceRecognition` used to squash the whole photo to the model's input
  size. Servers 1.1.15 / image 2.0.14 find the face on the full photo, cut a square
  around it and compare only that (without a face the whole photo is used, as before);
  the Windows server and the kiosk image now return identical distances. Distances
  therefore differ from older servers: a threshold you calibrated yourself needs
  recalibrating. `threshold = 0` still uses the server's default for the model and
  metric. Measured with the new comparison on 36 same-person kiosk pairs, 41
  same-person everyday pairs and 3,244 pairs of different people, these thresholds
  accept every same-person kiosk pair (Facenet512 with cosine also every everyday
  pair):

  | Model | cosine | euclidean | euclidean L2 | different people accepted |
  |---|---|---|---|---|
  | Facenet512 | 0.42 | 22.0 | 0.92 | about 0.2 % |
  | SFace | 0.45 | 6.5 | 0.95 | about 0.2 % |
  | Dlib | 0.07 | 0.54 | 0.38 | about 1 % |

  Facenet512 with cosine was the best all-round choice and is now the operator app's
  default.

Needs a server that supports these: Windows server 1.1.15 or kiosk image 2.0.14 and
later; older servers answer the new RPCs with `UNIMPLEMENTED`.

## Repository note, 04-10-2026 (operator app 1.1.15)

Release 1.5.3 carries `FaceSnapOperatorSetup-1.1.15.exe` (the installer moved from
1.5.2), and the sources in `flutter_apps/` match it. Most of it needs Windows server
1.1.15 or kiosk image 2.0.14; against an older server the new controls say so and
fall back.

- **Backlights.** The Lighting page has a "Backlights" card: one switch per
  backlight (bottom = relay 1, top = relay 2) on the USB relay module, with the state
  read back from the module, a note when no module is connected or the server is
  older, and Refresh. Before the app force-stops a server on this PC it switches the
  backlights off.
- **Lights-off photo mode.** A Lighting page switch for `leds_off_for_photo` (also a
  fleet settings profile key); the glasses switch is labelled as the "only for
  glasses wearers" variant.
- **Face recognition.** The servers now compare the face region (see 1.5.3), so the
  page's thresholds were recalibrated (the table above) and its slider ranges follow
  them. The page now opens on Facenet512 with cosine at 0.42 (was Dlib).
- **Calibration by a person.** The Calibration page offers Manual, Automatic and By a
  person. "By a person" shows the instructions and a start button; a successful result
  fills the position boxes as a proposal to check and save, a refused one shows the
  server's reason in amber.
- **Background erasing.** The Photo page offers withoutBG instead of rembg; "rembg"
  is listed only while an older server reports it.
- **Capture page.** A capture that ended without a photo shows the server's reason as
  an amber "!" row instead of a grey information row.
- **Kiosk page.** The periodic network scan no longer freezes the window (it stalled
  the UI for 0.5–4 s several times a minute): the sweep runs on its own isolate and the
  30-second re-scan skips it. A clean, unprovisioned board is found with "Search
  again" or on the Updater page.
- **About page.** The library list matches what the servers and the app use now
  (MediaPipe as FaceSnap's native build, withoutBG, the FrameFind glasses classifier,
  the .NET runtime and gRPC for .NET of the kiosk image, package_info_plus, …).
- Updated packages: dartssh2 4.1.0, package_info_plus 10.2.2, protobuf 6.1.0. The
  Dart stubs in `flutter_apps/face_snap_grpc` are regenerated for the new RPCs
  (`SetBacklight`, `GetBacklights`, `SetLedsOffForPhoto`, `CalibrateByPerson`,
  `SetCameraOrderingMode` with a mode name).

Tests (240 in total): `backlights_test.dart`, `leds_off_for_photo_test.dart`,
`face_recognition_thresholds_test.dart`, `calibration_by_person_test.dart`,
`background_method_test.dart` and `capture_give_up_test.dart`, against in-process
fake servers where a server is involved.

## Repository note, 01-10-2026 (operator app 1.1.14)

Release 1.5.2 now carries `FaceSnapOperatorSetup-1.1.14.exe`, and the sources in
`flutter_apps/operator_app` match it. When the first load of the Camera,
Calibration or Monitoring page failed (for example because the server or the
camera column was still starting), its error line stayed on screen even after the
page had loaded successfully ("kiosk not reachable — is the server running?").
Each page now removes its own load error once a load succeeds; a newer, different
error stays. The Calibration page also showed that error raw
(`ParallelWaitError: gRPC Error …`) and now shows the readable message. Tested in
`test/load_error_recovery_test.dart` against a fake server that refuses the first
load.

## Version 1.5.2, 01-10-2026

Background erasing strength. Replace `GrpcLibrary.dll` (and `GrpcLibrary.xml`);
the assembly version stays 1.0.0.0 and everything in 1.5.1 is unchanged — this
release only adds.

- **`SettingsProcessor.SetBackgroundStrength(int value)`** sets how strongly the
  background is erased, for every background method: 1 (mild) keeps more of a soft
  edge (fine hair, at the risk of a faint background-coloured fringe), 5 (heavy)
  drops faint edge pixels and pulls the edge in (a cleaner, harder edge, at the risk
  of thinning hair). 3 is the original behaviour and the default. It returns the
  strength the server applied (`BackgroundStrength.backgroundStrength`); a value
  outside 1–5 is refused with `INVALID_ARGUMENT`.
- **`KioskSettingsDto.backgroundStrength`** (from `LoadSettings`) is the current
  strength. A server from before this setting reports 3 — it erases the original
  way — and refuses `SetBackgroundStrength` with `UNIMPLEMENTED`.
- `ISettingsProcessor.SetBackgroundStrength` has a default body, like the members
  added in 1.5: an implementation written against 1.5.1 still loads and throws
  `NotSupportedException` for it until it implements it.

Needs a server that supports the setting: Windows server 1.1.14 or kiosk image
2.0.13 and later. These servers also fall back to the MediaPipe result when MODNet
keeps too little of the face, and remove faint leftovers of bystanders.

## Repository note, 01-10-2026 (operator app 1.1.13 sources)

The operator app sources in `flutter_apps/` are now at version 1.1.13:

- **Background erasing strength.** The Photo page shows an "Erasing strength" row
  (1 Mild … 5 Heavy) whenever background erasing is switched on. 3 is the
  existing look; 1–2 keep soft edges and fine hair, 4–5 drop faint edges and pull
  the edge in slightly. It uses the new `SetBackgroundStrength` RPC and the
  `background_strength` field of `LoadSettingsResponse` (field 40), both in the
  regenerated Dart stubs in `flutter_apps/face_snap_grpc`. Servers from before
  this change report 0, which the app shows as 3; choosing another level then
  springs back with the server's error. Fleet settings profiles can set
  `kiosk.background_strength` (1–5).
- **Fast camera selection.** The Media Foundation switch on the Camera page can be
  used again for a server running on the same PC; for a kiosk board it stays
  disabled, with a note explaining why.

Tests: `test/photo_strength_test.dart` and `test/camera_page_test.dart`, both
against an in-process fake gRPC server (`grpc` is now a dev dependency).

## Repository note, 01-10-2026 (operator app 1.1.12)

Release 1.5.0 now carries `FaceSnapOperatorSetup-1.1.12.exe`. The Updater page no
longer rolls an update back when the board has no LED board or cameras attached:
boards are often updated before they are built into a kiosk, so missing hardware is
reported as a warning ("LED board: NOT detected"). Any other LED-board or camera
error in the new server's log still rolls the update back. The log check is
`serverLogErrors()` / `kHardwareAbsentRe` in
`flutter_apps/operator_app/lib/updater/kiosk.dart`, tested in
`test/server_log_check_test.dart`.

## Version 1.5.1, 01-10-2026

A compatibility fix for applications built against GrpcLibrary 1.4 (and a fix for
the 1.5.0 quick start). Replace `GrpcLibrary.dll` (and `GrpcLibrary.xml`); the
assembly version stays 1.0.0.0 and the wire contract is unchanged.

- **One address per processor again.** In 1.5.0 every processor constructor
  re-pointed one process-wide channel, so an application with processors for two
  kiosks sent every call to the kiosk constructed last, and `new KioskProcessor()`
  reset the address to localhost (also after `GrpcChannelProvider.SetAddress`, the
  documented quick start). Now a processor constructed with an address keeps that
  address; one constructed without an address uses the shared channel;
  `GrpcChannelProvider.SetAddress` re-points every existing processor; and
  constructing a processor never changes the shared address.
- **Older interface implementations load again.** The 24 interface members added
  in 1.5 (`ICameraProcessor.SetAutofocus`, `ISettingsProcessor.SetPhotoFormat`, …)
  have default bodies. An application's own implementation or test double written
  against the 1.4 interfaces compiles and loads (1.5.0: `TypeLoadException`); it
  throws `NotSupportedException` for a newer member until it implements it.
- `csharp_sample` uses `GrpcChannelProvider.SetAddress` plus processors without an
  address.

Still different from 1.4 (unchanged since 1.5.0):

- **Face-recognition models.** The server replaced VGG-Face and ArcFace with
  Facenet512 and SFace under the same numbers: `Model` value 1 is `Facenet512`
  (was `VggFace`), value 2 is `Sface` (was `ArcFace`). An application built
  against 1.4 that asks for VGG-Face gets Facenet512, with different thresholds;
  rebuilding against 1.5 requires the new names.
- `SettingsProcessor.SetEyeGlassesCheck` calls the server (1.4 returned `false`
  without a call).
- Applications built against 1.3 or older: `CalibrationProcessor.SetCalibration`
  takes a list of `CalibrationData` since 1.4, and 1.0's `*Request` message types
  were replaced by `Empty` in 1.1.

## Repository note, 28-09-2026

Release 1.5.0 now carries `FaceSnapOperatorSetup-1.1.11.exe`. The operator app has
a new icon (the brain mark on a green tile) on the app and on the setup, and the
installer opens with an intro page; the artwork lives in
`flutter_apps/operator_app/installer_art/` (regenerate with `make_installer_art.py`).
No SDK or behaviour changes.

## Repository note, 24-09-2026

The fleet updater is now a page of the operator app (**Updater**, shown in Developer
mode) and its source is part of this repository again: `flutter_apps/operator_app/
lib/updater/` (deploy, remove, backup and restore engines, the kiosk board contract,
batch orchestration) with headless command-line tools under `bin/`. The separate
`FaceSnapUpdaterSetup` installer is retired; release 1.5.0 now carries
`FaceSnapOperatorSetup-1.1.9.exe` only. The operator app also lists the servers on
the network directly on its Kiosk page, and the Dart SDK gained
`GrpcChannelProvider.openChannel(host, port)` for talking to a server other than
the shared one.

## Repository note, 17-09-2026

The Dart client SDK is now part of this repository: `flutter_apps/face_snap_grpc/`
(generated gRPC stubs for all six services, `GrpcChannelProvider`, the
`startAutomaticCapture()` / `startManualCapture()` stream helpers and command-line
examples). The operator app in `flutter_apps/operator_app/` depends on it by path,
so the app now builds straight from a clone. Capture photo events carry
`firstChunkAt` / `lastChunkAt` timestamps (used by the operator app's new Capture
timing card).



## Repository note, 16-09-2026

The updater app's source (`flutter_apps/updater_app/`) was removed — it is a fleet
provisioning tool, not an SDK client example. Releases keep shipping its signed
installer (`FaceSnapUpdaterSetup-<version>.exe`).

The .NET MAUI demo app (`maui_app/`) was removed: it was superseded by the Flutter
operator app and by the new minimal C# console sample in `csharp_sample/`, which
walks the getting-started flow (connect, settings, automatic capture, face
recognition) against the bundled release DLLs.

With the repository going public, its git history was restarted from a fresh
initial commit.



## Version 1.5, Date 14-09-2026

GrpcLibrary refreshed from the Server 2.0 protos, with SDK wrappers added for the
full API surface:

### FaceRecognition — SFace model
The `Model` enum now includes `Sface` next to `Dlib` and `Facenet512`.

### KioskProcessor.StreamPreview(index, maxSeconds)
Live preview: streams complete JPEG frames (~15 fps) from one camera until the
enumeration stops or `maxSeconds` elapses. One camera at a time — USB2 bandwidth is
shared with captures.

### SettingsProcessor
`SetLedLayout("strip"/"ring")`, `SetFocusLight(colorHex, intensityPercent)`,
`SetOfiqChecks(bool)`, `SetGlassesLightsOff(bool)`. `SetBlurBackground` is now
`[Obsolete]` — the server dropped that RPC in favour of background erasing
(`SetBackgroundMethod`/`SetBackgroundColor`).

### LightProcessor
`SetGlareSafeLights(index)` (all-on lighting safe for glasses) and
`AutoTuneWhitePoint()` (streamed closed-loop white-point tuning via the light sensor).

### MonitoringProcessor.GetLightMeasurement()
One OPT4048 reading: lux, CCT and CIE 1931 chromaticity.

The release additionally ships the signed Windows installer of the operator app
(`FaceSnapOperatorSetup-1.1.0.exe`).



## Version 1.0, Date 09-03-2024

Inital release. 

Documentation: See https://gridler-tech.github.io/face_snap/index.html





## Version 1.1, Date 18-07-2024

Added functionality:

### GetFocusedCameraIndex(timeout)
This method requests the focused Camera index (where the user is best positioned in front of).

Docs see: https://gridler-tech.github.io/face_snap/api/GrpcLibrary.KioskProcessor.html#GrpcLibrary_KioskProcessor_GetFocusedCameraIndex_System_Int32_


### GetHighResolutionImageFromCameraIndex(index, timeout)
This method requests a high resolution image from a specific camera index.

Docs see: https://gridler-tech.github.io/face_snap/api/GrpcLibrary.KioskProcessor.html#GrpcLibrary_KioskProcessor_GetHighResolutionImageFromCameraIndex_System_Int32_System_Int32_


### GetHighResolutionImageWithIcaoChecksFromCameraIndex(index, timeout, eyesCheck, lipsCheck)
This method requests a high resolution image from a specific camera index with ICAO checks.

Docs see: https://gridler-tech.github.io/face_snap/api/GrpcLibrary.KioskProcessor.html#GrpcLibrary_KioskProcessor_GetHighResolutionImageWithIcaoChecksFromCameraIndex_System_Int32_System_Int32_System_Boolean_System_Boolean_


### GetKioskInfo()
This method requests the kiosk information.

Docs see: https://gridler-tech.github.io/face_snap/api/GrpcLibrary.KioskProcessor.html#GrpcLibrary_KioskProcessor_GetKioskInfo


### SetAllLights(bool)
This method sets all column lights (on or off)

Docs see: https://gridler-tech.github.io/face_snap/api/GrpcLibrary.LightProcessor.html#GrpcLibrary_LightProcessor_SetAllLights_System_Boolean_


### SetLightAtCameraIndex(index)
This method sets a light at given camera index

Docs see: https://gridler-tech.github.io/face_snap/api/GrpcLibrary.LightProcessor.html#GrpcLibrary_LightProcessor_SetLightAtCameraIndex_System_Int32_


### SetLightOffAtCameraIndex(index)
This method switch a light off at given camera index

Docs see: https://gridler-tech.github.io/face_snap/api/GrpcLibrary.LightProcessor.html#GrpcLibrary_LightProcessor_SetLightOffAtCameraIndex_System_Int32_

