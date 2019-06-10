object HTMLForm: THTMLForm
  Left = 588
  Top = 316
  Width = 505
  Height = 393
  Caption = 'Code HTML'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  Scaled = False
  DesignSize = (
    489
    354)
  PixelsPerInch = 96
  TextHeight = 13
  object mmHTML: TMemo
    Left = 8
    Top = 16
    Width = 377
    Height = 329
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      'Memo1')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object btnCopy: TButton
    Left = 392
    Top = 48
    Width = 88
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Copier'
    TabOrder = 1
    OnClick = btnCopyClick
  end
  object bntClose: TButton
    Left = 392
    Top = 80
    Width = 88
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Fermer'
    ModalResult = 2
    TabOrder = 2
  end
  object btnSave: TButton
    Left = 392
    Top = 16
    Width = 88
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Enregistrer...'
    TabOrder = 3
    OnClick = btnSaveClick
  end
  object cbHTMLHeader: TCheckBox
    Left = 392
    Top = 120
    Width = 89
    Height = 17
    Anchors = [akTop, akRight]
    Caption = 'Ent'#234'te HTML'
    Checked = True
    State = cbChecked
    TabOrder = 4
    OnClick = cbHTMLHeaderClick
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.htm'
    Filter = 'HTML Files (*.htm)|*.HTM|All files (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 144
    Top = 120
  end
end
