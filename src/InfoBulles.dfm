object InfoBulle: TInfoBulle
  Left = 557
  Top = 556
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 48
  ClientWidth = 205
  Color = clInfoBk
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  OnCreate = FormCreate
  OnMouseDown = FormMouseDown
  OnPaint = FormPaint
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 40
    Top = 5
    Width = 39
    Height = 13
    Caption = 'Label1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    OnMouseDown = FormMouseDown
  end
  object Label2: TLabel
    Left = 40
    Top = 20
    Width = 161
    Height = 26
    AutoSize = False
    Caption = 'Label2'
    WordWrap = True
    OnMouseDown = FormMouseDown
  end
  object Timer: TTimer
    Enabled = False
    Interval = 10
    OnTimer = TimerTimer
    Left = 168
    Top = 16
  end
end
