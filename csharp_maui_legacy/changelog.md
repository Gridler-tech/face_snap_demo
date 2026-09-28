# Face Snap SDK change log



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

