function state = changeChannel(state, channel, context)
channel = string(channel);
if channel == "(none)" || isempty(state.session.cache.recording), return; end
try
    signal = labkit.biosignal.getChannel(state.session.cache.recording, channel);
catch ME
    context.reportError("Channel selection", ME); context.alert(ME.message, "Channel selection"); return;
end
state.project.parameters.channel = channel; state.project.parameters.roiStart = 0; state.project.parameters.roiEnd = max(signal.time);
state.session.cache.signal = signal; state.session.cache.workingSignal = signal;
end
