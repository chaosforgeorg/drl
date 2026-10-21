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
  // Prototype hooks
  Hook_OnCreate         = 0;  // being, item
  Hook_OnAction         = 1;  // being (AI dispatch); also a perk hook
  Hook_OnAttacked       = 2;  // being (AI dispatch)

  // Session hooks
  Hook_OnLoad           = 3;  // module
  Hook_OnStartGame      = 4;  // module
  Hook_OnCreateWorld    = 5;  // module, challenge
  Hook_OnCreatePlayer   = 6;  // module, challenge
  Hook_OnCreateLevel    = 7;  // module, challenge
  Hook_OnWinGame        = 8;  // module, challenge

  // Perk hooks; comments name the owners the perk can be attached to
  Hook_OnAdd            = 9;  // level, being, item
  Hook_OnRemove         = 10; // level, being, item
  Hook_OnTick           = 11; // level, being, item
  Hook_OnTick10         = 12; // level, being, item
  Hook_OnPreAction      = 13; // being, item
  Hook_OnPostAction     = 14; // being, item
  Hook_OnPostMove       = 15; // being, item
  Hook_OnAct            = 16; // being, item
  Hook_OnCanAct         = 17; // being
  Hook_OnUseActive      = 18; // player
  Hook_OnActiveUsed     = 19; // player
  Hook_OnFire           = 20; // being, item
  Hook_OnFired          = 21; // being, item
  Hook_OnAltFire        = 22; // item
  Hook_OnHitBeing       = 23; // item
  Hook_OnDamage         = 24; // being, item
  Hook_OnReceiveDamage  = 25; // being, item
  Hook_OnDamageReceived = 26; // being, item
  Hook_OnCanMaxDamage   = 27; // being, item
  Hook_OnCanDualWield   = 28; // player
  Hook_OnKill           = 29; // level, being, item
  Hook_OnKillAll        = 30; // level
  Hook_OnDieCheck       = 31; // being, item
  Hook_OnDie            = 32; // being (except player)
  Hook_OnPickupCheck    = 33; // being, item
  Hook_OnPickup         = 34; // being, item
  Hook_OnDrop           = 35; // item
  Hook_OnEquipCheck     = 36; // item
  Hook_OnEquip          = 37; // item
  Hook_OnUnequipCheck   = 38; // item
  Hook_OnUnequip        = 39; // item
  Hook_OnUseCheck       = 40; // being, item
  Hook_OnUse            = 41; // item
  Hook_OnPreReload      = 42; // item
  Hook_OnReload         = 43; // item
  Hook_OnAltReload      = 44; // item
  Hook_OnDestroy        = 45; // item
  Hook_OnEnter          = 46; // item (separate from cell OnEnter)
  Hook_OnEnterLevel     = 47; // level, player, item
  Hook_OnExitLevel      = 48; // level, player, item
  Hook_OnCreateBeing    = 49; // level
  Hook_OnNuked          = 50; // level
  Hook_OnPreLevelUp     = 51; // player
  Hook_OnLevelUp        = 52; // player, item

  // Perk getters
  Hook_getDamageBonus   = 53; // being, item
  Hook_getToHitBonus    = 54; // being, item
  Hook_getShotsBonus    = 55; // being, item
  Hook_getFireCostBonus = 56; // being, item
  Hook_getDefenceBonus  = 57; // being, item
  Hook_getDodgeBonus    = 58; // being, item
  Hook_getMoveBonus     = 59; // being, item
  Hook_getBodyBonus     = 60; // being, item
  Hook_getResistBonus   = 61; // being, item
  Hook_getDamageMul     = 62; // being, item
  Hook_getFireCostMul   = 63; // being, item
  Hook_getAmmoCostMul   = 64; // being, item
  Hook_getReloadCostMul = 65; // being, item
  Hook_getGibMul        = 66; // being, item
  Hook_getGroundDesc    = 67; // item
  Hook_getLabel         = 68; // level, being, item
  Hook_getDescription   = 69; // level, being, item

  HookAmount            = 70;

const AllHooks         : TFlags = [ 0..HookAmount-1 ];
      // Prototype hooks of beings; items call OnCreate by name.
      BeingHooks       : TFlags = [ Hook_OnCreate..Hook_OnAttacked ];
      PerkHooks        : TFlags = [ Hook_OnAction, Hook_OnAdd..HookAmount-1 ];
      // Core module and challenge functions.
      SessionHooks     : TFlags = [ Hook_OnStartGame..Hook_OnWinGame ];
      ChallengeHooks   : TFlags = [ Hook_OnCreateWorld..Hook_OnWinGame ];

const HookNames : array[ 0..HookAmount-1 ] of AnsiString = (
      // Prototype hooks
      'OnCreate', 'OnAction', 'OnAttacked',
      // Session hooks
      'OnLoad', 'OnStartGame', 'OnCreateWorld', 'OnCreatePlayer', 'OnCreateLevel', 'OnWinGame',
      // Perk hooks
      'OnAdd', 'OnRemove', 'OnTick', 'OnTick10',
      'OnPreAction', 'OnPostAction', 'OnPostMove', 'OnAct', 'OnCanAct',
      'OnUseActive', 'OnActiveUsed',
      'OnFire', 'OnFired', 'OnAltFire', 'OnHitBeing',
      'OnDamage', 'OnReceiveDamage', 'OnDamageReceived', 'OnCanMaxDamage', 'OnCanDualWield',
      'OnKill', 'OnKillAll', 'OnDieCheck', 'OnDie',
      'OnPickupCheck', 'OnPickup', 'OnDrop',
      'OnEquipCheck', 'OnEquip', 'OnUnequipCheck', 'OnUnequip',
      'OnUseCheck', 'OnUse', 'OnPreReload', 'OnReload', 'OnAltReload', 'OnDestroy', 'OnEnter',
      'OnEnterLevel', 'OnExitLevel', 'OnCreateBeing', 'OnNuked',
      'OnPreLevelUp', 'OnLevelUp',
      // Perk getters
      'getDamageBonus', 'getToHitBonus', 'getShotsBonus', 'getFireCostBonus',
      'getDefenceBonus', 'getDodgeBonus', 'getMoveBonus', 'getBodyBonus', 'getResistBonus',
      'getDamageMul', 'getFireCostMul', 'getAmmoCostMul', 'getReloadCostMul', 'getGibMul',
      'getGroundDesc', 'getLabel', 'getDescription'
      );

function LoadHooks( aLua : TLua; const aTable : array of Const; aHooks : TFlags ) : TFlags;
function LoadCallbacks( aLua : TLua; aTable : TLuaTable ) : TFlags;

implementation

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

end.
