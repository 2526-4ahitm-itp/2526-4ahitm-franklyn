#define RepoRoot AddBackslash(SourcePath) + "..\..\.."
#define VersionFile FileOpen(RepoRoot + "\VERSION")
#define AppVersion Trim(FileRead(VersionFile))
#expr FileClose(VersionFile)

[Setup]
AppId={{73249FFA-D391-4F0D-B42B-C6447453E1AC}
AppName=Franklyn
AppVersion={#AppVersion}
AppPublisher=Franklyn
PrivilegesRequired=lowest
DefaultDirName={autopf}\Franklyn
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ChangesEnvironment=yes
SetupIconFile=franklyn.ico
UninstallDisplayIcon={app}\franklyn.exe
UninstallDisplayName=Franklyn
OutputDir={#RepoRoot}
OutputBaseFilename=franklyn-sentinel-{#AppVersion}-x86_64-windows-setup

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[Files]
Source: "{#RepoRoot}\dist\*"; DestDir: "{app}"; Excludes: "README.txt"; Flags: ignoreversion recursesubdirs

[Code]
function PathWithout(Paths, Dir: string): string;
var
  Entry: string;
  P: Integer;
begin
  Result := '';
  Paths := Paths + ';';
  while Paths <> '' do
  begin
    P := Pos(';', Paths);
    Entry := Copy(Paths, 1, P - 1);
    Delete(Paths, 1, P);
    if (Trim(Entry) <> '') and (CompareText(RemoveBackslash(Trim(Entry)), RemoveBackslash(Dir)) <> 0) then
    begin
      if Result <> '' then
        Result := Result + ';';
      Result := Result + Entry;
    end;
  end;
end;

function UserPath(): string;
begin
  if not RegQueryStringValue(HKCU, 'Environment', 'Path', Result) then
    Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Paths: string;
begin
  if CurStep = ssPostInstall then
  begin
    Paths := PathWithout(UserPath(), ExpandConstant('{app}'));
    if Paths <> '' then
      Paths := Paths + ';';
    RegWriteExpandStringValue(HKCU, 'Environment', 'Path', Paths + ExpandConstant('{app}'));
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RegWriteExpandStringValue(HKCU, 'Environment', 'Path', PathWithout(UserPath(), ExpandConstant('{app}')));
end;
