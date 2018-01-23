unit uMyFunctions;

interface

uses
  System.Classes, System.Types, System.SysUtils, System.IniFiles,
  System.IOUtils, FMX.Dialogs, FMX.Memo, FMX.Types, FMX.Forms, System.UITypes,
  FMX.PlatForm;

type
  TMyIniFile = class(TObject)
  const

  private
    pathIni: String;
  public
    FormWidth, FormHeight, FormTop, FormLeft: Integer;
    constructor Create;
    procedure LoadIniFile;
    procedure SaveIniFile;
  end;

function GetAppVersion(): String;
procedure MyLog(msg: String);

{$IFDEF MSWINDOWS }
function GetComputerName(): string;
function GetAutoRunFilePath(): String;
procedure CreateAutoRun();
procedure DeleteAutoRun();
procedure ExeMutex();
{$ENDIF}

var
  MyIniFile: TMyIniFile;

implementation

{$IFDEF MSWINDOWS}

uses Winapi.Windows, ShlObj, FMX.PlatForm.Win, ShellAPI;
{$ENDIF}
{$IFDEF ANDROID}

uses Androidapi.JNI.JavaTypes, Androidapi.Helpers,
  Androidapi.JNI.GraphicsContentViewText;
{$ENDIF}

constructor TMyIniFile.Create;
begin
  // C:\Users\UserName\Documents\exeName.ini
  // ExtractFileName(ParamStr(0)) 等同 Application.Title

  pathIni := TPath.GetDocumentsPath + PathDelim + Application.title + '.ini';
  // ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
end;

{$IFDEF ANDROID}

function GetAppVersion: String;
var
  PackageManager: JPackageManager;
  PackageInfo: JPackageInfo;
begin
  PackageManager := TAndroidHelper.Context.getPackageManager;
  PackageInfo := PackageManager.getPackageInfo
    (TAndroidHelper.Activity.getPackageName, 0);
  Result := JStringToString(PackageInfo.versionName);
end;
{$ENDIF}
// {$IFDEF MACOS}
// begin
// Result := '';
// end;
// {$ENDIF}
{$IFDEF IOS}

function GetAppVersion: String;
begin
  Result := string(TNSString.Wrap(CFBundleGetValueForInfoDictionaryKey
    (CFBundleGetMainBundle, kCFBundleVersionKey)).UTF8String);
end;
{$ENDIF}
{$IFDEF MSWINDOWS}

function GetAppVersion: String;
const
  Fmt = '%d.%d.%d.%d';

var
  sFileName: String;
  iBufferSize: DWORD;
  iDummy: DWORD;
  pBuffer: Pointer;
  pFileInfo: Pointer;
  iVer: array [1 .. 4] of Word;
begin
  // set default value
  Result := '';

  // prepare buffer for path and terminating #0
  SetLength(sFileName, MAX_PATH + 1);
  SetLength(sFileName, GetModuleFileName(hInstance, PChar(sFileName),
    MAX_PATH + 1));

  // get size of version info (0 if no version info exists)
  iBufferSize := GetFileVersionInfoSize(PChar(sFileName), iDummy);
  if (iBufferSize > 0) then
  begin
    GetMem(pBuffer, iBufferSize);
    try
      // get fixed file info (language independent)
      GetFileVersionInfo(PChar(sFileName), 0, iBufferSize, pBuffer);
      VerQueryValue(pBuffer, '\', pFileInfo, iDummy);
      // read version blocks
      iVer[1] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
      iVer[2] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
      iVer[3] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
      iVer[4] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
    finally
      FreeMem(pBuffer);
    end;
    // format result string
    Result := Format(Fmt, [iVer[1], iVer[2], iVer[3], iVer[4]]);
  end;
end;
{$ENDIF}

procedure TMyIniFile.LoadIniFile;
var
  iniFile: TIniFile;
  i: Integer;
  str: String;
begin
  iniFile := TIniFile.Create(pathIni);
  try

  finally
    iniFile.DisposeOf;
  end;
end;

procedure TMyIniFile.SaveIniFile;
var
  iniFile: TIniFile;
  i: Integer;
  str: String;
begin
  iniFile := TIniFile.Create(pathIni);
  try

  finally
    iniFile.DisposeOf;
  end;
end;

procedure MyLog(msg: String);
var
  str: String;
begin
{$IFDEF DEBUG}
  Log.d(msg);
  // str := DateTimeToStr(Now) + '-- ' + msg;
  // FormMain.MemoDebug.Lines.Add(msg);
{$ENDIF}
end;

{$IFDEF MSWINDOWS}

function GetComputerName: string;
var
  buffer: array [0 .. MAX_COMPUTERNAME_LENGTH + 1] of Char;
  Size: Cardinal;
begin
  Result := 'N/A';
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  Winapi.Windows.GetComputerName(@buffer, Size);
  Result := StrPas(buffer);
end;

function GetAutoRunFilePath(): String;
var
  fileName, pathStartUp: String;
  path: array [0 .. 255] of Char;
begin
  fileName := Application.title + '.url';
  if SHGetSpecialFolderPath(0, @path[0], CSIDL_STARTUP, true) then
    pathStartUp := String(path);

  Result := pathStartUp + PathDelim + fileName;
end;

procedure CreateAutoRun();
const
  FileProtocol = 'file:///';
var
  fileName: String;
  pathExe, pathUrl, pathAutoRun: String;
begin
  fileName := Application.title + '.url';
  pathUrl := TPath.GetDocumentsPath + PathDelim + fileName;
  pathExe := ParamStr(0);

  pathAutoRun := GetAutoRunFilePath();

  with TIniFile.Create(pathAutoRun) do
    try
      WriteString('InternetShortcut', 'URL', FileProtocol + pathExe);
      WriteString('InternetShortcut', 'IconIndex', '0');
      WriteString('InternetShortcut', 'IconFile', pathExe);
    finally
      DisposeOf();
    end;

end;

procedure DeleteAutoRun();
begin
  DeleteFile(PWideChar(GetAutoRunFilePath()));
end;

// 防止程式重覆執行
procedure ExeMutex();
var
  PrevInstHandle: THandle;
  Mutex: THandle;
  h: HWND;
begin
  Mutex := OpenMutex(SYNCHRONIZE, false, PChar(Application.title));

  if Mutex <> 0 then
  begin
    PrevInstHandle := Winapi.Windows.FindWindow(nil, PChar(Application.title));

    if PrevInstHandle <> 0 then
    begin
      if IsIconic(PrevInstHandle) then
        ShowWindow(PrevInstHandle, SW_RESTORE)
      else
        BringWindowToTop(PrevInstHandle);

      SetForegroundWindow(PrevInstHandle);
    end;
    // Application.ShowMainForm := false;  //XE10 沒有了
    Application.Terminate();
  end
  else
    CreateMutex(nil, false, PChar(Application.title));
end;
{$ENDIF}

end.
