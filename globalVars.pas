{   Minimalist Media Player
    Copyright (C) 2021 Baz Cuda <bazzacuda@gmx.com>
    https://github.com/BazzaCuda/MinimalistMediaPlayer

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
unit globalVars;

interface

uses ALProgressBar;

type
  TGlobalVars = class(TObject)
  strict private
    FPB: TALProgressBar;
  public
    property PB: TALProgressBar read FPB write FPB;
  end;

function GV: TGlobalVars;
function PB: TALProgressBar;

implementation

var
  gGV: TGlobalVars;

function GV: TGlobalVars;
begin
  case gGV = NIL of TRUE: gGV := TGlobalVars.create; end;
  result := gGV;
end;

function PB: TALProgressBar;
begin
  result := GV.PB;
end;

initialization
  gGV := NIL;

finalization
  case gGV <> NIL of TRUE: gGV.free; end;

end.
