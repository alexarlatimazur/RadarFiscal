unit uConfig;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

type
  { TConfig - Gerencia configurações do sistema via arquivo INI }
  TConfig = class
  private
    class var FInstance: TConfig;
    FArquivoINI: string;
    
    constructor Create;
    
    { Getters privados }
    function GetArquivoINI: string;
    function GetServidorBD: string;
    function GetPortaBD: Integer;
    function GetBancoBD: string;
    function GetUsuarioBD: string;
    function GetSenhaBD: string;
    
    { Setters privados }
    procedure SetServidorBD(const AValor: string);
    procedure SetPortaBD(AValor: Integer);
    procedure SetBancoBD(const AValor: string);
    procedure SetUsuarioBD(const AValor: string);
    procedure SetSenhaBD(const AValor: string);
  public
    destructor Destroy; override;
    
    { Singleton }
    class function GetInstance: TConfig;
    class procedure ReleaseInstance;
    
    { Métodos de leitura/gravação }
    function LerString(const ASecao, AChave, AValorPadrao: string): string;
    function LerInteiro(const ASecao, AChave: string; AValorPadrao: Integer): Integer;
    function LerBoolean(const ASecao, AChave: string; AValorPadrao: Boolean): Boolean;
    
    procedure GravarString(const ASecao, AChave, AValor: string);
    procedure GravarInteiro(const ASecao, AChave: string; AValor: Integer);
    procedure GravarBoolean(const ASecao, AChave: string; AValor: Boolean);
    
    { Criar arquivo INI padrão se não existir }
    procedure CriarArquivoPadrao;
    
    { Propriedades - SEM parênteses! }
    property ArquivoINI: string read GetArquivoINI;
    property ServidorBD: string read GetServidorBD write SetServidorBD;
    property PortaBD: Integer read GetPortaBD write SetPortaBD;
    property BancoBD: string read GetBancoBD write SetBancoBD;
    property UsuarioBD: string read GetUsuarioBD write SetUsuarioBD;
    property SenhaBD: string read GetSenhaBD write SetSenhaBD;
  end;

implementation

{ TConfig }

constructor TConfig.Create;
begin
  inherited Create;
  
  // Arquivo INI fica na mesma pasta do executável
  FArquivoINI := ExtractFilePath(ParamStr(0)) + 'RadarFiscal.ini';
  
  // Criar arquivo padrão se não existir
  if not FileExists(FArquivoINI) then
    CriarArquivoPadrao;
end;

destructor TConfig.Destroy;
begin
  inherited Destroy;
end;

class function TConfig.GetInstance: TConfig;
begin
  if not Assigned(FInstance) then
    FInstance := TConfig.Create;
  Result := FInstance;
end;

class procedure TConfig.ReleaseInstance;
begin
  if Assigned(FInstance) then
    FreeAndNil(FInstance);
end;

function TConfig.GetArquivoINI: string;
begin
  Result := FArquivoINI;
end;

function TConfig.LerString(const ASecao, AChave, AValorPadrao: string): string;
var
  INI: TIniFile;
begin
  INI := TIniFile.Create(FArquivoINI);
  try
    Result := INI.ReadString(ASecao, AChave, AValorPadrao);
  finally
    INI.Free;
  end;
end;

function TConfig.LerInteiro(const ASecao, AChave: string; AValorPadrao: Integer): Integer;
var
  INI: TIniFile;
begin
  INI := TIniFile.Create(FArquivoINI);
  try
    Result := INI.ReadInteger(ASecao, AChave, AValorPadrao);
  finally
    INI.Free;
  end;
end;

function TConfig.LerBoolean(const ASecao, AChave: string; AValorPadrao: Boolean): Boolean;
var
  INI: TIniFile;
begin
  INI := TIniFile.Create(FArquivoINI);
  try
    Result := INI.ReadBool(ASecao, AChave, AValorPadrao);
  finally
    INI.Free;
  end;
end;

procedure TConfig.GravarString(const ASecao, AChave, AValor: string);
var
  INI: TIniFile;
begin
  INI := TIniFile.Create(FArquivoINI);
  try
    INI.WriteString(ASecao, AChave, AValor);
  finally
    INI.Free;
  end;
end;

procedure TConfig.GravarInteiro(const ASecao, AChave: string; AValor: Integer);
var
  INI: TIniFile;
begin
  INI := TIniFile.Create(FArquivoINI);
  try
    INI.WriteInteger(ASecao, AChave, AValor);
  finally
    INI.Free;
  end;
end;

procedure TConfig.GravarBoolean(const ASecao, AChave: string; AValor: Boolean);
var
  INI: TIniFile;
begin
  INI := TIniFile.Create(FArquivoINI);
  try
    INI.WriteBool(ASecao, AChave, AValor);
  finally
    INI.Free;
  end;
end;

function TConfig.GetServidorBD: string;
begin
  Result := LerString('DATABASE', 'Servidor', 'localhost');
end;

function TConfig.GetPortaBD: Integer;
begin
  Result := LerInteiro('DATABASE', 'Porta', 3050);
end;

function TConfig.GetBancoBD: string;
begin
  Result := LerString('DATABASE', 'Banco', '');
end;

function TConfig.GetUsuarioBD: string;
begin
  Result := LerString('DATABASE', 'Usuario', 'SYSDBA');
end;

function TConfig.GetSenhaBD: string;
begin
  Result := LerString('DATABASE', 'Senha', 'masterkey');
end;

procedure TConfig.SetServidorBD(const AValor: string);
begin
  GravarString('DATABASE', 'Servidor', AValor);
end;

procedure TConfig.SetPortaBD(AValor: Integer);
begin
  GravarInteiro('DATABASE', 'Porta', AValor);
end;

procedure TConfig.SetBancoBD(const AValor: string);
begin
  GravarString('DATABASE', 'Banco', AValor);
end;

procedure TConfig.SetUsuarioBD(const AValor: string);
begin
  GravarString('DATABASE', 'Usuario', AValor);
end;

procedure TConfig.SetSenhaBD(const AValor: string);
begin
  GravarString('DATABASE', 'Senha', AValor);
end;

procedure TConfig.CriarArquivoPadrao;
var
  INI: TIniFile;
begin
  INI := TIniFile.Create(FArquivoINI);
  try
    // Seção DATABASE
    INI.WriteString('DATABASE', 'Servidor', 'localhost');
    INI.WriteInteger('DATABASE', 'Porta', 3050);
    INI.WriteString('DATABASE', 'Banco', ExtractFilePath(ParamStr(0)) + 'RadarFiscal.fdb');
    INI.WriteString('DATABASE', 'Usuario', 'SYSDBA');
    INI.WriteString('DATABASE', 'Senha', 'masterkey');
    
    // Seção SISTEMA (para futuras configurações)
    INI.WriteString('SISTEMA', 'Versao', '1.0');
    INI.WriteBool('SISTEMA', 'LogAtivo', True);
    INI.WriteString('SISTEMA', 'PastaLogs', ExtractFilePath(ParamStr(0)) + 'Logs\');
  finally
    INI.Free;
  end;
end;

initialization

finalization
  TConfig.ReleaseInstance;

end.
