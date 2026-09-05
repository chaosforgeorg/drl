{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlhooks;
interface
uses vutil, vluasystem, dfdata;

const
  Hook_OnCreate        = 0;   // Being and Item; Module and Challenge notified explicitly
  Hook_OnAction        = 1;   // Being
  Hook_OnAttacked      = 2;   // Being
  Hook_OnUseActive     = 3;   // Trait, Being
  Hook_OnDie           = 4;   // Being, Perk
  Hook_OnDieCheck      = 5;   // Being, Perk
  Hook_OnPickup        = 6;   // Being, Item, Perk
  Hook_OnPickupCheck   = 7;   // Item, Perk
  Hook_OnFirstPickup   = 8;   // Item
  Hook_OnUse           = 9;   // Item, Perk
  Hook_OnUseCheck      = 10;  // Item, Perk
  Hook_OnAltFire       = 11;  // Perk (item)
  Hook_OnAltReload     = 12;  // Perk (item)
  Hook_OnEquip         = 13;  // Item, Perk
  Hook_OnUnequip       = 14;  // Item, Perk
  Hook_OnAdd           = 15;  // Perk
  Hook_OnRemove        = 16;  // Perk
  Hook_OnTick10        = 17;  // Perk
  Hook_OnKill          = 18;  // Trait, Perk (item, being, level)
  Hook_OnKillAll       = 19;  // Perk (level)
  Hook_OnHitBeing      = 20;  // Perk (item)
  Hook_OnReload        = 21;  // Perk (item)
  Hook_OnDescribe      = 22;  // Item, Perk
  Hook_OnEquipCheck    = 23;  // Perk (item)
  Hook_OnAct           = 24;  // Item, Being (hack)
  Hook_OnDestroy       = 25;  // Item
  Hook_OnEnter         = 26;  // Item (separate)
  Hook_OnEnterLevel    = 27;  // Trait, Perk, Module, Challenge
  Hook_OnFire          = 28;  // Trait, Perk
  Hook_OnFired         = 29;  // Trait, Perk
  Hook_OnExitLevel     = 30;  // Perk (level), Module, Challenge
  Hook_OnTick          = 31;  // Perk, Module
  Hook_OnNuked         = 32;  // Perk (level)
  Hook_OnLoad          = 33;  // Module
  Hook_OnLoaded        = 34;  // Module
  Hook_OnUnLoad        = 35;  // Module, Challenge
  Hook_OnCreatePlayer  = 36;  // Module, Challenge
  Hook_OnLevelUp       = 37;  // Module, Challenge
  Hook_OnPreLevelUp    = 38;  // Module, Challenge
  Hook_OnWinGame       = 39;  // Module, Challenge
  Hook_OnCreateEpisode = 40;  // Module, Challenge
  Hook_OnIntro         = 41;  // Module
  Hook_OnGenerate      = 42;  // Module

  // TODO: merge with above
  Hook_OnPostMove      = 43;   // Trait, Perk
  Hook_OnPreReload     = 44;   // Perk (item)
  Hook_OnDamage        = 45;   // Trait, Being, Perk
  Hook_OnReceiveDamage = 46;   // Trait, Being, Perk
  Hook_OnPreAction     = 47;   // Trait, Perk
  Hook_OnPostAction    = 48;   // Trait, Perk
  Hook_OnCanDualWield  = 49;   // Trait
  Hook_OnCanMaxDamage  = 50;   // Trait, Perk

  Hook_getDamageBonus  = 51; // Trait, Perk
  Hook_getToHitBonus   = 52; // Trait, Perk
  Hook_getShotsBonus   = 53; // Trait, Perk
  Hook_getFireCostBonus= 54; // Trait, Perk
  Hook_getDefenceBonus = 55; // Perk
  Hook_getDodgeBonus   = 56; // Trait, Perk
  Hook_getMoveBonus    = 57; // Perk
  Hook_getBodyBonus    = 58; // Trait, Perk
  Hook_getResistBonus  = 59; // Trait, Perk
  Hook_getDamageMul    = 60; // Trait, Perk
  Hook_getFireCostMul  = 61; // Trait, Perk
  Hook_getAmmoCostMul  = 62; // Trait, Perk
  Hook_getReloadCostMul= 63; // Trait, Perk
  Hook_getGibMul       = 64; // Trait, Perk
  Hook_OnUnequipCheck  = 65; // Item, Perk
  Hook_OnDrop          = 66; // Perk (item)
  Hook_OnCanAct        = 67; // Being
  Hook_OnShort         = 68; // Perk

  HookAmount           = 69;

const AllHooks      : TFlags = [ 0..HookAmount-1 ];

var   BeingHooks       : TFlags;
      ItemHooks        : TFlags;
      FullInvHooks     : TFlags;
      NoInventoryHooks : TFlags;
      GlobalHooks      : TFlags;
      ModuleHooks      : TFlags;


const HookNames : array[ 0..HookAmount-1 ] of AnsiString = (
      'OnCreate', 'OnAction', 'OnAttacked', 'OnUseActive', 'OnDie', 'OnDieCheck',
      'OnPickup','OnPickupCheck','OnFirstPickup','OnUse','OnUseCheck',
      'OnAltFire', 'OnAltReload', 'OnEquip', 'OnUnequip', 'OnAdd', 'OnRemove', 'OnTick10', 'OnKill', 'OnKillAll',
      'OnHitBeing', 'OnReload', 'OnDescribe', 'OnEquipCheck', 'OnAct', 'OnDestroy', 'OnEnter', 'OnEnterLevel',
      'OnFire', 'OnFired', 'OnExitLevel', 'OnTick', 'OnNuked',
      'OnLoad','OnLoaded','OnUnLoad', 'OnCreatePlayer', 'OnLevelUp','OnPreLevelUp',
      'OnWinGame', 'OnCreateEpisode', 'OnIntro' , 'OnGenerate',

      'OnPostMove', 'OnPreReload', 'OnDamage', 'OnReceiveDamage', 'OnPreAction', 'OnPostAction',
      'OnCanDualWield', 'OnCanMaxDamage',

      'getDamageBonus', 'getToHitBonus', 'getShotsBonus', 'getFireCostBonus',
      'getDefenceBonus', 'getDodgeBonus', 'getMoveBonus', 'getBodyBonus', 'getResistBonus',
      'getDamageMul', 'getFireCostMul', 'getAmmoCostMul', 'getReloadCostMul',
      'getGibMul',
      'OnUnequipCheck',
      'OnDrop', 'OnCanAct',
      'OnShort'
      );

function LoadHooks( const aTable : array of Const ) : TFlags;
function LoadHooks( const aTable : array of Const; aHooks : TFlags ) : TFlags;
function LoadCallbacks( aTable : TLuaTable ) : TFlags;

implementation

function LoadHooks ( const aTable : array of Const ) : TFlags;
begin
  Exit( LoadHooks( aTable, AllHooks ) );
end;

function LoadHooks ( const aTable : array of Const; aHooks : TFlags ) : TFlags;
var iHook    : Byte;
    i, iSize : DWord;
begin
  with LuaSystem.GetTable( aTable ) do
  try
    LoadHooks := [];
    for iHook in aHooks do
      if isFunction(HookNames[iHook]) then
        Include(LoadHooks,iHook);
    iSize := LuaSystem.GetTableSize( ['core','callbacks'] );
    if iSize > 0 then
      for i := 1 to iSize do
        if isFunction( LuaSystem.Get( ['core','callbacks', i] ) ) then
          Include( LoadHooks, i + 200 );
  finally
    Free;
  end;
end;

function LoadCallbacks( aTable : TLuaTable ) : TFlags;
var i, iSize : DWord;
begin
  iSize := LuaSystem.GetTableSize( ['core','callbacks'] );
  if iSize = 0 then Exit( [] );
  LoadCallbacks := [];
  for i := 1 to iSize do
    if aTable.isFunction( LuaSystem.Get( ['core','callbacks', i] ) ) then
      Include( LoadCallbacks, i + 200 );
end;

initialization

AllHooks     := [ 0..HookAmount-1 ];
// Prototype masks; perks load their hooks independently.
BeingHooks   := [ Hook_OnCreate, Hook_OnAction, Hook_OnAttacked, Hook_OnUseActive,
  Hook_OnDie, Hook_OnDieCheck, Hook_OnPickup, Hook_OnDamage, Hook_OnReceiveDamage,
  Hook_OnAct, Hook_OnCanAct ];
FullInvHooks := [ Hook_OnPreAction, Hook_OnPostAction, Hook_OnTick ];
NoInventoryHooks := [ Hook_OnPickup ];
ItemHooks    := [ Hook_OnCreate, Hook_OnPickup, Hook_OnFirstPickup,
  Hook_OnUse, Hook_OnUseCheck, Hook_OnEquip, Hook_OnUnequip,
  Hook_OnEnter, Hook_OnAct, Hook_OnDestroy, Hook_OnDescribe, Hook_OnPickupCheck,
  Hook_OnUnequipCheck ];
GlobalHooks  := [ Hook_OnCreate, Hook_OnEnterLevel, Hook_OnExitLevel, Hook_OnTick,
  Hook_OnLoad, Hook_OnLoaded, Hook_OnUnLoad, Hook_OnCreatePlayer, Hook_OnLevelUp,
  Hook_OnPreLevelUp, Hook_OnWinGame, Hook_OnCreateEpisode,
  Hook_OnIntro, Hook_OnGenerate ];
ModuleHooks  := [ Hook_OnLoad ];

end.
