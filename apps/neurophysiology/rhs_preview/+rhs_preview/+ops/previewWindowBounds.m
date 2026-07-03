% Expected caller: rhs_preview.actions.table and preview-window ops. Input is app
% state. Output summarizes indexed duration and legal interactive window
% bounds without modifying state.
function bounds = previewWindowBounds(S)
%PREVIEWWINDOWBOUNDS Summarize preview-window timing bounds.

    index = struct();
    if isstruct(S) && isfield(S, "index") && isstruct(S.index)
        index = S.index;
    end

    durationSec = 0;
    hasIndexedDuration = isfield(index, "durationSec") && ...
        isfinite(index.durationSec) && index.durationSec > 0;
    if hasIndexedDuration
        durationSec = double(index.durationSec);
    end

    sampleRateHz = rhs_preview.ops.sampleRateFromIndex(index);
    if isfinite(sampleRateHz) && sampleRateHz > 0
        minDurationSec = max(0.001, 50 ./ sampleRateHz);
    else
        minDurationSec = 0.001;
    end

    windowDurationSec = eps;
    if isstruct(S) && isfield(S, "windowDurationSec")
        candidate = double(S.windowDurationSec);
        if isscalar(candidate) && isfinite(candidate)
            windowDurationSec = max(candidate, eps);
        end
    end

    bounds = struct( ...
        "hasIndexedDuration", hasIndexedDuration, ...
        "durationSec", durationSec, ...
        "minDurationSec", minDurationSec, ...
        "maxStartSec", max(0, durationSec - windowDurationSec));
end
