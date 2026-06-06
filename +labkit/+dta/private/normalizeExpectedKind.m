% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function kind = normalizeExpectedKind(kind)
%NORMALIZEEXPECTEDKIND Validate and normalize a private DTA kind argument.
%
% Called by:
%   loadFile, loadFiles, loadFolder, and addFilesToSession.
%
% Inputs:
%   kind - char vector or scalar string. Missing or blank means "auto".
%
% Output:
%   kind - lowercase string scalar: "auto", "chrono", "eis", or "cvct".
%
% Errors:
%   labkit:dta:InvalidKind for non-scalar/non-text input or unsupported
%   expected kinds.

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
