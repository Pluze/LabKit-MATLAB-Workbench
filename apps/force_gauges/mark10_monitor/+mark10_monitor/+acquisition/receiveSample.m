function receiveSample(connectionBox, buffer, context, connection, sample)
%RECEIVESAMPLE Retain one background-delivered sample and coalesce its view.
connectionBox("connection") = connection;
if isfield(sample, "HostTime_s") && isfinite(sample.HostTime_s)
    elapsed = double(sample.HostTime_s);
else
    elapsed = toc(buffer("started"));
end
buffer("sampleCount") = buffer("sampleCount") + 1;
buffer("lastTime_s") = elapsed;
if sample.Valid
    buffer("validCount") = buffer("validCount") + 1;
    buffer("lastForce_N") = sample.Force_N;
    buffer("lastTravel_mm") = sample.Travel_mm;
    appendPlot(buffer, elapsed, sample.Force_N, sample.Travel_mm);
    buffer("lastFailure") = "";
else
    buffer("invalidCount") = buffer("invalidCount") + 1;
    buffer("lastFailure") = sample.FailureStatus;
end
buffer("time_s") = [buffer("time_s"); elapsed];
buffer("force_N") = [buffer("force_N"); sample.Force_N];
buffer("travel_mm") = [buffer("travel_mm"); sample.Travel_mm];
buffer("forceRaw") = [buffer("forceRaw"); sample.ForceRawValue];
buffer("travelRaw") = [buffer("travelRaw"); sample.TravelRawValue];
buffer("forceUnit") = [buffer("forceUnit"); string(sample.ForceUnit)];
buffer("travelUnit") = [buffer("travelUnit"); string(sample.TravelUnit)];
buffer("valid") = [buffer("valid"); sample.Valid];
buffer("mode") = [buffer("mode"); string(sample.AcquisitionMode)];
postRefreshIfDue(buffer, elapsed, context);
end

function postRefreshIfDue(buffer, elapsed, context)
if buffer("refreshPending") || ...
        elapsed - buffer("lastRefresh_s") < ...
        mark10_monitor.acquisition.viewRefreshPeriod()
    return;
end
buffer("lastRefresh_s") = elapsed;
buffer("refreshPending") = true;
try
    context.postEvent("mark10.live.refresh", ...
        @mark10_monitor.acquisition.refreshState);
catch cause
    buffer("refreshPending") = false;
    rethrow(cause);
end
end

function appendPlot(buffer, time, force, travel)
maximumPoints = 2000;
t = [buffer("plotTime_s"); time];
f = [buffer("plotForce_N"); force];
x = [buffer("plotTravel_mm"); travel];
first = max(1, numel(t) - maximumPoints + 1);
buffer("plotTime_s") = t(first:end);
buffer("plotForce_N") = f(first:end);
buffer("plotTravel_mm") = x(first:end);
end
