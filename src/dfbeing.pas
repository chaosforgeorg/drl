{$INCLUDE drl.inc}
{
----------------------------------------------------
DFBEING.PAS -- Creature control and data in DRL
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit dfbeing;
interface
uses Classes, SysUtils,
     vluatable, vnode, vpath, vmath, vutil, vrltools,
     dfdata, dfthing, dfitem,
     drlinventory, drlcommand;

type TMoveResult = ( MoveOk, MoveBlock, MoveDoor, MoveBeing );

type TBeingTimes = record
  Reload : Byte;
  Fire   : Byte;
  Move   : Byte;
  Use    : Byte;
  Wear   : Byte;
end;

type

{ TBeing }

TBeing = class(TThing,IPathQuery)
    constructor Create( nid : byte ); overload;
    constructor Create( const nid : AnsiString ); overload;
    constructor CreateFromStream( Stream: TStream ); override;
    procedure WriteToStream( Stream: TStream ); override;
    procedure Initialize;
    function GetName( known : boolean ) : string;
    procedure Tick; override;
    procedure Action; virtual;
    procedure HandlePostMove; virtual;
    procedure HandlePostDisplace;
    function HandleCommand( aCommand : TCommand ) : Boolean;
    function  TryMove( aWhere : TCoord2D ) : TMoveResult;
    function  MoveTowards( aWhere : TCoord2D; aVisualMultiplier : Single = 1.0 ) : TMoveResult;
    procedure Reload( aAmmoItem : TItem; aSingle : Boolean );
    function Resurrect( aRange : Integer ) : TBeing;
    procedure Kill( aBloodAmount : DWord; aOverkill : Boolean; aKiller : TBeing; aWeapon : TItem; aDelay : Integer ); virtual;
    procedure Blood( aFrom : TDirection; aAmount : LongInt );
    function Attack( aWhere : TCoord2D; aMoveOnKill : Boolean ) : Boolean; overload;
    function Attack( aTarget : TBeing; aSecond : Boolean = False ) : Boolean; overload;
    function meleeWeaponSlot : TEqSlot;
    function getTotalResistance( const aResistance : AnsiString; aTarget : TBodyTarget ) : Integer;
    procedure ApplyDamage( aDamage : LongInt; aTarget : TBodyTarget; aDamageType : TDamageType; aSource : TItem; aDelay : Integer ); virtual;
    function calculateToHit( aBeing : TBeing ) : Integer;
    function SendMissile( aTarget : TCoord2D; aItem : TItem; aAltFire : TAltFire; aSequence : DWord; aShotCount : Integer ) : Boolean;
    function  isActive : boolean;
    function  WoundStatus : string;
    function  IsPlayer : Boolean;
    function GetBonus( aHook : Byte; const aParams : array of Const ) : Integer; override;
    function GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single; override;
    procedure BloodFloor;
    procedure Knockback( aDir : TDirection; aStrength : Single );
    destructor Destroy; override;
    function rollMeleeDamage( aSlot : TEqSlot = efWeapon; aTarget : TBeing = nil ) : Integer;
    function getMoveCost : LongInt;
    function getFireCost( aAltFire : TAltFire; aIsMelee : Boolean ) : LongInt;
    function getReloadCost( aItem : TItem ) : LongInt;
    function getUseCost( aItem : TItem ) : LongInt;
    function getWearCost( aItem : TItem ) : LongInt;
    function getDodgeMod : LongInt;
    function getKnockMod : LongInt;
    function getToHit( aItem : TItem; aAltFire : TAltFire; aIsMelee : Boolean ) : Integer;
    function getToDam( aItem : TItem; aAltFire : TAltFire; aIsMelee : Boolean ) : Integer;
    function canDualWield : boolean;
    function canDualWieldMelee : boolean;
    function canPackReload : Boolean;
    function getStrayChance( aDefender : TBeing; aWeapon : TItem ) : Byte;
    function Preposition( Creature : AnsiString ) : string;
    function Dead : Boolean;
    procedure Remove( Node : TNode ); override;
    function ASCIIMoreCode : AnsiString; virtual;

    // Actions
    // All actions return True/False depending on success.
    // On success they do eat up action cost!
    function ActionSwapWeapon : boolean;
    function ActionQuickKey( aIndex : Byte ) : Boolean;
    function ActionQuickWeapon( const aWeaponID : Ansistring ) : Boolean;
    function ActionDrop( aItem : TItem; aUnload : Boolean ) : boolean;
    function ActionWear( aItem : TItem ) : boolean;
    function ActionSwap( aItem : TItem; aSlot : TEqSlot ) : boolean;
    function ActionTakeOff( aSlot : TEqSlot ) : boolean;
    function ActionReload : Boolean;
    function ActionDualReload : Boolean;
    function ActionAltReload : Boolean;
    function ActionFire( aTarget : TCoord2D; aWeapon : TItem; aAltFire : Boolean = False; aDelay : Integer = 0; aForceSingle : Boolean = False ) : Boolean;
    function ActionPickup : Boolean;
    function ActionUse( aItem : TItem; aTarget : TCoord2D ) : Boolean;
    function ActionUnLoad( aItem : TItem; aDisassembleID : AnsiString = '' ) : Boolean;
    function ActionMove( aTarget : TCoord2D; aVisualMultiplier : Single = 1.0; aMoveCost : Integer = -1 ) : Boolean;
    function ActionSwapPosition( aTarget : TCoord2D ) : Boolean;
    function ActionActive : boolean;
    function ActionAction( aTarget : TCoord2D ) : Boolean;

    // Always returns False.
    //
    // aText (VFormatted with aParams is emoted if Being is player.
    function Fail( const aText : AnsiString; const aParams : array of Const ) : Boolean;

    // Always returns True.
    //
    // aText (VFormatted with aParams is emoted if Being is player.
    function Success( const aText : AnsiString; const aParams : array of Const; aCost : DWord = 0 ) : Boolean;

    // Always returns True.
    //
    // aPlayerText (VFormatted with aParams is emoted if Being is player, aBeingText (same format) otherwise.
    function Success( const aPlayerText, aBeingText : AnsiString; const aParams : array of Const; aCost : DWord = 0 ) : Boolean;

    procedure Emote( const aPlayerText, aBeingText : AnsiString; const aParams : array of Const );

    function MoveCost( const Start, Stop : TCoord2D ) : Single;
    function CostEstimate( const Start, Stop : TCoord2D ) : Single;
    function passableCoord( const aCoord : TCoord2D ) : boolean;
    function VisualTime( aActionCost : Word = 1000; aBaseTime : Word = 100 ) : Word;

    class procedure RegisterLuaAPI();

  protected
    procedure BloodDecal( aFrom : TDirection; aAmount : LongInt );
    procedure LuaLoad( Table : TLuaTable ); override;
    // private
    function FireRanged( aTarget : TCoord2D; aGun : TItem; aAlt : TAltFire = ALT_NONE; aDelay : Integer = 0 ) : Boolean;
    function getAmmoItem( Weapon : TItem ) : TItem;
    function HandleShotgunFire( aTarget : TCoord2D; aShotGun : TItem; aAltFire : TAltFire; aShots : DWord ) : Boolean;
    function HandleSpreadShots( aTarget : TCoord2D; aGun : TItem; aAltFire : TAltFire ) : Boolean;
    function HandleShots( aTarget : TCoord2D; aGun : TItem; aShots : DWord; aAltFire : TAltFire; aDelay : Integer ) : Boolean;

  protected
    FHPNom         : Word;
    FHPMax         : Word;
    FHPDecayMax    : Word;

    FTimes         : TBeingTimes;
    FLastCommand   : TCommand;

    FVisionRadius  : Byte;
    FSpeedCount    : LongInt;
    FAccuracy      : Integer;
    FStrength      : Integer;
    FSpriteMod     : Integer;
    FSpeed         : Byte;
    FExpValue      : Word;

    FMeleeAttack   : Boolean;
    FSilentAction  : Boolean;
    FTargetPos     : TCoord2D;
    FInv           : TInventory;
    FMovePos       : TCoord2D;
    FLastPos       : TCoord2D;
    FBloodBoots    : Byte;
    FChainFire     : Byte;
    FPath          : TPathFinder;
    FPathHazards   : TFlags;
    FPathClear     : TFlags;
    FKnockBacked   : Boolean;
    FDying         : Boolean;

    FOverlayUntil  : QWord;
  public
    property Inv       : TInventory  read FInv       write FInv;
    property TargetPos : TCoord2D    read FTargetPos write FTargetPos;
    property LastPos   : TCoord2D    read FLastPos   write FLastPos;
    property LastMove  : TCoord2D    read FMovePos   write FMovePos;

    property KnockBacked  : Boolean read FKnockBacked  write FKnockBacked;
    property SilentAction : Boolean read FSilentAction write FSilentAction;
    property MeleeAttack  : Boolean read FMeleeAttack;

    property OverlayUntil : QWord   read FOverlayUntil;
  published

    property can_dual_wield       : Boolean read canDualWield;
    property can_dual_wield_melee : Boolean read canDualWieldMelee;
    property last_command : Byte       read FLastCommand.Command;
    property ChainFire    : Byte       read FChainFire    write FChainFire;
    property HPMax        : Word       read FHPMax        write FHPMax;
    property HPNom        : Word       read FHPNom        write FHPNom;

    property Vision       : Byte       read FVisionRadius write FVisionRadius;
    property SCount       : LongInt    read FSpeedCount   write FSpeedCount;

    property Accuracy     : Integer    read FAccuracy      write FAccuracy;
    property Strength     : Integer    read FStrength      write FStrength;
    property SpriteMod    : Integer    read FSpriteMod     write FSpriteMod;

    property Speed        : Byte       read FSpeed         write FSpeed;
    property ExpValue     : Word       read FExpValue      write FExpValue;

    property HPDecayMax   : Word       read FHPDecayMax    write FHPDecayMax;

    property ReloadTime   : Byte       read FTimes.Reload  write FTimes.Reload;
    property FireTime     : Byte       read FTimes.Fire    write FTimes.Fire;
    property MoveTime     : Byte       read FTimes.Move    write FTimes.Move;
    property UseTime      : Byte       read FTimes.Use     write FTimes.Use;
    property WearTime     : Byte       read FTimes.Wear    write FTimes.Wear;
  end;


implementation

uses math, vlualibrary, vluaentitynode, vuid, vdebug, vvision, vluasystem,
     vluatools, vcolor, vvector,
     dfplayer, dflevel, dfmap, drlhooks,
     drlua, drlbase, drlio;

const PAIN_DURATION = 500;

function TBeing.getStrayChance( aDefender : TBeing; aWeapon : TItem ) : Byte;
var iMiss : Integer;
begin
  if IsPlayer        then Exit(0);
  if aDefender = nil then Exit(0);
  if aWeapon   = nil then Exit(0);

  iMiss := aWeapon.MissBase +
          aWeapon.MissDist *
          Distance( FPosition, aDefender.FPosition );

  if aDefender.IsPlayer then
  begin
    if (Player.Flags[ BF_MASTERDODGE ]) and (not Player.MasterDodge) then
    begin
      Player.MasterDodge := true;
      Exit(100);
    end;
  end;

  iMiss += aDefender.getDodgeMod;
  Exit( Clamp( iMiss, 0, 95 ) );
end;

constructor TBeing.Create(nid : byte);
var Table : TLuaTable;
begin
  inherited Create( LuaSystem.Get( ['beings', nid, 'id'] ) );
  FEntityID := ENTITY_BEING;
  Table := LuaSystem.GetTable( ['beings', nid] );
  LuaLoad( Table );
  FreeAndNil( Table );
end;

constructor TBeing.Create( const nid: AnsiString );
var Table : TLuaTable;
begin
  inherited Create( nid );
  FEntityID := ENTITY_BEING;
  Table := LuaSystem.GetTable(['beings', nid]);
  LuaLoad( Table );
  FreeAndNil( Table );
end;

constructor TBeing.CreateFromStream ( Stream : TStream ) ;
var Slot   : TEqSlot;
    Amount : Byte;
    c      : Byte;
begin
  inherited CreateFromStream ( Stream ) ;

  Initialize;

  FHPMax      := Stream.ReadWord();
  FHPNom      := Stream.ReadWord();
  FHPDecayMax := Stream.ReadWord();

  Stream.Read( FTimes,       SizeOf( FTimes ) );
  Stream.Read( FLastCommand, SizeOf( FLastCommand ) );
  Stream.Read( FAccuracy,    SizeOf( FAccuracy ) );
  Stream.Read( FStrength,    SizeOf( FStrength ) );
  Stream.Read( FSpriteMod,   SizeOf( FSpriteMod ) );

  FVisionRadius := Stream.ReadByte();
  FSpeedCount   := Stream.ReadWord();
  FSpeed        := Stream.ReadByte();
  FExpValue     := Stream.ReadWord();

  Amount := Stream.ReadByte;
  for c := 1 to Amount do
    FInv.Add( TItem.CreateFromStream( Stream ) );
  for slot in TEqSlot do
    if Stream.ReadByte <> 0 then
      FInv.RawSetSlot(slot,TItem.CreateFromStream( Stream ));
end;

procedure TBeing.WriteToStream ( Stream : TStream ) ;
var Item : TItem;
    Slot : TEqSlot;
begin
  inherited WriteToStream ( Stream ) ;

  Stream.WriteWord( FHPMax );
  Stream.WriteWord( FHPNom );
  Stream.WriteWord( FHPDecayMax );

  Stream.Write( FTimes,       SizeOf( FTimes ) );
  Stream.Write( FLastCommand, SizeOf( FLastCommand ) );
  Stream.Write( FAccuracy,    SizeOf( FAccuracy ) );
  Stream.Write( FStrength,    SizeOf( FStrength ) );
  Stream.Write( FSpriteMod,   SizeOf( FSpriteMod ) );

  Stream.WriteByte( FVisionRadius );
  Stream.WriteWord( FSpeedCount );
  Stream.WriteByte( FSpeed );
  Stream.WriteWord( FExpValue );

  Stream.WriteByte( FInv.Size );
  for Item in FInv do
    if not FInv.Equipped( Item ) then
      Item.WriteToStream( Stream );
  for slot in TEqSlot do
    if FInv.Slot[ slot ] = nil
      then Stream.WriteByte(0)
      else
      begin
        Stream.WriteByte(1);
        FInv.Slot[ slot ].WriteToStream(Stream);
      end;
end;

procedure TBeing.Initialize;
begin
  FInv := TInventory.Create( Self );
  FPath := nil;

  FTargetPos.Create(1,1);
  FLastPos.Create(1,1);
  FMovePos.Create(1,1);
  FLastCommand.Command := 0;

  FBloodBoots   := 0;
  FChainFire    := 0;
  FSpriteMod    := 0;

  FSilentAction := False;
  FKnockBacked  := False;
  FMeleeAttack  := False;
  FDying        := False;

  FOverlayUntil := 0;
end;

procedure TBeing.LuaLoad( Table : TLuaTable );
begin
  inherited LuaLoad( Table );
  Initialize;

  FHooks := FHooks * BeingHooks;

  FTimes.Move       := Table.getInteger('movetime',100);
  FTimes.Fire       := Table.getInteger('firetime',100);
  FTimes.Reload     := Table.getInteger('reloadtime',100);
  FTimes.Use        := Table.getInteger('usetime',100);
  FTimes.Wear       := Table.getInteger('weartime',100);
  FExpValue         := Table.getInteger('xp');

  FSpeed    := Table.getInteger('speed');
  FAccuracy := Table.getInteger('accuracy');
  FStrength := Table.getInteger('strength');

  FVisionRadius := VisionBaseValue + Table.getInteger('vision');

  Flags[ BF_WALKSOUND ] := ( IO.Audio.ResolveSoundID( [ FID+'.hoof', FSoundID+'.hoof' ] ) <> 0 );

  FHPMax := FHP;
  FHPNom := FHP;
  FSpeedCount := 900+Random(90);

  FHPDecayMax   := 100;

  if not isPlayer then
    CallHook(Hook_OnCreate,[]);
end;

function TBeing.getAmmoItem ( Weapon : TItem ) : TItem;
var iGroundAmmo : TItem;
begin
  if Weapon = nil then Exit( nil );
  iGroundAmmo := nil;
  if isPlayer then
  begin
    iGroundAmmo := TLevel(Parent).Item[ Position ];
    if iGroundAmmo <> nil then
    begin
      if ( iGroundAmmo.IType <> ITEMTYPE_AMMO ) or ( iGroundAmmo.NID <> Weapon.AmmoID )
        then iGroundAmmo := nil
        else if Player.EnemiesInVision < 1 then
          Exit( iGroundAmmo );
    end;
  end;
  if ( Weapon = FInv.Slot[ efWeapon ] ) and canPackReload then Exit( FInv.Slot[ efWeapon2 ] );
  if iGroundAmmo <> nil then Exit( iGroundAmmo );
  Exit( FInv.SeekStack( Weapon.AmmoID ) );
end;

function TBeing.HandleShotgunFire( aTarget : TCoord2D; aShotGun : TItem; aAltFire : TAltFire; aShots : DWord ) : Boolean;
var iThisUID   : DWord;
    iDual      : Boolean;
    iCount     : DWord;
    iDamageMul : Single;
    iDamage    : TDiceRoll;
    iDamageType: TDamageType;
    iBeing     : TBeing;
begin
  Assert( aShotGun <> nil );
  Assert( aShotGun.Flags[ IF_SHOTGUN ] );
  iThisUID := FUID;
  iBeing   := TLevel(Parent).Being[ aTarget ];

  iDual := aShotGun.Flags[ IF_DUALSHOTGUN ];
  if iDual then aShotgun.PlaySound( 'fire', FPosition );

  iDamage.Init( aShotGun.Damage_Dice, aShotGun.Damage_Sides, aShotGun.Damage_Add + getToDam( aShotgun, aAltFire, False ) );
  if BF_MAXDAMAGE in FFlags then iDamage.Init( 0, 0, iDamage.Max );
  iDamageMul := GetBonusMul( Hook_getDamageMul, [ aShotgun, False, aAltFire, iBeing ] )
              * aShotgun.GetBonusMul( Hook_getDamageMul, [ False, aAltFire, iBeing ] );

  if isPlayer then
    IO.addScreenShakeAnimation( 200+aShots*100, 0, Clampf( iDamage.max / 10, 2.0, 10.0 ), NewDirection( FPosition, aTarget ) );
  for iCount := 1 to aShots do
  begin
    if not iDual then aShotGun.PlaySound( 'fire', FPosition );
    iDamageType := aShotGun.DamageType;
    if (BF_ARMYDEAD in FFlags) and (iDamageType = DAMAGE_SHARPNEL) then iDamageType := Damage_IgnoreArmor;
    TLevel(Parent).ShotGun( FPosition, aTarget, iDamage, iDamageMul, iDamageType, aShotgun );
    if UIDs[ iThisUID ] = nil then Exit( false );
    if (not iDual) and (aShotGun.Shots > 1) then IO.Delay(30);
  end;
  Exit( true );
end;

function TBeing.HandleSpreadShots( aTarget : TCoord2D; aGun : TItem; aAltFire : TAltFire ) : Boolean;
var iLevel : TLevel;
begin
  iLevel := TLevel(Parent);
  Assert( aGun <> nil );
  if TLevel(Parent).Being[ aTarget ] <> nil then aTarget := TLevel(Parent).Being[ aTarget ].FLastPos;
  if not SendMissile( iLevel.Area.Clamped(NewCoord2D(aTarget.x+Sgn(aTarget.y-FPosition.y),aTarget.y-Sgn(aTarget.x-FPosition.x))),aGun,aAltFire,0,0 ) then Exit( False );
  if not SendMissile( iLevel.Area.Clamped(NewCoord2D(aTarget.x-Sgn(aTarget.y-FPosition.y),aTarget.y+Sgn(aTarget.x-FPosition.x))),aGun,aAltFire,0,0 ) then Exit( False );
  if not SendMissile( aTarget, aGun,aAltFire,0,0 ) then Exit( False );
  Exit( True );
end;

function TBeing.HandleShots ( aTarget : TCoord2D; aGun : TItem; aShots : DWord; aAltFire : TAltFire; aDelay : Integer ) : Boolean;
var iScatter     : DWord;
    iCount       : DWord;
    iSeqBase     : DWord;
    iChainTarget : TCoord2D;
    iMissileRange: SmallInt;
    iRay         : TVisionRay;
    iSteps       : SmallInt;
    iChaining    : Boolean;
begin
  Assert( aGun <> nil );
  iSeqBase := 0;
  if not isPlayer then iSeqBase := 100;
  iSeqBase += aDelay;
  iMissileRange := 30; // aGun.Missile.MaxRange;
  iChaining := ( aAltFire = ALT_CHAIN ) and ( aShots > 1 );

  if aGun.Flags[ IF_SCATTER ] then
  begin
    iSteps := 0;
    iRay.Init(TLevel(Parent), FPosition, aTarget);
    repeat
      iRay.Next;
      if not TLevel(Parent).isProperCoord(iRay.GetC) then begin aTarget:=iRay.prev; break;end; {**** Stop at edge of map.}
      Inc(iSteps);
      if iSteps >= iMissileRange then begin aTarget := iRay.GetC; break; end; {**** Stop if further than maxrange.}
      if aGun.Flags[ IF_EXACTHIT ] and (iRay.GetC = aTarget) then break; {**** Stop at target square for exact missiles.}
      if iRay.Done then
         iRay.Init(TLevel(Parent), iRay.GetC, iRay.GetC + (aTarget - FPosition)); {**** Extend target out in same direction for non-exact missiles.}
    until false;
    iScatter := Max(1,(iSteps div 4)); {**** SCATTER TIME!}
  end;
  if iChaining then
  begin
    iChainTarget := aTarget;
    aTarget      := FTargetPos;
  end;
  for iCount := 1 to aShots do
  begin
    if iChaining then aTarget := RotateTowards( FPosition, aTarget, iChainTarget, PI/6 );
    if aGun.Flags[ IF_SCATTER ] then
       begin
            if not SendMissile( TLevel(Parent).Area.Clamped(aTarget.RandomShifted( iScatter )), aGun, aAltFire, iSeqBase+(iCount-1)*aGun.MisDelay*3, iCount-1 ) then Exit( False );
       end
    else
       begin
            if not SendMissile( aTarget, aGun, aAltFire, iSeqBase+(iCount-1)*aGun.MisDelay*3, iCount-1 ) then Exit( False );
       end;
    if DRL.State <> DSPlaying then Exit( False );
  end;
  Exit( True );
end;

function TBeing.VisualTime( aActionCost : Word = 1000; aBaseTime : Word = 100 ) : Word;
begin
  Result := Ceil( ( 100.0 / FSpeed ) * ( aActionCost / 1000.0 ) * Single( aBaseTime ) );
end;

function TBeing.IsPlayer : Boolean;
begin
  Exit( inheritsFrom( TPlayer ) );
end;

function TBeing.GetBonus( aHook : Byte; const aParams : array of Const ) : Integer;
begin
  GetBonus := inherited GetBonus( aHook, aParams );
  if aHook in FHooks then
    GetBonus += LuaSystem.ProtectedRunHook( Self, HookNames[ aHook ], aParams );
end;

function TBeing.GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
begin
  GetBonusMul := inherited GetBonusMul( aHook, aParams );
  if aHook in FHooks then
    GetBonusMul *= LuaSystem.ProtectedRunHook( Self, HookNames[ aHook ], aParams );
end;

function TBeing.isActive: boolean;
begin
  Exit( TLevel(Parent).ActiveBeing = Self );
end;

function TBeing.Preposition( Creature : AnsiString ) : string;
begin
  Case Creature[1] of
    'a','e','i','o','u' : Exit('an ');
  end;
  Exit('a ');
end;

function TBeing.Dead: Boolean;
begin
  Exit( FHP <= 0 );
end;

procedure TBeing.Remove( Node : TNode );
begin
  if FInv <> nil then
    if Node is TItem then
      FInv.ClearSlot( Node as TItem );
  inherited Remove( Node );
end;

function TBeing.ASCIIMoreCode : AnsiString;
begin
  Exit( ID );
end;

function TBeing.ActionQuickKey( aIndex : Byte ) : Boolean;
var iUID  : TUID;
    iID   : string[32];
    iItem : TItem;
begin
  if ( aIndex < 1 ) or ( aIndex > 9 ) then Exit( False );
  with Player.FQuickSlots[ aIndex ] do
  begin
    iUID := UID;
    iID  := ID;
  end;
  if iUID <> 0 then
  begin
    iItem := UIDs[ iUID ] as TItem;
    if iItem <> nil then
    begin
      if FInv.Equipped( iItem )     then
      begin
         if iItem.isEqWeapon and ( FInv.Slot[ efWeapon2 ] = iItem )
           then Exit( ActionSwapWeapon )
           else Exit( Fail( 'You''re already using it!', [] ) );
      end;
      if not FInv.Contains( iItem ) then Exit( Fail( 'You no longer have it!', [] ) );
      Exit( ActionWear( iItem ) );
    end;
  end
  else
  if iID <> '' then
  begin
    for iItem in Inv do
      if iItem.isUsable then
        if iItem.id = iID then
        begin
          if iItem.isPack or ( DRL.Targeting.List.Current <> FPosition )
            then Exit( ActionUse( iItem, DRL.Targeting.List.Current ) )
            else Exit( Fail( 'No valid target!', [] ) );
        end;
    Exit( Fail( 'You no longer have any item like that!', [] ) );
  end;
  Exit( Fail( 'Quickslot %d is unassigned!', [aIndex] ) );
end;

function TBeing.ActionQuickWeapon( const aWeaponID : Ansistring ) : Boolean;
var iWeapon  : TItem;
    iItem    : TItem;
    iAmmo    : Byte;
begin
  if (not LuaSystem.Defines.Exists(aWeaponID)) or (LuaSystem.Defines[aWeaponID] = 0)then Exit( False );

  if Inv.Slot[ efWeapon ] <> nil then
  begin
    if Inv.Slot[ efWeapon ].ID = aWeaponID then Exit( Fail( 'You already have %s in your hands.', [ Inv.Slot[ efWeapon ].GetName(true) ] ) );
    if Inv.Slot[ efWeapon ].Flags[ IF_CURSED ] then Exit( Fail( 'You can''t!', [] ) );
  end;

  if Inv.Slot[ efWeapon2 ] <> nil then
    if Inv.Slot[ efWeapon2 ].ID = aWeaponID then
      Exit( ActionSwapWeapon );

  iAmmo   := 0;
  iWeapon := nil;
  for iItem in Inv do
    if iItem.isEqWeapon then
      if iItem.ID = aWeaponID then
      if iItem.Ammo >= iAmmo then
      begin
        iWeapon := iItem;
        iAmmo   := iItem.Ammo;
      end;

  if iWeapon = nil then Exit( Fail( 'You don''t have a %s!', [ Ansistring(LuaSystem.Get([ 'items', aWeaponID, 'name' ])) ] ) );

  Inv.Wear( iWeapon );

  if Option_SoundEquipPickup
    then iWeapon.PlaySound( 'pickup', FPosition )
    else iWeapon.PlaySound( 'reload', FPosition );

  if not ( BF_QUICKSWAP in FFlags )
     then Exit( Success( 'You prepare the %s!',[ iWeapon.Name ], getWearCost(iWeapon) ) )
     else Exit( Success( 'You prepare the %s instantly!',[ iWeapon.Name ] ) );
end;

function TBeing.ActionSwapWeapon : boolean;
begin
  if ( Inv.Slot[ efWeapon ] <> nil ) and Inv.Slot[ efWeapon ].Flags[ IF_CURSED ] then Exit( False );
  if ( Inv.Slot[ efWeapon2 ] <> nil ) and ( Inv.Slot[ efWeapon2 ].isAmmoPack )   then Exit( False );

  Inv.EqSwap( efWeapon, efWeapon2 );

  if Inv.Slot[ efWeapon ] <> nil then
    if Option_SoundEquipPickup
      then Inv.Slot[ efWeapon ].PlaySound( 'pickup', FPosition )
      else Inv.Slot[ efWeapon ].PlaySound( 'reload', FPosition );

  if ( BF_QUICKSWAP in FFlags ) or ( canDualWield )
    then Exit( Success( 'You swap your weapons instantly!',[] ) )
    else Exit( Success( 'You swap your weapons.',[], Round(getWearCost( Inv.Slot[ efWeapon ] ) *0.5) ) );
end;

function TBeing.ActionDrop ( aItem : TItem; aUnload : Boolean ) : boolean;
var iUnique : Boolean;
    iAmmo   : Integer;
    iAmmoID : DWord;
  procedure HandleAmmo;
  var iItem : TItem;
  begin
    if ( iAmmo = 0 ) or ( iAmmoID = 0 ) then Exit;
    iAmmo := Inv.AddStack(iAmmoID,iAmmo);
    if ( iAmmo > 0 ) then
    try
       iItem := TItem.Create(iAmmoID);
       iItem.Amount := iAmmo;
       TLevel(Parent).DropItem( iItem, FPosition, False, True )
    except
    on e : EPlacementException do iItem.Free
    end;
  end;
begin
  if aItem = nil then Exit( false );
  if not FInv.Contains( aItem ) then Exit( False );
  iUnique := aItem.Flags[ IF_UNIQUE ] or aItem.Flags[ IF_NODESTROY ];
  iAmmo   := 0;
  iAmmoID := 0;
  if aUnload and aItem.isRanged and aItem.isUnloadable and (not aItem.Flags[ IF_NOUNLOAD ] ) then
  begin
    iAmmo      := aItem.Ammo;
    iAmmoID    := aItem.AmmoID;
    aItem.Ammo := 0;
  end;
try
  if TLevel(Parent).DropItem( aItem, FPosition, False, True ) then
  begin
    FInv.ClearSlot( aItem );
    HandleAmmo;
    Exit( Success( 'You dropped %s.',[aItem.GetName(false)],ActionCostDrop ) )
  end
  else
    begin
      FInv.ClearSlot( aItem );
      HandleAmmo;
      if iUnique then
        Exit( Success( 'You dropped %s.',[aItem.GetName(false)],ActionCostDrop ) )
	  else
        Exit( Success( 'The dropped item melts!',[],ActionCostDrop ) );
    end;
except
  on e : EPlacementException do
  begin
    Fail( 'No room on the floor.', [] );
  end;
end;
  Exit( False );
end;

function TBeing.ActionWear( aItem : TItem ) : boolean;
var iWeapon : Boolean;
begin
  if aItem = nil then Exit( false );
  if not FInv.Contains( aItem ) then Exit( False );
  iWeapon := aItem.isEqWeapon;

  if Option_SoundEquipPickup
    then aItem.PlaySound( 'pickup', FPosition )
    else aItem.PlaySound( 'reload', FPosition );

  if FInv.DoWear( aItem ) then
  begin
    if not ( iWeapon and Flags[BF_QUICKSWAP] ) then
    begin
      Dec( FSpeedCount, getWearCost( aItem ) );
      Exit( True );
    end;
  end;
  Exit( False );
end;

function TBeing.ActionSwap( aItem : TItem; aSlot : TEqSlot ) : boolean;
var iWeapon : Boolean;
begin
  if aItem = nil then Exit( false );
  if not FInv.Contains( aItem ) then Exit( False );
  iWeapon := aItem.isEqWeapon;

  if Option_SoundEquipPickup
    then aItem.PlaySound( 'pickup', FPosition )
    else aItem.PlaySound( 'reload', FPosition );

  if FInv.DoWear( aItem, aSlot ) then
  begin
    if not ( iWeapon and Flags[BF_QUICKSWAP] ) then
    begin
      Dec( FSpeedCount, getWearCost( aItem ) );
      Exit( True );
    end;
  end;
  Exit( False );
end;

function TBeing.ActionTakeOff( aSlot : TEqSlot ) : boolean;
var iWeapon : Boolean;
    iItem   : TItem;
begin
  iItem := FInv.Slot[aSlot];
  if (iItem = nil) or iItem.Flags[ IF_CURSED ] then
    Exit( False );
  iWeapon := iItem.isEqWeapon;
  FInv.setSlot( aSlot, nil );
  if not ( iWeapon and Flags[BF_QUICKSWAP] ) then
  begin
    Dec( FSpeedCount, getWearCost( iItem ) );
    Exit( True );
  end;
  Exit( False );
end;

function TBeing.ActionReload : Boolean;
var iSCount   : LongInt;
    iWeapon   : TItem;
    iItem     : TItem;
    iAmmoUID  : TUID;
    iIsPack   : Boolean;
    iIsGround : Boolean;
    iAmmoName : AnsiString;
begin
  iSCount := SCount;
  iWeapon := Inv.Slot[ efWeapon ];
  if ( iWeapon = nil ) or ( not iWeapon.isRanged ) then Exit( Fail( 'You have no weapon to reload.',[] ) );
  if not iWeapon.CallHookCheck( Hook_OnPreReload, [ Self ] ) then Exit( iSCount > SCount );
  if ( iWeapon.Flags[ IF_RECHARGE ]) then Exit( Fail( 'The weapon cannot be manually reloaded!', [] ) );
  if ( iWeapon.Flags[ IF_NOAMMO ])   then Exit( Fail( 'The weapon doesn''t need to be reloaded!', [] ) );
  if ( iWeapon.Ammo = iWeapon.AmmoMax ) then Exit( Fail( 'Your %s is already loaded.', [ iWeapon.Name ] ) );

  iItem := getAmmoItem( iWeapon );

  if iItem = nil then Exit( Fail( 'You have no more ammo for the %s!',[iWeapon.Name] ) );

  iAmmoUID  := iItem.UID;
  iAmmoName := iItem.Name;

  iIsPack     := iItem.isAmmoPack;
  iIsGround := ( iItem.Parent = Self.Parent );

  if not iWeapon.CallHookCheck( Hook_OnReload, [ Self, iItem, iIsPack ] ) then Exit( iSCount > SCount );

  if iSCount = SCount then
  begin
    Reload( iItem, iWeapon.Flags[ IF_SINGLERELOAD ] );
    Emote( 'You '+IIf(iIsPack,'quickly ')+'reload the %s%s.', 'reloads his %s%s.', [iWeapon.Name,Iif(iIsGround,' from the ground')] );
  end;

  if iIsPack and ( UIDs[ iAmmoUID ] = nil ) and IsPlayer then
    IO.Msg( 'Your %s is depleted.', [iAmmoName] );
  
  Exit( True );
end;

function TBeing.ActionDualReload : Boolean;
var SAStore : Boolean;
    iReload : Boolean;
begin
  if not canDualWield then
    Exit( Fail( 'Dualreload not possible.', [] ) );
  SAStore := FSilentAction;
  FSilentAction := True;
  iReload := ActionReload;
  FInv.EqSwap( efWeapon, efWeapon2 );
  if ActionReload then iReload := True;
  FInv.EqSwap( efWeapon, efWeapon2 );
  FSilentAction := SAStore;
  if iReload then
    Exit( Success( 'You dualreload your guns!', 'dualreloads his guns.', [] ) )
  else
    if (FInv.Slot[ efWeapon ].Ammo = FInv.Slot[ efWeapon ].AmmoMax)
    and (FInv.Slot[ efWeapon2 ].Ammo = FInv.Slot[ efWeapon2 ].AmmoMax) then
      Exit( Fail( 'Guns already loaded.', [] ) )
    else
      Exit( Fail( 'No more ammo!', [] ) )
end;

function TBeing.ActionAltReload : Boolean;
var iAmmoItem : TItem;
    iWeapon   : TItem;
    iIsPack   : Boolean;
    iIsGround : Boolean;
begin
  iWeapon := Inv.Slot[ efWeapon ];
  if ( iWeapon = nil ) or ( not iWeapon.isRanged ) then Exit( Fail( 'You have no weapon to reload.',[] ) );
  case iWeapon.AltReload of
    RELOAD_SCRIPT : Exit( iWeapon.CallHookCheck( Hook_OnAltReload, [Self] ) );
    RELOAD_DUAL   : Exit( ActionDualReload );
    RELOAD_SINGLE :
      begin
        if iWeapon.Ammo = iWeapon.AmmoMax then Exit( Fail( 'Your %s is already fully loaded.', [ iWeapon.Name ] ) );
        iAmmoItem := getAmmoItem( iWeapon );
        if iAmmoItem = nil then Exit( Fail('You have no ammo for the %s!',[ iWeapon.Name ] ) );
        iIsPack := iAmmoItem.isAmmoPack;
        iIsGround := ( iAmmoItem.Parent = Self.Parent );
        Reload( iAmmoItem, True );
        Exit( Success('You%s single-load the %s%s.', [ IIf( iIsPack, ' quickly'), iWeapon.Name, IIf( iIsGround, ' from the ground') ] ) );
      end;
    else
      Exit( Fail('This weapon has no special reload mode.', [] ) );
  end;
end;

function TBeing.ActionFire ( aTarget : TCoord2D; aWeapon : TItem; aAltFire : Boolean; aDelay : Integer = 0; aForceSingle : Boolean = False ) : Boolean;
var iChainFire : Byte;
    iLimitRange: Boolean;
    iRange     : Byte;
    iDist      : Byte;
    iAltFire   : TAltFire;
begin
  iChainFire  := FChainFire;
  iAltFire    := ALT_NONE;
  FChainFire  := 0;

  if (aWeapon = nil) then Exit( False );
  if aAltFire then iAltFire := aWeapon.AltFire;

  if iAltFire <> ALT_NONE then 
  begin
    if (not aWeapon.isWeapon) then Exit( False );
    if aWeapon.isMelee then FMeleeAttack := True;
    if aWeapon.AltFire in [ ALT_SCRIPT, ALT_TARGETSCRIPT ] then
      if not aWeapon.CallHookCheck( Hook_OnAltFire, [Self] ) 
        then Exit( False );

    if aWeapon.isMelee then
    begin
      case aWeapon.AltFire of
        ALT_THROW  :
        begin
          SendMissile( aTarget, aWeapon, ALT_THROW, 0, 0 );
          Dec( FSpeedCount, 1000 );
          Exit( True );
        end;
      end;
      Exit( True );
    end;
  end;  
  
  if (not aWeapon.isRanged) then Exit( False );

  if ( not aWeapon.Flags[ IF_NOAMMO ] ) and ( not aWeapon.isUsable ) then
  begin
    if aWeapon.Ammo = 0 then Exit( False );
    if aWeapon.Ammo < aWeapon.ShotCost then Exit( False );
  end;
  
  iRange := aWeapon.Range;
  if iRange = 0 then iRange := self.Vision;
  iLimitRange := (not aWeapon.Flags[ IF_SHOTGUN ]) and aWeapon.Flags[ IF_EXACTHIT ];

  if iLimitRange then
  begin
    iDist := Distance( FPosition, aTarget );
    if iDist > iRange then
    begin
      if iRange = 1 then // Rocket jump hack!
        aTarget := FPosition + NewDirectionSmooth( FPosition, aTarget )
      else
        Exit( False );
    end;
  end;

  if (iAltFire = ALT_CHAIN) then
  begin
    if ( iChainFire > 0 )
      then FTargetPos := DRL.Targeting.PrevPos
      else FTargetPos := aTarget;
  end;
  FChainFire := iChainFire;

  Dec( FSpeedCount, getFireCost( iAltFire, False ) );

  if ( not FireRanged( aTarget, aWeapon, iAltFire, aDelay )) or Player.Dead then Exit( True );
  if ( not aForceSingle ) and canDualWield and ( Inv.Slot[ efWeapon2 ].Flags[ IF_NOAMMO ] or ( Inv.Slot[ efWeapon2 ].Ammo > 0 ) ) then
    if ( not FireRanged( aTarget, Inv.Slot[ efWeapon2 ], iAltFire, aDelay + 100 )) or Player.Dead then Exit( True );

  Exit( True );
end;

function TBeing.ActionPickup : Boolean;
var iAmount  : byte;
    iItem   : TItem;
    iName   : AnsiString;
    iCount  : Byte;
begin
  iItem := TLevel(Parent).Item[ FPosition ];

  if iItem = nil            then Exit( Fail( 'But there is nothing here!', [] ) );
  if not iItem.isPickupable then Exit( Fail( 'But there is nothing here to pick up!', [] ) );

  if iItem.isPower then
  begin
    if iItem.CallHookCheck(Hook_OnPickupCheck,[Self]) then
    begin
      iItem.PlaySound( 'powerup', FPosition );
      CallHook( Hook_OnPickUpItem, [iItem] );
      iItem.CallHook(Hook_OnPickUp, [Self]);
    end;
    TLevel(Parent).DestroyItem( FPosition );
    Dec(FSpeedCount,ActionCostPickUp);
    Exit( True );
  end;

  if BF_IMPATIENT in FFlags then
    if iItem.isUsable then
      begin
        if isPlayer then IO.Msg('No time to waste.');
        CallHook( Hook_OnPickUpItem, [iItem] );
        if iItem.isPack then Exit( ActionUse( iItem, FPosition ) );
        if DRL.Targeting.List.Current <> FPosition
          then Exit( ActionUse( iItem, DRL.Targeting.List.Current ) )
          else Exit( Fail( 'No valid target!', [] ) );
      end;

  if iItem.isStackable then
  begin
    if not iItem.CallHookCheck(Hook_OnPickupCheck,[Self]) then  Exit( False );
    iAmount := Inv.AddStack(iItem.NID,iItem.Amount);
    if iAmount <> iItem.Amount then
    begin
      iItem.playSound( 'pickup', FPosition );
      CallHook( Hook_OnPickUpItem, [iItem] );
      iName := iItem.Name;
      iCount := iItem.Amount-iAmount;
      if iAmount = 0 then
        TLevel(Parent).DestroyItem( FPosition )
      else iItem.Amount := iAmount;
      Exit( Success( 'You found %d of %s.',[iCount,iName],ActionCostPickup) );
    end else Exit( Fail('You don''t have enough room in your backpack.',[]) );
  end;

  if Inv.isFull then Exit( Fail( 'You don''t have enough room in your backpack.', [] ) );

  if not iItem.CallHookCheck(Hook_OnPickupCheck,[Self]) then  Exit( False );
  iItem.PlaySound('pickup', FPosition );
  if isPlayer then IO.Msg('You picked up %s.',[iItem.GetName(false)]);
  Inv.Add(iItem);
  CallHook( Hook_OnPickUpItem, [iItem] );
  Dec(FSpeedCount,ActionCostPickUp);
  iItem.CallHook(Hook_OnPickup, [Self]);
  Exit( True );
end;

function TBeing.ActionUse ( aItem : TItem; aTarget : TCoord2D ) : Boolean;
var isOnGround : Boolean;
    isLever    : Boolean;
    isUsable   : Boolean;
    isEquip    : Boolean;
    isPrepared : Boolean;
    isUse      : Boolean;
    isUsedUp   : Boolean;
    isFailed   : Boolean;
    isURanged  : Boolean;
    iSlot      : TEqSlot;
    iUseCost   : Integer;
    iUID       : TUID;
	
begin
  isFailed   := False;
  isOnGround := TLevel(Parent).Item[ FPosition ] = aItem;
  if aItem = nil then Exit( false );
  if (not aItem.isLever) and (not aItem.isUsable) and (not aItem.isAmmoPack) and (not aItem.isWearable) then Exit( False );
  if ((not aItem.isWearable) and (not aItem.CallHookCheck( Hook_OnUseCheck,[Self] ))) or (aItem.isWearable and ( (not aItem.CallHookCheck( Hook_OnEquipCheck,[Self] )) or (not aItem.CallHookCheck( Hook_OnPickupCheck,[Self] )) )) then Exit( False );

  isLever   := aItem.isLever;
  isUsable  := aItem.isUsable;
  isEquip   := aItem.isWearable;
  isURanged := aItem.IType = ITEMTYPE_URANGED;

  isUse   := not isEquip;
  iUID    := aItem.uid;
  if isOnGround then
    begin
      if isLever then
        begin
          Emote( 'You pull the lever...', 'pulls the lever...',[] );
          if isPlayer then Player.Statistics.Increase( 'levers_pulled' );
        end
	  else if isUsable then
	    begin
		  Emote( 'You use %s from the ground.', 'uses %s.', [ aItem.GetName(False,True) ] );
		end
	  else if isEquip then
	    begin
		  isPrepared := (aItem.isWeapon and (Inv.Slot[ efWeapon2 ] = nil));
		  if (Inv.Slot[ aItem.eqSlot ] = nil) or isPrepared then
		    begin
			  if (Inv.Slot[ aItem.eqSlot ] = nil) then iSlot := aItem.eqSlot
			  else if isPrepared then iSlot := efWeapon2;
			  Emote( 'You equip %s from the ground.', 'equips %s.', [ aItem.GetName(false) ] );
			end
		  else
			begin
			  Emote( 'You must unequip first!', '', [ aItem.GetName(false) ] );
			  isFailed := True;
			end;
		end;
	end
  else if not isURanged then
     Emote( 'You use %s.', 'uses %s.', [ aItem.GetName(False, True) ] );
  if isFailed then 
    Exit( False );

  if isEquip then
  begin
    aItem.PlaySound( 'pickup', FPosition );
    Inv.setSlot( iSlot, aItem );
  end;
  if isUsable and (not isURanged) then
    aItem.PlaySound( 'use', FPosition );
  if isEquip or isUsable then
    begin
      CallHook( Hook_OnPickUpItem, [aItem] );
      aItem.CallHook( Hook_OnPickup,[Self] )
    end;
  if isUse then
  begin
    iUseCost := getUseCost( aItem );

    if isURanged then
    begin
      aItem.Flags[ IF_NODESTROY ] := True;
      isUsedUp := ActionFire( aTarget, aItem, False );
      if UIDs.Get( iUID ) <> nil then aItem.Flags[ IF_NODESTROY ] := False;
      if isUsedUp
        then Emote( 'You use %s.', 'uses %s.', [ aItem.GetName(False, True) ] )
        else Exit( Fail( 'Out of range!', [] ) );
      aItem.PlaySound( 'use', FPosition );
    end
    else
      isUsedUp := aItem.CallHookCheck( Hook_OnUse,[Self] );
    if isUsedUp and ((UIDs.Get( iUID ) <> nil)  and (isLever or isUsable)) then
    begin
      if ( not isOnGround ) and ( aItem.Parent = Self ) then
        aItem := FInv.SeekStack( aItem.NID );
      aItem.Amount := aItem.Amount - 1;
      if aItem.Amount < 1 then FreeAndNil( aItem );
    end;
  end;

  if isURanged then Exit( isUsedUp );
  
  if isUse then
    Dec(FSpeedCount,iUseCost)
  else
    Dec(FSpeedCount,1000);
  Exit( True );
end;

function TBeing.ActionUnLoad ( aItem : TItem; aDisassembleID : AnsiString = '' ) : Boolean;
var iAmount : Integer;
    iName   : AnsiString;
begin
  if aItem = nil then Exit( False );
  if ( aDisassembleID <> '' ) then
  begin
    iName   := aItem.Name;
    FreeAndNil( aItem );
    aItem := TItem.Create( aDisassembleID );
    aItem.PlaySound('reload', FPosition );
    if not Inv.isFull
       then Inv.Add( aItem )
       else TLevel(Parent).DropItem( aItem, FPosition, False, True );
    Exit( Success( 'You disassemble the %s.',[iName], ActionCostReload ) );
  end;

  if not aItem.isUnloadable then Exit( Fail( 'This item cannot be unloaded!', [] ) );
  if aItem.Flags[ IF_NOUNLOAD ] then Exit( Fail( 'This weapon cannot be unloaded!', []) );
  if aItem.Flags[ IF_RECHARGE ] then Exit( Fail( 'This weapon is self powered!', []) );
  if aItem.Flags[ IF_NOAMMO ] then Exit( Fail( 'This weapon doesn''t use ammo!', []) );
  if aItem.Ammo = 0 then Exit( Fail( 'The weapon isn''t loaded!', [] ) );

  aItem.PlaySound( 'reload', FPosition );
  iName   := aItem.Name;
  iAmount := FInv.AddStack(aItem.AmmoID,aItem.Ammo);
  if iAmount = 0 then
  begin
    aItem.Ammo := 0;
    if aItem.isAmmoPack then FreeAndNil( aItem );
    Exit( Success( 'You fully unload the %s.', [iName], ActionCostReload ) );
  end;
  if aItem.Ammo = iAmount then Exit( Fail( 'You don''t have enough room in your backpack to unload the %s.', [ iName ] ) );
  aItem.Ammo := iAmount;
  Exit( Success( 'You partially unload the %s.', [ iName ], ActionCostReload ) );
end;

function TBeing.ActionMove( aTarget : TCoord2D; aVisualMultiplier : Single = 1.0; aMoveCost : Integer = -1 ) : Boolean;
var iVisualTime : Integer;
    iMoveCost   : Integer;
begin
  iMoveCost := getMoveCost;
  if GraphicsVersion then
  begin
    iVisualTime := Ceil( VisualTime( iMoveCost, AnimationSpeedMove ) * aVisualMultiplier );
    if isPlayer then
      IO.addScreenMoveAnimation( iVisualTime, aTarget );
    IO.addMoveAnimation( iVisualTime, 0, FUID, Position, aTarget, Sprite, True, isPlayer and ( aMoveCost = 0 ) );
  end;
  Displace( aTarget );
  if aMoveCost = -1
    then Dec( FSpeedCount, iMoveCost )
    else Dec( FSpeedCount, aMoveCost );
  HandlePostDisplace;
  HandlePostMove;
  Exit( True );
end;

function TBeing.ActionSwapPosition( aTarget : TCoord2D ) : Boolean;
var iLevel  : TLevel;
begin
  iLevel  := TLevel(Parent);
  if not iLevel.SwapBeings( Position, aTarget ) then Exit( False );
  Dec( FSpeedCount, getMoveCost );
  Exit( True );
end;

function TBeing.ActionActive : Boolean;
begin
  if ( not isPlayer ) then Exit( False );
  Exit( CallHookCheck( Hook_OnUseActive, [] ) );
end;

function TBeing.ActionAction( aTarget : TCoord2D ) : Boolean;
var iLevel : TLevel;
    iItem  : TItem;
begin
  iLevel := TLevel(Parent);
  iItem := iLevel.Item[ aTarget ];
  if Assigned( iItem ) and iItem.HasHook( Hook_OnAct )
    then iItem.CallHook( Hook_OnAct, [ LuaCoord( aTarget ), Self ] )
    else iLevel.CallHook( aTarget, Self, CellHook_OnAct );
  Exit( True );
end;

function TBeing.Fail ( const aText: AnsiString; const aParams: array of const ): Boolean;
begin
  if FSilentAction then Exit( False );
  if IsPlayer then IO.Msg( aText, aParams );
  Exit( False );
end;

function TBeing.Success ( const aText : AnsiString; const aParams : array of const; aCost : DWord ) : Boolean;
begin
  if aCost <> 0 then Dec( FSpeedCount, aCost );
  if FSilentAction then Exit( True );
  if IsPlayer then IO.Msg( aText, aParams );
  Exit( True );
end;

function TBeing.Success ( const aPlayerText, aBeingText : AnsiString; const aParams : array of const; aCost : DWord ) : Boolean;
begin
  if aCost <> 0 then Dec( FSpeedCount, aCost );
  Emote( aPlayerText, aBeingText, aParams );
  Exit( True );
end;

procedure TBeing.Emote ( const aPlayerText, aBeingText : AnsiString; const aParams : array of const ) ;
begin
  if FSilentAction then Exit;
  if IsPlayer
    then IO.Msg( aPlayerText, aParams )
    else if isVisible then IO.Msg( Capitalized(GetName(true))+' '+aBeingText, aParams );
end;

function TBeing.GetName(known : boolean) : string;
begin
  if BF_UNIQUENAME in FFlags then Exit( Name );
  if known then Exit( 'the ' + Name )
           else Exit( Preposition(Name) + Name );
end;

function  TBeing.WoundStatus : string;
var percent : LongInt;
begin
  percent := Min(Max(Round((FHP / FHPMax) * 100),0),1000);
  case percent of
 -1000..-1  : Exit('dead');
    0 ..10  : Exit('almost dead');
    11..20  : Exit('mortally wounded');
    21..35  : Exit('severely wounded');
    36..50  : Exit('heavily wounded');
    51..70  : Exit('wounded');
    71..80  : Exit('lightly wounded');
    81..90  : Exit('scratched');
    91..99  : Exit('almost unhurt');
    100     : Exit('unhurt');
    101..999: Exit('boosted');
    1000    : Exit('cheated');
  end;
end;


function TBeing.TryMove( aWhere : TCoord2D ) : TMoveResult;
var iLevel : TLevel;
begin
  iLevel := TLevel(Parent);
  if not iLevel.isProperCoord( aWhere )          then Exit( MoveBlock );
  if iLevel.cellFlagSet( aWhere, CF_OPENABLE )   then Exit( MoveDoor  );
  if not iLevel.isEmpty( aWhere, [EF_NOBLOCK] )  then Exit( MoveBlock );
  if ( not Self.isPlayer ) and iLevel.cellFlagSet( aWhere, CF_HAZARD ) and (not (BF_CHARGE in FFlags)) then
  begin
    if not (BF_ENVIROSAFE in FFlags) then Exit( MoveBlock );
  end;
  if iLevel.Being[ aWhere ] <> nil               then Exit( MoveBeing );
  Exit( MoveOk );
end;

function TBeing.MoveTowards( aWhere : TCoord2D; aVisualMultiplier : Single = 1.0 ): TMoveResult;
var iDir        : TDirection;
    iMoveResult : TMoveResult;
    iMoveCost   : Integer;
    iVisualMult : Single;
    iLevel      : TLevel;
begin
  iLevel := TLevel(Parent);
  iDir.CreateSmooth( FPosition, aWhere );
  FMovePos := FPosition + iDir;
  iMoveResult := TryMove( FMovePos );
  if iMoveResult = MoveBlock then
  begin
    iDir.Create( FPosition, aWhere );
    FMovePos := FPosition + iDir;
    iMoveResult := TryMove( FMovePos );
  end;
  if ( iMoveResult = MoveBlock ) and ( iDir.x <> 0 ) then
  begin
    FMovePos.x := FPosition.x + iDir.x;
    FMovePos.y := FPosition.y;
    iMoveResult := TryMove( FMovePos );
  end;
  if ( iMoveResult = MoveBlock ) and ( iDir.y <> 0 ) then
  begin
    FMovePos.x := FPosition.x;
    FMovePos.y := FPosition.y + iDir.y;
    iMoveResult := TryMove( FMovePos );
  end;
  if iMoveResult <> MoveOk then Exit( iMoveResult );

  iMoveCost   := getMoveCost;
  FSpeedCount := FSpeedCount - iMoveCost;
  if GraphicsVersion then
    if iLevel.AnimationVisible( FPosition, Self ) or iLevel.AnimationVisible( LastMove, Self ) then
    begin
      iVisualMult := ( 100.0 / FSpeed ) * ( iMoveCost / 1000.0 ) * aVisualMultiplier;
      IO.addMoveAnimation( Ceil( iVisualMult * 100 ), 0, FUID,Position,LastMove,Sprite, True, False );
    end;
  Displace( FMovePos );
  if BF_WALKSOUND in FFlags then
    PlaySound( 'hoof' );
  HandlePostDisplace;
  Exit( iMoveResult );
end;

procedure TBeing.Reload( aAmmoItem : TItem; aSingle : Boolean );
var iAmmo  : Byte;
    iPack  : Boolean;
    iCount : Integer;
    iCost  : Integer;
begin
  Inv.Slot[efWeapon].PlaySound( 'reload', FPosition );
  iCost := getReloadCost( Inv.Slot[efWeapon] );

  repeat
    iPack  := aAmmoItem.isAmmoPack;
    iCount := aAmmoItem.Amount;
    if iPack then iCount := aAmmoItem.Ammo;

    if aSingle then iAmmo := Min(iCount,1)
               else iAmmo := Min(iCount,Inv.Slot[efWeapon].AmmoMax-Inv.Slot[efWeapon].Ammo);

    iCount := iCount - iAmmo;
    if iPack
      then aAmmoItem.Ammo   := iCount
      else aAmmoItem.Amount := iCount;

    Inv.Slot[efWeapon].Ammo := Inv.Slot[efWeapon].Ammo + iAmmo;
    if iCount = 0 then
    begin
      FreeAndNil( aAmmoItem );
      if not iPack then
      begin
        if ( not aSingle ) and ( Inv.Slot[efWeapon].AmmoMax <> Inv.Slot[efWeapon].Ammo ) then
        begin
          aAmmoItem := FInv.SeekStack(Inv.Slot[efWeapon].AmmoID);
          if aAmmoItem <> nil then Continue;
        end;
      end;
    end;

    if iPack then
      Dec(FSpeedCount,iCost div 5)
    else
      Dec(FSpeedCount,iCost);
    Break;
  until aAmmoItem = nil;
end;

function TBeing.FireRanged( aTarget : TCoord2D; aGun : TItem; aAlt : TAltFire; aDelay : Integer = 0 ) : Boolean;
var iShots       : Integer;
    iShotsBonus  : Integer;
    iShotCost    : Integer;
    iShotsCost   : Integer;
    iChaining    : Boolean;
    iFreeShot    : Boolean;
    iResult      : Boolean;
    iSecond      : Boolean;
begin
  if DRL.State <> DSPlaying then Exit( False );
  if aTarget = FPosition then Exit( False );
  if aGun = nil then Exit( False );

  iShotsBonus  := GetBonus( Hook_getShotsBonus,  [ aGun, Integer( aAlt ) ] );

  iShots       := Max( aGun.Shots, 1 );
  iChaining    := ( aAlt = ALT_CHAIN ) and ( iShots > 1 );
  iShots       += iShotsBonus;

  if iChaining then
  begin
    case FChainFire of
      0      : iShots -= aGun.Shots div 3;
      1      : ;
      2..255 : iShots += aGun.Shots div 2;
    end;
  end;

  if aAlt = ALT_SINGLE then iShots := 1;

  iFreeShot := False;
  if aGun.Flags[ IF_NOAMMO ] or aGun.isUsable then iFreeShot := true;

  if not iFreeShot then
  begin
    iShotCost       := Max( aGun.ShotCost, 1 );
    iShotsCost      := iShots * iShotCost;
    iShotsCost      := Round( iShotsCost * GetBonusMul( Hook_getAmmoCostMul, [aGun, Integer( aAlt ), iShots ] ) );

    if iShotsCost > aGun.Ammo then
    begin
      if iShotsCost = ( iShots * iShotCost )
        then iShots := Min( aGun.Ammo div iShotCost, iShots )
        else iShots := Min( Floor( aGun.Ammo / ( iShotsCost / Single(iShots) ) ), iShots );
      iShotsCost := aGun.Ammo;
    end;
    if iShots < 1 then Exit( False );

    aGun.RechargeReset;

    aGun.Ammo := aGun.Ammo - iShotsCost;
  end;

  if iChaining and ( FChainFire < 255 ) then Inc( FChainFire );

  if iShots < 1 then Exit;

  if FTargetPos = Player.Position then Player.MultiMove.Stop;

  if isPlayer then
  begin
    if aGun.Flags[ IF_SHOTGUN ] then
      IO.addRumbleAnimation( aDelay, $2000, $8000, 100 )
    else
      IO.addRumbleAnimation( aDelay, $1000, $6000, 50 )
  end;


  if aGun.Flags[ IF_SHOTGUN ] then
    iResult := HandleShotgunFire( aTarget, aGun, aAlt, iShots )
  else if aGun.Flags[ IF_SPREAD ] then
    iResult := HandleSpreadShots( aTarget, aGun, aAlt )
  else
    iResult := HandleShots( aTarget, aGun, iShots, aAlt, aDelay );

  if not iResult then Exit( False );

  FTargetPos := aTarget;

  iSecond := (aGun = FInv.Slot[ efWeapon2 ]);
  aGun.CallHook( Hook_OnFired, [ Self, iSecond ] );
  CallHook( Hook_OnFired, [ aGun, iSecond ] );

  if aGun.Flags[ IF_DESTROY ] then
    FreeAndNil( aGun );

  Exit( True );
end;

procedure TBeing.Action;
var iThisUID : DWord;
begin
  FMeleeAttack := False;
  iThisUID := UID;
  TLevel(Parent).CallHook( FPosition, Self, CellHook_OnEnter );
  if UIDs[ iThisUID ] = nil then Exit;
  LastPos := FPosition;
  if UIDs[ iThisUID ] = nil then Exit;
  if CallHook(Hook_OnPreAction,[])  then if UIDs[ iThisUID ] = nil then Exit;
  CallHook(Hook_OnAction,[]);
  if UIDs[ iThisUID ] = nil then Exit;
  if CallHook(Hook_OnPostAction,[]) then if UIDs[ iThisUID ] = nil then Exit;
  while FSpeedCount >= 5000 do Dec( FSpeedCount, 1000 );
end;

procedure TBeing.HandlePostMove;
var iSlot : TEqSlot;
begin
  for iSlot in TEqSlot do
    if FInv.Slot[ iSlot ] <> nil then
      FInv.Slot[ iSlot ].CallHook( Hook_OnPostMove, [Self, iSlot <> efWeapon2 ]  );
  CallHook( Hook_OnPostMove, [] );
end;

procedure TBeing.HandlePostDisplace;
var iLevel      : TLevel;
begin
  BloodFloor;
  iLevel := TLevel( Parent );
  if iLevel.Item[ FPosition ] <> nil then
    if iLevel.Item[ FPosition ].Hooks[ Hook_OnEnter ] then
      iLevel.Item[ FPosition ].CallHook( Hook_OnEnter, [ Self ] );
end;


function TBeing.HandleCommand( aCommand : TCommand ) : Boolean; 
begin
  Result := True;
  case aCommand.Command of
    COMMAND_MOVE         : Result := ActionMove( aCommand.Target );
    COMMAND_USE          : Result := ActionUse( aCommand.Item, aCommand.Target );
    COMMAND_DROP         : Result := ActionDrop( aCommand.Item, aCommand.Alt );
    COMMAND_WEAR         : Result := ActionWear( aCommand.Item );
    COMMAND_TAKEOFF      : Result := ActionTakeOff( aCommand.Slot );
    COMMAND_SWAP         : Result := ActionSwap( aCommand.Item, aCommand.Slot );
    COMMAND_WAIT         : Dec( FSpeedCount, 1000 );
    COMMAND_ACTION       : Result := ActionAction( aCommand.Target );
    COMMAND_ENTER        : TLevel( Parent ).CallHook( Position, CellHook_OnExit );
    COMMAND_MELEE        : Attack( aCommand.Target, aCommand.Alt );
    COMMAND_RELOAD       : Result := ActionReload;
    COMMAND_ALTRELOAD    : Result := ActionAltReload;
    COMMAND_FIRE         : Result := ActionFire( aCommand.Target, aCommand.Item );
    COMMAND_ALTFIRE      : Result := ActionFire( aCommand.Target, aCommand.Item, True );
    COMMAND_PICKUP       : Result := ActionPickup;
    COMMAND_UNLOAD       : Result := ActionUnLoad( aCommand.Item, aCommand.ID );
    COMMAND_SWAPWEAPON   : Result := ActionSwapWeapon;
    COMMAND_QUICKKEY     : Result := ActionQuickKey( Ord( aCommand.ID[1] ) - Ord( '0' ) );
    COMMAND_ACTIVE       : Result := ActionActive;
    COMMAND_SWAPPOSITION : Result := ActionSwapPosition( aCommand.Target );
  else Exit( False );
  end;
  if Result then FLastCommand := aCommand;
end;

procedure TBeing.Tick;
begin
  inherited Tick;
  FInv.Tick;

  if ( FHP * 100 ) > Integer( FHPMax * FHPDecayMax ) then
    if FHP > 1 then
      if ( Player.Statistics.GameTime mod 50 = 0 ) then
        Dec( FHP );
  FSpeedCount := Min( FSpeedCount + FSpeed, 10000 );
  CallHook( Hook_OnTick, [ Player.Statistics.GameTime ] );
end;

function TBeing.Resurrect( aRange : Integer ) : TBeing;
var iRange  : Integer;
    iCoord  : TCoord2D;
    iLevel  : TLevel;
begin
  if aRange <= 0 then Exit( nil );
  iLevel := TLevel(Parent);
  for iRange := 1 to aRange do
    for iCoord in NewArea( FPosition, aRange ).Clamped( iLevel.Area.Shrinked ) do
      if iLevel.cellFlagSet( iCoord, CF_RAISABLE ) then
        if iLevel.isEmpty(iCoord,[EF_NOBEINGS,EF_NOBLOCK]) then
          if iLevel.isEyeContact( FPosition, iCoord ) then
            Exit( iLevel.Respawn( iCoord ) );
  Exit( nil );
end;


procedure TBeing.Blood( aFrom : TDirection; aAmount : LongInt );
var iCount : Integer;
    iCoord : TCoord2D;
    iLevel : TLevel;
begin
  if BF_NOBLEED in FFlags then Exit;
  iLevel := TLevel(Parent);
  if aAmount > 0 then
    for iCount := 1 to Min( aAmount, 20 ) do
    begin
      repeat
        case Random(5) of
          0..1 : iCoord := FPosition;
          2..3 : iCoord := FPosition + aFrom;
          4    : iCoord := FPosition + NewCoord2D( Random(3)-1, Random(3)-1);
        end;
      until iLevel.isProperCoord( iCoord );
      iLevel.Blood( iCoord );
    end;
  BloodDecal( aFrom, Clamp( aAmount + Random( aAmount ), 1, 12 ) );
end;

procedure TBeing.BloodDecal( aFrom : TDirection; aAmount : LongInt );
var iCount    : Integer;
    iLevel    : TLevel;
    iPosition : TVec2i;
    iOffset   : TVec2f;
    iDirOffset: TVec2f;
    iTCoord   : TCoord2D;
    iRange    : Single;
    iCanBleed : DWord;
    iSprite   : DWord;

  function RandomNorm : Single;
  var iU1, iU2 : Single;
  begin
    repeat iU1 := Random until iU1 <> 0.0;
    iU2 := Random;
    RandomNorm := Sqrt( -2.0 * Ln( iU1 ) ) * Cos( 2.0 * Pi * iU2 );
  end;

  function RandGuassian( aRadius : Single ) : TVec2f;
  begin
    repeat
      Result.X := RandomNorm * aRadius * 0.3;
      Result.Y := RandomNorm * aRadius * 0.3;
    until ( Result.X * Result.X + Result.Y * Result.Y ) < aRadius * aRadius;
  end;

  function CanBleedOn( aCoord : TCoord2D ) : DWord;
  var iCell : TCell;
  begin
    if not iLevel.isProperCoord( aCoord ) then Exit( 0 );
    iCell := Cells[ iLevel.CellBottom[ aCoord ] ];
    if CF_LIQUID    in iCell.Flags then Exit( 0 );
    if CF_BLOCKMOVE in iCell.Flags then
    begin
      if aCoord.y >= FPosition.y then Exit( 0 );
      if not ( CF_BLOCKLOS in iCell.Flags ) then Exit( 0 ); // void check
      aCoord.y := aCoord.y + 1;
      if not iLevel.isProperCoord( aCoord ) then Exit( 0 );
      iCell := Cells[ iLevel.CellBottom[ aCoord ] ];
      if ( CF_BLOCKMOVE in iCell.Flags ) then Exit( 0 );
      Exit( HARDSPRITE_DECAL_WALL_BLOOD[1+Random(3)] );
    end;
    Exit( HARDSPRITE_DECAL_BLOOD[1+Random(3)] );
  end;

begin
  iLevel := TLevel(Parent);
  iRange := Clampf( aAmount / 3.0, 0.75, 2.5 );
  iCanBleed := CanBleedOn( FPosition );
  iDirOffset.Init( aFrom.X * 0.5, aFrom.Y * 0.5 );
  for iCount := 1 to aAmount do
  begin
    iOffset := RandGuassian( iRange );
    iPosition.Init(
      Floor( ( FPosition.X + iOffset.X + iDirOffset.X ) * 32.0 ),
      Floor( ( FPosition.Y + iOffset.Y + iDirOffset.Y ) * 32.0 )
    );
    iTCoord := NewCoord2D( ( iPosition.X + 16 ) div 32, ( iPosition.Y + 16 ) div 32 );
    if iTCoord = FPosition then
    begin
      if ( iCanBleed <> 0 ) then
        iLevel.Decals.Add( iPosition, iCanBleed );
      Continue;
    end;
    iSprite := CanBleedOn( iTCoord );
    if iSprite <> 0 then
      iLevel.Decals.Add( iPosition, iSprite );
  end;
end;

procedure TBeing.Kill( aBloodAmount : DWord; aOverkill : Boolean; aKiller : TBeing; aWeapon : TItem; aDelay : Integer );
var iItem      : TItem;
    iCorpse    : Word;
    iBlood     : Byte;
    iDir       : TDirection;
    iLevel     : TLevel;
    iMeleeKill : Boolean;
begin
  iLevel := TLevel(Parent);
  if FDying then Exit;
  if not CallHookCheck( Hook_OnDieCheck, [ aOverkill ] ) then
  begin
    HP := Max(1,HP);
    Exit;
  end;
  FDying := True;

  // TODO: Change to Player.RegisterKill(kill)
  if ( not ( BF_FRIENDLY in FFlags ) ) and ( not ( BF_ILLUSION in FFlags ) ) then
    Player.RegisterKill( FID, aKiller, aWeapon, not Flags[ BF_RESPAWN ] );

  if (aKiller <> nil) and (aWeapon <> nil) then
    aWeapon.CallHook(Hook_OnKill, [ aKiller, Self ]);

  iMeleeKill := False;
  if (aKiller <> nil) then
  begin
    iMeleeKill := aKiller.MeleeAttack;
    aKiller.CallHook( Hook_OnKill, [ Self, aWeapon, aKiller.MeleeAttack ] );
  end;

  if not aOverkill then
  try
    if Flags[ BF_UNLOADONKILL ] and Assigned( FInv.Slot[ efWeapon ] ) then
    begin
      iItem := FInv.Slot[ efWeapon ];
      if ( not iItem.Flags[IF_NODROP] ) and ( not iItem.Flags[IF_NOUNLOAD] )
        and iItem.isUnloadable and ( iItem.Ammo > 0 ) then
        iItem.Ammo := FInv.AddStack(iItem.AmmoID,iItem.Ammo);
    end;

    for iItem in FInv do
      if not iItem.Flags[IF_NODROP] then
        iLevel.DropItem( iItem, FPosition, False, True );
  except
    on e : EPlacementException do ;
  end;

  iDir.code := 5;

  if aKiller <> nil then
    iDir.CreateSmooth( aKiller.FPosition, FPosition );

  iBlood := aBloodAmount;
  if aOverkill then iBlood *= 3;
  Blood(iDir,iBlood);

  CallHook( Hook_OnDie, [ aOverkill, iMeleeKill ] );

  if not aOverkill then
  begin
    iCorpse := GetLuaProtoValue('corpse');
    if iCorpse <> 0 then iLevel.DropCorpse( FPosition, iCorpse );
  end;

  if aOverkill then
    iLevel.playSound( 'gib',FPosition, Random(400) )
  else
    playSound( 'die', Random(400) );

  IO.addKillAnimation( 400, aDelay, Self );

  if not (BF_NOEXP in FFlags) then Player.AddExp(FExpValue);

  iLevel.Kill( Self );
end;

function TBeing.rollMeleeDamage( aSlot : TEqSlot = efWeapon; aTarget : TBeing = nil ) : Integer;
var iDamage   : Integer;
    iWeapon   : TItem;
begin
  iWeapon := Inv.Slot[ aSlot ];
  if ( iWeapon <> nil ) and ( not iWeapon.isMelee ) then iWeapon := nil;
  iDamage := getToDam( iWeapon, ALT_NONE, True );
  if iWeapon <> nil then
  begin
    if BF_MAXDAMAGE in FFlags then
      iDamage += iWeapon.maxDamage
    else
      iDamage += iWeapon.rollDamage;
  end
  else
  begin
    if BF_MAXDAMAGE in FFlags then
      iDamage += Max( (FStrength + 1) * 3, 1 )
    else
      iDamage += Max( Dice( FStrength + 1, 3 ), 1 );
  end;

  if iWeapon <> nil 
    then iDamage := Floor( iDamage * GetBonusMul( Hook_getDamageMul, [ iWeapon, True, ALT_NONE, aTarget ] ) * iWeapon.GetBonusMul( Hook_getDamageMul, [ True, ALT_NONE, aTarget ] ) )
    else iDamage := Floor( iDamage * GetBonusMul( Hook_getDamageMul, [ iWeapon, True, ALT_NONE, aTarget ] ) );
  if iDamage < 0 then iDamage := 0;
  rollMeleeDamage := iDamage;
end;

function TBeing.Attack( aWhere : TCoord2D; aMoveOnKill : Boolean ) : Boolean;
var iSlot       : TEqSlot;
    iWeapon     : TItem;
    iAttackCost : DWord;
    iLevel      : TLevel;
    iUID        : TUID;
    iPosition   : TCoord2D;
begin
  Result := False;
  FMeleeAttack := True;
  iSlot     := efTorso;
  iWeapon   := nil;
  iUID      := FUID;
  iLevel    := TLevel(Parent);
  iPosition := Position;
  if iLevel.Being[ aWhere ] <> nil then
    Result := Attack( iLevel.Being[ aWhere ] )
  else
  begin
    iSlot := meleeWeaponSlot;
    if iSlot in [ efWeapon, efWeapon2 ] then
	  iWeapon := Inv.Slot[ iSlot ];
	if iWeapon <> nil
      then iWeapon.PlaySound( 'fire', FPosition )
      else PlaySound( 'melee' );

    // Attack cost
    iAttackCost := getFireCost( ALT_NONE, True );

    if DRL.Level.AnimationVisible( Position, Self ) then
      IO.addBumpAnimation( VisualTime( iAttackCost, AnimationSpeedAttack ), 0, iUID, iPosition, aWhere, Sprite, 0.5 );

    if not ( BF_ILLUSION in FFlags ) then
      Result := iLevel.DamageTile( aWhere, rollMeleeDamage( iSlot ), Damage_Melee );
    Dec( FSpeedCount, iAttackCost )
  end;
  if iLevel.isAlive( iUID ) then
  begin
    if Result and aMoveOnKill and ( iPosition = Position ) then
      ActionMove( aWhere, 1.0, 0 )
    else
      if IsPlayer
        then IO.WaitForAnimation;
  end;
end;

function TBeing.Attack( aTarget : TBeing; aSecond : Boolean = False ) : Boolean;
var iName          : string;
    iDefenderName  : string;
    iResult        : string;
    iLevel         : TLevel;
    iDamage        : Integer;
    iWeaponSlot    : TEqSlot;
    iWeapon        : TItem;
    iDamageType    : TDamageType;
    iToHit         : Integer;
    iDualAttack    : Boolean;
    iAttackCost    : DWord;
    iTargetUID     : TUID;
    iUID           : TUID;
    iMissed        : Boolean;
begin
  Result := False;
  if BF_NOMELEE in FFlags then Exit;
  if aTarget = nil then Exit;
  iLevel       := TLevel(Parent);
  FMeleeAttack := True;
  iDualAttack  := False;
  iTargetUID   := aTarget.UID;
  iUID         := UID;
  iMissed      := False;

  // Choose weaponSlot
  iWeaponSlot := meleeWeaponSlot;
  if aSecond then iWeaponSlot := efWeapon2;

  iDamageType := Damage_Melee;
  if iWeaponSlot in [ efWeapon, efWeapon2 ] then
    iWeapon := Inv.Slot[ iWeaponSlot ]
  else
    iWeapon := nil;

  if ( iWeapon <> nil ) and ( not iWeapon.isMelee ) then iWeapon := nil;
  
  // Play Sound
  if (iWeapon <> nil) then
  begin
    iWeapon.PlaySound( 'fire', FPosition );
    iDamageType := iWeapon.DamageType;
  end
  else
    PlaySound( 'melee' );

  iDualAttack := canDualWieldMelee;

  // Attack cost
  iAttackCost := getFireCost( ALT_NONE, True );

  if not aSecond then
    if DRL.Level.AnimationVisible( FPosition, Self ) then
      IO.addBumpAnimation( VisualTime( iAttackCost, AnimationSpeedAttack ), 0, FUID, Position, aTarget.Position, Sprite, 0.5 );

  if iDualAttack or aSecond
    then Dec( FSpeedCount, iAttackCost div 2 )
    else Dec( FSpeedCount, iAttackCost );

  // Get names
  iName         := GetName( true );
  iDefenderName := aTarget.GetName( true );
  if IsPlayer         then iName         := 'you';
  if aTarget.IsPlayer then iDefenderName := 'you';

  // Last kill
  iToHit := getToHit( iWeapon, ALT_NONE, True ) - aTarget.GetBonus( Hook_getDefenceBonus, [True] );

  if Roll( 12 + iToHit ) < 0 then
  begin
    if IsPlayer then iResult := ' miss ' else iResult := ' misses ';
    if isVisible then IO.Msg( Capitalized(iName) + iResult + iDefenderName + '.' );
    iMissed := True;
  end;

  if not iMissed then
  begin
    if ( iWeapon <> nil ) then IO.addSoundAnimation( Iif( aSecond, 100, 30 ), aTarget.Position, IO.Audio.ResolveSoundID(['flesh_blade_hit']) );
    // Damage roll
    iDamage := rollMeleeDamage( iWeaponSlot, aTarget );

    // Shake
    if isPlayer or aTarget.IsPlayer then
      IO.addScreenShakeAnimation( 150, Iif( aSecond, 50, 0 ), Clampf( iDamage / 4, 3.0, 10.0 ), NewDirection( FPosition, aTarget.FPosition ) );

    // Hit message
    if IsPlayer then iResult := ' hit ' else iResult := ' hits ';
    if isVisible then IO.Msg( Capitalized(iName) + iResult + iDefenderName + '.' );

    // Apply damage
    if not ( BF_ILLUSION in FFlags ) then
      aTarget.ApplyDamage( iDamage, Target_Torso, iDamageType, iWeapon, 0 );
    if ( DRL.State <> DSPlaying ) or ( not iLevel.isAlive( iUID ) ) then Exit;
  end;

  if iWeapon <> nil then iWeapon.CallHook( Hook_OnFired, [ Self, aSecond ] );
  CallHook( Hook_OnFired, [ iWeapon, aSecond ] );

  Result := not TLevel(Parent).isAlive( iTargetUID );

  // Dualblade attack
  if iDualAttack and (not aSecond) and (not Result) then
    Exit( Attack( aTarget, True ) );
end;

function TBeing.meleeWeaponSlot: TEqSlot;
begin
  meleeWeaponSlot := efWeapon;
  if (BF_SWASHBUCKLER in FFlags) and
     ((Inv.Slot[efWeapon] = nil) or (not Inv.Slot[efWeapon].isMelee)) and
     (Inv.Slot[efWeapon2] <> nil) and (Inv.Slot[efWeapon2].isMelee) then
      meleeWeaponSlot := efWeapon2;
  if isPlayer then
  begin
    if (Inv.Slot[meleeWeaponSlot] <> nil) and Inv.Slot[meleeWeaponSlot].isMelee then
    begin
      if not DRL.CallHookCheck(Hook_OnFire,[Inv.Slot[meleeWeaponSlot], Self]) then Exit(efTorso);
    end
    else
      if not DRL.CallHookCheck(Hook_OnFire,[nil, Self]) then Exit(efTorso);
  end;
end;

function TBeing.getTotalResistance(const aResistance: AnsiString; aTarget: TBodyTarget): Integer;
var iResist : LongInt;
begin
  iResist := GetLuaProperty( ['resist',aResistance], 0 );
  if isPlayer and ( aTarget <> Target_Feet ) then iResist := Min( 95, iResist );
  if iResist >= 100 then Exit( 100 );
  getTotalResistance := iResist;
  if aTarget = Target_Internal then Exit;

  iResist := 0;
  if Inv.Slot[ efWeapon ] <> nil then
  begin
    iResist := Inv.Slot[ efWeapon ].GetResistance( aResistance );
    if iResist >= 100 then Exit( 100 );
  end;
  getTotalResistance += iResist;

  iResist := 0;
  case aTarget of
    Target_Torso    : if Inv.Slot[ efTorso ] <> nil then iResist := Inv.Slot[ efTorso ].GetResistance( aResistance );
    Target_Feet     : if Inv.Slot[ efBoots ] <> nil then iResist := Inv.Slot[ efBoots ].GetResistance( aResistance );
  end;
  if iResist >= 100 then Exit( 100 );

  iResist += GetBonus( Hook_getResistBonus, [ aResistance, Integer( aTarget ) ] );

  getTotalResistance += iResist;
  getTotalResistance := Min( 95, getTotalResistance );
end;

procedure TBeing.ApplyDamage( aDamage : LongInt; aTarget : TBodyTarget; aDamageType : TDamageType; aSource : TItem; aDelay : Integer );
var iDirection     : TDirection;
    iArmor         : TItem;
    iActive        : TBeing;
    iSlot          : TEqSlot;
    iArmorDamage   : LongInt;
    iProtection    : LongInt;
    iArmorValue    : Byte;
    iOverKillValue : LongInt;
    iResist        : LongInt;
begin
  if ( aDamage < 0 ) or (BF_INV in FFlags) or FDying then Exit;

  if aSource <> nil then
  begin
    if ( BF_SELFIMMUNE in FFlags ) and Self.Inv.Equipped( aSource ) then Exit;
    if aSource.Flags[ IF_ILLUSION ] then Exit;
  end;

  iActive := TLevel(Parent).ActiveBeing;
  if iActive <> nil then
  begin
     if ( ( aSource <> nil ) and ( iActive.Inv.Equipped( aSource ) ) ) then
     begin
       iActive.CallHook( Hook_OnDamage, [ Self, aDamage, aSource, aSource.isMelee ] );
       aSource.CallHook( Hook_OnDamage, [ Self, aDamage, iActive ] );
     end
     else if iActive.MeleeAttack then
       iActive.CallHook( Hook_OnDamage, [ Self, aDamage, aSource, True ] );
  end;
  if FDying then Exit;

  CallHook( Hook_OnReceiveDamage, [ aDamage, aSource, iActive ] );

  if FDying or ( BF_INV in FFlags ) then Exit;

  if aDamageType <> Damage_IgnoreArmor then
  begin
    case aDamageType of
      Damage_Acid        : iResist := getTotalResistance( 'acid', aTarget );
      Damage_Fire        : iResist := getTotalResistance( 'fire', aTarget );
      Damage_Cold        : iResist := getTotalResistance( 'cold', aTarget );
      Damage_Poison      : iResist := getTotalResistance( 'poison', aTarget );
      Damage_Sharpnel    : iResist := getTotalResistance( 'shrapnel', aTarget );
      Damage_Plasma,
      Damage_SPlasma     : iResist := getTotalResistance( 'plasma', aTarget );
      Damage_Bullet      : iResist := getTotalResistance( 'bullet', aTarget );
      Damage_Melee       : iResist := getTotalResistance( 'melee', aTarget );
      Damage_Pierce      : iResist := 0;
    else iResist := 0;
    end;
    if iResist >= 100 then Exit;
    if iResist <> 0 then
      aDamage := Max( Round( aDamage * ( (100-iResist) / 100 ) ), 1 );
  end;

  if isPlayer then
  begin
    if ( aTarget = Target_Torso ) and ( aDamage > 4 ) then
      PlaySound( 'pain' )
  end
  else PlaySound( 'hit' );

  iArmor := nil;
  iSlot := efWeapon;
  case aTarget of
    Target_Torso    : iSlot := efTorso;
    Target_Feet     : iSlot := efBoots;
  end;
  if iSlot <> efWeapon then iArmor := Inv.Slot[ iSlot ];

  iArmorValue := FArmor;
  if Inv.Slot[ efWeapon ] <> nil then
     iArmorValue += Inv.Slot[ efWeapon ].Armor;

  
  if iArmor <> nil then
  begin
    iProtection := iArmor.GetProtection;
    iArmorValue += iProtection;

    iArmorDamage := Max( aDamage - iProtection , 1 );
    if aDamageType = Damage_Acid then iArmorDamage *= 2;
    if iArmor.Flags[ IF_NODURABILITY ] then iArmorDamage := 0;
    iArmor.Durability := Max( 0, iArmor.Durability - iArmorDamage );

    if iArmorDamage > 0 then iArmor.RechargeReset;

    if (iArmor.Durability = 0) and (not iArmor.Flags[ IF_NODESTROY ]) then
    begin
      if IsPlayer then
        if aTarget = Target_Torso then IO.Msg('Your '+iArmor.Name+' is completely destroyed!')
                                  else IO.Msg('Your '+iArmor.Name+' are completely destroyed!');
      FreeAndNil( iArmor );
    end
    else if IsPlayer and ( iProtection <> iArmor.GetProtection ) then
      if aTarget = Target_Torso then IO.Msg('Your '+iArmor.Name+' is damaged!')
                                else IO.Msg('Your '+iArmor.Name+' are damaged!');

  end;

  if aDamageType = DAMAGE_SHARPNEL then iArmorValue := iArmorValue * 2;
  if aDamageType = DAMAGE_PLASMA   then iArmorValue := iArmorValue div 2;
  if aDamageType = DAMAGE_PIERCE   then iArmorValue := iArmorValue div 2;
  if aDamageType = DAMAGE_SPLASMA  then iArmorValue := iArmorValue div 3;


  if aDamageType <> Damage_IgnoreArmor then
  begin
    if (BF_HARDY in FFlags) and (aDamage <= iArmorValue) and (Random(2) = 1) then Exit;
    aDamage := Max( 1, aDamage - iArmorValue );
  end;

  if aDamage > 2 then
  begin
    if iActive <> nil then
      iDirection.Create( iActive.FPosition, FPosition )
    else iDirection.code := 5;
    Blood( iDirection, aDamage div 7 );
  end;

  case aDamageType of
    Damage_Fire    : iOverKillValue := FHPMax + FHPMax div 2;
    Damage_Acid    : iOverKillValue := FHPMax * 2;
    Damage_Plasma  : iOverKillValue := FHPMax * 2;
    Damage_Pierce  : iOverKillValue := FHPMax * 2;
    Damage_SPlasma : iOverKillValue := FHPMax;
  else
    iOverKillValue := FHPMax * 4;
  end;

  if IsPlayer then
  begin
    Player.Statistics.OnDamage( aDamage );
    if ( aTarget = Target_Feet )
      then IO.PulseBlood( 1.0 )
      else
      begin
        if aDamage > (FHPMax div 5) then
          IO.PulseBlood( Clampf( 4.0 * ( aDamage / FHPMax ), 0.5, 2.0 ) );
      end;
  end;

  FHP := Max( FHP - aDamage, 0 );
  if Dead and (not IsPlayer) and (not (BF_NODEATHMESSAGE in FFlags)) then
    if isVisible then IO.Msg(Capitalized(GetName(true))+' dies.')
                 else IO.Msg('You hear the scream of a freed soul!');
  if Dead
    then Kill( Min( aDamage div 2, 15), aDamage >= iOverKillValue, iActive, aSource, aDelay )
    else begin
      CallHook( Hook_OnAttacked, [ iActive, aSource ] );
      // TODO: handle Delay?
      FOverlayUntil := Max( FOverlayUntil, IO.Time + aDelay + PAIN_DURATION );
    end;
end;

function TBeing.calculateToHit( aBeing : TBeing ) : Integer;
var iWeapon : TItem;
    iToHit  : Integer;
begin
  if aBeing = nil then Exit( 0 );
  iWeapon := FInv.Slot[ efWeapon ];
  if (iWeapon = nil) or (iWeapon.isMelee) then
  begin
    if Distance( FPosition, aBeing.Position ) > 1 then Exit( 0 );
    iToHit := getToHit( iWeapon, ALT_NONE, True ) - aBeing.GetBonus( Hook_getDefenceBonus, [True] );
    Exit( toHitToChance( 12 + iToHit ) );
  end;

  if iWeapon.Flags[ IF_SHOTGUN ]
   or iWeapon.Flags[ IF_INSTANTHIT ]
   or iWeapon.Flags[ IF_EXACTHIT ]
   or iWeapon.Flags[ IF_AUTOHIT ] then Exit( 100 );

  iToHit := getToHit( iWeapon, ALT_NONE, False );
  iToHit -= aBeing.GetBonus( Hook_getDefenceBonus, [False] );
  if not iWeapon.Flags[ IF_FARHIT ] then
    iToHit -= Distance( FPosition, aBeing.Position ) div 3;

  Result := toHitToChance( 10 + iToHit );

  if ( not aBeing.isVisible ) and ( not iWeapon.Flags[ IF_UNSEENHIT ] ) then
    Result := Result div 2;
end;

function TBeing.SendMissile( aTarget : TCoord2D; aItem : TItem; aAltFire : TAltFire; aSequence : DWord; aShotCount : Integer ) : Boolean;
var iDirection  : TDirection;
    iMisslePath : TVisionRay;
    iOldCoord   : TCoord2D;
    iTarget     : TCoord2D;
    iSource     : TCoord2D;
    iCoord      : TCoord2D;
    iColor      : Byte;
    iToHit      : Integer;
    iDamage     : Integer;
    iBeing      : TBeing;
    iAimedBeing : TBeing;
    iMaxRange   : Byte;
    iRoll       : TDiceRoll;
    iRadius     : Byte;
    iIsHit      : Boolean;
    iRunDamage  : Boolean;
    iDodged     : Boolean;
    iFireDesc   : Ansistring;
    iSprite     : TSprite;
    iDuration   : DWord;
    iMarkSeq    : DWord;
    iSteps      : DWord;
    iDelay      : DWord;
    iSound      : DWord;
    iDirectHit  : Boolean;
    iThisUID    : TUID;
    iItemUID    : TUID;
    iHit        : Boolean;
    iLevel      : TLevel;
    iStart      : TCoord2D;
    iDamageMod  : Integer;
    iDamageMul  : Single;
    iMaxDamage  : Boolean;
    iCover      : TLuaEntityNode;
    iCoverValue : Integer;
    iExplosion  : TExplosionData;
begin
  if DRL.State <> DSPlaying then Exit( False );
  if aItem = nil then Exit( False );
  if not aItem.isWeapon then Exit( False );
  if FHP <= 0 then Exit( False );

  iLevel     := TLevel(Parent);
  iDirectHit := False;
  iThisUID   := FUID;
  iItemUID   := aItem.uid;
  iDodged    := False;
  if iLevel.isProperCoord( aTarget ) then
  begin
    iBeing      := iLevel.Being[ aTarget ];
    iAimedBeing := iLevel.Being[ aTarget ];
  end;
  if iBeing <> nil then
    if Random(100) <= getStrayChance( iBeing, aItem ) then
    begin
      if iBeing.FLastPos.X = 1 then iBeing.FLastPos := iBeing.FPosition;
      aTarget := iBeing.FLastPos;
      iDodged := True;
    end;
      
  case aItem.MisColor of
    MULTIYELLOW : case Random(3) of 0 : iColor := LightGreen; 1 : iColor := White;  2 : iColor := Yellow; end;
    MULTIBLUE   : case Random(3) of 0 : iColor := LightBlue;  1 : iColor := White;  2 : iColor := Blue;   end;
  else
    iColor := aItem.MisColor;
  end;
  iDelay := aItem.MisDelay;

  iMaxRange := 30; //aGun.MaxRange

  iToHit := getToHit( aItem, aAltFire, False );
  if aAltFire = ALT_AIMED then iToHit += 3;
  if aItem.Flags[ IF_SPREAD ] then iToHit += 10;

  iTarget := aTarget;
  iSource := FPosition;
  
  if aItem.Flags[ IF_INSTANTHIT ] then
      iSource := iTarget;

  iMisslePath.Init( iLevel, iSource, aTarget );

  iMaxDamage := (BF_MAXDAMAGE in FFlags) 
             or CallHookCan( Hook_OnCanMaxDamage, [ aItem, Integer( aAltFire ) ] )
             or aItem.CallHookCan( Hook_OnCanMaxDamage, [ Integer( aAltFire ), iBeing ] );
  if iMaxDamage then
    iDamage := aItem.maxDamage
  else
    iDamage := aItem.rollDamage;

  iDamageMod := getToDam( aItem, aAltFire, False );
  iDamageMul := GetBonusMul( Hook_getDamageMul, [ aItem, False, Integer( aAltFire ), iBeing ] )
              * aItem.GetBonusMul( Hook_getDamageMul, [ False, Integer( aAltFire ), iBeing ] );
  IO.Msg( '%f', [iDamageMul] );
  iDamage    += iDamageMod;
  iDamage    := Floor( iDamage * iDamageMul );

  iSteps := 0;
  iHit   := aItem.Flags[ IF_EXACTHIT ];
  iIsHit := aItem.Flags[ IF_EXACTHIT ];
  iStart := iMisslePath.GetSource;

  iRadius := aItem.Radius;
  if ( BF_FIREANGEL in FFlags ) and ( not ( aItem.Hooks[ Hook_OnHitBeing ] ) ) then
    iRadius += 1;

  repeat
    iOldCoord := iMisslePath.GetC;
    if not aItem.Flags[ IF_INSTANTHIT ] then
      iMisslePath.Next;
    iCoord := iMisslePath.GetC;
    iSteps := Distance (iStart.x, iStart.y, iCoord.x, iCoord.y);

    if not iLevel.isProperCoord( iCoord ) then Break;

    if not iLevel.isEmpty( iCoord, [EF_NOBLOCK] ) then
    begin
      iCoverValue := 10;
      if ( iCoord <> iTarget ) and ( not iLevel.cellFlagSet( iCoord, CF_BLOCKMOVE ) ) then
      begin
        iCoverValue := 0;
        iCover      := iLevel.GetItem( iCoord );
        if ( iCover <> nil ) then
        begin
          if not aItem.Flags[ IF_LOB ] then
          begin
            if iCover.Flags[ IF_LIGHTCOVER ] then iCoverValue := 3;
            if iCover.Flags[ IF_HARDCOVER ]  then iCoverValue := 7;
          end;
          if iCover.Flags[ IF_BLOCKSHOT ] then iCoverValue := 10;
        end;
      end;

      if ( iCoverValue >= 10 ) or ( Random(10) < iCoverValue ) then
      begin
        if (iAimedBeing = Player) and (iDodged) then IO.Msg('You dodge!');

        if aItem.Flags[ IF_DESTRUCTIVE ]
          then iLevel.DamageTile( iCoord, iDamage * 2, aItem.DamageType )
          else iLevel.DamageTile( iCoord, iDamage, aItem.DamageType );

        if iLevel.isVisible( iCoord ) then
          IO.Msg('Boom!');
        iCoord := iOldCoord;
        iHit   := True;
        Break;
      end;
    end;

    if iLevel.Being[ iCoord ] <> nil then
    begin
      iBeing := iLevel.Being[ iCoord ];
      if iBeing = iAimedBeing then
        iDodged := False;

      if aItem.Flags[ IF_LOB ] and ( iCoord <> iTarget ) then iToHit := -iToHit;
      iToHit -= iBeing.GetBonus( Hook_getDefenceBonus, [False] );

      if aItem.Flags[ IF_FARHIT ]
        then iIsHit := Roll( 10 + iToHit) >= 0
	else iIsHit := Roll( 10 - (distance(FPosition, iCoord ) div 3 ) + iToHit) >= 0;
      
      if iIsHit and ( not iLevel.isVisible( iCoord ) ) and ( not aItem.Flags[ IF_UNSEENHIT ] ) then
        iIsHit := (Random(10) > 4);
      
      if aItem.Flags[ IF_AUTOHIT ] then iIsHit := True;

      if iIsHit and ( iBeing <> iAimedBeing ) then
        if ( isPlayer and iBeing.Flags[ BF_FRIENDLY ] ) or
          ( Flags[ BF_FRIENDLY ] and iBeing.IsPlayer ) then
           if Random( 3 ) > 0 then
             iIsHit := False;

      if iIsHit then
      begin
        if iLevel.Being[ iCoord ] = Player
          then iDirectHit := True
          else if (iAimedBeing = Player) and (iDodged) then IO.Msg('You dodge!');
        if iLevel.isVisible( iCoord ) then
            if iBeing.IsPlayer then
            begin
              iFireDesc := LuaSystem.Get(['items',aItem.NID,'hitdesc'], '');
              if iFireDesc = '' then iFireDesc := 'You are hit!';
              IO.Msg( Capitalized( iFireDesc ) );
            end
            else IO.Msg('The missile hits '+iBeing.GetName(true)+'.');

        if iRadius = 0 then
        begin
          if ( not aItem.Flags[ IF_PIERCEHIT ] ) and ( aItem.Knockback > 0 ) then
          begin
            iDirection.CreateSmooth( Self.FPosition, iCoord );
            iBeing.KnockBack( iDirection, iDamage / aItem.Knockback );
          end;
          iRunDamage := True;
          if aItem.Hooks[ Hook_OnHitBeing ] then
          begin
            iRunDamage    := aItem.CallHookCheck(Hook_OnHitBeing,[Self,iBeing]);
          end;
          if iRunDamage then
            iBeing.ApplyDamage( iDamage, Target_Torso, aItem.DamageType, aItem, aSequence );
        end;

        if not aItem.Flags[ IF_PIERCEHIT ] then
        begin
          aTarget := iCoord;
          iHit    := True;
          Break;
        end;
      end;
    end;
    
    if iMisslePath.Done then
      if aItem.Flags[ IF_EXACTHIT ] then
        Break;

    if ( iSteps >= iMaxRange ) or aItem.Flags[ IF_INSTANTHIT ] then
    begin
      if (iAimedBeing = Player) and (iDodged) then IO.Msg('You dodge!');
      break;
    end;

    if UIDs[ iItemUID ] = nil then
    begin
      aItem := nil;
      vdebug.Log( LOGWARN, 'Item destroyed duirng SendMissile!');
      Exit( False );
    end;
  until false;

  if UIDs[ iThisUID ] = nil then Exit( False );

  if ( not aItem.Flags[ IF_SERIESSOUND ] ) or ( aShotCount = 0 ) then
  begin
    iSound  := IO.Audio.ResolveSoundID([aItem.ID+'.fire',aItem.SoundID+'.fire','fire']);
    if iSound <> 0 then
      IO.addSoundAnimation( aSequence, iSource, iSound );
  end;

  iSprite := aItem.MisSprite;

  if not aItem.Flags[ IF_INSTANTHIT ] then
  begin
    if aItem.Flags[ IF_RAYGUN ] then
    begin
      iDuration := iDelay;
      iMarkSeq  := 0;
    end
    else
    begin
      iDuration := (iSource - iMisslePath.GetC).LargerLength * iDelay;
      iMarkSeq  := iDuration + aSequence;
    end;
    IO.addMissileAnimation( iDuration, aSequence,iSource,iMisslePath.GetC,iColor,aItem.MisASCII,iDelay,iSprite,aItem.Flags[ IF_RAYGUN ]);
    if iHit and iLevel.isVisible( iMisslePath.GetC ) then
    begin
      IO.addSoundAnimation( iMarkSeq, iMisslePath.GetC, IO.Audio.ResolveSoundID([Iif( iIsHit, 'flesh_bullet_hit', 'concrete_bullet_hit' )]) );
      IO.addMarkAnimation(199, iMarkSeq, iMisslePath.GetC, aItem.HitSprite, Iif( iIsHit, LightRed, LightGray ), '*' );
    end;
  end;

  if aItem.Flags[ IF_THROWDROP ] then
  try
    iLevel.DropItem( aItem, iCoord, False, True )
  except
    FreeAndNil( aItem );
  end;

  if iRadius <> 0 then
  begin
    iRoll.Init(aItem.Damage_Dice, aItem.Damage_Sides, aItem.Damage_Add + iDamageMod );

    if iMaxDamage then
      iRoll.Init( 0,0, iRoll.Max );

    iExplosion            := aItem.Explosion;
    iExplosion.Range      := iRadius;
    if IO.Audio.GetSampleID(aItem.ID+'.explode') > 0
      then iExplosion.SoundID := aItem.ID
      else iExplosion.SoundID := Iif( aItem.SoundID <> '', aItem.SoundID, 'explode' );
    iExplosion.Damage     := iRoll;
    iExplosion.DamageType := aItem.DamageType;
    iDirection.CreateSmooth( FPosition, iCoord );
    iLevel.Explosion( iDelay*(iSteps+(aShotCount*2)), iCoord, iExplosion, aItem, iDirection, iDirectHit, iDamageMul );
  end;
  if (iAimedBeing = Player) and (iDodged) then Player.LastTurnDodge := True;
  Exit( UIDs[ iThisUID ] <> nil );
end;

procedure TBeing.BloodFloor;
var iLevel : TLevel;
begin
  if BF_FLY in FFlags then Exit;
  iLevel := TLevel(Parent);
       if iLevel.cellFlagSet( FPosition, CF_VBLOODY ) then Inc(FBloodBoots,1)
  else if iLevel.LightFlag[ FPosition, LFBLOOD ] then Inc(FBloodBoots,0)
    else if FBloodBoots > 0 then Dec(FBloodBoots);
  if FBloodBoots > 6 then FBloodBoots := 6;
  if FBloodBoots = 0 then Exit;
  if (iLevel.cellFlagSet(FPosition,CF_VBLOODY)) or
     (iLevel.LightFlag[ FPosition, LFBLOOD ]) then Exit;
  iLevel.Blood(FPosition);
  BloodDecal( NewDirection(0), 1 );
end;

procedure TBeing.Knockback( aDir : TDirection; aStrength : Single );
var iKnock     : TCoord2D;
    iLevel     : TLevel;
    iStrength  : Integer;
begin
  iLevel := TLevel(Parent);
  if aStrength <= 0.0         then Exit;
  if aDir.code = 0            then Exit;
  if BF_KNOCKIMMUNE in FFlags then Exit;

  iKnock     := FPosition + aDir;
  aStrength  *= getKnockMod / 100.0;
  iStrength  := Floor( aStrength ) - GetBonus( Hook_getBodyBonus, [] );
  if iStrength <= 0 then Exit;

  if not iLevel.isEmpty( iKnock, [EF_NOBEINGS,EF_NOBLOCK] ) then Exit;
  iKnock := FPosition;
  while iStrength > 0 do
  begin
    if not iLevel.isEmpty(iKnock + aDir, [EF_NOBEINGS,EF_NOBLOCK] ) then Break;
    iKnock += aDir;
    Dec(iStrength);
  end;

  if iLevel.isEmpty(iKnock,[EF_NOBEINGS,EF_NOBLOCK]) then
  begin
    if GraphicsVersion then
    begin
      if isPlayer then
        IO.addScreenMoveAnimation(100, iKnock );
      if iLevel.AnimationVisible( FPosition, Self ) or iLevel.AnimationVisible( iKnock, Self ) then
        IO.addMoveAnimation(100,0,FUID,Position,iKnock,Sprite,True,True);
      if isPlayer then
        IO.addScreenShakeAnimation( 400, 0, Clampf( iStrength * 1.0, 2.0, 10.0 ) );
    end;
    Displace( iKnock );
    HandlePostDisplace;
  end;
end;

function TBeing.getMoveCost: LongInt;
var iModifier  : Single;
    iMoveBonus : Integer;
    iSlot      : TEqSlot;
begin
  iModifier := FTimes.Move/100.0;
  for iSlot in TEqSlot do
    if Inv.Slot[iSlot] <> nil then
      with Inv.Slot[iSlot] do
        if MoveMod <> 0 then
          iModifier *= (100-MoveMod)/100.0;
  iMoveBonus := GetBonus( Hook_getMoveBonus, [] );
  if iMoveBonus <> 0 then iModifier *= (100-iMoveBonus)/100.0;
  if not ( BF_FLY in FFlags ) then
    with Cells[ TLevel(Parent).getCell(FPosition) ] do
      iModifier *= MoveCost;
  getMoveCost := Round( ActionCostMove * iModifier );
end;

function TBeing.getFireCost( aAltFire : TAltFire; aIsMelee : Boolean ) : LongInt;
var iModifier : Single;
    iBonus    : Integer;
    iWeapon   : TItem;
  function getWeaponFireCost( aWeapon : TItem ) : LongInt;
  begin
    if aIsMelee and ( aWeapon <> nil ) and ( not aWeapon.isMelee ) then aWeapon := nil;
    iModifier := 10;
    if aWeapon <> nil then iModifier := aWeapon.UseTime;
    iModifier *= FTimes.Fire/1000.0;
    iBonus    := GetBonus( Hook_getFireCostBonus, [ aWeapon, aIsMelee, Integer( aAltFire ) ] );
    if iBonus <> 0 then iModifier *= Max( (100.0-iBonus)/100, 0.1 );
    if iModifier < 0.1 then iModifier := 0.1;
    iModifier *= GetBonusMul( Hook_getFireCostMul, [ aWeapon, aIsMelee, Integer( aAltFire ) ] );
    if (aAltFire = ALT_AIMED) then iModifier *= 2;
    getWeaponFireCost := Round( ActionCostFire*iModifier );
  end;

begin
  iWeapon   := Inv.Slot[ efWeapon ];
  if ( iWeapon <> nil ) and ( aAltFire <> ALT_SINGLE ) then
    if ( aIsMelee and canDualWieldMelee ) or ( (not aIsMelee) and canDualWield and (Inv.Slot[ efWeapon2 ].Ammo > 0) ) then
       Exit( ( getWeaponFireCost( iWeapon ) + getWeaponFireCost( Inv.Slot[ efWeapon2 ] ) ) div 2 );
  Exit( getWeaponFireCost( iWeapon ) );
end;

function TBeing.getReloadCost( aItem : TItem ) : LongInt;
var iModifier : Real;
begin
  if (aItem = nil) or (aItem.isMelee) then Exit(1000);
  iModifier := aItem.ReloadTime/10.0;
  iModifier *= FTimes.Reload/100.0;
  iModifier *= GetBonusMul( Hook_getReloadCostMul, [ aItem ] );

  getReloadCost := Round(ActionCostReload*iModifier);
end;

function TBeing.getUseCost( aItem : TItem ) : LongInt;
begin
  getUseCost := 10;
  if aItem <> nil then getUseCost := aItem.UseTime;
  getUseCost := FTimes.Use * getUseCost;
end;

function TBeing.getWearCost( aItem : TItem ) : LongInt;
begin
  getWearCost := 10;
  if aItem <> nil then getWearCost := aItem.SwapTime;
  getWearCost := FTimes.Wear * getWearCost;
end;

function TBeing.getDodgeMod : LongInt;
var iSlot : TEqSlot;
begin
  Result := GetBonus( Hook_getDodgeBonus, [] );
  for iSlot in TEqSlot do
    if Inv.Slot[iSlot] <> nil then
      Result += Inv.Slot[iSlot].DodgeMod;
end;

function TBeing.getKnockMod : LongInt;
var iModifier : Real;
    iSlot     : TEqSlot;
begin
  iModifier := 100;
  for iSlot in TEqSlot do
    if Inv.Slot[iSlot] <> nil then
      with Inv.Slot[iSlot] do
        if KnockMod <> 0 then
          iModifier *= (100 + KnockMod) / 100.0 ;
  getKnockMod := Round(iModifier) ;
end;

function TBeing.canDualWield : boolean;
begin
  if ( Inv.Slot[efWeapon] <> nil ) and ( Inv.Slot[efWeapon2] <> nil ) and ( Inv.Slot[ efWeapon2 ].isWeapon ) then
    Exit( CallHookCan( Hook_OnCanDualWield, [ Inv.Slot[efWeapon], Inv.Slot[efWeapon2] ] ) );
  Exit( False );
end;

function TBeing.canDualWieldMelee: boolean;
begin
  if ( Inv.Slot[efWeapon] <> nil ) and ( Inv.Slot[efWeapon2] <> nil ) and ( Inv.Slot[ efWeapon ].isMelee ) and ( Inv.Slot[ efWeapon2 ].isMelee ) then
    Exit( CallHookCan( Hook_OnCanDualWield, [ Inv.Slot[efWeapon], Inv.Slot[efWeapon2] ] ) );
  Exit( False );
end;

function TBeing.canPackReload : Boolean;
var Weapon, Pack : TItem;
begin
  Weapon := FInv.Slot[ efWeapon ];
  Pack   := FInv.Slot[ efWeapon2 ];
  Exit( ( Weapon <> nil ) and ( Weapon.isRanged )
    and ( Pack <> nil )   and ( Pack.isAmmoPack )
    and ( Pack.AmmoID = Weapon.AmmoID) );
end;

function TBeing.getToHit(aItem : TItem; aAltFire : TAltFire; aIsMelee : Boolean) : Integer;
begin
  getToHit := FAccuracy + GetBonus( Hook_getToHitBonus,  [ aItem, aIsMelee, Integer( aAltFire ) ] );
  if (aItem <> nil) and ( aItem.isMelee = aIsMelee ) then getToHit += aItem.Acc;
  if not isPlayer then
    getToHit += TLevel(Parent).AccuracyBonus;
end;

function TBeing.getToDam(aItem : TItem; aAltFire : TAltFire; aIsMelee : Boolean) : Integer;
begin
  getToDam := GetBonus( Hook_getDamageBonus, [ aItem, aIsMelee, Integer( aAltFire ) ] );
end;

destructor TBeing.Destroy;
begin
  FreeAndNil( FInv );
  FreeAndNil( FPath );
  inherited Destroy;
end;

{ IBeingAI }

function TBeing.MoveCost(const Start, Stop: TCoord2D): Single;
var iDiff     : TCoord2D;
    iStopCell : TCell;
    iStopID   : Byte;
  function isHazard( aID : Byte ) : Boolean;
  begin
    if isPlayer and ( CellHook_OnHazardQuery in Cells[ aID ].Hooks ) then
    begin
      if aID in FPathHazards then Exit( True );
      if aID in FPathClear   then Exit( False );
      if TLevel(Parent).CallHook( CellHook_OnHazardQuery, aID, Self )
        then begin Include( FPathHazards, aID ); Exit( True ); end
        else begin Include( FPathClear, aID );   Exit( False ); end
    end
    else Exit( CF_HAZARD in Cells[ aID ].Flags );
  end;

begin
  iDiff := Start - Stop;
  if iDiff.x * iDiff.y = 0
     then MoveCost := 1.0
     else MoveCost := 1.3;

  if TLevel(Parent).Being[ Stop ] <> nil then MoveCost := MoveCost * 5;

  iStopID   := TLevel(Parent).getCell(Stop);
  iStopCell := Cells[ iStopID ];
  if not ( BF_FLY in FFlags ) then MoveCost := MoveCost * iStopCell.MoveCost;
  if BF_ENVIROSAFE in FFlags then Exit;
  if isHazard( iStopID ) then
  begin
    if FHp = FHpMax then Exit( 30 * MoveCost );
    if isHazard( TLevel(Parent).getCell(Start) ) then Exit( 3 * MoveCost );
    Exit( 5 * MoveCost );
  end;
end;

function TBeing.CostEstimate(const Start, Stop: TCoord2D): Single;
begin
  Exit( RealDistance(Start,Stop) )
end;

function TBeing.passableCoord( const aCoord : TCoord2D ): boolean;
var iItem : TItem;
begin
  if not TLevel(Parent).isProperCoord( aCoord ) then Exit( False );
  with Cells[ TLevel(Parent).getCell( aCoord ) ] do
  begin
    if (not isPlayer) and (CF_HAZARD in Flags) and (not ((BF_ENVIROSAFE in FFlags) or (BF_CHARGE in FFlags))) then Exit( False );
    iItem := TLevel(Parent).Item[ aCoord ];
    if Assigned( iItem ) and ( iItem.Flags[ IF_BLOCKMOVE ] ) then Exit( False );
    if (not ( CF_BLOCKMOVE in Flags )) then Exit( True );
    if (BF_OPENDOORS in FFlags) and ( CF_OPENABLE in Flags ) then Exit( True );
  end;
  Exit( False );
end;

function lua_being_new(L: Plua_State): Integer; cdecl;
var State       : TDRLLuaState;
    Being       : TBeing;
begin
  State.Init( L );
  Being := TBeing.Create(State.ToId( 1 ));
  State.Push( Being );
  Result := 1;
end;

function lua_being_kill(L: Plua_State): Integer; cdecl;
var State       : TDRLLuaState;
    Being       : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  Being.Kill(15,State.ToBoolean(2),nil,nil,0);
  Result := 0;
end;

function lua_being_get_name(L: Plua_State): Integer; cdecl;
var State       : TDRLLuaState;
    Being       : TBeing;
    Res         : AnsiString;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  Res := Being.getName(State.ToBoolean( 2 ));
  if State.ToBoolean( 3 ) then Res := Capitalized(Res);
  State.Push( Res );
  Result := 1;
end;

function lua_being_resurrect( L: Plua_State ): Integer; cdecl;
var iState : TDRLLuaState;
    iBeing : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  iState.Push( iBeing.Resurrect( iState.ToInteger(2) ) );
  Result := 1;
end;

function lua_being_apply_damage(L: Plua_State): Integer; cdecl;
var State       : TDRLLuaState;
    Being       : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  Being.ApplyDamage(State.ToInteger(2),TBodyTarget( State.ToInteger(3) ), TDamageType( State.ToInteger(4,Byte(Damage_Bullet)) ), State.ToObjectOrNil(2) as TItem, 0 );
  Result := 0;
end;

function lua_being_get_eq_item(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  State.Push( Being.Inv.Slot[TEqSlot(State.ToInteger( 2 ))] );
  Result := 1;
end;

function lua_being_set_eq_item(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
    slot    : TEqSlot;
    Item    : TItem;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  slot  := TEqSlot(State.ToInteger( 2 ));
  Item  := State.ToObjectOrNil(3) as TItem;

  if (Being.Inv.Slot[slot] <> nil) and (Being.Inv.Slot[slot] <> Item) then
    Being.Inv.Slot[slot].Free;

  if item <> nil then
    if not (Item.IType in ItemEqFilters[slot]) then
      State.Error('Being.seteqitem has wrong item for given slot!'+IntToStr(LongInt(Item.IType))+','+IntToStr(LongInt(Slot)));

  Being.Inv.setSlot(slot,Item);
  Result := 0;
end;

function lua_being_add_inv_item(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
    iItem   : TItem;
    iAmount : Integer;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  iItem  := iState.ToObject(2) as TItem;

  if iItem.isStackable then
  begin
    iAmount := iBeing.FInv.AddStack(iItem.NID,iItem.Amount);
    if iAmount <> iItem.Amount then
    begin
      if iAmount = 0
        then iItem.Free
        else iItem.Amount := iAmount;
      iState.Push( iAmount = 0 );
    end
    else
      iState.Push( False );
    Exit( 1 )
  end;
  if iBeing.FInv.isFull then
    iState.Push( False )
  else
  begin
    iBeing.FInv.Add( iItem );
    iState.Push( True );
  end;
  Result := 1;
end;

function lua_being_get_total_resistance(L: Plua_State): Integer; cdecl;
var State  : TDRLLuaState;
    Being  : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  State.Push( Being.getTotalResistance( State.ToString(2), TBodyTarget( State.ToInteger(3, Byte(TARGET_TORSO) ) )) );
  Result := 1;
end;

function lua_being_play_sound(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
    Being : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  Being.playSound( State.ToString(2), State.ToInteger(3,0) );
  Result := 0;
end;

function lua_being_quick_swap(L: Plua_State): Integer; cdecl;
var State  : TDRLLuaState;
    Being  : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  State.Push( Being.ActionSwapWeapon );
  Result := 1;
end;

function lua_being_drop(L: Plua_State): Integer; cdecl;
var State  : TDRLLuaState;
    Being  : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  State.Push( Being.ActionDrop( State.ToObjectOrNil( 2 ) as TItem, False ) );
  Result := 1;
end;

function lua_being_attack(L: Plua_State): Integer; cdecl;
var State  : TDRLLuaState;
    Being  : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if State.IsObject(2) then
    Being.Attack( State.ToObject(2) as TBeing )
  else
  begin
    if State.IsNil(2) then Exit(0);
    Being.Attack( State.ToCoord(2), State.ToBoolean(3) );
  end;
  Result := 1;
end;

function lua_being_action_fire(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
    iWeapon : TItem;
    iTarget : TCoord2D;
    iDelay  : Integer;
begin
  iState.Init(L);
  iBeing  := iState.ToObject( 1 ) as TBeing;
  iTarget := iState.ToPosition( 2 );
  iWeapon := iState.ToObject( 3 ) as TItem;
  iDelay  := iState.ToInteger( 4, 0 );
  if ( iBeing = nil ) or ( iWeapon = nil ) then Exit( 0 );
  if iWeapon.CallHookCheck( Hook_OnFire, [ iBeing ] )
    then iState.Push( iBeing.ActionFire( iTarget, iWeapon, False, iDelay, iState.ToBoolean( 5, False ) ) )
    else iState.Push( False );
  Result := 1;
end;

function lua_being_reload(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
    iWeapon : TItem;
    iItem   : TItem;
    iSingle : Boolean;
    iSCount : LongInt;
begin
  iState.Init(L);
  iBeing  := iState.ToObject(1) as TBeing;
  if iBeing <> nil then
  begin
    iWeapon := iBeing.Inv.Slot[ efWeapon ];
    if ( iWeapon <> nil ) and ( not iWeapon.Flags[ IF_RECHARGE ] ) then
    begin
      iItem := iState.ToObjectOrNil(2) as TItem;
      if iItem = nil then iItem := iBeing.Inv.SeekStack( iWeapon.AmmoID );
      if (iItem = nil) and iBeing.canPackReload then
        iItem := iBeing.Inv.Slot[ efWeapon2 ];
      if iItem <> nil then
      begin
        iSingle := iState.ToBoolean( 3, iWeapon.Flags[IF_SINGLERELOAD] );
        iSCount := iBeing.SCount;
        iBeing.Reload( iItem, iSingle );
        if not iState.ToBoolean( 4 ) then
          iBeing.SCount := iSCount;
        iState.Push( True );
        Exit( 1 );
      end;
    end;
  end;
  iState.Push( False );
  Result := 1;
end;

function lua_being_action_reload(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  iState.Push( iBeing.ActionReload );
  Result := 1;
end;

function lua_being_action_alt_reload(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  iState.Push( iBeing.ActionAltReload );
  Result := 1;
end;

function lua_being_action_dual_reload(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  iState.Push( iBeing.ActionDualReload );
  Result := 1;
end;

function lua_being_direct_seek(L: Plua_State): Integer; cdecl;
var State  : TDRLLuaState;
    Being  : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  if State.IsNil(2) then begin State.Push( Byte(MoveBlock) ); Exit(1); end;
  State.Push( Byte(Being.MoveTowards(State.ToPosition(2), State.ToFloat(3,1.0))) );
  State.PushCoord( Being.LastMove );
  Result := 2;
end;

function lua_being_use(L: Plua_State): Integer; cdecl;
var State  : TDRLLuaState;
    Being  : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  State.Push( Being.ActionUse( State.ToObjectOrNil(2) as TItem, State.ToPosition(3,Being.TargetPos) ) );
  Result := 1;
end;

function lua_being_wear(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
    iItem   : TItem;
    iLRes   : Boolean;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  iItem  := iState.ToObject(2) as TItem;
  iLRes  := False;
  if iItem <> nil then
  begin
    with iBeing do
    if iItem.isWearable then
    begin
      SCount := SCount - getWearCost( iItem );
      Inv.Wear( iItem );
      iLRes := True;
    end;
  end;
  iState.Push( iLRes );
  Result := 1;
end;

function lua_being_pickup(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  iState.Push( iBeing.ActionPickup );
  Result := 1;
end;

function lua_being_unload(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  iState.Push( iBeing.ActionUnload( iState.ToObject(1) as TItem ) );
  Result := 1;
end;

function lua_being_path_find(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  if iState.IsNil(2) then begin iState.Push( false ); Exit(1); end;

  with iBeing do
  begin
    if FPath = nil then FPath := TPathfinder.Create( iBeing );
    FPathHazards := [];
    FPathClear   := [];
    iState.Push( FPath.Run( iBeing.FPosition, iState.ToPosition(2), iState.ToInteger(3), iState.ToInteger(4) ) );
    if FPath.Found then FPath.Start := FPath.Start.Child;
  end;
  Result := 1;
end;

function lua_being_path_next(L: Plua_State): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
    iMoveR  : TMoveResult;
    iSuccess: Boolean;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  with iBeing do
  begin
    if (FPath = nil) or (not FPath.Found)
      or (FPath.Start = nil) or (Distance( FPath.Start.Coord, iBeing.Position ) <> 1) then
      begin
        iState.Push( False );
        Exit(1);
      end;

    iMoveR := iBeing.TryMove( FPath.Start.Coord );

    if iMoveR in [ MoveBlock, MoveBeing ] then
    begin
      iState.Push( Byte(iMoveR) );
      iState.PushCoord( iBeing.LastMove );
      Exit(2);
    end;

    if iMoveR = MoveDoor then
    begin
      if BF_OPENDOORS in iBeing.FFlags then
      begin
        iSuccess := Boolean( TLevel(iBeing.Parent).CallHook( FPath.Start.Coord, iBeing, CellHook_OnAct ) );
        if not iSuccess then iMoveR := MoveBlock;
      end;
      iState.Push( Byte(iMoveR) );
      iState.PushCoord( iBeing.LastMove );
      Exit(2);
    end;

    iBeing.MoveTowards(FPath.Start.Coord);
    FPath.Start := FPath.Start.Child;
    iState.Push( Byte(iMoveR) );
    iState.PushCoord( iBeing.LastMove );
  end;
  Result := 2;
end;

function lua_being_inv_items_closure(L: Plua_State): Integer; cdecl;
var State     : TDRLLuaState;
    Parent    : TBeing;
    Next      : TItem;
    Current   : TItem;
    Filter    : Byte;
begin
  State.Init( L );
  Parent    := TObject( lua_touserdata( L, lua_upvalueindex(1) ) ) as TBeing;
  Next      := TObject( lua_touserdata( L, lua_upvalueindex(2) ) ) as TItem;
  Filter    := lua_tointeger( L, lua_upvalueindex(3) );

  repeat
    Current := Next as TItem;
    if Next <> nil then Next := Next.Next as TItem;
    if Next = Parent.Child then Next := nil;
  until (Current = nil) or
        (((Filter = 0) or (Byte(Current.iType) = Filter)) and
         ( not Parent.Inv.Equipped(Current) ));

  lua_pushlightuserdata( L, Next );
  lua_replace( L, lua_upvalueindex(2) );

  State.Push( Current );
  Exit( 1 );
end;

// iterator
function lua_being_inv_items(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  lua_pushlightuserdata( L, Being );
  lua_pushlightuserdata( L, Being.Child );
  if lua_isnumber( L, 2 )
    then lua_pushvalue( L, 2 )
    else lua_pushnumber( L, 0 );
  lua_pushcclosure( L, @lua_being_inv_items_closure, 3 );
  Exit( 1 );
end;

function lua_being_inv_size(L: Plua_State): Integer; cdecl;
var State   : TDRLLuaState;
    Being   : TBeing;
begin
  State.Init(L);
  Being := State.ToObject(1) as TBeing;
  State.Push( Being.Inv.Size );
  Exit( 1 );
end;

function lua_being_relocate(L: Plua_State): Integer; cdecl;
var State  : TDRLLuaState;
    Thing  : TThing;
    Target : TCoord2D;
begin
  State.Init(L);
  Thing := State.ToObject(1) as TThing;
  if State.IsNil(2) then Exit(0);
  Target := State.ToCoord(2);
  if GraphicsVersion then
    if Thing is TBeing then
      if Thing is TPlayer then
        IO.addScreenMoveAnimation(Distance(Thing.Position,Target)*10,Target);
  Thing.Displace(Target);
  Result := 0;
end;

function lua_being_set_overlay(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iBeing : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  if iState.IsNil(2) then
  begin
    iBeing.FSprite.OverColor := ColorBlack;
    Exclude( iBeing.FSprite.Flags, SF_OVERLAY );
  end
  else
  begin
    iBeing.FSprite.OverColor := NewColor( iState.ToVec4f(2) );
    Include( iBeing.FSprite.Flags, SF_OVERLAY );
  end;
  Result := 0;
end;

function lua_being_set_coscolor(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iBeing : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  if iState.IsNil(2) then
  begin
    iBeing.FSprite.Color := ColorBlack;
    Exclude( iBeing.FSprite.Flags, SF_COSPLAY );
  end
  else
  begin
    iBeing.FSprite.Color := NewColor( iState.ToVec4f(2) );
    Include( iBeing.FSprite.Flags, SF_COSPLAY );
  end;
  Result := 0;
end;

function lua_being_get_auto_target(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iBeing : TBeing;
    iAuto  : TAutoTarget;
    iRange : Integer;
    iCount : Integer;
begin
  iState.Init(L);
  iBeing := iState.ToObject( 1 ) as TBeing;
  if iBeing = nil then Exit( 0 );
  iRange := iState.ToInteger( 2, iBeing.Vision );
  iCount := iState.ToInteger( 3, 1 );
  Result := 0;
  iAuto := TAutoTarget.Create( iBeing.Position );
  TLevel(iBeing.Parent).UpdateAutoTarget( iAuto, iBeing, iRange );
  if iAuto.Current <> iBeing.Position then
  begin
    iBeing.FTargetPos := iAuto.Current;
    while iCount > 0 do
    begin
      if iAuto.Current = iBeing.Position then Break;
      iState.PushCoord( iAuto.Current );
      iAuto.Next;
      Inc( Result );
      Dec( iCount );
    end;
  end;
  FreeAndNil( iAuto );
end;

function lua_being_get_tohit(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iBeing : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject( 1 ) as TBeing;
  if iBeing = nil then Exit( 0 );
  iState.Push( iBeing.getToHit( iState.ToObjectOrNil( 3 ) as TItem, ALT_NONE, iState.ToBoolean( 2, False ) ) );
  Result := 1;
end;

function lua_being_get_todam(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iBeing : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject( 1 ) as TBeing;
  if iBeing = nil then Exit( 0 );
  iState.Push( iBeing.getToDam( iState.ToObjectOrNil( 3 ) as TItem, ALT_NONE, iState.ToBoolean( 2, False ) ) );
  Result := 1;
end;

function lua_being_wipe_marker( L: Plua_State ): Integer; cdecl;
var iState : TDRLLuaState;
    iBeing : TBeing;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  if iBeing = nil then Exit( 0 );
  if iState.IsCoord( 2 )
    then DRL.Level.Markers.Wipe( iBeing.uid, iState.ToCoord(2) )
    else DRL.Level.Markers.Wipe( iBeing.uid );
  Result := 0;
end;

function lua_being_set_marker( L: Plua_State ): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
    iCoord  : TCoord2D;
    iSprite : TSprite;
    iTable  : TLuaTable;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  if iBeing = nil then Exit( 0 );
  iCoord := iState.ToPosition( 2 );
  if not iState.IsTable( 3 ) then Exit( 0 );
  FillChar( iSprite, SizeOf( iSprite), 0 );
  Initialize( iSprite );
  iTable := iState.ToTable( 3 );
  try
    if ReadSprite( iTable, iSprite )
      then DRL.Level.Markers.Add( iCoord, iSprite, iBeing.UID )
      else iState.Error('bad sprite data passed to being:set_marker');
  finally
    FreeAndNil ( iTable );
  end;
end;

function lua_being_animate_bump( L: Plua_State ): Integer; cdecl;
var iState  : TDRLLuaState;
    iBeing  : TBeing;
    iCoord  : TCoord2D;
    iAmount : Single;
begin
  iState.Init(L);
  iBeing := iState.ToObject(1) as TBeing;
  if iBeing = nil then Exit( 0 );
  iCoord  := iState.ToPosition( 2 );
  iAmount := iState.ToFloat( 3, 0.5 );
  with iBeing do
    if DRL.Level.AnimationVisible( Position, iBeing ) then
    begin
      IO.addBumpAnimation( VisualTime( iState.ToInteger( 4, 1000 ) ) , 0, UID, Position, iCoord, Sprite, iAmount );
      if iBeing.IsPlayer then IO.WaitForAnimation;
    end;
end;


const lua_being_lib : array[0..35] of luaL_Reg = (
      ( name : 'new';           func : @lua_being_new),
      ( name : 'kill';          func : @lua_being_kill),
      ( name : 'resurrect';     func : @lua_being_resurrect),
      ( name : 'apply_damage';  func : @lua_being_apply_damage),
      ( name : 'get_name';      func : @lua_being_get_name),
      ( name : 'inv_items';     func : @lua_being_inv_items),
      ( name : 'get_eq_item';   func : @lua_being_get_eq_item),
      ( name : 'set_eq_item';   func : @lua_being_set_eq_item),
      ( name : 'add_inv_item';  func : @lua_being_add_inv_item),
      ( name : 'play_sound';    func : @lua_being_play_sound),
      ( name : 'get_total_resistance';func : @lua_being_get_total_resistance),

      ( name : 'quick_swap';    func : @lua_being_quick_swap),
      ( name : 'pickup';        func : @lua_being_pickup),
      ( name : 'unload';        func : @lua_being_unload),
      ( name : 'drop';          func : @lua_being_drop),
      ( name : 'use';           func : @lua_being_use),
      ( name : 'wear';          func : @lua_being_wear),
      ( name : 'attack';        func : @lua_being_attack),
      ( name : 'action_fire';   func : @lua_being_action_fire),
      ( name : 'reload';            func : @lua_being_reload),
      ( name : 'action_reload';     func : @lua_being_action_reload),
      ( name : 'action_alt_reload'; func : @lua_being_action_alt_reload),
      ( name : 'action_dual_reload';func : @lua_being_action_dual_reload),
      ( name : 'direct_seek';   func : @lua_being_direct_seek),
      ( name : 'relocate';      func : @lua_being_relocate),

      ( name : 'path_find';     func : @lua_being_path_find),
      ( name : 'path_next';     func : @lua_being_path_next),

      ( name : 'set_overlay';     func : @lua_being_set_overlay),
      ( name : 'set_coscolor';    func : @lua_being_set_coscolor),
      ( name : 'get_auto_target'; func : @lua_being_get_auto_target),
      ( name : 'get_tohit';       func : @lua_being_get_tohit),
      ( name : 'get_todam';       func : @lua_being_get_todam),

      ( name : 'set_marker';   func : @lua_being_set_marker),
      ( name : 'wipe_marker';  func : @lua_being_wipe_marker),

      ( name : 'animate_bump';  func : @lua_being_animate_bump),

      ( name : nil;             func : nil; )
);

class procedure TBeing.RegisterLuaAPI();
begin
  LuaSystem.Register( 'being', lua_being_lib );
end;

end.
