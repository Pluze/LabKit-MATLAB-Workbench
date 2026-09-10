function applicationState = connectDevice(applicationState, context)
%CONNECTDEVICE Open the configured NI MAX resource without starting reads.
if applicationState.session.connection.connected
    return;
end
installed = false;
try
    connection = labkit.nidmm.connect( ...
        applicationState.session.connection.resource);
    box = containers.Map("KeyType", "char", "ValueType", "any");
    box("connection") = connection;
    context.setResource("nidmmConnection", box, @cleanupConnection);
    installed = true;
    applicationState.session.connection.connected = true;
    applicationState.session.connection.available = true;
    applicationState.session.connection.device = ...
        connection.Model + " | NI-DMM " + connection.DriverVersion;
    applicationState.session.connection.status = ...
        "Connected; recording stopped.";
    applicationState.session.connection.lastFailure = "";
catch cause
    if installed
        context.removeResource("nidmmConnection");
    end
    applicationState.session.connection.connected = false;
    applicationState.session.connection.status = "Connection failed.";
    applicationState.session.connection.lastFailure = string(cause.message);
    context.log("error", "ni_dmm_recorder.connection.failed", ...
        "NI-DMM connection failed", Category="connection", ...
        Exception=cause);
    context.alert(cause.message, "NI-DMM Connection");
end
end

function cleanupConnection(box)
if isa(box, "containers.Map") && isKey(box, "connection")
    labkit.nidmm.disconnect(box("connection"));
end
end
