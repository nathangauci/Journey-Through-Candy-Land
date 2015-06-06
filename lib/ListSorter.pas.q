unit ListSorter;
interface
type
	List= Array of Integer;
///
/// This unit sorts lists
/// It implements the bubble sort and allows it to
/// sort a dynamic array of integers.

function ListSort(ListArray: List): List;

///
/// The function takes the list and sorts it, the function
/// then returns the sorted list back to whereever is calling
/// the function

implementation

procedure Swap(var v1, v2: Integer);
var
	temp: Integer;
begin
	temp:= v1;
	v1:= v2;
	v2:= temp;
end;

function ListSort(ListArray: List): List;
var
	i, j: Integer;
begin
	for i:= High(ListArray) downto Low(ListArray) do
	begin
		for j:= Low(ListArray) to i -1 do
		begin
			if (ListArray[j] < ListArray [j+1]) then
			begin
				Swap(ListArray[j], ListArray[j+1]);
			end;
		end;
	end;
	result:=ListArray;
end;

end.