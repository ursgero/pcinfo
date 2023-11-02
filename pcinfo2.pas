unit pcinfo2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,  GlobalConfig;

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

begin

  try
    EditHostName.Text := configmanager.ReadString('Database', 'HostName', '');
    EditUserName.Text := configmanager.ReadString('Database', 'UserName', '');
    EditPassword.Text := configmanager.ReadString('Database', 'Password', '');
    EditDatabaseName.Text := configmanager.ReadString('Database', 'DatabaseName', '');
    EditTimerInterval.Text := IntToStr(configmanager.ReadInteger('Settings', 'TimerInterval', 5000));
    EditPort.Text := IntToStr(configmanager.ReadInteger('Database', 'Port', 3306));
  finally

  end;
end;


{ TFormConfig }

procedure TFormConfig.SaveButtonClick(Sender: TObject);

begin
  try


      configmanager.WriteString('Database', 'HostName', EditHostName.Text);
      configmanager.WriteString('Database', 'UserName', EditUserName.Text);
      configmanager.WriteString('Database', 'Password', EditPassword.Text);
      configmanager.WriteString('Database', 'DatabaseName', EditDatabaseName.Text);
      configmanager.WriteInteger('Settings', 'TimerInterval', StrToIntDef(EditTimerInterval.Text, 5000));
      configmanager.WriteInteger('Database', 'Port', StrToIntDef(EditPort.Text, 3306));

  except
    on E: Exception do
    begin
      // Erster Fehler: Problem beim Zugriff auf oder Schreiben in die INI-Datei
      try
        // Versuchen, Datei anzulegen, falls sie nicht existiert
        if not FileExists(ConfigFileName) then
          FileCreate(ConfigFileName);

        // Nach erfolgreichem Anlegen, erneut versuchen, die Parameter zu schreiben
;
        try
          configmanager.WriteString('Database', 'HostName', EditHostName.Text);
          configmanager.WriteString('Database', 'UserName', EditUserName.Text);
          configmanager.WriteString('Database', 'Password', EditPassword.Text);
          configmanager.WriteString('Database', 'DatabaseName', EditDatabaseName.Text);
          configmanager.WriteInteger('Settings', 'TimerInterval', StrToIntDef(EditTimerInterval.Text, 5000));
          configmanager.WriteInteger('Database', 'Port', StrToIntDef(EditPort.Text, 3306));
        finally

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

