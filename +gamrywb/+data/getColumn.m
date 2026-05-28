function col = getColumn(tbl, name)
%GETCOLUMN Return a table column by case-insensitive header name.

    idx = find(strcmpi(tbl.headers, name), 1);
    if isempty(idx)
        col = [];
    else
        col = tbl.data(:, idx);
    end
end
