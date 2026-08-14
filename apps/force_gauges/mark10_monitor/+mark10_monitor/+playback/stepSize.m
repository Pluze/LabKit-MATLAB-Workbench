function count = stepSize(sampleCount)
%STEPSIZE Return samples per frame for an approximately ten-second replay.
arguments
    sampleCount (1, 1) double {mustBeInteger, mustBeNonnegative}
end
targetFrames = 10 / mark10_monitor.viewRefreshPeriod();
count = max(1, ceil(sampleCount / targetFrames));
end
