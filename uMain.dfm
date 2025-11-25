object fMain: TfMain
  Left = 391
  Top = 238
  Caption = #1058#1077#1090#1088#1080#1089
  ClientHeight = 390
  ClientWidth = 360
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnPaint = FormPaint
  OnResize = FormResize
  TextHeight = 13
  object GameTimer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = GameTimerTimer
    Left = 152
    Top = 32
  end
  object MainMenu1: TMainMenu
    Left = 160
    Top = 112
    object GameItems: TMenuItem
      Caption = #1048#1075#1088#1072
      object StartItem: TMenuItem
        Caption = #1053#1086#1074#1072#1103' '#1080#1075#1088#1072
        ShortCut = 113
        OnClick = StartItemClick
      end
      object StopItem: TMenuItem
        Caption = #1057#1090#1086#1087
        Enabled = False
        ShortCut = 116
        OnClick = StopItemClick
      end
      object PauseItem: TMenuItem
        Caption = #1055#1072#1091#1079#1072
        Enabled = False
        ShortCut = 80
        OnClick = PauseItemClick
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object ExitItem: TMenuItem
        Caption = #1042#1099#1093#1086#1076
        OnClick = ExitItemClick
      end
    end
  end
end
