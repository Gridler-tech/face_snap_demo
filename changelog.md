# Face Snap SDK change log



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

