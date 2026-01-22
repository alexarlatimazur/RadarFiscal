program RadarFiscal;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, ufrmMain, ufrmConfiguracoes, ufrmCadastroEmpresas, uBaseEntity,
  uEmpresa, uCertificado, uDocumento, uUsuario, uConfig, uDBConnection,
  uEmpresaDAO
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFrmmain, Frmmain);
  Application.CreateForm(TfrmConfiguracoes, frmConfiguracoes);
  Application.CreateForm(TfrmCadastroEmpresas, frmCadastroEmpresas);
  Application.Run;
end.

