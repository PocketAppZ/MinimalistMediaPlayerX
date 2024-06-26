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
unit TProgramUpdatesClass;

interface

type
  TProgramUpdates = class(TObject)
  strict private
    FReleaseTag: string;
  private
    function getJSONReleaseTag: string;
    function downloadRelease(const aReleaseTag: string): string;
    function extractRelease(const aReleaseTag: string): boolean;
    function getReleaseTag: string;
  public
    property releaseTag: string read getReleaseTag;
  end;

function PU: TProgramUpdates;

implementation

uses
  idHTTP, idSSLOpenSSL, idComponent,
  system.json, system.classes, system.sysUtils, system.strUtils, system.zip,
  vcl.forms,
  consts, formDownload,
  TConfigFileClass, TCommonUtilsClass, TProgressBarClass, _debugWindow;

type
  TWorkProgress = class(TObject)  // only because IdHttp requires these callbacks to be procedure of object
    procedure idHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: int64);
    procedure idHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: int64);
    procedure idHTTPEnd(ASender: TObject; AWorkMode: TWorkMode);
  end;

var
  gPU: TProgramUpdates;

  gWP: TWorkProgress;
  gProgressBar: TProgressBar;
  gDownloadForm: TDownloadForm;

function PU: TProgramUpdates;
begin
  case gPU = NIL of TRUE: gPU := TProgramUpdates.create; end;
  result := gPU;
end;

function cleanTag(const aReleaseTag: string): string;
begin
  result := replaceStr(aReleaseTag, '.', '_');
end;

function fetchURL(const aURL: string; aFileStream: TStream = NIL; const aSuccess: string = ''): string;
var
  http:       TidHTTP;
  sslHandler: TidSSLIOHandlerSocketOpenSSL;
begin
  result        := aSuccess;
  gWP           := NIL;
  gProgressBar  := NIL;
  gDownloadForm := NIL;

  http := TidHTTP.create(nil);
  http.request.contentEncoding := 'UTF-8';

  sslHandler := TidSSLIOHandlerSocketOpenSSL.create(nil);
  sslHandler.sslOptions.sslVersions := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];

  http.IOHandler       := sslHandler;
  http.handleRedirects := TRUE;

  try
    try
      case aFileStream = NIL of  TRUE:  result := http.get(aUrl);     // just get the JSON release data
                                FALSE:  begin
                                          gWP := TWorkProgress.create;
                                          http.OnWorkBegin := gWP.idHTTPWorkBegin;
                                          http.OnWork      := gWP.idHTTPWork;
                                          http.OnWorkEnd   := gWP.idHTTPEnd;

                                          gDownloadForm := TDownloadForm.create(NIL);
                                          gProgressBar  := TProgressBar.create;
                                          gProgressBar.initProgressBar(gDownloadForm, PB_COLOR_DELTA);

                                          try
                                            gDownloadForm.show;
                                            http.get(aURL, aFileStream); // download the file
                                          finally
                                            case gWP           <> NIL of TRUE: freeAndNIL(gWP); end;
                                            case gProgressBar  <> NIL of TRUE: freeAndNIL(gProgressBar); end;
                                            case gDownloadForm <> NIL of TRUE: freeAndNIL(gDownloadForm); end;
                                          end;end;end;
    except
      on e:exception do result := e.Message; // if there's an error (e.g. 404), report it back to the About Box via the result, overriding aSuccess.
    end;
  finally
    sslHandler.free;
    http.free;
  end;
end;

function updateFile(const aReleaseTag: string): string;
begin
  result := CU.getExePath + 'update_' + cleanTag(aReleaseTag) + '.zip';
end;

{ TWorkProgress }

procedure TWorkProgress.idHTTPEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
//
end;

procedure TWorkProgress.idHTTPWork(aSender: TObject; aWorkMode: TWorkMode; aWorkCount: int64);
begin
  gProgressBar.position := aWorkCount;
  gDownloadForm.byteLabel.caption := format('%n of %n', [gProgressBar.position * 1.0, gProgressBar.max * 1.0]);
  gDownloadForm.byteLabel.Refresh;
  application.processMessages;
end;

procedure TWorkProgress.idHTTPWorkBegin(aSender: TObject; aWorkMode: TWorkMode; aWorkCountMax: int64);
begin
  gProgressBar.max := aWorkCountMax;
end;

{ TProgramUpdates }

function TProgramUpdates.extractRelease(const aReleaseTag: string): boolean;
  function backupName: string;
  begin
    result := 'MinimalistMediaPlayer ' + CU.getFileVersionFmt('', 'v%d_%d_%d');
  end;
begin
  result := FALSE;
  case  aReleaseTag = ''                                                                of TRUE: EXIT; end; // couldn't obtain latest release tag
  case (aReleaseTag <> '') AND (CU.getFileVersionFmt('', 'v%d.%d.%d') = aReleaseTag)    of TRUE: EXIT; end; // we're running the latest release

  case fileExists(CU.getExePath + backupName + '.exe') of FALSE:  CU.renameFile(paramStr(0), backupName); end;
  case fileExists(paramStr(0))                         of FALSE:  with TZipFile.create do begin
                                                                    open(updateFile(aReleaseTag), zmRead);
                                                                    extract('MinimalistMediaPlayer.exe', CU.getExePath);
                                                                    free;
                                                                    result := TRUE;
                                                                  end;end;
end;

function TProgramUpdates.getJSONReleaseTag: string;
var
  json: string;
  obj:  TJSONObject;
begin
  result := '';
  json := fetchURL('https://api.github.com/repos/bazzacuda/minimalistmediaplayerx/releases/latest');
  try
    obj := TJSONObject.ParseJSONValue(json) as TJSONObject;
    try
      case obj = NIL of FALSE: result := obj.values['tag_name'].value; end;
    except
    end;
  finally
    case obj = NIL of FALSE: obj.free; end;
  end;
end;

function TProgramUpdates.downloadRelease(const aReleaseTag: string): string;
begin
  result := aReleaseTag;

  case  aReleaseTag = ''                                                                of TRUE: EXIT; end; // couldn't obtain latest release tag
  case (aReleaseTag <> '') AND (CU.getFileVersionFmt('', 'v%d.%d.%d') = aReleaseTag)    of TRUE: EXIT; end; // we're running the latest release
  case (aReleaseTag <> '') AND (fileExists(updateFile(aReleaseTag)))                    of TRUE: EXIT; end; // we've already downloaded the release file

  var fs := TFileStream.create(updateFile(aReleaseTag), fmCreate);
  try
    result := fetchURL('https://github.com/BazzaCuda/MinimalistMediaPlayerX/releases/download/' + aReleaseTag + '/MinimalistMediaPlayer_' + cleanTag(aReleaseTag) + '.full.zip', fs, aReleaseTag);
  finally
    fs.free;
  end;
end;

function TProgramUpdates.getReleaseTag: string;
begin
  result := FReleaseTag;
  case result = '' of FALSE: EXIT; end;

  FReleaseTag := getJSONReleaseTag;
  result := downloadRelease(FReleaseTag); // if there's an error, report it back to the About Box via the result

  case (result = FReleaseTag) and fileExists(updateFile(FReleaseTag)) of TRUE: case extractRelease(FReleaseTag) of TRUE: result := result + ' Restart_Required'; end;end;
end;

initialization
  gPU := NIL;
  gWP            := NIL;
  gProgressBar   := NIL;
  gDownloadForm  := NIL;

finalization
  case gPU <> NIL of TRUE: gPU.free; end;

end.
