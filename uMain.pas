unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  Controls, Forms, Graphics, Dialogs, Vcl.Menus,
  Vcl.ExtCtrls;

const
  FIELD_WIDTH = 10;
  FIELD_HEIGHT = 23;
  FIGURE_LENGTH = 4;
  FIGURE_NUMBER = 36;

type
  TfMain = class(TForm)
    GameTimer: TTimer;
    MainMenu1: TMainMenu;
    GameItems: TMenuItem;
    StartItem: TMenuItem;
    StopItem: TMenuItem;
    N4: TMenuItem;
    ExitItem: TMenuItem;
    PauseItem: TMenuItem;
    procedure StartItemClick(Sender: TObject);
    procedure GameTimerTimer(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure StopItemClick(Sender: TObject);
    procedure ExitItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure PauseItemClick(Sender: TObject);
  private
    FFigureTop: Integer;
    FFigureLeft: Integer;
    FFirstTime: Boolean;

    FFigureRotationCenterX: Integer;
    FFigureRotationCenterY: Integer;

    FFigure: array [1 .. FIGURE_LENGTH, 1 .. FIGURE_LENGTH] of Integer;
    FGameField: array [1 .. FIELD_WIDTH, 1 .. FIELD_HEIGHT] of Integer;

    FTransferring: Boolean;
    FNewFigure: Integer;

    FStepX: Integer;
    FStepY: Integer;

    FBurnedLineNumber: Integer;
    FLineValue: Integer;
    FScore: Integer;
    FLevel: Integer;

    FGamePaused: Boolean;
    FGameStopped: Boolean;

    procedure FindFigureCenter;
    procedure GenerateNewFigure;

    procedure ValidateFigure;
    procedure DrawFigure(AWithBorder: Boolean = True);
    function CanMoveFigureDown: Boolean;
    function CanShiftFigure(ALeftShift: Boolean): Boolean;
    procedure MoveFigureDown;
    procedure ShiftFigure(ALeftShift: Boolean);
    procedure TurnFigure(ALeftRotation: Boolean);
    procedure PutFigure;

    procedure CheckLine;
    procedure BurnLine(ALine: Integer; ABeforeBurnedLines: Integer);

    procedure ResetGameField;
    procedure Remeasure;

    procedure ValidateScore;
    procedure RefreshScore;
  public
    procedure InvalidateWorkArea(ABeforeGame: Boolean);
    procedure DrawItem(ALeft, ATop: Integer; AStyle: Integer);

    procedure StopGame;
    procedure PauseGame;
  end;

var
  fMain: TfMain;

implementation

const
  S_GAME_OVER = 'Game Over';
  S_GAME_RESUME = 'Продолжить';
  S_GAME_PAUSE = 'Пауза';
  S_PAUSE_MESSAGE = 'Пауза';

  S_FIGURES_LIST = '1000000000000000' +
                   '1110001000000000' +
                   '1110100000000000' +
                   '0100111000000000' +
                   '0110110000000000' +
                   '1100011000000000' +
                   '1111000000000000' +
                   '0000011001100000' +
                   '0100111001000000' +
                 // -------------------
                   '2000000000000000' +
                   '2220002000000000' +
                   '2220200000000000' +
                   '0200222000000000' +
                   '0220220000000000' +
                   '2200022000000000' +
                   '2222000000000000' +
                   '0000022002200000' +
                   '0200222002000000' +
                 // -------------------
                   '3000000000000000' +
                   '3330003000000000' +
                   '3330300000000000' +
                   '0300333000000000' +
                   '0330330000000000' +
                   '3300033000000000' +
                   '3333000000000000' +
                   '0000033003300000' +
                   '0300333003000000' +
                 // -------------------
                   '4000000000000000' +
                   '4440004000000000' +
                   '4440400000000000' +
                   '0400444000000000' +
                   '0440440000000000' +
                   '4400044000000000' +
                   '4444000000000000' +
                   '0000044004400000' +
                   '0400444004000000';

  GAME_FIELD_COLOR = $333333;

  BCOLOR_1 = $CCFFFF;
  PCOLOR_1 = $66CCFF;

  BCOLOR_2 = $CCCCFF;
  PCOLOR_2 = $9999CC;

  BCOLOR_3 = $FF3333;
  PCOLOR_3 = $FF9966;

  BCOLOR_4 = $990099;
  PCOLOR_4 = $996699;

  SCORE_SPACE = 10;
  SCORE_SHIFT = 10;

  START_INTERVAL = 500;
  MAX_LEVEL = 10;
  START_LINE_VALUE = 5;
  LEVEL_STEP = 10;

  S_SCORE = 'Очки: ';
  S_LINES = 'Линии: ';
  S_LEVEL = 'Уровень: ';
  S_NEXT_FIGURE = 'Следующая:';

{$R *.DFM}

procedure TfMain.ResetGameField;
var
  I, J: Integer;
begin
  for I := 1 to FIELD_WIDTH do
    for J := 1 to FIELD_HEIGHT do
      FGameField[I, J] := 0;
end;

procedure TfMain.StartItemClick(Sender: TObject);
begin
  if FGamePaused then
  begin
    PauseGame;
    Exit;
  end;

  FBurnedLineNumber := 0;
  FLineValue := START_LINE_VALUE;
  FScore := 0;
  FLevel := 1;
  FFirstTime := False;
  FTransferring := False;
  FGamePaused := False;
  FGameStopped := False;

  Randomize;
  Remeasure;
  ResetGameField;
  InvalidateWorkArea(True);

  FNewFigure := Random(FIGURE_NUMBER - 1);
  // RefreshScore;
  GenerateNewFigure;

  GameTimer.Interval := START_INTERVAL;
  GameTimer.Enabled := True;
  StopItem.Enabled := True;
  PauseItem.Enabled := True;
end;

procedure TfMain.DrawItem(ALeft, ATop: Integer; AStyle: Integer);
begin
  with Canvas do
  begin
    case AStyle of
      0:
        begin
          Pen.Color := GAME_FIELD_COLOR;
          Brush.Color := GAME_FIELD_COLOR;
        end;
      2:
        begin
          Pen.Color := PCOLOR_2;
          Brush.Color := BCOLOR_2;
        end;
      3:
        begin
          Pen.Color := PCOLOR_3;
          Brush.Color := BCOLOR_3;
        end;
      4:
        begin
          Pen.Color := PCOLOR_4;
          Brush.Color := BCOLOR_4;
        end;
    else
      begin
        Pen.Color := PCOLOR_1;
        Brush.Color := BCOLOR_1;
      end;
    end;
    // If AStyle = 0 Then
    Rectangle(ALeft, ATop, ALeft + FStepX, ATop + FStepY)
    { Else
      Ellipse( ALeft, ATop, ALeft + FStepX, ATop + FStepY ); }
  end;
end;

procedure TfMain.InvalidateWorkArea(ABeforeGame: Boolean);
var
  I, J: Integer;
  RectLeft, RectTop: Integer;

  procedure _OutMessage(const AMessage: string);
  var
    tWidth, tHeight, RectLeft, RectTop: Integer;
  begin
    with Canvas do
    begin
      Font.Size := 14;
      tWidth := TextWidth(AMessage);
      tHeight := TextHeight(AMessage);
      RectLeft := (FIELD_WIDTH * FStepX - tWidth) div 2;
      RectTop := (FIELD_HEIGHT * FStepY - tHeight) div 2;
      Font.Color := clWhite;
      Brush.Color := GAME_FIELD_COLOR;
      TextRect(Rect(RectLeft, RectTop, RectLeft + tWidth, RectTop + tHeight), RectLeft, RectTop, AMessage);
    end;
  end;

begin
  if FFirstTime or FGamePaused then
    with Canvas do
    begin
      Pen.Color := GAME_FIELD_COLOR;
      Brush.Color := GAME_FIELD_COLOR;
      Rectangle(0, 0, FIELD_WIDTH * FStepX, FIELD_HEIGHT * FStepX);
      if FGamePaused then
        _OutMessage(S_PAUSE_MESSAGE);
      Exit;
    end;

  RectLeft := 0;

  for I := 1 to FIELD_WIDTH do
  begin
    RectTop := 0;
    for J := 1 to FIELD_HEIGHT do
    begin
      DrawItem(RectLeft, RectTop, FGameField[I, J]);
      Inc(RectTop, FStepY);
    end;
    Inc(RectLeft, FStepX);
  end;

  if not ABeforeGame and FGameStopped then
    _OutMessage(S_GAME_OVER);
end;

procedure TfMain.FindFigureCenter;
var
  I, J, Line, Fill: Integer;
begin
  FFigureRotationCenterX := 0;
  Fill := 0;
  for I := FIGURE_LENGTH downto 1 do
  begin
    Line := 0;
    for J := FIGURE_LENGTH downto 1 do
      if FFigure[I, J] <> 0 then
        Inc(Line);
    Inc(FFigureRotationCenterX, Line * I);
    Inc(Fill, Line);
  end;
  if Fill = 0 then
  begin
    StopGame;
    Exit;
  end;
  FFigureRotationCenterX := Round(FFigureRotationCenterX / Fill);

  FFigureRotationCenterY := 0;
  Fill := 0;
  for J := FIGURE_LENGTH downto 1 do
  begin
    Line := 0;
    for I := FIGURE_LENGTH downto 1 do
      if FFigure[I, J] <> 0 then
        Inc(Line);
    Inc(FFigureRotationCenterY, Line * J);
    Inc(Fill, Line);
  end;
  FFigureRotationCenterY := Round(FFigureRotationCenterY / Fill);
end;

procedure TfMain.GenerateNewFigure;
var
  I, J, NewFigure: Integer;
begin
  FFigureLeft := FIELD_WIDTH div 2;

  NewFigure := FNewFigure * FIGURE_LENGTH * FIGURE_LENGTH;
  for I := FIGURE_LENGTH downto 1 do
    for J := FIGURE_LENGTH downto 1 do
      FFigure[I, J] := StrToInt(S_FIGURES_LIST[NewFigure + (I - 1) * FIGURE_LENGTH + J]);
  Randomize;
  FNewFigure := Random(FIGURE_NUMBER - 1);

  for I := 1 to FIGURE_LENGTH do
  begin
    FFigureTop := 0;
    for J := FIGURE_LENGTH downto 1 do
      if FFigure[I, J] <> 0 then
        Inc(FFigureTop);
    if FFigureTop <> 0 then
    begin
      FFigureTop := 1 - I;
      break;
    end;
  end;

  FindFigureCenter;

  if not CanMoveFigureDown then
  begin
    Inc(FFigureTop);
    StopGame;
    Exit;
  end;

  Inc(FFigureTop);
  DrawFigure(True);
  RefreshScore;
end;

function TfMain.CanMoveFigureDown: Boolean;
var
  I, J: Integer;
begin
  Result := True;
  for I := 1 to FIGURE_LENGTH do
  begin
    for J := FIGURE_LENGTH downto 1 do
      if FFigure[I, J] <> 0 then
      begin
        Result := (FFigureTop + J <= FIELD_HEIGHT) and (FGameField[FFigureLeft + I - 1, FFigureTop + J] = 0);
        break;
      end;
    if not Result then
      Exit;
  end;
end;

procedure TfMain.DrawFigure(AWithBorder: Boolean);
var
  I, J: Integer;
  RectLeft, RectTop, SaveTop: Integer;
begin
  if FFigureLeft > 1 then
    RectLeft := (FFigureLeft - 2) * FStepX
  else
    RectLeft := 0;
  if FFigureTop > 1 then
    SaveTop := (FFigureTop - 2) * FStepY
  else
    SaveTop := 0;

  for I := 0 to FIGURE_LENGTH + 1 do
    if (FFigureLeft + I > 1) and (FFigureLeft + I - 1 <= FIELD_WIDTH) then
    begin
      RectTop := SaveTop;
      for J := 0 to FIGURE_LENGTH + 1 do
        if (FFigureTop + J > 1) and (FFigureTop + J - 1 <= FIELD_HEIGHT) then
        begin
          if ((I <> 0) and (I <> FIGURE_LENGTH + 1) and (J <> 0) and (J <> FIGURE_LENGTH + 1) and (FFigure[I, J] <> 0)) then
            DrawItem(RectLeft, RectTop, FFigure[I, J])
          else
            DrawItem(RectLeft, RectTop, FGameField[FFigureLeft + I - 1, FFigureTop + J - 1]);
          Inc(RectTop, FStepY);
        end;
      Inc(RectLeft, FStepX);
    end;
end;

procedure TfMain.ValidateFigure;
var
  I, J{, RectLeft, SaveTop}: Integer;
begin
//  RectLeft := (FFigureLeft - 1) * FStepX;
//  SaveTop := (FFigureTop - 1) * FStepY;
  for I := 1 to FIGURE_LENGTH do
    if FFigureLeft + I - 1 <= FIELD_WIDTH then
    begin
      //RectTop := SaveTop;
      for J := 1 to FIGURE_LENGTH do
        if FFigureTop + J - 1 <= FIELD_HEIGHT then
        begin
          if FFigure[I, J] <> 0 then
            FGameField[FFigureLeft + I - 1, FFigureTop + J - 1] := FFigure[I, J];
          //Inc(RectTop);
        end;
     // Inc(RectLeft);
    end;
  CheckLine;
  GenerateNewFigure;
end;

procedure TfMain.MoveFigureDown;
var
  I, RectLeft, RectTop: Integer;
begin
  if FTransferring then
    Exit;

  FTransferring := True;
  try
    RectLeft := (FFigureLeft - 1) * FStepX;
    RectTop := (FFigureTop - 1) * FStepY;
    if not CanMoveFigureDown then
    begin
      ValidateFigure;
      Exit;
    end;

    Inc(FFigureTop);

    for I := 1 to FIGURE_LENGTH do
    begin
      if FFigure[I, 1] <> 0 then
        DrawItem(RectLeft, RectTop, 0);
      Inc(RectLeft, FStepX);
    end;
    DrawFigure(True);
  finally
    FTransferring := False;
  end;
end;

function TfMain.CanShiftFigure(ALeftShift: Boolean): Boolean;
var
  I, J: Integer;
begin
  Result := True;
  for J := 1 to FIGURE_LENGTH do
  begin
    if ALeftShift then
    begin
      for I := 1 to FIGURE_LENGTH do
        if FFigure[I, J] <> 0 then
        begin
          Result := (FFigureLeft + I - 2 >= 1) and (FGameField[FFigureLeft + I - 2, FFigureTop + J - 1] = 0);
          break;
        end
    end
    else
      for I := FIGURE_LENGTH downto 1 do
        if FFigure[I, J] <> 0 then
        begin
          Result := (FFigureLeft + I <= FIELD_WIDTH) and (FGameField[FFigureLeft + I, FFigureTop + J - 1] = 0);
          break;
        end;
    if not Result then
      Exit;
  end;
end;

procedure TfMain.ShiftFigure(ALeftShift: Boolean);
var
  I, SideIndex, RectLeft, RectTop: Integer;
begin
  if FTransferring then
    Exit;

  FTransferring := True;
  try
    if not CanShiftFigure(ALeftShift) then
      Exit;

    RectLeft := (FFigureLeft - 1) * FStepX;
    RectTop := (FFigureTop - 1) * FStepY;

    if ALeftShift then
    begin
      SideIndex := FIGURE_LENGTH;
      RectLeft := RectLeft + (FIGURE_LENGTH - 1) * FStepX;
    end
    else
      SideIndex := 1;

    with Canvas do
    begin
      Pen.Color := GAME_FIELD_COLOR;
      Brush.Color := GAME_FIELD_COLOR;
      for I := 1 to FIGURE_LENGTH do
      begin
        if FFigure[SideIndex, I] <> 0 then
          Rectangle(RectLeft, RectTop, RectLeft + FStepX, RectTop + FStepY);
        Inc(RectTop, FStepY);
      end;
    end;

    if ALeftShift then
      Dec(FFigureLeft)
    else
      Inc(FFigureLeft);

    DrawFigure(True);
  finally
    FTransferring := False;
  end;
end;

procedure TfMain.TurnFigure(ALeftRotation: Boolean);
var
  I, J, OldX, OldY, RealLeft, RealTop, RectTop, RectLeft, Save: Integer;

  procedure _Rotate(ALeftRotation: Boolean);
  var
    I, J: Integer;
    NewFigure: array [1 .. FIGURE_LENGTH, 1 .. FIGURE_LENGTH] of Integer;
  begin
    for I := 1 to FIGURE_LENGTH do
      for J := 1 to FIGURE_LENGTH do
        if ALeftRotation then
          NewFigure[FIGURE_LENGTH - J + 1, I] := FFigure[I, J]
        else
          NewFigure[J, FIGURE_LENGTH - I + 1] := FFigure[I, J];

    for I := 1 to FIGURE_LENGTH do
      for J := 1 to FIGURE_LENGTH do
        FFigure[I, J] := NewFigure[I, J];
  end;

begin
  if FTransferring then
    Exit;

  FTransferring := True;
  try
    _Rotate(ALeftRotation);
    OldX := FFigureRotationCenterX;
    OldY := FFigureRotationCenterY;
    FindFigureCenter;
    RealLeft := FFigureLeft + OldX - FFigureRotationCenterX;
    RealTop := FFigureTop + OldY - FFigureRotationCenterY;
    for I := 1 to FIGURE_LENGTH do
      for J := 1 to FIGURE_LENGTH do
        if (FFigure[I, J] <> 0) and ((RealLeft + I <= 1) or (RealLeft + I - 1 > FIELD_WIDTH) or (RealTop + J <= 1) or
          (RealTop + J - 1 > FIELD_HEIGHT) or (FGameField[RealLeft + I - 1, RealTop + J - 1] <> 0)) then
        begin
          _Rotate(not ALeftRotation);
          FFigureRotationCenterX := OldX;
          FFigureRotationCenterY := OldY;
          Exit;
        end;

    Save := (FFigureTop - 1) * FStepY;
    if OldX > FFigureRotationCenterX then
    begin
      RectLeft := (FFigureLeft - 1) * FStepX;
      I := FFigureLeft;
      OldX := RealLeft;
    end
    else
    begin
      RectLeft := (RealLeft + FIGURE_LENGTH - 1) * FStepX;
      I := RealLeft + FIGURE_LENGTH;
      OldX := FFigureLeft + FIGURE_LENGTH;
    end;

    for I := I to OldX do
    begin
      RectTop := Save;
      if (I > 0) and (I <= FIELD_WIDTH) then
        for J := FFigureTop to FFigureTop + FIGURE_LENGTH do
          if (J > 0) and (J <= FIELD_HEIGHT) then
          begin
            DrawItem(RectLeft, RectTop, FGameField[I, J]);
            RectTop := RectTop + FStepY;
          end;
      RectLeft := RectLeft + FStepX;
    end;

    Save := (FFigureLeft - 1) * FStepX;
    if OldY > FFigureRotationCenterY then
    begin
      RectTop := (FFigureTop - 1) * FStepY;
      I := FFigureTop;
      OldY := RealTop;
    end
    else
    begin
      RectTop := (RealTop + FIGURE_LENGTH - 1) * FStepY;
      I := RealTop + FIGURE_LENGTH;
      OldY := FFigureTop + FIGURE_LENGTH;
    end;

    for J := I to OldY do
    begin
      RectLeft := Save;
      if (J > 0) and (J <= FIELD_HEIGHT) then
        for I := FFigureLeft to FFigureLeft + FIGURE_LENGTH do
          if (I > 0) and (I <= FIELD_WIDTH) then
          begin
            DrawItem(RectLeft, RectTop, FGameField[I, J]);
            RectLeft := RectLeft + FStepX;
          end;
      RectTop := RectTop + FStepY;
    end;

    FFigureLeft := RealLeft;
    FFigureTop := RealTop;
    DrawFigure(True);
  finally
    FTransferring := False;
  end;
end;

procedure TfMain.PutFigure;
var
  I, J, RectLeft, RectTop, SaveTop: Integer;
begin
  if FTransferring then
    Exit;

  FTransferring := True;
  GameTimer.Enabled := False;
  try
    RectLeft := (FFigureLeft - 1) * FStepX;
    SaveTop := (FFigureTop - 1) * FStepY;
    while CanMoveFigureDown do
      Inc(FFigureTop);
    RectTop := (FFigureTop - 1) * FStepY;

    Canvas.Pen.Color := GAME_FIELD_COLOR;
    Canvas.Brush.Color := GAME_FIELD_COLOR;
    for I := 1 to FIGURE_LENGTH do
    begin
      for J := 1 to FIGURE_LENGTH do
        if FFigure[I, J] <> 0 then
        begin
          Canvas.Rectangle(RectLeft, SaveTop, RectLeft + FStepX, RectTop);
          break;
        end;
      Inc(RectLeft, FStepX);
    end;

    DrawFigure();
    ValidateFigure;
  finally
    GameTimer.Enabled := not FGameStopped;
    FTransferring := False;
  end;
end;

procedure TfMain.StopGame;
begin
  FGameStopped := True;
  FGamePaused := False;
  GameTimer.Enabled := False;
  StopItem.Enabled := False;
  PauseItem.Enabled := False;
  PauseItem.Caption := S_GAME_PAUSE;
  InvalidateWorkArea(False);
end;

procedure TfMain.GameTimerTimer(Sender: TObject);
begin
  MoveFigureDown;
end;

procedure TfMain.FormPaint(Sender: TObject);
begin
  InvalidateWorkArea(False);
  if not(FGameStopped or FGamePaused) then
    DrawFigure;
  RefreshScore;
end;

procedure TfMain.StopItemClick(Sender: TObject);
begin
  StopGame;
end;

procedure TfMain.ExitItemClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  FFirstTime := True;
  FGameStopped := True;
  FGamePaused := False;
  FTransferring := False;
  Remeasure;
  ResetGameField;
end;

procedure TfMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FTransferring or FGameStopped then
    Exit;

  if (Key = Ord('p')) or (Key = Ord('P')) then
    PauseGame
  else if not FGamePaused then
    case Key of
      37:
        ShiftFigure(True); // VK_Left
      39:
        ShiftFigure(False); // VK_Right
      32:
        PutFigure; // VK_Space
      38:
        TurnFigure(False); // VK_Up
      40:
        MoveFigureDown; // TurnFigure( True );    // VK_Down
    end;
end;

procedure TfMain.CheckLine;
var
  FullLine: Boolean;
  I, J, BeforeBurnedLines: Integer;
begin
  BeforeBurnedLines := 0;
  for J := FFigureTop to FFigureTop + FIGURE_LENGTH do
    if (J > 0) and (J <= FIELD_HEIGHT) then
    begin
      FullLine := True;
      for I := 1 to FIELD_WIDTH do
        if FGameField[I, J] = 0 then
        begin
          FullLine := False;
          break;
        end;
      if FullLine then
      begin
        BurnLine(J, BeforeBurnedLines);
        Inc(BeforeBurnedLines);
      end;
    end;
end;

procedure TfMain.BurnLine(ALine, ABeforeBurnedLines: Integer);
var
  I, J, RectTop, RectLeft: Integer;
begin
  GameTimer.Enabled := False;
  try
    Inc(FBurnedLineNumber);
    FScore := FScore + Round(FLineValue * (ABeforeBurnedLines + 2) / 2);
    ValidateScore;
    RectTop := FStepY * (ALine - 1);

    for J := ALine downto 2 do
    begin
      RectLeft := 0;
      for I := 1 to FIELD_WIDTH do
      begin
        FGameField[I, J] := FGameField[I, J - 1];
        DrawItem(RectLeft, RectTop, FGameField[I, J]);
        Inc(RectLeft, FStepX);
      end;
      Dec(RectTop, FStepY);
    end;
    for I := 1 to FIELD_WIDTH do
      FGameField[I, 1] := 0;

    with Canvas do
    begin
      Pen.Color := GAME_FIELD_COLOR;
      Brush.Color := GAME_FIELD_COLOR;
      Rectangle(0, 0, FIELD_WIDTH * FStepX, FStepY);
    end;
  finally
    GameTimer.Enabled := not FGameStopped;
  end;
end;

procedure TfMain.Remeasure;
begin
  FStepX := ClientWidth div FIELD_WIDTH;
  FStepY := ClientHeight div FIELD_HEIGHT;
  if FStepX > FStepY then
    FStepX := FStepY
  else
    FStepY := FStepX;
end;

procedure TfMain.FormResize(Sender: TObject);
begin
  Remeasure;
  Invalidate;
end;

procedure TfMain.ValidateScore;
begin
  if (FLevel < MAX_LEVEL) and (FBurnedLineNumber mod LEVEL_STEP = 0) then
  begin
    FLineValue := FLineValue * 2;
    Inc(FLevel);
    GameTimer.Interval := Round(START_INTERVAL * 2 / FLevel); // Round( ( GameTimer.Interval * 3 ) / 4 );
  end;
  RefreshScore;
end;

procedure TfMain.RefreshScore;
var
  I, J, Height, RectTop, RectLeft: Integer;
  DrawingRect: TRect;
begin
  with Canvas do
  begin
    Pen.Color := clBtnFace;
    Brush.Color := clBtnFace;
    Font.Size := Self.Font.Size;
    Font.Color := clBtnText;

    Height := Canvas.TextHeight('0') + SCORE_SPACE;
    DrawingRect := Rect(FIELD_WIDTH * FStepX, 0, ClientWidth, Height);

    TextRect(DrawingRect, DrawingRect.Left + SCORE_SHIFT, DrawingRect.Top + SCORE_SPACE, S_SCORE + IntToStr(FScore));
    DrawingRect.Top := DrawingRect.Bottom;
    DrawingRect.Bottom := DrawingRect.Bottom + Height;
    TextRect(DrawingRect, DrawingRect.Left + SCORE_SHIFT, DrawingRect.Top + SCORE_SPACE, S_LINES + IntToStr(FBurnedLineNumber));
    DrawingRect.Top := DrawingRect.Bottom;
    DrawingRect.Bottom := DrawingRect.Bottom + Height * 2;
    TextRect(DrawingRect, DrawingRect.Left + SCORE_SHIFT, DrawingRect.Top + SCORE_SPACE, S_LEVEL + IntToStr(FLevel));
    DrawingRect.Top := DrawingRect.Bottom;
    DrawingRect.Bottom := DrawingRect.Bottom + Height;
    TextRect(DrawingRect, DrawingRect.Left + SCORE_SHIFT, DrawingRect.Top + SCORE_SPACE, S_NEXT_FIGURE);
  end;

  DrawingRect.Top := DrawingRect.Bottom + SCORE_SPACE;
  RectLeft := DrawingRect.Left + SCORE_SHIFT;
  if not FGameStopped then
  begin
    Height := FNewFigure * FIGURE_LENGTH * FIGURE_LENGTH;
    for I := 1 to FIGURE_LENGTH do
    begin
      RectTop := DrawingRect.Top;
      for J := 1 to FIGURE_LENGTH do
      begin
        DrawItem(RectLeft, RectTop, StrToInt(S_FIGURES_LIST[Height + (I - 1) * FIGURE_LENGTH + J]));
        Inc(RectTop, FStepY);
      end;
      RectLeft := RectLeft + FStepX;
    end;
    with Canvas do
    begin
      Pen.Color := clBtnFace;
      Brush.Color := clBtnFace;
      Rectangle(RectLeft, DrawingRect.Top, ClientWidth, RectTop);
    end;
    DrawingRect.Top := RectTop;
  end;
  Canvas.Rectangle(DrawingRect.Left, DrawingRect.Top, ClientWidth, ClientHeight);
end;

procedure TfMain.PauseGame;
begin
  GameTimer.Enabled := FGamePaused;
  FGamePaused := not FGamePaused;
  InvalidateWorkArea(False);
  if FGamePaused then
    PauseItem.Caption := S_GAME_RESUME
  else
  begin
    PauseItem.Caption := S_GAME_PAUSE;
    DrawFigure;
  end;
end;

procedure TfMain.PauseItemClick(Sender: TObject);
begin
  PauseGame;
end;

end.
