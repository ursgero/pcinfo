unit ConfigBroadcastU;

interface

uses
  Classes, SysUtils, IdUDPServer, IdGlobal, IdSocketHandle, IDUDPClient,GlobalConfig;

type

  TMessageEvent = procedure(Sender: TObject; const Message: string) of object;
  TStatusChangedEvent = procedure(Sender: TObject; IsActive: boolean) of object;

  TConfigBroadcaster = class(TObject)
    UDPClient: TIdUDPClient;
    UDPServer: TIdUDPServer;
    procedure ToggleUDPServer;
    function IsConfigFileValid: boolean;
    procedure myUDPRead(AThread: TIdUDPListenerThread; AData: TIdBytes;
      ABinding: TIdSocketHandle);
    //    procedure onUDPRead(AThread: TIdUDPListenerThread; AData: TIdBytes; ABinding: TIdSocketHandle);

  private
    ConfigFileName, ConfigPathName, LogPathName: string;
    FOnConfigReceived: TNotifyEvent;
    FOnMessage: TMessageEvent;
    FWaitingForConfig: boolean;
    FOnStatusChanged: TStatusChangedEvent;


    function ReadConfigData: string;

  public
    serverisactive: boolean;
    constructor Create;
    procedure Terminate;
    destructor Destroy; override;
    //    procedure thisUDPRead(AThread: TIdUDPListenerThread; const AData: array of byte; ABinding: TIdSocketHandle);


    procedure RequestConfig;
    procedure getfilename;
    procedure StoreConfigData(const Data: string);

    procedure BroadcastConfigRequest;
    property OnConfigReceived: TNotifyEvent read FOnConfigReceived
      write FOnConfigReceived;
    property OnMessage: TMessageEvent read FOnMessage write FOnMessage;
    property OnStatusChanged: TStatusChangedEvent
      read FOnStatusChanged write FOnStatusChanged;
  end;

const
  {$IFDEF WINDOWS}
  OSString = 'Windows';
{$ELSE}
  OSString = 'Unix';
{$ENDIF}


implementation




const
  BROADCAST_PORT_server = 21468;
  BROADCAST_PORT_client = 10478;
  CONFIG_REQUEST = 'REQUEST_CONFIG';
  CONFIG_RESPONSE = 'CONFIG_DATA:';

constructor TConfigBroadcaster.Create;
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


  UDPClient := TIdUDPClient.Create(nil);
  UDPClient.BoundPort := BROADCAST_PORT_client;

  UDPServer := TIdUDPServer.Create(nil);

  UDPServer.DefaultPort := BROADCAST_PORT_server;

  UDPServer.OnUDPRead := @myUDPRead;
  UDPServer.Active := IsConfigFileValid;
  ToggleUDPServer;
  //  UDPServer.Active := True;
end;

procedure TConfigBroadcaster.ToggleUDPServer;
begin
  //  UDPServer.Active := not UDPServer.Active;
  self.serverisactive := UDPServer.Active;
  if Assigned(FOnStatusChanged) then
    FOnStatusChanged(Self, UDPServer.Active);
end;


procedure TConfigBroadcaster.RequestConfig;
begin
  UDPClient.Broadcast(CONFIG_REQUEST, BROADCAST_PORT_client);
  FWaitingForConfig := True;
end;

procedure TConfigBroadcaster.getfilename;
Begin
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

end;

function TConfigBroadcaster.IsConfigFileValid: boolean;


begin
  getfilename;
  Result := FileExists(ConfigPathName + ConfigFileName);
  if Result then
  begin

    try
      // Überprüfen Sie hier, ob die benötigten Schlüssel vorhanden und korrekt sind
      // Zum Beispiel:
      Result := configmanager.ReadBool('Database', 'ConnectionValid', False);
    finally

    end;
  end;
end;



function TConfigBroadcaster.ReadConfigData: string;

begin
  getfilename;
  Result := '';

  try
    Result := Result + configmanager.ReadString('Database', 'HostName', '') + '|';
    Result := Result + configmanager.ReadString('Database', 'UserName', '') + '|';
    Result := Result + configmanager.ReadString('Database', 'Password', '') + '|';
    Result := Result + configmanager.ReadString('Database', 'DatabaseName', '');
  finally
//    IniFile.Free;
  end;
end;

destructor TConfigBroadcaster.Destroy;
begin
  UDPServer.Free;
  UDPClient.Free;
  inherited Destroy;
end;

procedure TConfigBroadcaster.BroadcastConfigRequest;
begin
  UDPClient.Broadcast(CONFIG_REQUEST, BROADCAST_PORT_client);
end;

procedure TConfigBroadcaster.myUDPRead(AThread: TIdUDPListenerThread; AData: TIdBytes;
  ABinding: TIdSocketHandle);

var
  Msg, ConfigData: string;
begin
  Msg := BytesToString(AData);

  if Msg = CONFIG_REQUEST then
  begin
    if Assigned(FOnMessage) then
      FOnMessage(Self, Format('Received request for config from %s:%d',
        [ABinding.PeerIP, ABinding.PeerPort]));

    // Eine Anfrage nach der Konfiguration wurde empfangen. Antwort senden:
    UDPServer.Send(ABinding.PeerIP, BROADCAST_PORT_client, CONFIG_RESPONSE +
      ReadConfigData);
  end
  else if Pos(CONFIG_RESPONSE, Msg) = 1 then
  begin
    // Config-Daten empfangen
    if Assigned(FOnMessage) then
      FOnMessage(Self, Format('Received config from %s:%d',
        [ABinding.PeerIP, ABinding.PeerPort]));
    ConfigData := Copy(Msg, Length(CONFIG_RESPONSE) + 1, MaxInt);
    StoreConfigData(ConfigData);

    // Eine Antwort mit der Konfiguration wurde empfangen.
    if Assigned(FOnConfigReceived) then
      FOnConfigReceived(Self);
  end;
end;


procedure TConfigBroadcaster.StoreConfigData(const Data: string);
var

  Parts: TStringList;
begin
  Parts := TStringList.Create;
  getfilename;
  try
    ExtractStrings(['|'], [], PChar(Data), Parts);

    if Parts.Count >= 4 then
    begin

      try
        configmanager.WriteString('Database', 'HostName', Parts[0]);
        configmanager.WriteString('Database', 'UserName', Parts[1]);
        configmanager.WriteString('Database', 'Password', Parts[2]);
        configmanager.WriteString('Database', 'DatabaseName', Parts[3]);
      finally

      end;
    end;
  finally
    Parts.Free;
  end;
end;

procedure TConfigBroadcaster.Terminate;
begin
  if UDPServer.Active then
    UDPServer.Active := False;

  // Wenn es zusätzliche Aufräumarbeiten für den UDPClient gibt, führen Sie diese hier aus.
  // Für den aktuellen Code scheint dies jedoch nicht erforderlich zu sein.
end;

end.
