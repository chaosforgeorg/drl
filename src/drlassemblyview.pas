{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlassemblyview;
interface
uses vutil, viotypes, vlua, dfdata, dfhof;

type TAssemblyView = class( TIOLayer )
  constructor Create( aLua : TLua; aHOF : THOF );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsModal : Boolean; override;
  destructor Destroy; override;
protected
  procedure ReadAssemblies;
protected
  FLua      : TLua;
  FHOF      : THOF;
  FSize     : TPoint;
  FContent  : TStringGArray;
end;

implementation

uses sysutils, vtig;

constructor TAssemblyView.Create( aLua : TLua; aHOF : THOF );
begin
  FLua := aLua;
  FHOF := aHOF;
  VTIG_EventClear;
  FSize      := Point( 80, 25 );
end;

procedure TAssemblyView.Update( aDTime : Integer; aActive : Boolean );
var iString : Ansistring;
begin
  if FContent = nil then ReadAssemblies;
  VTIG_BeginWindow('Known assemblies', 'assembly_view', FSize );
  for iString in FContent do
    VTIG_Text( iString );
  VTIG_Scrollbar;
  VTIG_End('{l<{!{$input_up},{$input_down}}> scroll, <{!{$input_ok},{$input_escape}}> return}');
  if VTIG_EventCancel or VTIG_EventConfirm then
    FFinished := True;
end;


function TAssemblyView.IsModal : Boolean;
begin
  Exit( True );
end;

destructor TAssemblyView.Destroy;
begin
  FreeAndNil( FContent );
  inherited Destroy;
end;

procedure TAssemblyView.ReadAssemblies;
var iType, iFound, i    : DWord;
    iString, iID, iDesc : AnsiString;
const TypeName : array[0..2] of string = ('Basic','Advanced','Master');
begin
  if FContent = nil then FContent := TStringGArray.Create;
  FContent.Clear;
  if FLua.Defined(['mod_arrays','__counter']) then
    for iType := 0 to 2 do
    begin
      FContent.Push('{y'+TypeName[iType]+' assemblies}');
      FContent.Push('');
      for i := 1 to FLua.Get(['mod_arrays','__counter']) do
      if FLua.Get(['mod_arrays',i,'level']) = iType then
      begin
        iID    := FLua.Get(['mod_arrays',i,'id']);
        iFound := FHOF.GetCounted( 'assemblies','assembly', iID );
        if FLua.Get( [ 'player','__props', 'assemblies', iID ], 0 ) > 0 then Inc( iFound );
        if iFound = 0
          then if iType = 0
            then iString := '  {d'+FLua.Get(['mod_arrays',i,'name'])+' ({L-})}'
            else iString := '  {d  -- ? -- ({L-})}'
          else 
          begin 
            iString := '  {y'+FLua.Get(['mod_arrays',i,'name'])+' ({L'+IntToStr(iFound)+'})}'
                       + ' - {l' + FLua.Get(['mod_arrays',i,'request_desc'],'')+'}';
            iDesc := FLua.Get(['mod_arrays',i,'desc'],'');
            if iDesc <> '' then
              iString += #10'   {!*} '+iDesc;
          end;
        FContent.Push( iString );
        FContent.Push( '' );
      end;
      if iType <> 2 then FContent.Push('');
    end;
end;


end.

