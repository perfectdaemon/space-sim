unit uMain;

interface

uses
  uGame, uGameScreen, uGameScreen.MainMenu, uGameScreen.Credits, uGameScreen.NewGame,
  uGameScreen.MainGame, uGameScreen.InGameMenu, uGameScreen.AlphaVersion, uDebugInfo,

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs;

type
  TfrmMain = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure FormFocus(var Msg : TMessage); message WM_ACTIVATE;
  end;

var
  frmMain: TfrmMain;
  Game: TdfGame;

  //Game screens
  MainMenu: TdfMainMenu;
  Credits: TdfCredits;
  NewGame: TdfNewGame;
  MainGame: TdfMainGame;
  InGameMenu: TdfInGameMenu;
  Alpha: TdfAlphaVersion;

implementation

{$R *.dfm}

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Game.Stop();
  Game.Free;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  //Создаем объект игры
  Game := TdfGame.Create(Self);

  //Создаем игровые экраны
  MainMenu := TdfMainMenu(Game.AddGameScene(TdfMainMenu));
  Credits := TdfCredits(Game.AddGameScene(TdfCredits));
  NewGame := TdfNewGame(Game.AddGameScene(TdfNewGame));
  MainGame := TdfMainGame(Game.AddGameScene(TdfMainGame));
  InGameMenu := TdfInGameMenu(Game.AddGameScene(TdfInGameMenu));
  Alpha := TdfAlphaVersion(Game.AddGameScene(TdfAlphaVersion));

  //Строим необходимые для них ассоциации
  MainMenu.SetGameScreens(NewGame, Credits);
  Credits.SetGameScreens(MainMenu);
  NewGame.SetGameScreens(MainGame);
  MainGame.SetGameScreens(InGameMenu, Alpha);
  InGameMenu.SetGameScreens(MainGame, MainMenu);
  Alpha.SetGameScreens(MainGame, MainMenu);

  //Устанавливаем активный экран
  Game.ActiveScreen := MainMenu;
//  Game.ActiveScreen := MainGame;
//  Game.ActiveScreen := NewGame;

  //Запускаем игру!
  Game.Start;
end;

procedure TfrmMain.FormFocus(var Msg: TMessage);
begin
  if (Msg.WParam = WA_INACTIVE) and (Game.ActiveScreen = MainGame) then
    Game.NotifyGameScenes(InGameMenu, naShowModal);
  inherited;
end;

end.
