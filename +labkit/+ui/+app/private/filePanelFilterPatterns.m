% Private filePanel helper. Expected caller: buildFilePanelControl recursive
% expansion. Input is a normalized or raw file filter. Output is a stable string
% column of concrete glob patterns for dir.
function patterns = filePanelFilterPatterns(filters)
    if ischar(filters) || isstring(filters)
        raw = string(filters);
    elseif iscell(filters)
        raw = string(filters(:, 1));
    else
        raw = "*.*";
    end
    patternParts = cell(numel(raw), 1);
    for k = 1:numel(raw)
        tokens = split(raw(k), ';');
        tokens = strtrim(tokens);
        tokens = tokens(strlength(tokens) > 0);
        patternParts{k} = tokens(:);
    end
    patterns = vertcat(patternParts{:});
    if isempty(patterns)
        patterns = "*.*";
    end
    patterns = unique(patterns, 'stable');
    concretePatterns = patterns(patterns ~= "*.*" & patterns ~= "*");
    if ~isempty(concretePatterns)
        patterns = concretePatterns;
    end
end
