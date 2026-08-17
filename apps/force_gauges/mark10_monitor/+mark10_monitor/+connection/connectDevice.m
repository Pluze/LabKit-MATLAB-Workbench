function state = connectDevice(state, context)
%CONNECTDEVICE Open and probe the selected device without starting reads.
port = state.session.connection.selectedPort;
if strlength(port) == 0
    context.alert("Select a serial port first.", "Mark-10 Connection");
    return;
end
connectionInstalled = false;
try
    connection = labkit.mark10.connect(port);
    connectionBox = containers.Map("KeyType", "char", "ValueType", "any");
    connectionBox("connection") = connection;
    context.setResource("application", "mark10Connection", connectionBox, ...
        @cleanupConnection);
    connectionInstalled = true;
    state.session.connection.connected = true;
    state.session.connection.status = "Connected; monitoring stopped.";
    state.session.connection.identity = identityText(connection.Identity);
    state.session.connection.capabilities = ...
        capabilitiesText(connection.Capabilities);
    state.session.connection.acquisitionMode = connection.AcquisitionMode;
    state = mark10_monitor.settings.copyReadback( ...
        state, connection.Settings);
catch cause
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
