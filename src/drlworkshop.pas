{$INCLUDE drl.inc}
{
----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlworkshop;
interface

procedure WorkshopPublish( const aModID, aDataPath : Ansistring );

implementation

uses classes, sysutils,
     vlog, vutil, vdebug, vrandom, vstoreinterface,
     drlmodule, dfdata;

procedure WriteModuleFile( aPath : Ansistring; aModule : TDRLModule );
var iMeta : Text;
begin
  Assign( iMeta, aPath );
  Rewrite( iMeta );
  Writeln( iMeta, 'meta = {' );
  Writeln( iMeta, '  id            = "' + aModule.ID + '",');
  Writeln( iMeta, '  name          = "' + aModule.Name + '",');
  Writeln( iMeta, '  base_version  = "' + aModule.BaseVersion + '",');
  Writeln( iMeta, '  base_required = "' + aModule.BaseRequired + '",');
  Writeln( iMeta, '  workshop_id   = "' + aModule.WorkshopID + '",');
  Writeln( iMeta, '  load_priority = ' + IntToStr( aModule.LoadPriority )+ ',');
  Writeln( iMeta, '  save_version  = ' + IntToStr( aModule.SaveVersion ) + ',');
  Writeln( iMeta, '  save_agnostic = ' + IIf( aModule.SaveAgnostic, 'true', 'false' ) + ',');
  Writeln( iMeta, '  is_base       = ' + IIf( aModule.IsBase, 'true', 'false' ) + ',');
  Writeln( iMeta, '}' );
  Writeln( iMeta );
  Close( iMeta );
  Log( LOGINFO, 'Written file "'+aPath+'"');
end;

procedure WorkshopPublish( const aModID, aDataPath : Ansistring );
var iSteam   : TStoreInterface;
    iModules : TDRLModules;
    iModule  : TDRLModule;
    iWID     : QWord;
begin
  Option_ForceRaw := not GodMode;
  iModules := nil;
  try
    Log(LOGINFO,'Request to publish mod '+aModID+'...' );
    iSteam := TStoreInterface.Get;
    if ( not iSteam.IsSteam ) or ( not iSteam.IsInitialized ) then
    begin
      Log( LOGERROR,'Can''t connect to steam, aborting.' );
      Exit;
    end;
    iModules := TDRLModules.Create(aDataPath);
    iModules.ScanModules;

    iModule := iModules.GetModuleInfo( aModID );
    if iModule = nil then
    begin
      Log( LOGERROR,'Can''t find module "'+aModID+'" - missing meta with proper ID?' );
      Exit;
    end;

    Log( LOGINFO,'Found module "'+aModID+'" in '+iModule.Path );
    if ( iModule.Source = DRLMSTEAM ) or ( (not GodMode) and ( iModule.Source <> DRLMSOURCE ) ) then
    begin
      Log( LOGERROR,'Only source modules can be uploaded!' );
      Exit;
    end;

    if iModule.WorkshopID = '' then
    begin
      Log( LOGINFO,'Workshop ID = 0, preparing for initial publish...' );
      iWID := iSteam.CreateModID;
      if iWID = 0 then
      begin
        Log( LOGERROR,'Failed to assign ID!' );
        Exit;
      end;
      iModule.WorkshopID := IntToStr( iWID );
      Log( LOGINFO,'Assigned Workshop ID = ' + iModule.WorkshopID );
      if iModule.Source = DRLMWAD
        then WriteModuleFile( aDataPath+'/deploy/'+iModule.ID+'/meta.lua', iModule )
        else WriteModuleFile( iModule.Path+'meta.lua', iModule );
    end
    else
      iWID := StrToQWord(iModule.WorkshopID);

    Log( LOGINFO,'Workshop ID = ' + IntToStr(iWID) + ' ' + Iif( iModule.Source = DRLMSOURCE, 'source', 'WAD' ) + ' deploy initialized.' );
    if iModule.Source = DRLMSOURCE
      then iSteam.ModUpdate( iModule.Path, iWID )
      else iSteam.ModUpdate( ExpandFileName( aDataPath+'/deploy/'+iModule.ID+'/'), iWID );

  finally
    FreeAndNil( iModules );
  end;
end;

end.
