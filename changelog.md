# Face Snap SDK change log



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

