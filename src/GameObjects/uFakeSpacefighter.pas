unit uFakeSpacefighter;

interface

uses
  GLScene, GLMaterial, GLTexture,

  uSpacefighter, uSimplePhysics;

type
  TdfFakeSpaceFighter = class(TdfSpaceFighter)
  protected
    procedure SetFighterMaterial(texturePath: String); override;
  public
    constructor CreateAsChild(aParent: TGLBaseSceneObject); override;
  end;

implementation

{ TdfFakeSpaceFighter }

constructor TdfFakeSpaceFighter.CreateAsChild(aParent: TGLBaseSceneObject);
begin
  inherited;
  FObjName := 'Голографическая мишень';
end;

procedure TdfFakeSpaceFighter.SetFighterMaterial(texturePath: String);
begin
  inherited;
  with FFighter.Material.GetActualPrimaryMaterial do
  begin
    BlendingMode := bmTransparency;
    FrontProperties.Diffuse.SetColor(0.5, 0.5, 1, 0.5);
  end;
end;

end.
