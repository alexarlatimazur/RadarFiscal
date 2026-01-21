// Classe base para entidades 
unit uBaseEntity; 
 
interface 
 
type 
  TBaseEntity = class 
  private 
    FID: Integer; 
  public 
    property ID: Integer read FID write FID; 
  end; 
 
implementation 
 
end. 
