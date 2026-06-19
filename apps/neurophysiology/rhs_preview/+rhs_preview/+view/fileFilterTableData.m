% Expected caller: rhs_preview.run/buildSpec. Input is app state. Output is
% editable cell rows for manual RHS file filtering.
function data = fileFilterTableData(S)
%FILEFILTERTABLEDATA Build display rows for the file filter table.

    rows = table();
    if isstruct(S) && isfield(S, "filterRows") && istable(S.filterRows)
        rows = S.filterRows;
    end
    if height(rows) == 0
        data = cell(0, 3);
        return;
    end

    data = cell(height(rows), 3);
    for r = 1:height(rows)
        data{r, 1} = char(rows.label(r));
        data{r, 2} = char(rows.filePath(r));
        data{r, 3} = char(rows.comment(r));
    end
end
