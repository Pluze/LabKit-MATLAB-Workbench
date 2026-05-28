function s = csvEscape(x)
%CSVESCAPE Escape double quotes for CSV text fields.

    s = strrep(char(x), '"', '""');
end
