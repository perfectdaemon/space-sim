unit uBooster;

interface

const
  C_BOOSTERS_PATH = 'data\gadgets\';

type
  TdfBooster = class
  private
    FRecSpeed: Single;
    FDuration: Single;
    FSpeedBonus: Single;
    FName: String;
    FDesc: String;
  protected
  public
    property Name: String read FName write FName;
    property Description: String read FDesc write FDesc;

    {Бонус к скорости, коорый дается ускорителем}
    property SpeedBonus: Single read FSpeedBonus write FSpeedBonus;
    {Продолжительность работы ускорителя}
    property Duration: Single read FDuration write FDuration;
    {Скорость восстановления "заряда"}
    property RechargeSpeed: Single read FRecSpeed write FRecSpeed;

    procedure LoadFromFile(const aFile: String);
  end;

implementation

uses
  SysUtils, IniFiles, uLog;

{ TdfBooster }

const
  C_MAIN = 'Main';
  C_NO_INFO = '<Не определено>';

procedure TdfBooster.LoadFromFile(const aFile: String);
var
  Ini: TIniFile;
begin
  if FileExists(C_BOOSTERS_PATH + aFile) then
  begin
    Ini := TIniFile.Create(C_BOOSTERS_PATH + aFile);

    FName := Ini.ReadString(C_MAIN, 'Name', C_NO_INFO);
    FDesc := Ini.ReadString(C_MAIN, 'Desc', C_NO_INFO);

    FSpeedBonus := Ini.ReadFloat(C_MAIN, 'SpeedBonus', 0.0);
    FDuration := Ini.ReadFloat(C_MAIN, 'Duration', 0.0);
    FRecSpeed := Ini.ReadFloat(C_MAIN, 'RechargeSpeed', 1.0);

    logWriteMessage('TdfBooster: Booster "' + FName + '" loaded from file ' + aFile);
    Ini.Free;
  end
  else
    logWriteError('TdfBooster: File ' + aFile + ' not found');
end;

end.
