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
