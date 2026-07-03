% Expected caller: ecg_print.definitionActions and direct unit tests. Inputs are a
% biosignal recording struct and parsed channel count. Output is user-facing
% status text. Side effects: none.

function text = importStatusText(recording, channelCount)
%IMPORTSTATUSTEXT Format ECG Print recording import status text.

    meta = recording.metadata;
    pieces = strings(1, 0);
    pieces(end+1) = sprintf('%d channel(s)', channelCount);
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
    text = char(strjoin(pieces, ' | '));
end
