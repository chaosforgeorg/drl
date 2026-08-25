{$INCLUDE drl.inc}
program drlwad;

// Manifest-driven WAD builder.
//
// Usage:
//   drlwad
//   drlwad path\to\build.lua
//   drlwad path\to\directory
//
// With no argument, drlwad loads build.lua. A directory argument loads build.lua
// from that directory; the trailing slash is optional. The manifest must define
// a global build table containing WAD tables in the following form:
//
//   { "output.wad", { "source mask", "TYPE", "wad folder",
//     compressed = true, encoded = true }, ... }
//
// Source masks are resolved relative to the manifest. Output WAD paths and
// dkey.inc are resolved relative to the process working directory.

uses classes, sysutils, strutils, custapp, idea,
     vlua, vluatable, vpkg, vdf;

type
  { TDRLWadApplication }

  TDRLWadApplication = class(TCustomApplication)
  private
    FBuildFileName : AnsiString;
    FSourceRoot    : AnsiString;
    FLua           : TLua;
    FBuildTable    : TLuaTable;
    FEKey          : TIDEAKey;
    FDKey          : TIDEAKey;
    FHasEncoded    : Boolean;
    procedure ResolveBuildFile;
    procedure LoadManifest;
    procedure ProcessManifest;
    procedure ProcessWad( aTable : TLuaTable; aWadIndex : Integer );
    function AddEntry( aCreator : TVDataCreator; aTable : TLuaTable;
      aWadIndex, aEntryIndex : Integer; const aOutputName : AnsiString ) : Boolean;
    function ResolveSourceMask( const aSourceMask : AnsiString ) : AnsiString;
    function ParseFileType( const aName : AnsiString; aWadIndex, aEntryIndex : Integer ) : DWord;
    procedure PrepareKeys;
    procedure WriteKeyFile;
  protected
    procedure DoRun; override;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

const
  UserKey: TIdeaCryptKey = (123, 111, 10, 12, 222, 90, 1, 8);

constructor TDRLWadApplication.Create;
begin
  inherited Create(nil);
  FBuildFileName := '';
  FSourceRoot    := '';
  FLua           := nil;
  FBuildTable    := nil;
  FHasEncoded    := False;
end;

destructor TDRLWadApplication.Destroy;
begin
  FreeAndNil(FBuildTable);
  FreeAndNil(FLua);
  inherited Destroy;
end;

procedure TDRLWadApplication.ResolveBuildFile;
var iArgument: AnsiString;
begin
  if ParamCount > 1 then
    raise Exception.Create('Expected zero or one build file argument');

  if ParamCount = 0 then
    iArgument := 'build.lua'
  else
  begin
    iArgument := ParamStr(1);
    if not EndsText('lua', iArgument) then
      iArgument := IncludeTrailingPathDelimiter(iArgument) + 'build.lua';
  end;

  FBuildFileName := ExpandFileName(iArgument);
  if not FileExists(FBuildFileName) then raise EFOpenError.CreateFmt( 'Build file not found: %s', [FBuildFileName] );
  FSourceRoot := IncludeTrailingPathDelimiter( ExtractFilePath(FBuildFileName) );
end;

procedure TDRLWadApplication.LoadManifest;
begin
  FLua := TLua.Create;
  try
    FLua.LoadFile(FBuildFileName);
  except
    on E: Exception do
      raise Exception.CreateFmt('Build file "%s": %s', [FBuildFileName, E.Message]);
  end;

  try
    FBuildTable := TLuaTable.Create(FLua.NativeState, 'build');
  except
    on E: Exception do
      raise Exception.CreateFmt('Build file "%s": global build must be a table (%s)', [FBuildFileName, E.Message]);
  end;
end;

function TDRLWadApplication.ParseFileType( const aName : AnsiString; aWadIndex, aEntryIndex : Integer ) : DWord;
begin
  if aName = 'RAW' then Result := FILETYPE_RAW
  else if aName = 'HELP' then Result := FILETYPE_HELP
  else if aName = 'XML' then Result := FILETYPE_XML
  else if aName = 'ASCII' then Result := FILETYPE_ASCII
  else if aName = 'LUA' then Result := FILETYPE_LUA
  else if aName = 'MUSIC' then Result := FILETYPE_MUSIC
  else if aName = 'SOUND' then Result := FILETYPE_SOUND
  else if aName = 'IMAGE' then Result := FILETYPE_IMAGE
  else if aName = 'FONT' then Result := FILETYPE_FONT
  else
    raise Exception.CreateFmt('WAD %d entry %d: unknown file type "%s"', [aWadIndex, aEntryIndex, aName]);
end;

function TDRLWadApplication.ResolveSourceMask( const aSourceMask : AnsiString ) : AnsiString;
var iAbsolute: Boolean;
begin
  iAbsolute := (aSourceMask <> '') and
    ((ExtractFileDrive(aSourceMask) <> '') or
     (aSourceMask[1] = PathDelim) or
     (aSourceMask[1] = '/') or
     (aSourceMask[1] = '\'));
  if iAbsolute 
    then Result := aSourceMask
    else Result := ExpandFileName(FSourceRoot + aSourceMask);
end;

function TDRLWadApplication.AddEntry( aCreator : TVDataCreator; aTable : TLuaTable;
  aWadIndex, aEntryIndex : Integer; const aOutputName : AnsiString ) : Boolean;
var iContext   : AnsiString;
    iFileType  : DWord;
    iFlags     : TVDFClumpFlags;
    iSize      : DWord;
    iSourceMask: AnsiString;
    iTypeName  : AnsiString;
    iValue     : TLuaIndexValue;
    iWadFolder : AnsiString;
begin
  Result            := False;
  iFlags            := [];
  iSourceMask       := '';
  iTypeName         := '';
  iWadFolder        := '';
  iContext := Format('WAD %d entry %d', [aWadIndex, aEntryIndex]);
  iSize := aTable.GetSize;
  if iSize < 2 then raise Exception.CreateFmt('%s: expected at least two positional fields, got %d', [iContext, iSize]);

  for iValue in aTable.IPairs do
  begin
    case iValue.Index of
      1:begin
          if not iValue.Value.IsString then raise Exception.CreateFmt('%s: source mask must be a string', [iContext]);
          iSourceMask := iValue.Value.ToString;
        end;
      2:begin
          if not iValue.Value.IsString then raise Exception.CreateFmt('%s: file type must be a string', [iContext]);
          iTypeName := iValue.Value.ToString;
        end;
      3:begin
          if not iValue.Value.IsString then raise Exception.CreateFmt('%s: WAD folder must be a string', [iContext]);
          iWadFolder := iValue.Value.ToString;
        end;
    end;
  end;
  if iSourceMask = '' then raise Exception.CreateFmt('%s: source mask cannot be empty', [iContext]);

  if aTable.GetBoolean('compressed', False) then 
    Include(iFlags, vdfCompressed);
  if aTable.GetBoolean('encoded', False) then
  begin
    Include(iFlags, vdfEncrypted);
    Result := True;
  end;
  iSourceMask := ResolveSourceMask(iSourceMask);
  iFileType := ParseFileType(iTypeName, aWadIndex, aEntryIndex);
  try
    aCreator.Add(iSourceMask, iFileType, iFlags, iWadFolder);
  except
    on E: Exception do
      raise Exception.CreateFmt('WAD %d ("%s") entry %d ("%s"): %s', [aWadIndex, aOutputName, aEntryIndex, iSourceMask, E.Message]);
  end;
end;

procedure TDRLWadApplication.ProcessWad( aTable : TLuaTable; aWadIndex : Integer );
var iCreator   : TVDataCreator;
    iEntryTable: TLuaTable;
    iEntryIndex: Integer;
    iOutputName: AnsiString;
    iSize      : DWord;
    iValue     : TLuaIndexValue;
begin
  iSize := aTable.GetSize;
  if iSize < 1 then raise Exception.CreateFmt('WAD %d: output filename is missing', [aWadIndex]);
  if iSize > DWord(High(Integer)) then raise Exception.CreateFmt('WAD %d: too many entries', [aWadIndex]);

  iOutputName := '';
  for iValue in aTable.IPairs do
  begin
    if iValue.Index = 1 then
    begin
      if not iValue.Value.IsString then raise Exception.CreateFmt('WAD %d: output filename must be a string', [aWadIndex]);
      iOutputName := iValue.Value.ToString;
    end
    else if not iValue.Value.IsTable then 
      raise Exception.CreateFmt('WAD %d entry %d: expected a table', [aWadIndex, iValue.Index - 1]);
  end;

  if iOutputName = '' then raise Exception.CreateFmt('WAD %d: output filename cannot be empty', [aWadIndex]);

  try
    iCreator := TVDataCreator.Create(iOutputName);
  except
    on E: Exception do
      raise Exception.CreateFmt('WAD %d ("%s"): %s', [aWadIndex, iOutputName, E.Message]);
  end;
  iCreator.SetKey(FEKey);

  for iEntryIndex := 1 to Integer(iSize) - 1 do
  begin
    iEntryTable := aTable.GetTable([iEntryIndex + 1]);
    try
      if AddEntry(iCreator, iEntryTable, aWadIndex, iEntryIndex, iOutputName) then
        FHasEncoded := True;
    finally
      iEntryTable.Free;
    end;
  end;
  try
    FreeAndNil(iCreator);
  except
    on E: Exception do
      raise Exception.CreateFmt('WAD %d ("%s") flush failed: %s', [aWadIndex, iOutputName, E.Message]);
  end;
end;

procedure TDRLWadApplication.ProcessManifest;
var iWadIndex : Integer;
    iWadTable : TLuaTable;
    iValue    : TLuaIndexValue;
begin
  FHasEncoded := False;
  iWadIndex := 0;
  for iValue in FBuildTable.IPairs do
  begin
    Inc(iWadIndex);
    iWadTable := TLuaTable.Create(FLua.NativeState, iValue.Value.Index);
    try
      ProcessWad(iWadTable, iWadIndex);
    finally
      iWadTable.Free;
    end;
  end;
end;

procedure TDRLWadApplication.PrepareKeys;
begin
  EnKeyIdea(UserKey, FEKey);
  DeKeyIdea(FEKey, FDKey);
end;

procedure TDRLWadApplication.WriteKeyFile;
var iCount   : Byte;
    iKeyFile : TextFile;
begin
  AssignFile(iKeyFile, 'dkey.inc');
  Rewrite(iKeyFile);
  try
    Write(iKeyFile, 'const LoveLace : TIDEAKey = ( ');
    for iCount := Low(FDKey) to High(FDKey) - 1 do
      Write(iKeyFile, FDKey[iCount], ', ');
    Writeln(iKeyFile, FDKey[High(FDKey)], ' );');
  finally
    CloseFile(iKeyFile);
  end;
end;

procedure TDRLWadApplication.DoRun;
begin
  try
    ResolveBuildFile;
    LoadManifest;
    PrepareKeys;
    ProcessManifest;
    if FHasEncoded then WriteKeyFile;
    Terminate(0);
  except
    on E: Exception do
    begin
      Writeln(StdErr, 'drlwad error: ', E.Message);
      Terminate(1);
    end;
  end;
end;

var
  DRLWadApplication: TDRLWadApplication;
  DRLWadExitCode   : Integer;
begin
  DRLWadApplication := nil;
  DRLWadExitCode := 1;
  try
    DRLWadApplication := TDRLWadApplication.Create;
    DRLWadApplication.Title := 'drlwad';
    DRLWadApplication.Run;
    DRLWadExitCode := System.ExitCode;
  except
    on E: Exception do
      Writeln(StdErr, 'drlwad error: ', E.Message);
  end;
  FreeAndNil(DRLWadApplication);
  Halt(DRLWadExitCode);
end.
