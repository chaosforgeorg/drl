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
  SysUtils, vapp, viorl, vluasystem, vrlapp, vstoreinterface, vutil,
  drlbase, drlmodule;

type
  TDRLApplication = class;

// TDRLRuntime
//
// Architectural boundary: owns DRL's runtime and data-generation lifetime,
// including module policy, services, Lua/content reloads, and the active
// session. Per-playthrough state belongs in TDRLSession.
type TDRLRuntime = class( TRLRuntime )
  private
    FSession     : TDRLSession;
    FGameFailed  : Boolean;
    FModules     : TDRLModules;
    FStore       : TStoreInterface;
    FCoreHooks   : TFlags;
    FModuleHooks : TFlags;
    FDataLoaded  : Boolean;
    procedure ApplyConfiguration;
    procedure CreateSession( aInitializeData : Boolean );
    procedure ReleaseSession;
    procedure SafeCallModuleHook( aHook : Byte; const aParams : array of Const );
    procedure UnloadGameData;
  protected
    function CreateIO : TIORL; override;
    function CreateLua : TLuaSystem; override;
    procedure PrepareGameData; override;
    procedure InitializeGameData; override;
    function RunGame : TVRunResult; override;
    procedure ShutdownGameData; override;
    procedure ResetGameData; override;
    procedure HandleGameException( aException : Exception ); override;
  public
    constructor Create( const aPaths : TGamePaths; var aConfiguration : TObject;
      const aModulesFile : AnsiString ); reintroduce;
    destructor Destroy; override;
    procedure Reconfigure;
    property Modules : TDRLModules read FModules;
    property Store : TStoreInterface read FStore;
    property Session : TDRLSession read FSession;
  end;

// TDRLApplication
//
// Architectural boundary: owns DRL process-level launch policy, options,
// configuration factories, utility selection, and top-level error handling.
// Runtime services and game state belong below this class.
type TDRLApplication = class( TRLApplication )
  private
    FWorkshopID  : AnsiString;
    FModulesFile : AnsiString;
  protected
    procedure DefineOptions; override;
    procedure ValidateOptions; override;
    procedure BeforeConfiguration( var aPaths : TGamePaths ); override;
    function CreateConfiguration( var aPaths : TGamePaths ) : TObject; override;
    procedure ApplyOptions; override;
    procedure BeforeDiagnostics; override;
    function CreateRuntime( const aPaths : TGamePaths; var aConfiguration : TObject ) : TRLRuntime; override;
    function ExecuteApplicationCommand : Boolean; override;
    procedure ApplicationException( aException : Exception ); override;
  end;

implementation

uses
  {$IFDEF WINDOWS}Windows, vos,{$ENDIF}
  vdebug, vlog, vlua,
  dfdata, dfhof, dfmap, drlconfig, drlconfiguration, drlgfxio, drlhelp, drlhooks,
  drlio, drlua, drltextio, drlworkshop;

type TDRLConfigurationState = class( TDRLConfiguration )
  private
    FLuaConfig : TDRLConfig;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ReplaceLuaConfig( aConfig : TDRLConfig );
    property LuaConfig : TDRLConfig read FLuaConfig;
  end;

constructor TDRLConfigurationState.Create;
begin
  inherited Create;
  drlconfiguration.Configuration := Self;
end;

destructor TDRLConfigurationState.Destroy;
begin
  if dfdata.Config = FLuaConfig then
    dfdata.Config := nil;
  if drlconfiguration.Configuration = Self then
    drlconfiguration.Configuration := nil;
  FreeAndNil( FLuaConfig );
  inherited Destroy;
end;

procedure TDRLConfigurationState.ReplaceLuaConfig( aConfig : TDRLConfig );
var iPrevious : TDRLConfig;
begin
  if aConfig = nil then
    raise Exception.Create('TDRLConfigurationState requires a Lua configuration');
  iPrevious := FLuaConfig;
  FLuaConfig := aConfig;
  dfdata.Config := FLuaConfig;
  iPrevious.Free;
end;

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

constructor TDRLRuntime.Create( const aPaths : TGamePaths;
  var aConfiguration : TObject; const aModulesFile : AnsiString );
begin
  inherited Create(aPaths, aConfiguration);
  ApplyConfiguration;
  FStore := TStoreInterface.Get;
  FModules := TDRLModules.Create(Paths.DataPath, aModulesFile);
  FModules.ScanModules;
  ModErrors := TStringGArray.Create;
  TDRLIO(IO).Modules := FModules;
  TDRLIO(IO).Store := FStore;
end;

destructor TDRLRuntime.Destroy;
begin
  ReleaseSession;
  UnloadGameData;
  drlbase.Lua := nil;
  TDRLIO(IO).Modules := nil;
  TDRLIO(IO).Store := nil;
  FreeAndNil(ModErrors);
  FreeAndNil(FModules);
  inherited Destroy;
end;

procedure TDRLRuntime.ReleaseSession;
begin
  if TDRLIO(IO).Session = FSession then
    TDRLIO(IO).Session := nil;
  if drlbase.DRL = FSession then
    drlbase.DRL := nil;
  FreeAndNil(FSession);
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
  Result := TDRLLua.Create(FModules, Paths.DataPath);
end;

procedure TDRLRuntime.CreateSession( aInitializeData : Boolean );
begin
  FSession := TDRLSession.Create( Self, FModules, FStore, Paths );
  TDRLIO(IO).Session := FSession;
  drlbase.DRL := FSession;
  if not aInitializeData then Exit;
  FSession.InitializeLevel;
  FSession.SetDataHooks( FCoreHooks, FModuleHooks );
  if not GraphicsVersion then
    (IO as TDRLTextIO).SetTextMap( FSession.Level );
end;

// Phase order: select module and paths; create an initial session shell;
// prepare IO/configuration, then non-Lua data owners.
procedure TDRLRuntime.PrepareGameData;
var iModulePath : AnsiString;
begin
  FGameFailed := False;
  if ForceRestart <> '' then
  begin
    FModules.ScanModules;
    CoreModuleID := ForceRestart;
  end;
  ForceRestart := '';
  CoreModuleID := FModules.Validate(CoreModuleID);
  if CoreModuleID = '' then
    TDRLIO(IO).RunModuleChoice;

  if not DirectoryExists(Paths.WritePath + 'user') then
    CreateDir(Paths.WritePath + 'user');
  if not DirectoryExists(Paths.WritePath + 'user' + PathDelim + CoreModuleID) then
    CreateDir(Paths.WritePath + 'user' + PathDelim + CoreModuleID);
  iModulePath := Paths.WritePath + 'user' + PathDelim + CoreModuleID + PathDelim;
  FPaths.ModuleUserPath := iModulePath;
  if not DirectoryExists(iModulePath + 'screenshot') then
    CreateDir(iModulePath + 'screenshot');
  if not DirectoryExists(iModulePath + 'mortem') then
    CreateDir(iModulePath + 'mortem');
  if not DirectoryExists(iModulePath + 'backup') then
    CreateDir(iModulePath + 'backup');

  FModules.ActivateModules(CoreModuleID);
  CreateSession( False );
  TDRLIO(IO).Initialize;
  TDRLIO(IO).LoadStart;
  ProgramRealTime := MSecNow();
  TDRLIO(IO).Configure(Config);
  TDRLIO(IO).Reconfigure(Config);

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

  Assert( Self.Configuration is TDRLConfigurationState );
  TDRLConfigurationState( Self.Configuration ).ReplaceLuaConfig(
    TDRLConfig.Create( Paths.ConfigurationPath, True )
  );
  TDRLIO(IO).LoadStart;
  FDataLoaded := True;
  ColorOverrides := TIntHashMap.Create;
  TDRLIO(IO).Configure(Config, True);
  FCoreHooks := [];
  FModuleHooks := [];
  Cells := TCells.Create;
  Help := THelp.Create;
  LuaRNG := GameRNG;
end;

// Phase order: publish Lua; load hooks and module data; then prepare
// presentation data and attach the initial level.
procedure TDRLRuntime.InitializeGameData;
var i : Integer;
begin
  LuaSystem.CallDefaultResult := True;
  FCoreHooks := LoadHooks(['core'], GlobalHooks);
  FModuleHooks := LoadHooks([CoreModuleID], GlobalHooks);
  SafeCallModuleHook(Hook_OnLoad, []);
  ApplyConfiguration;
  TDRLIO(IO).Reconfigure(Config);

  if GraphicsVersion then
    (IO as TDRLGFXIO).Textures.Upload;

  if GodMode and FileExists(Paths.WritePath + 'god.lua') then
    drlbase.Lua.LoadFile(Paths.WritePath + 'god.lua');
  HOF.Init(Paths);
  FSession.InitializeLevel;
  if not GraphicsVersion then
    (IO as TDRLTextIO).SetTextMap(FSession.Level);

  HARDSPRITE_HIGHLIGHT    := drlbase.Lua.Get('HARDSPRITE_HIGHLIGHT');
  HARDSPRITE_EXPL         := drlbase.Lua.Get('HARDSPRITE_EXPL');
  HARDSPRITE_SELECT       := drlbase.Lua.Get('HARDSPRITE_SELECT');
  HARDSPRITE_MARK         := drlbase.Lua.Get('HARDSPRITE_MARK');
  HARDSPRITE_GRID         := drlbase.Lua.Get('HARDSPRITE_GRID');
  HARDSPRITE_SHIELD       := drlbase.Lua.Get('HARDSPRITE_SHIELD');
  HARDSPRITE_SHIELD_COUNT := drlbase.Lua.Get('HARDSPRITE_SHIELD_COUNT');
  HARDEMITTER_BLOOD := 0;
  if drlbase.Lua.RawDefined('HARDEMITTER_BLOOD') then
    HARDEMITTER_BLOOD := drlbase.Lua.Get('HARDEMITTER_BLOOD', 0);
  for i := 0 to 3 do
  begin
    HARDSPRITE_DECAL_BLOOD[i] := 0;
    HARDSPRITE_DECAL_WALL_BLOOD[i] := 0;
  end;
  if drlbase.Lua.RawDefined('HARDSPRITE_DECAL_BLOOD_1') then
    for i := 0 to 3 do
      HARDSPRITE_DECAL_BLOOD[i] := drlbase.Lua.Get('HARDSPRITE_DECAL_BLOOD_'+IntToStr(i+1), 0);
  if drlbase.Lua.RawDefined('HARDSPRITE_DECAL_WALL_BLOOD_1') then
    for i := 0 to 3 do
      HARDSPRITE_DECAL_WALL_BLOOD[i] := drlbase.Lua.Get('HARDSPRITE_DECAL_WALL_BLOOD_'+IntToStr(i+1), 0);

  FSession.SetDataHooks(FCoreHooks, FModuleHooks);
  TDRLIO(IO).LoadStop;
end;

// One loaded generation can serve one or more playthrough sessions.
function TDRLRuntime.RunGame : TVRunResult;
var iFirstSession : Boolean;
    iSessionResult : TDRLSessionResult;
begin
  iFirstSession := True;
  repeat
    iSessionResult := FSession.Run( iFirstSession );
    if (ForceRestart <> '') or (iSessionResult in [DSR_Quit, DSR_ReloadData]) or
       (not Option_MenuReturn) then
      Break;
    ReleaseSession;
    CreateSession( True );
    iFirstSession := False;
  until False;
  if (ForceRestart <> '') or (iSessionResult = DSR_ReloadData) then
    Result := VRR_RELOAD_DATA
  else
    Result := VRR_QUIT;
end;

// Normal release only; failed-generation release is deferred to destruction.
procedure TDRLRuntime.ShutdownGameData;
begin
  if not FGameFailed then
  begin
    ReleaseSession;
    UnloadGameData;
  end;
end;

procedure TDRLRuntime.ResetGameData;
begin
  FGameFailed := False;
  TDRLIO(IO).Reset;
end;

procedure TDRLRuntime.HandleGameException( aException : Exception );
begin
  FGameFailed := True;
end;

procedure TDRLRuntime.ApplyConfiguration;
begin
  Setting_AlwaysRandomName := drlconfiguration.Configuration.GetBoolean('always_random_name');
  Setting_NoIntro := drlconfiguration.Configuration.GetBoolean('skip_intro');
  Setting_Flash := drlconfiguration.Configuration.GetBoolean('flashing_fx');
  Setting_Glow := drlconfiguration.Configuration.GetBoolean('glow_fx');
  Setting_BloodPulse := drlconfiguration.Configuration.GetBoolean('pulse_fx');
  Setting_ScreenShake := drlconfiguration.Configuration.GetBoolean('screen_shake');
  Setting_RunOverItems := drlconfiguration.Configuration.GetBoolean('run_over_items');
  Setting_HideHints := drlconfiguration.Configuration.GetBoolean('hide_hints');
  Setting_EmptyConfirm := drlconfiguration.Configuration.GetBoolean('empty_confirm');
  Setting_Mouse := drlconfiguration.Configuration.GetBoolean('enable_mouse');
  Setting_GamepadRumble := drlconfiguration.Configuration.GetBoolean('enable_rumble');
  Setting_MouseEdgePan := drlconfiguration.Configuration.GetBoolean('mouse_edge_pan');
  Setting_UnlockAll := drlconfiguration.Configuration.GetBoolean('unlock_all');
  Setting_MenuSound := drlconfiguration.Configuration.GetBoolean('menu_sound');
  Setting_WaitSound := drlconfiguration.Configuration.GetBoolean('wait_sound');
  Setting_GroupMessages := drlconfiguration.Configuration.GetBoolean('group_messages');
  Setting_ItemDropAnimation := drlconfiguration.Configuration.GetBoolean('item_drop_animation');
  Setting_Fade := drlconfiguration.Configuration.GetBoolean('fade_fx');
end;

procedure TDRLRuntime.Reconfigure;
begin
  ApplyConfiguration;
  if Assigned(IO) then
    TDRLIO(IO).Reconfigure(Config);
end;

procedure TDRLRuntime.SafeCallModuleHook( aHook : Byte; const aParams : array of Const );
var iModule : TDRLModule;
begin
  for iModule in FModules.ActiveModules do
    if aHook in iModule.Hooks then
    try
      LuaSystem.SetValue( 'BASE_MODULE_LOADING', iModule.IsBaseLoading );
      try
        LuaSystem.ProtectedCall( [iModule.ID, HookNames[aHook]], aParams );
      finally
        LuaSystem.SetValue( 'BASE_MODULE_LOADING', False );
      end;
    except
      on E : Exception do
      begin
        if ModdedGame then
        begin
          ModErrors.Push('Error : Mod "'+iModule.ID+'" failed to execute '+HookNames[aHook]+'!');
          ModErrors.Push('Path  : '+iModule.Path);
          ModErrors.Push(E.Message);
          ModErrors.Push('');
        end
        else
          raise;
      end;
    end;
end;

procedure TDRLRuntime.UnloadGameData;
begin
  if not FDataLoaded then Exit;
  if Assigned(IO) then
    TDRLIO(IO).ClearAnimations;
  FDataLoaded := False;
  HOF.Done;
  drlbase.Lua := nil;
  FreeAndNil(Help);
  FreeAndNil(ColorOverrides);
  FreeAndNil(Cells);
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
  AddValueOption('modules-file', #0, 'FILE', 'Load external module paths from FILE.');
end;

procedure TDRLApplication.ValidateOptions;
begin
  inherited ValidateOptions;
  if HasOption('publish') and (GetOptionValue('publish') = '') then
    FailOption('--publish requires a non-empty WORKSHOP_ID');
  if HasOption('modules-file') and (GetOptionValue('modules-file') = '') then
    FailOption('--modules-file requires a non-empty FILE');
end;

procedure TDRLApplication.BeforeConfiguration( var aPaths : TGamePaths );
begin
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
var iState : TDRLConfigurationState;
begin
  iState := TDRLConfigurationState.Create;
  try
    if FileExists( aPaths.SettingsPath ) then
      iState.Read( aPaths.SettingsPath )
    else
      iState.Write( aPaths.SettingsPath );

    iState.ReplaceLuaConfig( TDRLConfig.Create( aPaths.ConfigurationPath, False ) );
    aPaths.DataPath  := iState.LuaConfig.Configure( 'DataPath', aPaths.DataPath );
    aPaths.WritePath := iState.LuaConfig.Configure( 'WritePath', aPaths.WritePath );
    aPaths.ScorePath := iState.LuaConfig.Configure( 'ScorePath', aPaths.ScorePath );
    CoreModuleID := iState.GetString( 'default_module' );
    Result := iState;
  except
    iState.Free;
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
  if HasOption('modules-file') then
    FModulesFile := GetOptionValue('modules-file');
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
  Result := TDRLRuntime.Create(aPaths, aConfiguration, FModulesFile);
end;

function TDRLApplication.ExecuteApplicationCommand : Boolean;
begin
  Result := FWorkshopID <> '';
  if Result then
    WorkshopPublish(FWorkshopID, Paths.DataPath);
end;

procedure TDRLApplication.ApplicationException( aException : Exception );
begin
  if Assigned(Logger) then Logger.Flush;
  if not EXCEPTEMMITED then
    EmitCrashInfo(aException.Message, False);
end;

end.
