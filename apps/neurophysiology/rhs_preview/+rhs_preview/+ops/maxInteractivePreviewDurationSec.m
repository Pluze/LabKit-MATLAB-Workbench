% Expected caller: rhs_preview.run. Input is app state. Output is a preview
% duration cap that keeps interactive redraws bounded by sample count.
function durationSec = maxInteractivePreviewDurationSec(S)
%MAXINTERACTIVEPREVIEWDURATIONSEC Cap scroll-zoom preview duration.

    fileDurationSec = rhs_preview.ops.indexedDurationSec(S);
    if fileDurationSec <= 0
        durationSec = 1;
        return;
    end

    sampleRateHz = rhs_preview.ops.sampleRateFromIndex(S.index);
    if ~isfinite(sampleRateHz) || sampleRateHz <= 0
        durationSec = fileDurationSec;
        return;
    end
    channelCount = rhs_preview.ops.selectedChannelCount( ...
        S.previewChannelRows, S.maxPreviewChannels);
    durationSec = min(fileDurationSec, 1200000 ./ (sampleRateHz .* channelCount));
    durationSec = max(durationSec, rhs_preview.ops.minPreviewDurationSec(S));
end
