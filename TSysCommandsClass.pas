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
unit TSysCommandsClass;

interface

uses
  winAPI.messages, winAPI.windows,
  consts;

function doSysCommand(var Message: TWMSysCommand): boolean;
function sendSysCommandClose(const aHWND: HWND): boolean;

implementation

uses
  TGlobalVarsClass, TUICtrlsClass;

function doSysCommand(var Message: TWMSysCommand): boolean;
begin
  case Message.CmdType of MENU_ABOUT_ID:  UI.showAboutBox; end;
  case Message.CmdType of MENU_HELP_ID:   UI.toggleHelpWindow; end;
end;

function sendSysCommandClose(const aHWND: HWND): boolean;
begin
  GV.closeApp := TRUE;
  case UI.initialized of TRUE: postMessage(aHWND, WM_CLOSE, 0, 0); end;
end;

end.
