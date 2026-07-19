% Expected caller: RHS Preview direct callbacks. Input is app state. Output is a preview
% duration cap that keeps interactive redraws bounded by sample count.
function durationSec = maxInteractivePreviewDurationSec(S)
%MAXINTERACTIVEPREVIEWDURATIONSEC Cap scroll-zoom preview duration.

    bounds = rhs_preview.analysisRun.previewWindowBounds(S);
    fileDurationSec = bounds.durationSec;
    if fileDurationSec <= 0
        durationSec = 1;
        return;
    end

    sampleRateHz = rhs_preview.analysisRun.sampleRateFromIndex(S.index);
    if ~isfinite(sampleRateHz) || sampleRateHz <= 0
        durationSec = fileDurationSec;
        return;
    end
    channelCount = rhs_preview.analysisRun.selectedChannelCount( ...
        S.previewChannelRows, S.maxPreviewChannels);
    durationSec = min(fileDurationSec, 1200000 ./ (sampleRateHz .* channelCount));
    durationSec = max(durationSec, bounds.minDurationSec);
end
