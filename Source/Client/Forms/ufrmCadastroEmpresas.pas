unit ufrmCadastroEmpresas;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, Buttons, uEmpresa, uEmpresaDAO, uDBConnection, fphttpclient, fpjson, jsonparser;

type
  { TfrmCadastroEmpresas }
  TfrmCadastroEmpresas = class(TForm)
    btnNovo: TButton;
    btnEditar: TButton;
    btnExcluir: TButton;
    btnSalvar: TButton;
    btnCancelar: TButton;
    btnBuscarCNPJ: TButton;
    edtBuscar: TEdit;
    edtCNPJ: TEdit;
    edtRazaoSocial: TEdit;
    edtNomeFantasia: TEdit;
    edtUF: TEdit;
    edtIntervaloConsulta: TEdit;
    lblTitulo: TLabel;
    lblBuscar: TLabel;
    lblCNPJ: TLabel;
    lblRazaoSocial: TLabel;
    lblNomeFantasia: TLabel;
    lblUF: TLabel;
    lblAmbiente: TLabel;
    lblIntervalo: TLabel;
    lblMinutos: TLabel;
    lblTipoManifestacao: TLabel;
    pnlTopo: TPanel;
    pnlToolbar: TPanel;
    pnlGrid: TPanel;
    pnlForm: TPanel;
    pnlBotoes: TPanel;
    rbAmbienteProducao: TRadioButton;
    rbAmbienteHomologacao: TRadioButton;
    chkManifestacaoAuto: TCheckBox;
    chkAtivo: TCheckBox;
    cmbTipoManifestacao: TComboBox;
    gridEmpresas: TStringGrid;
    
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure btnNovoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnBuscarCNPJClick(Sender: TObject);
    procedure edtBuscarChange(Sender: TObject);
    procedure gridEmpresasSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure chkManifestacaoAutoClick(Sender: TObject);
  private
    FDAO: TEmpresaDAO;
    FEmpresaAtual: TEmpresa;
    FModoEdicao: Boolean;
    
    procedure ConfigurarGrid;
    procedure ConfigurarComboTipoManifestacao;
    procedure CarregarEmpresas;
    procedure LimparFormulario;
    procedure HabilitarFormulario(AHabilitar: Boolean);
    procedure PreencherFormulario(AEmpresa: TEmpresa);
    procedure ValidarCampos;
    function ObterEmpresaSelecionada: TEmpresa;
    function ObterTipoManifestacaoSelecionado: Char;
    procedure BuscarDadosCNPJ(const ACNPJ: string);
  public
  end;

var
  frmCadastroEmpresas: TfrmCadastroEmpresas;

implementation

{$R *.lfm}

{ TfrmCadastroEmpresas }

procedure TfrmCadastroEmpresas.FormCreate(Sender: TObject);
begin
  FDAO := TEmpresaDAO.Create;
  FEmpresaAtual := nil;
  FModoEdicao := False;
  
  ConfigurarGrid;
  ConfigurarComboTipoManifestacao;
  HabilitarFormulario(False);
  
  // Conectar ao banco
  try
    TDBConnection.GetInstance.Conectar;
    CarregarEmpresas;
  except
    on E: Exception do
      ShowMessage('Erro ao conectar ao banco: ' + E.Message);
  end;
end;

procedure TfrmCadastroEmpresas.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Assigned(FEmpresaAtual) then
    FreeAndNil(FEmpresaAtual);
  FreeAndNil(FDAO);
end;

procedure TfrmCadastroEmpresas.ConfigurarGrid;
begin
  gridEmpresas.ColCount := 5;
  gridEmpresas.RowCount := 1;
  gridEmpresas.FixedRows := 1;
  gridEmpresas.FixedCols := 0;
  
  // Cabeçalhos
  gridEmpresas.Cells[0, 0] := 'ID';
  gridEmpresas.Cells[1, 0] := 'CNPJ';
  gridEmpresas.Cells[2, 0] := 'Razão Social';
  gridEmpresas.Cells[3, 0] := 'UF';
  gridEmpresas.Cells[4, 0] := 'Ativo';
  
  // Larguras calculadas: Total = 580px + 20px scrollbar = 600px
  gridEmpresas.ColWidths[0] := 50;   // ID
  gridEmpresas.ColWidths[1] := 120;  // CNPJ
  gridEmpresas.ColWidths[2] := 300;  // Razão Social
  gridEmpresas.ColWidths[3] := 50;   // UF
  gridEmpresas.ColWidths[4] := 60;   // Ativo
  
  gridEmpresas.Options := gridEmpresas.Options + [goRowSelect];
end;

procedure TfrmCadastroEmpresas.ConfigurarComboTipoManifestacao;
begin
  cmbTipoManifestacao.Clear;
  cmbTipoManifestacao.Items.Add('C - Ciência da Operação');
  cmbTipoManifestacao.Items.Add('I - Confirmação da Operação');
  cmbTipoManifestacao.Items.Add('D - Desconhecimento da Operação');
  cmbTipoManifestacao.Items.Add('N - Não Realizada');
  cmbTipoManifestacao.ItemIndex := 3; // 'N' como padrão
  cmbTipoManifestacao.Enabled := False;
end;

procedure TfrmCadastroEmpresas.CarregarEmpresas;
var
  Lista: TList;
  Empresa: TEmpresa;
  I: Integer;
begin
  try
    Lista := FDAO.Listar(True); // Apenas ativas por padrão
    try
      gridEmpresas.RowCount := Lista.Count + 1;
      
      for I := 0 to Lista.Count - 1 do
      begin
        Empresa := TEmpresa(Lista[I]);
        gridEmpresas.Cells[0, I + 1] := IntToStr(Empresa.ID);
        gridEmpresas.Cells[1, I + 1] := Empresa.CNPJ;
        gridEmpresas.Cells[2, I + 1] := Empresa.RazaoSocial;
        gridEmpresas.Cells[3, I + 1] := Empresa.UF;
        if Empresa.Ativo = 'S' then
          gridEmpresas.Cells[4, I + 1] := 'Sim'
        else
          gridEmpresas.Cells[4, I + 1] := 'Não';
      end;
      
      // Liberar objetos
      for I := 0 to Lista.Count - 1 do
        TEmpresa(Lista[I]).Free;
    finally
      Lista.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao carregar empresas: ' + E.Message);
  end;
end;

procedure TfrmCadastroEmpresas.btnNovoClick(Sender: TObject);
begin
  FModoEdicao := True;
  LimparFormulario;
  HabilitarFormulario(True);
  
  if Assigned(FEmpresaAtual) then
    FreeAndNil(FEmpresaAtual);
  
  FEmpresaAtual := TEmpresa.Create;
  edtCNPJ.SetFocus;
end;

procedure TfrmCadastroEmpresas.btnEditarClick(Sender: TObject);
var
  Empresa: TEmpresa;
begin
  Empresa := ObterEmpresaSelecionada;
  if not Assigned(Empresa) then
  begin
    ShowMessage('Selecione uma empresa para editar');
    Exit;
  end;
  
  FModoEdicao := True;
  HabilitarFormulario(True);
  PreencherFormulario(Empresa);
  
  if Assigned(FEmpresaAtual) then
    FreeAndNil(FEmpresaAtual);
  
  FEmpresaAtual := Empresa;
  edtRazaoSocial.SetFocus;
end;

procedure TfrmCadastroEmpresas.btnExcluirClick(Sender: TObject);
var
  Empresa: TEmpresa;
begin
  Empresa := ObterEmpresaSelecionada;
  if not Assigned(Empresa) then
  begin
    ShowMessage('Selecione uma empresa para excluir');
    Exit;
  end;
  
  if MessageDlg('Confirmação', 
                'Deseja realmente excluir a empresa ' + Empresa.RazaoSocial + '?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      FDAO.Excluir(Empresa.ID);
      ShowMessage('Empresa excluída com sucesso!');
      CarregarEmpresas;
      LimparFormulario;
    except
      on E: Exception do
        ShowMessage('Erro ao excluir empresa: ' + E.Message);
    end;
  end;
  
  Empresa.Free;
end;

procedure TfrmCadastroEmpresas.btnSalvarClick(Sender: TObject);
var
  Sucesso: Boolean;
  MsgErro: string;
begin
  try
    ValidarCampos;
    
    // Preencher objeto com dados do formulário
    FEmpresaAtual.CNPJ := Trim(edtCNPJ.Text);
    FEmpresaAtual.RazaoSocial := Trim(edtRazaoSocial.Text);
    FEmpresaAtual.NomeFantasia := Trim(edtNomeFantasia.Text);
    FEmpresaAtual.UF := UpperCase(Trim(edtUF.Text));
    
    if rbAmbienteProducao.Checked then
      FEmpresaAtual.Ambiente := 'P'
    else
      FEmpresaAtual.Ambiente := 'H';
    
    if chkManifestacaoAuto.Checked then
    begin
      FEmpresaAtual.ManifestacaoAuto := 'S';
      FEmpresaAtual.TipoManifestacaoAuto := ObterTipoManifestacaoSelecionado;
    end
    else
    begin
      FEmpresaAtual.ManifestacaoAuto := 'N';
      FEmpresaAtual.TipoManifestacaoAuto := #0;
    end;
    
    FEmpresaAtual.IntervaloConsulta := StrToIntDef(edtIntervaloConsulta.Text, 60);
    
    if chkAtivo.Checked then
      FEmpresaAtual.Ativo := 'S'
    else
      FEmpresaAtual.Ativo := 'N';
    
    // Salvar
    if FEmpresaAtual.ID = 0 then
      Sucesso := FDAO.Inserir(FEmpresaAtual)
    else
      Sucesso := FDAO.Atualizar(FEmpresaAtual);
    
    if Sucesso then
    begin
      ShowMessage('Empresa salva com sucesso!');
      CarregarEmpresas;
      btnCancelarClick(nil);
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao salvar: ' + E.Message);
  end;
end;

procedure TfrmCadastroEmpresas.btnCancelarClick(Sender: TObject);
begin
  FModoEdicao := False;
  LimparFormulario;
  HabilitarFormulario(False);
  
  if Assigned(FEmpresaAtual) then
    FreeAndNil(FEmpresaAtual);
end;

procedure TfrmCadastroEmpresas.btnBuscarCNPJClick(Sender: TObject);
var
  CNPJ: string;
begin
  CNPJ := Trim(edtCNPJ.Text);
  
  if CNPJ = '' then
  begin
    ShowMessage('Informe o CNPJ para buscar');
    edtCNPJ.SetFocus;
    Exit;
  end;
  
  if Length(CNPJ) < 14 then
  begin
    ShowMessage('CNPJ deve ter 14 dígitos');
    edtCNPJ.SetFocus;
    Exit;
  end;
  
  BuscarDadosCNPJ(CNPJ);
end;

procedure TfrmCadastroEmpresas.edtBuscarChange(Sender: TObject);
var
  Lista: TList;
  Empresa: TEmpresa;
  I: Integer;
  Texto: string;
begin
  Texto := Trim(edtBuscar.Text);
  
  if Texto = '' then
  begin
    CarregarEmpresas;
    Exit;
  end;
  
  try
    Lista := FDAO.Buscar(Texto, True);
    try
      gridEmpresas.RowCount := Lista.Count + 1;
      
      for I := 0 to Lista.Count - 1 do
      begin
        Empresa := TEmpresa(Lista[I]);
        gridEmpresas.Cells[0, I + 1] := IntToStr(Empresa.ID);
        gridEmpresas.Cells[1, I + 1] := Empresa.CNPJ;
        gridEmpresas.Cells[2, I + 1] := Empresa.RazaoSocial;
        gridEmpresas.Cells[3, I + 1] := Empresa.UF;
        if Empresa.Ativo = 'S' then
          gridEmpresas.Cells[4, I + 1] := 'Sim'
        else
          gridEmpresas.Cells[4, I + 1] := 'Não';
      end;
      
      for I := 0 to Lista.Count - 1 do
        TEmpresa(Lista[I]).Free;
    finally
      Lista.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao buscar empresas: ' + E.Message);
  end;
end;

procedure TfrmCadastroEmpresas.gridEmpresasSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
end;

procedure TfrmCadastroEmpresas.chkManifestacaoAutoClick(Sender: TObject);
begin
  // Habilita/desabilita o combo de tipo de manifestação
  cmbTipoManifestacao.Enabled := chkManifestacaoAuto.Checked;
  
  // Se desmarcar, limpa a seleção
  if not chkManifestacaoAuto.Checked then
    cmbTipoManifestacao.ItemIndex := -1
  else
    // Se marcar e não houver seleção, define 'N' como padrão
    if cmbTipoManifestacao.ItemIndex = -1 then
      cmbTipoManifestacao.ItemIndex := 3; // 'N - Não Realizada'
end;

procedure TfrmCadastroEmpresas.LimparFormulario;
begin
  edtCNPJ.Clear;
  edtRazaoSocial.Clear;
  edtNomeFantasia.Clear;
  edtUF.Clear;
  edtIntervaloConsulta.Text := '60';
  rbAmbienteProducao.Checked := True;
  chkManifestacaoAuto.Checked := False;
  cmbTipoManifestacao.ItemIndex := 3; // 'N' como padrão
  cmbTipoManifestacao.Enabled := False;
  chkAtivo.Checked := True;
end;

procedure TfrmCadastroEmpresas.HabilitarFormulario(AHabilitar: Boolean);
begin
  edtCNPJ.Enabled := AHabilitar;
  btnBuscarCNPJ.Enabled := AHabilitar;
  edtRazaoSocial.Enabled := AHabilitar;
  edtNomeFantasia.Enabled := AHabilitar;
  edtUF.Enabled := AHabilitar;
  edtIntervaloConsulta.Enabled := AHabilitar;
  rbAmbienteProducao.Enabled := AHabilitar;
  rbAmbienteHomologacao.Enabled := AHabilitar;
  chkManifestacaoAuto.Enabled := AHabilitar;
  chkAtivo.Enabled := AHabilitar;
  
  // O combo só é habilitado se manifestação auto estiver marcada
  if AHabilitar then
    cmbTipoManifestacao.Enabled := chkManifestacaoAuto.Checked
  else
    cmbTipoManifestacao.Enabled := False;
  
  btnSalvar.Enabled := AHabilitar;
  btnCancelar.Enabled := AHabilitar;
  btnNovo.Enabled := not AHabilitar;
  btnEditar.Enabled := not AHabilitar;
  btnExcluir.Enabled := not AHabilitar;
end;

procedure TfrmCadastroEmpresas.PreencherFormulario(AEmpresa: TEmpresa);
begin
  edtCNPJ.Text := AEmpresa.CNPJ;
  edtRazaoSocial.Text := AEmpresa.RazaoSocial;
  edtNomeFantasia.Text := AEmpresa.NomeFantasia;
  edtUF.Text := AEmpresa.UF;
  edtIntervaloConsulta.Text := IntToStr(AEmpresa.IntervaloConsulta);
  
  if AEmpresa.Ambiente = 'P' then
    rbAmbienteProducao.Checked := True
  else
    rbAmbienteHomologacao.Checked := True;
  
  chkManifestacaoAuto.Checked := (AEmpresa.ManifestacaoAuto = 'S');
  
  // Define o tipo de manifestação no combo
  if chkManifestacaoAuto.Checked then
  begin
    cmbTipoManifestacao.Enabled := True;
    case AEmpresa.TipoManifestacaoAuto of
      'C': cmbTipoManifestacao.ItemIndex := 0;
      'I': cmbTipoManifestacao.ItemIndex := 1;
      'D': cmbTipoManifestacao.ItemIndex := 2;
      'N': cmbTipoManifestacao.ItemIndex := 3;
      else cmbTipoManifestacao.ItemIndex := 3; // Padrão 'N'
    end;
  end
  else
  begin
    cmbTipoManifestacao.Enabled := False;
    cmbTipoManifestacao.ItemIndex := -1;
  end;
  
  chkAtivo.Checked := (AEmpresa.Ativo = 'S');
end;

procedure TfrmCadastroEmpresas.ValidarCampos;
begin
  if Trim(edtCNPJ.Text) = '' then
    raise Exception.Create('CNPJ é obrigatório');
  
  if Length(Trim(edtCNPJ.Text)) < 14 then
    raise Exception.Create('CNPJ deve ter 14 caracteres');
  
  if Trim(edtRazaoSocial.Text) = '' then
    raise Exception.Create('Razão Social é obrigatória');
  
  if Trim(edtUF.Text) = '' then
    raise Exception.Create('UF é obrigatória');
  
  if Length(Trim(edtUF.Text)) <> 2 then
    raise Exception.Create('UF deve ter 2 caracteres');
  
  // Valida tipo de manifestação apenas se manifestação automática estiver ativa
  if chkManifestacaoAuto.Checked then
  begin
    if cmbTipoManifestacao.ItemIndex = -1 then
      raise Exception.Create('Tipo de Manifestação é obrigatório quando Manifestação Automática está ativa');
  end;
end;

function TfrmCadastroEmpresas.ObterEmpresaSelecionada: TEmpresa;
var
  Row: Integer;
  ID: Integer;
begin
  Result := nil;
  Row := gridEmpresas.Row;
  
  if Row < 1 then
    Exit;
  
  ID := StrToIntDef(gridEmpresas.Cells[0, Row], 0);
  if ID > 0 then
    Result := FDAO.BuscarPorID(ID);
end;

function TfrmCadastroEmpresas.ObterTipoManifestacaoSelecionado: Char;
begin
  Result := #0;
  
  if cmbTipoManifestacao.ItemIndex = -1 then
    Exit;
  
  case cmbTipoManifestacao.ItemIndex of
    0: Result := 'C'; // Ciência
    1: Result := 'I'; // Confirmação
    2: Result := 'D'; // Desconhecimento
    3: Result := 'N'; // Não Realizada
  end;
end;

procedure TfrmCadastroEmpresas.BuscarDadosCNPJ(const ACNPJ: string);
var
  HTTPClient: TFPHTTPClient;
  Response: string;
  JSON: TJSONData;
  JSONObject: TJSONObject;
  URL: string;
  CNPJLimpo: string;
  I: Integer;
begin
  // Remove TODOS os caracteres não numéricos do CNPJ
  CNPJLimpo := '';
  for I := 1 to Length(ACNPJ) do
  begin
    if ACNPJ[I] in ['0'..'9'] then
      CNPJLimpo := CNPJLimpo + ACNPJ[I];
  end;
  
  // Remover espaços em branco
  CNPJLimpo := Trim(CNPJLimpo);
  
  // Validar CNPJ limpo
  if CNPJLimpo = '' then
  begin
    ShowMessage('CNPJ inválido. Digite apenas números.');
    Exit;
  end;
  
  if Length(CNPJLimpo) <> 14 then
  begin
    ShowMessage('CNPJ deve ter exatamente 14 dígitos.' + #13#10 +
                'Você digitou: ' + IntToStr(Length(CNPJLimpo)) + ' dígitos' + #13#10 +
                'CNPJ informado: ' + ACNPJ);
    Exit;
  end;
  
  // URL da API ReceitaWS (SEM LIMITE e SEM HTTPS!)
  URL := 'http://receitaws.com.br/v1/cnpj/' + CNPJLimpo;
  
  HTTPClient := TFPHTTPClient.Create(nil);
  try
    try
      Screen.Cursor := crHourGlass;
      Application.ProcessMessages;
      
      // Fazer requisição HTTP
      Response := HTTPClient.Get(URL);
      
      // Parse JSON
      JSON := GetJSON(Response);
      try
        if not (JSON is TJSONObject) then
          raise Exception.Create('Resposta JSON inválida');
        
        JSONObject := TJSONObject(JSON);
        
        // Verificar se há erro na resposta
        if (JSONObject.Find('status') <> nil) and
           (JSONObject.Find('message') <> nil) and
           (JSONObject.Get('status', '') = 'ERROR') then
          raise Exception.Create(JSONObject.Get('message', 'Erro desconhecido'));
        
        // Preencher campos com os dados retornados (ReceitaWS usa nomes diferentes)
        if JSONObject.Find('nome') <> nil then
          edtRazaoSocial.Text := JSONObject.Get('nome', '');
        
        if JSONObject.Find('fantasia') <> nil then
          edtNomeFantasia.Text := JSONObject.Get('fantasia', '');
        
        if JSONObject.Find('uf') <> nil then
          edtUF.Text := JSONObject.Get('uf', '');
        
        ShowMessage('✅ Dados encontrados com sucesso!' + #13#10 + #13#10 +
                    'Fonte: ReceitaWS' + #13#10 +
                    '✨ SEM limite de consultas!');
      finally
        JSON.Free;
      end;
    except
      on E: EHTTPClient do
      begin
        if Pos('404', E.Message) > 0 then
          ShowMessage('❌ CNPJ não encontrado na base da Receita Federal.' + #13#10 + #13#10 +
                      'CNPJ pesquisado: ' + CNPJLimpo)
        else if Pos('400', E.Message) > 0 then
          ShowMessage('❌ CNPJ inválido.' + #13#10 + #13#10 +
                      'Verifique se o CNPJ está correto.' + #13#10 +
                      'CNPJ pesquisado: ' + CNPJLimpo)
        else
          ShowMessage('❌ Erro na busca: ' + E.Message + #13#10 + #13#10 +
                      'CNPJ pesquisado: ' + CNPJLimpo);
      end;
      on E: Exception do
      begin
        ShowMessage('❌ Erro ao buscar CNPJ: ' + E.Message);
      end;
    end;
  finally
    HTTPClient.Free;
    Screen.Cursor := crDefault;
  end;
end;

end.
