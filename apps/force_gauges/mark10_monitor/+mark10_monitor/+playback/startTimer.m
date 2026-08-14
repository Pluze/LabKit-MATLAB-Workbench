function startTimer(playback, context)
%STARTTIMER Install the bounded fixed-speed replay timer.
replayTimer = timer("ExecutionMode", "fixedSpacing", "BusyMode", "drop", ...
    "Period", mark10_monitor.playback.framePeriod(), ...
    "StartDelay", mark10_monitor.playback.framePeriod(), ...
    "TimerFcn", @(~, ~) ...
    mark10_monitor.playback.tick(playback, context));
context.setResource("application", "mark10PlaybackTimer", replayTimer, ...
    @cleanupTimer);
start(replayTimer);
end

function cleanupTimer(value)
if isa(value, "timer") && isvalid(value)
    stop(value);
    delete(value);
end
end
