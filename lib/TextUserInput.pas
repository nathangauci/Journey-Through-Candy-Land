unit TextUserInput;

interface
////////////////////////////////////////////////////////////
/// Reads a line from a file and returns it as a string   //
////////////////////////////////////////////////////////////

function ReadStringF(var tFile: TextFile): String;
////////////////////////////////////////////////////////////////////
/// Reads a line from a file and if it is an integer, returns it ///
/// else returns 0... 											 ///
////////////////////////////////////////////////////////////////////
function ReadIntegerF(var tFile: TextFile): Integer;

implementation
uses
	SysUtils;
function ReadStringF(var tFile: TextFile): String;
begin
	ReadLn(tFile, result);
end;

function ReadIntegerF(var tFile: TextFile): Integer;
var
	line: String;
begin
	line:= ReadStringF(tFile);
	TryStrToInt(line, result);
end;
end.
