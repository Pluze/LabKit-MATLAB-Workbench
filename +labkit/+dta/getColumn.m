function col = getColumn(tbl, name)
%GETCOLUMN Extract a named column from a parsed DTA table.
%
% Usage:
%   col = labkit.dta.getColumn(tbl, name)
%
% Description:
%   Finds the first header that matches name without regard to letter case and
%   returns the corresponding numeric data column. The function does not
%   convert units or remove NaN values.
%
% Inputs:
%   tbl - Scalar parsed table or curve structure with headers and data fields.
%       data has one column for each element of headers.
%   name - Character vector or string scalar naming the requested header.
%
% Outputs:
%   col - Numeric column vector from tbl.data, or [] when no header matches.
%
% Typical Call:
%   timeSec = labkit.dta.getColumn(item.curve, "T");
%   currentA = labkit.dta.getColumn(item.curve, "Im");

    idx = find(strcmpi(tbl.headers, name), 1);
    if isempty(idx)
        col = [];
    else
        col = tbl.data(:, idx);
    end
end
