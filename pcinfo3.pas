unit pcinfo3;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, sqldb, mysql56conn, Forms, Controls, Graphics, Dialogs,
  DBGrids, ExtCtrls, StdCtrls, inifiles;

type

  { TFormStandardDateiNamenEditor }

  TFormStandardDateiNamenEditor = class(TForm)
    btnAdd: TButton;
    Button2: TButton;
    Button3: TButton;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    MySQL56Connection1: TMySQL56Connection;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    rgOS: TRadioGroup;
    SQLQuery1: TSQLQuery;
    SQLQuery2: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure FormCreate(Sender: TObject);
    procedure LoadConfig;
    procedure btnAddClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
     ConfigFileName, ConfigPathName, LogPathName: string;
  public

  end;

//const
//  ConfigFileName = 'C:\ProgramData\pcinfo.ini';

var
  FormStandardDateiNamenEditor: TFormStandardDateiNamenEditor;

implementation

{$R *.lfm}

{ TFormStandardDateiNamenEditor }

procedure TFormStandardDateiNamenEditor.btnAddClick(Sender: TObject);
var
  selectedOS: string;
begin
  // Dateidialog öffnen
  if OpenDialog1.Execute then
  begin
    // Betriebssystem auswählen
    if rgOS.ItemIndex = 0 then
      selectedOS := 'Windows'
    else
      selectedOS := 'Unix';

    // Oder: automatische Erkennung des aktuellen OS
    {$IFDEF WINDOWS}
    selectedOS := 'Windows';
    {$ENDIF}
    {$IFDEF UNIX}
    selectedOS := 'Unix';
    {$ENDIF}

    // Daten in die Datenbank einfügen
//    SQLQuery2.Active:=true;
    SQLQuery2.SQL.Text := 'INSERT INTO standard_datei_namen (DateiName, OS) VALUES (:DateiName, :OS)';
    SQLQuery2.Params.ParamByName('DateiName').AsString := OpenDialog1.FileName;
    SQLQuery2.Params.ParamByName('OS').AsString := selectedOS;
    SQLQuery2.ExecSQL;

    // Optional: Transaktion commiten
    SQLTransaction1.Commit;

    // Daten neu laden/anzeigen
      SQLQuery1.Close;
  SQLQuery1.SQL.Text := 'SELECT * FROM standard_datei_namen';
  SQLQuery1.Open;
//    SQLQuery1.Refresh;
  end;
end;

procedure TFormStandardDateiNamenEditor.LoadConfig;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(ConfigPathName+ConfigFileName);
  try
    MySQL56Connection1.HostName := IniFile.ReadString('Database', 'HostName', '');
    MySQL56Connection1.UserName := IniFile.ReadString('Database', 'UserName', '');
    MySQL56Connection1.Password := IniFile.ReadString('Database', 'Password', '');
    MySQL56Connection1.DatabaseName :=
      IniFile.ReadString('Database', 'DatabaseName', '');
    MySQL56Connection1.Port := IniFile.ReadInteger('Database', 'Port', 3306);
  finally
    IniFile.Free;
  end;
end;

procedure TFormStandardDateiNamenEditor.FormCreate(Sender: TObject);
begin
    ConfigFileName := 'pcinfo.ini';
  {$IFDEF WINDOWS}
  ConfigPathName := 'C:\ProgramData\ge-it\';
  LogPathName :=  'C:\ProgramData\ge-it\';
  {$ENDIF}
  {$IFDEF UNIX}
  ConfigPathName := '/etc/ge-it/';  // Dies ist ein üblicher Ort für Konfigurationsdateien auf Unix-Systemen
  LogPathName :=  '/var/log/';
  {$ENDIF}
  ForceDirectories(ConfigPathName);
end;

procedure TFormStandardDateiNamenEditor.FormShow(Sender: TObject);
begin
  LoadConfig;

  try
    MySQL56Connection1.Connected := True;
  except
    exit;
  end;

  SQLQuery1.Close;
  SQLQuery1.SQL.Text := 'SELECT * FROM standard_datei_namen';
  SQLQuery1.Open;

end;

end.

