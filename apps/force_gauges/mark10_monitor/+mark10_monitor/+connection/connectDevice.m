function state = connectDevice(state, context)
%CONNECTDEVICE Open the selected device and begin non-motion monitoring.
port = state.session.connection.selectedPort;
if strlength(port) == 0
    context.alert("Select a serial port first.", "Mark-10 Connection");
    return;
end
connectionInstalled = false;
timerInstalled = false;
try
    connection = labkit.mark10.connect(port);
    connectionBox = containers.Map("KeyType", "char", "ValueType", "any");
    connectionBox("connection") = connection;
    context.setResource("application", "mark10Connection", connectionBox, ...
        @cleanupConnection);
    connectionInstalled = true;
    buffer = context.getResource("application", "mark10Buffer");
    resetMonitor(buffer);
    monitorTimer = timer( ...
        "ExecutionMode", "fixedSpacing", ...
        "BusyMode", "drop", ...
        "Period", mark10_monitor.acquisition.ratePeriod( ...
            state.session.acquisition.rate), ...
        "TimerFcn", @(~, ~) mark10_monitor.acquisition.poll( ...
            connectionBox, buffer, context));
    context.setResource("application", "mark10Timer", monitorTimer, ...
        @cleanupTimer);
    timerInstalled = true;
    start(monitorTimer);
    state.session.connection.connected = true;
    state.session.connection.status = "Connected and monitoring.";
    state.session.connection.identity = identityText(connection.Identity);
    state.session.connection.capabilities = ...
        capabilitiesText(connection.Capabilities);
    state.session.connection.acquisitionMode = connection.AcquisitionMode;
    state = mark10_monitor.settings.copyReadback( ...
        state, connection.Settings);
catch cause
    if timerInstalled
        context.removeResource("application", "mark10Timer");
    end
    if connectionInstalled
        context.removeResource("application", "mark10Connection");
    end
    state.session.connection.connected = false;
    state.session.connection.status = "Connection failed.";
    state.session.connection.lastFailure = string(cause.message);
    context.alert(cause.message, "Mark-10 Connection");
end
end

function cleanupConnection(box)
if isa(box, "containers.Map") && isKey(box, "connection")
    labkit.mark10.disconnect(box("connection"));
end
end

function cleanupTimer(value)
if isa(value, "timer") && isvalid(value)
    stop(value);
    delete(value);
end
end

function resetMonitor(buffer)
buffer("started") = tic;
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
end

function text = identityText(identity)
parts = [identity.Product, identity.Model, identity.Firmware];
parts = parts(strlength(parts) > 0);
if isempty(parts), text = "Identity unavailable; data protocol active.";
else, text = join(parts, " | "); end
end

function text = capabilitiesText(capabilities)
names = string(fieldnames(capabilities));
parts = strings(1, numel(names));
for index = 1:numel(names)
    parts(index) = names(index) + ": " + ...
        string(capabilities.(char(names(index))));
end
text = join(parts, newline);
end
