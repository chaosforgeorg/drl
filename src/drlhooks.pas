{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlhooks;
interface
uses vutil, dfdata;

const
  Hook_OnCreate        = 0;   // Being and Item -> Level, Module, Challenge, Core (Chained)
  Hook_OnAction        = 1;   // Being
  Hook_OnAttacked      = 2;   // Trait, Being
  Hook_OnUseActive     = 3;   // Trait, Being
  Hook_OnDie           = 4;   // Trait, Being, Level, Module, Challenge, Core (Chained)
  Hook_OnDieCheck      = 5;   // Trait, Being, Level, Module, Challenge, Core (Chained)
  Hook_OnPickupItem    = 6;   // Trait, Being, Level, Module, Challenge, Core (Chained)
  Hook_OnPickup        = 7;   // Item, Level, Module, Challenge, Core (Chained)
  Hook_OnPickupCheck   = 8;   // Item, Level, Module, Challenge, Core (Chained)
  Hook_OnFirstPickup   = 9;   // Item
  Hook_OnUse           = 10;  // Item, Level, Module, Challenge, Core (Chained)
  Hook_OnUseCheck      = 11;  // Item, Level, Module, Challenge, Core (Chained)
  Hook_OnAltFire       = 12;  // Item
  Hook_OnAltReload     = 13;  // Item
  Hook_OnEquip         = 14;  // Item
  Hook_OnUnequip       = 15;  // Item
  Hook_OnAdd           = 16;  // Perk
  Hook_OnRemove        = 17;  // Perk
  Hook_OnTick10        = 18;  // Perk
  Hook_OnKill          = 19;  // Item (separate), Trait, Being (separate), Level, Module, Challenge, Core (Chained)
  Hook_OnKillAll       = 20;  // Level, Module, Challenge, Core (Chained)
  Hook_OnHitBeing      = 21;  // Item
  Hook_OnReload        = 22;  // Item
  Hook_OnEquipTick     = 23;  // Item
  Hook_OnEquipCheck    = 24;  // Item
  Hook_OnAct           = 25;  // Item
  Hook_OnDestroy       = 26;  // Item
  Hook_OnEnter         = 27;  // Item (separate)
  Hook_OnEnterLevel    = 28;  // Level, Module, Challenge, Core (chained)
  Hook_OnFire          = 29;  // Item, Level, Module, Challenge, Core (Chained)
  Hook_OnFired         = 30;  // Trait (separate), Item, Level, Module, Challenge, Core (Chained)
  Hook_OnExit          = 31;  // Level, Module, Challenge, Core (Chained)
  Hook_OnTick          = 32;  // Perk, Being (Separate), Level, Module, Challenge, Core (Chained)
  Hook_OnNuked         = 33;  // Level, Module, Challenge, Core (Chained)
  Hook_OnLoad          = 34;  // Module, Challenge, Core (Chained)
  Hook_OnLoaded        = 35;  // Module, Challenge, Core (Chained)
  Hook_OnUnLoad        = 36;  // Module, Challenge, Core (Chained)
  Hook_OnCreatePlayer  = 37;  // Module, Challenge, Core (Chained)
  Hook_OnLevelUp       = 38;  // Module, Challenge, Core (Chained)
  Hook_OnPreLevelUp    = 39;  // Module, Challenge, Core (Chained)
  Hook_OnWinGame       = 40;  // Module, Challenge, Core (Chained)
  Hook_OnMortem        = 41;  // Module, Challenge, Core (Chained)
  Hook_OnMortemPrint   = 42;  // Module, Challenge, Core (Chained)
  Hook_OnCreateEpisode = 43;  // Module, Challenge, Core (Chained)
  Hook_OnIntro         = 44;  // Module, Challenge, Core (Chained)
  Hook_OnGenerate      = 45;  // Module, Challenge, Core (Chained)

  // TODO: merge with above
  Hook_OnPostMove      = 46;   // Trait, Being
  Hook_OnPreReload     = 47;   // Trait, Being
  Hook_OnDamage        = 48;   // Trait, Being, Item
  Hook_OnReceiveDamage = 49;   // Trait, Being
  Hook_OnPreAction     = 50;   // Trait, Being
  Hook_OnPostAction    = 51;   // Trait, Being
  Hook_OnCanDualWield  = 52;   // Trait
  Hook_OnCanMaxDamage  = 53;   // Trait

  Hook_OnDescribe      = 54; // Item

  Hook_getDamageBonus  = 55; // Trait, Being, Affects
  Hook_getToHitBonus   = 56; // Trait, Being, Affects
  Hook_getShotsBonus   = 57; // Trait, Being, Affects
  Hook_getFireCostBonus= 58; // Trait, Being, Affects
  Hook_getDefenceBonus = 59; // Trait, Being, Affects
  Hook_getDodgeBonus   = 60; // Trait, Being, Affects
  Hook_getMoveBonus    = 61; // Trait, Being, Affects
  Hook_getBodyBonus    = 62; // Trait, Being, Affects
  Hook_getResistBonus  = 63; // Trait, Being, Affects
  Hook_getDamageMul    = 64; // Trait, Being, Affects
  Hook_getFireCostMul  = 65; // Trait, Being, Affects
  Hook_getAmmoCostMul  = 66; // Trait, Being, Affects
  Hook_getReloadCostMul= 67; // Trait, Being, Affects
  Hook_OnUnequipCheck  = 68; // Item

  HookAmount           = 69;

const AllHooks      : TFlags = [ 0..HookAmount-1 ];

var   BeingHooks    : TFlags;
      ItemHooks     : TFlags;
      ChainedHooks  : TFlags;
      LevelHooks    : TFlags;
      GlobalHooks   : TFlags;
      ModuleHooks   : TFlags;


const HookNames : array[ 0..HookAmount-1 ] of AnsiString = (
      'OnCreate', 'OnAction', 'OnAttacked', 'OnUseActive', 'OnDie', 'OnDieCheck',
      'OnPickupItem', 'OnPickup','OnPickupCheck','OnFirstPickup','OnUse','OnUseCheck',
      'OnAltFire', 'OnAltReload', 'OnEquip', 'OnUnequip', 'OnAdd', 'OnRemove', 'OnTick10', 'OnKill', 'OnKillAll',
      'OnHitBeing', 'OnReload', 'OnEquipTick', 'OnEquipCheck', 'OnAct', 'OnDestroy', 'OnEnter', 'OnEnterLevel',
      'OnFire', 'OnFired', 'OnExit', 'OnTick', 'OnNuked',
      'OnLoad','OnLoaded','OnUnLoad', 'OnCreatePlayer', 'OnLevelUp','OnPreLevelUp',
      'OnWinGame', 'OnMortem', 'OnMortemPrint', 'OnCreateEpisode', 'OnIntro' , 'OnGenerate',

      'OnPostMove', 'OnPreReload', 'OnDamage', 'OnReceiveDamage', 'OnPreAction', 'OnPostAction',
      'OnCanDualWield', 'OnCanMaxDamage',
      'OnDescribe',
      'getDamageBonus', 'getToHitBonus', 'getShotsBonus', 'getFireCostBonus',
      'getDefenceBonus', 'getDodgeBonus', 'getMoveBonus', 'getBodyBonus', 'getResistBonus',
      'getDamageMul', 'getFireCostMul', 'getAmmoCostMul', 'getReloadCostMul',
      'OnUnequipCheck'
      );

function LoadHooks( const aTable : array of Const ) : TFlags;
function LoadHooks( const aTable : array of Const; aHooks : TFlags ) : TFlags;

implementation

uses vluasystem;

function LoadHooks ( const aTable : array of Const ) : TFlags;
begin
  Exit( LoadHooks( aTable, AllHooks ) );
end;

function LoadHooks ( const aTable : array of Const; aHooks : TFlags ) : TFlags;
var Hook  : Byte;
begin
  with LuaSystem.GetTable( aTable ) do
  try
    LoadHooks := [];
    for Hook in aHooks do
      if isFunction(HookNames[Hook]) then
        Include(LoadHooks,Hook);
  finally
    Free;
  end;
end;

initialization

AllHooks     := [ 0..HookAmount-1 ];
BeingHooks   := [ Hook_OnCreate, Hook_OnAction, Hook_OnAttacked, Hook_OnUseActive,
  Hook_OnDie, Hook_OnDieCheck, Hook_OnPickUpItem, Hook_OnPostMove, Hook_OnKill,
  Hook_OnDamage, Hook_OnReceiveDamage, Hook_OnPreAction, Hook_OnEnterLevel,
  Hook_getDamageBonus, Hook_getToHitBonus, Hook_getShotsBonus, Hook_getFireCostBonus,
  Hook_getDefenceBonus, Hook_getDodgeBonus, Hook_getMoveBonus, Hook_getBodyBonus,
  Hook_getResistBonus, Hook_getDamageMul, Hook_getFireCostMul, Hook_getAmmoCostMul];
ItemHooks    := [ Hook_OnCreate, Hook_OnPickup, Hook_OnFirstPickup,
  Hook_OnUse, Hook_OnUseCheck, Hook_OnAltFire, Hook_OnEquip, Hook_OnUnequip,
  Hook_OnEnter, Hook_OnFire, Hook_OnAct, Hook_OnDestroy, Hook_OnDescribe,
  Hook_OnUnequipCheck ];
ChainedHooks := [ Hook_OnCreate, Hook_OnDie, Hook_OnDieCheck, Hook_OnPickup,
  Hook_OnPickUpItem, Hook_OnKillAll, Hook_OnPickupCheck, Hook_OnUse, Hook_OnUseCheck,
  Hook_OnFire, Hook_OnFired ];
LevelHooks   := ChainedHooks + [ Hook_OnEnterLevel, Hook_OnKill, Hook_OnExit, Hook_OnTick,
  Hook_OnNuked ];
GlobalHooks  := LevelHooks + [ Hook_OnEnterLevel, Hook_OnKill, Hook_OnExit, Hook_OnTick,
  Hook_OnLoad, Hook_OnLoaded, Hook_OnUnLoad, Hook_OnCreatePlayer, Hook_OnLevelUp,
  Hook_OnPreLevelUp, Hook_OnWinGame, Hook_OnMortem, Hook_OnMortemPrint, Hook_OnCreateEpisode,
  Hook_OnIntro, Hook_OnGenerate ];
ModuleHooks  := [ Hook_OnLoad ];

end.

