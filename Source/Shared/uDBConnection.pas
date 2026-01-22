unit uDBConnection;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, DB, uConfig;

type
  { TDBConnection - Singleton para gerenciar conexão com Firebird }
  TDBConnection = class
  private
    class var FInstance: TDBConnection;
    FConnection: TIBConnection;
    FTransaction: TSQLTransaction;
    FConectado: Boolean;
    
    constructor Create;
    function GetConectado: Boolean;
  public
    destructor Destroy; override;
    
    { Singleton }
    class function GetInstance: TDBConnection;
    class procedure ReleaseInstance;
    
    { Métodos de conexão }
    procedure CarregarConfiguracao;
    procedure Conectar;
    procedure Desconectar;
    function TestarConexao: Boolean;
    
    { Métodos de transação }
    procedure IniciarTransacao;
    procedure Commit;
    procedure Rollback;
    function EmTransacao: Boolean;
    
    { Configuração da conexão }
    procedure ConfigurarConexao(const AServidor, ABanco, AUsuario, ASenha: string; APorta: Integer);
    
    { Criar query }
    function CriarQuery: TSQLQuery;
    
    { Acesso aos componentes }
    function GetConnection: TIBConnection;
    function GetTransaction: TSQLTransaction;
    
    { Propriedades }
    property Conectado: Boolean read GetConectado;
  end;

implementation

{ TDBConnection }

constructor TDBConnection.Create;
begin
  inherited Create;
  
  // Criar componentes
  FConnection := TIBConnection.Create(nil);
  FTransaction := TSQLTransaction.Create(nil);
  
  // Configurar transação
  FTransaction.DataBase := FConnection;
  FConnection.Transaction := FTransaction;
  
  FConectado := False;
end;

destructor TDBConnection.Destroy;
begin
  Desconectar;
  FreeAndNil(FTransaction);
  FreeAndNil(FConnection);
  inherited Destroy;
end;

class function TDBConnection.GetInstance: TDBConnection;
begin
  if not Assigned(FInstance) then
    FInstance := TDBConnection.Create;
  Result := FInstance;
end;

class procedure TDBConnection.ReleaseInstance;
begin
  if Assigned(FInstance) then
    FreeAndNil(FInstance);
end;

procedure TDBConnection.ConfigurarConexao(const AServidor, ABanco, AUsuario, ASenha: string; APorta: Integer);
begin
  Desconectar;
  
  FConnection.HostName := AServidor;
  FConnection.DatabaseName := ABanco;
  FConnection.UserName := AUsuario;
  FConnection.Password := ASenha;
  FConnection.CharSet := 'UTF8';
  
  // Parâmetros adicionais do Firebird
  FConnection.Params.Clear;
  FConnection.Params.Add('PAGE_SIZE=16384');
  FConnection.Params.Add('sql_dialect=3');
end;

procedure TDBConnection.CarregarConfiguracao;
var
  Config: TConfig;
begin
  Config := TConfig.GetInstance;
  
  // Carrega TUDO do arquivo INI (incluindo porta!)
  ConfigurarConexao(
    Config.ServidorBD,
    Config.BancoBD,
    Config.UsuarioBD,
    Config.SenhaBD,
    Config.PortaBD
  );
end;

procedure TDBConnection.Conectar;
begin
  if FConectado then
    Exit;
  
  // Se não foi configurado ainda, carregar do INI
  if FConnection.DatabaseName = '' then
    CarregarConfiguracao;
    
  try
    FConnection.Open;
    FConectado := True;
  except
    on E: Exception do
    begin
      FConectado := False;
      raise Exception.Create('Erro ao conectar ao banco de dados: ' + E.Message);
    end;
  end;
end;

procedure TDBConnection.Desconectar;
begin
  if not FConectado then
    Exit;
    
  try
    // Desfazer transação pendente
    if EmTransacao then
      Rollback;
      
    FConnection.Close;
    FConectado := False;
  except
    on E: Exception do
      raise Exception.Create('Erro ao desconectar do banco de dados: ' + E.Message);
  end;
end;

function TDBConnection.TestarConexao: Boolean;
begin
  Result := False;
  
  try
    if not FConectado then
      Conectar;
    Result := FConnection.Connected;
  except
    Result := False;
  end;
end;

function TDBConnection.GetConectado: Boolean;
begin
  Result := FConectado and FConnection.Connected;
end;

function TDBConnection.GetConnection: TIBConnection;
begin
  Result := FConnection;
end;

function TDBConnection.GetTransaction: TSQLTransaction;
begin
  Result := FTransaction;
end;

procedure TDBConnection.IniciarTransacao;
begin
  if not FConectado then
    raise Exception.Create('Não conectado ao banco de dados');
    
  if not EmTransacao then
    FTransaction.StartTransaction;
end;

procedure TDBConnection.Commit;
begin
  if not FConectado then
    raise Exception.Create('Não conectado ao banco de dados');
    
  if EmTransacao then
    FTransaction.Commit;
end;

procedure TDBConnection.Rollback;
begin
  if not FConectado then
    Exit;
    
  if EmTransacao then
    FTransaction.Rollback;
end;

function TDBConnection.EmTransacao: Boolean;
begin
  Result := FTransaction.Active;
end;

function TDBConnection.CriarQuery: TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.DataBase := FConnection;
  Result.Transaction := FTransaction;
end;

initialization

finalization
  TDBConnection.ReleaseInstance;

end.
