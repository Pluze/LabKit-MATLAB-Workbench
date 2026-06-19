% Expected caller: rhs_preview.run and preview-window ops. Input is app
% state. Output is the latest valid preview-window start time in seconds.
function maxStartSec = maxPreviewStartSec(S)
%MAXPREVIEWSTARTSEC Latest valid preview window start.

    maxStartSec = max(0, rhs_preview.ops.indexedDurationSec(S) - ...
        max(double(S.windowDurationSec), eps));
end
