{$INCLUDE drl.inc}
{
-------------------------------------------------------
DRL.PAS -- Main Program
Copyright (c) 2002-2025 by Kornel Kisielewicz
-------------------------------------------------------
}
{
[todo] move default value functionality to prototype structures
[todo] blueprints are only for type and range checking
[todo] blueprints can (should?) be turned off if not loading module, or in godmode?
[todo] however, we'd loose the option to run functions if not turned on?
[todo] container structures have meta information __blueprint and __prototype for default
[todo] the upper needs to be handled by core.unregister!
[todo] warning-only mode?
[todo] dryrun possibility of the wad file! for modders and stats generation

[todo] Copy configs from DataPath to ConfigurationPath if not present
[todo] Set proper paths on unix, create directories if needed
}

program drl;

uses SysUtils,
     {$IFDEF HEAPTRACE} heaptrc, {$ENDIF}
     {$IFDEF WINDOWS}   windows, {$ENDIF}
     vapp, vdebug, drlbase, vlog, vutil, vos,
     dfdata, drlio, drlconfig, drlconfiguration, drlworkshop;

{$IFDEF WINDOWS}
var Handle : HWND;
    Title  : AnsiString;

function ConsoleEventProc( CtrlType : DWORD ) : Bool; stdcall;
begin
  Result := True;
end;

{$R *.res}

{$ENDIF}

type
  TDRLApplication = class( TValkyrieApplication )
  private
    FWorkshopID : AnsiString;
    FGameFailed : Boolean;
  protected
    procedure DefineOptions; override;
    procedure ValidateOptions; override;
    procedure BeforeConfiguration( var aPaths : TGamePaths ); override;
    procedure LoadConfiguration( var aPaths : TGamePaths ); override;
    procedure ApplyOptions; override;
    procedure BeforeDiagnostics; override;
    function ExecuteApplicationCommand : Boolean; override;

    procedure CreateGame; override;
    procedure DestroyGame; override;
    procedure InitializeGame; override;
    function RunGame : TVRunResult; override;
    procedure ShutdownGame; override;
    procedure ResetGame; override;

    procedure GameException( aException : Exception ); override;
    procedure ApplicationException( aException : Exception ); override;
  end;

procedure TDRLApplication.DefineOptions;
begin
  AddFlag( 'god', #0, 'Enable god mode.' );
  AddValueOption( 'publish', #0, 'WORKSHOP_ID', 'Publish WORKSHOP_ID to Steam Workshop.' );
  AddFlag( 'no-sound', #0, 'Disable sound and music.' );
  AddFlag( 'windowed', #0, 'Force windowed mode.' );
  AddFlag( 'graphics', #0, 'Force graphical mode.' );
  AddFlag( 'console', #0, 'Force console mode.' );
  AddValueOption( 'name', #0, 'PLAYER_NAME', 'Use PLAYER_NAME for every game.' );
  AddValueOption( 'module', #0, 'MODULE_ID', 'Use MODULE_ID as the core module.' );
end;

procedure TDRLApplication.ValidateOptions;
begin
  inherited ValidateOptions;
  if HasOption( 'publish' ) and (GetOptionValue( 'publish' ) = '') then
    FailOption( '--publish requires a non-empty WORKSHOP_ID' );
end;

procedure TDRLApplication.BeforeConfiguration( var aPaths : TGamePaths );
begin
  ColorOverrides := nil;

  {$IFDEF WINDOWS}
  drl.Title := Self.Title;
  SetConsoleTitle( PChar(drl.Title) );
  Sleep( 40 );
  DisableAccessibilityShortcuts;
  {$ENDIF}

  if HasOption( 'god' ) then
  begin
    GodMode := True;
    if not HasOption( 'config' ) then
      aPaths.ConfigurationPath := aPaths.ResourcePath + 'godmode.lua';
  end;

  ForceNoAudio  := HasOption( 'no-sound' );
  ForceWindowed := HasOption( 'windowed' );
  ForceGraphics := HasOption( 'graphics' );
  ForceConsole  := HasOption( 'console' );

  if ForceGraphics then GraphicsVersion := True;
  if ForceConsole  then GraphicsVersion := False;
end;

procedure TDRLApplication.LoadConfiguration( var aPaths : TGamePaths );
begin
  Configuration := TDRLConfiguration.Create;
  if FileExists( aPaths.SettingsPath ) then
    Configuration.Read( aPaths.SettingsPath )
  else
    Configuration.Write( aPaths.SettingsPath );

  Config := TDRLConfig.Create( aPaths.ConfigurationPath, False );
  aPaths.DataPath  := Config.Configure( 'DataPath', aPaths.DataPath );
  aPaths.WritePath := Config.Configure( 'WritePath', aPaths.WritePath );
  aPaths.ScorePath := Config.Configure( 'ScorePath', aPaths.ScorePath );

  CoreModuleID := Configuration.GetString( 'default_module' );
end;

procedure TDRLApplication.ApplyOptions;
begin
  if HasOption( 'name' ) then
  begin
    ForcePlayerName  := GetOptionValue( 'name' );
    Option_AlwaysName := ForcePlayerName;
  end;
  if HasOption( 'module' ) then
    CoreModuleID := GetOptionValue( 'module' );
  if HasOption( 'publish' ) then
    FWorkshopID := GetOptionValue( 'publish' );
end;

procedure TDRLApplication.BeforeDiagnostics;
begin
  if FWorkshopID <> '' then
    Logger.AddSink( TConsoleLogSink.Create( LOGINFO, True ) );
end;

function TDRLApplication.ExecuteApplicationCommand : Boolean;
begin
  Result := FWorkshopID <> '';
  if Result then
    WorkshopPublish( FWorkshopID );
end;

procedure TDRLApplication.CreateGame;
begin
  drlbase.DRL := TDRL.Create;
end;

procedure TDRLApplication.DestroyGame;
begin
  if drlbase.DRL = nil then
    FreeAndNil( Config );
  FreeAndNil( Configuration );
  FreeAndNil( drlbase.DRL );
end;

procedure TDRLApplication.InitializeGame;
begin
  FGameFailed := False;
  if ForceRestart <> '' then
  begin
    drlbase.DRL.Modules.ScanModules;
    CoreModuleID := ForceRestart;
  end;
  ForceRestart := '';
  CoreModuleID := drlbase.DRL.Modules.Validate( CoreModuleID );
  if CoreModuleID = '' then
    drlbase.DRL.RunModuleChoice;

  if not DirectoryExists( Paths.WritePath + 'user' ) then
    CreateDir( Paths.WritePath + 'user' );
  if not DirectoryExists( Paths.WritePath + 'user' + PathDelim + CoreModuleID ) then
    CreateDir( Paths.WritePath + 'user' + PathDelim + CoreModuleID );
  FPaths.ModuleUserPath := Paths.WritePath + 'user' + PathDelim + CoreModuleID + PathDelim;
  if not DirectoryExists( Paths.ModuleUserPath + 'screenshot' ) then
    CreateDir( Paths.ModuleUserPath + 'screenshot' );
  if not DirectoryExists( Paths.ModuleUserPath + 'mortem' ) then
    CreateDir( Paths.ModuleUserPath + 'mortem' );
  if not DirectoryExists( Paths.ModuleUserPath + 'backup' ) then
    CreateDir( Paths.ModuleUserPath + 'backup' );

  drlbase.DRL.Initialize;

  {$IFDEF WINDOWS}
  if not GraphicsVersion then
  begin
    if Option_LockBreak then
    begin
      SetConsoleCtrlHandler( nil, False );
      SetConsoleCtrlHandler( @ConsoleEventProc, True );
    end;
    if Option_LockClose then
    begin
      Handle := FindWindow( nil, PChar(drl.Title) );
      RemoveMenu( GetSystemMenu( Handle, FALSE ), SC_CLOSE, MF_GRAYED );
      DrawMenuBar( FindWindow( nil, PChar(drl.Title) ) );
    end;
  end;
  {$ENDIF}
end;

function TDRLApplication.RunGame : TVRunResult;
begin
  drlbase.DRL.Run;
  if ForceRestart <> '' then
    Result := VRR_RELOAD_DATA
  else
    Result := VRR_QUIT;
end;

procedure TDRLApplication.ShutdownGame;
begin
  if not FGameFailed then
    drlbase.DRL.UnLoad;
end;

procedure TDRLApplication.ResetGame;
begin
  drlbase.DRL.Reset;
end;

procedure TDRLApplication.GameException( aException : Exception );
begin
  FGameFailed := True;
end;

procedure TDRLApplication.ApplicationException( aException : Exception );
begin
  if Assigned( Logger ) then Logger.Flush;
  if not EXCEPTEMMITED then
    EmitCrashInfo( aException.Message, False );
end;

begin
  Application := TDRLApplication.Create;
  try
    Application.Title := 'DRL';
    Application.Initialize;
    if not Application.Terminated then
      Application.Run;
  finally
    FreeAndNil( Application );
  end;
end.
