{$INCLUDE drl.inc}
unit drlcommand;
interface
uses vrltools, dfitem, dfdata;

type TCommand = object
  Command : Byte;
  Target  : TCoord2D;
  Item    : TItem;
  Slot    : TEqSlot;
  Alt     : Boolean;
  ID      : AnsiString;

  class function Create( aCommand : Byte ) : TCommand; static;
  class function Create( aCommand : Byte; aTarget : TCoord2D; aAlt : Boolean = False ) : TCommand; static;
  class function Create( aCommand : Byte; aID : AnsiString ) : TCommand; static;
  class function Create( aCommand : Byte; aItem : TItem ) : TCommand; static;
  class function Create( aCommand : Byte; aItem : TItem; aAlt : Boolean ) : TCommand; static;
  class function Create( aCommand : Byte; aItem : TItem; aSlot : TEqSlot ) : TCommand; static;
  class function Create( aCommand : Byte; aItem : TItem; aID : AnsiString ) : TCommand; static;
  class function Create( aCommand : Byte; aTarget : TCoord2D; aItem : TItem ) : TCommand; static;
end;

implementation

class function TCommand.Create( aCommand : Byte ) : TCommand;
begin
  Result.Command := aCommand;
  Result.Target  := NewCoord2D(0,0);
end;

class function TCommand.Create( aCommand : Byte; aTarget : TCoord2D; aAlt : Boolean = False ) : TCommand;
begin
  Result.Command := aCommand;
  Result.Target  := aTarget;
  Result.Alt     := aAlt;
end;

class function TCommand.Create( aCommand : Byte; aID : AnsiString ) : TCommand;
begin
  Result.Command := aCommand;
  Result.Item    := nil;
  Result.ID      := aID;
end;

class function TCommand.Create( aCommand : Byte; aItem : TItem ) : TCommand;
begin
  Result.Command := aCommand;
  Result.Item    := aItem;
  Result.ID      := '';
  Result.Alt     := False;
end;

class function TCommand.Create( aCommand : Byte; aItem : TItem; aAlt : Boolean ) : TCommand;
begin
  Result.Command := aCommand;
  Result.Item    := aItem;
  Result.ID      := '';
  Result.Alt     := aAlt;
end;

class function TCommand.Create( aCommand : Byte; aItem : TItem; aSlot : TEqSlot ) : TCommand;
begin
  Result.Command := aCommand;
  Result.Item    := aItem;
  Result.Slot    := aSlot;
  Result.ID      := '';
  Result.Alt     := False;
end;

class function TCommand.Create( aCommand : Byte; aItem : TItem; aID : AnsiString ) : TCommand;
begin
  Result.Command := aCommand;
  Result.Item    := aItem;
  Result.Id      := aID;
  Result.Alt     := False;
end;

class function TCommand.Create( aCommand : Byte; aTarget : TCoord2D; aItem : TItem ) : TCommand; static;
begin
  Result.Command := aCommand;
  Result.Target  := aTarget;
  Result.Item    := aItem;
  Result.Id      := '';
end;

end.
