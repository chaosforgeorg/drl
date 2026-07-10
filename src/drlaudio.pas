{$INCLUDE drl.inc}
unit drlaudio;

interface

uses classes, vgenerics, vrltools, vluaconfig, vdf, vaudio;

type
  TSoundEvent = packed record
    Time    : QWord;
    Coord   : TCoord2D;
    SoundID : Word;
  end;

  TAudioEntry = record
    ID       : AnsiString;
    Root     : AnsiString;
    FileName : AnsiString;
    IsMusic  : Boolean;
    DataFile : TVDataFile;
    Asset    : TAudioAssetHandle;
  end;

  TAudioRegistry  = specialize TGArray<TAudioEntry>;
  TAudioLookup    = specialize TGHashMap<Integer>;
  TSoundEventHeap = specialize TGHeap<TSoundEvent>;

  TSoundCount = record
    SoundID : Word;
    Count   : Byte;
  end;
  TSoundCountArray = specialize TGArray<TSoundCount>;

  TDRLAudio = class
  private
    FLastMusic         : AnsiString;
    FTime              : QWord;
    FSoundEvents       : TSoundEventHeap;
    FSoundCounts       : TSoundCountArray;
    FCurrentData       : TVDataFile;
    FAudioRegistry     : TAudioRegistry;
    FAudioLookup       : TAudioLookup;
    FSourceLookup      : TAudioLookup;
    FRoot              : AnsiString;
    FAudio             : TAudio;
    FHeartbeatAsset    : TAudioAssetHandle;
    FHeartbeatInstance : TAudioInstanceHandle;
    FHeartbeatEnabled  : Boolean;

    procedure Register( const aID, aFileName : AnsiString; aMusic : Boolean; const aRoot : AnsiString );
    procedure SoundQuery( aKey, aValue : Variant );
    procedure MusicQuery( aKey, aValue : Variant );
    function FindAsset( const aID : AnsiString ) : TAudioAssetHandle;
    function SourceKey( const aEntry : TAudioEntry; const aFolder : AnsiString ) : AnsiString;
    function CountSound( aSoundID : Word ) : Byte;
    procedure UpdateHeartbeat;
  public
    constructor Create;
    procedure Reset;
    procedure Reconfigure;
    procedure Configure( aConfig : TLuaConfig; aReload : Boolean = False );
    function LoadBindingFile( const aFile, aRoot : AnsiString ) : Boolean;
    function LoadBindingDataFile( aData : TVDataFile; const aFile, aRoot : AnsiString ) : Boolean;
    procedure Load;
    procedure Update( aMSec : DWord );
    procedure PlaySound( const aSoundID : AnsiString; aVolumePercent : Integer = 100 ); overload;
    procedure PlaySound( aSoundID : Word; aCoord : TCoord2D; aDelay : DWord = 0 );
    procedure PlayMusic( const aMusicID : AnsiString; aNotFound : Boolean = False );
    procedure PlayMusicOnce( const aMusicID : AnsiString );
    function ResolveSoundID( const aResolveIDs : array of AnsiString ) : Word;
    function GetSampleID( const aID : AnsiString ) : Word;
    function SampleExists( const aID : AnsiString ) : Boolean;
    destructor Destroy; override;
  end;

implementation

uses sysutils, math, vdebug, vutil, vmath, vvector, vsdlaudio, vfmodaudio,
     drlio, drlbase, drlconfiguration, dfplayer, dfdata;

const MAX_SOUND_COUNT = 8;
      SOUND_DELAY_MIN = 10;
      SOUND_DELAY_MAX = 50;

function EventCompare( const aLeft, aRight : TSoundEvent ) : Integer;
begin
  if aLeft.Time < aRight.Time then Exit(1);
  if aLeft.Time > aRight.Time then Exit(-1);
  Result := 0;
end;

constructor TDRLAudio.Create;
begin
  FSoundEvents   := TSoundEventHeap.Create(@EventCompare);
  FSoundCounts   := TSoundCountArray.Create;
  FAudioRegistry := TAudioRegistry.Create;
  FAudioLookup   := TAudioLookup.Create;
  FSourceLookup  := TAudioLookup.Create;
  Reset;
end;

destructor TDRLAudio.Destroy;
begin
  FreeAndNil( FAudio );
  FreeAndNil( FSoundEvents );
  FreeAndNil( FSoundCounts );
  FreeAndNil( FAudioRegistry );
  FreeAndNil( FAudioLookup );
  FreeAndNil( FSourceLookup );
  inherited Destroy;
end;

procedure TDRLAudio.Reset;
begin
  if FAudio <> nil then FAudio.Reset;
  FSoundEvents.Clear;
  FSoundCounts.Clear;
  FAudioRegistry.Clear;
  FAudioLookup.Clear;
  FSourceLookup.Clear;

  FCurrentData := nil;
  FTime        := 0;
  FRoot        := '';
  FLastMusic   := '';

  FHeartbeatAsset    := 0;
  FHeartbeatInstance := 0;
  FHeartbeatEnabled  := True;
end;

procedure TDRLAudio.Reconfigure;
var iOldMusic : Integer;
begin
  if FAudio = nil then Exit;
  iOldMusic := Setting_MusicVolume;
  FHeartbeatEnabled := Configuration.GetBoolean('heartbeat_sound');
  Setting_MenuSound := Configuration.GetBoolean('menu_sound');
  Setting_MusicVolume := Configuration.GetInteger('volume_music');
  Setting_SoundVolume := Configuration.GetInteger('volume_sound');
  FAudio.SetSoundVolumePercent(Setting_SoundVolume);
  FAudio.SetMusicVolumePercent(Setting_MusicVolume);
  if Setting_MusicVolume = 0
    then FAudio.StopMusic
    else if iOldMusic = 0 then
      PlayMusic(FLastMusic);
end;

procedure TDRLAudio.Configure( aConfig : TLuaConfig; aReload : Boolean );
begin
  FSoundEvents.Clear;
  if not SoundVersion or (Option_SoundEngine = 'NONE') or
     not (Option_Music or Option_Sound) then Exit;
  if (FAudio = nil) and not aReload then
  begin
    if Option_SoundEngine = 'FMOD' then FAudio := TFMODAudio.Create
                                    else FAudio := TSDLAudio.Create;
  end
  else 
    if FAudio <> nil then
    begin
      FAudio.Reset;
      FSourceLookup.Clear;
    end;
  Reconfigure;
end;

procedure TDRLAudio.Register( const aID, aFileName : AnsiString; aMusic : Boolean; const aRoot : AnsiString );
var iIndex : Integer;
    iEntry : TAudioEntry;
begin
  iIndex := FAudioLookup.Get(aID, -1);
  iEntry.ID := aID;
  iEntry.FileName := aFileName;
  iEntry.Root := aRoot;
  iEntry.IsMusic := aMusic;
  iEntry.DataFile := FCurrentData;
  iEntry.Asset := 0;
  if iIndex >= 0 then
  begin
    if FAudioRegistry[iIndex].IsMusic <> aMusic then
    begin
      Log( LOGERROR, 'Audio ID type mismatch: '+aID );
      Exit;
    end;
    FAudioRegistry[iIndex] := iEntry;
  end
  else
  begin
    iIndex := FAudioRegistry.Size;
    FAudioRegistry.Push( iEntry );
    FAudioLookup[aID] := iIndex;
  end;
end;

procedure TDRLAudio.SoundQuery( aKey, aValue : Variant );
begin
  Register( LowerCase(AnsiString(aKey)), AnsiString(aValue), False, FRoot );
end;

procedure TDRLAudio.MusicQuery( aKey, aValue : Variant );
begin
  Register( LowerCase(AnsiString(aKey)), AnsiString(aValue), True, FRoot );
end;

function TDRLAudio.LoadBindingFile( const aFile, aRoot : AnsiString ) : Boolean;
var iState : TLuaConfig;
begin
  FCurrentData := nil;
  Result := False;
  if not FileExists(aFile) then Exit;
  iState := TLuaConfig.Create(aFile);
  try
    FRoot := aRoot;
    if Option_Music and iState.TableExists('music') then iState.EntryFeed('music', @MusicQuery);
    if Option_Sound and iState.TableExists('sound') then iState.RecEntryFeed('sound', @SoundQuery);
    Result := True;
  finally
    iState.Free;
  end;
end;

function TDRLAudio.LoadBindingDataFile( aData : TVDataFile; const aFile, aRoot : AnsiString ) : Boolean;
var iStream : TStream;
    iState  : TLuaConfig;
begin
  Result := False;
  if not aData.FileExists(aFile) then Exit;
  FCurrentData := aData;
  FRoot := aRoot;
  iStream := aData.GetFile(aFile);
  iState := TLuaConfig.Create;
  try
    iState.Load(iStream, aData.GetFileSize(aFile), aFile);
    if Option_Music and iState.TableExists('music') then iState.EntryFeed('music', @MusicQuery);
    if Option_Sound and iState.TableExists('sound') then iState.RecEntryFeed('sound', @SoundQuery);
    Result := True;
  finally
    iState.Free;
    iStream.Free;
  end;
end;

procedure TDRLAudio.Load;
var i         : DWord;
    iStream   : TStream;
    iEntry    : TAudioEntry;
    iFileName : AnsiString;
    iFolder   : AnsiString;
    iSource   : AnsiString;
begin
  if FAudio = nil then Exit;
  for i := 0 to FAudioRegistry.Size - 1 do
  begin
    iEntry := FAudioRegistry[i];
    iFileName := ExtractFileName(iEntry.FileName);
    if iEntry.IsMusic then iFolder := 'music' else iFolder := 'sound';
    iSource := SourceKey( iEntry, iFolder );

    iEntry.Asset := FSourceLookup.Get( iSource, 0 );
    if iEntry.Asset <> 0 then
    begin
      FAudioRegistry[i] := iEntry;
      Continue;
    end;

    try
      if (iEntry.DataFile <> nil) and iEntry.DataFile.FileExists(iFileName, iFolder) then
      begin
        iStream := iEntry.DataFile.GetFile(iFileName, iFolder);
        try
          if iEntry.IsMusic then iEntry.Asset := FAudio.Load(iStream, iStream.Size, iEntry.FileName, auMusic)
                            else iEntry.Asset := FAudio.Load(iStream, iStream.Size, iEntry.FileName, auSound);
        finally
          iStream.Free;
        end;
      end
      else if iEntry.IsMusic then iEntry.Asset := FAudio.Load(iEntry.Root+iEntry.FileName, auMusic)
                             else iEntry.Asset := FAudio.Load(iEntry.Root+iEntry.FileName, auSound);
    except
      on E : Exception do
      begin
        iEntry.Asset := 0;
        Log(LOGWARN, 'Unable to load audio "'+iEntry.ID+'": '+E.Message);
      end;
    end;
    if iEntry.Asset <> 0 then
      FSourceLookup[iSource] := iEntry.Asset;
    FAudioRegistry[i] := iEntry;
  end;
  FHeartbeatAsset := FindAsset( 'heartbeat' );
  IO.LoadProgress(100);
end;

function TDRLAudio.FindAsset( const aID : AnsiString ) : TAudioAssetHandle;
var iIndex : Integer;
begin
  iIndex := FAudioLookup.Get( aID, -1 );
  if iIndex < 0 then Exit( 0 );
  Result := FAudioRegistry[iIndex].Asset;
end;

function TDRLAudio.SourceKey( const aEntry : TAudioEntry; const aFolder : AnsiString ) : AnsiString;
begin
  if aEntry.DataFile <> nil then
    Result := 'vdf:' + IntToHex(PtrUInt(aEntry.DataFile), SizeOf(Pointer) * 2) + ':' +
              aFolder + ':' + ExtractFileName(aEntry.FileName)
  else
    Result := 'file:' + LowerCase(ExpandFileName(aEntry.Root + aEntry.FileName));

  if aEntry.IsMusic then
    Result := 'stream:' + Result
  else
    Result := 'preload:' + Result;
end;

function TDRLAudio.CountSound( aSoundID : Word ) : Byte;
var i       : Integer;
    iCount  : TSoundCount;
begin
  for i := 0 to FSoundCounts.Size - 1 do
    if FSoundCounts[i].SoundID = aSoundID then
    begin
      iCount := FSoundCounts[i];
      Inc( iCount.Count );
      FSoundCounts[i] := iCount;
      Exit( iCount.Count );
    end;

  iCount.SoundID := aSoundID;
  iCount.Count := 1;
  FSoundCounts.Push( iCount );
  Result := 1;
end;

procedure TDRLAudio.UpdateHeartbeat;
var iVolume : Integer;
begin
  if (DRL.State <> DSPlaying) or (FAudio = nil) or (FHeartbeatAsset = 0) or
     not FHeartbeatEnabled or (not Option_Sound) or SoundOff or
     (Setting_SoundVolume = 0) or (Player = nil) or Player.Dead or
     (Player.HP * 2 >= Player.HPMax) then
  begin
    if (FAudio <> nil) and (FHeartbeatInstance <> 0) then
      FAudio.Stop( FHeartbeatInstance );
    FHeartbeatInstance := 0;
    Exit;
  end;

  iVolume := Round( 200.0 * (Player.HPMax - 2 * Player.HP) / Max(Player.HPMax - 2, 1) );
  iVolume := Clamp( iVolume, 0, 100 );
  if not FAudio.IsPlaying( FHeartbeatInstance ) then
    FHeartbeatInstance := FAudio.Play( FHeartbeatAsset, iVolume, True )
  else
    FAudio.SetInstanceVolume( FHeartbeatInstance, iVolume );
end;

procedure TDRLAudio.Update( aMSec : DWord );
var iEvent : TSoundEvent;
begin
  FTime += aMSec;
  FSoundCounts.Clear;
  while not FSoundEvents.IsEmpty and (FSoundEvents.Top.Time <= FTime) do
  begin
    iEvent := FSoundEvents.Pop;
    PlaySound( iEvent.SoundID, iEvent.Coord );
  end;
  if FAudio <> nil then FAudio.Update(aMSec);
  UpdateHeartbeat;
end;

procedure TDRLAudio.PlaySound( const aSoundID : AnsiString; aVolumePercent : Integer );
var iAsset : TAudioAssetHandle;
begin
  if (FAudio = nil) or not Option_Sound or SoundOff or (Setting_SoundVolume = 0) then Exit;
  iAsset := FindAsset(aSoundID);
  if iAsset <> 0 then FAudio.Play(iAsset, aVolumePercent);
end;

procedure TDRLAudio.PlaySound( aSoundID : Word; aCoord : TCoord2D; aDelay : DWord );
var iEvent    : TSoundEvent;
    iCount    : Byte;
    iDistance : Integer;
    iVolume   : Integer;
begin
  if (aSoundID = 0) or (FAudio = nil) or not Option_Sound or SoundOff or (Setting_SoundVolume = 0) then Exit;
  if aDelay > 0 then
  begin
    iEvent.Coord := aCoord;
    iEvent.SoundID := aSoundID;
    iEvent.Time := FTime+aDelay;
    FSoundEvents.Insert( iEvent );
    Exit;
  end;

  iCount := CountSound( aSoundID );
  if iCount >= MAX_SOUND_COUNT then Exit;
  if iCount > 1 then
  begin
    PlaySound( aSoundID, aCoord, SOUND_DELAY_MIN + Random(SOUND_DELAY_MAX - SOUND_DELAY_MIN + 1) );
    Exit;
  end;
  iDistance := Distance(aCoord, Player.Position);
  if iDistance <= 1 then iVolume := 127 else iVolume := Clamp((25-iDistance)*6, 0, 127);
  if (iVolume > 0) and (iVolume < 30) then iVolume := 30;
  if iVolume > 0 then FAudio.Play(aSoundID, Round(iVolume * 100.0 / 127.0));
end;

function TDRLAudio.ResolveSoundID( const aResolveIDs : array of AnsiString ) : Word;
var i      : Integer;
    iAsset : TAudioAssetHandle;
begin
  Result := 0;
  if (FAudio = nil) or not Option_Sound or SoundOff then Exit;
  for i := Low(aResolveIDs) to High(aResolveIDs) do
  begin
    iAsset := FindAsset( aResolveIDs[i] );
    if iAsset <> 0 then Exit( Word(iAsset) );
  end;
end;

function TDRLAudio.GetSampleID( const aID : AnsiString ) : Word;
begin
  if (FAudio = nil) or not Option_Sound or SoundOff then Exit( 0 );
  Result := Word( FindAsset(aID) );
end;

function TDRLAudio.SampleExists( const aID : AnsiString ) : Boolean;
begin
  Result := FindAsset(aID) <> 0;
end;

procedure TDRLAudio.PlayMusic( const aMusicID : AnsiString; aNotFound : Boolean );
var iAsset : TAudioAssetHandle;
begin
  FLastMusic := aMusicID;
  if (FAudio = nil) or not Option_Music or (Setting_MusicVolume = 0) then Exit;
  if aMusicID = '' then
  begin
    FAudio.StopMusic;
    Exit;
  end;
  if MusicOff then Exit;
  iAsset := FindAsset(aMusicID);
  if iAsset <> 0 then FAudio.PlayMusic(iAsset)
  else if not aNotFound then PlayMusic('level'+IntToStr(Random(23)+2), True);
end;

procedure TDRLAudio.PlayMusicOnce( const aMusicID : AnsiString );
var iAsset : TAudioAssetHandle;
begin
  if (FAudio = nil) or not Option_Music or (Setting_MusicVolume = 0) or MusicOff then Exit;
  if aMusicID = '' then
  begin
    FAudio.StopMusic;
    Exit;
  end;
  iAsset := FindAsset( aMusicID );
  if iAsset <> 0 then FAudio.PlayMusic( iAsset, False );
end;

end.
