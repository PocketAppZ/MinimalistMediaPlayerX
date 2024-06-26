{   Minimalist Media Player
    Copyright (C) 2021-2024 Baz Cuda
    https://github.com/BazzaCuda/MinimalistMediaPlayerX

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA
}
unit TCommonUtilsClass;

interface

uses
  winApi.windows,
  system.classes,
  vcl.controls, vcl.dialogs, vcl.extCtrls, vcl.forms, vcl.stdCtrls;

type
  TCommonUtils = class(TObject)
  private
  public
    procedure copyPNGImage(SourceImage, DestImage: TImage);
    function delay(const dwMilliseconds: DWORD): boolean;
    function deleteThisFile(const aFilePath: string; const shift: TShiftState): boolean;
    function doCommandLine(const aCommandLIne: string): boolean;
    function formatFileSize(const aSize: int64): string;
    function formatSeconds(const seconds: integer): string;
    function formatTime(const seconds: integer): string;
    function formattedWidthHeight(const width: integer; const height: integer): string;
    function getAspectRatio(const X: integer; const Y: integer): double;
    function getConfigFilePath: string;
    function getExePath: string;
    function getFileNameWithoutExtension(const aFilePath: string): string;
    function getFileSize(const aFilePath: string): int64;
    function getFileVersionFmt(const aFilePath: string = ''; const fmt: string = 'v%d.%d.%d.%d'): string;
    function getWndWidthHeight(const aWnd: HWND; var aWidth: integer; var aHeight: integer): boolean;
    function getScreenCentre: integer;
    function getScreenHeight: integer;
    function getScreenWidth: integer;
    function initTransparentForm(const aForm: TForm): TForm;
    function initTransparentLabel(const aLabel: TLabel): boolean;
    function isEditFriendly(const aFilePath: string): boolean;
    function offScreen(const aHWND: HWND): boolean;
    function reloadPlaylist(const aFolder: string): string;
    function renameFile(const aFilePath: string; const aNewFileNamePart: string = ''): string;
    function shellExec(const anExePath: string; const aParams: string): boolean;
    function showOKCancelMsgDlg(const aMsg: string;
                                const msgDlgType: TMsgDlgType = mtConfirmation;
                                const msgDlgButtons: TMsgDlgButtons = MBOKCANCEL;
                                const defButton: TMsgDlgBtn = MBCANCEL): TModalResult;
    function withinScreenLimits(const aWidth: integer; const aHeight: integer): boolean;
  end;


function CU: TCommonUtils;

implementation

uses
  winApi.shellApi, winAPI.activeX, winApi.messages,
  system.sysUtils, system.IOUtils,
  vcl.graphics,
  consts, formCaption, formInputBox,
  TGlobalVarsClass, TMediaPlayerClass, TPlaylistClass, TUICtrlsClass, _debugWindow;

var
  gCU: TCommonUtils;

function CU: TCommonUtils;
begin
  case gCU = NIL of TRUE: gCU := TCommonUtils.create; end;
  result := gCU;
end;

{ TCommonUtils }

procedure TCommonUtils.copyPNGImage(SourceImage, DestImage: TImage);
begin
  // Check if the source image has a picture to copy
  if Assigned(SourceImage.Picture) and Assigned(SourceImage.Picture.Graphic) then
  begin
    // Clear the destination image
    DestImage.Picture := nil;

    // Assign the graphic content from the source to the destination
    DestImage.Picture.Assign(SourceImage.Picture.Graphic);
  end;
end;


function TCommonUtils.delay(const dwMilliseconds: DWORD): boolean;
// Used to delay an operation; "sleep()" would suspend the thread, which is not what is required
var
  iStart, iStop: DWORD;
begin
  iStart := GetTickCount;
  repeat
    iStop  := GetTickCount;
    Application.ProcessMessages;
  until (iStop  -  iStart) >= dwMilliseconds;
end;

function TCommonUtils.deleteThisFile(const aFilePath: string; const shift: TShiftState): boolean;
// performs (in a separate process) the actual file/folder deletion initiated by deleteCurrentFile
begin
  case ssCtrl in Shift of  TRUE: doCommandLine('rot -nobanner -p 1 -r "' + ExtractFilePath(AFilePath) + '*.* "'); // folder contents but not subfolders
                          FALSE: doCommandLine('rot -nobanner -p 1 -r "' + AFilePath + '"'); end;                 // one individual file
end;

function TCommonUtils.doCommandLine(const aCommandLIne: string): boolean;
// Create a cmd.exe process to execute any command line
// "Current Directory" defaults to the folder containing this application's executable.
var
  vStartInfo:  TStartupInfo;
  vProcInfo:   TProcessInformation;
begin
  result := FALSE;
  case trim(aCommandLIne) = ''  of TRUE: EXIT; end;

  FillChar(vStartInfo,  SizeOf(TStartupInfo), #0);
  FillChar(vProcInfo,   SizeOf(TProcessInformation), #0);
  vStartInfo.cb          := SizeOf(TStartupInfo);
  vStartInfo.wShowWindow := SW_HIDE;
  vStartInfo.dwFlags     := STARTF_USESHOWWINDOW;

  var vCmd := 'c:\windows\system32\cmd.exe';
  var vParams := '/c ' + aCommandLIne;

  result := CreateProcess(PWideChar(vCmd), PWideChar(vParams), nil, nil, FALSE,
                          CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS, nil, PWideChar(getExePath), vStartInfo, vProcInfo);
end;

function TCommonUtils.formatFileSize(const aSize: int64): string;
begin
 case aSize >= 1052266987 of  TRUE: try result := format('FS:  %.3f GB', [aSize / 1024 / 1024 / 1024]); except end;  // >= 0.98 of 1GB
                             FALSE: case aSize < 1024 * 1024 of  TRUE: try result := format('FS:  %d KB', [trunc(aSize / 1024)]); except end;
                                                                FALSE: try result := format('FS:  %.2f MB', [aSize / 1024 / 1024]); except end;end;end;
end;

function TCommonUtils.formatSeconds(const seconds: integer): string;
begin
  case seconds < 100 of  TRUE: result := format('%ds', [seconds]);
                        FALSE: result := format('%dm%.2ds', [seconds div 60, seconds mod 60]);
  end;
end;

function TCommonUtils.formattedWidthHeight(const width, height: integer): string;
begin
  result := format('%dx%d', [width, height]);
end;

function TCommonUtils.formatTime(const seconds: integer): string;
begin
  case seconds < 60 of  TRUE: result := format('%.2d:%.2d', [0, seconds]);
                       FALSE: case seconds < 3600 of  TRUE: result := format('%.2d:%.2d', [seconds div 60, seconds mod 60]);
                                                     FALSE: result := format('%.2d:%.2d:%.2d', [seconds div 3600, (seconds mod 3600) div 60, seconds mod 3600 mod 60]); end;end;
end;

function TCommonUtils.getAspectRatio(const X: integer; const Y: integer): double;
begin
  result := 1;
  case (X = 0) or (Y = 0) of TRUE: EXIT; end;
  result := Y / X;
end;

function TCommonUtils.getConfigFilePath: string;
begin
  result := getExePath + 'MinimalistMediaPlayer.conf';
end;

function TCommonUtils.getExePath: string;
begin
  result := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
end;

function TCommonUtils.getFileNameWithoutExtension(const aFilePath: string): string;
begin
  result := TPath.GetFileNameWithoutExtension(aFilePath);
end;

function TCommonUtils.getFileSize(const aFilePath: string): int64;
var
  vHandle:  THandle;
  vRec:     TWin32FindData;
begin
  vHandle := findFirstFile(PChar(aFilePath), vRec);
  case vHandle <> INVALID_HANDLE_VALUE of TRUE: begin
                                                  winAPI.windows.findClose(vHandle);
                                                  case (vRec.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 of TRUE:
                                                    result := (int64(vRec.nFileSizeHigh) shl 32) + vRec.nFileSizeLow; end;end;end;
end;

function TCommonUtils.getFileVersionFmt(const aFilePath: string = ''; const fmt: string = 'v%d.%d.%d.%d'): string;
var
  vFilePath:    string;
  iBufferSize:  DWORD;
  iDummy:       DWORD;
  pBuffer:      pointer;
  pFileInfo:    pointer;
  iVer:         array[1..4] of WORD;
begin
  // set default value
  result := '';
  // get filename of exe/dll if no filename is specified
  vFilePath := aFilePath;
  case vFilePath = '' of TRUE:  begin
                                  // prepare buffer for path and terminating #0
                                  setLength(vFilePath, MAX_PATH + 1);
                                  setLength(vFilePath, getModuleFileName(hInstance, PChar(vFilePath), MAX_PATH + 1));
                                end;end;

  // get size of version info (0 if no version info exists)
  iBufferSize := getFileVersionInfoSize(PChar(vFilePath), iDummy);

  case iBufferSize > 0 of TRUE:   begin
                                    getMem(pBuffer, iBufferSize);
                                    try
                                      // get fixed file info (language independent)
                                      getFileVersionInfo(PChar(vFilePath), 0, iBufferSize, pBuffer);
                                      verQueryValue(pBuffer, '\', pFileInfo, iDummy);
                                      // read version blocks
                                      iVer[1] := hiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
                                      iVer[2] := loWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
                                      iVer[3] := hiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
                                      iVer[4] := loWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
                                    finally
                                      freeMem(pBuffer);
                                    end;
                                    // format result string
                                    result := format(fmt, [iVer[1], iVer[2], iVer[3], iVer[4]]);
                                  end;end;
end;

function TCommonUtils.getScreenCentre: integer;
begin
  result := getScreenWidth div 2;
end;

function TCommonUtils.getScreenHeight: integer;
begin
  var vRect := screen.WorkAreaRect; // the screen minus the taskbar
  result := vRect.height - UI.timelineHeight;
end;

function TCommonUtils.getScreenWidth: integer;
begin
  result := GetSystemMetrics(SM_CXVIRTUALSCREEN); // we'll assume that the taskbar is in it's usual place at the bottom of the screen
end;

function TCommonUtils.getWndWidthHeight(const aWnd: HWND; var aWidth: integer; var aHeight: integer): boolean;
var
  vR: TRect;
begin
  getWindowRect(aWnd, vR);
  aWidth  := vR.width;
  aHeight := vR.height;
end;

function TCommonUtils.initTransparentForm(const aForm: TForm): TForm;
begin
  aForm.align                  := alBottom;
  aForm.styleElements          := []; // don't allow any theme alterations
  aForm.borderStyle            := bsNone;
  aForm.color                  := clBlack;
  aForm.ctl3D                  := FALSE;
  aForm.doubleBuffered         := TRUE;
  aForm.margins.bottom         := 0;
  aForm.formStyle              := fsStayOnTop; // Keep the form always on top - hmmm. How does this impact infoPanel?
  aForm.borderIcons            := [];
  aForm.alphaBlend             := True;
  aForm.alphaBlendValue        := 255;
  aForm.transparentColorValue  := clBlack;
  aForm.transparentColor       := TRUE;
  result := aForm;
end;

function TCommonUtils.initTransparentLabel(const aLabel: TLabel): boolean;
begin
  aLabel.align             := alClient;
  aLabel.alignment         := taCenter;
  aLabel.alignWithMargins  := TRUE;
  aLabel.color             := clBlack;
  aLabel.font.color        := ST_DEFAULT_COLOR;
  aLabel.font.size         := 14;
  aLabel.font.style        := [fsBold];
  aLabel.layout            := tlBottom;
  aLabel.margins.Bottom    := 6;
  aLabel.parentColor       := FALSE;
  aLabel.parentCustomHint  := FALSE;
  aLabel.parentFont        := FALSE;
  aLabel.ParentShowHint    := FALSE;
  aLabel.showAccelChar     := FALSE;
  aLabel.showHint          := FALSE;
  aLabel.transparent       := TRUE;
  aLabel.wordWrap          := FALSE;
end;

function TCommonUtils.isEditFriendly(const aFilePath: string): boolean;
begin
  result := NOT aFilePath.contains('''') AND NOT aFilePath.contains('&');
end;

function TCommonUtils.offScreen(const aHWND: HWND): boolean;
var
  vR: TRect;
begin
  getWindowRect(aHWND, vR);
  result := (vR.bottom > getScreenHeight) or (vR.right > getScreenWidth) or (vR.left < 0) or (vR.top < 0);
end;

function TCommonUtils.reloadPlaylist(const aFolder: string): string;
begin
  var vCurrentItem     := PL.currentItem;
  var vCurrentPosition := MP.position;

  PL.fillPlaylist(aFolder);
  case PL.find(vCurrentItem) of  TRUE: MP.position := vCurrentPosition;
                                FALSE: begin
                                         PL.first;
                                         MP.play(PL.currentItem); end;end;
  MC.caption := PL.formattedItem;
  result := 'Playlist reloaded';
end;

function TCommonUtils.renameFile(const aFilePath: string; const aNewFileNamePart: string = ''): string;
// the user gets to edit the filename part without the path and the extension
var
  vOldFileNamePart: string;
  vExt:             string;
  s:                string;
  vNewFilePath:     string;
begin
  result := aFilePath; // indicates failure
  try
    vOldFileNamePart  := extractFileName(aFilePath);
    vExt              := extractFileExt(vOldFileNamePart);
    vOldFileNamePart  := getFileNameWithoutExtension(vOldFileNamePart);

    case aNewFileNamePart <> '' of  TRUE: s := aNewFileNamePart;
                                   FALSE: begin
                                            try
                                              s           := InputBoxForm(vOldFileNamePart); // the form returns the edited filename or the original if the user pressed cancel
                                            finally
                                            end;end;end;
  except
    s := '';   // any funny business, force the rename to be abandoned
  end;
  case (s = '') OR (s = vOldFileNamePart) of TRUE: EXIT; end; // nothing to do

  vNewFilePath := extractFilePath(aFilePath) + s + vExt;  // construct the full path and new filename with the original extension
  case system.sysUtils.renameFile(aFilePath, vNewFilePath) of  TRUE: result := vNewFilePath;
                                                              FALSE: ShowMessage('Rename failed:' + #13#10 +  SysErrorMessage(getlasterror)); end;
end;

function TCommonUtils.shellExec(const anExePath: string; const aParams: string): boolean;
begin
  shellExecute(0, 'open', pchar(anExePath), pchar('"' + aParams + '"'), '', SW_SHOW);
end;

function TCommonUtils.showOKCancelMsgDlg(const aMsg: string;
                                         const msgDlgType: TMsgDlgType = mtConfirmation;
                                         const msgDlgButtons: TMsgDlgButtons = MBOKCANCEL;
                                         const defButton: TMsgDlgBtn = MBCANCEL): TModalResult;
// used for displaying the delete file/folder confirmation dialog
// We modify the standard dialog to make everything bigger, especially the width so that long folder names and files display properly
// The standard dialog would unhelpfully truncate them.#
var vControl: TControl;
begin
  screen.cursor := crDefault;
  coInitialize(NIL);
  with CreateMessageDialog(aMsg, msgDlgType, msgDlgButtons, defButton) do
  try
    GV.userInput := TRUE;
    font.name := 'Segoe UI';
    font.size := 12;
    height    := height + 50;
    width     := width + 200;

    for var i := 0 to controlCount - 1 do begin
      case controls[i] is TLabel  of   TRUE: with Controls[i] as TLabel do Width := Width + 200; end;
      case controls[i] is TButton of   TRUE: with Controls[i] as TButton do begin
                                                                                top  := top  + 60;
                                                                                left := left + 100;
                                                                            end;end;
    end;
    result := ShowModal;
  finally
    free;
    GV.userInput := FALSE;
    coUninitialize;
  end;
end;

function TCommonUtils.withinScreenLimits(const aWidth: integer; const aHeight: integer): boolean;
begin
  var vR := screen.workAreaRect; // the screen minus the taskbar, which we assume is at the bottom of the desktop
  vR.height := vR.height - UI.timelineHeight;
  result := (aWidth <= vR.width) AND (aHeight <= vR.height);
end;

initialization
  gCU := NIL;

finalization
  case gCU <> NIL of TRUE: gCU.free; end;

end.
