unit uLog;

interface

const
  LOGFILE = 'main.log';

var
  iLog: Integer;



//������������ ������� ������� � ������������� ��� ������� �������

procedure logWriteMessage(Msg: String; DateTime: Boolean = True;
                                        NewLine: Boolean = True);
procedure logWriteWarning(Msg: String; DateTime: Boolean = True;
                                        NewLine: Boolean = True);
procedure logWriteError (Msg: String; DateTime: Boolean = True;
                                       NewLine: Boolean = True;
                                      Critical: Boolean = False);


//���������� ������� ������������� � ��������������� �������
function LogInit(): Integer;
function LogDeinit(): Integer;

implementation

uses
  dfLogger;

procedure logWriteMessage(Msg: String; DateTime: Boolean = True;
                                        NewLine: Boolean = True);
begin
  if DateTime then
    LoggerWriteDateTime(iLog, '');
  LoggerWriteUnFormated(ilog, PWideChar(Msg));
  if NewLine then
    LoggerWriteEndL(iLog);
end;

procedure logWriteWarning(Msg: String; DateTime: Boolean = True;
                                        NewLine: Boolean = True);
begin
  if DateTime then
    LoggerWriteDateTime(iLog, '');
  LoggerWriteWarning(ilog, PWideChar(Msg));
  if NewLine then
    LoggerWriteEndL(iLog);
end;

procedure logWriteError (Msg: String; DateTime: Boolean = True;
                                       NewLine: Boolean = True;
                                      Critical: Boolean = False);
begin
  if DateTime then
    LoggerWriteDateTime(iLog, '');
  if Critical then
    LoggerWriteError(ilog, PWideChar(' :CRITICAL: ' + Msg))
  else
    LoggerWriteError(ilog, PWideChar(Msg));
  if NewLine then
    LoggerWriteEndL(iLog);
end;




function LogInit(): Integer;
begin
  LoggerAddLog(LOGFILE);
  iLog := LoggerFindLog(LOGFILE);
  LoggerWriteHeader(iLog, '����� ������������');

  Result := 0;
end;

function LogDeinit(): Integer;
begin
  LoggerWriteBottom(iLog, '��������� ������������');
  LoggerDelLog(LOGFILE);

  Result := 0;
end;

initialization
  LogInit();

finalization
  LogDeInit();

end.
