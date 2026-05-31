function signal = getChannel(recording, channel)
%GETCHANNEL Return one signal from a recording by display name or index.
%
% Usage:
%   signal = labkit.biosignal.getChannel(recording, 1);
%   signal = labkit.biosignal.getChannel(recording, 'ECG');
%
% Inputs:
%   recording - struct returned by readRecording.
%   channel - 1-based numeric index, channel name, or display name.
%
% Output:
%   signal - one signal struct with time, values, fs, name, displayName,
%            and metadata.

    if ~isstruct(recording) || ~isfield(recording, 'signals')
        error('labkit:biosignal:InvalidRecording', ...
            'Recording must be a biosignal recording struct.');
    end
    if isempty(recording.signals)
        error('labkit:biosignal:NoChannels', ...
            'Recording does not contain numeric biosignal channels.');
    end

    if isnumeric(channel)
        idx = channel;
        if ~isscalar(idx) || idx < 1 || idx > numel(recording.signals) || idx ~= floor(idx)
            error('labkit:biosignal:InvalidChannelIndex', ...
                'Channel index is out of range.');
        end
        signal = recording.signals(idx);
        return;
    end

    if ~(ischar(channel) || (isstring(channel) && isscalar(channel)))
        error('labkit:biosignal:InvalidChannel', ...
            'Channel must be an index, character vector, or scalar string.');
    end

    channel = string(channel);
    displayNames = string({recording.signals.displayName});
    idx = find(strcmp(displayNames, channel), 1);
    if isempty(idx)
        rawNames = string({recording.signals.name});
        idx = find(strcmp(rawNames, channel), 1);
    end
    if isempty(idx)
        error('labkit:biosignal:UnknownChannel', ...
            'Unknown biosignal channel: %s.', channel);
    end
    signal = recording.signals(idx);
end
