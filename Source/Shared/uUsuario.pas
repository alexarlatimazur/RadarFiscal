unit uUsuario;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uBaseEntity;

type
  { TUsuario - Representa um usuário do sistema }
  TUsuario = class(TBaseEntity)
  private
    FLogin: string;
    FSenha: string;
    FNome: string;
    FEmail: string;
    FAtivo: Char;
    FAdministrador: Char;
    FDataUltimoAcesso: TDateTime;
  public
    constructor Create; override;
    destructor Destroy; override;
    
    { Implementação do método abstrato da classe base }
    function Validar(out AMensagemErro: string): Boolean; override;
    
    { Métodos auxiliares }
    function ValidarSenha(ASenhaDigitada: string): Boolean;
    function CriptografarSenha(ASenha: string): string;
    
    { Propriedades }
    property Login: string read FLogin write FLogin;
    property Senha: string read FSenha write FSenha;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property Ativo: Char read FAtivo write FAtivo;
    property Administrador: Char read FAdministrador write FAdministrador;
    property DataUltimoAcesso: TDateTime read FDataUltimoAcesso write FDataUltimoAcesso;
  end;

implementation

uses
  md5;  // Unit para hash MD5

{ TUsuario }

constructor TUsuario.Create;
begin
  inherited Create;
  
  // Valores padrão
  FLogin := '';
  FSenha := '';
  FNome := '';
  FEmail := '';
  FAtivo := 'S';           // S=Sim
  FAdministrador := 'N';   // N=Não
  FDataUltimoAcesso := 0;
end;

destructor TUsuario.Destroy;
begin
  inherited Destroy;
end;

function TUsuario.Validar(out AMensagemErro: string): Boolean;
begin
  Result := False;
  AMensagemErro := '';
  
  // Validar Login
  if Trim(FLogin) = '' then
  begin
    AMensagemErro := 'Login não informado';
    Exit;
  end;
  
  if Length(Trim(FLogin)) < 3 then
  begin
    AMensagemErro := 'Login deve ter no mínimo 3 caracteres';
    Exit;
  end;
  
  // Validar Senha (quando estiver sendo cadastrada/alterada)
  // Nota: Senha já deve vir criptografada do formulário
  if Trim(FSenha) = '' then
  begin
    AMensagemErro := 'Senha não informada';
    Exit;
  end;
  
  // Validar Nome
  if Trim(FNome) = '' then
  begin
    AMensagemErro := 'Nome não informado';
    Exit;
  end;
  
  // Validar Email (formato básico)
  if Trim(FEmail) <> '' then
  begin
    if Pos('@', FEmail) = 0 then
    begin
      AMensagemErro := 'Email inválido';
      Exit;
    end;
  end;
  
  // Validar Ativo
  if not (FAtivo in ['S', 'N']) then
  begin
    AMensagemErro := 'Ativo deve ser S (Sim) ou N (Não)';
    Exit;
  end;
  
  // Validar Administrador
  if not (FAdministrador in ['S', 'N']) then
  begin
    AMensagemErro := 'Administrador deve ser S (Sim) ou N (Não)';
    Exit;
  end;
  
  // Tudo OK
  Result := True;
end;

function TUsuario.ValidarSenha(ASenhaDigitada: string): Boolean;
var
  SenhaCriptografada: string;
begin
  SenhaCriptografada := CriptografarSenha(ASenhaDigitada);
  Result := (SenhaCriptografada = FSenha);
end;

function TUsuario.CriptografarSenha(ASenha: string): string;
begin
  // Usa MD5 para criptografar a senha
  // Em produção, considere usar algo mais seguro como bcrypt ou SHA256
  Result := MD5Print(MD5String(ASenha));
end;

end.
