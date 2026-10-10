function applicationState = changeChannel(applicationState, channel, callbackContext)
%CHANGECHANNEL Select a decoded channel and clear analysis from the old one.
if isempty(applicationState.session.cache.recording) || applicationState.session.importDirty, return; end
applicationState.session.cache.signal = ecg_print.sourceFiles.channelSignal( ...
    applicationState.session.cache.recording,string(channel),applicationState.project.parameters);
applicationState.project.parameters.channel = string(channel);
applicationState = ecg_print.analysisRun.resetRange(applicationState);
applicationState = ecg_print.analysisRun.clearAnalysis(applicationState);
applicationState.session.analysisStatus = "Ready to analyze.";
callbackContext.log("info","ecg_print.analysisrun.channel.changed","Selected a recording channel.");
end
