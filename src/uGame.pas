

unit uGame;

interface

uses
  Classes, Controls, Windows, SysUtils, Contnrs, Forms, IniFiles,

  GLScene, GLWin32Viewer, GLCadencer, GLObjects, GLRenderContextInfo,
  GLCrossPlatform, GLMaterial, GLParticleFX, GLPerlinPFX, GLContext,

  uGameScreen, uLog;

const
  C_WAIT_BEFORE_EXIT = 0.3;

  C_SYSTEM_FILE = 'data\system.ini';

  C_MAIN_SECTION   = 'Main';
  C_CAMERA_SECTION = 'Camera';
  C_BUFFER_SECTION = 'Buffer';

type
  TdfGame = class
  private
    FOwner: TComponent;

    FScene: TGLScene;
    FViewer: TGLSceneViewer;
    FCadencer: TGLCadencer;
    FMatLib: TGLMaterialLibrary;
    FEngineFX, FBoomFX, FBigBoomFX: TGLPerlinPFXManager;

    FCamera: TGLCamera;
    FLight: TGLLightSource;
    FGameScreens: TObjectList;
    FActiveScreen: TdfGameScreen;

    FSubject: TdfGameScreen;
    FAction: TdfNotifyAction;

    FmX, FmY: Integer; //позиция курсора мыши

    FWait: Double;

    FFPSInd: Integer;

    t: Double;

//    FGLSceneInfo: TdfGLSceneInfo;
    procedure MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Progress(Sender: TObject; const deltaTime, newTime: Double);
    function GetActiveScene: TdfGameScreen;
    procedure SetActiveScene(const aScene: TdfGameScreen);
  public
    constructor Create(aOwner: TComponent); virtual;
    destructor Destroy; override;

    function AddGameScene(aGameSceneClass: TdfGameSceneClass): TdfGameScreen;


    procedure NotifyGameScenes(Subject: TdfGameScreen; Action: TdfNotifyAction);

    property ActiveScreen: TdfGameScreen read GetActiveScene write SetActiveScene;

    procedure Start;
    procedure Stop;
  end;

implementation

uses
  uTweener, uFonts, uDebugInfo, uGLSceneObjects,
  VectorGeometry;

{ TdfGame }

procedure TdfGame.Progress(Sender: TObject; const deltaTime, newTime: Double);
var
  i: Integer;
begin
  FViewer.Invalidate;
  Tweener.Update(deltaTime);
  t := t + deltaTime;
  dfDebugInfo.UpdateParam(FFPSInd, FViewer.FramesPerSecond);
  if t >= 1 then
  begin
    FViewer.ResetPerformanceMonitor;
    t := 0;
  end;
  for i := 0 to FGameScreens.Count - 1 do
    TdfGameScreen(FGameScreens[i]).Update(deltaTime, FmX, FmY);

  if FActiveScreen.Status = gssFadeInComplete then
  begin
    logWriteMessage('TdfGame: "' + FActiveScreen.Name + '" status gssFadeInComplete');
    FActiveScreen.Status := gssReady;
  end;

  if Assigned(FSubject) then
    case FAction of
      naNone: Exit;

      naSwitchTo:
        if (FActiveScreen.Status = gssFadeOutComplete) or
           (FActiveScreen.Status = gssNone) then
        begin
          logWriteMessage('TdfGame: "' + FActiveScreen.Name + '" status gssFadeOutComplete');
          FActiveScreen.Status := gssNone;
          FActiveScreen.Unload;
          FSubject.Load();
          if FSubject.Status = gssPaused then
            FSubject.Status := gssReady
          else
            FSubject.Status := gssFadeIn;
          FActiveScreen := FSubject;
          FSubject := nil;
        end;

      naSwitchToQ:
      begin
        FActiveScreen.Status := gssFadeOutComplete;
        FActiveScreen.Unload;
        FSubject.Load;
        FSubject.Status := gssReady;
        FActiveScreen := FSubject;
        FSubject := nil;
      end;

      naPreload: Exit;


      //Показываем Subject поверх текущей ActiveScene
      naShowModal:
      begin
        FActiveScreen.Status := gssPaused;
        FSubject.Load();
        FSubject.Status := gssFadeIn;
        FActiveScreen := FSubject;
        FSubject := nil;
      end;
//      else
//      begin
//        FSubject.Update(deltaTime, FmX, FmY);
//      end;
    end;

  if FAction = naQuitGame then
  begin
    FWait := FWait + deltaTime;
    if FWait >= C_WAIT_BEFORE_EXIT then
    begin
      PostQuitMessage(0);
      Stop();
      Free;
    end;
  end;
end;


function TdfGame.GetActiveScene: TdfGameScreen;
begin
  if Assigned(FActiveScreen) then
    Result := FActiveScreen
  else
  begin
    Result := nil;
    logWriteError('TdfGame: GetActiveScene - nil at FActiveScene!');
  end;
end;

procedure TdfGame.MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  FmX := X;
  FmY := Y;
end;

procedure TdfGame.SetActiveScene(const aScene: TdfGameScreen);
begin
  if Assigned(aScene) then
    if not Assigned(FActiveScreen) then
    begin
      FActiveScreen := aScene;
      FActiveScreen.Load();
      FActiveScreen.Status := gssFadeIn;
    end
    else
      if aScene <> FActiveScreen then
        NotifyGameScenes(aScene, naSwitchTo);
end;

procedure TdfGame.Start;
begin
//  dfGLSceneObjects.HUDDummy.MoveLast;
  dfDebugInfo.MoveLast;
  FCadencer.Enabled := True;
end;

procedure TdfGame.Stop;
begin
  FCadencer.Enabled := False;
end;

function TdfGame.AddGameScene(aGameSceneClass: TdfGameSceneClass): TdfGameScreen;
begin
  Result := aGameSceneClass.Create();
  Result.OnNotify := Self.NotifyGameScenes;
  logWriteMessage('TdfGame: Added "' + Result.Name + '" game scene with index: ' + IntToStr(FGameScreens.Add(Result)));
end;

constructor TdfGame.Create(aOwner: TComponent);
var
  ind: Integer;
  Ini: TIniFile;
begin
  inherited Create();
  if FileExists(C_SYSTEM_FILE) then
  begin
    Ini := TIniFile.Create(C_SYSTEM_FILE);
    FOwner := aOwner;

    FScene := TGLScene.Create(FOwner);
    FScene.VisibilityCulling := vcNone;
//    FScene.ObjectsSorting := osInherited;
//    FScene.ObjectsSorting :=

    FCadencer := TGLCadencer.Create(FOwner);
    FCadencer.Enabled := False;
    FCadencer.OnProgress := Self.Progress;
    FCadencer.Scene := FScene;

    FCamera := TGLCamera.CreateAsChild(FScene.Objects);
    FCamera.DepthOfView := Ini.ReadFloat(C_CAMERA_SECTION, 'DepthOfView', 1000);
    FCamera.Direction.SetVector(0,0,1);
    FCamera.FocalLength := 90;

    FViewer := TGLSceneViewer.Create(FOwner);
    FViewer.Buffer.DepthPrecision := dp24bits;
    FViewer.Camera := FCamera;
    FViewer.Align := alClient;
    FViewer.Parent := TWinControl(aOwner);
    FViewer.OnMouseMove := MouseMove;
    FViewer.Buffer.AntiAliasing := aaNone;

    FMatLib := TGLMaterialLibrary.Create(FOwner);

    FEngineFX := TGLPerlinPFXManager.Create(FOwner);
    FEngineFX.Cadencer := FCadencer;

    {+debug}
    FEngineFX.ColorInner.SetColor(0.5, 0.5, 0.9, 1.0);
    FEngineFX.ColorOuter.SetColor(0.1, 0.1, 0.8, 0.5);
    FEngineFX.ParticleSize := 2.1;
    with FEngineFX.LifeColors.Add do
    begin
      LifeTime := 0.3;
    end;
    FBoomFX := TGLPerlinPFXManager.Create(FOwner);
    FBoomFX.Cadencer := FCadencer;
    FBoomFX.ColorInner.SetColor(0.9, 0.5, 0.5, 1.0);
    FBoomFX.ColorOuter.SetColor(0.7, 0.5, 0.5, 0.5);
    FBoomFX.ParticleSize := 1.4;

    with FBoomFX.LifeColors.Add do
    begin
      LifeTime := 0.4;
    end;

    FBigBoomFX := TGLPerlinPFXManager.Create(FOwner);
    FBigBoomFX.Cadencer := FCadencer;
    FBigBoomFX.ColorInner.SetColor(0.9, 0.7, 0.7, 1.0);
    FBigBoomFX.ColorOuter.SetColor(0.8, 0.4, 0.4, 0.5);
    FBigBoomFX.ParticleSize := 5.5;
    with FBigBoomFX.LifeColors.Add do
    begin
      LifeTime := 1.0;
    end;
    {-debug}

    FGameScreens :=TObjectList.Create(True);
    FActiveScreen := nil;
    FSubject := nil;

    FLight := TGLLightSource.CreateAsChild(FCamera);
    FLight.Diffuse.SetColor(1, 1, 1);

    FViewer.Buffer.BackgroundColor := RGB(
      Ini.ReadInteger(C_BUFFER_SECTION, 'backR', 0),
      Ini.ReadInteger(C_BUFFER_SECTION, 'backG', 0),
      Ini.ReadInteger(C_BUFFER_SECTION, 'backB', 0));

    {+debug}
    ind := uFonts.AddFont(aOwner, C_FONT_1);
    with GetFont(ind) do
      Font.Size := 24;

    with GetFont(AddFont(aOwner, C_FONT_2)) do
      Font.Size := 10;

    {-debug}

    //Заполняем синглтоны
    with dfGLSceneObjects do
    begin
      Scene := FScene;
      Viewer := FViewer;
      Cadencer := FCadencer;
      MatLibrary := FMatLib;
      EnginesFX[0] := FEngineFX;
      BoomFX[0] := FBoomFX;
      BoomFX[1] := FBigBoomFX;
      Camera := FCamera;
    end;

    dfDebugInfo := TdfDebugInfo.CreateAsChild(FScene.Objects);
    dfDebugInfo.Position.Z := -0.5;
    dfDebugInfo.BitmapFont := GetFont(C_FONT_2);
    dfDebugInfo.Layout := tlTop;
    dfDebugInfo.Alignment := taLeftJustify;
    dfDebugInfo.Visible := Ini.ReadBool(C_MAIN_SECTION, 'Debug', False);
    FFPSInd := dfDebugInfo.AddNewString('FPS');

    Ini.Free;
  end
  else
  begin
    logWriteError('TdfGame: File ' + C_SYSTEM_FILE + ' not founded', True, True, True);
    Free;
  end;
end;

destructor TdfGame.Destroy;
begin
  //Так как компоненты GLScene, GLViewer и GLCadencer были созданы с родителем
  //То их освободит родитель, в нашем случае - сама форма
  FGameScreens.Free;
  inherited;
end;

procedure TdfGame.NotifyGameScenes(Subject: TdfGameScreen; Action: TdfNotifyAction);
begin
  if FAction = naQuitGame then
    Exit;
  FSubject := Subject;
  FAction := Action;

  case Action of
    naSwitchTo:
    begin
//      logWriteMessage('TdfGame: Notified action: switch to "' + Subject.Name + '" game scene');
      if Assigned(FActiveScreen) then
        FActiveScreen.Status := gssFadeOut
      else
      begin
        FSubject.Status := gssFadeIn;
      end;
    end;
    naSwitchToQ: Exit;
    naPreload: Subject.Load();
    naQuitGame: FWait := 0;
    naShowModal: Exit;
  end;
end;

end.
