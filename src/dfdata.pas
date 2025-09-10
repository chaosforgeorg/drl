{$INCLUDE drl.inc}
{
----------------------------------------------------
DFDATA.PAS -- Data for DRL
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit dfdata;
interface
uses Classes, SysUtils, idea,
     vgenerics, vcolor, vutil, vrltools, vtigstyle, vluatable, vioevent, vvector,
     drlconfig, drlkeybindings;

const CoreModuleID      : AnsiString = '';
      ConfigurationPath : AnsiString = 'config.lua';
      ModuleUserPath    : AnsiString = '';
      DataPath          : AnsiString = '';
      WritePath         : AnsiString = '';
      ScorePath         : AnsiString = '';
      SettingsPath      : AnsiString = 'settings.lua';

      VersionModule     : Ansistring = '';
      VersionModuleSave : Ansistring = '';
      SaveVersionModule : Ansistring = '';
      SaveModString     : Ansistring = '';


{$INCLUDE version.inc}

var   MemorialWritten : Boolean;

const PlayerSafeZone = 6;

type
  TIntHashMap   = specialize TGHashMap<Integer>;
  TStringGArray = specialize TGArray<AnsiString>;


type
  // Error reporting.
  EZlibError          = class(EStreamError);
  EDunGenException    = class(EException);
  EItemException      = class(EException);

type TPageArray = specialize TGObjectArray< TStringGArray >;

type TPagedReport = class
  constructor Create( aTitle : Ansistring; aStyled : Boolean );
  function Add( aTitle : Ansistring; aHeader : Ansistring = '' ) : TStringGArray;
  procedure Add( aPage : TStringGArray; aTitle : Ansistring; aHeader : Ansistring = '' );
  destructor Destroy; override;
protected
  FPages   : TPageArray;
  FTitles  : TStringGArray;
  FHeaders : TStringGArray;
  FTitle   : AnsiString;
  FStyled  : Boolean;
public
  property Pages   : TPageArray    read FPages;
  property Titles  : TStringGArray read FTitles;
  property Headers : TStringGArray read FHeaders;
  property Title   : AnsiString    read FTitle;
  property Styled  : Boolean       read FStyled;
end;

type TMenuResult = class
  Quit       : Boolean;
  Loaded     : Boolean;
  ArchAngel  : Boolean;
  Challenge  : AnsiString;
  SChallenge : AnsiString;
  Difficulty : Byte;
  Klass      : Byte;
  Trait      : Byte;
  Name       : AnsiString;

  constructor Create;
  procedure Reset;
end;

type THOFRankEntry = record
  ID    : Ansistring;
  Value : Integer;
end;

type THOFRank = record
  Data : array of THOFRankEntry;
end;

const
  DEBUG           : Boolean = False;
  CRASHMODE       : Boolean = False;
  EXCEPTEMMITED   : Boolean = False;
  DemoVersion     : Boolean = False;
  ForceShop       : Boolean = False;
  GraphicsVersion : Boolean = True;
  SoundVersion    : Boolean = True;
  ForceNoAudio    : Boolean = False;
  ForceConsole    : Boolean = False;
  ForceGraphics   : Boolean = False;
  ForceWindowed   : Boolean = False;
  ModdedGame      : Boolean = False;
  ForceRestart    : Ansistring = '';
  ModErrors       : TStringGArray = nil;
  VisionBaseValue : Byte = 8;

  ThisSeed       : Cardinal = 0;

  NoPlayerRecord : Boolean = False;
  NoScoreRecord  : Boolean = False;

  GodMode      : Boolean = False;

  GameRealTime    : Comp = 0;
  ProgramRealTime : Comp = 0;

  Config       : TDRLConfig = nil;

const
  AnimationSpeedMove   = 125;
  AnimationSpeedPush   = 200;
  AnimationSpeedAttack = 100;

type
    TItemType       = ( ItemType_None, ItemType_Ranged, ItemType_NRanged, ItemType_URanged, ItemType_Armor, ItemType_Melee, ItemType_Ammo, ItemType_Pack, ItemType_Power, ItemType_Boots, ItemType_Tele, ItemType_Lever, ItemType_Feature, ItemType_AmmoPack );
    TBodyTarget     = ( Target_Internal, Target_Torso, Target_Feet );
    TEqSlot         = ( efTorso, efWeapon, efBoots, efWeapon2 );
    TStatusEffect   = ( StatusNormal, StatusInvert, StatusRed, StatusGreen, StatusBlue, StatusCyan, StatusMagenta, StatusYellow, StatusGray, StatusWhite );
    TDamageType     = ( Damage_Bullet, Damage_Melee, Damage_Pierce, Damage_Sharpnel, Damage_Acid, Damage_Fire, Damage_Cold, Damage_Poison, Damage_Plasma, Damage_SPlasma, Damage_IgnoreArmor );
    TAltFire        = ( ALT_NONE, ALT_CHAIN, ALT_THROW, ALT_SCRIPT, ALT_TARGETSCRIPT, ALT_AIMED, ALT_SINGLE );
    TAltReload      = ( RELOAD_NONE, RELOAD_SCRIPT, RELOAD_DUAL, RELOAD_SINGLE );
    TExplosionFlag  = ( efSelfHalf, efSelfKnockback, efSelfSafe, efAfterBlink, efChain, efRandomContent, efNoDistanceDrop, efAlwaysVisible );
    TResistance     = ( Resist_Bullet, Resist_Melee, Resist_Shrapnel, Resist_Acid, Resist_Fire, Resist_Plasma, Resist_Cold, Resist_Poison );

const
    ResNames : array[TResistance] of AnsiString = ('Bullet','Melee','Shrap','Acid','Fire','Plasma','Cold','Poison');
    ResIDs   : array[TResistance] of AnsiString = ('bullet','melee','shrapnel','acid','fire','plasma','cold','poison');


const
   PadQSlotChar : array[1..4] of Char = ( '^','<','>','v' );

const
{$include ../bin/data/core/constants.lua}
{$include ../bin/dkey.inc}

const
  COMMAND_NONE     = 0;
  COMMAND_SKIP     = 250;

const
  Setting_AlwaysRandomName : Boolean = False;
  Setting_NoIntro          : Boolean = False;
  Setting_RunOverItems     : Boolean = False;
  Setting_HideHints        : Boolean = False;
  Setting_EmptyConfirm     : Boolean = False;
  Setting_UnlockAll        : Boolean = False;
  Setting_MenuSound        : Boolean = False;
  Setting_MouseEdgePan     : Boolean = False;
  Setting_Mouse            : Boolean = True;
  Setting_GamepadRumble    : Boolean = True;
  Setting_Flash            : Boolean = True;
  Setting_Glow             : Boolean = True;
  Setting_Fade             : Boolean = True;
  Setting_ScreenShake      : Boolean = True;
  Setting_BloodPulse       : Boolean = True;
  Setting_ItemDropAnimation: Boolean = True;
  Setting_AutoTarget       : Boolean = True;
  Setting_GroupMessages    : Boolean = True;
  Setting_MusicVolume      : Byte = 25;
  Setting_SoundVolume      : Byte = 25;

const
  Option_HighASCII        : Boolean = {$IFDEF WINDOWS}True{$ELSE}False{$ENDIF};
  Option_Music            : Boolean = False;
  Option_Sound            : Boolean = False;
  Option_BlindMode        : Boolean = False;
  Option_ClearMessages    : Boolean = False;
  Option_MorePrompt       : Boolean = True;
  Option_MessageColoring  : Boolean = False;
  Option_InvFullDrop      : Boolean = False;
  Option_MortemArchive    : Boolean = False;
  Option_MenuReturn       : Boolean = False;
  Option_SoundEquipPickup : Boolean = False;
  Option_ColoredInventory : Boolean = True;
  Option_LockBreak        : Boolean = True;
  Option_LockClose        : Boolean = True;
  Option_ForceRaw         : Boolean = True;
  Option_MessageBuffer    : DWord = 100;
  Option_MaxRun           : DWord = 100;
  Option_MaxWait          : DWord = 20;
  Option_RunDelay         : Byte = 0;
  Option_Graphics         : string = 'TILES';
  Option_Blending         : Boolean = False;
  Option_SaveOnCrash      : Boolean = True;
  Option_SoundEngine      : string = 'DEFAULT';
  Option_AlwaysName       : string = '';
  Option_TimeStamp        : string = 'yyyy/mm/dd hh:nn:ss';
  Option_PlayerBackups    : DWord = 7;
  Option_ScoreBackups     : DWord = 7;
  Option_IntuitionColor   : Byte = LIGHTGRAY;
  Option_IntuitionChar    : Char = '.';

var
  ModuleOption_KlassAchievements         : Boolean = False;
  ModuleOption_NewMenu                   : Boolean = False;
  ModuleOption_MeleeMoveOnKill           : Boolean = False;
  ModuleOption_FullBeingDescription      : Boolean = False;
  ModuleOption_DefaultExplosionKnockback : Integer = 8;

var
  HARDSPRITE_HIGHLIGHT        : DWord = 0;
  HARDSPRITE_EXPL             : DWord = 0;
  HARDSPRITE_SELECT           : DWord = 0;
  HARDSPRITE_MARK             : DWord = 0;
  HARDSPRITE_GRID             : DWord = 0;
  HARDSPRITE_SHIELD           : DWord = 0;
  HARDSPRITE_SHIELD_COUNT     : DWord = 0;
  HARDSPRITE_DECAL_BLOOD      : array[0..3] of DWord = ( 0,0,0,0 );
  HARDSPRITE_DECAL_WALL_BLOOD : array[0..3] of DWord = ( 0,0,0,0 );

var
  SoundOff  : boolean = False;
  MusicOff  : boolean = False;

  // 0-25 range

const
{$include ../bin/data/core/commands.lua}
  INPUT_MOVE        = [INPUT_WALKUP,     INPUT_WALKDOWN,
                       INPUT_WALKRIGHT,  INPUT_WALKLEFT,
                       INPUT_WALKUPRIGHT,INPUT_WALKDOWNRIGHT,
                       INPUT_WALKUPLEFT, INPUT_WALKDOWNLEFT];
  INPUT_MULTIMOVE   = [INPUT_RUNUP,     INPUT_RUNDOWN,
                       INPUT_RUNRIGHT,  INPUT_RUNLEFT,
                       INPUT_RUNUPRIGHT,INPUT_RUNDOWNRIGHT,
                       INPUT_RUNUPLEFT, INPUT_RUNDOWNLEFT];
  INPUT_TARGETMOVE  = [INPUT_TARGETUP,     INPUT_TARGETDOWN,
                       INPUT_TARGETRIGHT,  INPUT_TARGETLEFT,
                       INPUT_TARGETUPRIGHT,INPUT_TARGETDOWNRIGHT,
                       INPUT_TARGETUPLEFT, INPUT_TARGETDOWNLEFT];

type TCellSet = set of Byte;
     TExplosionFlags = set of TExplosionFlag;
     TSprite = record
       Color     : TColor;
       OverColor : TColor;
       GlowColor : TColor;
       SpriteID  : array[0..7] of DWord;
       SCount    : Word;
       Frames    : Word;
       Frametime : Word;
       Flags     : TFlags;
     end;
     TExplosionData = record
       Range     : Integer;
       Delay     : Integer;
       Color     : Byte;
       Flags     : TExplosionFlags;
       Damage    : TDiceRoll;
       DamageType: TDamageType;
       ContentID : Word;
       Knockback : Integer;
       SoundID   : string[16];
       Sprite    : TSprite;
     end;

function NewSprite( ID : DWord ) : TSprite;
function NewSprite( ID : DWord; Color : TColor ) : TSprite;

const
  ActionCostPickUp = 1000;
  ActionCostDrop   = 500;
  ActionCostAct    = 500;
  ActionCostReload = 1000;
  ActionCostMove   = 1000;
  ActionCostFire   = 1000;

  ActSoundChance    = 30;

type

  TAffectData = record
    Name       : Ansistring;
    Color      : Byte;
    Color_exp  : Byte;
    AffHooks   : set of (AffectHookOnAdd,AffectHookOnUpdate,AffectHookOnRemove);
    Hooks      : TFlags;
    StatusEff  : TStatusEffect;
    StatusStr  : DWord;
  end;

var
  Affects   : array of TAffectData;

const

  StatusEffect  : TStatusEffect = StatusNormal;

const PACK_RELOAD = 100;



type TItemSlot = 1..MAX_INV_SIZE;
type TItemTypeSet = set of TItemType;

const ItemEqFilters : array[TEqSlot] of TItemTypeSet = (
                       [ItemType_Armor],
                       [ItemType_Melee,ItemType_Ranged,ItemType_NRanged],
                       [ItemType_Boots],
                       [ItemType_Melee,ItemType_Ranged,ItemType_AmmoPack]
                      );
const ItemsAll      : TItemTypeSet = [Low(TItemType)..High(TItemType)];

type TItemRecharge = record
  Delay   : Byte;
  Amount  : Byte;
  Counter : Byte;
  Limit   : Byte;
end;

type TItemProperties = record
  IType         : TItemType;

  Recharge      : TItemRecharge;
  MoveMod       : Integer;
  DodgeMod      : Integer;
  KnockMod      : Integer;

  SpriteMod     : Integer;
  Durability    : Word;
  MaxDurability : Word;

  AmmoID        : Byte;
  Ammo          : Word;
  AmmoMax       : Word;
  Acc           : Integer;
  Damage        : TDiceRoll;
  Range         : Byte;
  Spread        : Byte;
  Falloff       : Integer;
  Knockback     : Integer;
  Radius        : Byte;
  Shots         : Byte;
  ShotCost      : Byte;
  ReloadTime    : Byte;
  UseTime       : Byte;
  DamageType    : TDamageType;
  MissBase      : Byte;
  MissDist      : Byte;
  AltFire       : TAltFire;
  AltReload     : TAltReload;

  MisASCII      : Char;
  MisColor      : Byte;
  MisDelay      : Byte;

  PCosColor     : TColor;
  PGlowColor    : TColor;
  MisSprite     : TSprite;
  HitSprite     : TSprite;
  Explosion     : TExplosionData;
end;

const MaxPlayerLevel = 26;

const ExpTable : array[1..MaxPlayerLevel] of LongInt =
              (     0,    500,   1500,
                 4000,   7000,  11000,
                16000,  22000,  30000,
                40000,  50000,  60000,
                70000,  80000, 100000,
               120000, 140000, 160000,
               200000, 300000, 400000,
               500000, 600000, 700000,
               900000,10000000);
               
function Roll(stat : Integer) : Integer;
function ApplyMul( aBase, aMul : Integer ) : Integer;
function InputDirection( aInput : TInputKey ) : TDirection;
function DirectionToInput(Dir : TDirection) : TInputKey;
function TwoInt(x : integer) : string;
function ToProperFilename(s : string) : string;
function toHitToChance( aEffSkill : Integer ) : Integer;
function toHitPercent( aEffSkill : Integer ) : string;
function BonusStr(i : integer) : string;
function UnitsToPercent(Value : Integer) : string;
function Percent(Value : Integer) : string;
function Seconds(Value : Integer) : string;
function ItemTypeSetFromFlags( const aFlags : TFlags ) : TItemTypeSet;
function ExplosionFlagsFromFlags( const aFlags : TFlags ) : TExplosionFlags;
function RotateTowards( aSource, aTarget1, aTarget2 : TCoord2D; aAmount : Real ) : TCoord2D;
function MSecNow : Comp;
function DurationString( aSeconds : int64 ) : Ansistring;
function BlindCoord( const where : TCoord2D ) : string;
function SlotName(slot : TEqSlot) : string;
function DamageTypeName( aDamageType : TDamageType ) : Ansistring;
function ReadSprite( aTable : TLuaTable; var aSprite : TSprite ) : Boolean;
function ReadSprite( aTable : TLuaTable; const aName : Ansistring; var aSprite : TSprite ) : Boolean;
function ReadExplosion( aTable : TLuaTable; const aName : Ansistring; var aExplosion : TExplosionData ) : Boolean;
function ReadExplosion( aTable : TLuaTable; var aExplosion : TExplosionData ) : Boolean;
function ReadFileString( aStream : TStream; aSize : Integer ) : Ansistring;
function ReadFileString( const aFileName : Ansistring ) : Ansistring;
function WriteFileString( const aFileName, aText : Ansistring ) : Boolean;
function ReadLineFromStream( aStream : TStream; aSize : Integer = -1 ) : AnsiString;
function AxisToDirection( aAxis : TVec2f ) : TCoord2D;
function SmoothFade( aElapsed, aDuration : Single; aFadeIn : Boolean ) : Single;

var ColorOverrides : TIntHashMap;

function GetPropValueFixed(Instance: TObject; const PropName: Ansistring; PreferStrings: Boolean = True): Variant;

var TIGStyleColored   : TTIGStyle;
    TIGStyleFrameless : TTIGStyle;
    TIGStylePadless   : TTIGStyle;

implementation
uses typinfo, strutils, math, vmath, vdebug, vluasystem;

function ReadFileString( aStream : TStream; aSize : Integer ) : Ansistring;
begin
  Initialize( Result );
  SetLength( Result, aSize );
  if aStream.Size > 0 then aStream.ReadBuffer( Result[1], aSize );
end;

function ReadFileString( const aFileName : Ansistring ) : Ansistring;
var iTextFile : Text;
begin
  {$PUSH}
  {$I-}
  Assign(iTextFile,aFileName);
  Reset(iTextFile);
  Readln(iTextFile,Result);
  Close(iTextFile);
  {$POP} {restore $I}
  if IOResult <> 0 then Exit('');
end;

function WriteFileString( const aFileName, aText : Ansistring ) : Boolean;
var iTextFile : Text;
begin
  {$PUSH}
  {$I-}
  Assign(iTextFile,aFileName);
  Rewrite(iTextFile);
  Writeln(iTextFile,aText);
  Close(iTextFile);
  {$POP} {restore $I}
  Exit( IOResult <> 0 );
end;

function ReadLineFromStream( aStream : TStream; aSize : Integer = -1 ) : AnsiString;
var iChar : Char;
    iLine : Ansistring;
begin
  if aSize < 0 then aSize := aStream.Size;
  iLine := '';
  Initialize( iChar );
  while aStream.Read( iChar, SizeOf(iChar) ) = SizeOf(iChar) do
  begin
    if iChar = #10 then Break;
    if iChar <> #13 then iLine := iLine + iChar;
  end;

  if (iLine = '') and ( aStream.Position >= aSize )
    then Result := ''
    else Result := iLine;
end;

constructor TPagedReport.Create( aTitle : Ansistring; aStyled : Boolean );
begin
  FTitle := aTitle;
  FPages   := TPageArray.Create;
  FTitles  := TStringGArray.Create;
  FHeaders := TStringGArray.Create;
  FStyled  := aStyled;
end;

function TPagedReport.Add( aTitle : Ansistring; aHeader : Ansistring = '' ) : TStringGArray;
begin
  Result := TStringGArray.Create;
  FTitles.Push( aTitle );
  FHeaders.Push( aHeader );
  FPages.Push( Result );
end;

procedure TPagedReport.Add( aPage : TStringGArray; aTitle : Ansistring; aHeader : Ansistring = '' );
begin
  FTitles.Push( aTitle );
  FHeaders.Push( aHeader );
  FPages.Push( aPage );
end;

destructor TPagedReport.Destroy;
begin
  FreeAndNil( FPages );
  FreeAndNil( FTitles );
  FreeAndNil( FHeaders );
end;

{ TMenuResult }

constructor TMenuResult.Create;
begin
  Reset;
end;

procedure TMenuResult.Reset;
begin
  Quit       := False;
  Loaded     := False;
  Difficulty := 0;
  Challenge  := '';
  SChallenge := '';
  ArchAngel  := False;
  Klass      := 0;
  Trait      := 0;
  Name       := '';
end;

// change also in mortem lua!
function SlotName(slot : TEqSlot) : string;
begin
  case Slot of
//  efHead    : Exit('[ Head       ]');
    efTorso   : Exit('[ Armor      ]');
    efWeapon  : Exit('[ Weapon     ]');
    efBoots   : Exit('[ Boots      ]');
    efWeapon2 : Exit('[ Prepared   ]');
  end;
end;

function DamageTypeName( aDamageType : TDamageType ) : Ansistring;
begin
  case aDamageType of
    Damage_Bullet  : Exit('bullet');
    Damage_Melee   : Exit('melee');
    Damage_Sharpnel: Exit('shred');
    Damage_Acid    : Exit('acid');
    Damage_Fire    : Exit('fire');
    Damage_Cold    : Exit('cold');
    Damage_Poison  : Exit('poison');
    Damage_Plasma  : Exit('plasma');
    Damage_SPlasma : Exit('plasma');
    Damage_IgnoreArmor : Exit('heavy');
    Damage_Pierce  : Exit('pierce');
  end;
end;


function BlindCoord( const where : TCoord2D ) : string;
begin
  BlindCoord := '[';
  if where.y > 0 then BlindCoord += IntToStr(where.y)+'s';
  if where.y < 0 then BlindCoord += IntToStr(-where.y)+'n';
  if where.x > 0 then BlindCoord += IntToStr(where.x)+'e';
  if where.x < 0 then BlindCoord += IntToStr(-where.x)+'w';
  if (where.x = 0) and (where.y = 0) then BlindCoord += 'here';
  BlindCoord += ']';
end;

function GetPropValueFixed(Instance: TObject; const PropName: Ansistring;
  PreferStrings: Boolean): Variant;
begin
  GetPropValueFixed := GetPropValue(Instance, PropName, PreferStrings );
  if GetPropInfo(Instance, PropName)^.PropType^.Kind = tkBool then
    VarCast( GetPropValueFixed, GetPropValueFixed, varBoolean );
end;

function UnitsToPercent(Value : Integer) : string;
begin
  UnitsToPercent := IIf( Value >= 0, '+' ) + FloatToStrF(Value,ffFixed,0,2)+'%';
end;

function Percent(Value : Integer) : string;
begin
  Percent := IIf( Value >= 0, '+' ) + IntToStr(Value)+'%';
end;

function Seconds(Value : Integer) : string;
begin
  Seconds := FloatToStrF(Value/10.,ffFixed,0,1)+'s';
end;

function ItemTypeSetFromFlags( const aFlags: TFlags ): TItemTypeSet;
var iCount : TItemType;
begin
  ItemTypeSetFromFlags := [];
  for iCount in TItemTypeSet do
    if Byte( iCount ) in aFlags then Include( ItemTypeSetFromFlags, iCount );
end;

function ExplosionFlagsFromFlags( const aFlags: TFlags ): TExplosionFlags;
var iCount : TExplosionFlag;
begin
  ExplosionFlagsFromFlags := [];
  for iCount in TExplosionFlags  do
    if Byte( iCount ) in aFlags then Include( ExplosionFlagsFromFlags, iCount );
end;

function RotateTowards( aSource, aTarget1, aTarget2: TCoord2D; aAmount : Real ): TCoord2D;
var iVector1, iVector2 : TCoord2D;
    iCos, iSin, iAngle : Float;
    iAT1, iAT2         : Float;
    iSign              : Integer;
begin
  if aTarget1 = aTarget2 then Exit( aTarget2 );
  iVector1  := aTarget1 - aSource;
  iVector2  := aTarget2 - aSource;
  iAT1      := arctan2( iVector1.y, iVector1.x );
  iAT2      := arctan2( iVector2.y, iVector2.x );
  if iAT1 < 0 then iAT1 += 2*PI;
  if iAT2 < 0 then iAT2 += 2*PI;
  iAngle    := iAT2 - iAT1;
  iSign     := Sign( iAngle );
  if Floor( Abs( iAngle ) / aAmount ) < 1 then Exit( aTarget2 );
  if Abs( iAngle ) > PI then iSign := -iSign;

  iCos := cos( aAmount * iSign );
  iSin := sin( aAmount * iSign );
  
  RotateTowards.x := aSource.x + Round((iVector1.x * iCos) - (iVector1.y * iSin));
  RotateTowards.y := aSource.y + Round((iVector1.y * iCos) + (iVector1.x * iSin));
end;

function MSecNow: Comp;
begin
  Exit( TimeStampToMSecs( DateTimeToTimeStamp( Now ) ) );
end;

function DurationString( aSeconds : int64 ): Ansistring;
var iSec, iMin, iHour, iDay : DWord;
    iPos                    : Integer;
  function ValueString( aValue : DWord; const aName : String ) : String;
  begin
    if aValue = 0 then Exit('');
    Exit(IntToStr(aValue) + ' ' + aName + IIf( aValue > 1, 's' ) + ', ');
  end;
Begin
  if aSeconds <= 0 then Exit('0 seconds');
  iSec     := aSeconds mod 60;
  iMin     := (aSeconds div 60) mod 60;
  iHour    := (aSeconds div (60*60)) mod 24;
  iDay     := (aSeconds div (60*60*24));

  DurationString := ValueString( iDay, 'day' )
                  + ValueString( iHour, 'hour' )
                  + ValueString( iMin,  'minute' )
                  + ValueString( iSec,  'second' );

  RemoveTrailingChars( DurationString, [' ',','] );
  iPos := RPos( ',', DurationString );
  if iPos > 0 then
  begin
    Delete( DurationString, iPos, 1 );
    Insert( ' and', DurationString, iPos );
  end;
end;

function TwoInt(x : integer) : string;
begin
  if (x < 10) and (x > -1) then Exit(' '+IntToStr(x))
  else Exit(IntToStr(x));
end;



function InputDirection(aInput : TInputKey) : TDirection;
begin
  case aInput of
    INPUT_WALKLEFT        : InputDirection.Create(4);
    INPUT_WALKRIGHT       : InputDirection.Create(6);
    INPUT_WALKUP          : InputDirection.Create(8);
    INPUT_WALKDOWN        : InputDirection.Create(2);
    INPUT_WALKUPLEFT      : InputDirection.Create(7);
    INPUT_WALKUPRIGHT     : InputDirection.Create(9);
    INPUT_WALKDOWNLEFT    : InputDirection.Create(1);
    INPUT_WALKDOWNRIGHT   : InputDirection.Create(3);
    INPUT_WAIT            : InputDirection.Create(5);
    INPUT_RUNLEFT         : InputDirection.Create(4);
    INPUT_RUNRIGHT        : InputDirection.Create(6);
    INPUT_RUNUP           : InputDirection.Create(8);
    INPUT_RUNDOWN         : InputDirection.Create(2);
    INPUT_RUNUPLEFT       : InputDirection.Create(7);
    INPUT_RUNUPRIGHT      : InputDirection.Create(9);
    INPUT_RUNDOWNLEFT     : InputDirection.Create(1);
    INPUT_RUNDOWNRIGHT    : InputDirection.Create(3);
    INPUT_RUNWAIT         : InputDirection.Create(5);
    INPUT_TARGETLEFT      : InputDirection.Create(4);
    INPUT_TARGETRIGHT     : InputDirection.Create(6);
    INPUT_TARGETUP        : InputDirection.Create(8);
    INPUT_TARGETDOWN      : InputDirection.Create(2);
    INPUT_TARGETUPLEFT    : InputDirection.Create(7);
    INPUT_TARGETUPRIGHT   : InputDirection.Create(9);
    INPUT_TARGETDOWNLEFT  : InputDirection.Create(1);
    INPUT_TARGETDOWNRIGHT : InputDirection.Create(3);
    else InputDirection.Create(0);
  end;
end;

function DirectionToInput(Dir : TDirection) : TInputKey;
begin
  case Dir.code of
    4 : Exit( INPUT_WALKLEFT );
    6 : Exit( INPUT_WALKRIGHT );
    8 : Exit( INPUT_WALKUP );
    2 : Exit( INPUT_WALKDOWN );
    7 : Exit( INPUT_WALKUPLEFT );
    9 : Exit( INPUT_WALKUPRIGHT );
    1 : Exit( INPUT_WALKDOWNLEFT );
    3 : Exit( INPUT_WALKDOWNRIGHT );
    5 : Exit( INPUT_WAIT );
    else Exit( INPUT_WAIT );
  end;
end;

function NewSprite ( ID : DWord ) : TSprite;
begin
  NewSprite.Flags       := [];
  NewSprite.SpriteID[0] := ID;
  NewSprite.Frames      := 0;
  NewSprite.Frametime   := 0;
end;

function NewSprite ( ID : DWord; Color : TColor ) : TSprite;
begin
  NewSprite.Flags       := [ SF_COSPLAY ];
  NewSprite.Color       := Color;
  NewSprite.SpriteID[0] := ID;
  NewSprite.Frames      := 0;
  NewSprite.Frametime   := 0;
end;

function Roll(stat : Integer) : Integer;
var DieRoll : byte;
begin
  DieRoll := Dice(3,6);
  case DieRoll of
      3 : Exit(30);
      4 : Exit(20);
     17 : Exit(-20);
     18 : Exit(-30);
  end;
  Roll := stat - DieRoll;
end;

function ApplyMul( aBase, aMul : Integer ) : Integer;
begin
  if aMul = 0 then Exit( aBase );
  Result := Round( ( ( 100 + aMul ) / 100.0 ) * aBase );
end;

{ TStringList }


function ToProperFilename(s : string) : string;
const good : set of char = ['a'..'z','0','1'..'9','A'..'Z','[',']',' ','-'];
var ch : char;
begin
  ToProperFilename := '';
  for ch in s do
    ToProperFilename += IIf( ch in good, ch, '-' );
end;

function toHitPercent( aEffSkill : Integer ): string;
begin
  if aEffSkill <= 3  then Exit('1%');
  if aEffSkill >= 16 then Exit('98%');
  case aEffSkill of
    4 : Exit('2%');
    5 : Exit('5%');
    6 : Exit('9%');
    7 : Exit('16%');
    8 : Exit('26%');
    9 : Exit('38%');
   10 : Exit('50%');
   11 : Exit('62%');
   12 : Exit('74%');
   13 : Exit('84%');
   14 : Exit('91%');
   15 : Exit('95%');
  end;
end;

function toHitToChance( aEffSkill : Integer ) : Integer;
begin
  if aEffSkill <= 3  then Exit(1);
  if aEffSkill >= 16 then Exit(98);
  case aEffSkill of
    4 : Exit(2);
    5 : Exit(5);
    6 : Exit(9);
    7 : Exit(16);
    8 : Exit(26);
    9 : Exit(38);
   10 : Exit(50);
   11 : Exit(62);
   12 : Exit(74);
   13 : Exit(84);
   14 : Exit(91);
   15 : Exit(95);
  end;
end;

function BonusStr(i: integer): string;
begin
  if i < 0 then BonusStr := IntToStr(i)
           else BonusStr := '+'+IntToStr(i);
end;

function ReadSprite( aTable : TLuaTable; var aSprite : TSprite ) : Boolean;
var iTable : TLuaTable;
    iPair  : TLuaIndexValue;
begin
  ReadSprite := False;
  if aTable.IsNumber( 'sprite' ) then
  begin
    aSprite.SCount      := 1;
    aSprite.SpriteID[0] := aTable.getInteger('sprite',0);
    ReadSprite          := True;
  end;
  if aTable.IsTable( 'sprites' ) then
  begin
    aSprite.SCount  := aTable.GetTableSize( 'sprites' );
    Assert( aSprite.SCount > 0, '!' );
    try
      iTable := aTable.GetTable( 'sprites' );
      for iPair in iTable.IPairs do
        aSprite.SpriteID[iPair.Index-1] := iPair.Value.ToInteger;
    finally
      iTable.Free;
    end;
    ReadSprite          := True;
  end;
  if aTable.IsTable( 'sflags' ) then
    aSprite.Flags     := aTable.getFlags('sflags',[]);
  if aTable.IsNumber( 'sframes' ) then
    aSprite.Frames    := aTable.getInteger('sframes',0);
  if aTable.IsNumber( 'sftime' ) then
    aSprite.Frametime := aTable.getInteger('sftime',FRAME_TIME);
  if not aTable.isNil( 'overlay' ) then
  begin
    Include( aSprite.Flags, SF_OVERLAY );
    aSprite.OverColor := NewColor( aTable.GetVec4f('overlay' ) );
  end;
  if not aTable.isNil( 'coscolor' ) then
  begin
    Include( aSprite.Flags, SF_COSPLAY );
    aSprite.Color := NewColor( aTable.GetVec4f('coscolor' ) );
  end;
  if not aTable.isNil( 'glow' ) then
    aSprite.GlowColor := NewColor( aTable.GetVec4f('glow' ) );

  // so we can later move to in-sprite table sprite info definitions slowly
  if aTable.IsTable( 'sprite' ) then
  begin
    iTable := aTable.GetTable( 'sprite' );
    Result := ReadSprite( iTable, aSprite );
    iTable.Free;
  end;
end;

function ReadSprite( aTable : TLuaTable; const aName : Ansistring; var aSprite : TSprite ) : Boolean;
var iTable : TLuaTable;
begin
  ReadSprite := False;
  if aTable.IsNumber( aName ) then
  begin
    aSprite.SCount      := 1;
    aSprite.SpriteID[0] := aTable.getInteger( aName , 0 );
    ReadSprite          := True;
  end
  else if aTable.IsTable( aName ) then
  begin
    iTable := aTable.GetTable( aName );
    Result := ReadSprite( iTable, aSprite );
    iTable.Free;
  end;
end;

function ReadExplosion( aTable : TLuaTable; var aExplosion : TExplosionData ) : Boolean;
begin
  aExplosion.Range      := aTable.getInteger('range',0);
  aExplosion.Delay      := aTable.getInteger('delay',0);
  aExplosion.Color      := aTable.getInteger('color',0);
  aExplosion.Knockback  := aTable.GetInteger('knockback',ModuleOption_DefaultExplosionKnockback);
  aExplosion.SoundID    := aTable.getString('sound_id','');
  aExplosion.Flags      := ExplosionFlagsFromFlags( aTable.getFlags('flags',[]) );
  aExplosion.Damage     := NewDiceRoll( aTable.getString('damage','') );
  aExplosion.DamageType := TDamageType( aTable.getInteger('damage_type',LongInt( DAMAGE_FIRE ) ) );
  if aTable.IsNumber('content') then
    aExplosion.ContentID  := aTable.getInteger('content',0)
  else if aTable.IsString('content') then
  begin
    aExplosion.ContentID := LuaSystem.Defines[ aTable.getString( 'content' ) ];
    if aExplosion.ContentID = 0 then
      Log( LOGERROR, 'unknown define ('+aTable.getString( 'content' ) +')!' );
  end
  else
    aExplosion.ContentID := 0;
  FillChar( aExplosion.Sprite, SizeOf( TSprite ), 0 );
  ReadSprite( aTable, 'sprite', aExplosion.Sprite );
  ReadExplosion := aExplosion.Color > 0;
end;

function ReadExplosion( aTable : TLuaTable; const aName : Ansistring; var aExplosion : TExplosionData ) : Boolean;
var iTable : TLuaTable;
begin
  ReadExplosion                 := False;
  FillChar( aExplosion, SizeOf(TExplosionData), 0 );
  if aTable.IsTable( aName ) then
  begin
    iTable := aTable.GetTable( aName );
    Result := ReadExplosion( iTable, aExplosion );
    iTable.Free;
  end;
end;


function AxisToDirection( aAxis : TVec2f ) : TCoord2D;
const DeadZoneSquared = 0.4*0.4;
const KDirection8: array[0..7] of TCoord2D = (
    (x:  1; y:  0),  // Right
    (x:  1; y: -1),  // Up-Right
    (x:  0; y: -1),  // Up
    (x: -1; y: -1),  // Up-Left
    (x: -1; y:  0),  // Left
    (x: -1; y:  1),  // Down-Left
    (x:  0; y:  1),  // Down
    (x:  1; y:  1)   // Down-Right
  );
var iAngle      : Single;
    iSectorSize : Single;
begin
  if aAxis.X * aAxis.X + aAxis.Y * aAxis.Y < DeadZoneSquared then
    Exit(NewCoord2D(0,0));

  iAngle := ArcTan2(-aAxis.y, aAxis.x); // returns [-Pi..Pi]
  if iAngle < 0 then
    iAngle := iAngle + 2 * Pi;

  iSectorSize := Pi / 4;
  Result := KDirection8[Round(iAngle / iSectorSize) mod 8];
end;

function SmoothFade( aElapsed, aDuration : Single; aFadeIn : Boolean ) : Single;
var iNorm  : Single;
    iEased : Single;
begin
  if aDuration <= 0.0 then
    if aFadeIn then Exit( 1.0 ) else Exit( 0.0 );

  iNorm  := Clampf( aElapsed / aDuration, 0.0, 1.0 );
  iEased := iNorm * iNorm * (3.0 - 2.0 * iNorm);

  if aFadeIn
    then Exit( iEased )
    else Exit( 1.0 - iEased );
end;

end.
