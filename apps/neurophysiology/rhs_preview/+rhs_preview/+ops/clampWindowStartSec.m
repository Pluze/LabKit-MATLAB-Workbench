% Expected caller: rhs_preview.run and preview-window ops. Inputs are a
% requested start time and app state. Output is a valid start time.
function startSec = clampWindowStartSec(startSec, S)
%CLAMPWINDOWSTARTSEC Clamp preview start into indexed file bounds.

    startSec = double(startSec);
    if ~isfinite(startSec)
        startSec = 0;
    end
    startSec = min(rhs_preview.ops.maxPreviewStartSec(S), max(0, startSec));
end
