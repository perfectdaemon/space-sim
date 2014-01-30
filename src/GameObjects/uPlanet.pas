unit uPlanet;

interface

uses
  Classes, Contnrs,
  GLScene, GLObjects, GLRenderContextInfo, VectorGeometry, GLTexture, GLMaterial,

  uGameObject, uGameObjects, uGLSceneObjects;

const
  //материалы для планет
  //C_JUPITER_MATNAME = 'Jupiter';
  C_PLANET_PATH = 'data\planets\';

type
  TdfPlanet = class(TdfGameObject)
  private
    FPlane: TGLPlane; //Издалека планета видна как плоскость, биллборд
    FSphere: TGLSphere; //Вблизи планета видна объемно
    FAddPosition: TAffineVector;
    procedure SetAddPosition(const Value: TAffineVector);
  protected
  public
    constructor CreateAsChild(aParentOwner: TGLBaseSceneObject); reintroduce;

    procedure Update(deltaTime: Double); override;
    property Plane: TGLPlane read FPlane write FPlane;

    property RelPosition: TAffineVector read FAddPosition write SetAddPosition;

    procedure LoadPlanetMaterial(aTextureName: String);
  end;

  TdfPlanetRenderer = class(TGLDirectOpenGL)
  private
    FtmpVec: TAffineVector;
    FPlanetList: TObjectList;
  public
    constructor CreateAsChild(aParentOwner: TGLBaseSceneObject); reintroduce;
    destructor Destroy; override;

    procedure RegisterPlanet(aPlanet: TdfPlanet);
    procedure UnregisterPlanet(aPlanet: TdfPlanet);

    procedure PlanetRender(Sender: TObject; var rci: TRenderContextInfo);

    procedure Update(deltaTime: Double);
  end;

implementation

{ TdfPlanet }

constructor TdfPlanet.CreateAsChild(aParentOwner: TGLBaseSceneObject);
begin
  inherited;
  FPlane := TGLPlane.CreateAsChild(Self);
  FPlane.Visible := False;
  FSphere := TGLSphere.CreateAsChild(Self);
  FSphere.Visible := False;
end;

procedure TdfPlanet.LoadPlanetMaterial(aTextureName: String);
var
  w, h: Integer;
begin
  if not Assigned(dfGLSceneObjects.MatLibrary.LibMaterialByName(aTextureName)) then
    with dfGLSceneObjects.MatLibrary.Materials.Add do
    begin
      Name := aTextureName;
      with FPlane.Material do
      begin
        Texture.Image.LoadFromFile(C_PLANET_PATH + aTextureName);
        w := Texture.Image.Width;
        h := Texture.Image.Height;
        Texture.Enabled := True;
        Texture.TextureMode := tmReplace;
        Texture.TextureWrap := twNone;
        BlendingMode := bmTransparency;
        MaterialOptions := [moIgnoreFog, moNoLighting];
        FrontProperties.Diffuse.SetColor(1,1,1);
      end;
    end
  else
    with dfGLSceneObjects.MatLibrary.LibMaterialByName(aTextureName).Material.Texture.Image do
    begin
      w := Width;
      h := Height;
    end;
  FPlane.Width := w;
  FPlane.Height := h;
  FPlane.Material.DepthProperties.DepthWrite := False;
end;

procedure TdfPlanet.SetAddPosition(const Value: TAffineVector);
begin
  FAddPosition := Value;
  Update(0);
end;

procedure TdfPlanet.Update(deltaTime: Double);
begin
  inherited;
  Position.AsVector := dfGameObjects.Player.AbsolutePosition;
  Position.AddScaledVector(1.0, FAddPosition);
  Direction.AsAffineVector := VectorSubtract(dfGameObjects.Player.Position.AsAffineVector,
    Position.AsAffineVector);
end;

{ TdfPlanetRenderer }

constructor TdfPlanetRenderer.CreateAsChild(aParentOwner: TGLBaseSceneObject);
begin
  inherited;
  FPlanetList := TObjectList.Create(False);
  OnRender := Self.PlanetRender;
  Blend := False;
end;

destructor TdfPlanetRenderer.Destroy;
begin
  FPlanetList.Free;
  inherited;
end;

procedure TdfPlanetRenderer.PlanetRender(Sender: TObject;
  var rci: TRenderContextInfo);
var
  i: Integer;
begin
  for i := 0 to FPlanetList.Count - 1 do
    with TdfPlanet(FPlanetList[i]) do
      Plane.Render(rci);
end;

procedure TdfPlanetRenderer.RegisterPlanet(aPlanet: TdfPlanet);
begin
  if FPlanetList.IndexOf(aPlanet) = -1 then
    FPlanetList.Add(aPlanet);
end;

procedure TdfPlanetRenderer.UnregisterPlanet(aPlanet: TdfPlanet);
begin
  if FPlanetList.IndexOf(aPlanet) <> -1 then
    FPlanetList.Remove(aPlanet);
end;

procedure TdfPlanetRenderer.Update(deltaTime: Double);
var
  i: Integer;
begin
  FTmpVec := dfGameObjects.Player.Up.AsAffineVector;
  FTmpVec[2] := 0;
  Self.Up.AsAffineVector := FTmpVec;
  for i := 0 to FPlanetList.Count - 1 do
    with TdfPlanet(FPlanetList[i]) do
      Update(deltaTime);
end;

end.
