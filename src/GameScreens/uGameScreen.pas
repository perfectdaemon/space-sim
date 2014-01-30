{��������� GameScreen - ��������� ������������� �����, ���������� �������� � ������.
 ������ �����, ��� ������� ����� ��� �������� ����, ����� ���� � ��������� �� �������
 ������ �������� (����, ���� ����) ����������� � �������� ������}
unit uGameScreen;

interface

uses
  GLScene, GLWin32Viewer, GLMaterial, GLParticleFX;

type
  TdfGameScreen = class;

  //��������, ������� ����� ����� �������� ������ TdfGame
  //��� ��������, �������������, ������������� ��� ������ FadeIn � FadeOut,
  //�������� ������, ������������, ����� �� ����
  TdfNotifyAction = (naNone, naSwitchTo, naSwitchToQ, naShowModal, naPreload, naQuitGame);

  //��������� �����������. ���������� � ���, ��� ����� �������
  // � Subject �������� Action. ���������� �����, �.�. Sender �������� � TdfGame-�
  TdfNotifyProc = procedure(Subject: TdfGameScreen; Action: TdfNotifyAction) of object;

  //������ �������� ������
  //gssNone - ��� �������. �� update-���� � �� ������������
  //gssReady - �������� �� ������ ������, Update �����������, ������� �� ��������
  //gssFadeIn - ���� ������� ������ (���������)
  //gssFadeInComplete - ������� ��������� ��������, ������������� ������������� � gssReady
  //gssFadeOut - ���� ������� ��������� � ������
  //gssFadeOutComplete - ������� ������� ��������, ������������� ������������� � gssNone
  //gssPaused - �����, ����� ���������� ��������������, �� �� Update-����
  TdfGameSceneStatus = (gssNone, gssReady, gssFadeIn, gssFadeInComplete,
                        gssFadeOut, gssFadeOutComplete, gssPaused);

  {� �������� ��������:
   Create - �������� ������, ������� ��������� ���� ��� � ����� ������ � ������
            �� ���������� ���� ����

   Load   - ���������������� ��������� ��� ��������� ������� ������

   �������������: ��������� ��� GL-������� � Create, �� �� �������� �� �
   ������-���� GLScene.Objects �����, � ������ ��� ��� Load. ����� ��� Load
   ������� ���������� ������� ������}
  TdfGameScreen = class
  private
  protected
    FLoaded: Boolean;
    FName: String;
    FStatus: TdfGameSceneStatus;
    FNotifyProc: TdfNotifyProc;

    procedure FadeIn(deltaTime: Double); virtual;
    procedure FadeOut(deltaTime: Double); virtual;
    procedure SetName(const Value: String); virtual;

    function GetStatus: TdfGameSceneStatus; virtual;
    procedure SetStatus(const aStatus: TdfGameSceneStatus); virtual;
    function GetLoaded: Boolean; virtual;
  public
    constructor Create(); virtual; abstract;
    destructor Destroy; override; abstract;

    procedure Load(); virtual; abstract;
    procedure Unload(); virtual; abstract;

    procedure Update(deltaTime: Double; X, Y: Integer); virtual; abstract;

    property OnNotify: TdfNotifyProc read FNotifyProc write FNotifyProc;
    property Status: TdfGameSceneStatus read GetStatus write SetStatus;
    property IsLoaded: Boolean read GetLoaded;
    property Name: String read FName write SetName;
  end;

  TdfGameSceneClass = class of TdfGameScreen;

implementation

{ TdfGameScene }

procedure TdfGameScreen.FadeIn(deltaTime: Double);
begin
  Status := gssFadeInComplete;
end;

procedure TdfGameScreen.FadeOut(deltaTime: Double);
begin
  Status := gssFadeOutComplete;
end;

function TdfGameScreen.GetLoaded: Boolean;
begin
  Result := FLoaded;
end;

function TdfGameScreen.GetStatus: TdfGameSceneStatus;
begin
  Result := FStatus;
end;

procedure TdfGameScreen.SetName(const Value: String);
begin
  FName := Value;
end;

procedure TdfGameScreen.SetStatus(const aStatus: TdfGameSceneStatus);
begin
  FStatus := aStatus;
end;

end.
