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
  Hook_OnUse           = 8;   // Perk (item)
  Hook_OnUseCheck      = 9;   // Perk (item)
  Hook_OnAltFire       = 10;  // Perk (item)
  Hook_OnAltReload     = 11;  // Perk (item)
  Hook_OnEquip         = 12;  // Item, Perk
  Hook_OnUnequip       = 13;  // Item, Perk
  Hook_OnAdd           = 14;  // Perk
  Hook_OnRemove        = 15;  // Perk
  Hook_OnTick10        = 16;  // Perk
  Hook_OnKill          = 17;  // Trait, Perk (item, being, level)
  Hook_OnKillAll       = 18;  // Perk (level)
  Hook_OnHitBeing      = 19;  // Perk (item)
  Hook_OnReload        = 20;  // Perk (item)
  Hook_OnDescribe      = 21;  // Item, Perk
  Hook_OnEquipCheck    = 22;  // Perk (item)
  Hook_OnAct           = 23;  // Item, Being (hack)
  Hook_OnDestroy       = 24;  // Item
  Hook_OnEnter         = 25;  // Perk (item; separate from cell OnEnter)
  Hook_OnEnterLevel    = 26;  // Trait, Perk, Module, Challenge
  Hook_OnFire          = 27;  // Trait, Perk
  Hook_OnFired         = 28;  // Trait, Perk
  Hook_OnExitLevel     = 29;  // Perk (level), Module, Challenge
  Hook_OnTick          = 30;  // Perk, Module
  Hook_OnNuked         = 31;  // Perk (level)
  Hook_OnLoad          = 32;  // Module
  Hook_OnLoaded        = 33;  // Module
  Hook_OnUnLoad        = 34;  // Module, Challenge
  Hook_OnCreatePlayer  = 35;  // Module, Challenge
  Hook_OnLevelUp       = 36;  // Module, Challenge
  Hook_OnPreLevelUp    = 37;  // Module, Challenge
  Hook_OnWinGame       = 38;  // Module, Challenge
  Hook_OnCreateEpisode = 39;  // Module, Challenge
  Hook_OnIntro         = 40;  // Module
  Hook_OnGenerate      = 41;  // Module

  // TODO: merge with above
  Hook_OnPostMove      = 42;   // Trait, Perk
  Hook_OnPreReload     = 43;   // Perk (item)
  Hook_OnDamage        = 44;   // Trait, Being, Perk
  Hook_OnReceiveDamage = 45;   // Trait, Being, Perk
  Hook_OnPreAction     = 46;   // Trait, Perk
  Hook_OnPostAction    = 47;   // Trait, Perk
  Hook_OnCanDualWield  = 48;   // Trait
  Hook_OnCanMaxDamage  = 49;   // Trait, Perk

  Hook_getDamageBonus  = 50; // Trait, Perk
  Hook_getToHitBonus   = 51; // Trait, Perk
  Hook_getShotsBonus   = 52; // Trait, Perk
  Hook_getFireCostBonus= 53; // Trait, Perk
  Hook_getDefenceBonus = 54; // Perk
  Hook_getDodgeBonus   = 55; // Trait, Perk
  Hook_getMoveBonus    = 56; // Perk
  Hook_getBodyBonus    = 57; // Trait, Perk
  Hook_getResistBonus  = 58; // Trait, Perk
  Hook_getDamageMul    = 59; // Trait, Perk
  Hook_getFireCostMul  = 60; // Trait, Perk
  Hook_getAmmoCostMul  = 61; // Trait, Perk
  Hook_getReloadCostMul= 62; // Trait, Perk
  Hook_getGibMul       = 63; // Trait, Perk
  Hook_OnUnequipCheck  = 64; // Item, Perk
  Hook_OnDrop          = 65; // Perk (item)
  Hook_OnCanAct        = 66; // Being
  Hook_OnShort         = 67; // Perk

  HookAmount           = 68;

const AllHooks      : TFlags = [ 0..HookAmount-1 ];

var   BeingHooks       : TFlags;
      ItemHooks        : TFlags;
      FullInvHooks     : TFlags;
      NoInventoryHooks : TFlags;
      GlobalHooks      : TFlags;
      ModuleHooks      : TFlags;


const HookNames : array[ 0..HookAmount-1 ] of AnsiString = (
      'OnCreate', 'OnAction', 'OnAttacked', 'OnUseActive', 'OnDie', 'OnDieCheck',
      'OnPickup','OnPickupCheck','OnUse','OnUseCheck',
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
ItemHooks    := [ Hook_OnCreate, Hook_OnPickup,
  Hook_OnEquip, Hook_OnUnequip,
  Hook_OnAct, Hook_OnDestroy, Hook_OnDescribe, Hook_OnPickupCheck,
  Hook_OnUnequipCheck ];
GlobalHooks  := [ Hook_OnCreate, Hook_OnEnterLevel, Hook_OnExitLevel, Hook_OnTick,
  Hook_OnLoad, Hook_OnLoaded, Hook_OnUnLoad, Hook_OnCreatePlayer, Hook_OnLevelUp,
  Hook_OnPreLevelUp, Hook_OnWinGame, Hook_OnCreateEpisode,
  Hook_OnIntro, Hook_OnGenerate ];
ModuleHooks  := [ Hook_OnLoad ];

end.
