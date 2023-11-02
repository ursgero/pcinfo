unit ConfigManagerU;

interface

uses
  Classes, SysUtils, IniFiles;

type
  TConfigManager = class(TObject)
  private
    ConfigFileName, ConfigPathName, LogPathName: string;
    FIniFile: TIniFile;
    FConfigPath: string;
  public
    constructor Create;
    destructor Destroy; override;

    function ReadString(const Section, Ident, Default: string): string;
    procedure WriteString(const Section, Ident, Value: string);

    function ReadBool(const Section, Ident: string; Default: Boolean): Boolean;
    procedure WriteBool(const Section, Ident: string; Value: Boolean);

    function ReadInteger(const Section, Ident: string; Default: Integer): Integer;
    procedure WriteInteger(const Section, Ident: String; Value: Integer);


    // Weitere Methoden und Eigenschaften nach Bedarf
  end;



implementation

constructor TConfigManager.Create ;
begin
  inherited Create;

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


  FConfigPath := ExtractFilePath(ParamStr(0)) + ConfigFileName;
  if not FileExists(FConfigPath) then
    FConfigPath := ConfigPathName + DirectorySeparator + ConfigFileName;

  FIniFile := TIniFile.Create(FConfigPath);
end;

destructor TConfigManager.Destroy;
begin
  FIniFile.Free;
  inherited Destroy;
end;

function TConfigManager.ReadString(const Section, Ident, Default: string): string;
begin
  Result := FIniFile.ReadString(Section, Ident, Default);
end;

procedure TConfigManager.WriteString(const Section, Ident, Value: string);
begin
  FIniFile.WriteString(Section, Ident, Value);
end;

function TConfigManager.ReadBool(const Section, Ident: string; Default: Boolean): Boolean;
begin
  Result := FIniFile.ReadBool(Section, Ident, Default);
end;

procedure TConfigManager.WriteBool(const Section, Ident: string; Value: Boolean);
begin
  FIniFile.WriteBool(Section, Ident, Value);
end;

function TConfigManager.ReadInteger(const Section, Ident: string; Default: Integer): Integer;
begin
  Result := FIniFile.ReadInteger(Section, Ident, Default);
end;

procedure TConfigManager.WriteInteger(const Section, Ident: String; Value: Integer);
begin
  FIniFile.WriteInteger(Section, Ident, Value);
end;

end.

