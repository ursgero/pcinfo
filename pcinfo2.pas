unit pcinfo2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, inifiles;

type

  { TFormConfig }

  TFormConfig = class(TForm)
    SaveButton: TButton;
    EditHostName: TEdit;
    EditUserName: TEdit;
    EditPassword: TEdit;
    EditDatabaseName: TEdit;
    EditTimerInterval: TEdit;
    EditPort: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure LoadConfig;
  private
    ConfigFileName, ConfigPathName, LogPathName: string;
  public

  end;

//  const
//  ConfigFileName = 'C:\ProgramData\pcinfo.ini';


var
  FormConfig: TFormConfig;

implementation

{$R *.lfm}

{ TFormConfig }

procedure TFormConfig.FormCreate(Sender: TObject);
begin
  // Beschriftung der Labels setzen
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

procedure TFormConfig.FormShow(Sender: TObject);
begin
  Label1.Caption := 'Host Name:';
  Label2.Caption := 'User Name:';
  Label3.Caption := 'Password:';
  Label4.Caption := 'Database Name:';
  Label5.Caption := 'Timer Interval (ms):';
  Label6.Caption := 'Port:';

  LoadConfig;
end;

procedure TFormConfig.LoadConfig;
var
  IniFile: TIniFile;
begin
  if not FileExists(ConfigPathName+ConfigFileName) then Exit;

  IniFile := TIniFile.Create(ConfigPathName+ConfigFileName);
  try
    EditHostName.Text := IniFile.ReadString('Database', 'HostName', '');
    EditUserName.Text := IniFile.ReadString('Database', 'UserName', '');
    EditPassword.Text := IniFile.ReadString('Database', 'Password', '');
    EditDatabaseName.Text := IniFile.ReadString('Database', 'DatabaseName', '');
    EditTimerInterval.Text := IntToStr(IniFile.ReadInteger('Settings', 'TimerInterval', 5000));
    EditPort.Text := IntToStr(IniFile.ReadInteger('Database', 'Port', 3306));
  finally
    IniFile.Free;
  end;
end;


{ TFormConfig }

procedure TFormConfig.SaveButtonClick(Sender: TObject);
var
  IniFile: TIniFile;
begin
  try
    IniFile := TIniFile.Create(ConfigFileName);
    try
      IniFile.WriteString('Database', 'HostName', EditHostName.Text);
      IniFile.WriteString('Database', 'UserName', EditUserName.Text);
      IniFile.WriteString('Database', 'Password', EditPassword.Text);
      IniFile.WriteString('Database', 'DatabaseName', EditDatabaseName.Text);
      IniFile.WriteInteger('Settings', 'TimerInterval', StrToIntDef(EditTimerInterval.Text, 5000));
      IniFile.WriteInteger('Database', 'Port', StrToIntDef(EditPort.Text, 3306));
    finally
      IniFile.Free;
    end;
  except
    on E: Exception do
    begin
      // Erster Fehler: Problem beim Zugriff auf oder Schreiben in die INI-Datei
      try
        // Versuchen, Datei anzulegen, falls sie nicht existiert
        if not FileExists(ConfigFileName) then
          FileCreate(ConfigFileName);

        // Nach erfolgreichem Anlegen, erneut versuchen, die Parameter zu schreiben
        IniFile := TIniFile.Create(ConfigFileName);
        try
          IniFile.WriteString('Database', 'HostName', EditHostName.Text);
          IniFile.WriteString('Database', 'UserName', EditUserName.Text);
          IniFile.WriteString('Database', 'Password', EditPassword.Text);
          IniFile.WriteString('Database', 'DatabaseName', EditDatabaseName.Text);
          IniFile.WriteInteger('Settings', 'TimerInterval', StrToIntDef(EditTimerInterval.Text, 5000));
          IniFile.WriteInteger('Database', 'Port', StrToIntDef(EditPort.Text, 3306));
        finally
          IniFile.Free;
        end;

      except
        on EInner: Exception do
        begin
          // Zweiter Fehler: Problem beim erneuten Schreiben oder Anlegen der Datei
          MessageDlg('Fehler', 'Kritischer Fehler: ' + EInner.Message, mtError, [mbOK], 0);
          Exit; // Verlassen der Methode, da ein kritischer Fehler aufgetreten ist
        end;
      end;

      // Nachricht über den ersten Fehler
      MessageDlg('Fehler', 'Fehler beim Speichern der Konfiguration: ' + E.Message + '. Die Einstellungen wurden in eine neu angelegte Datei geschrieben.', mtInformation, [mbOK], 0);
    end;
  end;

  Close;
end;



end.

