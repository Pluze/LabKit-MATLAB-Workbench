function col = getColumn(tbl, name)
%GETCOLUMN Return a table column by case-insensitive header name.
%
% Inputs:
%   tbl - parsed table/curve struct with headers and data fields.
%   name - header name to match case-insensitively.
%
% Output:
%   col - numeric column vector, or [] when the header is absent.

    idx = find(strcmpi(tbl.headers, name), 1);
    if isempty(idx)
        col = [];
    else
        col = tbl.data(:, idx);
    end
end
