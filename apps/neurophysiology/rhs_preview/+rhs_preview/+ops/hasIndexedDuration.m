% Expected caller: rhs_preview.run and RHS preview ops. Input is app state.
% Output indicates whether indexed RHS duration is usable.
function tf = hasIndexedDuration(S)
%HASINDEXEDDURATION True when state has a positive indexed duration.

    tf = isstruct(S) && isfield(S, "index") && isstruct(S.index) && ...
        isfield(S.index, "durationSec") && isfinite(S.index.durationSec) && ...
        S.index.durationSec > 0;
end
