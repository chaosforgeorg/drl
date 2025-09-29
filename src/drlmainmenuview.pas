{$INCLUDE drl.inc}
{
 ----------------------------------------------------
Copyright (c) 2002-2025 by Kornel Kisielewicz
----------------------------------------------------
}
unit drlmainmenuview;
interface
uses vio, viotypes, vgenerics, vtextures, vtigstyle, dfdata, drlio;

type TMainMenuViewMode = (
  MAINMENU_FIRST, MAINMENU_INTRO, MAINMENU_MENU,
  MAINMENU_DIFFICULTY, MAINMENU_FAIR, MAINMENU_KLASS, MAINMENU_TRAIT, MAINMENU_CTYPE, MAINMENU_NAME,
  MAINMENU_CPICK, MAINMENU_CFIRST, MAINMENU_CSECOND,
  MAINMENU_BADSAVE, MAINMENU_SAVECOMPAT, MAINMENU_DONE );

type TMainMenuEntry = record
  Name  : Ansistring;
  Desc  : Ansistring;
  Allow : Boolean;
  Extra : Ansistring;
  ID    : Ansistring;
  NID   : Byte;
  Req   : Byte;
end;

type TMainMenuEntryArray = specialize TGArray< TMainMenuEntry >;

type TMainMenuView = class( TIOLayer )
  constructor Create( aInitial : TMainMenuViewMode = MAINMENU_FIRST; aResult : TMenuResult = nil );
  procedure Update( aDTime : Integer; aActive : Boolean ); override;
  function IsFinished : Boolean; override;
  function IsModal : Boolean; override;
  destructor Destroy; override;
protected
  procedure Render;
  procedure UpdateFirst;
  procedure UpdateIntro;
  procedure UpdateMenu;
  procedure UpdateBadSave;
  procedure UpdateSaveCompat;
  procedure UpdateFair;
  procedure UpdateName;
  procedure UpdateDifficulty;
  procedure UpdateKlass;
  procedure UpdateChallengeType;
  procedure UpdateChallenge;
  procedure OnCancel;
  procedure SetSoundCallback;
  procedure ResetSoundCallback;
  procedure ReloadArrays;
  procedure ReloadChallenge( aType : Byte );
  procedure RenderASCIILogo;
  procedure UpdateModErrors;
protected
  FSize        : TIOPoint;
  FMode        : TMainMenuViewMode;
  FFirst       : Ansistring;
  FIntro1      : Ansistring;
  FIntro2      : Ansistring;
  FMOTD        : Ansistring;
  FResult      : TMenuResult;
  FSaveExists  : Boolean;
  FJHCLink     : Boolean;

  FArrayCType  : TMainMEnuEntryArray;
  FArrayDiff   : TMainMEnuEntryArray;
  FArrayKlass  : TMainMEnuEntryArray;
  FArrayChal   : TMainMEnuEntryArray;
  FTitleChal   : Ansistring;
  FChallenges  : Boolean;
  FFKlassPick  : Boolean;
  FMenuStyle   : TTIGStyle;
  FWindowStyle : TTIGStyle;

  FBGTexture   : TTextureID;
  FLogoTexture : TTextureID;
  FName        : array[0..48] of Char;
end;

implementation

uses math, sysutils,
     vutil, vtig, vtigio, vgltypes, vluasystem, vluavalue, vsound,
     dfhof,
     drlbase, drlgfxio, drlplayerview, drlhelpview, drlsettingsview, drlpagedview;

var ChallengeType : array[1..4] of TMainMenuEntry =
((
   Name : 'Angel Game';
   Desc : 'Play one of the DRL classic challenge games that place restrictions on play style or modify play behaviour.';
   Allow : True; Extra : 'Reach {yPrivate FC} rank to unlock!'; ID : ''; NID : 0; Req : 0;
),(
   Name : 'Dual-angel Game';
   Desc : 'Mix two DRL challenge game types. Only the first counts highscore-wise - the latter is your own challenge!';
   Allow : True; Extra : 'Reach {ySergeant} rank to unlock!'; ID : ''; NID : 0; Req : 0;
),(
   Name : 'Archangel Game';
   Desc : 'Play one of the DRL challenge in its ultra hard form. Do not expect fairness here!';
   Allow : True; Extra : 'Reach {ySergeant Major} rank to unlock!'; ID : ''; NID : 0; Req : 0;
),(
   Name : 'Custom Challenge';
   Desc : 'Play one of many custom DRL challenge levels and episodes. Download new ones from the {yCustom game/Download Mods} option in the main menu.';
   Allow : True; Extra : ''; ID : ''; NID : 0; Req : 0;
));

const MAINMENU_ID = 'mainmenu';

const CTYPE_ANGEL  = 1;
      CTYPE_DANGEL = 2;
      CTYPE_AANGEL = 3;
//      CTYPE_CUSTOM = 4;

      CTYPE_SECOND = 10;


constructor TMainMenuView.Create( aInitial : TMainMenuViewMode = MAINMENU_FIRST; aResult : TMenuResult = nil );
begin
  FMenuStyle   := TIGStyleFrameless;
  FMenuStyle.Padding[ VTIG_WINDOW_PADDING ]   := Point( 5, 1 );
  FWindowStyle := TIGStyleFrameless;
  FWindowStyle.Padding[ VTIG_WINDOW_PADDING ] := Point( 2, 1 );

  VTIG_EventClear;
  VTIG_ResetSelect( MAINMENU_ID );

  FMode       := aInitial;
  FResult     := aResult;
  FSaveExists := False;
  FJHCLink    := (CoreModuleID = 'drl') and ( not DRL.Store.IsSteam );
  if (not FJHCLink) and DemoVersion then
    FJHCLink := True;
  FArrayCType := nil;
  FArrayDiff  := nil;
  FArrayKlass := nil;
  FArrayChal  := nil;
  FTitleChal  := '';
  FSize       := Point( 80, 25 );
  FChallenges := ( LuaSystem.Get( ['chal','__counter'], 0 ) > 0 ) and (not DemoVersion);

  if not ( FMode in [MAINMENU_FIRST,MAINMENU_INTRO] ) then
    Assert( aResult <> nil, 'nil result passed!' );

  if FMode = MAINMENU_FIRST then
  begin
    if not FileExists( WritePath + 'drl.prc' ) then
    begin
      WriteFileString( WritePath + 'drl.prc', 'DRL was already run.' );

      FFirst := AnsiString( LuaSystem.ProtectedCall( [CoreModuleID,'GetFirstText'], [] ) );
      if FFirst = '' then FMode := MAINMENU_INTRO;

      if not DemoVersion then
      begin
        if FileExists( ModuleUserPath + 'savedemo' ) then
        begin
          if ( not FileExists( ModuleUserPath + 'save' ) )
            then RenameFile( ModuleUserPath + 'savedemo', ModuleUserPath + 'save' )
            else DeleteFile( ModuleUserPath + 'savedemo' );
        end;
      end;
    end
    else
      FMode := MAINMENU_INTRO;
  end;

  FMOTD := AnsiString( LuaSystem.ProtectedCall( [CoreModuleID,'GetMOTD'], [] ) );

  if FMode in [MAINMENU_FIRST,MAINMENU_INTRO] then
  begin
    FIntro1 := AnsiString( LuaSystem.ProtectedCall( [CoreModuleID,'GetLogoBox'], [] ) );
    FIntro2 := AnsiString( LuaSystem.ProtectedCall( [CoreModuleID,'GetLogoText'], [] ) );
  end;

  if GraphicsVersion then
  begin
    FBGTexture   := (IO as TDRLGFXIO).Textures.TextureID['background'];
    FLogoTexture := (IO as TDRLGFXIO).Textures.TextureID[AnsiString( LuaSystem.ProtectedCall( [CoreModuleID,'GetLogoTexture'], [] ) )];
  end;

  if FMode = MAINMENU_MENU then
  begin
    FSaveExists := DRL.SaveExists;
  end;
end;

procedure TMainMenuView.Update( aDTime : Integer; aActive : Boolean );
begin
  if FMode = MAINMENU_KLASS then
  begin
    if FArrayKlass.Size = 1 then
    begin
      FResult.Klass := FArrayKlass[0].NID;
      FMode         := MAINMENU_TRAIT;
      IO.PushLayer( TPlayerView.CreateTrait( True, FResult.Klass ) );
    end;
  end;
  VTIG_Clear;
  if GraphicsVersion then Render;
  if not IO.IsTopLayer( Self ) then
  begin
    ResetSoundCallback;
    Exit;
  end;
  SetSoundCallback;

  if ModErrors.Size > 0 then
  begin
    UpdateModErrors;
    Exit;
  end;

  if not GraphicsVersion then
    if FMode in [MAINMENU_INTRO,MAINMENU_MENU,MAINMENU_DIFFICULTY,MAINMENU_KLASS,MAINMENU_FAIR,MAINMENU_CTYPE,MAINMENU_NAME] then
      RenderASCIILogo;

  case FMode of
    MAINMENU_FIRST      : UpdateFirst;
    MAINMENU_INTRO      : UpdateIntro;
    MAINMENU_MENU       : UpdateMenu;
    MAINMENU_BADSAVE    : UpdateBadSave;
    MAINMENU_SAVECOMPAT : UpdateSaveCompat;
    MAINMENU_DIFFICULTY : UpdateDifficulty;
    MAINMENU_KLASS      : UpdateKlass;
    MAINMENU_FAIR       : UpdateFair;
    MAINMENU_CTYPE      : UpdateChallengeType;
    MAINMENU_NAME       : UpdateName;
    MAINMENU_CPICK      : UpdateChallenge;
    MAINMENU_CFIRST     : UpdateChallenge;
    MAINMENU_CSECOND    : UpdateChallenge;
    MAINMENU_TRAIT      :
    begin
      if TPlayerView.TraitPick = 255 then
      begin
        OnCancel;
        FMode := MAINMENU_MENU;
      end
      else
      begin
        FResult.Trait := TPlayerView.TraitPick;
        if (Option_AlwaysName <> '') or Setting_AlwaysRandomName
          then FMode := MAINMENU_DONE
          else begin
            IO.Root.Console.ShowCursor;
            FName[0] := #0;
            IO.Driver.StartTextInput;
            if IO.IsGamepad then
              DRL.Store.StartText( 'Enter name', 30 );
            FMode := MAINMENU_NAME;
          end;
      end;
    end;
  end;
end;

procedure TMainMenuView.UpdateFirst;
begin
  VTIG_FreeLabel( FFirst, Rectangle(5,2,70,23) );
  if VTIG_EventCancel or VTIG_EventConfirm then
    FMode := MAINMENU_INTRO;
end;

procedure TMainMenuView.UpdateIntro;
begin
  VTIG_FreeLabel( FIntro1, Point( 28, 9 ) );
  VTIG_FreeLabel( FIntro2, Rectangle(2,14,77,12) );

  if VTIG_EventCancel or VTIG_EventConfirm then
    FMode := MAINMENU_DONE;
end;

const
  TextContinueGame  = ' {b--} Continue game {b---}';
  TextNewGame       = ' {b-----} New game {b-----}';
  TextChallengeGame = ' {b--} Challenge game {b--}';
  TextJHC           = ' {B=}{^ Buy JHC on Steam!}{B=}';
  TextShowHighscore = ' {b-} Show highscores {b--}';
  TextShowPlayer    = ' {b---} Show player {b----}';
  TextExit          = ' {b------} Exit {b--------}';
  TextHelp          = ' {b------} Help {b--------}';
  TextSettings      = ' {b----} Settings {b------}';

procedure TMainMenuView.UpdateMenu;
var iSize  : TIOPoint;
    iCount : Byte;
begin
  IO.Root.Console.HideCursor;
  VTIG_PushStyle( @FMenuStyle );
  iSize := Point(34,9);
  iCount := 6;
  if FJHCLink then
  begin
    Inc( iSize.Y );
    Inc( iCount );
  end;
  VTIG_Begin( MAINMENU_ID, iSize, Point( 24, 14 ) );
  VTIG_PopStyle;
    VTIG_PushStyle( @TIGStyleColored );
    if FSaveExists then
      if VTIG_Selectable( TextContinueGame ) then
      begin
        if DRL.LoadSaveFile then
        begin
          FResult.Loaded := True;
          FMode := MAINMENU_DONE;
        end
        else
        begin
          if SaveVersionModule = ''
            then FMode := MAINMENU_BADSAVE
            else FMode := MAINMENU_SAVECOMPAT;
        end;
      end;
    if not FSaveExists then
      if VTIG_Selectable( TextNewGame ) then
      begin
        FResult.Reset;
        ReloadArrays;
        FMode := MAINMENU_DIFFICULTY;
      end;
    if VTIG_Selectable( TextChallengeGame, (not FSaveExists) and FChallenges ) then
    begin
      FResult.Reset;
      ReloadArrays;
      FMode := MAINMENU_CTYPE;
    end;
    if VTIG_Selectable( TextShowHighscore ) then IO.PushLayer( TPagedView.Create( HOF.GetPagedScoreReport ) );
    if VTIG_Selectable( TextShowPlayer )    then IO.PushLayer( TPagedView.Create( HOF.GetPagedPlayerReport ) );
    if VTIG_Selectable( TextHelp )          then IO.PushLayer( THelpView.Create );
    if VTIG_Selectable( TextSettings )      then IO.PushLayer( TSettingsView.Create );
    if FJHCLink then
    begin
      if VTIG_Selectable( TextJHC ) then
        DRL.OpenJHCPage;
    end;
    if VTIG_Selectable( TextExit ) then
    begin
      FResult.Quit := True;
      FMode := MAINMENU_DONE;
    end;
    VTIG_PopStyle;
  VTIG_End;

  VTIG_FreeLabel( FMOTD, Point(2,24) );


  if VTIG_EventCancel then
  begin
    OnCancel;
    if VTIG_Selected( MAINMENU_ID ) = iCount
      then begin FMode := MAINMENU_DONE; FResult.Quit := True; end
      else VTIG_ResetSelect( MAINMENU_ID, iCount );
  end;

  if ForceShop then
  begin
    DRL.OpenJHCPage;
    ForceShop := False;
  end;

  if VTIG_Event( TIG_EV_RESTART ) then
    ForceRestart := CoreModuleID;

  if ForceRestart <> '' then
  begin
    FMode := MAINMENU_DONE;
    DRL.SetState( DSQUIT );
    if FResult <> nil then FResult.Quit := True;
  end;
end;

procedure TMainMenuView.UpdateBadSave;
begin
  VTIG_BeginWindow('Corrupted save file', Point( 42, 13 ), Point(19,8) );
  VTIG_Text('Save file is {!corrupted}, or from a'+#10+'{!previous version}!'+#10+#10+'Version compatibility will be maintained between big versions.'+#10+#10+'{!Removed} corrupted save file, we''re sorry :(. Player and score data are {!intact}.');
  VTIG_End('Press <{!{$input_ok},{$input_escape}}> to continue...');
  if VTIG_EventCancel or VTIG_EventConfirm then
  begin
    FSaveExists := False;
    FMode := MAINMENU_MENU;
  end;
end;

procedure TMainMenuView.UpdateSaveCompat;
begin
  VTIG_BeginWindow('Incompatible save file!', Point( 42, 20 ), Point(19,4) );
  if SaveVersionModule <> VersionModuleSave then
  begin
    VTIG_Text('Save file is from a {!previous version} of the game!');
    VTIG_Text('Save game version : {!'+SaveVersionModule+'}' );
    VTIG_Text('This game version : {!'+VersionModuleSave+'}' );
    VTIG_Text('');
    if DRL.Store.IsSteam
      then VTIG_Text('You can try to download the direct previous version from {!Steam} Betas tab and finish the game, or delete the save file now.')
      else VTIG_Text('You can try downloading the previous version from the web and finish the game, or delete the save file now.');
  end
  else
  begin
    VTIG_Text('Save file uses different mods!');
    VTIG_Text('Save file IDs : {!'+SaveModString+'}' );
    VTIG_Text('Current IDs   : {!'+DRL.Modules.ModString+'}' );
    VTIG_Text('');
    VTIG_Text('You can exit the game and try to match the mods or delete the save file now.');
  end;
  VTIG_Text('');
  if VTIG_Selectable( '  Cancel loading, keep save' ) then
    FMode := MAINMENU_MENU;
  if VTIG_Selectable( '  Delete save file' ) then
  begin
    FSaveExists := False;
    DeleteFile( ModuleUserPath + 'save' );
    FMode := MAINMENU_MENU;
  end;

  VTIG_End;
  if VTIG_EventCancel then
    FMode := MAINMENU_MENU;
end;


procedure TMainMenuView.UpdateFair;
begin
  VTIG_BeginWindow('Warning', Point( 40, 9 ), Point(21,14) );
  VTIG_PushStyle( @TIGStyleColored );
  VTIG_Text('Are you sure? This difficulty level isn''t even remotely fair!');
  VTIG_Text('');

  if VTIG_Selectable( 'Bring it on!' ) then
    FMode := MAINMENU_KLASS;
  if VTIG_Selectable( 'Cancel' ) then
    FMode := MAINMENU_DIFFICULTY;
  VTIG_PopStyle;
  VTIG_End();
  if VTIG_EventCancel then
  begin
    OnCancel;
    FMode := MAINMENU_DIFFICULTY;
  end;
end;

procedure TMainMenuView.UpdateName;
var iStoreText   : Ansistring;
    iStoreCancel : Boolean;
begin
  VTIG_PushStyle( @FWindowStyle );
  VTIG_Begin( 'mainmenu_name', Point( 36, 4 ), Point(23,18) );
  VTIG_PopStyle;
  VTIG_PushStyle( @TIGStyleColored );
  VTIG_Text('Type a name for your character');
  if VTIG_Input(@FName[0],48) then
  begin
    FResult.Name := AnsiString(FName);
    IO.Driver.StopTextInput;
    IO.Root.Console.HideCursor;
    FMode := MAINMENU_DONE;
  end;
  if DRL.Store.GetText( iStoreText, @iStoreCancel ) then
  begin
    IO.Driver.StopTextInput;
    IO.Root.Console.HideCursor;
    if iStoreCancel then
    begin
      OnCancel;
      FMode := MAINMENU_MENU;
    end
    else
    begin
      FResult.Name := iStoreText;
      FMode := MAINMENU_DONE;
    end;
  end;
  VTIG_PopStyle;
  VTIG_End();

  if VTIG_EventCancel then
  begin
    IO.Driver.StopTextInput;
    IO.Root.Console.HideCursor;
    OnCancel;
    FMode := MAINMENU_MENU;
  end;
end;

procedure TMainMenuView.UpdateDifficulty;
var iSelected, i, iLines : Integer;
    iWindowID            : AnsiString;
begin
  if FArrayDiff.Size < 2 then
  begin
    FResult.Difficulty := 0;
    FMode := MAINMENU_KLASS;
    Exit;
  end;
  if ModuleOption_NewMenu then
  begin
    iLines := 13;
    if FArrayDiff[FArrayDiff.Size-1].Allow then iLines -= 2;

    if FResult.Challenge = ''
      then iWindowID := 'mainmenu_difficulty'
      else iWindowID := 'mainmenu_difficulty_chal';
    iSelected := VTIG_Selected(iWindowID);
    if ( iSelected < 0 ) or (iSelected >= FArrayDiff.Size) then iSelected := 0;
    VTIG_PushStyle( @FWindowStyle );
    VTIG_Begin( 'mainmenu_difficulty_desc', Point( 49, iLines ), Point( 29, 16 ) );
    VTIG_PopStyle;
      VTIG_PushStyle( @TIGStyleColored );
      VTIG_Text( Padded( '- {!' + FArrayDiff[iSelected].Name + ' }', 48, '-' ) );
      VTIG_PopStyle;
      VTIG_Text( FArrayDiff[iSelected].Desc );
      if not FArrayDiff[iSelected].Allow then VTIG_Text( FArrayDiff[iSelected].Extra );
    VTIG_End;

    VTIG_PushStyle( @TIGStyleFrameless );
    VTIG_Begin( iWindowID, Point( 17, 2+FArrayDiff.Size ), Point( 9, 16 ) );
    VTIG_PopStyle;
      VTIG_PushStyle( @TIGStyleColored );
      for i := 0 to FArrayDiff.Size - 1 do
        if VTIG_Selectable( FArrayDiff[i].Name, FArrayDiff[i].Allow ) then
        begin
          FResult.Difficulty := FArrayDiff[i].NID;
          if FResult.Difficulty >= 5
            then FMode := MAINMENU_FAIR
            else FMode := MAINMENU_KLASS;
        end;
      iSelected := VTIG_Selected;
      VTIG_PopStyle;
    VTIG_End;
  end
  else
  begin
    VTIG_PushStyle( @TIGStyleFrameless );
    VTIG_Begin( 'mainmenu_difficulty', Point( 26, 9 ), Point( 29, 16 ) );
    VTIG_PopStyle;
      VTIG_PushStyle( @TIGStyleColored );
      for i := 0 to FArrayDiff.Size - 1 do
        if VTIG_Selectable( FArrayDiff[i].Name, FArrayDiff[i].Allow ) then
        begin
          FResult.Difficulty := FArrayDiff[i].NID;
          if FResult.Difficulty >= 5
            then FMode := MAINMENU_FAIR
            else FMode := MAINMENU_KLASS;
        end;
      VTIG_PopStyle;
    VTIG_End;
  end;

  if VTIG_EventCancel then
  begin
    FMode := MAINMENU_MENU;
    OnCancel;
  end;
end;

procedure TMainMenuView.UpdateKlass;
var iSelected, i, iLines : Integer;
begin
  iSelected := VTIG_Selected('mainmenu_klass');
  if ( iSelected < 0 ) or (iSelected >= FArrayKlass.Size) then iSelected := 0;
  iLines := 9;
  if Length( FArrayKlass[iSelected].Desc ) > 200 then iLines := 13;
  VTIG_PushStyle( @FWindowStyle );
  VTIG_Begin( 'mainmenu_klass_desc', Point( 49, iLines ), Point( 29, 16 ) );
  VTIG_PopStyle;
    VTIG_PushStyle( @TIGStyleColored );
    VTIG_Text( Padded( '- {!' + FArrayKlass[iSelected].Name + ' }', 48, '-' ) );
    VTIG_PopStyle;
    VTIG_Text( FArrayKlass[iSelected].Desc );
  VTIG_End;

  VTIG_PushStyle( @TIGStyleFrameless );
  VTIG_Begin( 'mainmenu_klass', Point( 16, 2+FArrayKlass.Size ), Point( 10, 16 ) );
  VTIG_PopStyle;
    if not FFKlassPick then
    begin
      for i := 0 to FArrayKlass.Size - 1 do
        if FArrayKlass[i].Allow then
        begin
          VTIG_ResetSelect( '', i );
          Break;
        end;
      FFKlassPick := True;
    end;

    VTIG_PushStyle( @TIGStyleColored );
    for i := 0 to FArrayKlass.Size - 1 do
      if VTIG_Selectable( FArrayKlass[i].Name, FArrayKlass[i].Allow ) then
      begin
        FResult.Klass := FArrayKlass[i].NID;
        FMode         := MAINMENU_TRAIT;
        IO.PushLayer( TPlayerView.CreateTrait( True, FResult.Klass ) );
      end;
    iSelected := VTIG_Selected;
    VTIG_PopStyle;
  VTIG_End;

  if VTIG_EventCancel then
  begin
    FMode := MAINMENU_MENU;
    OnCancel;
  end;
end;

procedure TMainMenuView.UpdateChallengeType;
var iSelected, i : Integer;
begin
  iSelected := VTIG_Selected('mainmenu_ctype');
  if ( iSelected < 0 ) or (iSelected >= FArrayCType.Size) then iSelected := 0;
  VTIG_PushStyle( @FWindowStyle );
  VTIG_Begin( 'mainmenu_ctype_desc', Point( 49, 8 ), Point( 29, 16 ) );
  VTIG_PopStyle;
    VTIG_PushStyle( @TIGStyleColored );
    VTIG_Text( Padded( '- {!' + FArrayCType[iSelected].Name + ' }', 48, '-' ) );
    VTIG_PopStyle;
    VTIG_Text( FArrayCType[iSelected].Desc );
    if not FArrayCType[iSelected].Allow then
    begin
      VTIG_Text('');
      VTIG_Text(FArrayCType[iSelected].Extra);
    end;
  VTIG_End;

  VTIG_PushStyle( @TIGStyleFrameless );
  VTIG_Begin( 'mainmenu_ctype', Point( 19, 5 ), Point( 9, 18 ) );
  VTIG_PopStyle;
    VTIG_PushStyle( @TIGStyleColored );
    for i := 0 to FArrayCType.Size - 1 do
      if VTIG_Selectable( FArrayCType[i].Name, FArrayCType[i].Allow ) then
      begin
        ReloadChallenge( i+1 );
        if i = 1
          then FMode := MAINMENU_CFIRST
          else FMode := MAINMENU_CPICK;
      end;
    iSelected := VTIG_Selected;
    VTIG_PopStyle;
  VTIG_End;

  if VTIG_EventCancel then
  begin
    FMode := MAINMENU_MENU;
    OnCancel;
  end;
end;

procedure TMainMenuView.UpdateChallenge;
var iSelect : Integer;
    iCount  : Byte;
    iPick   : Integer;
    iRank   : AnsiString;
begin
  VTIG_BeginWindow( FTitleChal, 'challenges_view', FSize );
    iSelect := -1;
    iPick   := -1;

    VTIG_BeginGroup( 28 );
      VTIG_PushStyle( @TIGStyleColored );
      for iCount := 0 to FArrayChal.Size-1 do
        if VTIG_Selectable( FArrayChal[iCount].Name, FArrayChal[iCount].Allow ) then
          iPick := iCount;
      iSelect := VTIG_Selected;
      VTIG_PopStyle;

      VTIG_EndGroup;

      VTIG_BeginGroup;
      if iSelect >= 0 then
      begin
          VTIG_Text( FArrayChal[iSelect].Name, VTIGDefaultStyle.Color[ VTIG_TITLE_COLOR ] );
          VTIG_Ruler;
          VTIG_Text( 'Rating: {!'+FArrayChal[iSelect].Extra+'}'#10#10+FArrayChal[iSelect].Desc );
          if not FArrayChal[iSelect].Allow then
          begin
            iRank := LuaSystem.Get( ['ranks','skill',FArrayChal[iSelect].Req+1,'name'] );
            VTIG_Text('');
            VTIG_Text( 'Reach {y'+iRank+'} rank to unlock!' );
          end;
      end;
      VTIG_EndGroup;

  VTIG_End('{l<{!{$input_up}},{!{$input_down}}> select, <{!{$input_ok}}> select, <{!{$input_escape}}> cancel}');

  if VTIG_EventCancel then
  begin
    OnCancel;
    FMode := MAINMENU_MENU;

  end
  else if iPick >= 0 then
  begin
    case FMode of
      MAINMENU_CPICK   : begin FResult.Challenge := FArrayChal[iPick].ID;  FMode := MAINMENU_DIFFICULTY; end;
      MAINMENU_CFIRST  : begin FResult.Challenge := FArrayChal[iPick].ID;  FMode := MAINMENU_CSECOND; ReloadChallenge( CTYPE_SECOND ); end;
      MAINMENU_CSECOND : begin FResult.SChallenge := FArrayChal[iPick].ID; FMode := MAINMENU_DIFFICULTY; end;
    end;
    ReloadArrays;
  end;
end;

procedure TMainMenuView.OnCancel;
begin
  if (not Option_Sound) or (Sound = nil) or ( not Setting_MenuSound ) then Exit;
  if Sound.SampleExists('menu.cancel') then Sound.PlaySample('menu.cancel');
end;

procedure SoundCallback( aEvent : TTIGSoundEvent; aParam : Pointer );
begin
  if (not Option_Sound) or (Sound = nil) or ( not Setting_MenuSound ) then Exit;
  case aEvent of
    VTIG_SOUND_CHANGE : if Sound.SampleExists('menu.change') then Sound.PlaySample('menu.change');
    VTIG_SOUND_ACCEPT : if Sound.SampleExists('menu.pick')   then Sound.PlaySample('menu.pick');
  end;
end;

procedure TMainMenuView.SetSoundCallback;
begin
  VTIG_GetIOState.SoundCallback := @SoundCallback;
end;

procedure TMainMenuView.ResetSoundCallback;
begin
  VTIG_GetIOState.SoundCallback := nil;
end;


procedure TMainMenuView.Render;
var iIO        : TDRLGFXIO;
    iMin, iMax : TGLVec2f;
    iSize      : TGLVec2f;
begin
  iIO := IO as TDRLGFXIO;
  Assert( iIO <> nil );
  iSize.Init( IO.Driver.GetSizeX, IO.Driver.GetSizeY );
  iIO.RenderUIBackground( FBGTexture );

  if FMode = MAINMENU_FIRST then
    IO.RenderUIBackgroundBlock( Point(4,1), Point(76,24), 0.7 );

  if ( FMode in [MAINMENU_INTRO,MAINMENU_MENU,MAINMENU_DIFFICULTY,MAINMENU_KLASS,MAINMENU_FAIR,MAINMENU_NAME,MAINMENU_CTYPE] )
    and IO.IsTopLayer( Self ) then
  begin
    iMin.Y  := Floor(iSize.Y / 25) * (-8);
    if (FMode <> MAINMENU_INTRO)
      then begin iMax.Y  := Floor(iSize.Y / 25) * 24; iMin.Y := Floor(iSize.Y / 25) * (-10); end
      else iMax.Y  := Floor(iSize.Y / 25) * 18;
    iMin.X  := (iSize.X - (iMax.Y - iMin.Y)) / 2;
    iMax.X  := (iSize.X + (iMax.Y - iMin.Y)) / 2;

    iIO.QuadSheet.PushTexturedQuad(
      GLVec2i(Floor(iMin.X), Floor(iMin.Y)),
      GLVec2i(Floor(iMax.X), Floor(iMax.Y)),
      GLVec2f( 0,0 ), GLVec2f( 1,1 ),
      iIO.Textures.Texture[ FLogoTexture ].GLTexture
    );

    case FMode of
      MAINMENU_INTRO : begin
        IO.RenderUIBackgroundBlock( Point(25,9), Point(55,13), 0.7 );
        IO.RenderUIBackgroundBlock( Point(1,14), Point(79,25), 0.7 );
      end;
      MAINMENU_MENU : begin
        IO.RenderUIBackgroundBlock( Point(0,24),  Point(80,25), 0.7 );
      end;
    end;

  end;

end;


function TMainMenuView.IsFinished : Boolean;
begin
  Exit( FMode = MAINMENU_DONE );
end;

function TMainMenuView.IsModal : Boolean;
begin
  Exit( True );
end;

procedure TMainMenuView.ReloadArrays;
var iEntry : TMainMenuEntry;
    iTable : TLuaTable;
    iCount : Word;
    iSkill : Integer;
begin
  if FArrayCType = nil then FArrayCType := TMainMenuEntryArray.Create;
  if FArrayDiff  = nil then FArrayDiff  := TMainMenuEntryArray.Create;
  if FArrayKlass = nil then FArrayKlass := TMainMenuEntryArray.Create;
  FArrayCType.Clear;
  FArrayDiff.Clear;
  FArrayKlass.Clear;

  iSkill := HOF.GetRank('skill');

  ChallengeType[1].Allow := (iSkill > 0) or (GodMode) or (Setting_UnlockAll);
  ChallengeType[2].Allow := (iSkill > 3) or (GodMode) or (Setting_UnlockAll);
  ChallengeType[3].Allow := (iSkill > 4) or (GodMode) or (Setting_UnlockAll);
  FArrayCType.Push( ChallengeType[1] );
  FArrayCType.Push( ChallengeType[2] );
  FArrayCType.Push( ChallengeType[3] );

  for iTable in LuaSystem.ITables('diff') do
  with iTable do
  begin
    iEntry.Allow := True;
    if (FResult.Challenge <> '') and (not GetBoolean( 'challenge' )) then Continue;
    if GetInteger('req_skill',0) > iSkill then iEntry.Allow := Setting_UnlockAll;
    iEntry.Name := GetString('name');
    iEntry.Desc := GetString('desc','');
    iEntry.Extra:= GetString('desc_unlock','');
    iEntry.ID   := GetString('id');
    iEntry.NID  := GetInteger('nid');
    iEntry.Req  := 0;
    FArrayDiff.Push( iEntry );
  end;

  for iCount := 1 to LuaSystem.Get(['klasses','__counter']) do
    with LuaSystem.GetTable([ 'klasses', iCount ]) do
    try
      if not GetBoolean( 'hidden',False ) then
      begin
        iEntry.Name  := GetString('name');
        iEntry.Desc  := GetString('desc');
        iEntry.ID    := GetString('id');
        iEntry.Extra := '';
        iEntry.NID   := GetInteger('nid');
        iEntry.Allow := IsFunction('OnPick');
        iEntry.Req  := 0;
        FArrayKlass.Push( iEntry );
      end;
    finally
      Free;
    end;
end;

procedure TMainMenuView.ReloadChallenge( aType : Byte );
var iChalCount  : DWord;
    iChoices    : DWord;
    iCount      : Integer;
    iPrefix     : Ansistring;
    iChallenges : array of Byte;
    iEntry      : TMainMenuEntry;
    iValue      : TLuaValue;
begin
  VTIG_EventClear;
  VTIG_ResetSelect( 'challenges_view' );

  if FArrayChal = nil then FArrayChal := TMainMenuEntryArray.Create;
  FArrayChal.Clear;
  iChalCount  := LuaSystem.Get(['chal','__counter']);
  iChallenges := nil;
  iChoices    := 0;
  iPrefix     := '';

  SetLength( iChallenges, iChalCount );

  case aType of
    CTYPE_ANGEL  : begin
      FTitleChal := 'Choose your Challenge';
      for iCount := 1 to iChalCount do
        iChallenges[iCount-1] := iCount;
      iChoices := iChalCount;
    end;
    CTYPE_DANGEL : begin
      FTitleChal := 'Choose your Primary Challenge';
      for iCount := 1 to iChalCount do
        if LuaSystem.Defined([ 'chal', iCount, 'secondary' ]) then
        begin
          iChallenges[iChoices] := iCount;
          Inc( iChoices );
        end;
    end;
    CTYPE_AANGEL : begin
      FTitleChal := 'Choose your Arch-Challenge';
      FResult.ArchAngel := True;
      iPrefix := 'arch_';
      for iCount := 1 to iChalCount do
        if LuaSystem.Defined([ 'chal', iCount, 'arch_name' ]) then
        begin
          iChallenges[iChoices] := iCount;
          Inc( iChoices );
        end;
    end;
//        CTYPE_CUSTOM = 4;
    CTYPE_SECOND : begin
      FTitleChal := 'Choose your Secondary Challenge';
      with LuaSystem.GetTable([ 'chal', FResult.Challenge, 'secondary' ]) do
      try
        for iValue in Values do
        begin
          iChallenges[iChoices] := LuaSystem.Get( ['chal','challenge_'+LowerCase(iValue.ToString),'nid'] );
          Inc( iChoices );
        end;
      finally
        Free;
      end;
    end;
  end;
  SetLength( iChallenges, iChoices );

  for iCount := 0 to High( iChallenges ) do
    with LuaSystem.GetTable([ 'chal', iChallenges[iCount] ]) do
    try
      iEntry.Name  := GetString(iPrefix+'name');
      iEntry.Desc  := GetString(iPrefix+'description');
      iEntry.Extra := GetString(iPrefix+'rating');
      if iEntry.Extra = '' then iEntry.Extra := 'UNRATED';
      iEntry.ID    := GetString('id');
      iEntry.NID   := iChallenges[iCount];
      iEntry.Req   := GetInteger(iPrefix+'rank',0);
      iEntry.Allow := (HOF.GetRank('skill') >= iEntry.Req) or (GodMode) or (Setting_UnlockAll);
      FArrayChal.Push( iEntry );
    finally
      Free;
    end;
end;

procedure TMainMenuView.UpdateModErrors;
var i, iM : Integer;
begin
  VTIG_BeginWindow('Mod loading errors', Point( 70, -1 ) );
  VTIG_Text('{!There were errors while loading mods - fix, remove or disable!} ');
  VTIG_Text('');
  iM := Min( ModErrors.Size, 8 );
  for i := 0 to iM - 1 do
    VTIG_Text(ModErrors[i], LIGHTRED );
  if ModErrors.Size > 12
    then VTIG_Text('... and '+IntToStr( ModErrors.Size - 8 )+' more error line(s).' );
  VTIG_Text('');
  VTIG_Text('You can ignore and proceed the errors are just version compatibility errors, otherwise the game might be unstable.');
  VTIG_Text('If you''re working on a mod, you can edit it and press {!Ctrl}+{!F1} to reload.');
  VTIG_End('Press <{!{$input_escape}}> to continue...');
  if VTIG_Event( TIG_EV_RESTART ) then
  begin
    ForceRestart := CoreModuleID;
    FMode := MAINMENU_MENU;
    ModErrors.Clear;
  end;

  if VTIG_EventCancel then
    ModErrors.Clear;
end;

procedure TMainMenuView.RenderASCIILogo;
var iCount  : Integer;
    iString : AnsiString;
begin
  if GraphicsVersion then Exit;

  if IO.Ascii.Exists('logo') then
  begin
    iCount := 0;
    for iString in IO.Ascii['logo'] do
    begin
      VTIG_FreeLabel( iString, Point( 17, iCount ) );
      Inc( iCount );
    end;
  end;
end;

destructor TMainMenuView.Destroy;
begin
  FreeAndNil( FArrayCType );
  FreeAndNil( FArrayDiff );
  FreeAndNil( FArrayKlass );
  FreeAndNil( FArrayChal );
  ResetSoundCallback;
  inherited Destroy;
end;

end.

