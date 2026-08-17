function state = startMonitoring(state, context)
%STARTMONITORING Begin live reads on an already connected Mark-10 device.
if ~state.session.connection.connected || state.session.acquisition.monitoring
    return;
end
connectionBox = context.getResource("application", "mark10Connection");
buffer = context.getResource("application", "mark10Buffer");
resetMonitor(buffer);
state = mark10_monitor.acquisition.refreshState(state, context);
monitorTimer = mark10_monitor.acquisition.createTimer( ...
    connectionBox, buffer, context, ...
    mark10_monitor.acquisition.ratePeriod(state.session.acquisition.rate));
context.setResource("application", "mark10Timer", monitorTimer, ...
    @cleanupTimer);
start(monitorTimer);
state.session.acquisition.monitoring = true;
state.session.acquisition.retainedValidCount = 0;
state.session.connection.status = "Connected and monitoring.";
state.session.export.status = "Monitoring in progress; data retained in memory.";
state = mark10_monitor.analysis.invalidate(state, context, []);
state.session.analysis.dataSource = "Live Monitoring";
end

function resetMonitor(buffer)
buffer("started") = tic;
buffer("monitoringStartedAt") = datetime("now");
buffer("time_s") = zeros(0, 1);
buffer("force_N") = zeros(0, 1);
buffer("travel_mm") = zeros(0, 1);
buffer("forceRaw") = zeros(0, 1);
buffer("travelRaw") = zeros(0, 1);
buffer("forceUnit") = strings(0, 1);
buffer("travelUnit") = strings(0, 1);
buffer("valid") = false(0, 1);
buffer("mode") = strings(0, 1);
buffer("plotTime_s") = zeros(0, 1);
buffer("plotForce_N") = zeros(0, 1);
buffer("plotTravel_mm") = zeros(0, 1);
buffer("sampleCount") = 0;
buffer("validCount") = 0;
buffer("invalidCount") = 0;
buffer("lastTime_s") = 0;
buffer("lastForce_N") = NaN;
buffer("lastTravel_mm") = NaN;
buffer("lastFailure") = "";
buffer("lastRefresh_s") = -Inf;
buffer("refreshPending") = false;
end

function cleanupTimer(value)
if isa(value, "timer") && isvalid(value)
    stop(value);
    delete(value);
end
end
