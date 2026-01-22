unit uDocumento;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uBaseEntity;

type
  { TDocumento - Representa um documento fiscal eletrônico }
  TDocumento = class(TBaseEntity)
  private
    FIDEmpresa: Integer;
    FChaveAcesso: string;
    FNSU: Int64;
    FTipoDocumento: string;
    FModelo: string;
    FSerie: string;
    FNumero: string;
    FCNPJEmitente: string;
    FNomeEmitente: string;
    FUFEmitente: string;
    FDataEmissao: TDateTime;
    FValorTotal: Currency;
    FSituacao: string;
    FOrigem: string;
    FDataRecebimento: TDateTime;
    FPossuiXMLCompleto: Char;
    FManifestado: Char;
    FTipoManifestacao: Char;
    FDataManifestacao: TDateTime;
  public
    constructor Create; override;
    destructor Destroy; override;
    
    { Implementação do método abstrato da classe base }
    function Validar(out AMensagemErro: string): Boolean; override;
    
    { Propriedades }
    property IDEmpresa: Integer read FIDEmpresa write FIDEmpresa;
    property ChaveAcesso: string read FChaveAcesso write FChaveAcesso;
    property NSU: Int64 read FNSU write FNSU;
    property TipoDocumento: string read FTipoDocumento write FTipoDocumento;
    property Modelo: string read FModelo write FModelo;
    property Serie: string read FSerie write FSerie;
    property Numero: string read FNumero write FNumero;
    property CNPJEmitente: string read FCNPJEmitente write FCNPJEmitente;
    property NomeEmitente: string read FNomeEmitente write FNomeEmitente;
    property UFEmitente: string read FUFEmitente write FUFEmitente;
    property DataEmissao: TDateTime read FDataEmissao write FDataEmissao;
    property ValorTotal: Currency read FValorTotal write FValorTotal;
    property Situacao: string read FSituacao write FSituacao;
    property Origem: string read FOrigem write FOrigem;
    property DataRecebimento: TDateTime read FDataRecebimento write FDataRecebimento;
    property PossuiXMLCompleto: Char read FPossuiXMLCompleto write FPossuiXMLCompleto;
    property Manifestado: Char read FManifestado write FManifestado;
    property TipoManifestacao: Char read FTipoManifestacao write FTipoManifestacao;
    property DataManifestacao: TDateTime read FDataManifestacao write FDataManifestacao;
  end;

implementation

{ TDocumento }

constructor TDocumento.Create;
begin
  inherited Create;
  
  // Valores padrão
  FIDEmpresa := 0;
  FChaveAcesso := '';
  FNSU := 0;
  FTipoDocumento := '';
  FModelo := '';
  FSerie := '';
  FNumero := '';
  FCNPJEmitente := '';
  FNomeEmitente := '';
  FUFEmitente := '';
  FDataEmissao := 0;
  FValorTotal := 0;
  FSituacao := '';
  FOrigem := '';
  FDataRecebimento := Now;
  FPossuiXMLCompleto := 'N';  // N=Não
  FManifestado := 'N';         // N=Não
  FTipoManifestacao := #0;
  FDataManifestacao := 0;
end;

destructor TDocumento.Destroy;
begin
  inherited Destroy;
end;

function TDocumento.Validar(out AMensagemErro: string): Boolean;
begin
  Result := False;
  AMensagemErro := '';
  
  // Validar IDEmpresa
  if FIDEmpresa <= 0 then
  begin
    AMensagemErro := 'ID da Empresa não informado';
    Exit;
  end;
  
  // Validar Chave de Acesso
  if Trim(FChaveAcesso) = '' then
  begin
    AMensagemErro := 'Chave de Acesso não informada';
    Exit;
  end;
  
  if Length(Trim(FChaveAcesso)) <> 44 then
  begin
    AMensagemErro := 'Chave de Acesso inválida (deve ter 44 caracteres)';
    Exit;
  end;
  
  // Validar NSU
  if FNSU <= 0 then
  begin
    AMensagemErro := 'NSU não informado';
    Exit;
  end;
  
  // Validar Tipo de Documento
  if Trim(FTipoDocumento) = '' then
  begin
    AMensagemErro := 'Tipo de Documento não informado';
    Exit;
  end;
  
  // Validar CNPJ Emitente
  if Trim(FCNPJEmitente) = '' then
  begin
    AMensagemErro := 'CNPJ do Emitente não informado';
    Exit;
  end;
  
  // Validar Nome Emitente
  if Trim(FNomeEmitente) = '' then
  begin
    AMensagemErro := 'Nome do Emitente não informado';
    Exit;
  end;
  
  // Validar UF Emitente
  if Trim(FUFEmitente) = '' then
  begin
    AMensagemErro := 'UF do Emitente não informada';
    Exit;
  end;
  
  if Length(Trim(FUFEmitente)) <> 2 then
  begin
    AMensagemErro := 'UF do Emitente inválida';
    Exit;
  end;
  
  // Validar Origem
  if not (FOrigem in ['DFE', 'EMAIL']) then
  begin
    AMensagemErro := 'Origem deve ser DFE ou EMAIL';
    Exit;
  end;
  
  // Validar PossuiXMLCompleto
  if not (FPossuiXMLCompleto in ['S', 'N']) then
  begin
    AMensagemErro := 'Possui XML Completo deve ser S (Sim) ou N (Não)';
    Exit;
  end;
  
  // Validar Manifestado
  if not (FManifestado in ['S', 'N']) then
  begin
    AMensagemErro := 'Manifestado deve ser S (Sim) ou N (Não)';
    Exit;
  end;
  
  // Se manifestado, validar tipo de manifestação
  if (FManifestado = 'S') and not (FTipoManifestacao in ['C', 'I', 'D', 'N']) then
  begin
    AMensagemErro := 'Tipo de Manifestação deve ser C (Ciência), I (Confirmação), D (Desconhecimento) ou N (Não Realizada)';
    Exit;
  end;
  
  // Tudo OK
  Result := True;
end;

end.
