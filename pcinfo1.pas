unit pcinfo1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mysql56conn, sqldb, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, IdUDPServer, inifiles, pcinfo2, pcinfo3, pcinfo4,
  shellapi, IdSocketHandle, IdGlobal, ConfigBroadCastU;

type

  { TForm1 }

  TForm1 = class(TForm)
    BtnEditConfig: TButton;
    Button1: TButton;
    Button2: TButton;
    btnOpenConfig: TButton;
    Edit1: TEdit;
    IdUDPServer1: TIdUDPServer;
    Label1: TLabel;
    ListBox1: TListBox;
    Memo1: TMemo;
    MySQL56Connection1: TMySQL56Connection;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Shape1: TShape;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    Timer1: TTimer;
    btnCancel: TToggleBox;
    TrayIcon1: TTrayIcon;
    procedure btnCancelChange(Sender: TObject);
    procedure BtnEditConfigClick(Sender: TObject);
    procedure btnOpenConfigClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure IdUDPServer1UDPRead(AThread: TIdUDPListenerThread;
      AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure Timer1Timer(Sender: TObject);
    procedure StartConfigAssistant();
    procedure LoadConfig;
    function ConnectToDatabase: boolean;
    procedure TrayIcon1Click(Sender: TObject);
    function UserExists: boolean;
    procedure CreateUser;
    function AskForDatabaseCredentials: boolean;
    function TestDatabaseConnection(DB: string): boolean;
    function DatabaseExists(): boolean;
    procedure CreateDatabase();
    procedure CreateTable();
    procedure SaveConfig;
    procedure ConfigReceived(Sender: TObject);
    procedure UpdateConnectionStatusInConfig(IsValid: boolean);
    procedure HandleConfigMessage(Sender: TObject; const Message: string);
    procedure ConfigBroadcasterStatusChanged(Sender: TObject; IsActive: boolean);
    procedure UpdateUDPServerStatus;
  private
    FOnConfigReceived: TNotifyEvent;
    //         ConfigFileName, ConfigPathName, LogPathName: string;
    RootUsername, RootPassword: string;
    ConfigBroadcaster: TConfigBroadcaster;

    ConfigFileName, ConfigPathName, LogPathName: string;
    FWaitingForConfig: boolean;
    //        function ReadConfigData: string;

  public
    procedure LogToFile(const Message: string);
    //         procedure RequestConfig;
    //         procedure StoreConfigData(const Data: string);
    //         procedure BroadcastConfigRequest;
    //         property OnConfigReceived: TNotifyEvent read FOnConfigReceived write FOnConfigReceived;
  end;

const
{$IFDEF WINDOWS}
  OSString = 'Windows';
{$ELSE}
  OSString = 'Unix';
{$ENDIF}
  DBName = 'pc_data';

//const
//  ConfigFileName = 'C:\ProgramData\ge-it\pcinfo.ini';

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

function TForm1.AskForDatabaseCredentials: boolean;
var
  DBServer, DBUser, DBPass, DBName: string;
  IniFile: TIniFile;
begin
  Result := False;

  DBServer := InputBox('Datenbankverbindung', 'Bitte geben Sie den Datenbankserver ein:',
    MySQL56Connection1.HostName);
  if DBServer = '' then
    Exit;

  form1.RootUsername := InputBox('Datenbankverbindung',
    'Bitte geben Sie den Root/Admin Benutzernamen ein:', form1.RootUsername);
  if form1.RootUsername = '' then
    Exit;

  form1.RootPassword := InputBox('Datenbankverbindung',
    'Bitte geben Sie für Root/Admin das Passwort ein:', form1.RootPassword);
  if form1.RootPassword = '' then
    Exit;

  MySQL56Connection1.UserName := 'pcinfo';
  DBUser := InputBox('Datenbankverbindung', 'Bitte geben Sie den Benutzernamen ein:',
    MySQL56Connection1.UserName);
  if DBUser = '' then
    Exit;

  MySQL56Connection1.Password := 'pcinfo';
  DBPass := InputBox('Datenbankverbindung', 'Bitte geben Sie das Passwort ein:',
    MySQL56Connection1.Password);
  if DBPass = '' then
    Exit;

  DBName := InputBox('Datenbankverbindung',
    'Bitte geben Sie den Namen der Datenbank ein:', MySQL56Connection1.DatabaseName);
  if DBName = '' then
    Exit;

  // Werte im Connection-Objekt setzen
  MySQL56Connection1.HostName := DBServer;
  MySQL56Connection1.UserName := form1.RootUsername;
  MySQL56Connection1.Password := form1.RootPassword;
  MySQL56Connection1.DatabaseName := DBName;

  // Werte in die INI-Datei schreiben
  IniFile := TIniFile.Create(ConfigPathName + ConfigFileName);
  try
    IniFile.WriteString('Database', 'HostName', DBServer);
    IniFile.WriteString('Database', 'UserName', DBUser);
    IniFile.WriteString('Database', 'Password', DBPass);
    IniFile.WriteString('Database', 'DatabaseName', DBName);
  finally
    IniFile.Free;

  end;

  Result := True;
end;

procedure TForm1.UpdateConnectionStatusInConfig(IsValid: boolean);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(ConfigPathName + ConfigFileName);
  try
    IniFile.WriteBool('Database', 'ConnectionValid', IsValid);
  finally
    IniFile.Free;
  end;
end;



function TForm1.TestDatabaseConnection(DB: string): boolean;
var
  BDB: string;
begin
  try
    BDB := MySQL56Connection1.DatabaseName;
    if DB <> '' then
      MySQL56Connection1.DatabaseName := DB;
    MySQL56Connection1.Connected := True;
    Result := True;
  except
    on E: Exception do
    begin
      LogToFile('Datenbankverbindung fehlgeschlagen: ' + E.Message);
      ShowMessage('Datenbankverbindung fehlgeschlagen: ' + E.Message);
      UpdateConnectionStatusInConfig(False);
      Result := False;
    end;
  end;
  MySQL56Connection1.DatabaseName := BDB;
  UpdateConnectionStatusInConfig(True);
end;



function TForm1.DatabaseExists: boolean;
var
  SQLQuery: TSQLQuery;
  OriginalDBName: string;
begin
  Result := False;
  SQLQuery := TSQLQuery.Create(nil);
  try
    // Speichern Sie den ursprünglichen Datenbanknamen
    OriginalDBName := MySQL56Connection1.DatabaseName;

    // Setzen Sie die DatabaseName-Eigenschaft auf einen leeren String
    MySQL56Connection1.DatabaseName := 'information_schema';

    // Verbindung herstellen
    MySQL56Connection1.Connected := True;

    SQLQuery.Database := MySQL56Connection1;
    SQLQuery.Transaction := SQLTransaction1;

    // SQL-Abfrage, um zu überprüfen, ob die Datenbank existiert
    SQLQuery.SQL.Text := 'SHOW DATABASES LIKE :DBName';
    SQLQuery.Params.ParamByName('DBName').AsString := OriginalDBName;

    SQLQuery.Open;

    // Überprüfen, ob Ergebnisse zurückgeliefert wurden
    if not SQLQuery.EOF then
      Result := True;

    // Schließen Sie die Verbindung
    MySQL56Connection1.Connected := False;

    // Setzen Sie den Datenbanknamen zurück
    MySQL56Connection1.DatabaseName := OriginalDBName;
  finally
    SQLQuery.Free;
  end;
end;




procedure TForm1.CreateDatabase;
var
  Query: TSQLQuery;
  OriginalDBName, Originaluser, Originalpassword: string;
begin
  Query := TSQLQuery.Create(nil);
  try
    OriginalDBName := MySQL56Connection1.DatabaseName;
    Originaluser := MySQL56Connection1.UserName;
    OriginalPassword := MySQL56Connection1.Password;

    // Verbinden Sie sich mit einer Standarddatenbank (z. B. "information_schema")
    MySQL56Connection1.DatabaseName := 'information_schema';
    MySQL56Connection1.UserName := form1.RootUsername;
    MySQL56Connection1.Password := form1.RootPassword;
    // Verbindung herstellen
    MySQL56Connection1.Connected := True;

    Query.DataBase := MySQL56Connection1;

    Query.SQL.Text := Format('CREATE DATABASE %s COLLATE utf8mb4_german2_ci;',
      [OriginalDBName]);
    Query.ExecSQL;

    // Schließen Sie die Verbindung
    MySQL56Connection1.Connected := False;

    // Setzen Sie den Datenbanknamen zurück
    MySQL56Connection1.DatabaseName := OriginalDBName;
    MySQL56Connection1.UserName := OriginalUser;
    MySQL56Connection1.Password := OriginalPassword;
  finally
    Query.Free;
  end;
end;



procedure TForm1.CreateTable();
begin
  try
    SQLQuery1.SQL.Text :=
      'CREATE TABLE `pc_data` (' + '`ID` INT(11) NOT NULL AUTO_INCREMENT,' +
      '`PCName` VARCHAR(255) NOT NULL COLLATE "utf8mb4_german2_ci",' +
      '	`DateiName` VARCHAR(255) NOT NULL COLLATE "utf8mb4_german2_ci",' +
      '	`FileContent` LONGTEXT NULL DEFAULT NULL COLLATE "utf8mb4_german2_ci",' +
      '	`ErrorMessage` TEXT NULL DEFAULT NULL COLLATE "utf8mb4_german2_ci",' +
      '	`zuletztGelesen` TIMESTAMP NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
      +
      '	`letztesUpdate` DATETIME NULL DEFAULT NULL,' +
      '	PRIMARY KEY (`ID`) USING BTREE' + ') ' + 'COLLATE="utf8mb4_german2_ci" ' +
      'ENGINE=InnoDB ' + 'AUTO_INCREMENT=1' + ';';

    SQLQuery1.ExecSQL;


    SQLQuery1.SQL.Text :=
      'CREATE TABLE `standard_datei_namen` (' +
      '	`ID` INT(11) NOT NULL AUTO_INCREMENT,' +
      '	`DateiName` VARCHAR(255) NOT NULL COLLATE "utf8mb4_german2_ci",' +
      '   `OS` VARCHAR(50) NOT NULL DEFAULT "Windows" COLLATE "utf8mb4_german2_ci",' +
      '	PRIMARY KEY (`ID`) USING BTREE' + ') ' + 'COLLATE="utf8mb4_german2_ci" ' +
      'ENGINE=InnoDB ' + 'AUTO_INCREMENT=1';

    SQLQuery1.ExecSQL;
  except
    on E: Exception do
    begin
      LogToFile('Tabellenerstellungsfehler: ' + E.Message);
      ShowMessage('Tabellenerstellungsfehler: ' + E.Message);
    end;
  end;
end;

function TForm1.UserExists: boolean;
var
  SQLQuery: TSQLQuery;
  IniFile: TIniFile;
  NewUserName: string;
begin
  Result := False;

  IniFile := TIniFile.Create(ConfigPathName + ConfigFileName);
  try
    NewUserName := IniFile.ReadString('Database', 'UserName', '');
  finally
    IniFile.Free;
  end;

  SQLQuery := TSQLQuery.Create(nil);
  try
    SQLQuery.Database := MySQL56Connection1;
    SQLQuery.Transaction := SQLTransaction1;

    // Abfrage, um zu überprüfen, ob der Benutzer existiert
    SQLQuery.SQL.Text := 'SELECT user FROM mysql.user WHERE user = :UserName';
    SQLQuery.Params.ParamByName('UserName').AsString := NewUserName;

    SQLQuery.Open;

    // Überprüfen, ob Ergebnisse zurückgeliefert wurden
    if not SQLQuery.EOF then
      Result := True;
  finally
    SQLQuery.Free;
  end;
end;




procedure TForm1.CreateUser;
var
  IniFile: TIniFile;
  NewUserName, NewUserPassword, Database: string;
begin
  IniFile := TIniFile.Create(ConfigPathName + ConfigFileName);
  try
    NewUserName := IniFile.ReadString('Database', 'UserName', '');
    NewUserPassword := IniFile.ReadString('Database', 'Password', '');
    Database := IniFile.ReadString('Database', 'DatabaseName', '');
  finally
    IniFile.Free;
  end;
  try
    // Benutzer erstellen (dies kann je nach Datenbanksystem variieren).
    SQLQuery1.SQL.Text := Format('CREATE USER "%s"@"%%" IDENTIFIED BY "%s";',
      [NewUserName, NewUserPassword]);
    logtofile('Benutzererstellung: ' + SQLQuery1.SQL.Text);
    SQLQuery1.ExecSQL;
    // Rechte gewähren
    SQLQuery1.SQL.Text := 'GRANT USAGE ON *.*  TO "' + NewUserName + '"@"%";';
    logtofile('Benutzererstellung: ' + SQLQuery1.SQL.Text);
    SQLQuery1.ExecSQL;

    // Privilegien aktualisieren
    SQLQuery1.SQL.Text := 'FLUSH PRIVILEGES;';
    logtofile('Benutzererstellung: ' + SQLQuery1.SQL.Text);
    SQLQuery1.ExecSQL;

    SQLQuery1.SQL.Text := Format(
      'GRANT EXECUTE, SELECT, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, ' +
      'CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, '
      +
      'INDEX, INSERT, REFERENCES, TRIGGER, UPDATE, LOCK TABLES ON `%s`.* TO "%s"@"%%" WITH GRANT OPTION;',
      [Database, NewUserName]);
    SQLQuery1.ExecSQL;

    // Privilegien erneut aktualisieren
    SQLQuery1.SQL.Text := 'FLUSH PRIVILEGES;';
    logtofile('Benutzererstellung: ' + SQLQuery1.SQL.Text);
    SQLQuery1.ExecSQL;


  except
    on E: Exception do
    begin
      logtofile('Benutzererstellungsfehler: ' + E.Message);
      logtofile('Benutzererstellungsfehler: ' + SQLQuery1.SQL.Text);
      ShowMessage('Benutzererstellungsfehler: ' + E.Message);
    end;
  end;
end;

procedure TForm1.SaveConfig;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(ConfigPathName + ConfigFileName);
  try
    IniFile.WriteString('Database', 'HostName', MySQL56Connection1.HostName);
    IniFile.WriteString('Database', 'UserName', MySQL56Connection1.UserName);
    IniFile.WriteString('Database', 'Password', MySQL56Connection1.Password);
    IniFile.WriteString('Database', 'DatabaseName', MySQL56Connection1.DatabaseName);
    IniFile.WriteInteger('Database', 'Port', MySQL56Connection1.Port);
    IniFile.WriteInteger('Settings', 'TimerInterval', Timer1.Interval);
    UpdateConnectionStatusInConfig(False);
  finally
    IniFile.Free;
  end;
end;


procedure TForm1.Timer1Timer(Sender: TObject);
var
  pcName: string;
  dateiName: string;
  ci: integer;
  SQLQuery2: TSQLQuery;
begin
  Timer1.Enabled := False; // Timer deaktivieren

  // PC-Namen aus den Systemvariablen auslesen
  pcName := GetEnvironmentVariable('COMPUTERNAME');

  SQLQuery1.Close;
  SQLQuery1.SQL.Text := 'SELECT DateiName FROM standard_datei_namen WHERE OS = :OSValue';
  SQLQuery1.Params.ParamByName('OSValue').AsString := OSString;
  SQLQuery1.Open;


  try
    SQLQuery2 := TSQLQuery.Create(nil);
    SQLQuery2.Database := SQLQuery1.Database;
    SQLQuery2.Transaction := SQLTransaction1;

    sqlquery1.First;
    Listbox1.Items.Clear;

    while not SQLQuery1.EOF do
    begin
      dateiName := SQLQuery1.FieldByName('DateiName').AsString;
      ListBox1.Items.Add(dateiName);
      sqlquery1.Next;
    end;
    sqlquery1.Close;

    for ci := 0 to ListBox1.Items.Count - 1 do
    begin
      dateiName := ListBox1.Items[ci];
      if FileExists(dateiName) then
      begin

        try
          Memo1.Lines.LoadFromFile(dateiName);
          Edit1.Text := dateiName;
          // Überprüfen, ob ein Eintrag für den aktuellen PC-Namen und Dateinamen bereits vorhanden ist
          SQLQuery2.Close;
          SQLQuery2.SQL.Text :=
            'SELECT * FROM pc_data WHERE PcName = :PCName AND DateiName = :DateiName';
          SQLQuery2.Params.ParamByName('PCName').AsString := pcName;
          SQLQuery2.Params.ParamByName('DateiName').AsString := dateiName;
          SQLQuery2.Open;

          if SQLQuery2.RecordCount > 0 then
          begin
            // UPDATE verwenden, um den bestehenden Eintrag zu aktualisieren
            SQLQuery2.Close;
            SQLQuery2.SQL.Text :=
              'UPDATE pc_data SET FileContent = :FileContent, letztesUpdate = NOW() WHERE PcName = :PCName AND DateiName = :DateiName';
            SQLQuery2.Params.ParamByName('PCName').AsString := pcName;
            SQLQuery2.Params.ParamByName('DateiName').AsString := dateiName;
            SQLQuery2.Params.ParamByName('FileContent').AsString := Memo1.Text;
            SQLQuery2.ExecSQL;
            SQLTransaction1.Commit;
          end
          else
          begin
            // INSERT verwenden, um einen neuen Eintrag hinzuzufügen
            SQLQuery2.Close;
            SQLQuery2.SQL.Text :=
              'INSERT INTO pc_data (PCName,DateiName, FileContent, letztesUpdate) VALUES (:PCName, :DateiName, :FileContent, NOW())';
            SQLQuery2.Params.ParamByName('PCName').AsString := pcName;
            SQLQuery2.Params.ParamByName('DateiName').AsString := dateiName;
            SQLQuery2.Params.ParamByName('FileContent').AsString := Memo1.Text;
            SQLQuery2.ExecSQL;
            SQLTransaction1.Commit;
          end;
          UpdateConnectionStatusInConfig(True);
        except
          on E: Exception do
          begin
            UpdateConnectionStatusInConfig(False);
            LogToFile('Fehler beim Ausführen der SQL-Operation: ' + E.Message);
          end;
        end;

      end
      else
      begin
        try
          // Überprüfen, ob ein Eintrag für den aktuellen PC-Namen und Dateinamen bereits vorhanden ist
          SQLQuery2.Close;
          SQLQuery2.SQL.Text :=
            'SELECT COUNT(*) as EntryCount FROM pc_data WHERE PcName = :PCName AND DateiName = :DateiName';
          SQLQuery2.Params.ParamByName('PCName').AsString := pcName;
          SQLQuery2.Params.ParamByName('DateiName').AsString := dateiName;
          SQLQuery2.Open;

          if SQLQuery1.FieldByName('EntryCount').AsInteger > 0 then
          begin
            // UPDATE verwenden, um den bestehenden Eintrag zu aktualisieren
            SQLQuery2.Close;
            SQLQuery2.SQL.Text :=
              'UPDATE pc_data SET ErrorMessage = :ErrorMessage, letztesUpdate = NOW()  WHERE PcName = :PCName AND DateiName = :DateiName';
            SQLQuery2.Params.ParamByName('PCName').AsString := pcName;
            SQLQuery2.Params.ParamByName('DateiName').AsString := dateiName;
            SQLQuery2.Params.ParamByName('ErrorMessage').AsString := 'Fehlermeldung hier...';
            // Aktualisieren Sie diesen Platzhalter entsprechend Ihrem Code
            SQLQuery2.ExecSQL;
            SQLTransaction1.Commit;
          end
          else
          begin
            // INSERT verwenden, um einen neuen Eintrag hinzuzufügen
            SQLQuery2.Close;
            SQLQuery2.SQL.Text :=
              'INSERT INTO pc_data (PcName,DateiName, ErrorMessage, letztesUpdate) VALUES (:PCName, :DateiName, :ErrorMessage, now())';
            SQLQuery2.Params.ParamByName('PCName').AsString := pcName;
            SQLQuery2.Params.ParamByName('DateiName').AsString := dateiName;
            SQLQuery2.Params.ParamByName('ErrorMessage').AsString := 'Fehlermeldung hier...';
            // Aktualisieren Sie diesen Platzhalter entsprechend Ihrem Code
            SQLQuery2.ExecSQL;
            SQLTransaction1.Commit;
          end;
          UpdateConnectionStatusInConfig(True);
        except
          on E: Exception do
          begin
            UpdateConnectionStatusInConfig(False);
            LogToFile('Fehler beim Ausführen der SQL-Operation: ' + E.Message);
          end;
        end;

      end;

      //    SQLQuery1.Next;
    end;

  finally
    SQLQuery2.Free;
  end;

  //  Application.Terminate; // Programm beenden
end;

procedure TForm1.StartConfigAssistant();
begin
  // AskForDatabaseCredentials(var DBServer, DBUser, DBPassword: string)
  if AskForDatabaseCredentials and TestDatabaseConnection('information_schema') then
  begin
    if not DatabaseExists() then
    begin
      CreateDatabase();
      CreateTable();
    end;

    if not UserExists then
    begin
      CreateUser;
    end;
  end
  else
  begin
    ShowMessage('Verbindung zum SQL-Server konnte nicht hergestellt werden.');
    Application.Terminate;
  end;
end;


procedure TForm1.BtnEditConfigClick(Sender: TObject);
begin
  FormConfig.ShowModal; // Öffnet das Konfigurationsformular zur Bearbeitung
  LoadConfig;  // Neue Methode, um die Konfiguration erneut zu laden (siehe unten)

  try
    MySQL56Connection1.Connected := True;
  except
    Timer1.Enabled := False;
  end;
  if not FileExists(ConfigFileName) then
  begin
    Timer1.Enabled := False;
    Exit;
  end
  else if not ConnectToDatabase then
    // ConnectToDatabase sollte Ihre Methode sein, um eine Verbindung herzustellen.
  begin
    Timer1.Enabled := False;
    Exit;
  end
  else
    Timer1.Enabled := True;

end;

procedure TForm1.btnCancelChange(Sender: TObject);
begin
  Application.Terminate;

end;

procedure TForm1.btnOpenConfigClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(Application.ExeName), '/DBCreate', nil, 1);
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Form2.showmodal;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  FormStandardDateiNamenEditor.showmodal;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ConfigBroadcaster.Terminate;
end;

procedure TForm1.LogToFile(const Message: string);
var
  LogFile: TextFile;
  LogFileName: string;
begin
  LogFileName := LogPathName + 'errorlog.txt';
  // Verwenden des globalen Pfads für die Logdatei
  AssignFile(LogFile, LogFileName);
  if FileExists(LogFileName) then
    Append(LogFile)  // Wenn die Datei bereits existiert, fügen Sie dem Ende hinzu
  else
    Rewrite(LogFile);  // Wenn die Datei nicht existiert, erstellen Sie eine neue
  try
    WriteLn(LogFile, DateTimeToStr(Now) + ': ' + Message);
    // Schreiben Sie das aktuelle Datum, die Uhrzeit und die Fehlermeldung
  finally
    CloseFile(LogFile);
  end;
end;



procedure TForm1.LoadConfig;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(ConfigPathName + ConfigFileName);
  try
    MySQL56Connection1.HostName := IniFile.ReadString('Database', 'HostName', '');
    MySQL56Connection1.UserName := IniFile.ReadString('Database', 'UserName', '');
    MySQL56Connection1.Password := IniFile.ReadString('Database', 'Password', '');
    MySQL56Connection1.DatabaseName :=
      IniFile.ReadString('Database', 'DatabaseName', '');
    MySQL56Connection1.Port := IniFile.ReadInteger('Database', 'Port', 3306);
    Timer1.Interval := IniFile.ReadInteger('Settings', 'TimerInterval', 5000);
  finally
    IniFile.Free;
  end;
end;

procedure TForm1.HandleConfigMessage(Sender: TObject; const Message: string);
begin
  // Fügen Sie die Nachricht zu Ihrem Memo hinzu
  LogToFile(Message);
  Memo1.Lines.Add(Message);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ConfigBroadcaster := TConfigBroadcaster.Create;
  //  OnConfigReceived := @ConfigReceived;
  ConfigBroadcaster.OnMessage := @HandleConfigMessage;
  //  ConfigBroadcaster.OnStatusChanged := @ConfigBroadcasterStatusChanged;

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

procedure TForm1.ConfigBroadcasterStatusChanged(Sender: TObject; IsActive: boolean);
begin
  UpdateUDPServerStatus;
end;

function TForm1.ConnectToDatabase: boolean;
begin
  Result := False;
  try
    MySQL56Connection1.Connected := False; // Zuerst trennen
    MySQL56Connection1.Connected := True;  // Versuch, erneut zu verbinden
    Result := MySQL56Connection1.Connected; // Wenn erfolgreich, Result = True
  except
    on E: Exception do
    begin
      // Hier könnten Sie zusätzliche Fehlerbehandlungen oder Protokollierungen hinzufügen
      logtofile('Fehler beim Verbinden mit der Datenbank: ' + E.Message);
      ShowMessage('Fehler beim Verbinden mit der Datenbank: ' + E.Message);
    end;
  end;
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  Self.Show;                // Das Hauptformular anzeigen
  Self.WindowState := wsNormal; // Fensterstatus auf "Normal" setzen
  TrayIcon1.Visible := False;   // Das TrayIcon ausblenden
end;


procedure TForm1.ConfigReceived(Sender: TObject);
begin
  // Hier können Sie die empfangene Konfiguration verarbeiten.
end;

{
procedure TForm1.FormShow(Sender: TObject);
begin
  Timer1.Enabled:=false;

  if (ParamCount > 0) and (ParamStr(1) = '/DBCreate') then
  begin
    StartConfigAssistant();
    FormConfig.ShowModal;
    application.Terminate;
  end;

  LoadConfig;  // Verwenden der neuen Methode zum Laden der Konfiguration

  try
  MySQL56Connection1.Connected := True;
  except
    Timer1.Enabled:=false;
    Panel1.Visible := True;
    Panel1.Align:=alClient;
    Panel1.BringToFront;
  end;

  if not FileExists(ConfigPathName+ConfigFileName) then
  begin
    Timer1.Enabled:=false;
 //   ConfigBroadcaster.BroadcastConfigRequest;

    Panel1.Visible := True;
    Panel1.Align:=alClient;
    Panel1.BringToFront;
  end
  else if not ConnectToDatabase then
  begin
    Timer1.Enabled:=false;
    Panel1.Visible := True;
    Panel1.Align:=alClient;
    Panel1.BringToFront;
  end
  else
    Timer1.Enabled := True;
end;                       }

procedure TForm1.UpdateUDPServerStatus;
begin
  if ConfigBroadcaster.serverisactive then
  begin
    Shape1.Brush.Color := clGreen;
    Shape1.Hint := 'UDPServer ist aktiv';
  end
  else
  begin
    Shape1.Brush.Color := clRed;
    Shape1.Hint := 'UDPServer ist nicht aktiv';
  end;
  Shape1.ShowHint := True;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  //  ConfigBroadcaster: TConfigBroadcaster;
  Response: integer;
begin
  Timer1.Enabled := False;

  if (ParamCount > 0) and (ParamStr(1) = '/DBCreate') then
  begin
    StartConfigAssistant();
    FormConfig.ShowModal;
    application.Terminate;
  end;

  LoadConfig;  // Verwenden der neuen Methode zum Laden der Konfiguration


  try
    // Überprüfen, ob die Konfigurationsdatei vorhanden und gültig ist
    if not ConfigBroadcaster.IsConfigFileValid then
    begin
      Timer1.Enabled := False;
      Panel1.Visible := True;
      Panel1.Align := alClient;
      Panel1.BringToFront;

      Response := MessageDlg(
        'Keine gültige Konfigurationsdatei gefunden. Möchten Sie eine Netzwerkanfrage durchführen oder das Konfigurationsformular öffnen?',
        mtConfirmation, [mbYes, mbNo], 0);
      case Response of
        mrYes:
        begin
          ConfigBroadcaster.RequestConfig;
          ShowMessage('Suche nach Konfigurationsdatei im Netzwerk...');
        end;
        mrNo:
        begin
          // Hier öffnen Sie das Konfigurationsformular
          FormConfig.ShowModal;
        end;
      end;
    end;
  finally

  end;

  try
    MySQL56Connection1.Connected := True;
  except
    Timer1.Enabled := False;
    Panel1.Visible := True;
    Panel1.Align := alClient;
    Panel1.BringToFront;
  end;

  if not ConnectToDatabase then
  begin
    Timer1.Enabled := False;
    Panel1.Visible := True;
    Panel1.Align := alClient;
    Panel1.BringToFront;
  end
  else
    Timer1.Enabled := True;
  UpdateUDPServerStatus;
end;

procedure TForm1.FormWindowStateChange(Sender: TObject);
begin
  if Self.WindowState = wsMinimized then
  begin
    Self.Hide;
    TrayIcon1.Visible := True;
  end;
end;



procedure TForm1.IdUDPServer1UDPRead(AThread: TIdUDPListenerThread;
  AData: TIdBytes; ABinding: TIdSocketHandle);
begin

end;



end.
