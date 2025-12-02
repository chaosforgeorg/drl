{$INCLUDE drl.inc}
{
----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit dfplayer;
interface
uses classes, sysutils,
     vuielement,vpath, vutil, vrltools, vuitypes,
     dfbeing, dfhof, dfdata, dfitem,
     drltraits, drlkeybindings, drlstatistics, drlmultimove;


type TQuickSlotInfo = record
  UID : TUID;
  ID  : string[32];
end;

{ TPlayer }

type TPlayer = class(TBeing)
  NukeActivated   : Word;

  InventorySize   : Byte;
  MasterDodge     : Boolean;
  FKills          : TKillTable;
  FKillMax        : DWord;
  FKillCount      : DWord;

  FQuickSlots     : array[1..9] of TQuickSlotInfo;

  constructor Create; reintroduce;
  procedure Initialize; reintroduce;
  constructor CreateFromStream( Stream: TStream ); override;
  procedure WriteToStream( Stream: TStream ); override;
  function CallHook( aHook : Byte; const aParams : array of Const ) : Boolean; override;
  function CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean; override;
  function CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean; override;
  function GetBonus( aHook : Byte; const aParams : array of Const ) : Integer; override;
  function GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single; override;
  function PlayerTick : Boolean;
  procedure HandlePostMove; override;
  procedure PreAction;
  procedure PostAction;
  function GetMultiMoveInput : TInputKey;
  procedure LevelEnter;
  procedure doUpgradeTrait;
  procedure RegisterKill( const aKilledID : AnsiString; aKiller : TBeing; aWeapon : TItem; aUnique : Boolean );
  procedure ApplyDamage( aDamage : LongInt; aTarget : TBodyTarget; aDamageType : TDamageType; aSource : TItem; aDelay : Integer ); override;
  procedure LevelUp;
  procedure AddExp( aAmount : LongInt );
  procedure WriteMemorial;
  destructor Destroy; override;
  procedure Kill( aBloodAmount : DWord; aOverkill : Boolean; aKiller : TBeing; aWeapon : TItem; aDelay : Integer ); override;
  procedure AddHistory( const aHistory : Ansistring );
  class procedure RegisterLuaAPI();
  procedure UpdateVisual;
  function ASCIIMoreCode : AnsiString; override;
  function RunPath( const aCoord : TCoord2D ) : Boolean;
  procedure ExamineNPC;
  procedure ExamineItem;
  procedure NextLevelIndex;
  function GetSprite: TSprite; override;
  function GetPerkEffect : TStatusEffect;
private
  FLevelIndex     : Integer;
  FExp            : LongInt;
  FExpLevel       : Byte;
  FKlass          : Byte;
  FScore          : LongInt;
  FExpFactor      : Real;
  FEnemiesInVision: Word;
  FKilledBy       : AnsiString;
  FKilledMelee    : Boolean;
  FLastTurnDodge  : Boolean;

  FTraits         : TTraits;
  FStatistics     : TStatistics;
  FMultiMove      : TMultiMove;
  FCSprite        : TSprite;
public
  property MultiMove       : TMultiMove  read FMultiMove;
  property Statistics      : TStatistics read FStatistics;
  property Traits          : TTraits     read FTraits;
published
  property KilledBy        : AnsiString read FKilledBy;
  property KilledMelee     : Boolean    read FKilledMelee;
  property LastTurnDodge   : Boolean    read FLastTurnDodge write FLastTurnDodge;
  property Exp             : LongInt    read FExp           write FExp;
  property ExpLevel        : Byte       read FExpLevel      write FExpLevel;
  property NukeTime        : Word       read NukeActivated  write NukeActivated;
  property Klass           : Byte       read FKlass         write FKlass;
  property ExpFactor       : Real       read FExpFactor     write FExpFactor;
  property Score           : LongInt    read FScore         write FScore;
  property Level_Index     : Integer    read FLevelIndex    write FLevelIndex;
  property EnemiesInVision : Word       read FEnemiesInVision;
end;

var Player     : TPlayer;
    MortemData : TUIStringArray = nil;

implementation

uses math, vuid, variants, vioevent, vgenerics,
     vnode, vcolor, vdebug, vluasystem, vluastate, vtig,
     dfmap, dflevel,
     drlhooks, drlio, drlspritemap, drlbase, drlperk,
     drlua, drlinventory, drlplayerview, drlhudviews;

constructor TPlayer.Create;
var iState : TLuaState;
begin
  inherited Create('soldier');

  FTraits    := TTraits.Create;
  FKills     := TKillTable.Create;
  FKillMax   := 0;
  FKillCount := 0;

  FLevelIndex   := 0;
  StatusEffect  := StatusNormal;
  FStatistics   := TStatistics.Create;
  FScore        := 0;
  NukeActivated := 0;
  FExpLevel   := 1;
  FKlass      := 1;
  FExp        := ExpTable[ FExpLevel ];

  InventorySize := High( TItemSlot );
  FExpFactor := 1.0;

  Initialize;
  iState.Init( drlbase.Lua.Raw );
  iState.ClearLuaProperties( Self );

  FillChar( FQuickSlots, SizeOf(FQuickSlots), 0 );
  CallHook( Hook_OnCreate, [] );
end;

procedure TPlayer.Initialize;
begin
  FKilledBy       := '';
  FKilledMelee    := False;

  FEnemiesInVision:= 0;
  FMultiMove      := TMultiMove.Create;
  FPath           := TPathFinder.Create(Self);
  MemorialWritten := False;
  MasterDodge     := False;
  FLastTurnDodge  := False;

  drlbase.Lua.RegisterPlayer(Self);
end;

procedure TPlayer.WriteToStream ( Stream : TStream ) ;
begin
  inherited WriteToStream( Stream );

  Stream.Write( FLevelIndex, SizeOf( FLevelIndex ) );
  Stream.WriteWord( NukeActivated );
  Stream.WriteByte( InventorySize );
  Stream.WriteByte( FExpLevel );
  Stream.WriteByte( FKlass );
  Stream.WriteDWord( FExp );
  Stream.WriteDWord( FScore );
  Stream.WriteDWord( FKillMax );
  Stream.WriteDWord( FKillCount );

  Stream.Write( FLastTurnDodge, SizeOf( FLastTurnDodge ) );
  Stream.Write( FExpFactor,     SizeOf( FExpFactor ) );
  Stream.Write( FQuickSlots,    SizeOf( FQuickSlots ) );
  Stream.Write( FCSprite,       SizeOf( FCSprite ) );

  FTraits.WriteToStream( Stream );
  FKills.WriteToStream( Stream );
  FStatistics.WriteToStream( Stream );
end;

constructor TPlayer.CreateFromStream ( Stream : TStream ) ;
begin
  inherited CreateFromStream( Stream );

  Stream.Read( FLevelIndex, SizeOf( FLevelIndex ) );
  NukeActivated  := Stream.ReadWord();
  InventorySize  := Stream.ReadByte();
  FExpLevel      := Stream.ReadByte();
  FKlass         := Stream.ReadByte();
  FExp           := Stream.ReadDWord();
  FScore         := Stream.ReadDWord();
  FKillMax       := Stream.ReadDWord();
  FKillCount     := Stream.ReadDWord();

  Stream.Read( FLastTurnDodge, SizeOf( FLastTurnDodge ) );
  Stream.Read( FExpFactor,     SizeOf( FExpFactor ) );
  Stream.Read( FQuickSlots,    SizeOf( FQuickSlots ) );
  Stream.Read( FCSprite,       SizeOf( FCSprite ) );

  FTraits         := TTraits.CreateFromStream( Stream );
  FKills          := TKillTable.CreateFromStream( Stream );
  FStatistics     := TStatistics.CreateFromStream( Stream );

  Initialize;
end;

function TPlayer.CallHook( aHook : Byte; const aParams : array of Const ) : Boolean;
begin
  CallHook := FTraits.CallHook( aHook, aParams );
  if inherited CallHook( aHook, aParams ) then
    CallHook := True;
  if FInv.CallHook( aHook, False, aParams ) then
    CallHook := True;
end;

function TPlayer.CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean;
begin
  if not ( inherited CallHookCheck( aHook, aParams ) ) then Exit ( False );
  Exit( FTraits.CallHookCheck( aHook, aParams ) );
end;

function TPlayer.CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean;
begin
  if ( inherited CallHookCan( aHook, aParams ) ) then Exit ( true );
  Exit( FTraits.CallHookCan( aHook, aParams ) );
end;

function TPlayer.GetBonus( aHook : Byte; const aParams : array of Const ) : Integer;
begin
  GetBonus := inherited GetBonus( aHook, aParams );
  GetBonus += FTraits.GetBonus( aHook, aParams );
end;

function TPlayer.GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
begin
  GetBonusMul := inherited GetBonusMul( aHook, aParams );
  GetBonusMul *= FTraits.GetBonusMul( aHook, aParams );
end;

procedure TPlayer.LevelUp;
begin
  Inc( FExpLevel );
  IO.Blink( LightBlue, 100 );

  IO.Msg( 'You advance to level %d!', [ FExpLevel ] );
  IO.PushLayer( TMoreLayer.Create( False ) );
  IO.WaitForLayer( False );

  if not DRL.CallHookCheck( Hook_OnPreLevelUp, [ FExpLevel ] ) then Exit;
  IO.BloodSlideDown( 20 );
  doUpgradeTrait();
  DRL.CallHook( Hook_OnLevelUp, [ FExpLevel ] );
end;

procedure TPlayer.AddExp( aAmount : LongInt );
begin
  if Dead then Exit;
  aAmount := Round( aAmount * FExpFactor );
  FExp += aAmount;
end;

procedure TPlayer.ApplyDamage(aDamage: LongInt; aTarget: TBodyTarget; aDamageType: TDamageType; aSource : TItem; aDelay : Integer );
begin
  if aDamage < 0 then Exit;
  if BF_INV in FFlags then Exit;
  FMultiMove.Stop;
  DRL.DamagedLastTurn := True;
  if ( aDamage >= Max( FHPMax div 3, 10 ) ) then
  begin
    IO.Blink( Red, 100 );
    IO.addRumbleAnimation( aDelay, $6000, $4000, 250 );
  end
  else
    IO.addRumbleAnimation( aDelay, $4000, $2000, 100 );

  if aDamage > 0 then FKills.DamageTaken;

  inherited ApplyDamage(aDamage, aTarget, aDamageType, aSource, aDelay );
end;

procedure TPlayer.RegisterKill ( const aKilledID : AnsiString; aKiller : TBeing; aWeapon : TItem; aUnique : Boolean ) ;
var iKillClass : AnsiString;
begin
  iKillClass := 'other';
  if ( aKiller = Self ) and ( TLevel(Parent).ActiveBeing = Self ) then
  begin
    if FMeleeAttack   then iKillClass := 'melee';
    if aWeapon <> nil then iKillClass := aWeapon.ID;
  end;
  FKills.Add( aKilledID, iKillClass );
  if aUnique then Inc( FKillCount );
end;

function TPlayer.RunPath( const aCoord : TCoord2D ) : boolean;
begin
  FPathHazards := [];
  FPathClear   := [];
  if FPath.Run( FPosition, aCoord, 200) then
  begin
    FMultiMove.Start( FPath );
    Exit( True );
  end;
  Exit( False );
end;

function TPlayer.PlayerTick : Boolean;
var iThisUID    : DWord;
begin
  iThisUID := UID;
  TLevel(Parent).CallHook( FPosition, Self, CellHook_OnEnter );
  if UIDs[ iThisUID ] = nil then Exit( False );

  MasterDodge := False;
  if DRL.State <> DSPlaying then Exit( False );
  Inv.OnUpdate;
  FLastPos := FPosition;
  FMeleeAttack := False;
  Exit( True );
end;

procedure TPlayer.HandlePostMove;

  function RunStopNear : boolean;
  begin
    if TLevel( Parent ).isProperCoord( FPosition.ifIncX(+1) ) and TLevel( Parent ).cellFlagSet( FPosition.ifIncX(+1), CF_RUNSTOP ) then Exit( True );
    if TLevel( Parent ).isProperCoord( FPosition.ifIncX(-1) ) and TLevel( Parent ).cellFlagSet( FPosition.ifIncX(-1), CF_RUNSTOP ) then Exit( True );
    if TLevel( Parent ).isProperCoord( FPosition.ifIncY(+1) ) and TLevel( Parent ).cellFlagSet( FPosition.ifIncY(+1), CF_RUNSTOP ) then Exit( True );
    if TLevel( Parent ).isProperCoord( FPosition.ifIncY(-1) ) and TLevel( Parent ).cellFlagSet( FPosition.ifIncY(-1), CF_RUNSTOP ) then Exit( True );
    Exit( False );
  end;

begin
  inherited HandlePostMove;
  if FMultiMove.IsRepeat then
    if RunStopNear or ((not Setting_RunOverItems) and (TLevel( Parent ).Item[ FPosition ] <> nil)) then
      FMultiMove.Stop;
end;

function TPlayer.GetMultiMoveInput : TInputKey;
begin
  GetMultiMoveInput := INPUT_NONE;
  if FMultiMove.Active then
  begin
    if BF_SESSILE in FFlags then
    begin
      FMultiMove.Stop;
      Fail('You can''t!',[] );
      Exit( INPUT_NONE );
    end;

    Exit( FMultiMove.CalculateInput( FPosition ) );
  end;
end;

procedure TPlayer.PreAction;
var iLevel      : TLevel;
begin
  iLevel := TLevel( Parent );

  if iLevel.Item[ FPosition ] <> nil then
  begin
    if not FMultiMove.IsPath then
      IO.Msg( iLevel.Item[ FPosition ].GetExtName( True ) );
  end;

  FEnemiesInVision := iLevel.GetEnemiesVisible;
  if FEnemiesInVision > 0
    then FMultiMove.Stop
    else FChainFire := 0;

  if FMultiMove.Active then
  begin
    if IO.CommandEventPending then
    begin
      IO.Msg('Stop.');
      FMultiMove.Stop;
      IO.ClearEventBuffer;
    end
    else
    begin
      if not GraphicsVersion then
        IO.Delay( Option_RunDelay );
    end;
  end;

  CallHook(Hook_OnPreAction,[]);
end;

procedure TPlayer.PostAction;
begin
  if not Dead then
    if FExpLevel < MaxPlayerLevel - 1 then
      while FExp >= ExpTable[ FExpLevel + 1 ] do
        LevelUp;

  CallHook(Hook_OnPostAction,[]);
  if DRL.State <> DSPlaying then Exit;
  FLastTurnDodge := False;
  UpdateVisual;
end;

procedure TPlayer.LevelEnter;
begin
  if FHP < (FHPMax div 10) then
    AddHistory('Entering @1 he was almost dead...');

  FStatistics.OnLevelEnter;

  FTargetPos.Create(0,0);
  FChainFire := 0;
end;

procedure TPlayer.ExamineNPC;
var iLevel : TLevel;
    iWhere : TCoord2D;
    iCount : Word;
begin
  iLevel := TLevel(Parent);
  iCount := 0;
  for iWhere in iLevel.Area do
    if iLevel.isVisible(iWhere) and ( iLevel.Being[iWhere] <> nil ) and (iWhere <> FPosition) then
    with iLevel.Being[iWhere] do
    begin
      Inc(iCount);
      IO.Msg('You see '+ GetName(false) + ' (' + WoundStatus + ') ' + BlindCoord(iWhere-Self.FPosition)+'.');
    end;
  if iCount = 0 then IO.Msg('There are no monsters in sight.');
end;

procedure TPlayer.ExamineItem;
var iLevel : TLevel;
    iWhere : TCoord2D;
    iCount : Word;
begin
  iLevel := TLevel(Parent);
  iCount := 0;
  for iWhere in iLevel.Area do
    if iLevel.isVisible(iWhere) then
      if iLevel.Item[iWhere] <> nil then
      with iLevel.Item[iWhere] do
      begin
        Inc(iCount);
        IO.Msg('You see '+ GetName(false) + ' ' + BlindCoord(iWhere-Self.FPosition)+'.');
      end;
  if iCount = 0 then IO.Msg('There are no items in sight.');
end;

procedure TPlayer.NextLevelIndex;
begin
  Inc(FLevelIndex);
end;

function TPlayer.GetSprite : TSprite;
begin
  Exit(FCSprite);
end;

function TPlayer.GetPerkEffect : TStatusEffect;
var iCount    : DWord;
    iStrength : DWord;
begin
  GetPerkEffect := StatusNormal;
  if ( FPerks = nil ) or ( FPerks.List.Size = 0 ) then Exit;
  iStrength     := 0;
  for iCount := 0 to FPerks.List.Size - 1 do
    with PerkData[FPerks.List[iCount].ID] do
      if StatusStr > iStrength then
      begin
        GetPerkEffect := StatusEff;
        iStrength     := StatusStr;
      end;
end;


// pieczarki oliwki szynka kielbasa peperoni motzarella //

destructor TPlayer.Destroy;
begin
  FreeAndNil( FStatistics );
  FreeAndNil( FKills );
  FreeAndNil( FMultiMove );
  FreeAndNil( FTraits );
  inherited Destroy;
end;

procedure TPlayer.Kill( aBloodAmount : DWord; aOverkill : Boolean; aKiller : TBeing; aWeapon : TItem; aDelay : Integer );
var iLevel   : TLevel;
    iSlot    : TEqSlot;
begin
  iLevel := TLevel(Parent);
  if (DRL.State <> DSPlaying) and IsPlayer then Exit;

  for iSlot in TEqSlot do
    if FInv.Slot[ iSlot ] <> nil then
      if not FInv.Slot[ iSlot ].CallHookCheck( Hook_OnDieCheck, [ aOverkill ] ) then
      begin
        HP := Max(1,HP);
        Exit;
      end;

  if not CallHookCheck( Hook_OnDieCheck, [ aOverkill ] ) then
  begin
    HP := Max(1,HP);
    Exit;
  end;

  if (aKiller <> nil) and (not DRL.GameWon) then
  begin
    FKilledBy          := aKiller.ID;
    FKilledMelee       := aKiller.MeleeAttack;
  end;

  Blood( NewDirection(0,0),15 );
  iLevel.DropCorpse( FPosition, GetLuaProtoValue('corpse') );

  if aOverkill
     then iLevel.playSound( 'gib',FPosition )
     else PlaySound( 'die' );

  IO.addKillAnimation( 1000, aDelay, Self );
  IO.WaitForAnimation;
  FAnimCount := 1;

  begin
    IO.Msg('You die!...');
    IO.PushLayer( TMoreLayer.Create( False ) );
    IO.WaitForLayer( False );
  end;
  DRL.SetState( DSFinished );

  if NukeActivated > 0 then
  begin
    NukeActivated := 1;
    iLevel.NukeTick;
    IO.WaitForAnimation;
  end;
  WriteMemorial;
end;

procedure TPlayer.WriteMemorial;
var iCopyText   : Text;
    iMortemText : Text;
    iString     : AnsiString;

procedure ScoreCRC(var aScore : LongInt);
begin
  if aScore < 2000 then Exit;
  while not ((aScore mod 277) = 0) do Inc(aScore);
  Inc(aScore,FExpLevel);
  Inc(aScore,FLevelIndex*3);
end;

begin
  if MemorialWritten then Exit;
  MemorialWritten := True;
  if FScore = -1000 then Exit;

  FStatistics.Update;
  DRL.CallHook(Hook_OnMortem,[ not NoPlayerRecord ]);
  if LuaSystem.Defined([CoreModuleID,'RunAwards']) then
    LuaSystem.ProtectedCall([CoreModuleID,'RunAwards'],[NoPlayerRecord]);

  if LuaSystem.Defined([CoreModuleID,'GetScore']) then
  begin
    FScore := LuaSystem.ProtectedCall([CoreModuleID,'GetScore'],[])
  end
  else
  begin
    FScore += Max(FExp + (FLevelIndex * 1000) + Max(FHP,0) * 20,0);
    if FScore < 0 then FScore := 0;
    if DRL.Difficulty = DIFF_NIGHTMARE then FScore -= FStatistics.GameTime div 500;

    if DRL.GameWon then FScore += FScore div 4;
    FScore := Round( FScore * Double(LuaSystem.Get([ 'diff', DRL.Difficulty, 'scorefactor' ])) );
    // FScore
    ScoreCRC(FScore);
  end;
  if GodMode then FScore := 0;
  if FScore > 0 then
  begin
    DRL.Store.IncStat('drl_kills', FKills.Count );
    if FHP <= 0    then DRL.Store.IncStat( 'drl_deaths' );
    if DRL.GameWon then DRL.Store.IncStat( 'drl_wins' );
  end;

  HOF.Add(Name,FScore,FKilledBy,FExpLevel,FLevelIndex,DRL.Challenge,DRL.Level.Abbr);

  if Assigned( MortemData ) then
  begin
    Log( LOGERROR, 'Mortem data not cleared!');
    FreeAndNil( MortemData );
  end;
  MortemData := TUIStringArray.Create;
  LuaSystem.ProtectedCall([CoreModuleID,'RunPrintMortem'],[]);
  Assign(iMortemText, ModuleUserPath + 'mortem.txt' );
  Rewrite(iMortemText);
  for iString in MortemData do
    Writeln( iMortemText, VTIG_StripTags( iString ) );
  Close(iMortemText);

  FScore := -1000;

  if Option_MortemArchive then
  begin
    iString :=  ModuleUserPath + 'mortem'+PathDelim+ToProperFilename('['+FormatDateTime(Option_TimeStamp,Now)+'] '+Name)+'.txt';
    Assign(iCopyText,iString);
    Log('Writing mortem...: '+iString);
    Rewrite(iCopyText);
    Assign(iMortemText, ModuleUserPath + 'mortem.txt');
    Reset(iMortemText);
    
    while not EOF(iMortemText) do
    begin
      Readln(iMortemText,iString);
      Writeln(iCopyText,iString);
    end;

    Close(iCopyText);
    Close(iMortemText);
  end;
end;

procedure TPlayer.AddHistory( const aHistory : Ansistring );
begin
  LuaSystem.ProtectedCall(['player','add_history'],[ Self, aHistory ]);
end;

procedure TPlayer.UpdateVisual;
var Spr       : LongInt;
    Gray      : TColor;
    iWeapon   : TItem;
    iSpMod    : Integer;
    iPDSprite : Integer;
begin
  Color  := LightGray;
  iSpMod := 0;
  FCSprite := FSprite;
  if Inv.Slot[ efTorso ] <> nil then
    Color := Inv.Slot[ efTorso ].Color;
  Gray := NewColor( 200,200,200 );
  Include( FCSprite.Flags, SF_COSPLAY );
  FCSprite.GlowColor := ColorZero;
  FCSprite.Color     := GRAY;
  if Inv.Slot[ efTorso ] <> nil then
  begin
    if Inv.Slot[ efTorso ].PGlowColor.A > 0 then
      FCSprite.GlowColor := Inv.Slot[ efTorso ].PGlowColor;
    FCSprite.Color     := Inv.Slot[ efTorso ].PCosColor;
    iSpMod            := Inv.Slot[ efTorso ].SpriteMod;
  end
  else
  begin
    iSpMod := FSpriteMod;
    FCSprite.Color := FSprite.Color;
  end;
  iWeapon := Inv.Slot[ efWeapon ];
  if iWeapon <> nil then
  begin
    iPDSprite := LuaSystem.Get( ['items', iWeapon.ID, 'pdsprite'], 0 );
    if ( iPDSprite <> 0 ) and ( canDualWield )
      then FCSprite.SpriteID[0] := iPDSprite
      else FCSprite.SpriteID[0] := LuaSystem.Get( ['items', iWeapon.ID, 'psprite'], 0 );
    if FCSprite.SpriteID[0] <> 0 then
    begin
      FCSprite.SpriteID[0] := FCSprite.SpriteID[0] + iSpMod;
      Exit;
    end;
    // HACK via the spritesheet
    Spr := Inv.Slot[ efWeapon ].Sprite.SpriteID[0] - SpriteCellRow;
    if (Spr <= 12) and (Spr >= 1) then
      FCSprite.SpriteID[0] := Spr
    else
      if Inv.Slot[ efWeapon ].isMelee then FCSprite.SpriteID[0] := 2 else FCSprite.SpriteID[0] := 11;
  end
  else
    FCSprite.SpriteID[0] := LuaSystem.Get( ['beings', ID, 'sprite'], 0 ) + iSpMod;
end;

function TPlayer.ASCIIMoreCode : AnsiString;
begin
  if (Inv.Slot[efTorso] <> nil) and (IO.ASCII.Exists(Inv.Slot[efTorso].ID)) then
    exit(Inv.Slot[efTorso].ID);
  Exit('player');
end;

procedure TPlayer.doUpgradeTrait;
begin
  if DemoVersion and (ExpLevel > 7) then Exit;
  IO.PushLayer( TPlayerView.CreateTrait( False ) );
  IO.WaitForLayer( True );
end;

function lua_player_add_exp(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if not (Being is TPlayer) then Exit(0);
  Player.addExp(State.ToInteger(2));
  Result := 0;
end;


function lua_player_has_won(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
begin
  State.Init(L);
  State.Push(DRL.GameWon);
  Result := 1;
end;

function lua_player_resort_stacks(L: Plua_State): Integer; cdecl;
var State     : TDRLLuaState;
    Being     : TBeing;
    Item      : TItem;
    Node, Temp: TNode;
var List : TItemList;
    Cnt  : Byte;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if not (Being is TPlayer) then Exit(0);

  for Cnt in TItemSlot do
    List[ Cnt ] := nil;

  Cnt := 0;
  for Node in Player do
    if Node is TItem then
      if (Node as TItem).isStackable then
      begin
        Inc( Cnt );
        List[ Cnt ] := Node as TItem;
      end;

  Temp := TNode.Create;
  for Item in List do
    if Item <> nil then
      Temp.Add( Item );

  for Node in Temp do
    with Node as TItem do
      Player.Inv.AddStack( NID, Amount );

  FreeAndNil( Temp );
  Result := 0;
end;

function lua_player_win(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if not (Being is TPlayer) then Exit(0);
  IO.FadeOut(1.0);
  DRL.SetState( DSFinished );
  DRL.GameWon := True;
  Result := 0;
end;

function lua_player_choose_trait(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if not (Being is TPlayer) then Exit(0);
  Player.doUpgradeTrait();
  Result := 0;
end;

function lua_player_level_up(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iBeing : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  if not (iBeing is TPlayer) then Exit(0);
  Player.LevelUp();
  Result := 0;
end;

function lua_player_exit(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iBeing : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  if not (iBeing is TPlayer) then Exit(0);
  if DRL.State <> DSSaving then
  begin
    if iState.IsNumber(3) then
      IO.FadeOut( iState.ToFloat(3) );
    DRL.SetState( DSNextLevel );
  end;
  Player.FSpeedCount := 4000;
  if iState.IsNil(2) then Exit( 0 );
  if iState.IsNumber(2) then
  begin
    Player.FLevelIndex := iState.ToInteger(2)-1;
    Exit(0);
  end;
  iState.Error('Player.exit - bad parameters!');
  Result := 0;
end;

function lua_player_quick_weapon(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if not (Being is TPlayer) then Exit(0);
  Player.ActionQuickWeapon(State.ToString(2));
  Result := 0;
end;

function lua_player_set_inv_size(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
    n : byte;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if not (Being is TPlayer) then Exit(0);
  n := State.ToInteger(2);
  if (n = 0) or (n > High(TItemSlot)) then
    State.Error( 'Inventory size must be in the 1..'+IntToStr(High(TItemSlot))+' range!' );
  Player.InventorySize := n;
  Result := 0;
end;


function lua_player_mortem_print(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if not (Being is TPlayer) then Exit(0);
  if not Assigned( MortemData ) then raise Exception.Create('player:mortem_print called in wrong place!');
  MortemData.Push( State.ToString(2) );
  Result := 0;
end;

function lua_player_get_trait(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if not (Being is TPlayer) then Exit(0);
  State.Push( Player.Traits[ State.ToInteger( 2 ) ] );
  Result := 1;
end;

function lua_player_get_trait_hist(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if not (Being is TPlayer) then Exit(0);
  State.Push( Player.Traits.GetHistory );
  Result := 1;
end;

function lua_player_set_achievement(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iID    : Ansistring;
begin
  iState.Init(L);
  if (iState.ToObject(1) as TPlayer) = nil then Exit(0);
  iID := iState.ToString(2);
  if DRL.Store.SetAchievement( iID ) then
    Log( LOGINFO, 'lua: set_achievement('+iID+') succeeded!');
  Result := 0;
end;

function lua_player_store_inc_stat(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iID    : Ansistring;
begin
  if GodMode then Exit(0);
  iState.Init(L);
  if (iState.ToObject(1) as TPlayer) = nil then Exit(0);
  iID := iState.ToString(2);
  if DRL.Store.IncStat( iID ) then
    Log( LOGINFO, 'lua: store_inc_stat('+iID+') succeeded!');
  Result := 0;
end;

function lua_player_store_mark_stat(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iID    : Ansistring;
begin
  if GodMode then Exit(0);
  iState.Init(L);
  if (iState.ToObject(1) as TPlayer) = nil then Exit(0);
  iID := iState.ToString(2);
  if DRL.Store.MarkStat( iID ) then
    Log( LOGINFO, 'lua: store_mark_stat('+iID+') succeeded!');
  Result := 0;
end;

const lua_player_lib : array[0..15] of luaL_Reg = (
      ( name : 'set_achievement'; func : @lua_player_set_achievement),
      ( name : 'store_inc_stat';  func : @lua_player_store_inc_stat),
      ( name : 'store_mark_stat'; func : @lua_player_store_mark_stat),
      ( name : 'add_exp';         func : @lua_player_add_exp),
      ( name : 'has_won';         func : @lua_player_has_won),
      ( name : 'get_trait';       func : @lua_player_get_trait),
      ( name : 'get_trait_hist';  func : @lua_player_get_trait_hist),
      ( name : 'resort_stacks';   func : @lua_player_resort_stacks),
      ( name : 'win';             func : @lua_player_win),
      ( name : 'choose_trait';    func : @lua_player_choose_trait),
      ( name : 'level_up';        func : @lua_player_level_up),
      ( name : 'exit';            func : @lua_player_exit),
      ( name : 'quick_weapon';    func : @lua_player_quick_weapon),
      ( name : 'set_inv_size';    func : @lua_player_set_inv_size),
      ( name : 'mortem_print';    func : @lua_player_mortem_print),
      ( name : nil;               func : nil; )
);

class procedure TPlayer.RegisterLuaAPI();
begin
  LuaSystem.Register( 'player', lua_player_lib );
end;

end.
