% Expected caller: rhs_preview.definitionActions. Inputs are RHS index, channel rows, and
% maximum plotted channels. Output is an adaptive initial preview duration.
function durationSec = suggestedPreviewDurationSec(index, channelRows, maxPreviewChannels)
%SUGGESTEDPREVIEWDURATIONSEC Estimate initial preview window length.

    durationSec = 0.050;
    if ~isstruct(index) || ~isfield(index, "durationSec") || ...
            ~isfinite(index.durationSec) || index.durationSec <= 0
        return;
    end

    fileDurationSec = double(index.durationSec);
    sampleRateHz = rhs_preview.analysisRun.sampleRateFromIndex(index);
    if ~isfinite(sampleRateHz) || sampleRateHz <= 0
        durationSec = min(fileDurationSec, 1.0);
        return;
    end

    channelCount = rhs_preview.analysisRun.selectedChannelCount(channelRows, maxPreviewChannels);
    targetTotalPoints = 600000;
    maxDurationByPoints = targetTotalPoints ./ (sampleRateHz .* channelCount);
    durationSec = min(fileDurationSec, max(0.050, maxDurationByPoints));
    durationSec = niceDurationSec(durationSec, fileDurationSec);
end

function durationSec = niceDurationSec(durationSec, fileDurationSec)
    if durationSec >= fileDurationSec
        durationSec = fileDurationSec;
        return;
    end

    candidates = [0.050 0.100 0.250 0.500 1 2 5 10 20 30 60];
    idx = find(candidates <= durationSec, 1, "last");
    if isempty(idx)
        durationSec = max(0.010, durationSec);
    else
        durationSec = candidates(idx);
    end
end
