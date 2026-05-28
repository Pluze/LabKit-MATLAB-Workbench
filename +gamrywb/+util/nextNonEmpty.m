function idx = nextNonEmpty(lines, startIdx)
%NEXTNONEMPTY Return the next non-blank line index, or NaN.

    idx = NaN;
    for i = startIdx:numel(lines)
        if ~isempty(strtrim(lines{i}))
            idx = i;
            return;
        end
    end
end
