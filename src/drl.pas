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
     vdebug, drlbase, vlog, vutil, vos, vparams,
     dfdata, drlio, drlconfig, drlconfiguration, drlworkshop;

{$IFDEF WINDOWS}
var Handle : HWND;
    Title  : AnsiString;

function ConsoleEventProc(CtrlType: DWORD): Bool; stdcall;
begin
  Result := True;
end;

{$R *.res}

{$ENDIF}

var RootPath   : AnsiString = '';
    WorkshopID : Ansistring = '';

begin
try
  try
    Configuration := TDRLConfiguration.Create;

    {$IFDEF Darwin}
    {$IFDEF OSX_APP_BUNDLE}
    RootPath := GetResourcesPath();
    DataPath          := RootPath;
    ConfigurationPath := RootPath + 'config.lua';
    SettingsPath      := RootPath + 'settings.lua';
    {$ENDIF}
    {$ELSE}
      {$IFDEF UNIX}
      {$ENDIF}
    {$ENDIF}

    {$IFDEF Windows}
    RootPath := ExtractFilePath( ParamStr(0) );
    if not FileExists( RootPath + 'config.lua' ) then
      RootPath := '';
    DataPath          := RootPath;
    ConfigurationPath := RootPath + 'config.lua';
    SettingsPath      := RootPath + 'settings.lua';

    Title := 'DRL';
    SetConsoleTitle(PChar(Title));
    Sleep(40);
    DisableAccessibilityShortcuts;
    {$ENDIF}
    ColorOverrides := nil;

    with TParams.Create do
    try
      if isSet('god')    then
      begin
        GodMode           := True;
        ConfigurationPath := RootPath + 'godmode.lua';
      end;
      if isSet('config')     then ConfigurationPath := get('config');
      if isSet('publish')    then
      begin
        WorkshopID        := get('publish');
        if WorkshopID <> '' then
          Logger.AddSink( TConsoleLogSink.Create( LOGINFO, True ) );
      end;
      if isSet('nosound')    then ForceNoAudio      := True;
      if isSet('window')     then ForceWindowed     := True;
      if isSet('graphics')   then
      begin
        GraphicsVersion := True;
        ForceGraphics := True;
      end;
      if isSet('console')    then
      begin
        GraphicsVersion := False;
        ForceConsole := True;
      end;

      if FileExists( SettingsPath )
        then Configuration.Read( SettingsPath )
        else Configuration.Write( SettingsPath );

      Config := TDRLConfig.Create( ConfigurationPath, False );
      DataPath     := Config.Configure( 'DataPath', DataPath );
      WritePath    := Config.Configure( 'WritePath', WritePath );
      ScorePath    := Config.Configure( 'ScorePath', ScorePath );

      CoreModuleID := Configuration.GetString('default_module');

      if isSet('datapath')   then DataPath          := get('datapath');
      if isSet('writepath')  then WritePath         := get('writepath');
      if isSet('scorepath')  then ScorePath         := get('scorepath');
      if isSet('name')       then Option_AlwaysName := get('name');
      if isSet('module')     then CoreModuleID      := get('module');
    finally
      Free;
    end;

    {$IFDEF HEAPTRACE}
    SetHeapTraceOutput( WritePath + 'heap.txt');
    {$ENDIF}

    Logger.AddSink( TTextFileLogSink.Create( LOGDEBUG, WritePath + 'runtime.log', False ) );
    LogSystemInfo();
    Logger.Log( LOGINFO, 'Log path set to - ' + WritePath );

    ErrorLogFileName := WritePath + 'error.log';
    Randomize;

    if WorkshopID <> '' then
    begin
      WorkshopPublish( WorkShopID );
      FreeAndNil( Configuration );
      Exit;
    end;

    drlbase.DRL := TDRL.Create;

    repeat
      if ForceRestart <> '' then
      begin
        drlbase.DRL.Modules.ScanModules;
        CoreModuleID := ForceRestart;
      end;
      ForceRestart := '';
      CoreModuleID := drlbase.DRL.Modules.Validate( CoreModuleID );
      if CoreModuleID = '' then
        drlbase.DRL.RunModuleChoice;

      begin // Make and assign directories
        if not DirectoryExists( WritePath + 'user' ) then CreateDir( WritePath + 'user' );
        if not DirectoryExists( WritePath + 'user' + PathDelim + CoreModuleID ) then CreateDir( WritePath + 'user' + PathDelim + CoreModuleID );
        ModuleUserPath := WritePath + 'user' + PathDelim + CoreModuleID + PathDelim;
        if not DirectoryExists( ModuleUserPath + 'screenshot' ) then CreateDir( ModuleUserPath + 'screenshot' );
        if not DirectoryExists( ModuleUserPath + 'mortem' ) then CreateDir( ModuleUserPath + 'mortem' );
        if not DirectoryExists( ModuleUserPath + 'backup' ) then CreateDir( ModuleUserPath + 'backup' );
      end;

      drlbase.DRL.Initialize;

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
          Handle := FindWindow(nil, PChar(Title));
          RemoveMenu(GetSystemMenu( Handle, FALSE), SC_CLOSE , MF_GRAYED);
          DrawMenuBar(FindWindow(nil, PChar(Title)));
        end;
      end;
      {$ENDIF}
      drlbase.DRL.Run;
      drlbase.DRL.UnLoad;

      drlbase.DRL.Reset;
    until ForceRestart = '';
  finally
    FreeAndNil( Configuration );
    FreeAndNil( drlbase.DRL );
  end;
except on e : Exception do
  begin
    if not EXCEPTEMMITED then
      EmitCrashInfo( e.Message, False );
    raise
  end;
end;

end.


