function tick(playback, context)
%TICK Advance by one fixed visual frame, independent of recorded timing.
index = playback("index");
count = numel(playback("time_s"));
index = min(count, index + mark10_monitor.playback.stepSize(count));
playback("index") = index;
context.postEvent("mark10.playback.refresh", ...
    @mark10_monitor.playback.refreshState);
end
