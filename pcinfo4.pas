unit pcinfo4;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mysql56conn, sqldb, DB, Forms, Controls, Graphics, Dialogs,
  DBGrids, ExtCtrls, StdCtrls, pcinfo5, GlobalConfig;

type

  { TForm2 }

  TForm2 = class(TForm)
    Button1: TButton;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    MySQL56Connection1: TMySQL56Connection;
    Panel1: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure Button1Click(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure DBGrid1ColumnSized(Sender: TObject);
    procedure DBGrid1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Panel2Click(Sender: TObject);
    procedure LoadConfig;
    procedure AdjustDBGridColumns;
    procedure Splitter1Moved(Sender: TObject);
    procedure SQLQuery1AfterOpen(DataSet: TDataSet);
  private
    ConfigFileName, ConfigPathName, LogPathName: string;
  public

  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

{ TForm2 }
procedure TForm2.LoadConfig;

begin

  try
    MySQL56Connection1.HostName := configmanager.ReadString('Database', 'HostName', '');
    MySQL56Connection1.UserName := configmanager.ReadString('Database', 'UserName', '');
    MySQL56Connection1.Password := configmanager.ReadString('Database', 'Password', '');
    MySQL56Connection1.DatabaseName :=
      configmanager.ReadString('Database', 'DatabaseName', '');
    MySQL56Connection1.Port := configmanager.ReadInteger('Database', 'Port', 3306);
  finally

  end;
end;

procedure TForm2.DBGrid1ColumnSized(Sender: TObject);
begin

end;

procedure TForm2.DBGrid1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
var
  Grid: TDBGrid;
  Col, Row: integer;
  Field: TField;
begin
  Grid := Sender as TDBGrid;

  // Position der Zelle unter dem Mauszeiger ermitteln
  Grid.MouseToCell(X, Y, Col, Row);

  // Wenn wir über einer gültigen Zelle sind
  if (Row > 0) and (Row <= Grid.DataSource.DataSet.RecordCount) and (Col >= 1) then
  begin
    Field := Grid.Columns[Col - 1].Field;

    // Prüfen, ob es sich um ein Memo-Feld handelt und ob der Inhalt "(MEMO)" ist
    if (Field is TMemoField) and (Field.DataType = FTMEMO) then
      Grid.Hint := 'Klicken Sie, um den Inhalt anzuzeigen'
    else
      Grid.Hint := '';
  end
  else
    Grid.Hint := '';
  // Setzen Sie den Hinweis zurück, wenn Sie nicht über einer gültigen Zelle sind
end;


procedure TForm2.DBGrid1CellClick(Column: TColumn);
var
  FieldContent: string;
begin
  // Überprüfen, ob das geklickte Feld ein MEMO-Feld ist
  if DBGrid1.SelectedField is TMemoField then
  begin
    FieldContent := DBGrid1.SelectedField.AsString;

    // Neues Formular öffnen und Inhalt setzen
    with TForm3.Create(Self) do
    begin
      try
        Memo1.Lines.Text := FieldContent;
        if ShowModal = mrOk then
        begin
          // Optional: Änderungen speichern, falls gewünscht
          // DBGrid1.SelectedField.AsString := MemoView.Text;
        end;
      finally
        Free;
      end;
    end;
  end;
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
  self.ModalResult:=MrOK;
end;


procedure TForm2.FormCreate(Sender: TObject);
begin
  ConfigFileName := 'pcinfo.ini';
  {$IFDEF WINDOWS}
  ConfigPathName := 'C:\ProgramData\ge-it\';
  LogPathName := 'C:\ProgramData\ge-it\';
  {$ENDIF}
  {$IFDEF UNIX}
  ConfigPathName := '/etc/ge-it/';
  // Dies ist ein üblicher Ort für Konfigurationsdateien auf Unix-Systemen
  LogPathName := '/var/log/';
  {$ENDIF}
  ForceDirectories(ConfigPathName);
end;

procedure TForm2.AdjustDBGridColumns;
var
  i: integer;
begin
  for i := 0 to DBGrid1.Columns.Count - 1 do
  begin
    // Für dieses Beispiel setzen wir die Mindest- und Maximalbreite fest.
    // Sie können dies an Ihre eigenen Bedürfnisse anpassen.
    if DBGrid1.Columns[i].Width > 400 then
      DBGrid1.Columns[i].Width := 400;
  end;
end;

procedure TForm2.Splitter1Moved(Sender: TObject);
begin

end;

procedure TForm2.SQLQuery1AfterOpen(DataSet: TDataSet);
begin
  self.AdjustDBGridColumns;
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  LoadConfig;

  try
    MySQL56Connection1.Connected := True;
  except
    exit;
  end;

  SQLQuery1.Close;
  SQLQuery1.SQL.Text := 'SELECT * FROM pc_data';
  SQLQuery1.Open;
end;

procedure TForm2.Panel2Click(Sender: TObject);
begin

end;



end.

