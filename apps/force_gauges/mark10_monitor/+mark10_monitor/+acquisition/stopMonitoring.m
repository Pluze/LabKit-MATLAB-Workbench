function state = stopMonitoring(state, context)
%STOPMONITORING Stop live reads while keeping the serial connection open.
if ~state.session.acquisition.monitoring
    return;
end
buffer = context.getResource("application", "mark10Buffer");
context.removeResource("application", "mark10Timer");
state = mark10_monitor.acquisition.refreshState(state, context);
state.session.acquisition.monitoring = false;
state.session.acquisition.retainedValidCount = sum(buffer("valid"));
state.session.connection.status = "Connected; monitoring stopped.";
state.session.export.status = compose( ...
    "Monitoring stopped: %d valid samples retained.", ...
    state.session.acquisition.retainedValidCount);
end
