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
