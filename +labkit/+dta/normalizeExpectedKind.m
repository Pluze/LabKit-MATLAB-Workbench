function kind = normalizeExpectedKind(kind)
%NORMALIZEEXPECTEDKIND Validate and normalize an expected DTA kind.

    if nargin < 1
        kind = "auto";
        return;
    end

    if ~(ischar(kind) || (isstring(kind) && isscalar(kind)))
        error('labkit:dta:InvalidKind', 'Expected kind must be a character vector or scalar string.');
    end

    kind = lower(strtrim(string(kind)));
    if strlength(kind) == 0
        kind = "auto";
        return;
    end

    allowed = ["auto", "chrono", "eis", "cvct"];
    if ~any(kind == allowed)
        error('labkit:dta:InvalidKind', ...
            'Expected kind must be one of: auto, chrono, eis, cvct.');
    end
end
