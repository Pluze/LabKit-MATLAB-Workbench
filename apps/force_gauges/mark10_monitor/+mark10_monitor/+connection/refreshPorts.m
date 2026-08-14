function state = refreshPorts(state, ~)
%REFRESHPORTS Refresh serial choices without probing or opening devices.
ports = reshape(labkit.mark10.ports(), 1, []);
state.session.connection.ports = ports;
if isempty(ports)
    state.session.connection.selectedPort = "";
    state.session.connection.status = "No serial ports detected.";
elseif ~any(ports == state.session.connection.selectedPort)
    state.session.connection.selectedPort = ports(1);
    state.session.connection.status = "Select a port and connect.";
end
end
