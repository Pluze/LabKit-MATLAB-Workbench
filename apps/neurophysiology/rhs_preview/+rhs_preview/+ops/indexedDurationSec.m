% Expected caller: rhs_preview.run and RHS preview ops. Input is app state.
% Output is indexed RHS duration in seconds, or zero when unavailable.
function durationSec = indexedDurationSec(S)
%INDEXEDDURATIONSEC Return indexed file duration.

    durationSec = 0;
    if rhs_preview.ops.hasIndexedDuration(S)
        durationSec = double(S.index.durationSec);
    end
end
