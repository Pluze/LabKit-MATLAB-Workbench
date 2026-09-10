function applicationState = refreshDevices(applicationState, context)
%REFRESHDEVICES Discover local NI-DMM resources without opening hardware.
if applicationState.session.connection.connected
    return;
end
status = labkit.nidmm.availability();
applicationState.session.connection.available = status.Available;
if ~status.Available
    applicationState = noDevices(applicationState, status.Message);
    applicationState.session.connection.lastFailure = status.Status;
    return;
end
try
    devices = labkit.nidmm.discover();
    applicationState.session.connection.devices = devices;
    resources = string({devices.Resource});
    if isempty(resources)
        applicationState = noDevices(applicationState, ...
            "No local NI-DMM devices were found. Check NI MAX and the USB connection.");
        return;
    end
    current = applicationState.session.connection.resource;
    if ~any(resources == current)
        current = resources(1);
    end
    applicationState.session.connection.resource = current;
    applicationState.session.connection.status = compose( ...
        "Found %d NI-DMM device(s). Select a device and connect.", ...
        numel(resources));
    applicationState.session.connection.device = discoveredIdentity( ...
        devices(resources == current));
    applicationState.session.connection.lastFailure = "";
catch cause
    applicationState = noDevices(applicationState, "Device discovery failed.");
    applicationState.session.connection.lastFailure = string(cause.message);
    context.log("error", "ni_dmm_recorder.connection.discovery_failed", ...
        "NI-DMM device discovery failed", Category="connection", ...
        Exception=cause);
    context.alert(cause.message, "NI-DMM Discovery");
end
end

function applicationState = noDevices(applicationState, message)
applicationState.session.connection.devices = repmat( ...
    struct("Resource", "", "Model", "", "Bus", ""), 0, 1);
applicationState.session.connection.resource = "";
applicationState.session.connection.status = message;
applicationState.session.connection.device = "Not connected";
end

function value = discoveredIdentity(device)
value = device.Resource;
if strlength(device.Model) > 0
    value = value + " | " + device.Model;
end
if strlength(device.Bus) > 0
    value = value + " | " + device.Bus;
end
end
