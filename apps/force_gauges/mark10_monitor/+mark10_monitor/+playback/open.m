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
playback("index") = 0;
playback("started") = tic;
playback("dataStart_s") = recording.Time_s(1);
context.setResource("application", "mark10Playback", playback, []);
state.session.playback.loaded = true;
state.session.playback.playing = false;
state.session.playback.source = filepath;
state.session.playback.status = compose("Loaded %d samples from %s.", ...
    numel(recording.Time_s), string(recording.Format));
state.session.acquisition.plotTime_s = zeros(0, 1);
state.session.acquisition.plotForce_N = zeros(0, 1);
state.session.acquisition.plotTravel_mm = zeros(0, 1);
state.session.acquisition.sampleCount = 0;
state.session.acquisition.validCount = 0;
state.session.acquisition.invalidCount = 0;
end
