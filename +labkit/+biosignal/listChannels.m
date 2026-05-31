function names = listChannels(recording)
%LISTCHANNELS Return display names for all channels in a recording.

    validateRecording(recording);
    if isempty(recording.signals)
        names = {};
        return;
    end

    names = cell(1, numel(recording.signals));
    for k = 1:numel(recording.signals)
        names{k} = char(recording.signals(k).displayName);
    end
end

function validateRecording(recording)
    assert(isstruct(recording) && isfield(recording, 'signals'), ...
        'labkit:biosignal:InvalidRecording', ...
        'Recording must be a biosignal recording struct.');
end
