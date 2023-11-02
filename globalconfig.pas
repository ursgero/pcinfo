unit GlobalConfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ConfigManagerU;

var
  ConfigManager: TConfigManager;

implementation

initialization
  // Pfad zur Konfigurationsdatei wird festgelegt, hier als Beispiel "MeinConfigFile.ini".
  ConfigManager := TConfigManager.Create;

finalization
  FreeAndNil(ConfigManager);

end.


