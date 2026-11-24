function state = disconnectDevice(state, context)
%DISCONNECTDEVICE Stop acquisition and close the Mark-10 connection.
if ~state.session.connection.connected
    return;
end
wasMonitoring = state.session.acquisition.monitoring;
if wasMonitoring
    state = mark10_monitor.acquisition.stopMonitoring(state,context);
end
state.session.connection.connected = false;
context.removeResource("mark10Connection");
state.session.connection.status = "Disconnected; monitoring data retained.";
if wasMonitoring
    state.session.export.status = compose( ...
        "Disconnected: %d valid monitoring samples retained.", ...
        state.session.acquisition.retainedValidCount);
end
end
