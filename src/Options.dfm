object OptionsForm: TOptionsForm
  Left = 911
  Top = 231
  BorderStyle = bsDialog
  Caption = 'Options par d'#233'faut'
  ClientHeight = 257
  ClientWidth = 376
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Arial'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  Scaled = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 72
    Width = 165
    Height = 15
    Caption = 'Emplacement du Player Flash'
  end
  object Label2: TLabel
    Left = 8
    Top = 120
    Width = 274
    Height = 15
    Caption = 'Vous pouvez t'#233'l'#233'charger le Player Flash sur le site'
  end
  object lbAdobe: TLabel
    Left = 288
    Top = 120
    Width = 35
    Height = 15
    Cursor = crHandPoint
    Caption = 'Adobe'
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlue
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    OnClick = lbAdobeClick
  end
  object edPlayer: TEdit
    Left = 8
    Top = 88
    Width = 313
    Height = 23
    TabOrder = 2
    Text = 'edPlayer'
  end
  object btBrowse: TButton
    Left = 328
    Top = 88
    Width = 33
    Height = 21
    Caption = '...'
    TabOrder = 3
    OnClick = btBrowseClick
  end
  object btOK: TButton
    Left = 200
    Top = 224
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 4
    OnClick = btOKClick
  end
  object btCancel: TButton
    Left = 288
    Top = 224
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Annuler'
    ModalResult = 2
    TabOrder = 5
  end
  object cbUserPlayer: TCheckBox
    Left = 8
    Top = 48
    Width = 345
    Height = 17
    Caption = 'Utiliser par d'#233'faut, le Player externe au lieu de l'#39'ActiveX'
    TabOrder = 1
  end
  object cbAutoRefresh: TCheckBox
    Left = 8
    Top = 16
    Width = 337
    Height = 17
    Caption = 'Actualiser automatiquement l'#39'animation.'
    TabOrder = 0
  end
  object cbLinkFPR: TCheckBox
    Left = 8
    Top = 160
    Width = 345
    Height = 17
    Caption = 'Associer FlashPascal2 aux fichiers .FPR'
    TabOrder = 6
  end
  object cbNoOptimize: TCheckBox
    Left = 8
    Top = 192
    Width = 345
    Height = 17
    Caption = 'D'#233'sactiver l'#39'optimisation de code'
    TabOrder = 7
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = '.exe'
    Filter = 'Programme (*.exe)|*.*|Tous les fichiers (*.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 160
    Top = 224
  end
end
