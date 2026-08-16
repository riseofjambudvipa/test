[Setup]
AppName=CapStudio
AppVersion=1.0.0
AppPublisher=CapStudio Team
AppPublisherURL=https://capstudio.app
AppSupportURL=https://capstudio.app/support
AppUpdatesURL=https://capstudio.app/releases
AppId={{8F3A1C2E-7D4B-4E9F-A2C1-B5D6E8F0A3C7}
DefaultDirName={autopf}\CapStudio
DefaultGroupName=CapStudio
OutputDir=.
OutputBaseFilename=CapStudio_Setup_Windows_1.0.0
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Install for current user only — no UAC prompt required
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
UninstallDisplayIcon={app}\capstudio.exe
UninstallDisplayName=CapStudio
VersionInfoVersion=1.0.0.0
VersionInfoCompany=CapStudio Team
VersionInfoDescription=CapStudio Installer
VersionInfoCopyright=Copyright (C) 2024 CapStudio Team
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\CapStudio"; Filename: "{app}\capstudio.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall CapStudio"; Filename: "{uninstallexe}"
Name: "{commondesktop}\CapStudio"; Filename: "{app}\capstudio.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Run]
Filename: "{app}\capstudio.exe"; Description: "{cm:LaunchProgram,CapStudio}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Remove user data directory only if user confirms; do not auto-delete
Type: dirifempty; Name: "{localappdata}\CapStudio"
