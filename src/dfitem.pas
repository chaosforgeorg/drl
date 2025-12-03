{$INCLUDE drl.inc}
{
----------------------------------------------------
DFITEM.PAS -- Items data and handling for DRL
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit dfitem;
interface
uses Classes, SysUtils, dfthing, dfdata, vrltools, vluatable, vcolor, math;

type

{ TItem }

TItem  = class( TThing )

    constructor Create( const anid : AnsiString; onFloor : boolean = False ); overload;
    constructor Create(anid : byte; onFloor : boolean = False); overload;
    constructor CreateFromStream( aStream: TStream ); override;
    procedure WriteToStream( aStream: TStream ); override;

    function    rollDamage : Integer;
    function    maxDamage : Integer;
    function    GetName( aKnown : boolean; aSingle : Boolean = False ) : Ansistring;
    function    GetExtName( aLyingHere : Boolean ) : Ansistring;
    function    GetProtection : Byte;
    function    GetResistance( const aResistance : AnsiString ) : Integer;
    function    Description( aSingle : Boolean ) : Ansistring; overload;
    function    Description : Ansistring; overload;
    function    DescriptionBox( aShort : Boolean = False ) : Ansistring;
    function    ResistDescriptionShort : AnsiString;
    function    GetAltFireName : AnsiString;
    function    GetAltReloadName : AnsiString;
    destructor  Destroy; override;
    function    eqSlot : TEqSlot;
    function    isStackable : Boolean;
    function    isUnloadable : Boolean;
    function    isMelee : Boolean;
    function    isRanged : Boolean;
    function    isWeapon : Boolean;
    function    isEqWeapon : Boolean;
    function    isTele : Boolean;
    function    isLever : Boolean;
    function    isPower : Boolean;
    function    isPack : Boolean;
    function    isUsable : Boolean;
    function    isAmmoPack : Boolean;
    function    isFeature : Boolean;
    function    isWearable : Boolean;
    function    isPickupable : Boolean;
    function    canFire : Boolean;
    function MenuColor : byte;
    procedure OnUpdate( Owner : TThing );
    function Preposition( const Item : AnsiString ) : string;
    class function Compare( a, b : TItem ) : Boolean; reintroduce;
    class procedure RegisterLuaAPI();
    private
    FNID      : Byte;
    FProps    : TItemProperties;
    FMods     : array[Ord('A')..Ord('Z')] of Byte;
    FAppear   : Integer;
    FAmount   : Integer;
    FMax      : Integer;
    procedure LuaLoad( aTable : TLuaTable; aOnFloor: boolean ); reintroduce;
    public
    property PGlowColor     : TColor         read FProps.PGlowColor      write FProps.PGlowColor;
    property PCosColor      : TColor         read FProps.PCosColor       write FProps.PCosColor;
    property HitSprite      : TSprite        read FProps.HitSprite;
    property MisSprite      : TSprite        read FProps.MisSprite;
    property Explosion      : TExplosionData read FProps.Explosion;
    published
    property Max            : Integer     read FMax;
    property Amount         : Integer     read FAmount                write FAmount;
    property NID            : Byte        read FNID;
    property MissBase       : Byte        read FProps.MissBase        write FProps.MissBase;
    property MissDist       : Byte        read FProps.MissDist        write FProps.MissDist;
    property IType          : TItemType   read FProps.IType          write FProps.IType;
    property Durability     : Word        read FProps.Durability     write FProps.Durability;
    property MaxDurability  : Word        read FProps.MaxDurability  write FProps.MaxDurability;
    property MoveMod        : Integer     read FProps.MoveMod        write FProps.MoveMod;
    property DodgeMod       : Integer     read FProps.DodgeMod       write FProps.DodgeMod;
    property KnockMod       : Integer     read FProps.KnockMod       write FProps.KnockMod;
    property SpriteMod      : Integer     read FProps.SpriteMod      write FProps.SpriteMod;
    property AmmoID         : Byte        read FProps.AmmoID         write FProps.AmmoID;
    property Ammo           : Word        read FProps.Ammo           write FProps.Ammo;
    property AmmoMax        : Word        read FProps.AmmoMax        write FProps.AmmoMax;
    property Acc            : Integer     read FProps.Acc            write FProps.Acc;
    property Damage_Dice    : Word        read FProps.Damage.Amount  write FProps.Damage.Amount;
    property Damage_Sides   : Word        read FProps.Damage.Sides   write FProps.Damage.Sides;
    property Damage_Add     : Integer     read FProps.Damage.Bonus   write FProps.Damage.Bonus;
    property Range          : Byte        read FProps.Range          write FProps.Range;
    property Spread         : Byte        read FProps.Spread         write FProps.Spread;
    property Falloff        : Integer     read FProps.Falloff        write FProps.Falloff;
    property Knockback      : Integer     read FProps.Knockback      write FProps.Knockback;
    property Radius         : Byte        read FProps.Radius         write FProps.Radius;
    property Shots          : Byte        read FProps.Shots          write FProps.Shots;
    property ShotCost       : Byte        read FProps.ShotCost       write FProps.ShotCost;
    property ReloadTime     : Byte        read FProps.ReloadTime     write FProps.ReloadTime;
    property UseTime        : Byte        read FProps.UseTime        write FProps.UseTime;
    property SwapTime       : Byte        read FProps.SwapTime       write FProps.SwapTime;
    property DamageType     : TDamageType read FProps.DamageType     write FProps.DamageType;
    property AltFire        : TAltFire    read FProps.AltFire        write FProps.AltFire;
    property AltReload      : TAltReload  read FProps.AltReload      write FProps.AltReload;
    property MisASCII       : Char        read FProps.MisASCII       write FProps.MisAscii;
    property MisColor       : Byte        read FProps.MisColor       write FProps.MisColor;
    property MisDelay       : Byte        read FProps.MisDelay       write FProps.MisDelay;
    property Appear         : Integer     read FAppear               write FAppear;
    property Desc           : AnsiString  read Description;
  end;

procedure SwapItem(var a, b: TItem);

implementation

uses vnode, drlua, vluasystem, vluaentitynode, vutil, vdebug, dfbeing, drlbase, vmath, drlhooks;

procedure SwapItem(var a, b: TItem);
var c : TItem;
begin
  c := a;
  a := b;
  b := c;
end;

class function TItem.Compare(a, b: TItem): Boolean;
begin
  if a = nil then Exit(True);
  if b = nil then Exit(False);
  if a.FProps.IType > b.FProps.IType then Exit(True);
  if a.FProps.IType < b.FProps.IType then Exit(False);
  Exit(a.NID > b.NID);
end;

function TItem.eqSlot : TEqSlot;
begin
  case FProps.IType of
    ITEMTYPE_ARMOR    : Exit(efTorso);
    ITEMTYPE_MELEE    : Exit(efWeapon);
    ITEMTYPE_RANGED   : Exit(efWeapon);
    ITEMTYPE_NRANGED  : Exit(efWeapon);
    ITEMTYPE_BOOTS    : Exit(efBoots);
    ITEMTYPE_AMMOPACK : Exit(efWeapon2);
  end;
  raise EItemException.CreateFmt('eqSlot -- unsupported IType: %d',[ Byte( FProps.Itype ) ]);
end;

constructor TItem.Create(anid : byte; onFloor : boolean);
var Table : TLuaTable;
begin
  inherited Create( LuaSystem.Get( ['items',anid,'id'] ) );
  FEntityID := ENTITY_ITEM;
  if aNID = 0 then raise EItemException.Create('Bad item (ID#0) passed to Create!');

  Table := LuaSystem.GetTable( ['items',anid ] );
  LuaLoad( Table, onFloor );
  FreeAndNil( Table );
end;

constructor TItem.Create( const anid : AnsiString; onFloor: boolean);
var Table : TLuaTable;
begin
  inherited Create( anid );
  FEntityID := ENTITY_ITEM;
  if anid = '' then raise EItemException.Create('Bad item id!');

  Table := LuaSystem.GetTable( ['items',anid] );
  LuaLoad( Table, onFloor );
  FreeAndNil( Table );
end;

constructor TItem.CreateFromStream ( aStream : TStream ) ;
var i, iCount : Word;
begin
  inherited CreateFromStream ( aStream ) ;

  aStream.Read( FMods,     SizeOf( FMods ) );
  aStream.Read( FProps,    SizeOf( FProps ) );
  aStream.Read( FAppear,   SizeOf( FAppear ) );
  aStream.Read( FMax,      SizeOf( FMax ) );
  aStream.Read( FAmount,   SizeOf( FAmount ) );

  FNID   := aStream.ReadByte();
  iCount := aStream.ReadWord();
  if iCount = 0 then Exit;
  for i := 1 to iCount do
    Add( TItem.CreateFromStream( aStream ) );
end;

procedure TItem.WriteToStream ( aStream : TStream ) ;
var iNode : TNode;
begin
  inherited WriteToStream ( aStream ) ;

  aStream.Write( FMods,     SizeOf( FMods ) );
  aStream.Write( FProps,    SizeOf( FProps ) );
  aStream.Write( FAppear,   SizeOf( FAppear ) );
  aStream.Write( FMax,      SizeOf( FMax ) );
  aStream.Write( FAmount,   SizeOf( FAmount ) );

  aStream.WriteByte( FNID );

  aStream.WriteWord( ChildCount );
  if ChildCount = 0 then Exit;

  for iNode in Self do
     if iNode is TItem then
       iNode.WriteToStream( aStream );
end;

procedure TItem.LuaLoad( aTable : TLuaTable; aOnFloor: boolean );
var i : Byte;
begin
  inherited LuaLoad( aTable );
  FHooks := FHooks * ItemHooks;

  FProps.itype := TItemType( aTable.getInteger('type') );

  for i := Ord('A') to Ord('Z') do FMods[i] := 0;

  FAppear          := 0;
  FNID             := aTable.getInteger('nid');
  FMax             := aTable.getInteger('max');
  FAmount          := aTable.getInteger('amount');

  FProps.MoveMod   := aTable.getInteger( 'movemod', 0 );
  FProps.DodgeMod  := aTable.getInteger( 'dodgemod', 0 );
  FProps.KnockMod  := aTable.getInteger( 'knockmod', 0 );

  FProps.Durability    := aTable.getInteger('durability',0);
  FProps.MaxDurability := FProps.Durability;
  FProps.SpriteMod     := aTable.GetInteger('spritemod',0);

  FProps.Ammo     := aTable.getInteger('ammo',0);
  FProps.AmmoMax  := aTable.getInteger('ammomax',0);
  FProps.AmmoID   := aTable.getInteger('ammo_id',0);
  if Ammo = 0 then FProps.Ammo := FProps.AmmoMax;

  FProps.Damage     := NewDiceRoll( aTable.getInteger('damage_dice',0), aTable.getInteger('damage_sides',0), aTable.getInteger('damage_bonus',0) );
  FProps.DamageType := TDamageType( aTable.getInteger('damagetype',0) );

  FProps.Acc         := aTable.getInteger('acc',0);
  FProps.UseTime     := aTable.getInteger('usetime',10);
  FProps.SwapTime    := aTable.getInteger('swaptime',10);
  FProps.ReloadTime  := aTable.getInteger('reloadtime',10);
  FProps.AltFire     := TAltFire( aTable.getInteger('altfire',0) );

  FProps.Radius      := aTable.getInteger('radius',0);
  FProps.Range       := aTable.getInteger('range',0);
  FProps.Shots       := aTable.getInteger('shots',0);
  FProps.ShotCost    := aTable.getInteger('shotcost',0);
  FProps.Spread      := aTable.getInteger('spread',0);
  FProps.Falloff     := aTable.GetInteger('falloff',0);
  FProps.Knockback   := aTable.GetInteger('knockback',0);

  FProps.MisASCII    := aTable.getChar('misascii','-');
  FProps.MisColor    := aTable.getInteger('miscolor',0);
  FProps.MisDelay    := aTable.getInteger('misdelay',0);
  FProps.MissBase    := aTable.getInteger('miss_base',0);
  FProps.MissDist    := aTable.getInteger('miss_dist',0);

  FProps.AltFire     := TAltFire( aTable.getInteger('altfire',0) );
  FProps.AltReload   := TAltReload( aTable.getInteger('altreload',0) );

  FProps.PCosColor := ColorZero;
  FProps.PGlowColor := ColorZero;
  if not aTable.isNil( 'pcoscolor' ) then FProps.PCosColor  := NewColor( aTable.GetVec4f('pcoscolor' ) );
  if not aTable.isNil( 'pglow' )     then FProps.PGlowColor := NewColor( aTable.GetVec4f('pglow' ) );

  ReadSprite( aTable, 'missprite', FProps.MisSprite );
  ReadSprite( aTable, 'hitsprite', FProps.HitSprite );
  ReadExplosion( aTable, 'explosion', FProps.Explosion );


  if aOnFloor and ( FProps.IType = ITEMTYPE_AMMO ) then
    FAmount := Round( FAmount * Double(LuaSystem.Get([ 'diff', DRL.Difficulty, 'ammofactor' ])) );

  CallHook( Hook_OnCreate, [] );
end;

function TItem.MenuColor: byte;
begin
  if not Option_ColoredInventory then Exit(LightGray);
  if Color = white then Exit(LightGray) else Exit(Color);
end;

function    TItem.rollDamage : Integer;
begin
  if isWeapon then Exit(FProps.Damage.Roll);
  raise EItemException.CreateFmt('TItem.Damage called for Itype %d!',[ Byte( FProps.Itype ) ] );
end;

function TItem.maxDamage: Integer;
begin
  if isWeapon then Exit(FProps.Damage.Max);
  raise EItemException.CreateFmt('TItem.MaxDamage called for Itype %d!',[ Byte( FProps.Itype ) ] );
end;

function    TItem.GetProtection : Byte;
begin
  if FArmor = 0 then Exit(0);
  if Flags[ IF_NODEGRADE ] then Exit(FArmor);
  if (FProps.IType in [ITEMTYPE_ARMOR,ITEMTYPE_BOOTS]) then
    case FProps.Durability of
      0         : GetProtection := 0;
      1  .. 25  : GetProtection := math.Max( FArmor div 4, 1 );
      26 .. 49  : GetProtection := math.Max( FArmor div 2, 1 );
      50 ..1000 : GetProtection := FArmor;
    end
  else Exit(FArmor);
end;

function    TItem.GetResistance ( const aResistance : AnsiString ): Integer;
var iResist : LongInt;
begin
  iResist := GetLuaProperty( ['resist',aResistance], 0 );
  if iResist <= 0 then Exit(iResist);
  if Flags[ IF_NODEGRADE ] then Exit(iResist);
  if (FProps.IType in [ITEMTYPE_ARMOR,ITEMTYPE_BOOTS]) then
    case FProps.Durability of
      0         : GetResistance := 0;
      1  .. 25  : GetResistance := Ceil( math.Max( iResist div 4, 1 ) );
      26 .. 49  : GetResistance := Ceil( math.Max( iResist div 2, 1 ) );
      50 ..1000 : GetResistance := iResist;
    end
  else Exit(iResist);
end;

function TItem.Description : Ansistring;
begin
  Exit( Description( False ) );
end;

function TItem.Description( aSingle : Boolean ) : Ansistring;
var FlagStr : string[10];
    Count   : Byte;
begin
  Description := Name;
  case FProps.IType of
    ITEMTYPE_LEVER,
    ITEMTYPE_TELE,
    ITEMTYPE_FEATURE  : Exit(Description);
    ITEMTYPE_AMMOPACK : Description += ' (x'+IntToStr(FProps.Ammo)+')';
    ITEMTYPE_MELEE :
    begin
      Description += ' ('+FProps.Damage.toString+')';
      FlagStr := '';
      if IF_MODIFIED in FFlags then
      for Count := Ord('A') to Ord('Z') do
        if FMods[Count] > 0 then FlagStr += Chr(Count);
      if FArmor <> 0 then Description += ' ['+IntToStr(FArmor)+']';
      if FlagStr <> '' then Description += ' ('+FlagStr+')';
      Description += ResistDescriptionShort;
    end;
    ITEMTYPE_ARMOR, ITEMTYPE_BOOTS :
      begin
        if IF_NODURABILITY in FFlags then
          Description += ' ['+IntToStr(GetProtection)+']'
        else
          Description += ' ['+IntToStr(GetProtection)+'/'+IntToStr(FArmor)+'] ('+IntToStr(FProps.Durability)+'%)';
        FlagStr := '';
        if IF_MODIFIED in FFlags then
        for Count := Ord('A') to Ord('Z') do
          if FMods[Count] > 0 then FlagStr += Chr(Count);
        if FlagStr <> '' then Description += ' ('+FlagStr+')';
        //Description += ResistDescriptionShort;
      end;
    ITEMTYPE_RANGED, ITEMTYPE_NRANGED : begin
            Description += ' ('+FProps.Damage.toString+')';
            if FProps.Shots <> 0 then Description += 'x' +IntToStr(FProps.Shots);
            if not ( IF_NOAMMO in FFlags ) then Description += ' ['+IntToStr(FProps.Ammo)+'/'+IntToStr(FProps.AmmoMax)+']';
            if FArmor <> 0 then Description += ' ['+IntToStr(FArmor)+']';
            if IF_MODIFIED in FFlags then
            begin
              FlagStr := '';
              for Count := Ord('A') to Ord('Z') do
              if FMods[Count] > 0 then
                FlagStr += Chr(Count) + Iif( FMods[Count] > 1, IntToStr(FMods[Count]), '' );
              if FlagStr <> '' then Description += ' ('+FlagStr+')';
            end;
            Description += ResistDescriptionShort;
          end;
    ITEMTYPE_URANGED: begin
        if FProps.Damage.max > 0 then
          Description += ' ('+FProps.Damage.toString+')';
      end;
  end;
  if ( FMax > 1 ) and ( not aSingle ) then Description += ' (x'+IntToStr(FAmount)+')';
end;

function TItem.GetAltFireName : AnsiString;
begin
  GetAltFireName := LuaSystem.Get([ 'items', ID, 'altfirename' ], '');
  if GetAltFireName <> '' then Exit;
  case FProps.AltFire of
    ALT_CHAIN     : Exit('chain fire');
    ALT_THROW     : Exit('throw');
    ALT_AIMED     : Exit('aimed');
    ALT_SINGLE    : Exit('single');
  end;
end;

function TItem.GetAltReloadName : AnsiString;
begin
  GetAltReloadName := LuaSystem.Get([ 'items', ID, 'altreloadname' ], '');
end;

function TItem.DescriptionBox( aShort : Boolean = False ): Ansistring;
begin
  DescriptionBox := '';
  case FProps.IType of
    ITEMTYPE_ARMOR, ITEMTYPE_BOOTS : DescriptionBox :=
      'Durability  : {!'+IntToStr(FProps.MaxDurability)+'}'#10+
      IIf(FProps.SwapTime  <> 10, 'Swap time   : {!'+Seconds(FProps.SwapTime)+'}'#10);
    ITEMTYPE_URANGED : DescriptionBox :=
      'Damage type : {!'+DamageTypeName(FProps.DamageType)+'}'#10+
      IIf(FProps.Radius <> 0,'Expl.radius : {!'+IntToStr(FProps.Radius)+'}'#10);
    ITEMTYPE_RANGED, ITEMTYPE_NRANGED : DescriptionBox :=
      IIf(FProps.UseTime  <> 10, 'Fire time   : {!'+Seconds(FProps.UseTime)+'}'#10)+
      IIf(FProps.ReloadTime > 0, 'Reload time : {!'+Seconds(FProps.ReloadTime)+'}'#10)+
      IIf(FProps.SwapTime <> 10, 'Swap time   : {!'+Seconds(FProps.SwapTime)+'}'#10)+
      IIf(FProps.Acc       <> 0, 'Accuracy    : {!'+BonusStr(FProps.Acc)+'}'#10)+
      'Damage type : {!'+DamageTypeName(FProps.DamageType)+'}'#10+
      IIf(FProps.Shots    <> 0,'Shots       : {!'+IntToStr(FProps.Shots)+'}'#10)+
      IIf(FProps.ShotCost <> 0,'Shot cost   : {!'+IntToStr(FProps.ShotCost)+'}'#10)+
      IIf(FProps.Radius   <> 0,'Expl.radius : {!'+IntToStr(FProps.Radius)+'}'#10)+
      IIf(FProps.Falloff  <> 0,'Dmg. falloff: {!'+IntToStr(FProps.Falloff)+'%}'#10)+
      IIf(FProps.Spread   <> 0,'Cone size   : {!'+IntToStr(FProps.Spread)+'}'#10)+
      IIf(FProps.Range    <> 0,'Max range   : {!'+IntToStr(FProps.Range)+'}'#10)+
      IIf((not aShort) and (FProps.AltFire   <> ALT_NONE   ),'Alt. fire   : {!'+GetAltFireName+'}'#10)+
      IIf((not aShort) and (FProps.AltReload <> RELOAD_NONE),'Alt. reload : {!'+GetAltReloadName+'}'#10);
    ITEMTYPE_MELEE : DescriptionBox :=
      IIf(FProps.UseTime <> 10, 'Attack time : {!'+Seconds(FProps.UseTime)+'}'#10)+
      IIf(FProps.SwapTime<> 10, 'Swap time   : {!'+Seconds(FProps.SwapTime)+'}'#10)+
      IIf(FProps.Acc     <> 0,  'Accuracy    : {!' + BonusStr(FProps.Acc)+'}'#10)+
      'Damage type : {!'+DamageTypeName(FProps.DamageType)+'}'#10+
      IIf((not aShort) and (FProps.AltFire <> ALT_NONE),'Alt. fire   : {!'+GetAltFireName+'}'#10);
  end;
  DescriptionBox +=
    IIf(FProps.MoveMod  <> 0,'Move speed  : {!'+Percent(FProps.MoveMod)+'}'#10)+
    IIf(FProps.KnockMod <> 0,'Knockback   : {!'+Percent(FProps.KnockMod)+'}'#10)+
    IIf(FProps.DodgeMod <> 0,'Dodge rate  : {!'+Percent(FProps.DodgeMod)+'}'#10);

  DescriptionBox +=
      IIf(GetResistance('bullet')   <> 0,'Bullet res. : {!' + BonusStr(GetResistance('bullet'))+'}'#10)+
      IIf(GetResistance('melee')    <> 0,'Melee res.  : {!' + BonusStr(GetResistance('melee'))+'}'#10)+
      IIf(GetResistance('shrapnel') <> 0,'Shrapnel res: {!' + BonusStr(GetResistance('shrapnel'))+'}'#10)+
      IIf(GetResistance('acid')     <> 0,'Acid res.   : {!' + BonusStr(GetResistance('acid'))+'}'#10)+
      IIf(GetResistance('fire')     <> 0,'Fire res.   : {!' + BonusStr(GetResistance('fire'))+'}'#10)+
      IIf(GetResistance('plasma')   <> 0,'Plasma res. : {!' + BonusStr(GetResistance('plasma'))+'}'#10)+
      IIf(GetResistance('cold')     <> 0,'Cold res.   : {!' + BonusStr(GetResistance('cold'))+'}'#10)+
      IIf(GetResistance('poison')   <> 0,'Poison res. : {!' + BonusStr(GetResistance('poison'))+'}'#10);
end;

function TItem.ResistDescriptionShort: AnsiString;
const ResLetter : array[Low(TResistance)..High(TResistance)] of Char = ( 'b','m','s','a','f','p','c','o' );
const ResID   : array[Low(TResistance)..High(TResistance)] of AnsiString =
   ( 'bullet', 'melee', 'shrapnel', 'acid', 'fire', 'plasma', 'cold', 'poison' );
var Resistance : TResistance;
    iValue : LongInt;
begin
  ResistDescriptionShort := '';
  for Resistance := Low( TResistance ) to High( TResistance ) do
  begin
    iValue := GetResistance( ResID[ Resistance ] );
    if iValue > 0 then
      ResistDescriptionShort += ResLetter[ Resistance ]
    else if iValue < 0 then
      ResistDescriptionShort += '-'+ResLetter[ Resistance ];
  end;
  if ResistDescriptionShort = '' then Exit('') else Exit(' {'+ResistDescriptionShort+'}')
end;

function TItem.Preposition( const Item : AnsiString ) : string;
begin
  if IF_PLURALNAME in FFlags then Exit('');
  Case Item[1] of
    'a','e','i','o','u' : Exit('an ');
  end;
  Exit('a ');
end;

function    TItem.GetName( aKnown : boolean; aSingle : Boolean = False ) : Ansistring;
begin
  if FAmount > 1 then Exit( Description( aSingle ) );
  if Flags[ IF_UNIQUENAME ] then Exit( Description( aSingle ) );
  if aKnown then Exit('the '+Description( aSingle ))
            else Exit(Preposition(Description( aSingle ))+Description( aSingle ));
end;

function TItem.GetExtName( aLyingHere : Boolean ) : Ansistring;
var iName : AnsiString;
begin
  iName := '';
  if Hook_OnDescribe in FHooks then
  begin
    iName := LuaSystem.ProtectedRunHook( Self, HookNames[Hook_OnDescribe], [] );
  end;
  if iName = '' then iName := GetName( False );

  if not aLyingHere then Exit( iName );

  if Flags[ IF_FEATURENAME ] then Exit( Format('There is a %s here.', [ iName ] ) );
  if Flags[ IF_PLURALNAME ]  then Exit( Format('There are %s lying here.', [ iName ] ) );
  Exit( Format('There is %s lying here.', [ iName ] ) );
end;

destructor  TItem.Destroy;
begin
  inherited Destroy;
end;

function TItem.isStackable : boolean;
begin
  Exit(FMax > 1);
end;

function TItem.isUnloadable : boolean;
begin
  Exit(FProps.IType in [ITEMTYPE_RANGED,ITEMTYPE_AMMOPACK]);
end;

function TItem.isMelee : boolean;
begin
  Exit(FProps.IType = ITEMTYPE_MELEE);
end;

function TItem.isRanged : boolean;
begin
  Exit(FProps.IType in [ITEMTYPE_RANGED,ITEMTYPE_NRANGED,ITEMTYPE_URANGED]);
end;

function TItem.isWeapon : boolean;
begin
  Exit(isRanged or isMelee);
end;

function TItem.isEqWeapon : boolean;
begin
  Exit(FProps.IType in [ITEMTYPE_RANGED,ITEMTYPE_NRANGED,ITEMTYPE_MELEE]);
end;

function TItem.isTele : boolean;
begin
  Exit(FProps.IType = ITEMTYPE_TELE);
end;

function TItem.isLever : boolean;
begin
  Exit(FProps.IType = ITEMTYPE_LEVER);
end;

function TItem.isPower : boolean;
begin
  Exit(FProps.IType = ITEMTYPE_POWER);
end;

function TItem.isPack : boolean;
begin
  Exit(FProps.IType = ITEMTYPE_PACK);
end;

function TItem.isUsable : boolean;
begin
  Exit(FProps.IType in [ITEMTYPE_PACK, ITEMTYPE_URANGED]);
end;

function TItem.isAmmoPack : boolean;
begin
  Exit(FProps.IType = ITEMTYPE_AMMOPACK);
end;

function TItem.isFeature : Boolean;
begin
  Exit(FProps.IType = ITEMTYPE_FEATURE);
end;

function TItem.isWearable : boolean;
begin
  Exit(FProps.IType in [ITEMTYPE_RANGED,ITEMTYPE_NRANGED,ITEMTYPE_ARMOR,ITEMTYPE_MELEE,ITEMTYPE_BOOTS,ITEMTYPE_AMMOPACK]);
end;

function TItem.isPickupable : Boolean;
begin
  Exit( not ( FProps.IType in [ ITEMTYPE_FEATURE, ITEMTYPE_TELE, ITEMTYPE_LEVER ] ) );
end;

function TItem.canFire: boolean;
begin
  if not isRanged then Exit( False );
  if not Flags[ IF_NOAMMO ] then
  begin
    if Ammo = 0        then Exit( False );
    if Ammo < ShotCost then Exit( False );
  end;
  Exit( True );
end;

procedure TItem.OnUpdate( Owner : TThing );
begin 
  if ( Hook_OnEquipTick in FHooks ) or ( ( FPerks <> nil ) and ( Hook_OnEquipTick in FPerks.Hooks ) ) then
    CallHook( Hook_OnEquipTick, [ Owner ] );
end;

function lua_item_new(L: Plua_State): Integer; cdecl;
var State : TDRLLuaState;
    Item  : TItem;
begin
  State.Init(L);
  Item := TItem.Create( State.ToId( 1 ), State.ToBoolean( 2 ) );
  State.Push(Item);
  Result := 1;
end;

function lua_item_get_mod(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iItem  : TItem;
begin
  iState.Init(L);
  iItem := iState.ToObject(1) as TItem;
  iState.Push( iItem.FMods[ Ord(iState.ToChar(2))]);
  Result := 1;
end;

function lua_item_set_mod(L: Plua_State): Integer; cdecl;
var iState : TDRLLuaState;
    iItem  : TItem;
begin
  iState.Init(L);
  iItem := iState.ToObject(1) as TItem;
  iItem.FMods[ Ord(iState.ToChar(2))] := iState.ToInteger(3);
  Result := 0;
end;

function lua_item_set_sprite(L: Plua_State): Integer; cdecl;
var iState   : TDRLLuaState;
    iItem    : TItem;
    iType    : Ansistring;
    iPSprite : ^TSprite;
    iTable   : TLuaTable;
begin
  iState.Init(L);
  iItem := iState.ToObject(1) as TItem;
  if iItem = nil then Exit(0);
  iType := iState.ToString(2);
  iPSprite := nil;
  if iType = 'spr' then
    iPSprite := @iItem.FSprite
  else if iType = 'mis' then
    iPSprite := @iItem.FProps.MisSprite
  else if iType = 'hit' then
    iPSprite := @iItem.FProps.HitSprite
  else if iType = 'exp' then
    iPSprite := @iItem.FProps.Explosion.Sprite;
  if iPSprite = nil then
  begin
    iState.Error('sprite type expected as parameter #1!');
    Exit( 0 );
  end;
  iTable := iState.ToTable(3);
  if iTable = nil then Exit( 0 );
  FillChar( iPSprite^, SizeOf( TSprite ), 0 );
  ReadSprite( iTable, iPSprite^ );
  FreeAndNil( iTable );
  Result := 0;
end;

function lua_item_set_explosion(L: Plua_State): Integer; cdecl;
var iState   : TDRLLuaState;
    iItem    : TItem;
    iTable   : TLuaTable;
begin
  iState.Init(L);
  iItem := iState.ToObject(1) as TItem;
  if iItem = nil then Exit(0);
  iTable := iState.ToTable(2);
  if iTable = nil then Exit( 0 );
  FillChar( iItem.FProps.Explosion, SizeOf( TExplosionData ), 0 );
  ReadExplosion( iTable, iItem.FProps.Explosion );
  FreeAndNil( iTable );
  Result := 0;
end;

function lua_item_set_sound_id(L: Plua_State): Integer; cdecl;
var iState   : TDRLLuaState;
    iItem    : TItem;
begin
  iState.Init(L);
  iItem := iState.ToObject(1) as TItem;
  if iItem = nil then Exit(0);
  iItem.SoundID := iState.ToString( 2 );
  Result := 0;
end;

const lua_item_lib : array[0..6] of luaL_Reg = (
      ( name : 'new';           func : @lua_item_new),
      ( name : 'get_mod';       func : @lua_item_get_mod),
      ( name : 'set_mod';       func : @lua_item_set_mod),
      ( name : 'set_sprite';    func : @lua_item_set_sprite),
      ( name : 'set_explosion'; func : @lua_item_set_explosion),
      ( name : 'set_sound_id';  func : @lua_item_set_sound_id),
      ( name : nil;             func : nil; )
);

class procedure TItem.RegisterLuaAPI();
begin
  LuaSystem.Register( 'item', lua_item_lib );
end;

end.
