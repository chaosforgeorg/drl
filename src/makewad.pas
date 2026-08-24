{$INCLUDE drl.inc}
program makewad;
uses Classes,SysUtils, strutils, getopts, vlog, vpkg,vdf, vutil, dfdata, idea;

var WAD         : TVDataCreator;
    EKey,DKKey  : TIDEAKey;
    KeyFile     : Text;
    Count       : Byte;
    ModuleID    : AnsiString;
    ModulePath  : AnsiString;
    LegacyArgument : AnsiString;
    ModulePathSet  : Boolean;
    Path        : AnsiString;

const UserKey : TIdeaCryptKey = (123,111,10,12,222,90,1,8);
      LongOptions : array[1..2] of TOption = (
        ( Name : 'module-path'; Has_arg : Required_Argument;
          Flag : nil; Value : 'm' ),
        ( Name : ''; Has_arg : No_Argument; Flag : nil; Value : #0 )
      );

procedure ExecuteFile(const aFileName: string);
var iFile                        : TextFile;
    iLine, iType, iMask, iFolder : Ansistring;
    iSpacePos1, iSpacePos2       : SizeInt;
begin
  AssignFile(iFile, aFileName);
  Reset(iFile);
  try
    while not Eof(iFile) do
    begin
      ReadLn(iFile, iLine);
      iSpacePos1 := Pos(' ', iLine);
      iType   := iLine;
      iMask   := '';
      iFolder := '';
      if iSpacePos1 > 0 then
      begin
        iType := Copy(iLine, 1, iSpacePos1 - 1);
        iSpacePos2 := PosEx(' ', iLine, iSpacePos1 + 1);
        if iSpacePos2 > 0 then
        begin
          iMask   := Copy(iLine, iSpacePos1 + 1, iSpacePos2 - iSpacePos1 - 1);
          iFolder := Copy(iLine, iSpacePos2 + 1, Length(iLine) - iSpacePos2);
        end
        else
          iMask :=  Copy(iLine, iSpacePos1 + 1, Length(iLine) - iSpacePos1);
        Writeln(iType, '-',iMask,'-',iFolder);
      end;
      if iType = 'lua'   then WAD.Add(Path+iMask,FILETYPE_LUA,[vdfCompressed,vdfEncrypted], iFolder );
      if iType = 'music' then WAD.Add(Path+iMask,FILETYPE_RAW,[], 'music' );
    end;
  finally
    CloseFile(iFile);
  end;
end;

var iFileMode : Boolean = False;

procedure ParseCommandLine;
var iOption      : Char;
    iOptionIndex : LongInt;
begin
  ModuleID       := 'drl';
  ModulePath     := '';
  LegacyArgument := '';
  ModulePathSet  := False;
  iOptionIndex   := 0;

  OptErr := False;
  repeat
    iOption := GetLongOpts( ':', @LongOptions[1], iOptionIndex );
    case iOption of
      'm' :
        begin
          if ModulePathSet then
            raise Exception.Create( 'Duplicate --module-path option' );
          ModulePath := Trim( OptArg );
          if ModulePath = '' then
            raise Exception.Create(
              '--module-path requires a directory'
            );
          ModulePathSet := True;
        end;
      '?' : raise Exception.Create( 'Unknown command-line option' );
      ':' : raise Exception.Create(
        '--module-path requires a directory'
      );
    end;
  until iOption = EndOfOptions;

  if OptInd <= ParamCount then
  begin
    ModuleID := ParamStr( OptInd );
    Inc( OptInd );
  end;
  if OptInd <= ParamCount then
  begin
    LegacyArgument := ParamStr( OptInd );
    Inc( OptInd );
  end;
  if OptInd <= ParamCount then
    raise Exception.Create(
      'Only one file list or audio module may be specified'
    );
end;

begin
  Logger.AddSink( TTextFileLogSink.Create( LOGDEBUG, WritePath + 'runtime.log', False ) );
  Logger.AddSink( TConsoleLogSink.Create( LOGDEBUG ) );

  try
    ParseCommandLine;
    EnKeyIdea(UserKey,EKey);
    DeKeyIdea(EKey,DKKey);

    WAD := TVDataCreator.Create('core.wad');
    WAD.Add('data/core/*.lua',FILETYPE_LUA,[vdfCompressed], '' );
    FreeAndNil(WAD);

    Assign(KeyFile,'dkey.inc');
    Rewrite(KeyFile);
    Write(KeyFile,'const LoveLace : TIDEAKey = ( ');
    for Count := Low(DKKey) to High(DKKey)-1 do
      Write(KeyFile,DKKey[Count],', ');
    Writeln(KeyFile,DKKey[High(DKKey)],' );');
    Close(KeyFile);

    begin
      if ModulePathSet then
      begin
        Path := IncludeTrailingPathDelimiter( ExpandFileName( ModulePath ) );
        if not DirectoryExists( Path ) then
          raise Exception.CreateFmt(
            'External module directory not found: %s', [ Path ]
          );
        if not FileExists( Path + 'meta.lua' ) then
          raise Exception.CreateFmt(
            'External module directory has no meta.lua: %s', [ Path ]
          );
      end
      else
        Path := 'data/' + ModuleID + '/';

      WAD := TVDataCreator.Create(ModuleID+'.wad');
      WAD.SetKey( EKey );

      WAD.Add(Path+'help/*.hlp',FILETYPE_RAW,[vdfCompressed,vdfEncrypted], 'help' );
      WAD.Add(Path+'ascii/*.asc',FILETYPE_RAW,[vdfCompressed,vdfEncrypted], 'ascii' );
      WAD.Add(Path+'fonts/font*.png',FILETYPE_IMAGE,[], 'fonts' );
      WAD.Add(Path+'fonts/default',FILETYPE_RAW,[], 'fonts' );
      if ( LegacyArgument <> '' ) and LegacyArgument.EndsWith( '.txt' ) then
      begin
         ExecuteFile( LegacyArgument );
         iFileMode := True;
      end;

      if not iFileMode then
      begin
        WAD.Add(Path+'*.lua',FILETYPE_LUA,[vdfCompressed,vdfEncrypted], '' );
        WAD.Add(Path+'levels/**.lua',FILETYPE_LUA,[vdfCompressed,vdfEncrypted], 'levels' );
        WAD.Add(Path+'items/*.lua',FILETYPE_LUA,[vdfCompressed,vdfEncrypted], 'items' );
      end;
      WAD.Add(Path+'graphics/*.png',FILETYPE_IMAGE,[], 'graphics' );
      WAD.Add(Path+'sound/*.wav',FILETYPE_RAW,[vdfCompressed], 'sound' );
      if not iFileMode then
      begin
        WAD.Add(Path+'music/*.ogg',FILETYPE_RAW,[], 'music' );
        WAD.Add(Path+'music/*.mp3',FILETYPE_RAW,[], 'music' );
        WAD.Add(Path+'music/*.mid',FILETYPE_RAW,[vdfCompressed], 'music' );
      end;

      if ( LegacyArgument <> '' ) and ( not iFileMode ) then
      begin
        Path := 'data/' + LegacyArgument + '/';
        WAD.Add(Path+'audio.lua',FILETYPE_LUA,[vdfCompressed,vdfEncrypted], '' );
        WAD.Add(Path+'sound/*.wav',FILETYPE_RAW,[vdfCompressed], 'sound' );
        WAD.Add(Path+'music/*.ogg',FILETYPE_RAW,[], 'music' );
        WAD.Add(Path+'music/*.mp3',FILETYPE_RAW,[], 'music' );
        WAD.Add(Path+'music/*.mid',FILETYPE_RAW,[vdfCompressed], 'music' );
      end;

      FreeAndNil(WAD);
    end;
  except
    on E : Exception do
    begin
      Writeln( 'makewad error: ' + E.Message );
      Halt( 1 );
    end;
  end;
end.
