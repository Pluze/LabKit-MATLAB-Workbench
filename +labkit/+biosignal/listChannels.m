function names = listChannels(recording)
%LISTCHANNELS Return display names for all channels in a recording.
%
% Usage:
%   names = labkit.biosignal.listChannels(recording)
%
% Description:
%   Returns channel display names in recording order. These are the same
%   names accepted by labkit.biosignal.getChannel and are suitable for a
%   list box or drop-down menu. A recording with no signals returns a 1-by-0
%   cell array.
%
% Inputs:
%   recording - Recording structure returned by
%               labkit.biosignal.readRecording.
%
% Outputs:
%   names - 1-by-N cell array of display-name character vectors.
%
% Errors:
%   labkit:biosignal:InvalidRecording - recording is not a structure with a
%                                      signals field.
%
% Example:
%   signals(1).displayName = "ECG";
%   signals(2).displayName = "Respiration";
%   recording = struct('signals', signals);
%   names = labkit.biosignal.listChannels(recording);

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
