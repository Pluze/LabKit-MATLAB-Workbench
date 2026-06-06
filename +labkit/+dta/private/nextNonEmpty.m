% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function idx = nextNonEmpty(lines, startIdx)
%NEXTNONEMPTY Return the next non-blank line index from a parser line list.
%
% Inputs:
%   lines - cell array of line text.
%   startIdx - 1-based index where scanning begins.
%
% Output:
%   idx - first index whose trimmed line is non-empty, or NaN when no such
%         line exists.

    idx = NaN;
    for i = startIdx:numel(lines)
        if ~isempty(strtrim(lines{i}))
            idx = i;
            return;
        end
    end
end
