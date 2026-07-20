% App-owned implementation for ecg_print.analysisRun.changeChannel within the ecg_print product workflow.
function applicationState = changeChannel( ...
        applicationState, channel, callbackContext)
%CHANGECHANNEL Adopt one decoded channel and invalidate dependent products.
channel = string(channel);
if channel == "(none)" || ...
        isempty(applicationState.session.cache.recording)
    return;
end
try
    signal = labkit.biosignal.getChannel( ...
        applicationState.session.cache.recording, channel);
catch ME
    callbackContext.reportError("Channel selection", ME);
    callbackContext.alert(ME.message, "Channel selection failed");
    return;
end
applicationState.project.parameters.channel = channel;
applicationState.project.parameters.roiStart = 0;
applicationState.project.parameters.roiEnd = max(signal.time);
applicationState.session.cache.signal = signal;
applicationState.session.cache.workingSignal = signal;
applicationState.session.cache.filteredSignal = [];
applicationState.session.cache.events = [];
applicationState.session.cache.segments = [];
applicationState.session.cache.template = [];
applicationState.session.cache.measurements = [];
applicationState.project.results.lastAnalysis = struct();
applicationState.project.results.lastSegmentExport = [];
applicationState.project.results.lastWaveformExport = [];
callbackContext.appendStatus("Selected channel: " + channel);
end
