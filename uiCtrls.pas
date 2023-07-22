{   Minimalist Media Player
    Copyright (C) 2021 Baz Cuda <bazzacuda@gmx.com>
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
unit uiCtrls;

interface

uses
  Forms, winApi.windows, consts, winAPI.shellAPI, vcl.graphics, vcl.controls, vcl.ComCtrls, globalVars, vcl.extCtrls;

type
  TUI = class(TObject)
  strict private
    FMainForm: TForm;
    FVideoPanel: TPanel;
  private
    function addMenuItems(aForm: TForm): boolean;
    function setCustomTitleBar(aForm: TForm): boolean;
    function setGlassFrame(aForm: TForm): boolean;
    function setWindowStyle(aForm: TForm): boolean;
    function createVideoPanel(aForm: TForm): boolean;
  public
    function initUI(aForm: TForm): boolean;
    property mainForm: TForm read FMainForm;
    property videoPanel: TPanel read FVideoPanel;
  end;

function UI: TUI;

implementation

var
  gUI: TUI;

function UI: TUI;
begin
  case gUI = NIL of TRUE: gUI := TUI.create; end;
  result := gUI;
end;

{ TUI }

function TUI.addMenuItems(aForm: TForm): boolean;
begin
  var vSysMenu := getSystemMenu(aForm.handle, FALSE);
  AppendMenu(vSysMenu, MF_SEPARATOR, 0, '');
  AppendMenu(vSysMenu, MF_STRING, MENU_ABOUT_ID, '&About Minimalist Media Player�');
  AppendMenu(vSysMenu, MF_STRING, MENU_HELP_ID, 'Show &Keyboard functions');
end;

function TUI.createVideoPanel(aForm: TForm): boolean;
begin
  FVideoPanel        := TPanel.create(aForm);
  FVideoPanel.parent := aForm;
  FVideoPanel.align  := alClient;
  FVideoPanel.color  := clBlack;
  FVideoPanel.BevelOuter := bvNone;
end;

function TUI.initUI(aForm: TForm): boolean;
begin
  FMainForm := aForm;
  aForm.position      := poScreenCenter;
  aForm.borderIcons   := [biSystemMenu];
  aForm.styleElements := []; // [seFont]; //, seClient];
  setGlassFrame(aForm);
  setCustomTitleBar(aForm);
  setWindowStyle(aForm);
  DragAcceptFiles(aForm.handle, TRUE);
  addMenuItems(aForm);
  aForm.color         := clBlack; // background color of the window's client area, so zooming-out doesn't show the design-time color
  createVideoPanel(aForm);
end;

function TUI.setCustomTitleBar(aForm: TForm): boolean;
begin
  aForm.customTitleBar.enabled        := TRUE;
  aForm.customTitleBar.showCaption    := FALSE;
  aForm.customTitleBar.showIcon       := FALSE;
  aForm.customTitleBar.systemButtons  := FALSE;
  aForm.customTitleBar.systemColors   := FALSE;
  aForm.customTitleBar.systemHeight   := FALSE;
  aForm.customTitleBar.height         := 1; // systemHeight=FALSE must be set before this
end;

function TUI.setGlassFrame(aForm: TForm): boolean;
begin
  aForm.glassFrame.enabled  := TRUE;
  aForm.glassFrame.top      := 1;
end;

function TUI.setWindowStyle(aForm: TForm): boolean;
begin
  SetWindowLong(aForm.handle, GWL_STYLE, GetWindowLong(aForm.handle, GWL_STYLE) OR WS_CAPTION AND (NOT (WS_BORDER)));
end;

initialization
  gUI := NIL;

finalization
  case gUI <> NIL of TRUE: gUI.free; end;

end.
