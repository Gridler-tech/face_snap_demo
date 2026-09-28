; Inno Setup installer for the FaceSnap Operator app (Flutter, Windows) ONLY.
; This is the public download attached to Gridler-tech/face_snap_demo releases;
; unlike face_snap_server.iss it contains no server, weights or kiosk app.
;
; Compile with the Inno Setup compiler (ISCC), passing the staged build:
;   ISCC.exe /DFlutterOperatorDir="C:\Users\<user>\builds\face_snap\flutter_operator" ^
;            /DAppVersion=1.2.3 face_snap_operator.iss
;
; Optional defines:
;   /DCompressMode=none   fast test build (store, no compression)
;   /DSign                sign the setup + uninstaller; pass the signtool command too:
;                         "/Ssigntool=signtool.exe sign /n Gridler /fd sha256 /tr http://timestamp.digicert.com /td sha256 $f"
;                         (sign the bundled exes BEFORE compiling)
;
; FlutterOperatorDir = the staged flutter Release folder (operator_app.exe +
; flutter_windows.dll + data\ + the three VC++ runtime DLLs).

; NOTE: keep /DAppVersion equal to the version: in this app's pubspec.yaml —
; the app displays the pubspec version in its UI (package_info_plus), so a
; mismatched define ships an installer whose app shows a different version.
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef FlutterOperatorDir
  #define FlutterOperatorDir "..\..\..\..\builds\face_snap\flutter_operator"
#endif
#ifndef CompressMode
  #define CompressMode "lzma2/max"
#endif

#define AppName "FaceSnap Operator"
#define AppPublisher "Gridler"
#define ExeName "operator_app.exe"

[Setup]
AppId={{3D8A6C2E-51B7-4F0D-8E2A-FACE5NAP0002}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\FaceSnapOperator
DefaultGroupName=FaceSnap Operator
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#ExeName}
; Look: the setup exe carries the app's own icon (icon A: brain mark on a green
; tile); a welcome page with the side image, the icon in the header of the other
; pages. Every standard DPI scale is supplied; Inno picks the best match.
; Artwork: installer_art\ (regenerate with make_installer_art.py).
SetupIconFile=windows\runner\resources\app_icon.ico
WizardStyle=modern
DisableWelcomePage=no
WizardImageFile=installer_art\wizard_side_164x314.bmp,installer_art\wizard_side_192x386.bmp,installer_art\wizard_side_246x459.bmp,installer_art\wizard_side_273x556.bmp,installer_art\wizard_side_328x604.bmp,installer_art\wizard_side_355x700.bmp,installer_art\wizard_side_410x797.bmp
WizardSmallImageFile=installer_art\wizard_small_55.bmp,installer_art\wizard_small_64.bmp,installer_art\wizard_small_83.bmp,installer_art\wizard_small_92.bmp,installer_art\wizard_small_110.bmp,installer_art\wizard_small_119.bmp,installer_art\wizard_small_138.bmp
OutputBaseFilename=FaceSnapOperatorSetup-{#AppVersion}
Compression={#CompressMode}
SolidCompression=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; The operator app needs no admin rights: default to a per-user install
; (Local AppData\Programs); the dialog still allows an all-users install.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
#ifdef Sign
SignTool=signtool
SignedUninstaller=yes
#endif

[Messages]
; The intro (welcome) page. %n = line break. Keep ASCII: this file has no BOM.
WelcomeLabel1=Welcome to FaceSnap Operator {#AppVersion}
WelcomeLabel2=The operator console for FaceSnap photo kiosks:%n%n  -  find the kiosks on the network and connect to one%n  -  capture photos and review every ICAO quality check%n  -  tune camera, lighting and photo settings, calibrate the cameras%n  -  update the kiosk servers (Updater page, in developer mode)%n%nClose FaceSnap Operator if it is running before you continue.
FinishedHeadingLabel=FaceSnap Operator is installed

[Files]
; The staged Flutter Release folder (exe + flutter_windows.dll + data + VC++ DLLs).
Source: "{#FlutterOperatorDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: checkedonce

[Icons]
Name: "{group}\FaceSnap Operator"; Filename: "{app}\{#ExeName}"
Name: "{group}\Uninstall FaceSnap Operator"; Filename: "{uninstallexe}"
Name: "{autodesktop}\FaceSnap Operator"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeName}"; Description: "Start FaceSnap Operator now"; Flags: nowait postinstall skipifsilent

; The app keeps its own settings in %APPDATA%\FaceSnapOperator (config.json,
; captures); the uninstaller leaves them in place on purpose.
