unit uGameObjects;

interface

uses
  Contnrs,

  uGameObject, uSpaceFighter, uFighterControl.User, uBoomAccum;

{� ���� �������� ������� ������ ������, ��� ��������� ���, ����� ������ ������
 ����� MainGame �������� ��� ���������� �� ��������������� ��������

 ����������, � ���� ������� �������� ��� ����� TdfMainGame}
var
  dfGameObjects: record
    Player: TdfSpaceFighter;
    UserControl: TdfUserControl;
    GameObjects: TObjectList; //������ ������ ������� ��������

    BigBoom: TdfBoomAccum;
  end;

implementation

end.
