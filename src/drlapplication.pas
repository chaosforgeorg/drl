{$INCLUDE drl.inc}
{
-------------------------------------------------------
DRLAPPLICATION.PAS -- DRL application and runtime policy
Copyright (c) 2002-2025 by Kornel Kisielewicz
-------------------------------------------------------
}
unit drlapplication;
interface

uses sysutils,
     vapp, viorl, vlua, vrlapp, vstoreinterface, vutil, vioevent,
     dfdata, dfhof, drlbase, drlmodule, drlgamedata, drlhelp, drlio;

type
  TDRLApplication = class;

// TDRLRuntime
//
// Architectural boundary: owns DRL's runtime and data-generation lifetime,
// including module policy, services, Lua/content reloads, and the active
// session. Per-playthrough state belongs in TDRLSession.
type TDRLRuntime = class( TRLRuntime )
  private
    FSession          : TDRLSession;
    FModules          : TDRLModules;
    FStore            : TStoreInterface; // Owned; created once per process with the runtime.
    FData             : TGameData;
    FHelp             : THelp;
    FModErrors        : TStringGArray;
    FSessionHooks     : TFlags;
    FDataLoaded       : Boolean;
    FHOF              : THOF;
    FProfileTimeStart : Comp;
    procedure CreateSession( aInitializeData : Boolean );
    procedure ReleaseSession;
    procedure SafeCallModuleHook( aHook : Byte; const aParams : array of Const );
    procedure UnloadGameData;
    procedure LuaError( const aMessage : AnsiString );
    function GetIO : TDRLIO;
  protected
    function CreateIO : TIORL; override;
    function CreateLua : TLua; override;
    function PrepareGameData : Boolean; override;
    procedure InitializeGameData; override;
    function RunGame : TVRunResult; override;
    procedure ShutdownGameData; override;
    procedure ResetGameData; override;
  public
    constructor Create( const aPaths : TGamePaths; var aConfiguration : TObject;
      const aModulesFile : AnsiString ); reintroduce;
    destructor Destroy; override;
    procedure Reconfigure;
    procedure SaveProfile;
    // The IO created by CreateIO, typed for DRL.
    property IO        : TDRLIO          read GetIO;
    property HOF       : THOF            read FHOF;
    property Help      : THelp           read FHelp;
    property ModErrors : TStringGArray   read FModErrors;
    property Data      : TGameData       read FData;
    property Modules   : TDRLModules     read FModules;
    property Store     : TStoreInterface read FStore;
    property Session   : TDRLSession     read FSession;
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

uses {$IFDEF WINDOWS}windows,{$ENDIF}
     {$IFDEF WINDOWS}vos,{$ENDIF} vdebug, vlog, vluastate, vluastore,
     dfmap, drlconfig, drlconfiguration, drlgfxio, drlhooks, drllua, drltextio, drlworkshop;

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
  FStore := TStoreInterface.CreateDefault;
  FStore.SuppressProgress := GodMode;
  FModules := TDRLModules.Create( Paths.DataPath, GodMode, aModulesFile );
  FModules.ScanModules( FStore );
  FModErrors := TStringGArray.Create;
  IO.BindStore( FStore );
end;

destructor TDRLRuntime.Destroy;
begin
  ReleaseSession;
  UnloadGameData;
  IO.BindStore( nil );
  FreeAndNil(FModErrors);
  FreeAndNil(FModules);
  inherited Destroy;
  // Lua and IO, released by inherited Destroy, borrow the store.
  FreeAndNil(FStore);
end;

procedure TDRLRuntime.ReleaseSession;
begin
  // Views and animations must be released while their Session and level exist.
  if FSession <> nil then
  begin
    IO.Clear;
    IO.ClearAnimations;
  end;
  IO.BindRunStatus( nil );
  IO.BindAutoTarget( nil );
  FreeAndNil(FSession);
end;

function TDRLRuntime.CreateIO : TIORL;
begin
  if GraphicsVersion then
    Result := TDRLGFXIO.Create( Self.Configuration as TDRLConfiguration, Config )
  else
    Result := TDRLTextIO.Create( Self.Configuration as TDRLConfiguration, Config );
end;

function TDRLRuntime.CreateLua : TLua;
begin
  Result := TDRLLua.Create( FModules, Paths.DataPath );
  Result.ErrorFunc := @LuaError;
  IO.RegisterLuaAPI( Result );
end;

function TDRLRuntime.GetIO : TDRLIO;
begin
  Exit( TDRLIO( TRLRuntime( Self ).IO ) );
end;

// Lua errors during a run are reported in game; elsewhere they abort.
procedure TDRLRuntime.LuaError( const aMessage : AnsiString );
begin
  if FSession.State in [ DSPlaying, DSEnding ] then
    IO.ErrorReport( aMessage )
  else
    raise ELuaException.Create( 'LuaError: ' + aMessage );
  Log( 'LuaError: ' + aMessage );
end;

procedure TDRLRuntime.CreateSession( aInitializeData : Boolean );
begin
  FSession := TDRLSession.Create( Self, IO, Self.Configuration as TDRLConfiguration, FModules, FStore, FData, Paths );
  IO.BindRunStatus( FSession.RunStatus );
  IO.BindAutoTarget( FSession.Targeting.List );
  if not aInitializeData then Exit;
  TDRLLua( FLua ).BindNodeContext( FSession.Context );
  FSession.InitializeLevel;
  FSession.SetSessionHooks( FSessionHooks );
end;

// Phase order: select module and paths; confirm outdated mods; create an
// initial session shell; prepare IO/configuration, then non-Lua data owners.
function TDRLRuntime.PrepareGameData : Boolean;
var iModulePath : AnsiString;
begin
  if ForceRestart <> '' then
  begin
    FModules.ScanModules( FStore );
    CoreModuleID := ForceRestart;
  end;
  ForceRestart := '';
  CoreModuleID := FModules.Validate(CoreModuleID);
  if CoreModuleID = '' then
    IO.RunModuleChoice( FModules.CoreModules );

  if not DirectoryExists(Paths.WritePath + 'user') then
    CreateDir(Paths.WritePath + 'user');
  if not DirectoryExists(Paths.WritePath + 'user' + PathDelim + CoreModuleID) then
    CreateDir(Paths.WritePath + 'user' + PathDelim + CoreModuleID);
  iModulePath := Paths.WritePath + 'user' + PathDelim + CoreModuleID + PathDelim;
  FPaths.ModuleUserPath := iModulePath;
  if not DirectoryExists(iModulePath + 'screenshot') then
    CreateDir(iModulePath + 'screenshot');
  IO.SShotPath := iModulePath + 'screenshot';
  if not DirectoryExists(iModulePath + 'mortem') then
    CreateDir(iModulePath + 'mortem');
  if not DirectoryExists(iModulePath + 'backup') then
    CreateDir(iModulePath + 'backup');

  FModules.ActivateModules(CoreModuleID);
  if ( FModules.OutdatedModules.Size > 0 )
  and ( not IO.RunModuleAPIWarning( FModules.OutdatedModules ) ) then
    Exit( False );

  FData := TGameData.Create;
  CreateSession( False );
  IO.Initialize( FModules.CoreModule );
  IO.LoadStart;
  FProfileTimeStart := MSecNow();
  IO.Configure(Config, False);
  IO.Reconfigure(Config);

  {$IFDEF WINDOWS}
  if ( not GraphicsVersion ) and ( not GodMode ) then
  begin
    // Ctrl-C and the console close button would end the game without saving.
    SetConsoleCtrlHandler(nil, False);
    SetConsoleCtrlHandler(@ConsoleEventProc, True);
    ConsoleHandle := FindWindow(nil, PChar(ConsoleTitle));
    RemoveMenu(GetSystemMenu(ConsoleHandle, False), SC_CLOSE, MF_GRAYED);
    DrawMenuBar(ConsoleHandle);
  end;
  {$ENDIF}

  Assert( Self.Configuration is TDRLConfigurationState );
  TDRLConfigurationState( Self.Configuration ).ReplaceLuaConfig(
    TDRLConfig.Create( Paths.ConfigurationPath, True )
  );
  IO.LoadStart;
  FDataLoaded := True;
  IO.Configure(Config, True);
  FSessionHooks := [];
  FHelp := THelp.Create;
  Result := True;
end;

// Phase order: publish Lua; load hooks and module data; then prepare
// presentation data and attach the initial level.
procedure TDRLRuntime.InitializeGameData;
var i : Integer;
begin
  FSession.Context.BindLua( FLua );
  TDRLLua( FLua ).BindNodeContext( FSession.Context );
  FData.RegisterLuaAPI( FLua );
  RegisterStoreLuaAPI( FLua, FStore );
  // Runtime outlives Lua; the callbacks resolve the Session active at each call.
  TDRLSession.RegisterLuaAPI( FLua, @FSession );
  // Natives register before scripts run: the core module guards globals.
  FHOF := THOF.Create( FLua, Paths );
  FHOF.RegisterLuaAPI( FLua );
  TDRLLua( FLua ).ReadWad( IO, FHelp, FModErrors );
  FData.LoadRules( FLua );
  if GodMode then RegisterDebugConsole( VKEY_F1 );
  FLua.CallDefaultResult := True;
  FSessionHooks := LoadHooks( FLua, [CoreModuleID], SessionHooks );
  SafeCallModuleHook(Hook_OnLoad, []);
  IO.Reconfigure(Config);
  IO.PrepareGraphics;

  if GodMode and FileExists(Paths.WritePath + 'god.lua') then
    FLua.LoadFile(Paths.WritePath + 'god.lua');
  FSession.InitializeLevel;

  HARDSPRITE_HIGHLIGHT    := FLua.Get('HARDSPRITE_HIGHLIGHT');
  HARDSPRITE_EXPL         := FLua.Get('HARDSPRITE_EXPL');
  HARDSPRITE_SELECT       := FLua.Get('HARDSPRITE_SELECT');
  HARDSPRITE_MARK         := FLua.Get('HARDSPRITE_MARK');
  HARDSPRITE_GRID         := FLua.Get('HARDSPRITE_GRID');
  HARDSPRITE_SHIELD       := FLua.Get('HARDSPRITE_SHIELD');
  HARDSPRITE_SHIELD_COUNT := FLua.Get('HARDSPRITE_SHIELD_COUNT');
  HARDEMITTER_BLOOD := 0;
  if FLua.RawDefined('HARDEMITTER_BLOOD') then
    HARDEMITTER_BLOOD := FLua.Get('HARDEMITTER_BLOOD', 0);
  for i := 0 to 3 do
  begin
    HARDSPRITE_DECAL_BLOOD[i] := 0;
    HARDSPRITE_DECAL_WALL_BLOOD[i] := 0;
  end;
  if FLua.RawDefined('HARDSPRITE_DECAL_BLOOD_1') then
    for i := 0 to 3 do
      HARDSPRITE_DECAL_BLOOD[i] := FLua.Get('HARDSPRITE_DECAL_BLOOD_'+IntToStr(i+1), 0);
  if FLua.RawDefined('HARDSPRITE_DECAL_WALL_BLOOD_1') then
    for i := 0 to 3 do
      HARDSPRITE_DECAL_WALL_BLOOD[i] := FLua.Get('HARDSPRITE_DECAL_WALL_BLOOD_'+IntToStr(i+1), 0);

  FSession.SetSessionHooks( FSessionHooks );
  IO.LoadStop;
end;

// One loaded generation can serve one or more playthrough sessions.
function TDRLRuntime.RunGame : TVRunResult;
var iFirstSession : Boolean;
    iSessionResult : TDRLSessionResult;
begin
  iFirstSession := True;
  repeat
    iSessionResult := FSession.Run( iFirstSession );
    if (ForceRestart <> '') or (iSessionResult in [DSR_Quit, DSR_ReloadData]) then
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

procedure TDRLRuntime.ShutdownGameData;
begin
  ReleaseSession;
  UnloadGameData;
end;

procedure TDRLRuntime.ResetGameData;
begin
  IO.Reset;
end;

procedure TDRLRuntime.SaveProfile;
var iSeconds : DWord;
begin
  iSeconds := Round( (MSecNow() - FProfileTimeStart) / 1000 );
  FProfileTimeStart := MSecNow();
  FHOF.Save( iSeconds );
end;

procedure TDRLRuntime.Reconfigure;
begin
  IO.Reconfigure(Config);
end;

procedure TDRLRuntime.SafeCallModuleHook( aHook : Byte; const aParams : array of Const );
var iModule : TDRLModule;
begin
  for iModule in FModules.ActiveModules do
    if aHook in iModule.Hooks then
    try
      FLua.SetValue( 'BASE_MODULE_LOADING', iModule.IsBaseLoading );
      try
        FLua.ProtectedCall( [iModule.ID, HookNames[aHook]], aParams );
      finally
        FLua.SetValue( 'BASE_MODULE_LOADING', False );
      end;
    except
      on E : Exception do
      begin
        if ModdedGame then
        begin
          FModErrors.Push('Error : Mod "'+iModule.ID+'" failed to execute '+HookNames[aHook]+'!');
          FModErrors.Push('Path  : '+iModule.Path);
          FModErrors.Push(E.Message);
          FModErrors.Push('');
        end
        else
          raise;
      end;
    end;
end;

procedure TDRLRuntime.UnloadGameData;
begin
  FreeAndNil( FData );
  if not FDataLoaded then Exit;
  FDataLoaded := False;
  try
    if FHOF <> nil then
      SaveProfile;
  finally
    FreeAndNil( FHOF );
    FreeAndNil( FHelp );
  end;
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
