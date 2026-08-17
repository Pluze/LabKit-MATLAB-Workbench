function state = disconnectDevice(state, context)
%DISCONNECTDEVICE Stop acquisition and close the Mark-10 connection.
if ~state.session.connection.connected
    return;
end
wasMonitoring = state.session.acquisition.monitoring;
buffer = context.getResource("application", "mark10Buffer");
state.session.connection.connected = false;
state.session.acquisition.monitoring = false;
state.session.acquisition.retainedValidCount = sum(buffer("valid"));
context.removeResource("application", "mark10Timer");
context.removeResource("application", "mark10Connection");
state.session.connection.status = "Disconnected; monitoring data retained.";
if wasMonitoring
    state.session.export.status = compose( ...
        "Disconnected: %d valid monitoring samples retained.", ...
        state.session.acquisition.retainedValidCount);
end
end
