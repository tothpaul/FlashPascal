object ProjectForm: TProjectForm
  Left = 553
  Top = 286
  BorderStyle = bsDialog
  Caption = 'Nouveau projet'
  ClientHeight = 199
  ClientWidth = 295
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Arial'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  Scaled = False
  PixelsPerInch = 96
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 206
    Height = 15
    Caption = 'Dimensions de l'#39'animation en pixels :'
  end
  object Label2: TLabel
    Left = 24
    Top = 40
    Width = 43
    Height = 15
    Caption = 'Largeur'
  end
  object Label3: TLabel
    Left = 144
    Top = 40
    Width = 44
    Height = 15
    Caption = 'Hauteur'
  end
  object Label4: TLabel
    Left = 8
    Top = 80
    Width = 119
    Height = 15
    Caption = 'Couleur d'#39'arri'#232're plan'
  end
  object shColor: TShape
    Left = 200
    Top = 76
    Width = 57
    Height = 23
    Cursor = crHandPoint
    OnMouseDown = shColorMouseDown
  end
  object Label5: TLabel
    Left = 8
    Top = 120
    Width = 184
    Height = 15
    Caption = 'Cadence en images par seconde'
  end
  object edWidth: TEdit
    Left = 80
    Top = 36
    Width = 57
    Height = 23
    TabOrder = 0
    Text = '550'
  end
  object edHeight: TEdit
    Left = 200
    Top = 36
    Width = 57
    Height = 23
    TabOrder = 1
    Text = '400'
  end
  object Button1: TButton
    Left = 48
    Top = 160
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 168
    Top = 160
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Annuler'
    ModalResult = 2
    TabOrder = 3
  end
  object edFrameRate: TEdit
    Left = 200
    Top = 116
    Width = 57
    Height = 23
    TabOrder = 4
    Text = '12'
  end
  object edColor: TEdit
    Left = 136
    Top = 76
    Width = 57
    Height = 23
    MaxLength = 6
    TabOrder = 5
    Text = 'FFFFFF'
    OnChange = edColorChange
  end
  object ColorDialog: TColorDialog
    Ctl3D = True
    Left = 248
    Top = 72
  end
end
