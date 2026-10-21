{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlhooks;
interface
uses vutil, vlua, dfdata;

const
  Hook_OnCreate        = 0;   // Being and Item
  Hook_OnAction        = 1;   // Being
  Hook_OnAttacked      = 2;   // Being
  Hook_OnUseActive     = 3;   // Perk (player)
  Hook_OnDie           = 4;   // Perk (being)
  Hook_OnDieCheck      = 5;   // Perk (being, item)
  Hook_OnPickup        = 6;   // Perk (being, item)
  Hook_OnPickupCheck   = 7;   // Perk (item)
  Hook_OnUse           = 8;   // Perk (item)
  Hook_OnUseCheck      = 9;   // Perk (item)
  Hook_OnAltFire       = 10;  // Perk (item)
  Hook_OnAltReload     = 11;  // Perk (item)
  Hook_OnEquip         = 12;  // Perk (item)
  Hook_OnUnequip       = 13;  // Perk (item)
  Hook_OnAdd           = 14;  // Perk
  Hook_OnRemove        = 15;  // Perk
  Hook_OnTick10        = 16;  // Perk
  Hook_OnKill          = 17;  // Perk (item, being, level)
  Hook_OnKillAll       = 18;  // Perk (level)
  Hook_OnHitBeing      = 19;  // Perk (item)
  Hook_OnReload        = 20;  // Perk (item)
  Hook_getGroundDesc   = 21;  // Perk (item)
  Hook_OnEquipCheck    = 22;  // Perk (item)
  Hook_OnAct           = 23;  // Perk (being, item)
  Hook_OnDestroy       = 24;  // Perk (item)
  Hook_OnEnter         = 25;  // Perk (item; separate from cell OnEnter)
  Hook_OnEnterLevel    = 26;  // Perk (level, player, item)
  Hook_OnFire          = 27;  // Perk
  Hook_OnFired         = 28;  // Perk
  Hook_OnExitLevel     = 29;  // Perk (level, player, item)
  Hook_OnTick          = 30;  // Perk (level, being, item)
  Hook_OnNuked         = 31;  // Perk (level)
  Hook_OnLoad          = 32;  // Module
  Hook_OnStartGame     = 33;  // Module
  Hook_OnCreateBeing   = 34;  // Perk (level)
  Hook_OnCreatePlayer  = 35;  // Module, Challenge
  Hook_OnLevelUp       = 36;  // Perk (player)
  Hook_OnPreLevelUp    = 37;  // Perk (player)
  Hook_OnWinGame       = 38;  // Module, Challenge
  Hook_OnCreateWorld   = 39;  // Module, Challenge
  Hook_OnActiveUsed    = 40;  // Perk (player)
  // Slot 41 is unused.

  // TODO: merge with above
  Hook_OnPostMove      = 42;   // Perk
  Hook_OnPreReload     = 43;   // Perk (item)
  Hook_OnDamage        = 44;   // Perk
  Hook_OnReceiveDamage = 45;   // Perk
  Hook_OnPreAction     = 46;   // Perk
  Hook_OnPostAction    = 47;   // Perk
  Hook_OnCanDualWield  = 48;   // Perk (player)
  Hook_OnCanMaxDamage  = 49;   // Perk

  Hook_getDamageBonus  = 50; // Perk
  Hook_getToHitBonus   = 51; // Perk
  Hook_getShotsBonus   = 52; // Perk
  Hook_getFireCostBonus= 53; // Perk
  Hook_getDefenceBonus = 54; // Perk
  Hook_getDodgeBonus   = 55; // Perk
  Hook_getMoveBonus    = 56; // Perk
  Hook_getBodyBonus    = 57; // Perk
  Hook_getResistBonus  = 58; // Perk
  Hook_getDamageMul    = 59; // Perk
  Hook_getFireCostMul  = 60; // Perk
  Hook_getAmmoCostMul  = 61; // Perk
  Hook_getReloadCostMul= 62; // Perk
  Hook_getGibMul       = 63; // Perk
  Hook_OnUnequipCheck  = 64;  // Perk (item)
  Hook_OnDrop          = 65; // Perk (item)
  Hook_OnCanAct        = 66; // Perk (being)
  Hook_getLabel        = 67; // Perk
  Hook_getDescription  = 68; // Perk
  Hook_OnCreateLevel   = 69; // Module, Challenge
  Hook_OnDamageReceived= 70; // Perk
  Hook_OnBeingDeath    = 71; // Module (core module, after a being's death is accepted)

  HookAmount           = 72;

const AllHooks      : TFlags = [ 0..HookAmount-1 ] - [ 41 ];

var   BeingHooks       : TFlags;
      FullInvHooks     : TFlags;
      NoInventoryHooks : TFlags;
      SessionHooks     : TFlags;
      ChallengeHooks   : TFlags;
      ModuleLoadHooks  : TFlags;
      // Core module hooks entities raise through TDRLLua.CallCoreHook.
      CoreEntityHooks  : TFlags;


const HookNames : array[ 0..HookAmount-1 ] of AnsiString = (
      'OnCreate', 'OnAction', 'OnAttacked', 'OnUseActive', 'OnDie', 'OnDieCheck',
      'OnPickup','OnPickupCheck','OnUse','OnUseCheck',
      'OnAltFire', 'OnAltReload', 'OnEquip', 'OnUnequip', 'OnAdd', 'OnRemove', 'OnTick10', 'OnKill', 'OnKillAll',
      'OnHitBeing', 'OnReload', 'getGroundDesc', 'OnEquipCheck', 'OnAct', 'OnDestroy', 'OnEnter', 'OnEnterLevel',
      'OnFire', 'OnFired', 'OnExitLevel', 'OnTick', 'OnNuked',
      'OnLoad','OnStartGame','OnCreateBeing', 'OnCreatePlayer', 'OnLevelUp','OnPreLevelUp',
      'OnWinGame', 'OnCreateWorld', 'OnActiveUsed', '',

      'OnPostMove', 'OnPreReload', 'OnDamage', 'OnReceiveDamage', 'OnPreAction', 'OnPostAction',
      'OnCanDualWield', 'OnCanMaxDamage',

      'getDamageBonus', 'getToHitBonus', 'getShotsBonus', 'getFireCostBonus',
      'getDefenceBonus', 'getDodgeBonus', 'getMoveBonus', 'getBodyBonus', 'getResistBonus',
      'getDamageMul', 'getFireCostMul', 'getAmmoCostMul', 'getReloadCostMul',
      'getGibMul',
      'OnUnequipCheck',
      'OnDrop', 'OnCanAct',
      'getLabel', 'getDescription', 'OnCreateLevel', 'OnDamageReceived', 'OnBeingDeath'
      );

function LoadHooks( aLua : TLua; const aTable : array of Const ) : TFlags;
function LoadHooks( aLua : TLua; const aTable : array of Const; aHooks : TFlags ) : TFlags;
function LoadCallbacks( aLua : TLua; aTable : TLuaTable ) : TFlags;

implementation

function LoadHooks( aLua : TLua; const aTable : array of Const ) : TFlags;
begin
  Exit( LoadHooks( aLua, aTable, AllHooks ) );
end;

function LoadHooks( aLua : TLua; const aTable : array of Const; aHooks : TFlags ) : TFlags;
var iHook    : Byte;
    i, iSize : DWord;
begin
  with aLua.GetTable( aTable ) do
  try
    LoadHooks := [];
    for iHook in aHooks do
      if isFunction(HookNames[iHook]) then
        Include(LoadHooks,iHook);
    iSize := aLua.GetTableSize( ['core','callbacks'] );
    if iSize > 0 then
      for i := 1 to iSize do
        if isFunction( aLua.Get( ['core','callbacks', i] ) ) then
          Include( LoadHooks, i + 200 );
  finally
    Free;
  end;
end;

function LoadCallbacks( aLua : TLua; aTable : TLuaTable ) : TFlags;
var i, iSize : DWord;
begin
  iSize := aLua.GetTableSize( ['core','callbacks'] );
  if iSize = 0 then Exit( [] );
  LoadCallbacks := [];
  for i := 1 to iSize do
    if aTable.isFunction( aLua.Get( ['core','callbacks', i] ) ) then
      Include( LoadCallbacks, i + 200 );
end;

initialization

// Prototype masks; perks load their hooks independently.
BeingHooks   := [ Hook_OnCreate, Hook_OnAction, Hook_OnAttacked ];
FullInvHooks := [ Hook_OnPreAction, Hook_OnPostAction, Hook_OnTick ];
NoInventoryHooks := [ Hook_OnPickup ];
SessionHooks := [ Hook_OnCreateLevel,
  Hook_OnStartGame, Hook_OnCreatePlayer,
  Hook_OnWinGame, Hook_OnCreateWorld ];
ChallengeHooks := [ Hook_OnCreateLevel, Hook_OnCreatePlayer,
  Hook_OnWinGame, Hook_OnCreateWorld ];
ModuleLoadHooks := [ Hook_OnLoad ];
CoreEntityHooks := [ Hook_OnBeingDeath ];

end.
