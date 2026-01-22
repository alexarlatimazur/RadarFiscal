unit uCertificado;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uBaseEntity;

type
  { TCertificado - Representa um certificado digital A1 }
  TCertificado = class(TBaseEntity)
  private
    FIDEmpresa: Integer;
    FArquivoCertificado: TBytes;  // BLOB - arquivo .pfx
    FSenha: string;
    FDataValidade: TDateTime;
    FAtivo: Char;
    FNumeroCertificado: string;
    FCNPJ: string;
    FRazaoSocial: string;
  public
    constructor Create; override;
    destructor Destroy; override;
    
    { Implementação do método abstrato da classe base }
    function Validar(out AMensagemErro: string): Boolean; override;
    
    { Métodos auxiliares }
    function EstaVencido: Boolean;
    function DiasParaVencimento: Integer;
    
    { Propriedades }
    property IDEmpresa: Integer read FIDEmpresa write FIDEmpresa;
    property ArquivoCertificado: TBytes read FArquivoCertificado write FArquivoCertificado;
    property Senha: string read FSenha write FSenha;
    property DataValidade: TDateTime read FDataValidade write FDataValidade;
    property Ativo: Char read FAtivo write FAtivo;
    property NumeroCertificado: string read FNumeroCertificado write FNumeroCertificado;
    property CNPJ: string read FCNPJ write FCNPJ;
    property RazaoSocial: string read FRazaoSocial write FRazaoSocial;
  end;

implementation

uses
  DateUtils;

{ TCertificado }

constructor TCertificado.Create;
begin
  inherited Create;
  
  // Valores padrão
  FIDEmpresa := 0;
  SetLength(FArquivoCertificado, 0);
  FSenha := '';
  FDataValidade := 0;
  FAtivo := 'S';  // S=Sim
  FNumeroCertificado := '';
  FCNPJ := '';
  FRazaoSocial := '';
end;

destructor TCertificado.Destroy;
begin
  SetLength(FArquivoCertificado, 0);
  inherited Destroy;
end;

function TCertificado.Validar(out AMensagemErro: string): Boolean;
begin
  Result := False;
  AMensagemErro := '';
  
  // Validar IDEmpresa
  if FIDEmpresa <= 0 then
  begin
    AMensagemErro := 'ID da Empresa não informado';
    Exit;
  end;
  
  // Validar Arquivo do Certificado
  if Length(FArquivoCertificado) = 0 then
  begin
    AMensagemErro := 'Arquivo do Certificado não informado';
    Exit;
  end;
  
  // Validar Senha
  if Trim(FSenha) = '' then
  begin
    AMensagemErro := 'Senha do Certificado não informada';
    Exit;
  end;
  
  // Validar Data de Validade
  if FDataValidade = 0 then
  begin
    AMensagemErro := 'Data de Validade não informada';
    Exit;
  end;
  
  // Validar se certificado está vencido
  if EstaVencido then
  begin
    AMensagemErro := 'Certificado vencido';
    Exit;
  end;
  
  // Validar Ativo
  if not (FAtivo in ['S', 'N']) then
  begin
    AMensagemErro := 'Ativo deve ser S (Sim) ou N (Não)';
    Exit;
  end;
  
  // Validar CNPJ
  if Trim(FCNPJ) = '' then
  begin
    AMensagemErro := 'CNPJ do Certificado não informado';
    Exit;
  end;
  
  if Length(Trim(FCNPJ)) < 14 then
  begin
    AMensagemErro := 'CNPJ do Certificado inválido';
    Exit;
  end;
  
  // Tudo OK
  Result := True;
end;

function TCertificado.EstaVencido: Boolean;
begin
  Result := (FDataValidade > 0) and (FDataValidade < Now);
end;

function TCertificado.DiasParaVencimento: Integer;
begin
  if FDataValidade = 0 then
    Result := 0
  else
    Result := DaysBetween(Now, FDataValidade);
    
  if EstaVencido then
    Result := -Result;  // Negativo se já venceu
end;

end.
