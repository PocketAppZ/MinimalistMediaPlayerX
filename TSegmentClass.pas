{   Minimalist Media Player
    Copyright (C) 2021 Baz Cuda
    https://github.com/BazzaCuda/MinimalistMediaPlayer

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA
}
unit TSegmentClass;

interface

uses
  vcl.extCtrls, vcl.stdCtrls, vcl.graphics, system.classes, vcl.forms, vcl.controls, winAPI.windows, generics.collections, System.Messaging;

const
  NEARLY_BLACK = clBlack + $101010;
  DEFAULT_SEGMENT_HEIGHT = 54;

type
  TSegment = class(TPanel)
  strict private
    FDeleted:     boolean;
    FEndSS:       integer;
    FOldColor:    TColor;
    FSegDetails:  TLabel;
    FSegID:       TLabel;
    FSelected:    boolean;
    FStartSS:     integer;
    FTrashCan:    TImage;
  private
    function  getDuration: integer;
    procedure setSegID(const Value: string);
    function  getSegID: string;
    procedure setSelected(const Value: boolean);
    function  getIx: integer;
    function  getIsLast: boolean;
    function  getIsFirst: boolean;

    class var FParent: TWinControl;
    class var FSelSeg: TSegment;
    class var FSegments: TObjectList<TSegment>;
    class destructor freeSegments;
    class function getSegments: TObjectList<TSegment>; static;
    class function getIncludedCount: integer; static;

  protected
    procedure doClick(Sender: TObject);
    procedure paint; override;
  public
    constructor create(const aStartSS: integer; const aEndSS: integer; const aDeleted: boolean = FALSE);
    function delete: boolean;
    procedure setDisplayDetails;
    property deleted:   boolean read FDeleted  write FDeleted;
    property duration:  integer read getDuration;
    property endSS:     integer read FEndSS    write FEndSS;
    property isFirst:   boolean read getIsFirst;
    property isLast:    boolean read getIsLast;
    property ix:        integer read getIx;
    property oldColor:  TColor  read FOldColor write FOldColor;
    property segID:     string  read getSegID  write setSegID;
    property selected:  boolean read FSelected write setSelected;
    property startSS:   integer read FStartSS  write FStartSS;
    property trashCan:  TImage  read FTrashCan;

    class function clearFocus: boolean; static;
    class property includedCount: integer read getIncludedCount;
    class property parentForm: TWinControl write FParent;
    class property segments: TObjectList<TSegment> read getSegments; // technique copied from system.messaging.TMessageManager
    class property selSeg: TSegment read FSelSeg write FSelSeg;
  end;

implementation

uses system.sysUtils, _debugWindow;

var nextColor: integer = 0;
function generateRandomEvenDarkerSoftColor: TColor;
// chatGPT
var
  darkerSoftColors: array of TColor;
begin
  // Define an array of even darker soft colors
  SetLength(darkerSoftColors, 6);
  darkerSoftColors[0] := RGB(80, 80, 80);   // Very Dark Gray
  darkerSoftColors[1] := RGB(70, 70, 70);   // Very Dark Silver
  darkerSoftColors[2] := RGB(60, 60, 60);   // Very Dark Platinum
  darkerSoftColors[3] := RGB(50, 50, 50);   // Very Dark Snow
  darkerSoftColors[4] := RGB(40, 40, 40);   // Very Dark Ivory
  darkerSoftColors[5] := RGB(30, 30, 30);   // Extremely Dark Gray

  result := darkerSoftColors[nextColor];
  inc(nextColor);
  case nextColor > 5 of TRUE: nextColor := 0; end;
end;

{ TSegment }

procedure TSegment.doClick(Sender: TObject);
begin
  clearFocus;
  FSelSeg    := SELF;
  selected   := TRUE;
end;

class function TSegment.clearFocus: boolean;
begin
  for var vSegment in FSegments do vSegment.selected := FALSE;
  FSelSeg := NIL;
end;

function TSegment.delete: boolean;
begin
  deleted    := TRUE;
  case color  = NEARLY_BLACK of FALSE: oldColor := color; end; // in case user tries to delete an already-deleted segment
  color      := NEARLY_BLACK;
end;

constructor TSegment.create(const aStartSS: integer; const aEndSS: integer; const aDeleted: boolean = FALSE);
begin
  inherited create(NIL);
  parent            := FParent;
  height            := DEFAULT_SEGMENT_HEIGHT;
  font.color        := clSilver;
  font.size         := 10;
  font.style        := [fsBold];
  alignment         := taLeftJustify;
  onClick           := doClick;
  doubleBuffered    := TRUE;

  startSS           := aStartSS;
  endSS             := aEndSS;
  borderStyle       := bsNone;
  bevelOuter        := bvNone;
  color             := generateRandomEvenDarkerSoftColor;
  oldColor          := color;

  FSegID            := TLabel.create(SELF);
  FSegID.parent     := SELF;
  FSegID.top        := 0;
  FSegID.left       := 4;
  FSegID.styleElements := [];

  FSegDetails := TLabel.create(SELF);
  FSegDetails.parent     := SELF;
  FSegDetails.top        := 38;
  FSegDetails.left       := 4;
  FSegDetails.styleElements := [];

  FTrashCan := TImage.create(SELF);
  FTrashCan.parent := SELF;
  FTrashCan.stretch := TRUE;
  FTrashCan.center  := TRUE;
  FTrashCan.height  := 31;
  FTrashCan.width   := 41;
  FTrashCan.visible := FALSE;
  FTrashCan.onClick := doClick;

  case aDeleted of TRUE: SELF.delete; end;
end;

function TSegment.getDuration: integer;
begin
  result := FEndSS - FStartSS;
end;

function TSegment.getIx: integer;
begin
  result := FSegments.indexOf(SELF);
end;

class function TSegment.getIncludedCount: integer;
begin
  result := 0;
  for var vSegment in FSegments do
    case vSegment.deleted of FALSE: inc(result); end;
end;

function TSegment.getIsFirst: boolean;
begin
  result := ix = 0;
end;

function TSegment.getIsLast: boolean;
begin
  result := ix = FSegments.count - 1;
end;

function TSegment.getSegID: string;
begin
  result := FSegID.caption;
end;

class function TSegment.getSegments: TObjectList<TSegment>;
begin
  case FSegments = NIL of TRUE: begin
                                  FSegments := TObjectList<TSegment>.create;
                                  FSegments.ownsObjects := TRUE; end;end;
  result := FSegments;
end;

procedure TSegment.paint;
begin
  var rect := getClientRect;

  canvas.brush.color := color;

  canvas.fillRect(rect);

  case selected of  TRUE: Frame3D(canvas, rect, clTeal, clTeal, 1);
                   FALSE: Frame3D(canvas, rect, color, color, 1); end;
end;

procedure TSegment.setDisplayDetails;
begin
  FSegDetails.caption := format('%ds - %ds', [startSS, endSS]);
end;

procedure TSegment.setSegID(const Value: string);
begin
  FSegID.caption := value;
end;

procedure TSegment.setSelected(const Value: boolean);
begin
  FSelected := Value;
  invalidate;
end;

class destructor TSegment.freeSegments;
begin
  freeAndNil(FSegments);
end;

end.
