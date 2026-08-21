function state = open(state, context)
%OPEN Load a standard CSV, MESUR gauge LOG, or complete MAT recording.
choice = context.chooseInputFile( ...
    ["*.csv;*.log;*.mat", "Mark-10 recordings"], "");
if choice.Cancelled
    return;
end
filepath = string(choice.Value);
recording = mark10_monitor.playback.readRecording(filepath);
playback = containers.Map("KeyType", "char", "ValueType", "any");
playback("time_s") = recording.Time_s;
playback("force_N") = recording.Force_N;
playback("travel_mm") = recording.Travel_mm;
playback("index") = numel(recording.Time_s);
context.setResource("mark10Playback", playback, []);
state.session.playback.loaded = true;
state.session.playback.playing = false;
state.session.playback.source = filepath;
state = mark10_monitor.analysis.invalidate(state, context, []);
state.session.analysis.dataSource = "Loaded Recording";
state = mark10_monitor.playback.applyCursor( ...
    state, playback, playback("index"));
state = mark10_monitor.livePlots.updateLimits(state, true);
state.session.playback.status = compose( ...
    "Loaded %d samples from %s; complete curve displayed.", ...
    numel(recording.Time_s), string(recording.Format));
end
