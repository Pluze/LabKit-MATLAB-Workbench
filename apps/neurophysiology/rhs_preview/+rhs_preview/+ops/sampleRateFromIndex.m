% Expected caller: RHS preview-window ops. Input is an RHS index struct.
% Output is sample rate in hertz, or NaN when unavailable.
function sampleRateHz = sampleRateFromIndex(index)
%SAMPLERATEFROMINDEX Resolve sample rate from indexed RHS metadata.

    sampleRateHz = NaN;
    if isfield(index, "info") && isstruct(index.info) && ...
            isfield(index.info, "sampleRateHz")
        sampleRateHz = double(index.info.sampleRateHz);
    end
    if (~isfinite(sampleRateHz) || sampleRateHz <= 0) && ...
            isfield(index, "sampleCount") && isfield(index, "durationSec") && ...
            index.durationSec > 0
        sampleRateHz = double(index.sampleCount) ./ double(index.durationSec);
    end
end
