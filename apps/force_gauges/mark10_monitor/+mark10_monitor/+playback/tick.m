function tick(playback, context)
%TICK Advance the replay cursor and coalesce one visible refresh event.
time = playback("time_s");
index = playback("index");
due = playback("dataStart_s") + toc(playback("started"));
while index < numel(time) && time(index + 1) <= due
    index = index + 1;
end
playback("index") = index;
context.postEvent("mark10.playback.refresh", ...
    @mark10_monitor.playback.refreshState);
end
