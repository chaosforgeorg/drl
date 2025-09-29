{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlinventory;
interface
uses SysUtils,
     vnode,
     dfitem, dfthing, dfdata,
     drlhooks;

type
  TItemList      = array[TItemSlot] of TItem;
  TEquipmentList = array[TEqSlot] of TItem;

TInventory = class;

TInventoryEnumerator = specialize TGNodeEnumerator< TItem >;

TInventory = class( TVObject )
       constructor Create( aOwner : TThing );
       procedure Sort( var aList : TItemList );
       function  Size : byte;
       procedure Add( aItem : TItem );
       function  Find( const aID : Ansistring ) : TItem;
       function  SeekStack( aID : DWord ) : TItem;
       function  CountAmount( aID : DWord ) : Integer;
       function  AddStack( aID : DWord; aCount : Integer ) : Integer;
       function  isFull : boolean;
       procedure RawSetSlot( aIndex : TEqSlot; aItem : TItem ); inline;
       procedure EqSwap( aSlot1, aSlot2 : TEqSlot );
       procedure EqTick;
       procedure ClearSlot( aItem : TItem );
       function DoWear( aItem : TItem ) : Boolean;
       // no checking if slot fits!
       function DoWear( aItem : TItem; aSlot : TEqSlot ) : Boolean;
       function Wear( aItem : TItem ) : Boolean;
       function Contains( aItem : TItem ) : Boolean;
       function FindSlot( aItem : TItem ) : TEqSlot;
       function GetEnumerator : TInventoryEnumerator;
       function Equipped( aItem : TItem ) : Boolean;
       destructor Destroy; override;
       procedure setSlot( aIndex : TEqSlot; aItem : TItem ); inline;
     private
       FOwner  : TThing;
       FChosen : TItem;
       FSlots  : TEquipmentList;
       function  getSlot( aIndex : TEqSlot ) : TItem; inline;
     public
       property Slot[ aIndex : TEqSlot ] : TItem read getSlot;
     end;

implementation

uses vmath, vluasystem, drlio, drlkeybindings, dfplayer;

{ TInventoryEnumerator }

function TInventory.Wear( aItem : TItem ) : Boolean;
begin
  if aItem = nil then Exit( False );
  if not Contains( aItem ) then Exit( False );
  if not aItem.isWearable then Exit( False );
  setSlot( aItem.eqSlot, aItem );
  Exit( True )
end;

function TInventory.getSlot(aIndex: TEqSlot): TItem; inline;
begin
  Exit(FSlots[aIndex]);
end;

procedure TInventory.setSlot( aIndex: TEqSlot; aItem: TItem); inline;
begin
  if FSlots[aIndex] = aItem then Exit;
  if FSlots[aIndex] <> nil  then FSlots[aIndex].CallHook( Hook_OnRemove, [FOwner] );
  FSlots[aIndex] := nil;
  if aItem <> nil then aItem.CallHook( Hook_OnEquip, [FOwner] );
  if aItem <> nil then FOwner.Add( aItem );
  FSlots[aIndex] := aItem;
end;

procedure TInventory.RawSetSlot( aIndex: TEqSlot; aItem: TItem ); inline;
begin
  if aItem <> nil then FOwner.Add( aItem );
  FSlots[aIndex] := aItem;
end;

constructor TInventory.Create( aOwner : TThing );
var iSlot : TEqSlot;
begin
  FChosen := nil;
  FOwner  := aOwner;
  for iSlot in TEqSlot do
    FSlots[iSlot] := nil;
end;

function TInventory.Size : byte;
var iSlot : TEqSlot;
begin
  Size := FOwner.ChildCount;
  for iSlot in TEqSlot do
    if FSlots[iSlot] <> nil then
      Dec(Size);
end;

procedure TInventory.Add( aItem : TItem );
begin
  if aItem = nil then Exit;
  if isFull then raise EItemException.Create('Inventory full at add!');
  FOwner.Add( aItem );
end;

destructor TInventory.Destroy;
begin
end;

procedure   TInventory.Sort( var aList : TItemList );
var iCount  : Integer;
    iCount2 : Integer;
begin
  for iCount := Low(TItemSlot) to High(TItemSlot)-Low(TItemSlot) do
    for iCount2 := Low(TItemSlot) to High(TItemSlot)-iCount do
      if TItem.Compare(aList[iCount2],aList[iCount2+1]) then
        SwapItem(aList[iCount2],aList[iCount2+1]);
end;

function TInventory.SeekStack( aID : DWord ) : TItem;
var iItem  : TItem;
    iCount : Integer;
begin
  SeekStack := nil;
  iCount    := 99999;

  for iItem in Self do
    if iItem.NID = aID then
      if iItem.Amount <= iCount then
      begin
        SeekStack := iItem;
        iCount    := iItem.Amount;
      end;
end;

function TInventory.CountAmount( aID : DWord ) : Integer;
var iItem : TItem;
begin
  CountAmount := 0;
  if aID = 0 then Exit( 0 );
  for iItem in Self do
    if iItem.NID = aID then
      CountAmount += iItem.Amount;
end;

function TInventory.Find( const aID : Ansistring ) : TItem;
var iItem : TItem;
begin
  for iItem in Self do
    if iItem.ID = aID then
      Exit( iItem );
  Exit( nil );
end;


function TInventory.AddStack( aID : DWord; aCount : Integer ) : Integer;
var iAmount : Integer;
    iItem   : TItem;
    iMax    : Integer;
begin
  if LuaSystem.Defined([ CoreModuleID, 'GetItemMax' ])
    then iMax := LuaSystem.ProtectedCall([ CoreModuleID, 'GetItemMax' ], [aID] )
    else iMax := LuaSystem.Get(['items',aID,'max']);
  iItem := SeekStack(aID);

  if iItem <> nil then
  begin
    iAmount      := Min(aCount,iMax-iItem.Amount);
    aCount       -= iAmount;
    iItem.Amount := iItem.Amount + iAmount;
  end;
  if aCount = 0 then Exit(0);

  repeat
    if isFull then Exit(aCount);

    iAmount      := Min(aCount,iMax);
    iItem        := TItem.Create(aID);
    iItem.Amount := iAmount;
    Add(iItem);
    aCount -= iAmount;
  until aCount = 0;
  Exit(0);
end;

function TInventory.isFull: boolean;
var iSize : Integer;
begin
  iSize := Size;
  if FOwner = Player then Exit( iSize >= Player.InventorySize );
  Exit(iSize >= High(TItemSlot));
end;


procedure TInventory.EqSwap(aSlot1, aSlot2: TEqSlot);
var iItem : TItem;
begin
  iItem          := FSlots[aSlot1];
  FSlots[aSlot1] := FSlots[aSlot2];
  FSlots[aSlot2] := iItem;
end;

procedure TInventory.EqTick;
var iSlot : TEqSlot;
begin
  for iSlot in TEqSlot do
    if FSlots[iSlot] <> nil then
      FSlots[iSlot].Tick(FOwner);
end;

procedure TInventory.ClearSlot ( aItem : TItem ) ;
var iSlot : TEqSlot;
begin
  for iSlot in TEqSlot do
    if FSlots[iSlot] = aItem then
      setSlot( iSlot, nil );
end;

function TInventory.DoWear ( aItem : TItem ) : Boolean;
var iItem : TItem;
begin
  if aItem = nil then Exit( False );
  if aItem.Hooks[ Hook_OnEquipCheck ] then
    if not aItem.CallHookCheck( Hook_OnEquipCheck,[FOwner] ) then Exit( False );
  iItem := FSlots[aItem.eqSlot];
  if (iItem <> nil) and iItem.Flags[ IF_CURSED ] then begin IO.Msg('You can''t, your '+iItem.Name+' is cursed!'); Exit( False ); end;
  IO.Msg('You wear/wield : '+aItem.GetName(false));
  Wear( aItem );
  Exit( True );
end;

function TInventory.DoWear ( aItem : TItem; aSlot : TEqSlot ) : Boolean;
var iItem : TItem;
begin
  if aItem = nil then Exit( False );
  if aItem.Hooks[ Hook_OnEquipCheck ] then
    if not aItem.CallHookCheck( Hook_OnEquipCheck,[FOwner] ) then Exit( False );
  iItem := FSlots[aSlot];
  if (iItem <> nil) and iItem.Flags[ IF_CURSED ] then begin IO.Msg('You can''t, your '+iItem.Name+' is cursed!'); Exit( False ); end;
  IO.Msg('You wear/wield : '+aItem.GetName(false));
  setSlot( aSlot, aItem );
  Exit( True );
end;

function TInventory.Contains( aItem : TItem ) : Boolean;
begin
  Exit( aItem.Parent = FOwner );
end;

function TInventory.FindSlot ( aItem : TItem ) : TEqSlot;
var iSlot : TEqSlot;
begin
  for iSlot in TEqSlot do
    if FSlots[iSlot] = aItem then Exit( iSlot );
  Exit( TEqSlot(0) );
end;

function TInventory.GetEnumerator : TInventoryEnumerator;
begin
  GetEnumerator.Create(FOwner);
end;

function TInventory.Equipped ( aItem : TItem ) : Boolean;
var iSlot : TEqSlot;
begin
  for iSlot in TEqSlot do
    if FSlots[ iSlot ] = aItem then
      Exit( True );
  Exit( False );
end;

end.

