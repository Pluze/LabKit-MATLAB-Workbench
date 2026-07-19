% App coordinate helper; maps a column count to spreadsheet labels without side effects.
function names = spreadsheetColumnNames(count)
%SPREADSHEETCOLUMNNAMES Return Excel-style labels A, B, ..., AA.
%
% Expected caller: T-Test Wizard table presentation and cell-address
% reporting. count is a nonnegative integer scalar. The output is a
% one-by-count cell array of character vectors. Side effects are none.

    assert(isnumeric(count) && isscalar(count) && isfinite(count) && ...
        count >= 0 && count == fix(count), ...
        'ttest_wizard:InvalidColumnCount', ...
        'Spreadsheet column count must be a nonnegative integer.');
    names = cell(1, double(count));
    for k = 1:double(count)
        names{k} = columnName(k);
    end
end

function name = columnName(index)
    name = "";
    while index > 0
        remainder = mod(index - 1, 26);
        name = string(char(double('A') + remainder)) + name;
        index = floor((index - 1) / 26);
    end
    name = char(name);
end
