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
program MinimalistMediaPlayer;

{$R *.dres}

uses
  Vcl.Forms,
  Vcl.Styles,
  Vcl.Themes,
  MPVBasePlayer in 'libMPVDelphi\MPVBasePlayer.pas',
  MPVClient in 'libMPVDelphi\MPVClient.pas',
  MPVConst in 'libMPVDelphi\MPVConst.pas',
  MPVNode in 'libMPVDelphi\MPVNode.pas',
  MPVRender in 'libMPVDelphi\MPVRender.pas',
  MPVRenderGL in 'libMPVDelphi\MPVRenderGL.pas',
  MPVStreamCB in 'libMPVDelphi\MPVStreamCB.pas',
  MPVTrack in 'libMPVDelphi\MPVTrack.pas',
  ALProgressBar in 'ALProgressBar.pas',
  consts in 'consts.pas',
  MediaInfoDLL in 'MediaInfoDLL.pas',
  formAbout in 'formAbout.pas' {AboutForm},
  formCaption in 'formCaption.pas' {CaptionForm},
  formCaptions in 'formCaptions.pas' {CaptionsForm},
  formDownload in 'formDownload.pas' {DownloadForm},
  formHelp in 'formHelp.pas' {HelpForm},
  formInputBox in 'formInputBox.pas' {InputBoxForm},
  formMain in 'formMain.pas' {MMPUI},
  formPlaylist in 'formPlaylist.pas' {PlaylistForm},
  formProgress in 'formProgress.pas' {ProgressForm},
  formStreamList in 'formStreamList.pas' {StreamListForm},
  formTimeline in 'formTimeline.pas' {TimelineForm},
  TAppEventsClass in 'TAppEventsClass.pas',
  TBookmarkClass in 'TBookmarkClass.pas',
  TCommonUtilsClass in 'TCommonUtilsClass.pas',
  TConfigFileClass in 'TConfigFileClass.pas',
  TGlobalVarsClass in 'TGlobalVarsClass.pas',
  TKeyboardClass in 'TKeyboardClass.pas',
  TMediaInfoClass in 'TMediaInfoClass.pas',
  TMediaPlayerClass in 'TMediaPlayerClass.pas',
  TMediaTypesClass in 'TMediaTypesClass.pas',
  TParamStringsClass in 'TParamStringsClass.pas',
  TPlaylistClass in 'TPlaylistClass.pas',
  TProgramUpdatesClass in 'TProgramUpdatesClass.pas',
  TProgressBarClass in 'TProgressBarClass.pas',
  TSegmentClass in 'TSegmentClass.pas',
  TSendAllClass in 'TSendAllClass.pas',
  TSysCommandsClass in 'TSysCommandsClass.pas',
  TTickTimerClass in 'TTickTimerClass.pas',
  TUICtrlsClass in 'TUICtrlsClass.pas',
  _debugWindow in '..\DebugWindow\_debugWindow.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := FALSE;
  debugClear;

  Application.Initialize;
  Application.ShowMainForm := FALSE;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Charcoal Dark Slate');
  Application.CreateForm(TMMPUI, MMPUI);
  Application.Run;
end.
