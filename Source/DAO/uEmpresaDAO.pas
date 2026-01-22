unit uEmpresaDAO;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, sqldb, uEmpresa, uDBConnection;

type
  { TEmpresaDAO - Acesso a dados da tabela EMPRESAS }
  TEmpresaDAO = class
  private
    FConnection: TDBConnection;
  public
    constructor Create;
    destructor Destroy; override;
    
    { CRUD }
    function Inserir(AEmpresa: TEmpresa): Boolean;
    function Atualizar(AEmpresa: TEmpresa): Boolean;
    function Excluir(AID: Integer): Boolean;
    
    { Consultas }
    function BuscarPorID(AID: Integer): TEmpresa;
    function BuscarPorCNPJ(const ACNPJ: string; AApenasAtiva: Boolean = True): TEmpresa;
    function Listar(AApenasAtivas: Boolean = True): TList;
    function ListarTodas: TList;
    function ListarAtivas: TList;
    
    { Buscas parciais }
    function BuscarPorRazaoSocial(const ARazaoSocial: string; AApenasAtivas: Boolean = True): TList;
    function BuscarPorNomeFantasia(const ANomeFantasia: string; AApenasAtivas: Boolean = True): TList;
    function Buscar(const ATexto: string; AApenasAtivas: Boolean = True): TList;
    
    { Utilitários }
    function CNPJJaExiste(const ACNPJ: string; AIDExcluir: Integer = 0): Boolean;
  end;

implementation

{ TEmpresaDAO }

constructor TEmpresaDAO.Create;
begin
  inherited Create;
  FConnection := TDBConnection.GetInstance;
end;

destructor TEmpresaDAO.Destroy;
begin
  inherited Destroy;
end;

function TEmpresaDAO.Inserir(AEmpresa: TEmpresa): Boolean;
var
  Query: TSQLQuery;
  MensagemErro: string;
begin
  Result := False;
  
  // Validar antes de inserir
  if not AEmpresa.Validar(MensagemErro) then
    raise Exception.Create('Dados inválidos: ' + MensagemErro);
  
  // Verificar se CNPJ já existe
  if CNPJJaExiste(AEmpresa.CNPJ) then
    raise Exception.Create('CNPJ já cadastrado');
  
  Query := FConnection.CriarQuery;
  try
    Query.SQL.Text := 
      'INSERT INTO EMPRESAS (' +
      '  CNPJ, RAZAO_SOCIAL, NOME_FANTASIA, UF, AMBIENTE, ' +
      '  ATIVO, MANIFESTACAO_AUTO, TIPO_MANIFESTACAO_AUTO, ' +
      '  INTERVALO_CONSULTA, ATIVO_MONITORAMENTO, DATA_CRIACAO' +
      ') VALUES (' +
      '  :CNPJ, :RAZAO_SOCIAL, :NOME_FANTASIA, :UF, :AMBIENTE, ' +
      '  :ATIVO, :MANIFESTACAO_AUTO, :TIPO_MANIFESTACAO_AUTO, ' +
      '  :INTERVALO_CONSULTA, :ATIVO_MONITORAMENTO, :DATA_CRIACAO' +
      ')';
    
    Query.ParamByName('CNPJ').AsString := AEmpresa.CNPJ;
    Query.ParamByName('RAZAO_SOCIAL').AsString := AEmpresa.RazaoSocial;
    Query.ParamByName('NOME_FANTASIA').AsString := AEmpresa.NomeFantasia;
    Query.ParamByName('UF').AsString := AEmpresa.UF;
    Query.ParamByName('AMBIENTE').AsString := AEmpresa.Ambiente;
    Query.ParamByName('ATIVO').AsString := AEmpresa.Ativo;
    Query.ParamByName('MANIFESTACAO_AUTO').AsString := AEmpresa.ManifestacaoAuto;
    
    if AEmpresa.TipoManifestacaoAuto <> #0 then
      Query.ParamByName('TIPO_MANIFESTACAO_AUTO').AsString := AEmpresa.TipoManifestacaoAuto
    else
      Query.ParamByName('TIPO_MANIFESTACAO_AUTO').Clear;
    
    Query.ParamByName('INTERVALO_CONSULTA').AsInteger := AEmpresa.IntervaloConsulta;
    Query.ParamByName('ATIVO_MONITORAMENTO').AsString := AEmpresa.AtivoMonitoramento;
    Query.ParamByName('DATA_CRIACAO').AsDateTime := AEmpresa.DataCriacao;
    
    FConnection.IniciarTransacao;
    try
      Query.ExecSQL;
      
      // Pegar o ID gerado
      Query.SQL.Text := 'SELECT GEN_ID(GEN_EMPRESAS_ID, 0) AS ID_GERADO FROM RDB$DATABASE';
      Query.Open;
      AEmpresa.ID := Query.FieldByName('ID_GERADO').AsInteger;
      Query.Close;
      
      FConnection.Commit;
      Result := True;
    except
      on E: Exception do
      begin
        FConnection.Rollback;
        raise Exception.Create('Erro ao inserir empresa: ' + E.Message);
      end;
    end;
  finally
    Query.Free;
  end;
end;

function TEmpresaDAO.Atualizar(AEmpresa: TEmpresa): Boolean;
var
  Query: TSQLQuery;
  MensagemErro: string;
begin
  Result := False;
  
  // Validar antes de atualizar
  if not AEmpresa.Validar(MensagemErro) then
    raise Exception.Create('Dados inválidos: ' + MensagemErro);
  
  // Verificar se CNPJ já existe (excluindo o próprio registro)
  if CNPJJaExiste(AEmpresa.CNPJ, AEmpresa.ID) then
    raise Exception.Create('CNPJ já cadastrado para outra empresa');
  
  Query := FConnection.CriarQuery;
  try
    Query.SQL.Text := 
      'UPDATE EMPRESAS SET ' +
      '  CNPJ = :CNPJ, ' +
      '  RAZAO_SOCIAL = :RAZAO_SOCIAL, ' +
      '  NOME_FANTASIA = :NOME_FANTASIA, ' +
      '  UF = :UF, ' +
      '  AMBIENTE = :AMBIENTE, ' +
      '  ATIVO = :ATIVO, ' +
      '  MANIFESTACAO_AUTO = :MANIFESTACAO_AUTO, ' +
      '  TIPO_MANIFESTACAO_AUTO = :TIPO_MANIFESTACAO_AUTO, ' +
      '  INTERVALO_CONSULTA = :INTERVALO_CONSULTA, ' +
      '  ATIVO_MONITORAMENTO = :ATIVO_MONITORAMENTO ' +
      'WHERE ID_EMPRESA = :ID_EMPRESA';
    
    Query.ParamByName('ID_EMPRESA').AsInteger := AEmpresa.ID;
    Query.ParamByName('CNPJ').AsString := AEmpresa.CNPJ;
    Query.ParamByName('RAZAO_SOCIAL').AsString := AEmpresa.RazaoSocial;
    Query.ParamByName('NOME_FANTASIA').AsString := AEmpresa.NomeFantasia;
    Query.ParamByName('UF').AsString := AEmpresa.UF;
    Query.ParamByName('AMBIENTE').AsString := AEmpresa.Ambiente;
    Query.ParamByName('ATIVO').AsString := AEmpresa.Ativo;
    Query.ParamByName('MANIFESTACAO_AUTO').AsString := AEmpresa.ManifestacaoAuto;
    
    if AEmpresa.TipoManifestacaoAuto <> #0 then
      Query.ParamByName('TIPO_MANIFESTACAO_AUTO').AsString := AEmpresa.TipoManifestacaoAuto
    else
      Query.ParamByName('TIPO_MANIFESTACAO_AUTO').Clear;
    
    Query.ParamByName('INTERVALO_CONSULTA').AsInteger := AEmpresa.IntervaloConsulta;
    Query.ParamByName('ATIVO_MONITORAMENTO').AsString := AEmpresa.AtivoMonitoramento;
    
    FConnection.IniciarTransacao;
    try
      Query.ExecSQL;
      FConnection.Commit;
      Result := True;
    except
      on E: Exception do
      begin
        FConnection.Rollback;
        raise Exception.Create('Erro ao atualizar empresa: ' + E.Message);
      end;
    end;
  finally
    Query.Free;
  end;
end;

function TEmpresaDAO.Excluir(AID: Integer): Boolean;
var
  Query: TSQLQuery;
begin
  Result := False;
  
  Query := FConnection.CriarQuery;
  try
    // Verificar se empresa existe
    Query.SQL.Text := 'SELECT COUNT(*) AS QTD FROM EMPRESAS WHERE ID_EMPRESA = :ID_EMPRESA';
    Query.ParamByName('ID_EMPRESA').AsInteger := AID;
    Query.Open;
    
    if Query.FieldByName('QTD').AsInteger = 0 then
      raise Exception.Create('Empresa não encontrada');
    
    Query.Close;
    
    // Excluir
    Query.SQL.Text := 'DELETE FROM EMPRESAS WHERE ID_EMPRESA = :ID_EMPRESA';
    Query.ParamByName('ID_EMPRESA').AsInteger := AID;
    
    FConnection.IniciarTransacao;
    try
      Query.ExecSQL;
      FConnection.Commit;
      Result := True;
    except
      on E: Exception do
      begin
        FConnection.Rollback;
        raise Exception.Create('Erro ao excluir empresa: ' + E.Message);
      end;
    end;
  finally
    Query.Free;
  end;
end;

function TEmpresaDAO.BuscarPorID(AID: Integer): TEmpresa;
var
  Query: TSQLQuery;
begin
  Result := nil;
  
  Query := FConnection.CriarQuery;
  try
    Query.SQL.Text := 
      'SELECT * FROM EMPRESAS WHERE ID_EMPRESA = :ID_EMPRESA';
    Query.ParamByName('ID_EMPRESA').AsInteger := AID;
    Query.Open;
    
    if not Query.EOF then
    begin
      Result := TEmpresa.Create;
      Result.ID := Query.FieldByName('ID_EMPRESA').AsInteger;
      Result.CNPJ := Query.FieldByName('CNPJ').AsString;
      Result.RazaoSocial := Query.FieldByName('RAZAO_SOCIAL').AsString;
      Result.NomeFantasia := Query.FieldByName('NOME_FANTASIA').AsString;
      Result.UF := Query.FieldByName('UF').AsString;
      Result.Ambiente := Query.FieldByName('AMBIENTE').AsString[1];
      Result.Ativo := Query.FieldByName('ATIVO').AsString[1];
      Result.ManifestacaoAuto := Query.FieldByName('MANIFESTACAO_AUTO').AsString[1];
      
      if not Query.FieldByName('TIPO_MANIFESTACAO_AUTO').IsNull then
        Result.TipoManifestacaoAuto := Query.FieldByName('TIPO_MANIFESTACAO_AUTO').AsString[1]
      else
        Result.TipoManifestacaoAuto := #0;
      
      Result.IntervaloConsulta := Query.FieldByName('INTERVALO_CONSULTA').AsInteger;
      Result.AtivoMonitoramento := Query.FieldByName('ATIVO_MONITORAMENTO').AsString[1];
      Result.DataCriacao := Query.FieldByName('DATA_CRIACAO').AsDateTime;
      
      if not Query.FieldByName('DATA_ULTIMA_CONSULTA').IsNull then
        Result.DataUltimaConsulta := Query.FieldByName('DATA_ULTIMA_CONSULTA').AsDateTime;
    end;
    
    Query.Close;
  finally
    Query.Free;
  end;
end;

function TEmpresaDAO.BuscarPorCNPJ(const ACNPJ: string; AApenasAtiva: Boolean): TEmpresa;
var
  Query: TSQLQuery;
  SQL: string;
begin
  Result := nil;
  
  Query := FConnection.CriarQuery;
  try
    // Montar SQL com ou sem filtro de ativa
    SQL := 'SELECT * FROM EMPRESAS WHERE CNPJ = :CNPJ';
    
    if AApenasAtiva then
      SQL := SQL + ' AND ATIVO = ''S''';
    
    Query.SQL.Text := SQL;
    Query.ParamByName('CNPJ').AsString := ACNPJ;
    Query.Open;
    
    if not Query.EOF then
    begin
      Result := TEmpresa.Create;
      Result.ID := Query.FieldByName('ID_EMPRESA').AsInteger;
      Result.CNPJ := Query.FieldByName('CNPJ').AsString;
      Result.RazaoSocial := Query.FieldByName('RAZAO_SOCIAL').AsString;
      Result.NomeFantasia := Query.FieldByName('NOME_FANTASIA').AsString;
      Result.UF := Query.FieldByName('UF').AsString;
      Result.Ambiente := Query.FieldByName('AMBIENTE').AsString[1];
      Result.Ativo := Query.FieldByName('ATIVO').AsString[1];
      Result.ManifestacaoAuto := Query.FieldByName('MANIFESTACAO_AUTO').AsString[1];
      
      if not Query.FieldByName('TIPO_MANIFESTACAO_AUTO').IsNull then
        Result.TipoManifestacaoAuto := Query.FieldByName('TIPO_MANIFESTACAO_AUTO').AsString[1]
      else
        Result.TipoManifestacaoAuto := #0;
      
      Result.IntervaloConsulta := Query.FieldByName('INTERVALO_CONSULTA').AsInteger;
      Result.AtivoMonitoramento := Query.FieldByName('ATIVO_MONITORAMENTO').AsString[1];
      Result.DataCriacao := Query.FieldByName('DATA_CRIACAO').AsDateTime;
      
      if not Query.FieldByName('DATA_ULTIMA_CONSULTA').IsNull then
        Result.DataUltimaConsulta := Query.FieldByName('DATA_ULTIMA_CONSULTA').AsDateTime;
    end;
    
    Query.Close;
  finally
    Query.Free;
  end;
end;

function TEmpresaDAO.Listar(AApenasAtivas: Boolean): TList;
var
  Query: TSQLQuery;
  Empresa: TEmpresa;
  SQL: string;
begin
  Result := TList.Create;
  
  Query := FConnection.CriarQuery;
  try
    // Montar SQL com ou sem filtro
    SQL := 'SELECT * FROM EMPRESAS';
    
    if AApenasAtivas then
      SQL := SQL + ' WHERE ATIVO = ''S''';
    
    SQL := SQL + ' ORDER BY RAZAO_SOCIAL';
    
    Query.SQL.Text := SQL;
    Query.Open;
    
    while not Query.EOF do
    begin
      Empresa := TEmpresa.Create;
      Empresa.ID := Query.FieldByName('ID_EMPRESA').AsInteger;
      Empresa.CNPJ := Query.FieldByName('CNPJ').AsString;
      Empresa.RazaoSocial := Query.FieldByName('RAZAO_SOCIAL').AsString;
      Empresa.NomeFantasia := Query.FieldByName('NOME_FANTASIA').AsString;
      Empresa.UF := Query.FieldByName('UF').AsString;
      Empresa.Ambiente := Query.FieldByName('AMBIENTE').AsString[1];
      Empresa.Ativo := Query.FieldByName('ATIVO').AsString[1];
      Empresa.ManifestacaoAuto := Query.FieldByName('MANIFESTACAO_AUTO').AsString[1];
      
      if not Query.FieldByName('TIPO_MANIFESTACAO_AUTO').IsNull then
        Empresa.TipoManifestacaoAuto := Query.FieldByName('TIPO_MANIFESTACAO_AUTO').AsString[1]
      else
        Empresa.TipoManifestacaoAuto := #0;
      
      Empresa.IntervaloConsulta := Query.FieldByName('INTERVALO_CONSULTA').AsInteger;
      Empresa.AtivoMonitoramento := Query.FieldByName('ATIVO_MONITORAMENTO').AsString[1];
      Empresa.DataCriacao := Query.FieldByName('DATA_CRIACAO').AsDateTime;
      
      if not Query.FieldByName('DATA_ULTIMA_CONSULTA').IsNull then
        Empresa.DataUltimaConsulta := Query.FieldByName('DATA_ULTIMA_CONSULTA').AsDateTime;
      
      Result.Add(Empresa);
      Query.Next;
    end;
    
    Query.Close;
  finally
    Query.Free;
  end;
end;

function TEmpresaDAO.ListarTodas: TList;
begin
  // Chama o método genérico sem filtro
  Result := Listar(False);
end;

function TEmpresaDAO.ListarAtivas: TList;
begin
  // Chama o método genérico com filtro de ativas
  Result := Listar(True);
end;

function TEmpresaDAO.BuscarPorRazaoSocial(const ARazaoSocial: string; AApenasAtivas: Boolean): TList;
var
  Query: TSQLQuery;
  Empresa: TEmpresa;
  SQL: string;
begin
  Result := TList.Create;
  
  Query := FConnection.CriarQuery;
  try
    // CONTAINING é case-insensitive no Firebird
    SQL := 'SELECT * FROM EMPRESAS WHERE RAZAO_SOCIAL CONTAINING :RAZAO_SOCIAL';
    
    if AApenasAtivas then
      SQL := SQL + ' AND ATIVO = ''S''';
    
    SQL := SQL + ' ORDER BY RAZAO_SOCIAL';
    
    Query.SQL.Text := SQL;
    Query.ParamByName('RAZAO_SOCIAL').AsString := ARazaoSocial;
    Query.Open;
    
    while not Query.EOF do
    begin
      Empresa := TEmpresa.Create;
      Empresa.ID := Query.FieldByName('ID_EMPRESA').AsInteger;
      Empresa.CNPJ := Query.FieldByName('CNPJ').AsString;
      Empresa.RazaoSocial := Query.FieldByName('RAZAO_SOCIAL').AsString;
      Empresa.NomeFantasia := Query.FieldByName('NOME_FANTASIA').AsString;
      Empresa.UF := Query.FieldByName('UF').AsString;
      Empresa.Ambiente := Query.FieldByName('AMBIENTE').AsString[1];
      Empresa.Ativo := Query.FieldByName('ATIVO').AsString[1];
      Empresa.ManifestacaoAuto := Query.FieldByName('MANIFESTACAO_AUTO').AsString[1];
      
      if not Query.FieldByName('TIPO_MANIFESTACAO_AUTO').IsNull then
        Empresa.TipoManifestacaoAuto := Query.FieldByName('TIPO_MANIFESTACAO_AUTO').AsString[1]
      else
        Empresa.TipoManifestacaoAuto := #0;
      
      Empresa.IntervaloConsulta := Query.FieldByName('INTERVALO_CONSULTA').AsInteger;
      Empresa.AtivoMonitoramento := Query.FieldByName('ATIVO_MONITORAMENTO').AsString[1];
      Empresa.DataCriacao := Query.FieldByName('DATA_CRIACAO').AsDateTime;
      
      if not Query.FieldByName('DATA_ULTIMA_CONSULTA').IsNull then
        Empresa.DataUltimaConsulta := Query.FieldByName('DATA_ULTIMA_CONSULTA').AsDateTime;
      
      Result.Add(Empresa);
      Query.Next;
    end;
    
    Query.Close;
  finally
    Query.Free;
  end;
end;

function TEmpresaDAO.BuscarPorNomeFantasia(const ANomeFantasia: string; AApenasAtivas: Boolean): TList;
var
  Query: TSQLQuery;
  Empresa: TEmpresa;
  SQL: string;
begin
  Result := TList.Create;
  
  Query := FConnection.CriarQuery;
  try
    // CONTAINING é case-insensitive no Firebird
    SQL := 'SELECT * FROM EMPRESAS WHERE NOME_FANTASIA CONTAINING :NOME_FANTASIA';
    
    if AApenasAtivas then
      SQL := SQL + ' AND ATIVO = ''S''';
    
    SQL := SQL + ' ORDER BY NOME_FANTASIA';
    
    Query.SQL.Text := SQL;
    Query.ParamByName('NOME_FANTASIA').AsString := ANomeFantasia;
    Query.Open;
    
    while not Query.EOF do
    begin
      Empresa := TEmpresa.Create;
      Empresa.ID := Query.FieldByName('ID_EMPRESA').AsInteger;
      Empresa.CNPJ := Query.FieldByName('CNPJ').AsString;
      Empresa.RazaoSocial := Query.FieldByName('RAZAO_SOCIAL').AsString;
      Empresa.NomeFantasia := Query.FieldByName('NOME_FANTASIA').AsString;
      Empresa.UF := Query.FieldByName('UF').AsString;
      Empresa.Ambiente := Query.FieldByName('AMBIENTE').AsString[1];
      Empresa.Ativo := Query.FieldByName('ATIVO').AsString[1];
      Empresa.ManifestacaoAuto := Query.FieldByName('MANIFESTACAO_AUTO').AsString[1];
      
      if not Query.FieldByName('TIPO_MANIFESTACAO_AUTO').IsNull then
        Empresa.TipoManifestacaoAuto := Query.FieldByName('TIPO_MANIFESTACAO_AUTO').AsString[1]
      else
        Empresa.TipoManifestacaoAuto := #0;
      
      Empresa.IntervaloConsulta := Query.FieldByName('INTERVALO_CONSULTA').AsInteger;
      Empresa.AtivoMonitoramento := Query.FieldByName('ATIVO_MONITORAMENTO').AsString[1];
      Empresa.DataCriacao := Query.FieldByName('DATA_CRIACAO').AsDateTime;
      
      if not Query.FieldByName('DATA_ULTIMA_CONSULTA').IsNull then
        Empresa.DataUltimaConsulta := Query.FieldByName('DATA_ULTIMA_CONSULTA').AsDateTime;
      
      Result.Add(Empresa);
      Query.Next;
    end;
    
    Query.Close;
  finally
    Query.Free;
  end;
end;

function TEmpresaDAO.Buscar(const ATexto: string; AApenasAtivas: Boolean): TList;
var
  Query: TSQLQuery;
  Empresa: TEmpresa;
  SQL: string;
begin
  Result := TList.Create;
  
  Query := FConnection.CriarQuery;
  try
    // Busca em CNPJ, Razão Social E Nome Fantasia
    SQL := 'SELECT * FROM EMPRESAS WHERE ' +
           '(CNPJ CONTAINING :TEXTO OR ' +
           ' RAZAO_SOCIAL CONTAINING :TEXTO OR ' +
           ' NOME_FANTASIA CONTAINING :TEXTO)';
    
    if AApenasAtivas then
      SQL := SQL + ' AND ATIVO = ''S''';
    
    SQL := SQL + ' ORDER BY RAZAO_SOCIAL';
    
    Query.SQL.Text := SQL;
    Query.ParamByName('TEXTO').AsString := ATexto;
    Query.Open;
    
    while not Query.EOF do
    begin
      Empresa := TEmpresa.Create;
      Empresa.ID := Query.FieldByName('ID_EMPRESA').AsInteger;
      Empresa.CNPJ := Query.FieldByName('CNPJ').AsString;
      Empresa.RazaoSocial := Query.FieldByName('RAZAO_SOCIAL').AsString;
      Empresa.NomeFantasia := Query.FieldByName('NOME_FANTASIA').AsString;
      Empresa.UF := Query.FieldByName('UF').AsString;
      Empresa.Ambiente := Query.FieldByName('AMBIENTE').AsString[1];
      Empresa.Ativo := Query.FieldByName('ATIVO').AsString[1];
      Empresa.ManifestacaoAuto := Query.FieldByName('MANIFESTACAO_AUTO').AsString[1];
      
      if not Query.FieldByName('TIPO_MANIFESTACAO_AUTO').IsNull then
        Empresa.TipoManifestacaoAuto := Query.FieldByName('TIPO_MANIFESTACAO_AUTO').AsString[1]
      else
        Empresa.TipoManifestacaoAuto := #0;
      
      Empresa.IntervaloConsulta := Query.FieldByName('INTERVALO_CONSULTA').AsInteger;
      Empresa.AtivoMonitoramento := Query.FieldByName('ATIVO_MONITORAMENTO').AsString[1];
      Empresa.DataCriacao := Query.FieldByName('DATA_CRIACAO').AsDateTime;
      
      if not Query.FieldByName('DATA_ULTIMA_CONSULTA').IsNull then
        Empresa.DataUltimaConsulta := Query.FieldByName('DATA_ULTIMA_CONSULTA').AsDateTime;
      
      Result.Add(Empresa);
      Query.Next;
    end;
    
    Query.Close;
  finally
    Query.Free;
  end;
end;

function TEmpresaDAO.CNPJJaExiste(const ACNPJ: string; AIDExcluir: Integer): Boolean;
var
  Query: TSQLQuery;
begin
  Result := False;
  
  Query := FConnection.CriarQuery;
  try
    if AIDExcluir > 0 then
      Query.SQL.Text := 
        'SELECT COUNT(*) AS QTD FROM EMPRESAS WHERE CNPJ = :CNPJ AND ID_EMPRESA <> :ID_EMPRESA'
    else
      Query.SQL.Text := 
        'SELECT COUNT(*) AS QTD FROM EMPRESAS WHERE CNPJ = :CNPJ';
    
    Query.ParamByName('CNPJ').AsString := ACNPJ;
    
    if AIDExcluir > 0 then
      Query.ParamByName('ID_EMPRESA').AsInteger := AIDExcluir;
    
    Query.Open;
    Result := Query.FieldByName('QTD').AsInteger > 0;
    Query.Close;
  finally
    Query.Free;
  end;
end;

end.
