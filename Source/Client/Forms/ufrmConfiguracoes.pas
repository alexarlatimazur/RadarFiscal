unit ufrmConfiguracoes;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uConfig, uDBConnection;

type
  { TfrmConfiguracoes }
  TfrmConfiguracoes = class(TForm)
    btnTestarConexao: TButton;
    btnFechar: TButton;
    btnProcurarBanco: TButton;
    dlgAbrirBanco: TOpenDialog;
    edtServidor: TEdit;
    edtPorta: TEdit;
    edtBanco: TEdit;
    edtUsuario: TEdit;
    edtSenha: TEdit;
    lblServidor: TLabel;
    lblPorta: TLabel;
    lblBanco: TLabel;
    lblUsuario: TLabel;
    lblSenha: TLabel;
    lblTitulo: TLabel;
    lblStatus: TLabel;
    pnlTopo: TPanel;
    pnlBotoes: TPanel;
    pnlConteudo: TPanel;
    
    procedure FormCreate(Sender: TObject);
    procedure btnTestarConexaoClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure btnProcurarBancoClick(Sender: TObject);
  private
    procedure CarregarConfiguracoes;
    procedure ExibirStatus(const AMensagem: string; ASucesso: Boolean);
  public
  end;

var
  frmConfiguracoes: TfrmConfiguracoes;

implementation

{$R *.lfm}

{ TfrmConfiguracoes }

procedure TfrmConfiguracoes.FormCreate(Sender: TObject);
begin
  CarregarConfiguracoes;
  lblStatus.Caption := 'Aguardando teste de conexão...';
  lblStatus.Font.Color := clGray;
end;

procedure TfrmConfiguracoes.CarregarConfiguracoes;
var
  Config: TConfig;
begin
  Config := TConfig.GetInstance;
  
  edtServidor.Text := Config.ServidorBD;
  edtPorta.Text := IntToStr(Config.PortaBD);
  edtBanco.Text := Config.BancoBD;
  edtUsuario.Text := Config.UsuarioBD;
  edtSenha.Text := Config.SenhaBD;
  edtSenha.PasswordChar := '*';
end;

procedure TfrmConfiguracoes.btnTestarConexaoClick(Sender: TObject);
var
  DB: TDBConnection;
begin
  lblStatus.Caption := 'Testando conexão...';
  lblStatus.Font.Color := clBlue;
  Application.ProcessMessages;
  
  DB := TDBConnection.GetInstance;
  try
    // Forçar recarregar configurações
    DB.Desconectar;
    DB.CarregarConfiguracao;
    
    // Tentar conectar
    DB.Conectar;
    
    if DB.Conectado then
    begin
      ExibirStatus('✓ Conexão realizada com sucesso!', True);
      ShowMessage('Conexão com o banco de dados estabelecida com sucesso!' + sLineBreak + sLineBreak +
                  'Servidor: ' + edtServidor.Text + sLineBreak +
                  'Banco: ' + edtBanco.Text);
    end
    else
      ExibirStatus('✗ Falha ao conectar', False);
      
  except
    on E: Exception do
    begin
      ExibirStatus('✗ Erro: ' + E.Message, False);
      ShowMessage('Erro ao conectar ao banco de dados:' + sLineBreak + sLineBreak + E.Message);
    end;
  end;
end;

procedure TfrmConfiguracoes.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmConfiguracoes.btnProcurarBancoClick(Sender: TObject);
begin
  dlgAbrirBanco.Title := 'Selecionar Banco de Dados';
  dlgAbrirBanco.Filter := 'Firebird Database (*.fdb)|*.fdb|Todos os arquivos (*.*)|*.*';
  dlgAbrirBanco.DefaultExt := 'fdb';
  
  // Se já tem um caminho, usar como inicial
  if edtBanco.Text <> '' then
    dlgAbrirBanco.InitialDir := ExtractFilePath(edtBanco.Text);
  
  if dlgAbrirBanco.Execute then
    edtBanco.Text := dlgAbrirBanco.FileName;
end;

procedure TfrmConfiguracoes.ExibirStatus(const AMensagem: string; ASucesso: Boolean);
begin
  lblStatus.Caption := AMensagem;
  
  if ASucesso then
    lblStatus.Font.Color := clGreen
  else
    lblStatus.Font.Color := clRed;
end;

end.
