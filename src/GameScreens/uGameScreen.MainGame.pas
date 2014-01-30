{Главный экран - игровой, "в нем" пользователь играет}
unit uGameScreen.MainGame;

interface

uses
  SysUtils, Windows, Contnrs,

  GLScene, GLObjects, GLWin32Viewer, VectorGeometry, VectorTypes,
  GLVectorFileObjects, GLFile3DS, GLFilePNG, GLMaterial, GLTexture,
  GLHUDObjects, GLRenderContextInfo, GLParticleFX, GLKeyboard,
  GLSkyDome,

  uGameScreen, uSpacefighter, uFighterControl.User, uDebugInfo, uAsteroidField,
  uSimplePhysics, uBulletAccum, uGameObject, uTarget, uFonts, uBoomAccum,
  uTutorial, uPlanet;

const
  C_SCREEN_NAME = 'Main Game';
  C_FADEIN_TIME = 2.5;

type
  TdfMainGame = class (TdfGameScreen)
  private
    FRoot: TGLDummyCube;
    FHUDDummy: TGLDummyCube;
    FBlankBack: TGLHUDSprite;

    FMatLib: TGLMaterialLibrary;
    FViewerW, FViewerH: Integer;

    Ft: Double;

    FInGameMenu, FAlpha: TdfGameScreen;

    FSkyDome: TGLSkyDome;

    FPlayer: TdfSpaceFighter;

    FGameObjects: TObjectList;
    FUserControl: TdfUserControl;
    FAsteroidField: TdfAsteroidField;
    FJupiterPlanet: TdfPlanet;
    FPlanetRenderer: TdfPlanetRenderer;
    FParticleRenderer: TGLParticleFXRenderer;

    FBooms, FBigBooms: TdfBoomAccum;
  {+debug}
    FTutorial: TdfTutorialMission;
//    FPlayerPosInd: Integer; //индекс строки дебага с позицией игрока
    procedure OnCollision(o1, o2: TdfPhys);
    procedure OnGameObjectNotify(aObj: TdfGameObject;
      aAction: TdfGameObjectNotifyAction);
    procedure OnMissionEnd();
  {-debug}
    procedure FadeInComplete();
    procedure FadeOutComplete();
  protected
    procedure FadeIn(deltaTime: Double); override;
    procedure FadeOut(deltaTime: Double); override;
    procedure SetStatus(const aStatus: TdfGameSceneStatus); override;
  public
    constructor Create(); override;
    destructor Destroy; override;

    procedure Load(); override;
    procedure Unload(); override;

    procedure Update(deltaTime: Double; X, Y: Integer); override;

    procedure SetGameScreens(aInGameMenu, aAlpha: TdfGameScreen);
  end;

implementation

uses
  uGLSceneObjects, uGameObjects;

{ TdfMainGameScreen }

constructor TdfMainGame.Create();
var
  colorMin, colorMax: TVector3b;
  props: TdfBoomProperties;
begin
  inherited;
  FName := C_SCREEN_NAME;

  FRoot := TGLDummyCube.CreateAsChild(dfGLSceneObjects.Scene.Objects);
  FRoot.Visible := False;

  FViewerW := dfGLSceneObjects.Viewer.Width;
  FViewerH := dfGLSceneObjects.Viewer.Height;
  FMatLib := dfGLSceneObjects.MatLibrary;

  FGameObjects := TObjectList.Create(False);

  FHUDDummy := TGLDummyCube.CreateAsChild(FRoot);

  colorMin[0] := 128;
  colorMin[1] := 128;
  colorMin[2] := 128;
  colorMax[0] := 255;
  colorMax[1] := 255;
  colorMax[2] := 255;
  FSkyDome := TGLSkyDome.CreateAsChild(FRoot);
  FSkyDome.Bands.Clear;
  FSkyDome.Stars.AddRandomStars(2000, colorMin, colorMax, 1.0, 10.0);

  FParticleRenderer := TGLParticleFXRenderer.CreateAsChild(FRoot);
  FParticleRenderer.Visible := False;
  dfGLSceneObjects.EnginesFX[0].Renderer := FParticleRenderer;
  dfGLSceneObjects.BoomFX[0].Renderer := FParticleRenderer;
  dfGLSceneObjects.BoomFX[1].Renderer := FParticleRenderer;

  FPlanetRenderer := TdfPlanetRenderer.CreateAsChild(FRoot);

  dfPhysics := TdfSimplePhysics.Create();
  dfPhysics.OnCollision := OnCollision;

  FPlayer := TdfSpaceFighter.CreateAsChild(FRoot);
  FPlayer.LoadFromFile('sfBuran2.ini');
  FPlayer.GroupID := C_GROUP_ALLIES;
  FPlayer.Position.SetPoint(0, 0, 1);
  FUserControl := TdfUserControl.Create(FPlayer, FHUDDummy);
  FUserControl.Enabled := True;

  dfGameObjects.Player := FPlayer;
  dfGameObjects.UserControl := FUserControl;
  dfGameObjects.GameObjects := FGameObjects;

//  FPlayerPosInd := dfDebugInfo.AddNewString('Позиция игрока');
//  dfDebugInfo.HideString(FPlayerPosInd);

  FAsteroidField := TdfAsteroidField.CreateAsChild(FRoot);
  FAsteroidField.SetMatLib(FMatLib);
  FAsteroidField.LoadFromFile('af1.ini', True);

//Юпитер
  FJupiterPlanet := TdfPlanet.CreateAsChild(FRoot);
  FJupiterPlanet.RelPosition := AffineVectorMake(0, 0, 700);
  FJupiterPlanet.LoadPlanetMaterial('jupiter.png');
  FPlanetRenderer.RegisterPlanet(FJupiterPlanet);

  FBooms := TdfBoomAccum.CreateAsChild(FRoot);
  with props do
  begin
    sPositionDispersion := 1.2;
    sParticleInterval := 0.01;
    sVelocityDispersion := 10.2;
  end;
  FBooms.Init(10, dfGLSceneObjects.BoomFX[0], props);

  FBigBooms := TdfBoomAccum.CreateAsChild(FRoot);
  with props do
  begin
    sPositionDispersion := 2.5;
    sParticleInterval := 0.001;
    sVelocityDispersion := 20.2;
  end;
  FBigBooms.Init(5, dfGLSceneObjects.BoomFX[1], props);
  dfGameObjects.BigBoom := FBigBooms;

  FHUDDummy.MoveLast;
  Ft := 0;
  FInGameMenu := nil;

  FBlankBack := TGLHUDSprite.CreateAsChild(FRoot);
  FBlankBack.SetSize(FViewerW, FViewerH);
  FBlankBack.Position.SetPoint(FViewerW / 2, FViewerH / 2, 0.5);
  with FBlankBack.Material do
  begin
    Texture.Enabled := False;
    BlendingMode := bmTransparency;
    MaterialOptions := [moIgnoreFog, moNoLighting];
    FrontProperties.Diffuse.SetColor(0, 0, 0, 1);
  end;
  FBlankBack.MoveFirst;

  FTutorial := TdfTutorialMission.Create(FRoot, FHUDDummy, GetFont(C_FONT_1));
  FTutorial.OnGameObjectNotify := Self.OnGameObjectNotify;
  FTutorial.OnMissionEnd := Self.OnMissionEnd;
end;

destructor TdfMainGame.Destroy;
begin
  FTutorial.Free;
  FUserControl.Free;
  FGameObjects.Free;
  FRoot.Free;
  dfPhysics.Free;
  inherited;
end;

procedure TdfMainGame.FadeIn(deltaTime: Double);
begin
  Ft := Ft + deltaTime;
  FBlankBack.Material.FrontProperties.Diffuse.Alpha := 1 - Ft / C_FADEIN_TIME;
  if Ft >= C_FADEIN_TIME then
    inherited;
end;

procedure TdfMainGame.FadeInComplete;
begin
  //*
  FBlankBack.Visible := False;
  FTutorial.Start;
end;

procedure TdfMainGame.FadeOut(deltaTime: Double);
begin
  inherited;
end;

procedure TdfMainGame.FadeOutComplete;
begin
  FRoot.Visible := False;
  Unload();
end;

procedure TdfMainGame.Load;
begin
  inherited;
  if FLoaded then
    Exit;

  dfDebugInfo.Visible := True;
  FPlayer.ResetParams();
  FUserControl.ResetParams();

  FParticleRenderer.MoveLast;
  FHUDDummy.MoveLast;
  FParticleRenderer.Visible := True;

  FLoaded := True;
end;

procedure TdfMainGame.OnCollision(o1, o2: TdfPhys);

  procedure BulletVSDestroyable(aBullet, aDestr: TdfPhys);
  var
    bul: TdfBullet;
  begin
    bul :=  TdfBullet(aBullet.Obj);
    if bul.Used then
    begin
      TdfGameObject(aDestr.Obj).TakeDamage(bul.Damage);
      FBooms.SetBoom(AffineVectorMake(bul.AbsolutePosition), 0.3);
      bul.Used := False;
    end;
  end;

  procedure BulletVSAsteroid(aBullet, aAster: TdfPhys);
  var
    bul: TdfBullet;
  begin
    bul :=  TdfBullet(aBullet.Obj);
    if bul.Used then
    begin
      bul.Used := False;
      FBooms.SetBoom(AffineVectorMake(bul.AbsolutePosition), 0.3);
    end;
  end;

  procedure DestrVSDestr(aDestr1, aDestr2: TdfPhys);
  begin
    dfPhysics.Bounce(aDestr1, aDestr2);
    dfPhysics.Bounce(aDestr2, aDestr1);
    //В альфа-версии не отнимаем здоровье за столкновение
    //Так как все сделано сферами и большинство столкновений неочевидно
  end;

  procedure DestrVSAsteroid(aDestr, aAster: TdfPhys);
  begin
    dfPhysics.Bounce(aDestr, aAster);
    //В альфа-версии не отнимаем здоровье за столкновение
    //Так как все сделано сферами и большинство столкновений неочевидно
  end;

begin
  case o1.UserType of

    C_PHYS_BULLET:
      case o2.UserType of
        C_PHYS_BULLET: Exit;
        C_PHYS_DESTROYABLE: BulletVSDestroyable(o1, o2);
        C_PHYS_INVINCIBLE: Exit;
        C_PHYS_ASTEROID: BulletVSAsteroid(o1, o2);
      end;

    C_PHYS_DESTROYABLE:
      case o2.UserType of
        C_PHYS_BULLET: BulletVSDestroyable(o2, o1); //Удаляем пулю o2, у первого объекта отнимаем жизнь
        C_PHYS_DESTROYABLE: DestrVSDestr(o1, o2); //Отталкиваемся, отнимаем жизни o1, o2
        C_PHYS_INVINCIBLE: Exit; //Ничего
        C_PHYS_ASTEROID: DestrVSAsteroid(o1, o2);   //Отталкиваемся, отнимаем жизнь у o1
      end;

    C_PHYS_INVINCIBLE: Exit;

    C_PHYS_ASTEROID:
      case o2.UserType of
        C_PHYS_BULLET: BulletVSAsteroid(o2, o1); //Уничтожаем пулю
        C_PHYS_DESTROYABLE: DestrVSAsteroid(o2, o1); //отталкиваем о2, отнимаем жизнь
        C_PHYS_INVINCIBLE: Exit; //Ничего
        C_PHYS_ASTEROID: Exit;   //Ничего
      end;
  end;
end;

procedure TdfMainGame.OnGameObjectNotify(aObj: TdfGameObject;
  aAction: TdfGameObjectNotifyAction);
begin
  case aAction of
    naAdded: FPlayer.ObjectsAround.Add(aObj);
    naRemoved: FPlayer.ObjectsAround.Remove(aObj);
    naChanged: ;
  end;
end;

procedure TdfMainGame.OnMissionEnd;
begin
  OnNotify(FAlpha, naShowModal);
end;

procedure TdfMainGame.SetGameScreens(aInGameMenu, aAlpha: TdfGameScreen);
begin
  FInGameMenu := aInGameMenu;
  FAlpha := aAlpha;
end;

procedure TdfMainGame.SetStatus(const aStatus: TdfGameSceneStatus);
begin
  inherited;
  case aStatus of
    gssNone           : Exit;
    gssReady          : Exit;
    gssFadeIn         :
    begin
      Load();
      FRoot.Visible := True;
      FBlankBack.Visible := True;
      Ft := 0;
    end;
    gssFadeInComplete : FadeInComplete();
    gssFadeOut        : Ft := 0;
    gssFadeOutComplete: FadeOutComplete();
    gssPaused         : Exit;
  end;
end;

procedure TdfMainGame.Unload;
var
  i: Integer;
begin
  inherited;
  if not FLoaded then
    Exit;

//  dfDebugInfo.Visible := False;
  FTutorial.Stop;
  FParticleRenderer.Visible := False;
  for i := 0 to FPlayer.WeaponsCount - 1 do
    FPlayer.Weapons[i].ReleaseAllBullets();
  //*

  FLoaded := False;
end;

procedure TdfMainGame.Update(deltaTime: Double; X, Y: Integer);
begin
  inherited;
  case FStatus of
    gssNone: Exit;
    gssFadeIn: FadeIn(deltaTime);
    gssFadeInComplete: Exit;
    gssFadeOut: FadeOut(deltaTime);
    gssFadeOutComplete: Exit;
    gssPaused: Exit;

    gssReady:
    begin
      dfPhysics.Update(deltaTime);

      FTutorial.Update(deltaTime);
//      dfDebugInfo.UpdateParam(FPlayerPosInd, FPlayer.Position.AsVector);
      FPlayer.Update(deltaTime);
      FUserControl.Update(deltaTime, X, Y);

      FPlanetRenderer.Update(deltaTime);

      FAsteroidField.UpdateField(deltaTime);

      FBooms.Update(deltaTime);
      FBigBooms.Update(deltaTime);

      if IsKeyDown(VK_ESCAPE) then
        OnNotify(FInGameMenu, naShowModal);
    end;
  end;
end;

end.

