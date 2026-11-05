#ifndef AppVersion
  #error AppVersion must be provided by the build
#endif

[Setup]
AppId={{5A0A2754-2B04-4CDE-BEAC-9AC164954412}
AppName=Mihomote
AppVersion={#AppVersion}
DefaultDirName={autopf}\Mihomote
DefaultGroupName=Mihomote
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=mihomote-windows-setup
Compression=lzma2
SolidCompression=yes
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\mihomote.exe

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Mihomote"; Filename: "{app}\mihomote.exe"
