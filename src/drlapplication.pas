{$INCLUDE drl.inc}
{
-------------------------------------------------------
DRLAPPLICATION.PAS -- DRL application and runtime policy
Copyright (c) 2002-2025 by Kornel Kisielewicz
-------------------------------------------------------
}
unit drlapplication;
interface

uses
  SysUtils, vapp, viorl, vluasystem, vrlapp,
  drlbase;

type
  TDRLApplication = class;

// TDRLRuntime
//
// Architectural boundary: owns DRL's runtime and data-generation lifetime,
// including module policy, services, Lua/content reloads, and the active
// session. Per-playthrough state belongs in TDRLSession; TDRL temporarily
// crosses this boundary
type TDRLRuntime = class( TRLRuntime )
  private
    FApplication : TDRLApplication;
    FDRL         : TDRL;
    FGameFailed  : Boolean;
  protected
    function CreateIO : TIORL; override;
    function CreateLua : TLuaSystem; override;
    procedure PrepareGameData; override;
    procedure InitializeGameData; override;
    function RunGame : TVRunResult; override;
    procedure ShutdownGameData; override;
    procedure ResetGameData; override;
    procedure GameException( aException : Exception ); override;
  public
    constructor Create( aApplication : TDRLApplication; const aPaths : TGamePaths; var aConfiguration : TObject ); reintroduce;
    destructor Destroy; override;
  end;

// TDRLApplication
//
// Architectural boundary: owns DRL process-level launch policy, options,
// configuration factories, utility selection, and top-level error handling.
// Runtime services and game state belong below this class.
type TDRLApplication = class( TRLApplication )
  private
    FWorkshopID : AnsiString;
  protected
    procedure DefineOptions; override;
    procedure ValidateOptions; override;
    procedure BeforeConfiguration( var aPaths : TGamePaths ); override;
    function CreateConfiguration( var aPaths : TGamePaths ) : TObject; override;
    procedure ApplyOptions; override;
    procedure BeforeDiagnostics; override;
    function CreateRuntime( const aPaths : TGamePaths; var aConfiguration : TObject ) : TRLRuntime; override;
    function ExecuteGameUtility : Boolean; override;
    procedure DestroyGame; override;
    procedure ApplicationException( aException : Exception ); override;
  end;

implementation

uses
  {$IFDEF WINDOWS}Windows, vos,{$ENDIF}
  vdebug, vlog, vutil,
  dfdata, drlconfig, drlconfiguration, drlgfxio, drlio, drlua, drltextio,
  drlworkshop;

{$IFDEF WINDOWS}
var
  ConsoleHandle : HWND;
  ConsoleTitle  : AnsiString;

function ConsoleEventProc( aCtrlType : DWORD ) : Bool; stdcall;
begin
  Result := True;
end;
{$ENDIF}

{ TDRLRuntime }

constructor TDRLRuntime.Create( aApplication : TDRLApplication; const aPaths : TGamePaths; var aConfiguration : TObject );
begin
  FApplication := aApplication;
  inherited Create(aPaths, aConfiguration);
  FDRL := TDRL.Create(Self);
  drlbase.DRL := FDRL;
end;

destructor TDRLRuntime.Destroy;
begin
  FreeAndNil(FDRL);
  drlbase.DRL := nil;
  drlbase.Lua := nil;
  FreeAndNil(Config);
  inherited Destroy;
end;

function TDRLRuntime.CreateIO : TIORL;
begin
  if GraphicsVersion then
    Result := TDRLGFXIO.Create
  else
    Result := TDRLTextIO.Create;
end;

function TDRLRuntime.CreateLua : TLuaSystem;
begin
  Result := TDRLLua.Create;
end;

procedure TDRLRuntime.PrepareGameData;
var iConfig     : TDRLConfig;
    iModulePath : AnsiString;
begin
  FGameFailed := False;
  if ForceRestart <> '' then
  begin
    FDRL.Modules.ScanModules;
    CoreModuleID := ForceRestart;
  end;
  ForceRestart := '';
  CoreModuleID := FDRL.Modules.Validate(CoreModuleID);
  if CoreModuleID = '' then
    FDRL.RunModuleChoice;

  if not DirectoryExists(Paths.WritePath + 'user') then
    CreateDir(Paths.WritePath + 'user');
  if not DirectoryExists(Paths.WritePath + 'user' + PathDelim + CoreModuleID) then
    CreateDir(Paths.WritePath + 'user' + PathDelim + CoreModuleID);
  iModulePath := Paths.WritePath + 'user' + PathDelim + CoreModuleID + PathDelim;
  FPaths.ModuleUserPath := iModulePath;
  FApplication.FPaths.ModuleUserPath := iModulePath;
  if not DirectoryExists(iModulePath + 'screenshot') then
    CreateDir(iModulePath + 'screenshot');
  if not DirectoryExists(iModulePath + 'mortem') then
    CreateDir(iModulePath + 'mortem');
  if not DirectoryExists(iModulePath + 'backup') then
    CreateDir(iModulePath + 'backup');

  FDRL.Initialize;

  {$IFDEF WINDOWS}
  if not GraphicsVersion then
  begin
    if Option_LockBreak then
    begin
      SetConsoleCtrlHandler(nil, False);
      SetConsoleCtrlHandler(@ConsoleEventProc, True);
    end;
    if Option_LockClose then
    begin
      ConsoleHandle := FindWindow(nil, PChar(ConsoleTitle));
      RemoveMenu(GetSystemMenu(ConsoleHandle, False), SC_CLOSE, MF_GRAYED);
      DrawMenuBar(ConsoleHandle);
    end;
  end;
  {$ENDIF}

  iConfig := TDRLConfig.Create(Paths.ConfigurationPath, True);
  FreeAndNil(Config);
  Config := iConfig;
  FDRL.PrepareLoad;
end;

procedure TDRLRuntime.InitializeGameData;
begin
  FDRL.Load;
end;

function TDRLRuntime.RunGame : TVRunResult;
begin
  FDRL.Run;
  if ForceRestart <> '' then
    Result := VRR_RELOAD_DATA
  else
    Result := VRR_QUIT;
end;

procedure TDRLRuntime.ShutdownGameData;
begin
  if not FGameFailed then
    FDRL.UnLoad;
end;

procedure TDRLRuntime.ResetGameData;
begin
  FDRL.Reset;
end;

procedure TDRLRuntime.GameException( aException : Exception );
begin
  FGameFailed := True;
end;

{ TDRLApplication }

procedure TDRLApplication.DefineOptions;
begin
  AddFlag('god', #0, 'Enable god mode.');
  AddValueOption('publish', #0, 'WORKSHOP_ID', 'Publish WORKSHOP_ID to Steam Workshop.');
  AddFlag('no-sound', #0, 'Disable sound and music.');
  AddFlag('windowed', #0, 'Force windowed mode.');
  AddFlag('graphics', #0, 'Force graphical mode.');
  AddFlag('console', #0, 'Force console mode.');
  AddValueOption('name', #0, 'PLAYER_NAME', 'Use PLAYER_NAME for every game.');
  AddValueOption('module', #0, 'MODULE_ID', 'Use MODULE_ID as the core module.');
end;

procedure TDRLApplication.ValidateOptions;
begin
  inherited ValidateOptions;
  if HasOption('publish') and (GetOptionValue('publish') = '') then
    FailOption('--publish requires a non-empty WORKSHOP_ID');
end;

procedure TDRLApplication.BeforeConfiguration( var aPaths : TGamePaths );
begin
  ColorOverrides := nil;

  {$IFDEF WINDOWS}
  ConsoleTitle := Self.Title;
  SetConsoleTitle(PChar(ConsoleTitle));
  Sleep(40);
  DisableAccessibilityShortcuts;
  {$ENDIF}

  if HasOption('god') then
  begin
    GodMode := True;
    if not HasOption('config') then
      aPaths.ConfigurationPath := aPaths.ResourcePath + 'godmode.lua';
  end;

  ForceNoAudio  := HasOption('no-sound');
  ForceWindowed := HasOption('windowed');
  ForceGraphics := HasOption('graphics');
  ForceConsole  := HasOption('console');

  if ForceGraphics then GraphicsVersion := True;
  if ForceConsole then GraphicsVersion := False;
end;

function TDRLApplication.CreateConfiguration( var aPaths : TGamePaths ) : TObject;
var iConfiguration : TDRLConfiguration;
begin
  iConfiguration := nil;
  try
    iConfiguration := TDRLConfiguration.Create;
    Configuration := iConfiguration;
    if FileExists(aPaths.SettingsPath) then
      iConfiguration.Read(aPaths.SettingsPath)
    else
      iConfiguration.Write(aPaths.SettingsPath);

    Config := TDRLConfig.Create(aPaths.ConfigurationPath, False);
    aPaths.DataPath  := Config.Configure('DataPath', aPaths.DataPath);
    aPaths.WritePath := Config.Configure('WritePath', aPaths.WritePath);
    aPaths.ScorePath := Config.Configure('ScorePath', aPaths.ScorePath);
    CoreModuleID := iConfiguration.GetString('default_module');
    Result := iConfiguration;
  except
    FreeAndNil(Config);
    FreeAndNil(iConfiguration);
    Configuration := nil;
    raise;
  end;
end;

procedure TDRLApplication.ApplyOptions;
begin
  if HasOption('name') then
  begin
    ForcePlayerName := GetOptionValue('name');
    Option_AlwaysName := ForcePlayerName;
  end;
  if HasOption('module') then
    CoreModuleID := GetOptionValue('module');
  if HasOption('publish') then
    FWorkshopID := GetOptionValue('publish');
end;

procedure TDRLApplication.BeforeDiagnostics;
begin
  if FWorkshopID <> '' then
    Logger.AddSink(TConsoleLogSink.Create(LOGINFO, True));
end;

function TDRLApplication.CreateRuntime( const aPaths : TGamePaths; var aConfiguration : TObject ) : TRLRuntime;
begin
  Result := TDRLRuntime.Create(Self, aPaths, aConfiguration);
end;

function TDRLApplication.ExecuteGameUtility : Boolean;
begin
  Result := FWorkshopID <> '';
  if Result then
    WorkshopPublish(FWorkshopID);
end;

procedure TDRLApplication.DestroyGame;
begin
  if Runtime = nil then
    FreeAndNil(Config);
  inherited DestroyGame;
  Configuration := nil;
end;

procedure TDRLApplication.ApplicationException( aException : Exception );
begin
  if Assigned(Logger) then Logger.Flush;
  if not EXCEPTEMMITED then
    EmitCrashInfo(aException.Message, False);
end;

end.
