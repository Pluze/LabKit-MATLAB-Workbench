% Expected callers: App SDK session creation and ECG actions. Inputs are a
% recording path, durable import parameters, and preferred channel. Outputs
% are the decoded session cache and app-facing import status.
function [cache, importStatus] = loadRecording(filepath, parameters, preferredChannel)
    options = ecg_print.sourceFiles.importOptions( ...
        parameters.fallbackFs, parameters.headerLine, parameters.hasHeader, ...
        parameters.timeColumn, parameters.timeUnit, parameters.signalColumns);
    [recording, status] = labkit.biosignal.readRecording(char(filepath), options);
    if ~status.ok
        error('ecg_print:ParseFailed', '%s', status.message);
    end
    channels = labkit.biosignal.listChannels(recording);
    if isempty(channels)
        error('ecg_print:NoChannels', ...
            'No numeric signal channels were found.');
    end
    channel = string(channels{1});
    if any(string(channels) == string(preferredChannel))
        channel = string(preferredChannel);
    end
    signal = ecg_print.sourceFiles.channelSignal(recording, channel, parameters);
    cache = ecg_print.sourceFiles.emptyCache();
    cache.filepath = string(filepath); cache.recording = recording;
    cache.signal = signal; cache.workingSignal = signal;
    cache.channelItems = channels;
    importStatus = ecg_print.sourceFiles.importStatusText( ...
        recording, numel(channels));
end
