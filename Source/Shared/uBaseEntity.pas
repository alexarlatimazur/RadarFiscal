unit uBaseEntity;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  { TBaseEntity - Classe base para todas as entidades do sistema }
  TBaseEntity = class(TObject)
  private
    FID: Integer;
    FDataCriacao: TDateTime;
  protected
    { Métodos virtuais que podem ser sobrescritos }
    procedure SetID(AValue: Integer); virtual;
    function GetID: Integer; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    
    { Método para validação - deve ser implementado nas classes filhas }
    function Validar(out AMensagemErro: string): Boolean; virtual; abstract;
    
    { Propriedades }
    property ID: Integer read GetID write SetID;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
  end;

implementation

{ TBaseEntity }

constructor TBaseEntity.Create;
begin
  inherited Create;
  FID := 0;
  FDataCriacao := Now;
end;

destructor TBaseEntity.Destroy;
begin
  inherited Destroy;
end;

procedure TBaseEntity.SetID(AValue: Integer);
begin
  FID := AValue;
end;

function TBaseEntity.GetID: Integer;
begin
  Result := FID;
end;

end.
