unit ufrmmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  StdCtrls, ufrmCadastroEmpresas, ufrmConfiguracoes;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    MainMenu: TMainMenu;
    mnuCadastros: TMenuItem;
    mnuCadastroEmpresas: TMenuItem;
    mnuFerramentas: TMenuItem;
    mnuConfiguracoes: TMenuItem;
    mnuSeparador1: TMenuItem;
    mnuSair: TMenuItem;
    pnlPrincipal: TPanel;
    lblTitulo: TLabel;
    lblVersao: TLabel;
    
    procedure FormCreate(Sender: TObject);
    procedure mnuCadastroEmpresasClick(Sender: TObject);
    procedure mnuConfiguracoesClick(Sender: TObject);
    procedure mnuSairClick(Sender: TObject);
  private

  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Inicialização do formulário principal
  Caption := 'Radar Fiscal';
end;

procedure TfrmMain.mnuCadastroEmpresasClick(Sender: TObject);
var
  frm: TfrmCadastroEmpresas;
begin
  frm := TfrmCadastroEmpresas.Create(nil);
  try
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

procedure TfrmMain.mnuConfiguracoesClick(Sender: TObject);
var
  frm: TfrmConfiguracoes;
begin
  frm := TfrmConfiguracoes.Create(nil);
  try
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

procedure TfrmMain.mnuSairClick(Sender: TObject);
begin
  Close;
end;

end.
