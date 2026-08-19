% Expected caller: ecg_print direct callbacks and direct unit tests. Inputs are a
% biosignal recording struct and parsed channel count. Output is user-facing
% status text. Side effects: none.

function text = importStatusText(recording, channelCount)
%IMPORTSTATUSTEXT Format ECG Print recording import status text.

    meta = recording.metadata;
    pieces = strings(1, 0);
    pieces(end+1) = sprintf('%d channel(s)', channelCount);
    if isfield(meta, 'detectedFormat')
        pieces(end+1) = "format: " + string(meta.detectedFormat);
    end
    if isfield(meta, 'importFallbackUsed') && meta.importFallbackUsed
        pieces(end+1) = "parser fallback used";
    end
    if isfield(meta, 'timeColumn') && strlength(string(meta.timeColumn)) > 0
        pieces(end+1) = "time: " + string(meta.timeColumn);
    end
    if isfield(meta, 'timeUnit')
        pieces(end+1) = "unit: " + string(meta.timeUnit);
    end
    if isfield(meta, 'timeSource')
        pieces(end+1) = "source: " + string(meta.timeSource);
    end
    if isfield(meta, 'timeRepair')
        repair = meta.timeRepair;
        if isfield(repair, 'repairedBackwardCount') && repair.repairedBackwardCount > 0
            pieces(end+1) = sprintf('repaired backward: %d', repair.repairedBackwardCount);
        end
        if isfield(repair, 'largeGapCount') && repair.largeGapCount > 0
            pieces(end+1) = sprintf('large gaps: %d', repair.largeGapCount);
        end
    end
    if isfield(meta, 'samplingNormalization') && meta.samplingNormalization.enabled
        normalization = meta.samplingNormalization;
        pieces(end+1) = "uniform sampling";
        if normalization.resampledChannelCount > 0
            pieces(end+1) = sprintf('resampled: %d', ...
                normalization.resampledChannelCount);
        end
        if normalization.compressedGapCount > 0
            pieces(end+1) = sprintf('compressed gaps: %d', ...
                normalization.compressedGapCount);
        end
        if isfield(normalization, 'removedNonfiniteTimeCount') && ...
                normalization.removedNonfiniteTimeCount > 0
            pieces(end+1) = sprintf('removed invalid times: %d', ...
                normalization.removedNonfiniteTimeCount);
        end
        if isfield(normalization, 'removedDuplicateTimeCount') && ...
                normalization.removedDuplicateTimeCount > 0
            pieces(end+1) = sprintf('removed duplicate times: %d', ...
                normalization.removedDuplicateTimeCount);
        end
    end
    text = char(strjoin(pieces, ' | '));
end
