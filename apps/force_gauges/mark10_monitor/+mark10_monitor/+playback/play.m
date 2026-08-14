function state = play(state, context)
%PLAY Resume recording playback using original relative timing.
playback = context.getResource("application", "mark10Playback");
count = numel(playback("time_s"));
index = playback("index");
if index >= count
    index = 0;
    playback("index") = 0;
end
time = playback("time_s");
playback("dataStart_s") = time(index + 1);
playback("started") = tic;
replayTimer = timer("ExecutionMode", "fixedSpacing", "BusyMode", "drop", ...
    "Period", 0.02, "TimerFcn", @(~, ~) ...
    mark10_monitor.playback.tick(playback, context));
context.setResource("application", "mark10PlaybackTimer", replayTimer, ...
    @cleanupTimer);
start(replayTimer);
state.session.playback.playing = true;
state.session.playback.status = compose("Replaying sample %d of %d.", ...
    index, count);
end

function cleanupTimer(value)
if isa(value, "timer") && isvalid(value)
    stop(value);
    delete(value);
end
end
