unit uTarget;

interface

uses
  SysUtils, Classes,

  uGameObject, uSpacefighter,

  GLScene, GLObjects, GLHUDObjects, GLMaterial, GLTexture, GLWindowsFont,
  VectorGeometry, VectorTypes, GLCrossPlatform, GLFilePNG;

const
  C_HUD_PATH = 'data\hud\';
  C_DISTANCE_OFFSET_X = 0;
  C_DISTANCE_OFFSET_Y = -25;
  C_DISTANCE_SCALE = 0.5;
  C_LIFEBAR_OFFSET_X = 0;
  C_LIFEBAR_OFFSET_Y = 25;
  C_TARGETNAME_SCALE = 0.3;
  C_TARGETNAME_OFFSET_X = 0;
  C_TARGETNAME_OFFSET_Y = -45;
//  C_LIFEBAR_MAXWIDTH = 60;

type
  TdfTarget = class (TGLDummyCube)
  private
    FTarget: TdfGameObject; //Объект, на который все это нацелено
    FChaser: TdfGameObject; //Объект, который получает информацию, преследователь

    FFrame: TGLHUDSprite; //Рамка вокруг объекта
    FAim: TGLHUDSprite;   //Точка вероятного перехвата - куда стрелять
    FLifeBar: TGLHUDSprite; //Указатель "жизни" объекта
    FDirection: TGLHUDSprite; //Если объект вне экрана, то рисуется указатель на него
    FDistance: TGLHUDText; //Дистанция до объекта
    FTargetName: TGLHUDText;      //Название объекта

    FLifeBarBaseWidth: Single;

    FActive: Boolean;

    FDistanceValue: Single;

    intPoint, targetDir: TVector;
    targetDir2: TVector2f;
    wndCenterX, wndCenterY: Integer;

    FNoAim, FNoLifeBar: Boolean;

    function GetInterceptionPoint(q: Integer; posObject, posWeapon,
      velObject: TVector; velWeapon: Single): TVector;
    procedure SetActive(const Value: Boolean);
    procedure SetChaser(const Value: TdfGameObject);
    procedure SetTarget(const Value: TdfGameObject);

    procedure SetNeutralTarget();
    procedure SetAllyTarget();
    procedure SetEnemyTarget();
  public
    constructor CreateAsChild(aParentOwner: TGLBaseSceneObject); reintroduce;

    property Target: TdfGameObject read FTarget write SetTarget;
    property Chaser: TdfGameObject read FChaser write SetChaser;

    property Active: Boolean read FActive write SetActive;

//    property TimeToUpdateDistance: Single read FTime write FTime;

    property Frame: TGLHUDSprite read FFrame write FFrame;
    property Aim: TGLHUDSprite read FAim write FAim;
    property LifeBar: TGLHUDSprite read FLifeBar write FLifeBar;
    property Distance: TGLHUDText read FDistance write FDistance;
    property DistanceValue: Single read FDistanceValue;
    property DirectionToTarget: TGLHUDSprite read FDirection write FDirection;

    procedure AddMaterialToFrame(aTextureName: String);
    procedure AddMaterialToAim(aTextureName: String);
    procedure AddMaterialToLifeBar(aTextureName: String);
    procedure AddMaterialToDirection(aTextureName: String);
    procedure AddFontToTexts(aFont: TGLWindowsBitmapFont);

    procedure Update(deltaTime: Double);
  end;

implementation

uses
  uGLSceneObjects;

{ TdfTarget }

procedure TdfTarget.AddFontToTexts(aFont: TGLWindowsBitmapFont);
begin
  FDistance.BitmapFont := aFont;
  aFont.EnsureChars('0', '9');
  FTargetName.BitmapFont := aFont;
  aFont.EnsureChars('A', 'я');
end;

procedure TdfTarget.AddMaterialToAim(aTextureName: String);
var
  w, h: Single;
begin
  if not Assigned(dfGLSceneObjects.MatLibrary.LibMaterialByName(aTextureName)) then
    with dfGLSceneObjects.MatLibrary.Materials.Add do
    begin
      Name := aTextureName;
      with Material do
      begin
        Texture.Image.LoadFromFile(C_HUD_PATH + aTextureName);
        w := Texture.Image.Width;
        h := Texture.Image.Height;
        Texture.Enabled := True;
        Texture.TextureMode := tmModulate;
        Texture.TextureWrap := twNone;
        BlendingMode := bmTransparency;
        MaterialOptions := [moIgnoreFog, moNoLighting];
        FrontProperties.Diffuse.SetColor(1, 0, 0);
      end;
    end;
  FAim.Material.MaterialLibrary := dfGLSceneObjects.MatLibrary;
  FAim.Material.LibMaterialName := aTextureName;
  FAim.Width := w;
  FAim.Height := h;
end;

procedure TdfTarget.AddMaterialToDirection(aTextureName: String);
var
  w, h: Single;
begin
  if not Assigned(dfGLSceneObjects.MatLibrary.LibMaterialByName(aTextureName)) then
    with dfGLSceneObjects.MatLibrary.Materials.Add do
    begin
      Name := aTextureName;
      with Material do
      begin
        Texture.Image.LoadFromFile(C_HUD_PATH + aTextureName);
        w := Texture.Image.Width;
        h := Texture.Image.Height;
        Texture.Enabled := True;
        Texture.TextureMode := tmModulate;
        Texture.TextureWrap := twNone;
        BlendingMode := bmTransparency;
        MaterialOptions := [moIgnoreFog, moNoLighting];
        FrontProperties.Diffuse.SetColor(1, 0, 0, 0.7);
      end;
    end;
  FDirection.Material.MaterialLibrary := dfGLSceneObjects.MatLibrary;
  FDirection.Material.LibMaterialName := aTextureName;
  FDirection.Width := w;
  FDirection.Height := h;
end;

procedure TdfTarget.AddMaterialToFrame(aTextureName: String);
var
  w, h: Single;
begin
  if not Assigned(dfGLSceneObjects.MatLibrary.LibMaterialByName(aTextureName)) then
    with dfGLSceneObjects.MatLibrary.Materials.Add do
    begin
      Name := aTextureName;
      with Material do
      begin
        Texture.Image.LoadFromFile(C_HUD_PATH + aTextureName);
        w := Texture.Image.Width;
        h := Texture.Image.Height;
        Texture.Enabled := True;
        Texture.TextureMode := tmModulate;
        Texture.TextureWrap := twNone;
        BlendingMode := bmTransparency;
        MaterialOptions := [moIgnoreFog, moNoLighting];
        FrontProperties.Diffuse.SetColor(1, 0, 0);
      end;
    end;
  FFrame.Material.MaterialLibrary := dfGLSceneObjects.MatLibrary;
  FFrame.Material.LibMaterialName := aTextureName;
  FFrame.Width := w;
  FFrame.Height := h;
end;

procedure TdfTarget.AddMaterialToLifeBar(aTextureName: String);
var
  w, h: Single;
begin
  if not Assigned(dfGLSceneObjects.MatLibrary.LibMaterialByName(aTextureName)) then
    with dfGLSceneObjects.MatLibrary.Materials.Add do
    begin
      Name := aTextureName;
      with Material do
      begin
        Texture.Image.LoadFromFile(C_HUD_PATH + aTextureName);
        Texture.Enabled := True;
        w := Texture.Image.Width;
        h := Texture.Image.Height;
        Texture.TextureMode := tmModulate;
        Texture.TextureWrap := twNone;
        BlendingMode := bmTransparency;
        MaterialOptions := [moIgnoreFog, moNoLighting];
        FrontProperties.Diffuse.SetColor(1, 1, 1);
      end;
    end;
  FLifeBar.Material.MaterialLibrary := dfGLSceneObjects.MatLibrary;
  FLifeBar.Material.LibMaterialName := aTextureName;
  FLifeBar.Width := w;
  FLifeBar.Height := h;
  FLifeBarBaseWidth := FLifeBar.Width;
end;

constructor TdfTarget.CreateAsChild(aParentOwner: TGLBaseSceneObject);
begin
  inherited;
  FFrame := TGLHUDSprite.CreateAsChild(Self);
  FAim := TGLHUDSprite.CreateAsChild(Self);
  FLifeBar := TGLHUDSprite.CreateAsChild(Self);
  FDirection := TGLHUDSprite.CreateAsChild(Self);
  FDistance := TGLHUDText.CreateAsChild(Self);
  FTargetName := TGLHUDText.CreateAsChild(Self);

  wndCenterX := dfGLSceneObjects.Viewer.Width div 2;
  wndCenterY := dfGLSceneObjects.Viewer.Height div 2;
  with FDistance do
  begin
    Alignment := taCenter;
    Layout := tlCenter;
    ModulateColor.SetColor(1.0, 0.0, 0.0);
    Scale.Scale(C_DISTANCE_SCALE);
  end;

  with FTargetName do
  begin
    Alignment := taCenter;
    Layout := tlCenter;
    ModulateColor.SetColor(1.0, 1.0, 0.0);
    Scale.Scale(C_TARGETNAME_SCALE);
  end;
end;

function TdfTarget.GetInterceptionPoint(q: Integer; posObject, posWeapon,
  velObject: TVector; velWeapon: Single): TVector;
var
   invSpeed, t: Single;
   targEst: TVector;
begin
   invSpeed := 1 / (velWeapon + 0.1);
   t := FDistanceValue * invSpeed;
   if q >= 1 then
   begin
     targEst := VectorCombine(posObject, velObject, 1, t);
     t := VectorDistance(posWeapon, targEst) * invSpeed;
     if q >= 2 then
     begin
       targEst := VectorCombine(posObject, velObject, 1, t);
       t := VectorDistance(posWeapon, targEst) * invSpeed;
     end;
   end;
   Result := VectorCombine(posObject, velObject, 1, t);
end;

procedure TdfTarget.SetActive(const Value: Boolean);
begin
  FActive := Value;

  FFrame.Visible := Value;
  FDirection.Visible := Value;
  FDistance.Visible := Value;
  FAim.Visible := Value;
  FLifeBar.Visible := Value;
  FTargetName.Visible := Value;
end;

procedure TdfTarget.SetAllyTarget;
begin
  FFrame.Material.GetActualPrimaryMaterial.FrontProperties.Diffuse.SetColor(0,1,0);
  FDirection.Material.GetActualPrimaryMaterial.FrontProperties.Diffuse.SetColor(0,1,0);
  FDistance.ModulateColor.SetColor(0,1,0);
  FNoAim := True;
  FNoLifeBar := False;
end;

procedure TdfTarget.SetEnemyTarget;
begin
  FFrame.Material.GetActualPrimaryMaterial.FrontProperties.Diffuse.SetColor(1,0,0);
  FDirection.Material.GetActualPrimaryMaterial.FrontProperties.Diffuse.SetColor(1,0,0);
  FDistance.ModulateColor.SetColor(1,0,0);
  FNoAim := False;
  FNoLifeBar := False;
end;

procedure TdfTarget.SetNeutralTarget;
begin
  FFrame.Material.GetActualPrimaryMaterial.FrontProperties.Diffuse.SetColor(1,1,1);
  FDirection.Material.GetActualPrimaryMaterial.FrontProperties.Diffuse.SetColor(1,1,1);
  FDistance.ModulateColor.SetColor(1,0,0);
  FNoAim := True;
  FNoLifeBar := True;
end;

procedure TdfTarget.SetChaser(const Value: TdfGameObject);
begin
  FChaser := Value;
  Active := Assigned(FTarget) and Assigned (FChaser);
end;

procedure TdfTarget.SetTarget(const Value: TdfGameObject);
begin
  FTarget := Value;
  if Assigned(FTarget) then
  begin
    Active := Assigned(FChaser);
    FTargetName.Text := Value.ObjectName;
    case FTarget.GroupID of
      C_GROUP_OBJECT: SetNeutralTarget;
      C_GROUP_NEUTRALS: SetNeutralTarget;
      C_GROUP_ALLIES: SetAllyTarget;
      C_GROUP_ENEMIES: SetEnemyTarget;
    end;
  end;
end;

procedure TdfTarget.Update(deltaTime: Double);

  function IsValueBetween(aValue, aMin, aMax: Single): Boolean;
  begin
    Result := (aValue > aMin) and (aValue < aMax);
  end;

begin
  if FActive and Assigned(FTarget) and Assigned(FChaser) then
  begin
    {Рамка}
    FFrame.Position.AsVector :=
      dfGLSceneObjects.Viewer.Buffer.WorldToScreen(FTarget.AbsolutePosition);
    FFrame.Position.Y := dfGLSceneObjects.Viewer.Height - FFrame.Position.Y;

    {Дистанция}
    FDistanceValue := VectorDistance(FChaser.AbsolutePosition, FTarget.AbsolutePosition);
    FDistance.Text := FloatToStrF(FDistanceValue, ffGeneral, 4, 3);
    FDistance.Position := FFrame.Position;
    with FDistance.Position do
    begin
      X := X + C_DISTANCE_OFFSET_X;
      Y := Y + C_DISTANCE_OFFSET_Y;
    end;

    {Имя объекта}
    FTargetName.Position := FFrame.Position;
    with FTargetName.Position do
    begin
      X := X + C_TARGETNAME_OFFSET_X;
      Y := Y + C_TARGETNAME_OFFSET_Y;
    end;

    {Лайфбар}
    if not FNoLifeBar then
    begin
      FLifeBar.Visible := True;
      FLifeBar.Position := FFrame.Position;
      with FLifeBar.Position do
      begin
        X := X + C_LIFEBAR_OFFSET_X;
        Y := Y + C_LIFEBAR_OFFSET_Y;
      end;
      FLifeBar.Width := FLifeBarBaseWidth * FTarget.Health / FTarget.MaxHealth;
    end
    else
      FLifeBar.Visible := False;

    {Прицел}
    if not FNoAim then
    begin
      FAim.Visible := FDistanceValue < TdfSpaceFighter(FChaser).MaxWeaponDistance;
      intPoint := GetInterceptionPoint(2, FTarget.AbsolutePosition,
        FChaser.AbsolutePosition, VectorScale(FTarget.AbsoluteDirection, FTarget.Speed),
          TdfSpaceFighter(FChaser).AverageWeaponSpeed);
      FAim.Position.AsVector := dfGLSceneObjects.Viewer.Buffer.WorldToScreen(intPoint);
      FAim.Position.Y := dfGLSceneObjects.Viewer.Height - FAim.Position.Y;
    end
    else
      FAim.Visible := False;

    {Направление}
    FDirection.Visible := True;
    targetDir := VectorSubtract(FTarget.AbsolutePosition, dfGLSceneObjects.Camera.AbsolutePosition);
    NormalizeVector(targetDir);
    if VectorDotProduct(dfGLSceneObjects.Camera.AbsoluteDirection, targetDir) > 0 then
    begin
      if IsValueBetween(FFrame.Position.X, 0, dfGLSceneObjects.Viewer.Width)
        and IsValueBetween(FFrame.Position.Y, 0, dfGLSceneObjects.Viewer.Height) then
        FDirection.Visible := False
      else
      begin
        FDirection.Position.X := ClampValue(FFrame.Position.X,
          FDirection.Width / 2, dfGLSceneObjects.Viewer.Width - FDirection.Width / 2);
        FDirection.Position.Y := ClampValue(FFrame.Position.Y,
          FDirection.Height / 2, dfGLSceneObjects.Viewer.Height - FDirection.Height / 2);
      end;
    end
    else
    begin
      targetDir2[0] := wndCenterX - FFrame.Position.X;
      targetDir2[1] := wndCenterY - FFrame.Position.Y;
      NormalizeVector(targetDir2);
      ScaleVector(targetDir2, 1000);
      FDirection.Position.X := ClampValue(targetDir2[0],
        FDirection.Width / 2, dfGLSceneObjects.Viewer.Width - FDirection.Width / 2);
      FDirection.Position.Y := ClampValue(targetDir2[1],
        FDirection.Height / 2, dfGLSceneObjects.Viewer.Height - FDirection.Height / 2);
    end;
  end
  else
    if not Assigned(FTarget) then
      Active := False;
end;

end.
