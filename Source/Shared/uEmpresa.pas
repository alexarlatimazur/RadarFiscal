unit uEmpresa;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uBaseEntity;

type
  { TEmpresa - Representa uma empresa monitorada pelo sistema }
  TEmpresa = class(TBaseEntity)
  private
    FCNPJ: string;
    FRazaoSocial: string;
    FNomeFantasia: string;
    FUF: string;
    FAmbiente: Char;
    FAtivo: Char;
    FManifestacaoAuto: Char;
    FTipoManifestacaoAuto: Char;
    FIntervaloConsulta: Integer;
    FAtivoMonitoramento: Char;
    FDataUltimaConsulta: TDateTime;
  public
    constructor Create; override;
    destructor Destroy; override;
    
    { Implementação do método abstrato da classe base }
    function Validar(out AMensagemErro: string): Boolean; override;
    
    { Propriedades }
    property CNPJ: string read FCNPJ write FCNPJ;
    property RazaoSocial: string read FRazaoSocial write FRazaoSocial;
    property NomeFantasia: string read FNomeFantasia write FNomeFantasia;
    property UF: string read FUF write FUF;
    property Ambiente: Char read FAmbiente write FAmbiente;
    property Ativo: Char read FAtivo write FAtivo;
    property ManifestacaoAuto: Char read FManifestacaoAuto write FManifestacaoAuto;
    property TipoManifestacaoAuto: Char read FTipoManifestacaoAuto write FTipoManifestacaoAuto;
    property IntervaloConsulta: Integer read FIntervaloConsulta write FIntervaloConsulta;
    property AtivoMonitoramento: Char read FAtivoMonitoramento write FAtivoMonitoramento;
    property DataUltimaConsulta: TDateTime read FDataUltimaConsulta write FDataUltimaConsulta;
  end;

implementation

{ TEmpresa }

constructor TEmpresa.Create;
begin
  inherited Create;
  
  // Valores padrão
  FCNPJ := '';
  FRazaoSocial := '';
  FNomeFantasia := '';
  FUF := '';
  FAmbiente := 'P';  // P=Produção
  FAtivo := 'S';     // S=Sim
  FManifestacaoAuto := 'N';  // N=Não
  FTipoManifestacaoAuto := #0;
  FIntervaloConsulta := 60;  // 60 minutos padrão
  FAtivoMonitoramento := 'S';
  FDataUltimaConsulta := 0;
end;

destructor TEmpresa.Destroy;
begin
  inherited Destroy;
end;

function TEmpresa.Validar(out AMensagemErro: string): Boolean;
begin
  Result := False;
  AMensagemErro := '';
  
  // Validar CNPJ
  if Trim(FCNPJ) = '' then
  begin
    AMensagemErro := 'CNPJ não informado';
    Exit;
  end;
  
  if Length(Trim(FCNPJ)) < 14 then
  begin
    AMensagemErro := 'CNPJ inválido';
    Exit;
  end;
  
  // Validar Razão Social
  if Trim(FRazaoSocial) = '' then
  begin
    AMensagemErro := 'Razão Social não informada';
    Exit;
  end;
  
  // Validar UF
  if Trim(FUF) = '' then
  begin
    AMensagemErro := 'UF não informada';
    Exit;
  end;
  
  if Length(Trim(FUF)) <> 2 then
  begin
    AMensagemErro := 'UF inválida';
    Exit;
  end;
  
  // Validar Ambiente
  if not (FAmbiente in ['P', 'H']) then
  begin
    AMensagemErro := 'Ambiente deve ser P (Produção) ou H (Homologação)';
    Exit;
  end;
  
  // Validar Ativo
  if not (FAtivo in ['S', 'N']) then
  begin
    AMensagemErro := 'Ativo deve ser S (Sim) ou N (Não)';
    Exit;
  end;
  
  // Validar ManifestacaoAuto
  if not (FManifestacaoAuto in ['S', 'N']) then
  begin
    AMensagemErro := 'Manifestação Automática deve ser S (Sim) ou N (Não)';
    Exit;
  end;
  
  // Se manifestação automática está ativa, validar tipo
  if (FManifestacaoAuto = 'S') and not (FTipoManifestacaoAuto in ['C', 'I', 'D', 'N']) then
  begin
    AMensagemErro := 'Tipo de Manifestação deve ser C (Ciência), I (Confirmação), D (Desconhecimento) ou N (Não Realizada)';
    Exit;
  end;
  
  // Validar IntervaloConsulta
  if FIntervaloConsulta <= 0 then
  begin
    AMensagemErro := 'Intervalo de Consulta deve ser maior que zero';
    Exit;
  end;
  
  // Validar AtivoMonitoramento
  if not (FAtivoMonitoramento in ['S', 'N']) then
  begin
    AMensagemErro := 'Ativo Monitoramento deve ser S (Sim) ou N (Não)';
    Exit;
  end;
  
  // Tudo OK
  Result := True;
end;

end.
