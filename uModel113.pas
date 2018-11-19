unit uModel113;

interface

uses
  SysUtils, Forms, Vcl.Dialogs, Vcl.Controls,
  System.Classes, StdCtrls, FileCtrl,
  uTSingleESRIgrid, uError, uDSmodelS_Interface, LargeArrays,
  AVgridIO, Vcl.ComCtrls, uTIntegerESRIgrid, uTabstractESRIgrid, xyTable,
  DUtils;

type
  TMainForm = class(TForm)
    Label1: TLabel;
    EditESRIgridGHG: TEdit;
    RunButton: TButton;
    SingleESRIgridGHG: TSingleESRIgrid;
    SpecifyOutputFolderDialog: TSaveDialog;
    EditESRIgridGLG: TEdit;
    Label2: TLabel;
    SingleESRIgridGLG: TSingleESRIgrid;
    EditESRIgridLandgebruik: TEdit;
    LabelGewas: TLabel;
    Label4: TLabel;
    EditESRIgridBodemtype: TEdit;
    SingleESRIgridDroogteschade: TSingleESRIgrid;
    SingleESRIgridNatschade: TSingleESRIgrid;
    SingleESRIgridTotaleSchade: TSingleESRIgrid;
    SingleESRIgridIResult: TSingleESRIgrid;
    ProgressBar1: TProgressBar;
    ComboBoxModelNr: TComboBox;
    LabelModelNr: TLabel;
    IntegerESRIgridGewas: TIntegerESRIgrid;
    IntegerESRIgridBodemType: TIntegerESRIgrid;
    SingleESRIgridVeenOxidatie: TSingleESRIgrid;
    SingleESRIgridGt: TSingleESRIgrid;
    GroupBox1: TGroupBox;
    CheckBoxCalcVeenOx: TCheckBox;
    CheckBoxCalcGt: TCheckBox;
    CheckBoxCalcNatEnDrSchade: TCheckBox;

    procedure EditESRIgridGHGClick(Sender: TObject);
    procedure EditESRIgridGLGClick(Sender: TObject);
    procedure EditESRIgridLandgebruikClick(Sender: TObject);
    procedure EditESRIgridBodemTypeClick(Sender: TObject);
    procedure RunButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CheckBoxCalcNatEnDrSchadeClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  VeenOxTable: TxyTableLinInt;

implementation

const
  cIni_InputGrids = 'INPUT GRIDS'; cIni_OutputGrids = 'OUTPUT GRIDS';
  cIni_GHGgrid = 'GHGgrid'; cIni_GLGgrid = 'GLGgrid';
  cIni_LandgebruikGrid = 'LandgebruikGrid'; cIni_BodemTypeGrid = 'BodemTypeGrid';
  cIni_OutputDir = 'Output Directory';
  cIni_DefaultInputDir = 'c:\'; cIni_DefaultOutputDir = 'c\';

{$R *.DFM}

procedure TMainForm.EditESRIgridGHGClick(Sender: TObject);
var
  Directory: string;
begin
  Directory := GetCurrentDir;
  if SelectDirectory( Directory,  [], 0 ) then begin
    EditESRIgridGHG.Text := ExpandFileName( Directory );
    fini.WriteString( cIni_InputGrids, cIni_GHGgrid, EditESRIgridGHG.Text );
  end;
end;

procedure TMainForm.EditESRIgridGLGClick(Sender: TObject);
var
  Directory: string;
begin
  Directory := GetCurrentDir;
  if SelectDirectory( Directory,  [], 0 ) then begin
    EditESRIgridGLG.Text := ExpandFileName( Directory );
    fini.WriteString( cIni_InputGrids, cIni_GLGgrid, EditESRIgridGLG.Text );
  end;
end;

procedure TMainForm.EditESRIgridLandgebruikClick(Sender: TObject);
var
  Directory: string;
begin
  Directory := GetCurrentDir;
  if SelectDirectory( Directory,  [], 0 ) then begin
    EditESRIgridLandgebruik.Text := ExpandFileName( Directory );
    fini.WriteString( cIni_InputGrids, cIni_LandgebruikGrid,
      EditESRIgridLandgebruik.Text );
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  S: String;
begin
  InitialiseLogFile;
  with fini do begin
    S := ReadString( cIni_InputGrids, cIni_GHGgrid, cIni_DefaultInputDir );
    if DirectoryExists( S ) then EditESRIgridGHG.Text := S;
    S := ReadString( cIni_InputGrids, cIni_GLGgrid, cIni_DefaultInputDir );
    if SysUtils.DirectoryExists( S ) then EditESRIgridGLG.Text := S;
    S := ReadString( cIni_InputGrids, cIni_LandgebruikGrid, cIni_DefaultInputDir );
    if SysUtils.DirectoryExists( S ) then EditESRIgridLandgebruik.Text := S;
    S := ReadString( cIni_InputGrids, cIni_BodemTypeGrid, cIni_DefaultInputDir );
    if SysUtils.DirectoryExists( S ) then EditESRIgridBodemType.Text := S;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
FinaliseLogFile;
end;

procedure TMainForm.CheckBoxCalcNatEnDrSchadeClick(Sender: TObject);
begin
  ComboBoxModelNr.Visible := not( ComboBoxModelNr.Visible );
  LabelModelNr.Visible := not( LabelModelNr.Visible );
  EditESRIgridLandgebruik.Visible := not( EditESRIgridLandgebruik.Visible );
  LabelGewas.Visible := not( LabelGewas.Visible );
end;

procedure TMainForm.EditESRIgridBodemtypeClick(Sender: TObject);
var
  Directory: string;
begin
  Directory := GetCurrentDir;
  if SelectDirectory( Directory,  [], 0 ) then begin
    EditESRIgridBodemtype.Text := ExpandFileName( Directory );
    fini.WriteString( cIni_InputGrids, cIni_BodemTypeGrid,
      EditESRIgridBodemType.Text );
  end;
end;

procedure TMainForm.RunButtonClick(Sender: TObject);
var
  ModelID: Integer;
const
  cNat = 0; cDroog = 1; cTotaal = 2;
var
  i, j, iResult, NRows, NCols, Bodem: Integer;
  RP, SQ, RQ, Result_Array: TarrayOfDouble; {-Vlak/punt/lijn waarden van c.q. naar de schil}
  Dir, ASCdir: string;
  x, y: Single;
  Save_Cursor: TCursor;
  GLG, GHG, Gt, {-m-mv}
  VeenOxidatie: Double; {-mm/jaar}

  Function AllGridsHaveData: Boolean;
  begin
    Result := not ( ( RP[ 0 ] = MISSINGINT ) or
                    ( RP[ 1 ] = MISSINGINT ) or
                    ( RP[ 2 ] = MissingSingle ) or
                    ( RP[ 3 ] = MissingSingle ) );
  end;

  Procedure DestroyAlInputGrids;
  begin
    Try FreeAndNil( SingleESRIgridGHG ) Except End;
    Try FreeAndNil( SingleESRIgridGLG ) Except End;
    Try FreeAndNil( IntegerESRIgridGewas ) Except End;
    Try FreeAndNil( IntegerESRIgridBodemtype ) Except end;
  end;

  Procedure DestroyAlOutputGrids;
  begin
    Try FreeAndNil( SingleESRIgridNatschade ); Except End;
    Try FreeAndNil( SingleESRIgridDroogteschade ) Except End;
    Try FreeAndNil( SingleESRIgridTotaleSchade ) Except end;
    Try FreeAndNil( SingleESRIgridIResult ) Except end;
    Try FreeAndNil( SingleESRIgridVeenOxidatie ) Except end;
    Try FreeAndNil( SingleESRIgridGt ) Except end;
  end;

  Procedure DestroyInAndOutputArrays;
  begin
    SetLength( RP, 0 );
    SetLength( SQ, 0 );
    SetLength( RQ, 0 );
    SetLength( Result_Array, 0 );
  end;

  Procedure DestroyAllData;
  begin
    DestroyAlInputGrids; DestroyAlOutputGrids; { DestroyInAndOutputArrays;}
  end;

  Function GetVeenOxidatie( const GLG: Double ): Double;
  begin
    {Result :=}
  end;

    Function GetGt( const GHG, GLG: Double ): Double;
    begin
      if ( GLG <= 0.50 ) then GetGt := 10 else begin    { (A, B, C) 1 )}
        if ( GLG <= 0.80 ) then begin
          if      ( GHG <= 0.25 ) then GetGt := 20      { A 2 }
          else if ( GHG <= 0.40 ) then GetGt := 25      { B 2 }
          else                         GetGt := 40;     { C 2 }
        end else if ( GLG <= 1.20 ) then begin
          if      ( GHG <= 0.25 ) then GetGt := 30      { A 3 }
          else if ( GHG <= 0.40 ) then GetGt := 35      { B 3 }
          else if ( GHG <= 0.80 ) then GetGt := 40      { C 3 }
          else                         GetGt := 70;     { D 3 }
        end else begin
          if      ( GHG <= 0.25 ) then GetGt := 50      { A 4 }
          else if ( GHG <= 0.40 ) then GetGt := 55      { B 4 }
          else if ( GHG <= 0.80 ) then GetGt := 60      { C 4 }
          else if ( GHG <= 1.40 ) then GetGt := 70      { D 4 }
          else                         GetGt := 75;     { E 4 }
        end; {-if}
      end; {-if}
    end; {-Function GetGt}

begin
  Save_Cursor := Screen.Cursor;

  Try
    if not ( CheckBoxCalcVeenOx.Checked or CheckBoxCalcNatEnDrSchade.Checked or
            CheckBoxCalcGt.Checked ) then begin
      raise Exception.Create( 'Geen berekenings optie gespecificeerd. ' );
    end;
  except
    On E: Exception do begin
      HandleError( E.Message, true );
      Exit;
    end;
  end;

  Dir := fini.ReadString( cIni_OutputGrids, cIni_OutputDir, cIni_DefaultOutputDir );
  if SelectDirectory( Dir, [sdAllowCreate, sdPerformCreate, sdPrompt], 0 ) then begin
    fini.WriteString( cIni_OutputGrids, cIni_OutputDir, ExpandFileName( Dir ) );
    Try
      Try

        AscDir :=  Dir  + '\ASC';
        if ( not DirectoryExists( AscDir ) ) then begin
          {$I-}
          MkDir(  AscDir );
          if ( IOResult <> 0 ) then
            Raise Exception.Create( 'Could not create dir [' + AscDir + '].' );
          {$I+}
        end;

        if CheckBoxCalcVeenOx.Checked or CheckBoxCalcNatEnDrSchade.Checked then begin
          {-Initialise input grid BodemType}
          IntegerESRIgridBodemtype := TIntegerESRIgrid.InitialiseFromESRIGridFile( EditESRIgridBodemtype.Text, iResult, self );
          if ( iResult <> cNoError ) then begin
            raise Exception.CreateFmt( 'Error initialising Bodemtype ESRI raster grid reading row %d.', [-iResult] );
          end;
        end;

        if CheckBoxCalcNatEnDrSchade.Checked then begin
          {-Initialise input grid Gewas}
          IntegerESRIgridGewas := TIntegerESRIgrid.InitialiseFromESRIGridFile(
            EditESRIgridLandgebruik.Text, iResult, self );
          if ( iResult <> cNoError ) then begin
            raise Exception.CreateFmt('Error initialising Landgebruik ESRI raster grid reading row %d.', [-iResult] );
          end;
        end;

        {-Initialise input grids GHG en GLG}
        if CheckBoxCalcNatEnDrSchade.Checked or CheckBoxCalcGt.Checked then begin
          SingleESRIgridGHG := TSingleESRIgrid.InitialiseFromESRIGridFile( EditESRIgridGHG.Text, iResult, self );
          if ( iResult <> cNoError ) then begin
            raise Exception.CreateFmt('Error initialising GHG ESRI raster grid reading row %d.', [-iResult] );
          end;
        end;
        SingleESRIgridGLG := TSingleESRIgrid.InitialiseFromESRIGridFile( EditESRIgridGLG.Text, iResult, self );
        if ( iResult <> cNoError ) then begin
          raise Exception.CreateFmt('Error initialising GLG ESRI raster grid reading row %d.', [-iResult] );
        end;
        NRows := SingleESRIgridGLG.NRows;
        NCols := SingleESRIgridGLG.NCols;

        if CheckBoxCalcGt.Checked then begin
          {-Bereken Gt}
          SingleESRIgridGt := TSingleESRIgrid.Clone( SingleESRIgridGLG, 'Gt', iResult, self );
          if ( iResult <> cNoError ) then begin
            raise Exception.CreateFmt('Error creating grid %s.', ['SingleESRIgridGt']);
          end;
          ProgressBar1.Max := NRows; ProgressBar1.Position := 0;
          for i := 1 to NRows do begin
            for j := 1 to NCols do begin
              SingleESRIgridGt.SetValue( i, j, MissingSingle  );
              SingleESRIgridGLG.GetCellCentre( i, j, x, y );
              GLG   := SingleESRIgridGLG.GetValueXY( x, y );          {-GLG (m-mv)}
              if GLG <> MissingSingle then begin
                GHG   := SingleESRIgridGHG.GetValueXY( x, y );        {-GLG (m-mv)}
                if GHG <> MissingSingle then begin
                  Gt := GetGt( GHG, GLG );
                  SingleESRIgridGt.SetValue( i, j, Gt );
                end;
              end;
            end;
            ProgressBar1.Position := i; ProgressBar1.Update;
          end;
          ProgressBar1.Position := 0; ProgressBar1.Update;
          SingleESRIgridGt.SaveAs( Dir + '\Gt');
          SingleESRIgridGt.ExportToASC( ASCdir + '\Gt.asc' );
          WriteToLogFile( 'Gt s are calculated' );
          ShowMessage( 'Gt''s are calculated' );
          FreeAndNil( SingleESRIgridGt );
        end;

        if CheckBoxCalcVeenOx.Checked then begin
          {-Bereken veenoxidatie}
          SingleESRIgridVeenOxidatie := TSingleESRIgrid.Clone( SingleESRIgridGLG, 'VeenOx', iResult, self );
          if ( iResult <> cNoError ) then begin
            raise Exception.CreateFmt('Error creating grid %s.', ['SingleESRIgridVeenOxidatie']);
          end;
          VeenOxTable := TxyTableLinInt.Create( 15, mainform );
          With VeenOxTable do begin
            SetXY( 1, 0.0,   0 ); {GLG (m-mv) en daling (mm/jaar)}
            SetXY( 2, 0.1, 0.8 );
            SetXY( 3, 0.2, 1.7 );
            SetXY( 4, 0.3, 2.6 );
            SetXY( 5, 0.4, 3.8 );
            SetXY( 6, 0.5, 5.1 );
            SetXY( 7, 0.6, 7.4 );
            SetXY( 8, 0.7, 9.8 );
            SetXY( 9, 0.8, 12.2 );
            SetXY( 10, 0.9, 14.5 );
            SetXY( 11, 1.0, 16.9 );
            SetXY( 12, 1.1, 19.2 );
            SetXY( 13, 1.2, 21.6 );
            SetXY( 14, 1.3, 23.9 );
            SetXY( 15, 2.5, 30.0 );
          end;
          ProgressBar1.Max := NRows; ProgressBar1.Position := 0;
          for i := 1 to NRows do begin
            for j := 1 to NCols do begin
              SingleESRIgridVeenOxidatie.SetValue( i, j, MissingSingle  );
              SingleESRIgridGLG.GetCellCentre( i, j, x, y );
              Bodem := IntegerESRIgridBodemtype.GetValueXY( x, y );   {-BodemType }
              if Bodem <> MISSINGINT then begin
                GLG   := SingleESRIgridGLG.GetValueXY( x, y );          {-GLG (m-mv)}
                if GLG <> MissingSingle then begin
                  if ( Bodem < 15 ) then begin {-Bodemtype = Veengronden of moerige gronden}
                    VeenOxidatie := VeenOxTable.EstimateY( GLG, FrWrd );
                    SingleESRIgridVeenOxidatie.SetValue( i, j, VeenOxidatie  );
                  end;
                end;
              end;
            end;
            ProgressBar1.Position := i; ProgressBar1.Update;
          end;
          ProgressBar1.Position := 0; ProgressBar1.Update;

          SingleESRIgridVeenOxidatie.SaveAs( Dir + '\VeenOx' );
          SingleESRIgridVeenOxidatie.ExportToASC( ASCdir + '\VeenOx.asc'  );
          WriteToLogFile(  'Veenoxidatie is calculated.' );
          ShowMessage( 'Veenoxidatie is calculated.' );
          FreeAndNil( SingleESRIgridVeenOxidatie );
        end;

        if CheckBoxCalcNatEnDrSchade.checked then begin

          {-Create output grids}
          SingleESRIgridNatschade := TSingleESRIgrid.Clone( SingleESRIgridGLG, 'Natschade', iResult, self );
          if ( iResult <> cNoError ) then begin
            raise Exception.CreateFmt('Error creating grid %s.', ['SingleESRIgridNatschade']);
          end;
          SingleESRIgridNatschade.SaveAs( 'd:\tmp\testnat' );

          SingleESRIgridDroogteschade := TSingleESRIgrid.Clone( SingleESRIgridGLG, 'DrgSchade', iResult, self );
          if ( iResult <> cNoError ) then begin
            raise Exception.CreateFmt('Error creating grid %s.', ['SingleESRIgridDroogteschade']);
          end;

          SingleESRIgridTotaleSchade := TSingleESRIgrid.Clone( SingleESRIgridGLG, 'TotSchade', iResult, self );
          if ( iResult <> cNoError ) then begin
            raise Exception.CreateFmt('Error creating grid %s.', ['SingleESRIgridTotaleSchade']);
          end;

          SingleESRIgridIResult := TSingleESRIgrid.Clone( SingleESRIgridGLG, 'IResult', iResult, self );
          if ( iResult <> cNoError ) then begin
            raise Exception.CreateFmt('Error creating grid %s.', ['SingleESRIgridIResult']);
          end;

          {-Initialise model --> nRP, nSQ, nRQ, nResPar}
          ModelID := 113 + ComboBoxModelNr.ItemIndex;

          DSmodelS_Interface := TDSmodelS_Interface.Create(ModelID, IResult);
          if ( iResult <> cNoError ) then begin
            raise Exception.Createfmt('Error initialising model %d ', [ModelID]);
          end;

        {-Create input arrays "RP, SQ and RQ"; create output array "Result_Array"}
          with DSmodelS_Interface do begin
            SetLength( RP, nRP ); WriteToLogFileFmt(  'nRP = %d', [nRP] );
            SetLength( SQ, nSQ ); WriteToLogFileFmt(  'nSQ = %d', [nSQ] );
            SetLength( RQ, nRQ ); WriteToLogFileFmt(  'nRQ = %d', [nRQ] );
            SetLength( Result_Array, nResPar );
          end;

          {-Bereken nat- en droogteschades}
          WriteToLogFile(  Format( 'Run model%d.', [ModelID] ) );
          ProgressBar1.Max := NRows; ProgressBar1.Position := 0;
          Screen.Cursor := crHourglass;
          for i := 1 to NRows do begin
            for j := 1 to NCols do begin

              SingleESRIgridGLG.GetCellCentre( i, j, x, y );
              Bodem := IntegerESRIgridBodemtype.GetValueXY( x, y );   {-BodemType }
              GLG   := SingleESRIgridGLG.GetValueXY( x, y );          {-GLG (m-mv)}
              GHG   := SingleESRIgridGHG.GetValueXY( x, y );          {-GLG (m-mv)}
              RP[ 0 ] := IntegerESRIgridGewas.GetValueXY( x, y ); {-Gewas}
              RP[ 1 ] := Bodem;   {-BodemType }
              RP[ 2 ] := GHG;     {-GHG (m-mv)}
              RP[ 3 ] := GLG;     {-GLG (m-mv)}

              if not AllGridsHaveData then begin {-Put MissingSingle in all output maps}
                SingleESRIgridNatschade.SetValue( i, j, MissingSingle );
                SingleESRIgridDroogteschade.SetValue( i, j, MissingSingle );
                SingleESRIgridTotaleSchade.SetValue( i, j, MissingSingle );
                SingleESRIgridIResult.SetValue( i, j, MissingSingle );
              end else begin
                Try
                  DSmodelS_Interface.Run_Model( RP, SQ, RQ, Result_Array, IResult );
                Except
                  On E: Exception do begin
                    HandleError( Format( 'Error running model at (x=%f, y=%f).', [x, y] ), true );
                    DestroyAllData; Exit;
                  end;
                end;
                SingleESRIgridNatschade.SetValue( i, j, Result_Array[ cNat ] );
                SingleESRIgridDroogteschade.SetValue( i, j, Result_Array[ cDroog ] );
                SingleESRIgridTotaleSchade.SetValue( i, j, Result_Array[ cTotaal ] );
                SingleESRIgridIResult.SetValue( i, j, IResult );
              end;
            end;
            ProgressBar1.Position := i; ProgressBar1.Update;
          end;
          WriteToLogFile(  Format( 'Model %d is finished.', [ModelID] ) );

          DestroyAlInputGrids;

          {-Write all result grids nat- en droogteschade; free memory of these grids}
          SingleESRIgridNatschade.SaveAs( Dir + '\NatSchade');
          SingleESRIgridDroogteschade.SaveAs( Dir + '\DrgSchade' );
          SingleESRIgridTotaleSchade.SaveAs( Dir + '\TotSchade' );
          SingleESRIgridIResult.SaveAsInteger( Dir + '\IResult' );

          SingleESRIgridNatschade.ExportToASC( ASCdir + '\NatSchade.asc' );
          SingleESRIgridDroogteschade.ExportToASC( ASCdir + '\DrgSchade.asc' );
          SingleESRIgridTotaleSchade.ExportToASC( ASCdir + '\TotSchade.asc' );
          SingleESRIgridIResult.ExportToASC( ASCdir + '\IResult.asc' );

          ShowMessageFmt( 'Run of model %d is successful', [ModelID] );
        end;

      Except
        On E: Exception do begin
          HandleError( E.Message, true );
        end;
      End;

      Finally
        WriteToLogFileFmt(  'iResult in reading SingleESRIgrid: %d', [iResult] );
        Try DSmodelS_Interface.Free; except end;
        DestroyAllData;
        ProgressBar1.Visible := false;
        Screen.Cursor := Save_Cursor;
      end;

  end; {-if}

end;

begin
   InitialiseGridIO;
end.
