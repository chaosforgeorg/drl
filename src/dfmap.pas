{$INCLUDE drl.inc}
{
----------------------------------------------------
DFMAP.PAS -- Map data and handling for DRL
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit dfmap;
interface
uses vutil, vmath, dfdata;

type TCellHook  = (CellHook_OnEnter, CellHook_OnExit, CellHook_OnAct, CellHook_OnDescribe, CellHook_OnHazardQuery, CellHook_OnDestroy);
     TCellHooks = set of TCellHook;
const CellHooks : array[TCellHook] of string = ('OnEnter', 'OnExit', 'OnAct', 'OnDescribe', 'OnHazardQuery', 'OnDestroy');

type TMap = object
       Overlay  : array[ 1..MaxX, 1..MaxY ] of Byte;
       Rotation : array[ 1..MaxX, 1..MaxY ] of Byte;
       Style    : array[ 1..MaxX, 1..MaxY ] of Byte;
       Deco     : array[ 1..MaxX, 1..MaxY ] of Byte;
     end;

type TCell = class
  PicChr      : Char;
  PicLow      : Char;
  Sprite      : array[0..15] of TSprite;
  Deco        : array[1..16] of TSprite;
  BloodSprite : TSprite;
  LightColor  : array[0..15] of Byte;
  DarkColor   : Byte;
  BloodColor  : Byte;
  Desc        : AnsiString;
  BlDesc      : AnsiString;
  DR          : Byte;
  HP          : Byte;
  Flags       : TFlags;
  Hooks       : TCellHooks;
  MoveCost    : Single;
  bloodto     : AnsiString;
  destroyto   : AnsiString;
  raiseto     : AnsiString;
end;
            

type

{ TCells }

TCells = class
         public
           procedure RegisterCell( aCellNum : Byte );
           destructor Destroy; override;
         private
           FData     : array of TCell;
           FMaxCells : Byte;
           function getCell( aIndex : Byte ) : TCell;
         public
           property Cells[ aIndex : Byte ] : TCell read getCell; default;
           property Max : Byte read FMaxCells;
         end;

var Cells : TCells;

implementation

uses SysUtils, vluasystem, vdebug;

procedure TCells.RegisterCell( aCellNum : byte );
var iColorID : AnsiString;
    iHook    : TCellHook;
    iCell    : TCell;
    iTable   : TLuaTable;
    iSubTable: TLuaTable;
    iBase    : TSprite;
    iSprite  : TSprite;
    iSize, i : Integer;
begin
  if aCellNum >= High( FData ) then
  begin
    SetLength( FData, vmath.Max( High( FData ) * 2, 100 ) );
    FMaxCells := aCellNum;
  end;
  if aCellNum > FMaxCells then FMaxCells := aCellNum;

  iCell  := TCell.Create;
  iTable := LuaSystem.GetTable(['cells',aCellNum]);
  with iTable do
  try
    iColorID := getString('id');
    if IsString('color_id') then iColorID := getString('color_id');

    iCell.Hooks := [];
    for iHook in TCellHooks do
      if isFunction( CellHooks[ iHook ] ) then
        Include( iCell.Hooks,iHook );

    iCell.PicChr    := getChar('ascii');
    iCell.PicLow    := getChar('asciilow');
    iCell.DarkColor := getInteger('color_dark');

    FillChar( iCell.LightColor, SizeOf(iCell.LightColor), 0 );
    if iTable.IsTable('color') then
    begin
      iSize := iTable.GetTableSize( 'color' );
      if iSize > High( iCell.LightColor ) then
        raise Exception.Create( 'Maximum number of ASCII color styles reached!' );

      with GetTable( 'color' ) do
      try
        for i := 1 to iSize do
          if IsNumber( i ) then
            iCell.LightColor[i-1] := GetValue( i )
      finally
        Free;
      end
    end
    else
      iCell.LightColor[0]:= getInteger('color');

    iCell.BloodColor:= getInteger('blcolor');
    iCell.Desc      := getString('name');
    iCell.BlDesc    := getString('blname');
    iCell.DR        := getInteger('armor');
    iCell.HP        := getInteger('hp');
    iCell.Flags     := getFlags('flags');
    iCell.bloodto   := getString('bloodto');
    iCell.destroyto := getString('destroyto');
    iCell.raiseto   := getString('raiseto');
    iCell.MoveCost  := getFloat('move_cost', 1.0 );
    FillChar( iCell.Sprite,      SizeOf(iCell.Sprite),      0 );
    FillChar( iCell.BloodSprite, SizeOf(iCell.BloodSprite), 0 );
    FillChar( iCell.Deco,        SizeOf(iCell.Deco),        0 );
    Initialize( iBase );
    FillChar( iBase,             SizeOf(iBase),             0 );
    ReadSprite( iTable, iBase );
    if iTable.IsTable( 'sprite' ) then
    begin
      iSize := iTable.GetTableSize( 'sprite' );
      if iSize > High( iCell.Sprite ) then
        raise Exception.Create( 'Maximum number of sprite styles reached!' );
      if iSize > 0 then
      with GetTable( 'sprite' ) do
      try
        for i := 1 to iSize do
        begin
          iSprite := iBase;
          if IsNumber( i ) then
            iSprite.SpriteID[0] := GetValue( i )
          else
          begin
            iSubTable := iTable.GetTable( ['sprite',i] );
            ReadSprite( iSubTable, iSprite );
            iSubTable.Free;
          end;
          iCell.Sprite[i - 1] := iSprite;
        end;
      finally
        Free;
      end;
    end
    else
      iCell.Sprite[0] := iBase;
    iCell.BloodSprite.SpriteID[0] := getInteger('blsprite',0);
    if iTable.IsTable( 'deco' ) then
    begin
      iSize := iTable.GetTableSize( 'deco' );
      if iSize > High( iCell.Deco ) then
        raise Exception.Create( 'Maximum number of sprite decorations reached!' );
      if iSize > 0 then
      with GetTable( 'deco' ) do
      try
        for i := 1 to iSize do
        begin
          iSprite := iCell.Deco[ i ];
          if IsNumber( i ) then
            iSprite.SpriteID[0] := GetValue( i )
          else
          begin
            iSubTable := iTable.GetTable( ['deco',i] );
            ReadSprite( iSubTable, iSprite );
            iSubTable.Free;
          end;
          iCell.Deco[ i ] := iSprite;
        end;
      finally
        Free;
      end;
    end;

  finally
    Free;
  end;

  if (not Option_HighASCII) then iCell.PicChr := iCell.PicLow;

  if ColorOverrides.Exists(iColorID+'_light') then
    iCell.LightColor[0] := ColorOverrides[iColorID+'_light'];
  if ColorOverrides.Exists(iColorID+'_dark') then
    iCell.DarkColor:= ColorOverrides[iColorID+'_dark'];

  FData[aCellNum] := iCell;
end;

function TCells.getCell( aIndex : Byte ) : TCell;
begin
  Exit( FData[ aIndex ] );
end;

destructor TCells.Destroy;
var iCell : TCell;
begin
  for iCell in FData do
    iCell.Free;
end;


end.
