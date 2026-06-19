% Expected caller: rhs_preview.run and preview-window ops. Input is app
% state. Output is the smallest interactive preview duration in seconds.
function durationSec = minPreviewDurationSec(S)
%MINPREVIEWDURATIONSEC Minimum useful preview duration.

    sampleRateHz = rhs_preview.ops.sampleRateFromIndex(S.index);
    if isfinite(sampleRateHz) && sampleRateHz > 0
        durationSec = max(0.001, 50 ./ sampleRateHz);
    else
        durationSec = 0.001;
    end
end
