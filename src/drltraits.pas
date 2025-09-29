{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drltraits;
interface
uses classes, sysutils, vutil, vnode, dfdata, drlhooks;

const   MAXTRAITS  = 50;
        MAXKLASS   = 10;

type TTraits = class( TVObject )
  constructor Create;
  constructor CreateFromStream( aStream : TStream ); override;
  procedure WriteToStream( aStream : TStream ); override;
  function CallHook( aHook : Byte; const aParams : array of Const ) : Boolean;
  function CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean;
  function CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean;
  function GetBonus( aHook : Byte; const aParams : array of Const ) : Integer;
  function GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
  function GetHistory : AnsiString;
  procedure Upgrade ( aKlass : Byte; aTrait : Byte ) ;
  function CanPick( aKlass : Byte; aTrait : Byte; aCharLevel : Byte ): Boolean;
  class function CanPickInitially( aTrait : Byte; aKlassID : Byte ) : Boolean; static;
protected
  function Get( aTrait : Byte ) : Byte;
protected
  FBlocked  : array[1..MAXTRAITS]      of Boolean;
  FOrder    : array[1..MaxPlayerLevel] of Byte;
  FValues   : array[1..MAXTRAITS]      of Byte;
  FHooks    : array[1..MAXTRAITS]      of TFlags;
  FHookMask : TFlags;
  FCount    : Byte;
  FMaster   : Byte;
public
  property Values[ aIndex : Byte ] : Byte read Get; default;
  property Master : Byte read FMaster;
end;

implementation

uses vluasystem, dfplayer;

function TTraits.CanPick( aKlass : Byte; aTrait : Byte; aCharLevel : Byte ): Boolean;
var iOther, iValue : DWord;
    iVariant : Variant;
    iTable   : TLuaTable;
    iReqLevel : Integer;
begin
  if FBlocked[ aTrait ] then Exit( False );
  if not LuaSystem.Defined(['traits',aTrait,'OnPick']) then Exit( False );

  with LuaSystem.GetTable(['klasses',aKlass,'trait',aTrait]) do
  try
    if (aCharLevel < 12) and (Self.FValues[ aTrait ] >= getInteger( 'max', 1 )) then Exit( False );
    iReqLevel := getInteger( 'reqlevel', 0 );
    if iReqLevel > 0 then iReqLevel += Self.FValues[ aTrait ] * 3;
    if aCharLevel < iReqLevel then Exit( False );
	
    if IsTable('blocks') then
    begin
      with GetTable('blocks') do
      try
        for iVariant in VariantValues do
          if Self.FValues[ Word(iVariant) ] >= 1 then Exit( False );
      finally
        Free;
      end;
    end;
	
    if IsTable('requires') then
    for iTable in ITables('requires') do
    begin
      iOther := iTable.GetValue( 1 );
      iValue := iTable.GetValue( 2 );
      if Self.FValues[ iOther ] < iValue then Exit( False );
    end;
  finally
    Free;
  end;
  Exit( True );
end;

procedure TTraits.Upgrade ( aKlass : Byte; aTrait : Byte ) ;
var i            : Byte;
    iMax, iMax12 : DWord;
    iMaster      : Boolean;
    iVariant     : Variant;
begin
  Inc( FValues[ aTrait ] );

  iMax    := 1;
  iMax12  := 1;
  iMaster := False;
  if aKlass > 0 then
    with LuaSystem.GetTable(['klasses',aKlass,'trait',aTrait]) do
    try
      iMax    := getInteger( 'max', 1 );
      iMax12  := getInteger( 'max_12', iMax );
      iMaster := getBoolean( 'master', False );
    finally
      Free;
    end;

  FHooks[ aTrait ] := LoadHooks( ['traits',aTrait] );
  FHookMask += FHooks[ aTrait ];

  if FValues[ aTrait ] >= iMax12 then
    FBlocked[ aTrait ] := True;

  if iMaster then
  begin
    for i := 1 to MAXTRAITS do
      if LuaSystem.Get(['klasses',aKlass,'trait',i,'master'], False ) then
        FBlocked[ i ] := True;
    FBlocked[ aTrait ] := FValues[ aTrait ] >= iMax;
    FMaster := aTrait;
  end;

  LuaSystem.ProtectedCall( [ 'traits',aTrait,'OnPick' ], [ Player, FValues[ aTrait ] ] );

  if aKlass = 0 then Exit;

  if (FValues[ aTrait ] = 1) and LuaSystem.Defined(['klasses',aKlass,'trait',aTrait,'blocks']) then
  begin
    with LuaSystem.GetTable(['klasses',aKlass,'trait',aTrait,'blocks']) do
    try
      for iVariant in VariantValues do
        FBlocked[ Word(iVariant) ] := True;
    finally
      Free;
    end;
  end;

  Inc( FCount );
  FOrder[ FCount ] := aTrait;
end;

class function TTraits.CanPickInitially(aTrait: Byte; aKlassID: Byte): Boolean;
begin
  CanPickInitially := True;
  if not LuaSystem.Defined(['traits',aTrait,'OnPick']) then Exit( False );

  // #5 ReqLevel
  with LuaSystem.GetTable(['klasses',aKlassID,'trait',aTrait]) do
  try
    if IsTable('requires') or (GetInteger('reqlevel',0) > 1) then CanPickInitially := False;
  finally
    Free;
  end;
end;

function TTraits.Get( aTrait : Byte ) : Byte;
begin
  Exit( FValues[ aTrait ] );
end;

constructor TTraits.Create;
var iCount : Byte;
begin
  inherited Create;
  for iCount := 1 to High(FBlocked) do FBlocked[iCount] := False;
  for iCount := 1 to High(FValues)  do FValues[iCount] := 0;
  for iCount := 1 to High(FOrder)   do FOrder[iCount] := 0;
  for iCount := 1 to High(FHooks)   do FHooks[iCount] := [];
  FCount  := 0;
  FMaster := 0;
  FHookMask := [];
end;

constructor TTraits.CreateFromStream( aStream : TStream );
begin
  inherited CreateFromStream( aStream );
  aStream.Read( FValues,   SizeOf( FValues ) );
  aStream.Read( FBlocked,  SizeOf( FBlocked ) );
  aStream.Read( FOrder,    SizeOf( FOrder ) );
  aStream.Read( FCount,    SizeOf( FCount ) );
  aStream.Read( FHooks,    SizeOf( FHooks ) );
  aStream.Read( FHookMask, SizeOf( FHookMask ) );
  aStream.Read( FMaster,   SizeOf( FMaster ) );
end;

procedure TTraits.WriteToStream( aStream : TStream );
begin
  inherited WriteToStream( aStream );
  aStream.Write( FValues,   SizeOf( FValues ) );
  aStream.Write( FBlocked,  SizeOf( FBlocked ) );
  aStream.Write( FOrder,    SizeOf( FOrder ) );
  aStream.Write( FCount,    SizeOf( FCount ) );
  aStream.Write( FHooks,    SizeOf( FHooks ) );
  aStream.Write( FHookMask, SizeOf( FHookMask ) );
  aStream.Write( FMaster,   SizeOf( FMaster ) );
end;

function TTraits.CallHook( aHook : Byte; const aParams : array of Const ) : Boolean;
var i : Integer;
begin
  CallHook := False;
  if not ( aHook in FHookMask ) then Exit;
  for i := 1 to High(FHooks) do
    if aHook in FHooks[i] then
    begin
      CallHook := True;
      LuaSystem.ProtectedCall( [ 'traits', i, HookNames[aHook] ], ConcatConstArray( [Player], aParams ) )
    end;
end;

function TTraits.CallHookCheck( aHook : Byte; const aParams : array of Const ) : Boolean;
var i : Integer;
begin
  if not ( aHook in FHookMask ) then Exit( True );
  for i := 1 to High(FHooks) do
    if aHook in FHooks[i] then
      if not LuaSystem.ProtectedCall( [ 'traits', i, HookNames[aHook] ], ConcatConstArray( [Player], aParams ) ) then
        Exit( False );
  Exit( True );
end;

function TTraits.CallHookCan( aHook : Byte; const aParams : array of Const ) : Boolean;
var i : Integer;
begin
  if not ( aHook in FHookMask ) then Exit( False );
  for i := 1 to High(FHooks) do
    if aHook in FHooks[i] then
      if LuaSystem.ProtectedCall( [ 'traits', i, HookNames[aHook] ], ConcatConstArray( [Player], aParams ) ) then
        Exit( True );
  Exit( False );
end;

function TTraits.GetBonus( aHook : Byte; const aParams : array of Const ) : Integer;
var i : Integer;
begin
  GetBonus := 0;
  if not ( aHook in FHookMask ) then Exit( 0 );
  for i := 1 to High(FHooks) do
    if aHook in FHooks[i] then
      GetBonus += LuaSystem.ProtectedCall( [ 'traits', i, HookNames[aHook] ], ConcatConstArray( [Player], aParams ) );
end;

function TTraits.GetBonusMul( aHook : Byte; const aParams : array of Const ) : Single;
var i : Integer;
begin
  GetBonusMul := 1.0;
  if not ( aHook in FHookMask ) then Exit( 1.0 );
  for i := 1 to High(FHooks) do
    if aHook in FHooks[i] then
      GetBonusMul *= LuaSystem.ProtectedCall( [ 'traits', i, HookNames[aHook] ], ConcatConstArray( [Player], aParams ) );
end;


function TTraits.GetHistory: AnsiString;
var iCount : Byte;
begin
  GetHistory := '';
  for iCount := 1 to High(FOrder) do
    if (FOrder[iCount] > 0) and (FOrder[iCount] <= High(FValues)) then
      GetHistory += LuaSystem.Get(['traits',FOrder[iCount],'abbr'], False )+'->';
end;

end.

