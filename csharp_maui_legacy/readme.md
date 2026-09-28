# PhotoColumnApp — version 1 operator app (.NET MAUI) — LEGACY

> **Legacy / unsupported.** This is the original version-1 operator app for the
> FaceSnap kiosk, frozen at its final state (July 2026). It has been superseded
> by the Flutter operator app (`../flutter_apps/operator_app`); for new
> integrations start from `../csharp_sample` and the current SDK in
> `../library`. It is kept here for customers who built on the v1 MAUI code.
>
> - .NET MAUI, net8.0 (Windows / Android / iOS / Mac Catalyst).
> - Builds against the SDK DLLs frozen in its own `library/` folder (July 2026
>   contract) — these still work against current servers, but new server
>   features since then are not exposed here.
> - The Windows packaging certificate is not included; Visual Studio will
>   offer to create a temporary one when you publish.
> - Bug fixes and new features land only in the Flutter app and `csharp_sample`.

---

[![.NET build and run tests](https://github.com/Gridler-tech/face_snap_demo/actions/workflows/dotnet.yml/badge.svg)](https://github.com/Gridler-tech/face_snap_demo/actions/workflows/dotnet.yml)

# Info

This repository will provide an example .NET maui implementation of Face Snap

## Face snap documentation

The library documentation can be found here: https://gridler-tech.github.io/face_snap/