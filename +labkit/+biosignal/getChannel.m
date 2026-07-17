function signal = getChannel(recording, channel)
%GETCHANNEL Return one signal from a recording by display name or index.
%
% Usage:
%   signal = labkit.biosignal.getChannel(recording, channel)
%
% Description:
%   Selects one channel from a recording created by
%   labkit.biosignal.readRecording. A numeric channel is interpreted as a
%   1-based index. Text is matched exactly against displayName first and then
%   against the source name. Matching is case-sensitive.
%
%   Use labkit.biosignal.listChannels to obtain the display names presented
%   by the recording. Display names are unique even when source channel names
%   are repeated.
%
% Inputs:
%   recording - Recording structure returned by
%               labkit.biosignal.readRecording.
%   channel - Positive integer index, character vector, or scalar string
%             containing a channel name or display name.
%
% Outputs:
%   signal - Selected signal structure. Its principal fields are time in
%            seconds, values, fs in hertz, name, displayName, unit, and
%            metadata.
%
% Errors:
%   labkit:biosignal:InvalidRecording - recording has no signals field.
%   labkit:biosignal:NoChannels - recording contains no signals.
%   labkit:biosignal:InvalidChannelIndex - numeric index is not an integer
%                                         within the available range.
%   labkit:biosignal:InvalidChannel - channel has an unsupported type.
%   labkit:biosignal:UnknownChannel - no exact name matches channel.
%
% Example:
%   channel = struct('name', "ECG", 'displayName', "ECG", ...
%       'time', [0; 0.01], 'values', [0; 1], 'fs', 100, ...
%       'unit', "mV", 'metadata', struct());
%   recording = struct('signals', channel);
%   signal = labkit.biosignal.getChannel(recording, "ECG");
%
% See also labkit.biosignal.listChannels,
%   labkit.biosignal.readRecording

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
