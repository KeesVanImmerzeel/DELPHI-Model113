program Model113;

uses
  Forms,
  Sysutils,
  uError,
  AVGRIDIO,
  uModel113 in 'uModel113.pas' {MainForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  InitialiseGridIO;
  Try
    Try
      Application.Run;
    Except
      WriteToLogFile( Format( 'Error in application: [%s].', [ExtractFileName( ParamStr( 0 ) )] ) );
    end;
  Finally
  end;
end.
