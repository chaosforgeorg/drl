{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit dfhof;
interface
uses Classes, DOM, vnode, vxml, vxmldata, dfdata, vuitypes;

const MaxHofEntries = 500;
      MaxID         = 1023;

//     CRC_PRIME_099 = 62189;
     
const PlayerFile = 'player.wad';
      ScoreFile  = 'score.wad';

{ THOF }

type THOF = object
  procedure Init;
  procedure Add( const Name : AnsiString; aScore : LongInt; const aKillerID : AnsiString; Level, DLev : Word; nChal, nAbbr : AnsiString );
  function RankCheck( out aResult : THOFRank ) : Boolean;
  function GetPagedPlayerReport : TPagedReport;
  function GetPagedScoreReport : TPagedReport;
  procedure Done;

  function GetCount( aXPathQuery : string; aContext : TDOMNode = nil ) : DWord;
  function GetChildCount( aXPathQuery : string; aContext : TDOMNode = nil ) : DWord;

  function AddCounted( const aRootID, aLeafID, aElementID : AnsiString; aAmount : DWord = 1 ) : Boolean;
  function GetCounted( const aRootID, aLeafID, aElementID : AnsiString ) : DWord;
  function GetRank( const aRankName : Ansistring ) : Integer;
private
  FScore      : TScoreFile;
  FPlayerInfo : TVXMLDataFile;

  procedure SetRank( const aRankName: Ansistring; aValue : Integer );
  procedure Save; overload;
  // TODO : remove
  function GetBadgeCount( aBadgeLevel : DWord ) : DWord;

  function GetRankReqCount( const aRankArray : AnsiString; aRankLevel : DWord ) : DWord;
  function GetRankReqDescription( const aRankArray : AnsiString; aRankLevel : DWord; aRankReq :DWord ) : AnsiString;
  function IsRankReqCompleted( const aRankArray : AnsiString; aRankLevel : DWord; aRankReq : DWord ) : Boolean;
  function GetRankReqCurrent( const aRankArray : AnsiString; aRankLevel : DWord; aRankReq : DWord ) : DWord;
  function GetRankReqTotal( const aRankArray : AnsiString; aRankLevel : DWord; aRankReq : DWord ) : DWord;

  function CheckRank( const aRankArray : Ansistring; aCurrent : Integer ) : boolean;

  function GetDiffKills( aDiff : AnsiString ) : string;
  function GetDiffScore( aDiff : AnsiString ) : string;
  function GetDiffDeaths( aDiff : AnsiString ) : string;

  function GetChalDesc(Chal : Byte; aDiffLevel : AnsiString; aVictoryType: AnsiString) : string;

  function GetCountStr( aXPathQuery : string; aContext : TDOMNode = nil ) : String;
  function IncreaseXMLCount( aContainer : TDOMElement; const aElementID : string; const aID : string; aAmount : DWord ) : TDOMElement;
  function IncreaseXMLCount( aContainer : TDOMElement; const aElementID : string; aAmount : DWord ) : TDOMElement;

  function GameResultBetter( const ResultOld, ResultNew : String ) : boolean;
  function GameResultAtLeast( const ResultAtLeast, ResultNew : String ) : boolean;
  procedure HandleAchievements( const aRankArray : Ansistring; aRankLevel : Integer );
end;

var HOF : THOF;

implementation

uses math, sysutils, strutils, variants,
     vluasystem, vluatable, vdebug, vtig, vutil, vrltools,
     drlbase, dfplayer;

const HOFOpen : Boolean = False;

function THOF.GetBadgeCount( aBadgeLevel : DWord ): DWord;
var iCount   : DWord;
    iCounter : DWord;
    iBadges  : LongInt;
begin
  if aBadgeLevel = 0 then Exit( 0 );
  iBadges := LuaSystem.Get(['badges','__counter']);
  iCount := 0;
  for iCounter := 1 to iBadges do
  begin
    if (LuaSystem.Get(['badges',iCounter,'level']) = aBadgeLevel) and
       (GetCounted( 'badges', 'badge', LuaSystem.Get(['badges',iCounter,'id']) ) > 0) then
      Inc( iCount );
  end;
  Exit( iCount );
end;

function THOF.GetDiffScore( aDiff : AnsiString ) : string;
var iMax     : string;
    iElement : TDOMElement;
    iWins    : string;
    iPlural  : string;
begin
  iElement := FPlayerInfo.XML.GetElement('player/games/game[@id="'+aDiff+'"]');
  if iElement = nil then Exit('none');
  iMax     := iElement.GetAttribute('max');
  if iMax = '' then Exit('none');
  if Pos( ':', iMax ) > 0 then Exit('reached level '+ExtractDelimited(2, iMax, [':']));

  iWins := GetCountStr( 'win[@id="total"]', iElement );
  if iWins = '1' then iPlural := ''
    else iPlural := 's';

  if iMax = 'sacrifice' then Exit('half won ('+iWins+' win'+iPlural+' total)');
  if iMax = 'win'       then Exit('won ('+iWins+' win'+iPlural+' total)');
  if iMax = 'final'     then Exit('fully won ('+iWins+' win'+iPlural+' total)');
  Exit('Error!');
end;

function THOF.GetDiffDeaths( aDiff : AnsiString ) : string;
var iCount   : DWord;
    iWins    : DWord;
    iElement : TDOMElement;
begin
  iElement := FPlayerInfo.XML.GetElement('player/games/game[@id="'+aDiff+'"]');
  if iElement = nil then Exit('none');
  iCount   := StrToInt(iElement.GetAttribute('count'));
  iWins    := GetCount( 'win[@id="total"]', iElement );
  Exit(IntToStr(iCount - iWins));
end;

function THOF.GetDiffKills( aDiff : AnsiString ) : string;
var iCount : string;
begin
  iCount := GetCountStr('player/kills/killtype[@id="'+aDiff+'"]');
  if iCount = '0'
    then Exit('none')
    else Exit( iCount );
end;

function THOF.GetChalDesc(Chal : Byte; aDiffLevel : AnsiString; aVictoryType: AnsiString) : string;
var iElement   : TDOMElement;
    iMax       : String;
    iSacrifice : DWord;
    iWin       : DWord;
    iFinal     : DWord;
begin
  if Chal = 0
    then iElement := FPlayerInfo.XML.GetElement('player/challenges/challenge[@id="unchallenged"]/game[@id="'+aDiffLevel+'"]')
    else iElement := FPlayerInfo.XML.GetElement('player/challenges/challenge[@id="'+LuaSystem.Get(['chal',Chal,'abbr'])+'"]/game[@id="'+aDiffLevel+'"]');
  if (iElement = nil) then
    begin
      if aVictoryType = 'partial' then Exit('{lnone}')
	  else Exit('');
	end;
  iMax     := iElement.GetAttribute('max');
  if iMax = '' then Exit('{lnone}');
  if (Pos( ':', iMax ) > 0) and (aVictoryType = 'partial') then Exit('{Rlevel '+ExtractDelimited(2, iMax, [':'])+'}');

  iSacrifice := GetCount('win[@id="sacrifice"]', iElement);
  iWin       := GetCount('win[@id="win"]', iElement);
  iFinal     := GetCount('win[@id="final"]', iElement);

  iMax := '';
  // FIXME I have no idea why not having the terminal number causes text to be chewed up.
  case aVictoryType of
    'partial' : if iSacrifice > 0
                  then iMax += '{lPart }{L'+IntToStr(iSacrifice)+'}'
                  else iMax += '{dPart 0}';
    'standard': if iWin > 0
                  then iMax += '{lStnd }{L'+IntToStr(iWin)+'}'
                  else iMax += '{dStnd 0}';
    'full'    : if iFinal > 0
                  then iMax += '{lFull }{L'+IntToStr(iFinal)+'}'
                  else iMax += '{dFull 0}';
    'total'   : iMax += '{yTotl }{L'+IntToStr(iSacrifice+iWin+iFinal)+'}';
  end;
  Exit( iMax );
end;

function THOF.GetCount(aXPathQuery: string; aContext : TDOMNode = nil ): DWord;
begin
  Exit( StrToIntDef( GetCountStr( aXPathQuery, aContext ), 0 ) );
end;

function THOF.GetChildCount(aXPathQuery: string; aContext: TDOMNode): DWord;
var iXMLElement  : TDOMElement;
begin
  if aContext = nil then aContext := FPlayerInfo.XML;
  iXMLElement := FPlayerInfo.XML.GetElement( aXPathQuery, aContext );
  if (iXMLElement = nil) then Exit(0) else Exit( iXMLElement.ChildNodes.Count );
end;

function THOF.GetCountStr(aXPathQuery: string; aContext : TDOMNode = nil ): string;
var iXMLElement  : TDOMElement;
begin
  if aContext = nil then aContext := FPlayerInfo.XML;
  iXMLElement := FPlayerInfo.XML.GetElement( aXPathQuery, aContext );
  if (iXMLElement = nil) then Exit('0');
  GetCountStr := iXMLElement.GetAttribute('count');
  if GetCountStr = '' then Exit('1');
end;

function THOF.GetRank( const aRankName : Ansistring ): Integer;
var iXMLElement  : TDOMElement;
begin
  iXMLElement := FPlayerInfo.XML.GetElement( 'player/ranks/rank[@id="'+aRankName+'"]' );
  if (iXMLElement = nil) then Exit(0) else Exit( StrToInt(iXMLElement.GetAttribute('value') ));
end;

procedure THOF.SetRank( const aRankName: Ansistring; aValue: Integer );
var iXMLElement  : TDOMElement;
    iXMLEntry    : TDOMElement;
begin
  iXMLElement := TDOMElement(FPlayerInfo.XML.DocumentElement.FindNode('ranks'));
  if iXMLElement = nil then
  begin
    iXMLElement := FPlayerInfo.XML.CreateElement('ranks');
    FPlayerInfo.XML.DocumentElement.AppendChild( iXMLElement );
  end;
  iXMLEntry := FPlayerInfo.XML.GetElement( 'rank[@id="'+aRankName+'"]', iXMLElement );
  if iXMLEntry = nil then
  begin
    iXMLEntry := FPlayerInfo.XML.CreateElement('rank');
    iXMLEntry.SetAttribute('id',aRankName);
    iXMLElement.AppendChild( iXMLEntry );
  end;
  iXMLEntry.SetAttribute('value',IntToStr(aValue));
end;

function THOF.AddCounted( const aRootID, aLeafID, aElementID : AnsiString; aAmount : DWord = 1 ): Boolean;
var XMLEntry : TDOMElement;
begin
  AddCounted := GetCounted( aRootID, aLeafID, aElementID ) = 0;
  XMLEntry := IncreaseXMLCount( FPlayerInfo.XML.DocumentElement, aRootID, aAmount );
  IncreaseXMLCount( XMLEntry, aLeafID, aElementID, aAmount );
end;

function THOF.GetCounted( const aRootID, aLeafID, aElementID : AnsiString ): DWord;
begin
  Exit( GetCount( 'player/'+aRootID+'/'+aLeafID+'[@id="'+aElementID+'"]' ) );
end;

function THOF.GetPagedPlayerReport : TPagedReport;
const BadgeLevelName : array[1..6] of string = (' Bronze ',' Silver ','  Gold  ','Platinum','Diamond ','Angelic ');
var
   iPage    : TStringGArray;

   count    : DWord;
   iTotal   : DWord;
   iFound   : DWord;
   cn,cn2,c : LongInt;
   iDiffID  : AnsiString;
   iDiffCnt : DWord;
   iChalCnt : DWord;
   iPages   : DWord;
   iElement : TDOMElement;
   iBadges  : LongInt;
   iID      : AnsiString;
   iString  : AnsiString;
   iDesc    : AnsiString;
   iPair    : TLuaIndexVariant;
   iRank    : Integer;

  function IsNone(l : LongInt) : string;
  begin
    if l = 0 then Exit('{lnone}')
             else Exit('{!'+IntToStr(l)+'}');
  end;

  procedure PushRank( const aRankID : AnsiString; aCurrent : Byte );
  var iReq, i  : DWord;
      iCurrent : DWord;
      iTotal   : DWord;
      iName    : Ansistring;
  begin
    if aCurrent+1 < LuaSystem.Get(['ranks', aRankID,'__counter']) then
    begin
      iName := '{!'+LuaSystem.Get(['ranks', aRankID, aCurrent+2,'name'])+'}';
      iPage.Push('To achieve '+iName+' rank:');
      for iReq := 1 to GetRankReqCount(aRankID,aCurrent+1) do
      begin
        iCurrent := GetRankReqCurrent( aRankID,aCurrent+1,iReq );
        iTotal   := GetRankReqTotal  ( aRankID,aCurrent+1,iReq );
        if iCurrent < iTotal
          then iPage.Push('   * '+GetRankReqDescription( aRankID,aCurrent+1,iReq )+' ({!'+IntToStr(iCurrent)+'}/{!'+IntToStr(iTotal)+'})' )
          else iPage.Push('   {d* '+StripEncoding( GetRankReqDescription( aRankID,aCurrent+1,iReq ) ) + '}' );
      end;
      iTotal := LuaSystem.GetTableSize(['ranks', aRankID, aCurrent+2, 'unlocks' ]);
      if iTotal > 0 then
      begin
        iPage.Push(iName+' rank unlocks:');
        for i := 1 to iTotal do
        begin
          iPage.Push('   * '+ LuaSystem.Get(['ranks', aRankID, aCurrent+2, 'unlocks', i ]) );
        end;
      end;
    end;
    iPage.Push('');
  end;

begin
  Result := TPagedReport.Create( 'Player Info', True );
  iDiffCnt := 0;
  iChalCnt := 0;
  iDiffCnt := LuaSystem.Get([ 'diff', '__counter' ], 0 );
  iChalCnt := LuaSystem.Get( ['chal','__counter'], 0 );

  // ---------------------------------------------------------------------------

  iPage := Result.Add( '' );

  with LuaSystem.GetTable(['ranks']) do
  try
    for iPair in IndexVariants do
    begin
      iID     := iPair.Value;
      iRank   := GetRank( iID );
      iString := LuaSystem.Get([ 'ranks', iID, 'name' ], '' );
      iPage.Push(Padded( iString + ' rank',15)+': {!'+LuaSystem.Get([ 'ranks', iID, iRank+1, 'name' ])+'}' );
    end;
  finally
    Free;
  end;

  iPage.Push('Games won      : {!'+IntToStr(GetCount('player/games/win[@id="total"]'))+
           '  (' +IntToStr(GetCount('player/games/win[@id="sacrifice"]')) + ' partial, ' +
                 IntToStr(GetCount('player/games/win[@id="win"]')) + ' standard, ' +
                 IntToStr(GetCount('player/games/win[@id="final"]')) + ' full)}}' );
  iPage.Push('All kills      : {!'+IntToStr(GetCount('player/kills'))+
            '  ('+IntToStr(GetCount('player/kills/killtype[@id="weapon-melee"]')) + ' melee, '+
                  IntToStr(GetCount('player/kills/killtype[@id="weapon-pistol"]')) + ' pistol)}');
  iPage.Push('Total game time: {!'+DurationString(GetCount('player/time'))+'}');
  iPage.Push('');

  with LuaSystem.GetTable(['ranks']) do
  try
    for iPair in IndexVariants do
    begin
      PushRank( iPair.Value, GetRank( iPair.Value ) );
    end;
  finally
    Free;
  end;

  //Page.Push('');

  if iDiffCnt > 0 then
  begin
    iPage.Push('Difficulty level achievements');
    for cn := 1 to iDiffCnt do
    begin
      iDiffID := LuaSystem.Get([ 'diff', cn, 'id' ]);
      iPage.Push(' '+Padded(LuaSystem.Get([ 'diff', cn, 'name' ]),21)+': {!'+Padded(GetDiffScore(iDiffID),25)+
                  '} Deaths: {!'+Padded(GetDiffDeaths(iDiffID),4)+
                   '} Kills: {!'+Padded(GetDiffKills(iDiffID),6)+'}');
    end;
  end;

  // ---------------------------------------------------------------------------
  iPage := Result.Add( 'Kills',Padded('Monster name',16)+Padded('TOTAL',7)
            +Padded('Easy',6)+Padded('Med',6)+Padded('Hard',6)+Padded('VHard',6)+Padded('NMare',6)
            +Padded('Melee',6)+Padded('Pist',6)+Padded('Shotg',6)+Padded('Chain',6) );

  for cn := 2 to LuaSystem.Get(['beings','__counter']) do
  begin
    iElement := FPlayerInfo.XML.GetElement('player/kills/killbeing[@id="'+LuaSystem.Get(['beings',cn,'id'])+'"]');
    if iElement = nil then Continue;

    iString := Padded(LuaSystem.Get(['beings',cn,'name']),16);
    iString += Padded(IsNone(StrToInt(iElement.GetAttribute('count'))),10);

    for cn2 := 1 to LuaSystem.Get([ 'diff', '__counter' ]) do
      iString += Padded(IsNone(GetCount( 'killtype[@id="'+LuaSystem.Get([ 'diff', cn2, 'id' ])+'"]', iElement)),9);

    iString += Padded(IsNone(GetCount( 'killtype[@id="weapon-melee"]', iElement)),9);
    iString += Padded(IsNone(GetCount( 'killtype[@id="weapon-pistol"]', iElement)),9);
    iString += Padded(IsNone(GetCount( 'killtype[@id="weapon-shotgun"]', iElement)),9);
    iString += Padded(IsNone(GetCount( 'killtype[@id="weapon-chain"]', iElement)),8);

    iPage.Push( iString );
  end;

  // ---------------------------------------------------------------------------
  iPage := Result.Add( 'Victories',Padded('Difficulty',24)
               +Padded('Medium',13)+Padded('Hard',13)+Padded('Very Hard',13)+Padded('Nightmare',13) );

  if iChalCnt > 0 then
  for cn := 1 to (iChalCnt+1)*4 do
  begin
    if (cn mod 4) = 1 then
          begin
            if cn = 1
              then iString := ' '+Padded('Standard Game',24)
              else iString := ' '+Padded(LuaSystem.Get(['chal',Floor(cn div 4),'name']),24);
          end
        else iString := Padded('',25);

    for cn2 := 2 to iDiffCnt do
    begin
      case ( (cn - 1) mod 4 ) + 1 of
        1: iDesc := GetChalDesc(Floor((cn-1) div 4),LuaSystem.Get([ 'diff', cn2, 'id' ]),'partial');
        2: iDesc := GetChalDesc(Floor((cn-1) div 4),LuaSystem.Get([ 'diff', cn2, 'id' ]),'standard');
        3: iDesc := GetChalDesc(Floor((cn-1) div 4),LuaSystem.Get([ 'diff', cn2, 'id' ]),'full');
        4: iDesc := GetChalDesc(Floor((cn-1) div 4),LuaSystem.Get([ 'diff', cn2, 'id' ]),'total');
      end;
      iString += iDesc;
      if cn2 < iDiffCnt
        then iString += StringOfChar(' ', 13-VTIG_Length(iDesc));
    end;
    iPage.Push( iString );
  end;

  // ---------------------------------------------------------------------------
  if LuaSystem.Defined(['medals','__counter']) then
  begin
    iPage := TStringGArray.Create;

    for cn := 1 to LuaSystem.Get(['medals','__counter']) do
    begin
      if LuaSystem.Get(['medals',cn,'hidden']) then Continue;
      Count := GetCounted('medals','medal',LuaSystem.Get(['medals',cn,'id']));
      if Count = 0 then iString := ' {d' else iString := ' {!';
      iString += LuaSystem.Get(['medals',cn,'name']);
      if Count = 0 then iString += ' ({L-})}' else iString += ' ({L'+IntToStr(Count)+'})}';

      iPage.Push( Padded(iString,40)+'{l'+LuaSystem.Get(['medals',cn,'desc'])+'}');
    end;
    iPage.Push('');
    for cn := 1 to LuaSystem.Get(['medals','__counter']) do
    begin
      if not LuaSystem.Get(['medals',cn,'hidden']) then Continue;
      Count := GetCounted('medals','medal',LuaSystem.Get(['medals',cn,'id']));
      if Count = 0 then
      begin
        iPage.Push( '   {d----}');
        Continue;
      end;
      iString := ' {!'+LuaSystem.Get(['medals',cn,'name'])+' ({L'+IntToStr(Count)+'})}';
      iPage.Push( Padded(iString,40)+'{l'+LuaSystem.Get(['medals',cn,'desc'])+'}');
    end;

    cn := 0; cn2 := 0;
    iElement := FPlayerInfo.XML.GetElement('player/medals');
    if iElement <> nil then
    begin
      cn  := StrToInt(iElement.GetAttribute('count'));
      cn2 := iElement.ChildNodes.Count;
    end;

    Result.Add( iPage, 'Medals', 'Total medals received  : {!'+Padded(IntToStr(cn),7)+'}Total different medals  : {!'+IntToStr(cn2)+'}/{!'+IntToStr(LuaSystem.Get(['medals','__counter']))+'}');
  end;

  // ---------------------------------------------------------------------------
  iPage := TStringGArray.Create;

  c := 0;
  cn2 := 0;
  iString := '';

  for cn := 1 to LuaSystem.Get(['items','__counter']) do
  with LuaSystem.getTable(['items',cn]) do
  try
    if getBoolean('is_exotic') then
    begin
      Inc(c);
      Inc(cn2);
      Count := GetCounted('uniques','unique',getString('id'));
      if Count = 0
        then iString += '{d'+getString('name')+' ({L-})}'
        else iString += '{!'+getString('name')+' ({L'+IntToStr(Count)+'})}';
      if cn2 mod 2 = 1
        then iString := ' '+Padded(iString,40)
        else begin iPage.Push(iString); iString := ''; end;
    end;
  finally
    Free;
  end;

  if iString <> '' then begin iPage.Push(iString); iString := ''; end;
  cn2 := 0;
  iPage.Push('');
  for cn := 1 to LuaSystem.Get(['items','__counter']) do
  with LuaSystem.getTable(['items',cn]) do
  try
    if getBoolean('is_unique') then
    begin
      Inc(c);
      Inc(cn2);
      Count := GetCounted('uniques','unique',getString('id'));
      if Count = 0
        then iString += '{d  ----  }'
        else iString += '{!'+getString('name')+' ({L'+IntToStr(Count)+'})}';
      if cn2 mod 2 = 1
        then iString := ' '+Padded(iString,40)
        else begin iPage.Push(iString); iString := ''; end;
    end;
  finally
    Free;
  end;
  if iString <> '' then iPage.Push(iString);

  cn := 0; cn2 := 0;
  iElement := FPlayerInfo.XML.GetElement('player/uniques');
  if iElement <> nil then
  begin
    cn  := StrToInt(iElement.GetAttribute('count'));
    cn2 := iElement.ChildNodes.Count;
  end;
  Result.Add( iPage, 'Items','Total specials found  : {!'+Padded(IntToStr(cn),7)+'}Total different specials  : {!'+IntToStr(cn2)+'}/{!'+IntToStr(c)+'}');

  // ---------------------------------------------------------------------------
  if LuaSystem.Defined(['mod_arrays','__counter']) then
  begin
    iPage := TStringGArray.Create;

    c := 0;
    iString := '';

    for cn2 := 0 to 2 do
    begin
      case cn2 of
        0 : iPage.Push(' {!Basic assemblies}');
        1 : iPage.Push(' {!Advanced assemblies}');
        2 : iPage.Push(' {!Master assemblies}');
      end;
      iPage.Push('');
      for cn := 1 to LuaSystem.Get(['mod_arrays','__counter']) do
      with LuaSystem.GetTable(['mod_arrays',cn]) do
      try
        if getInteger('level') = cn2 then
        begin
          Inc(c);
          Count := GetCount('player/assemblies/assembly[@id="'+getString('id')+'"]');
          if Count = 0
            then
              begin
                 if cn2 = 0
                   then iString += ' {d'+getString('name')+' ({L-})}'
                   else iString += ' {d  -- ? -- ({L-})}'
              end
            else iString += Padded(' {!'+getString('name')+' ({L'+IntToStr(Count)+'})}',40) + '{l' + getString('request_desc')+'}';
          iPage.Push(iString);
          iString := '';
        end;
      finally
        Free;
      end;
      if cn2 <> 2 then iPage.Push('');
    end;

    cn := 0; cn2 := 0;
    iElement := FPlayerInfo.XML.GetElement('player/assemblies');
    if iElement <> nil then
    begin
      cn  := StrToInt(iElement.GetAttribute('count'));
      cn2 := iElement.ChildNodes.Count;
    end;
    Result.Add( iPage, 'Assemblies','Total assembled       : {!'+Padded(IntToStr(cn),7)+'}Total different assemblies: {!'+IntToStr(cn2)+'}/{!'+IntToStr(c)+'}');
  end;

  // ---------------------------------------------------------------------------

  if LuaSystem.Defined(['badges','__counter']) then
  begin
    iBadges := LuaSystem.Get(['badges','__counter']);
    iPages  := 5;
    if (GetBadgeCount(6) >= 1) or (GetBadgeCount(5) >= 1) then iPages := 6;
    for cn2 := 1 to iPages do
    begin
      iPage := TStringGArray.Create;
      iTotal := 0;
      iFound := 0;
      for cn := 1 to iBadges do
      with LuaSystem.GetTable(['badges',cn]) do
      try
        if getInteger('level') = cn2 then
        begin
          iTotal += 1;
          if GetCounted( 'badges', 'badge', getString('id') ) > 0 then
          begin
            iFound += 1;
            iString := ' {!'+getString('name');
          end
          else
            iString := ' {d'+getString('name');
          iPage.Push( Padded(iString,31) + '}{l -- ' + getString('desc') + '}' );
        end;
      finally
        Free;
      end;

      Result.Add(iPage, 'Badges - '+BadgeLevelName[cn2], Padded('Total '+Trim(BadgeLevelName[cn2])+' badges received',36)+' : {!'+IntToStr(iFound)+'}/{!'+IntToStr(iTotal)+'}');

    end;
  end;

  // ---------------------------------------------------------------------------
  iBadges := LuaSystem.Get(['awards','__counter'],0);
  if iBadges > 0 then
  begin
    iPage := Result.Add('Custom Awards');
    for cn := 1 to iBadges do
    begin
      if cn > 1 then iPage.Push('');
      iFound  := LuaSystem.GetTableSize(['awards',cn,'levels']);
      iDiffID := LuaSystem.Get(['awards',cn,'id']);
      iTotal  := 0;
      for cn2 := iFound downto 1 do
      begin
        if GetCounted( 'awards', 'award', iDiffID + '_' + IntToStr(cn2) ) > 0 then
        begin
          iTotal := cn2;
          Break;
        end;
      end;

      if iTotal > 0
        then iString := Padded(' {!'+LuaSystem.Get(['awards',cn,'name'])+' ('+LuaSystem.Get(['awards',cn,'levels',iTotal,'name'])+')}',38)
        else iString := Padded(' {d'+LuaSystem.Get(['awards',cn,'name'])+' (none yet)}',38);
      iPage.Push( Padded(iString,38)+ ' {dModule: {l'+LuaSystem.Get(['awards',cn,'mname'])+'}}');
      if iTotal >= iFound
        then iPage.Push('   {dMaximum award level reached. Award received for: {l'+LuaSystem.Get(['awards',cn,'levels',iTotal,'name'] )+'}}')
        else iPage.Push('   {dTo achieve {L'+LuaSystem.Get(['awards',cn,'levels',iTotal+1,'name'])+'} level you need to: {l'+LuaSystem.Get(['awards',cn,'levels',iTotal+1,'desc'] )+'}');
    end;
  end;
end;

function THOF.GetPagedScoreReport : TPagedReport;
var iChals     : TIntHashMap;
    iCCount    : DWord;
    iPages     : array[0..99] of TStringGArray;
    iCount     : DWord;
    iAmount    : DWord;
    iElement   : TScoreEntry;
    iChal      : Ansistring;
    iChalIdx   : DWord;
    iDiff      : DWord;

    iScore     : DWord;
    iLevel     : DWord;
    iDlev      : AnsiString;
    iString    : AnsiString;
    iName      : AnsiString;
    iKill      : AnsiString;
    iColor     : AnsiString;
    iHeader    : AnsiString;
    iKlassChar : Char;

  procedure Push( aIndex : DWord; aString : AnsiString );
  begin
    if iPages[ aIndex ] = nil then iPages[ aIndex ] := TStringGArray.Create;
    iPages[ aIndex ].Push( aString );
  end;

begin
  FillChar( iPages, Sizeof( iPages ), 0 );
  iChals := TIntHashMap.Create;
  if LuaSystem.Defined(['chal','__counter']) then
  begin
    iCCount := LuaSystem.Get(['chal','__counter']);
    for iCount := 1 to iCCount do
      iChals[ LuaSystem.Get(['chal',iCount,'abbr']) ] := iCount;
  end;

  iAmount := FScore.Entries;
  for iCount := 1 to iAmount do
  begin
    iElement := FScore[ iCount ];
    iDiff    := StrToInt( iElement.GetAttribute('difficulty') );
    iChal    := iElement.GetAttribute('challenge');
    iChalIDX := 0;
    if iChal <> '' then
    begin
      iChalIDX := iChals.Get( iChal, 0 );
      if iChalIDX = 0 then Continue;
    end;

    iScore := math.Max( StrToInt( iElement.GetAttribute('score') ), 0 );
    iLevel := StrToInt( iElement.GetAttribute('level') );
    iDLev  := iElement.GetAttribute('depth');
    iName  := iElement.GetAttribute('name');
    iKill  := iElement.GetAttribute('killed');

    if iCount = FScore.LastEntry then
      iColor := '{L'
    else
      iColor := '{!';

    iString := LuaSystem.Get(['diff',iDiff,'code']) + ' ';
    iString += iColor + Padded(IntToStr(iScore),8);
    iString += Padded(iName,17) + ' ';

    iKlassChar := 'C';
    if iElement.hasAttribute('klass') then iKlassChar := LuaSystem.Get(['klasses',AnsiString(iElement.GetAttribute('klass')),'char']);

    iString += iKlassChar + '{L'+Padded(IntToStr(iLevel),3)+'}';
    iString += Padded(iKill,34);
    if iDLev.Length > 0 then
    begin
      if iDLev[1] in ['1'..'9'] then
        iString += 'L{L'+Padded(iDLev,4)+'}'
      else
        iString += Padded(iDLev,5);

    end;
//    if iChal <> '' then iString += iChal;
    iString += '}';

    if iChalIDX = 0 then
    begin
      Push( 0, iString );
      if iDiff <> 0 then
        Push( iDiff, iString );
    end
    else Push( iChalIDX + 10, iString );
  end;

  iHeader := '';
  Result := TPagedReport.Create( 'Hall of fame', True );
  if iPages[0] <> nil
    then Result.Add( iPages[0], '', iHeader )
    else Result.Add( '', iHeader );
  for iCount := 1 to 9 do
    if iPages[iCount] <> nil then
      Result.Add( iPages[iCount], LuaSystem.Get(['diff',iCount,'code']), iHeader );
  for iCount := 10 to 99 do
    if iPages[iCount] <> nil then
      Result.Add( iPages[iCount], LuaSystem.Get(['chal',iCount - 10,'abbr']), iHeader );
  FreeAndNil( iChals );
end;

procedure THOF.Init;
var iScorePath : Ansistring;
begin
  iScorePath := ScorePath;
  if iScorePath = '' then iScorePath := ModuleUserPath;
  FScore := TScoreFile.Create( iScorePath + ScoreFile, MaxHOFEntries );
  FScore.SetCRC( '344ef'+{ModuleID+}'3321', '738af'+{ModuleID+}'92-5' );
  FScore.SetBackup( iScorePath+'backup'+PathDelim, Option_ScoreBackups );
  FScore.Lock;
  try
    FScore.Load;
  finally
    FScore.Unlock;
  end;

  FPlayerInfo := TVXMLDataFile.Create( ModuleUserPath + PlayerFile, 'player' );
  FPlayerInfo.SetCRC( '344ef'+{ModuleID+}'3321', '738af'+{ModuleID+}'92-5' );
  FPlayerInfo.SetBackup(  ModuleUserPath + 'backup'+PathDelim, Option_PlayerBackups );
  FPlayerInfo.Load;

  HOFOpen := True;
end;

function THOF.GameResultBetter( const ResultOld, ResultNew : String ) : boolean;
  function NameToVal( const Str : String ) : DWord;
  begin
    if Length(Str) = 0 then Exit(0);
    if Pos(':',Str) <> 0 then Exit( StrToInt(ExtractDelimited( 2, Str, [':'] ) ) );
    if Str = 'sacrifice' then Exit( 10000 );
    if Str = 'win'       then Exit( 20000 );
    if Str = 'final'     then Exit( 30000 );
    Exit(0);
  end;
begin
  if ResultOld = ResultNew then Exit(False);
  Exit( NameToVal( ResultOld ) < NameToVal( ResultNew ) );
end;

function THOF.GameResultAtLeast(const ResultAtLeast, ResultNew : String): boolean;
  function NameToVal( const Str : String ) : DWord;
  begin
    if Length(Str) = 0 then Exit(0);
    if Pos(':',Str) <> 0 then Exit( StrToInt(ExtractDelimited( 2, Str, [':'] ) ) );
    if Str = 'sacrifice' then Exit( 10000 );
    if Str = 'win'       then Exit( 20000 );
    if Str = 'final'     then Exit( 30000 );
    Exit(0);
  end;
begin
  if ResultAtLeast = ResultNew then Exit(True);
  Exit( NameToVal( ResultNew ) >= NameToVal( ResultAtLeast ) );
end;

function THOF.IncreaseXMLCount( aContainer : TDOMElement; const aElementID : string; const aID : string; aAmount : DWord ) : TDOMElement;
var iXMLElement  : TDOMElement;
begin
  if aAmount = 0 then Exit( nil );
  iXMLElement := FPlayerInfo.XML.GetElement(aElementID + '[@id="'+aID+'"]', aContainer);
  if iXMLElement = nil then
  begin
    iXMLElement := aContainer.OwnerDocument.CreateElement( aElementID );
    iXMLElement.SetAttribute( 'id', aID );
    iXMLElement.SetAttribute( 'count', IntToStr( aAmount ) );
    aContainer.AppendChild( iXMLElement );
  end
  else
    iXMLElement.SetAttribute('count', IntToStr(StrToIntDef(iXMLElement.GetAttribute('count'),0) + LongInt(aAmount)));
  Exit( iXMLElement );
end;

function THOF.IncreaseXMLCount( aContainer : TDOMElement; const aElementID : string; aAmount : DWord ) : TDOMElement;
var iXMLElement  : TDOMElement;
    iCurrent     : LongInt;
begin
  iXMLElement := TDOMElement(aContainer.FindNode(aElementID));
  if iXMLElement = nil then
  begin
    iXMLElement := aContainer.OwnerDocument.CreateElement(aElementID);
    iXMLElement.SetAttribute('count','0');
    aContainer.AppendChild( iXMLElement );
  end;
  iCurrent     := StrToIntDef(iXMLElement.GetAttribute('count'),0);
  iXMLElement.SetAttribute('count',IntToStr(iCurrent + LongInt(aAmount)));

  Exit( iXMLElement );
end;

procedure THOF.Add( const Name : AnsiString; aScore : LongInt; const aKillerID : AnsiString; Level, DLev : Word; nChal, nAbbr : AnsiString );
var XMLElement : TDOMElement;
    XMLSubElement : TDOMElement;
    XMLEntry   : TDOMElement;
    iScoreEntry : TScoreEntry;
    VS : String;
    iGameResultID : AnsiString;
    iString : String;
    iGameResult : String;
    iKills : DWord;
    iChalAbbr  : string;
    iChalInc : Integer;
    iDiffID : string;
    iWeaponGroup    : AnsiString;
    iKillsEntry     : TKillTableIterator.TPairType;
    iKillTypesEntry : TKillTableEntryIterator.TPairType;

  function WeaponGroup( const aID : AnsiString ) : AnsiString;
  begin
    if aID = 'other' then Exit('other');
    if aID = 'melee' then Exit('weapon-melee');
    if LuaSystem.Defined( ['items',aID,'group'] ) then
        Exit( 'weapon-'+LuaSystem.Get( ['items',aID,'group'] ) )
    else
        Exit( 'other' );
  end;

begin
  iGameResultID := LuaSystem.ProtectedCall([CoreModuleID,'GetResultId'],[]);
  if not NoPlayerRecord then
  begin
    iDiffID       := LuaSystem.Get([ 'diff', DRL.Difficulty, 'id' ]);
    iChalInc      := 0;
    iChalAbbr     := 'unchallenged';
    if nChal <> '' then
    begin
      iChalAbbr := LuaSystem.Get(['chal',nChal,'abbr']);
      iChalInc := 1;
    end;

    XMLEntry := IncreaseXMLCount( FPlayerInfo.XML.DocumentElement, 'deaths', 1 );
    IncreaseXMLCount( XMLEntry, 'death', iChalAbbr, 1 );
    IncreaseXMLCount( XMLEntry, 'death', iGameResultID, 1 );
    if (aKillerID <> '') and (aKillerID <> Player.ID) then
      IncreaseXMLCount( XMLEntry, 'death', LuaSystem.Get(['beings',aKillerID,'id']), 1 );

    // KILLS

    XMLEntry := IncreaseXMLCount( FPlayerInfo.XML.DocumentElement, 'kills', Player.FKills.Count );

    for iKillsEntry in Player.FKills do
    begin
      iKills := iKillsEntry.Value.Count;
      if iKills = 0 then Continue;

      XMLElement := IncreaseXMLCount( XMLEntry, 'killbeing', iKillsEntry.Key, iKills );
      IncreaseXMLCount( XMLElement, 'killtype', iDiffID, iKills );

      for iKillTypesEntry in iKillsEntry.Value do
      begin
        iWeaponGroup := WeaponGroup(iKillTypesEntry.Key);
        IncreaseXMLCount( XMLElement, 'killtype', iWeaponGroup, iKillTypesEntry.Value );
        IncreaseXMLCount( XMLEntry, 'killtype', iWeaponGroup, iKillTypesEntry.Value );
        if (iKillTypesEntry.Key <> 'melee') and (iKillTypesEntry.Key <> 'other') then
          IncreaseXMLCount( XMLEntry, 'killtype', iKillTypesEntry.Key, iKillTypesEntry.Value );
      end;
    end;

    IncreaseXMLCount( XMLEntry, 'killtype', iDiffID, Player.FKills.Count );
    IncreaseXMLCount( XMLEntry, 'killtype', iChalAbbr, Player.FKills.Count );

    // GAMES
    iGameResult := LuaSystem.ProtectedCall([CoreModuleID,'GetShortResultId'],[iGameResultID,DLev]);
    XMLEntry := IncreaseXMLCount( FPlayerInfo.XML.DocumentElement, 'games', 1 );
    if DRL.GameWon then
    begin
      IncreaseXMLCount( XMLEntry, 'win', iGameResult, 1 );
      IncreaseXMLCount( XMLEntry, 'win', 'total', 1 );
    end;
    XMLElement := IncreaseXMLCount( XMLEntry, 'game', iDiffID, 1 );
    iString := XMLElement.GetAttribute('max');
    if GameResultBetter( iString, iGameResult ) then XMLElement.SetAttribute('max',iGameResult);
    if DRL.GameWon then
    begin
      IncreaseXMLCount( XMLElement, 'win', iGameResult, 1 );
      IncreaseXMLCount( XMLElement, 'win', 'total', 1 );
    end;

    // CHALLENGES
    XMLEntry := IncreaseXMLCount( FPlayerInfo.XML.DocumentElement, 'challenges', iChalInc );
    XMLElement := IncreaseXMLCount( XMLEntry, 'challenge', iChalAbbr, 1 );
    iString := XMLElement.GetAttribute('max');
    if GameResultBetter( iGameResult, iString ) then XMLElement.SetAttribute('max',iGameResult);
    if DRL.GameWon then
    begin
      IncreaseXMLCount( XMLElement, 'win', iGameResult, 1 );
      IncreaseXMLCount( XMLElement, 'win', 'total', 1 );
    end;
    XMLSubElement := IncreaseXMLCount( XMLElement, 'game', iDiffID, 1 );
    iString := XMLSubElement.GetAttribute('max');
    if GameResultBetter( iString, iGameResult ) then XMLSubElement.SetAttribute('max',iGameResult);
    if DRL.GameWon then
    begin
      IncreaseXMLCount( XMLSubElement, 'win', iGameResult, 1 );
      IncreaseXMLCount( XMLSubElement, 'win', 'total', 1 );
    end;
  end;

  if not NoScoreRecord then
  begin
    VS := LuaSystem.ProtectedCall([CoreModuleID,'GetResultDescription'],[iGameResultID,true]);

    FScore.Lock;
    try
      FScore.Load;
      iScoreEntry := FScore.Add( aScore );
      if iScoreEntry <> nil then
      begin
        //Score.Add(Name,aScore,Level,DLev,DRL.Difficulty,VS,VSS,LuaSystem.Get(['klasses',Player.Klass,'id']));
        iScoreEntry.SetAttribute('name', Name );
        iScoreEntry.SetAttribute('level', IntToStr(Level) );
        if nAbbr <> ''
          then iScoreEntry.SetAttribute('depth', nAbbr )
          else iScoreEntry.SetAttribute('depth', IntToStr(DLev) );
        iScoreEntry.SetAttribute('klass', LuaSystem.Get(['klasses',Player.Klass,'id']) );
        iScoreEntry.SetAttribute('killed', VS );
        iScoreEntry.SetAttribute('difficulty', IntToStr(DRL.Difficulty) );
        if nChal <> '' then
          iScoreEntry.SetAttribute('challenge', LuaSystem.Get(['chal',nChal,'abbr']) );
        FScore.Save;
      end;
    finally
      FScore.Unlock;
    end;
  end;
  Save;
end;

function THOF.RankCheck( out aResult : THOFRank ) : Boolean;
var iSize   : Integer;
    iValues : array of Integer;
    i       : Integer;
    iPair   : TLuaIndexVariant;
begin
  if NoPlayerRecord then Exit( False );

  iSize := LuaSystem.GetTableSize( 'ranks' );

  Initialize( aResult );
  Initialize( iValues );
  SetLength( aResult.Data, iSize );
  SetLength( iValues, iSize );

  i := 0;
  with LuaSystem.GetTable(['ranks']) do
  try
    for iPair in IndexVariants do
    begin
      aResult.Data[i].ID    := iPair.Value;
      iValues[i]            := GetRank( aResult.Data[i].ID );
      aResult.Data[i].Value := iValues[i];
      Inc( i );
    end;
  finally
    Free;
  end;

  try
    for i := 0 to iSize-1 do
      while CheckRank(aResult.Data[i].ID,iValues[i]) do
        Inc(iValues[i]);
  except
    on e : EDOMError do
      Log( e.Message );
  end;

  RankCheck := False;
  for i := 0 to iSize-1 do
  begin
    if iValues[i] = aResult.Data[i].Value
      then aResult.Data[i].Value := 0
      else begin
        aResult.Data[i].Value := iValues[i];
        if DRL.Store.IsInitialized then
          HandleAchievements( aResult.Data[i].ID, iValues[i] );
        RankCheck := True;
      end;
    SetRank(aResult.Data[i].ID,iValues[i]);
  end;
end;

procedure THOF.Done;
begin
  Save;
  FreeAndNil( FScore );
  FreeAndNil( FPlayerInfo );
  HOFOpen := False;
end;


procedure THOF.Save;
var iSeconds : DWord;
begin
  if not HOFOpen then Exit;

  iSeconds := Round( (MSecNow() - ProgramRealTime) / 1000 );
  ProgramRealTime := MSecNow();
  IncreaseXMLCount( FPlayerInfo.XML.DocumentElement, 'time', iSeconds );

  FPlayerInfo.Save;
end;

function THOF.GetRankReqCount(const aRankArray: AnsiString; aRankLevel: DWord ): DWord;
begin
  Exit( LuaSystem.GetTableSize( [ 'ranks', aRankArray, aRankLevel+1, 'reqs' ] ) );
end;

function THOF.GetRankReqDescription(const aRankArray: AnsiString; aRankLevel: DWord; aRankReq: DWord): AnsiString;
var iAmount : DWord;
    iParam  : Variant;
    iParam2 : Variant;
    iReq    : AnsiString;
begin
  with LuaSystem.GetTable( [ 'ranks', aRankArray, aRankLevel+1, 'reqs', aRankReq ] ) do
  try
    iParam  := GetField( 'param' );
    if not IsNil( 'param2' ) then
      iParam2 := GetField( 'param2' );
    iAmount := GetInteger( 'amount', 1 );
    iReq    := GetString( 'req' );
  finally
    Free;
  end;
  Exit( LuaSystem.ProtectedCall( ['requirements', iReq, 'description'], [iAmount, iParam, iParam2] ) );
end;

function THOF.IsRankReqCompleted(const aRankArray: AnsiString; aRankLevel: DWord; aRankReq: DWord): Boolean;
var iAmount : DWord;
    iParam  : Variant;
    iParam2 : Variant;
    iReq    : AnsiString;
begin
  with LuaSystem.GetTable( [ 'ranks', aRankArray, aRankLevel+1, 'reqs', aRankReq ] ) do
  try
    iParam  := GetField( 'param' );
    if not IsNil( 'param2' ) then
      iParam2 := GetField( 'param2' );
    iAmount := GetInteger( 'amount', 1 );
    iReq    := GetString( 'req' );
  finally
    Free;
  end;
  Exit( LuaSystem.ProtectedCall( ['requirements', iReq, 'progress'], [iParam,iParam2] ) >= iAmount );
end;

function THOF.GetRankReqCurrent(const aRankArray: AnsiString; aRankLevel: DWord; aRankReq: DWord): DWord;
var iParam  : Variant;
    iParam2 : Variant;
    iReq    : AnsiString;
begin
  with LuaSystem.GetTable( [ 'ranks', aRankArray, aRankLevel+1, 'reqs', aRankReq ] ) do
  try
    iParam  := GetField( 'param' );
    if not IsNil( 'param2' ) then
      iParam2 := GetField( 'param2' );
    iReq    := GetString( 'req' );
  finally
    Free;
  end;
  Exit( LuaSystem.ProtectedCall( ['requirements', iReq, 'progress'], [iParam,iParam2] ) );
end;

function THOF.GetRankReqTotal(const aRankArray: AnsiString; aRankLevel: DWord; aRankReq: DWord): DWord;
begin
  Exit( LuaSystem.Get( [ 'ranks', aRankArray, aRankLevel+1, 'reqs', aRankReq, 'amount' ], 1 ) );
end;

function THOF.CheckRank( const aRankArray : Ansistring; aCurrent : Integer ) : boolean;
var iCount : DWord;
begin
  if aCurrent+1 >= LuaSystem.Get(['ranks', aRankArray, '__counter'],0) then Exit( False );
  iCount := GetRankReqCount( aRankArray, aCurrent+1 );
  if iCount = 0 then Exit( True );
  for iCount := 1 to iCount do
    if not IsRankReqCompleted( aRankArray, aCurrent+1, iCount ) then Exit( False );
  Exit( True );
end;

procedure THOF.HandleAchievements( const aRankArray : Ansistring; aRankLevel : Integer );
var i    : Integer;
    iAch : AnsiString;
begin
  for i := 1 to aRankLevel do
  begin
    iAch := LuaSystem.Get( [ 'ranks', aRankArray, i+1, 'achievement' ], '' );
    if iAch <> '' then
        if DRL.Store.SetAchievement( iAch ) then
          Log( LOGINFO, iAch+' awarded!');
  end;
end;

end.
