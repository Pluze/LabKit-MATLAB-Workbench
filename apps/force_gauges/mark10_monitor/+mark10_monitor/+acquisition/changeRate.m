function state = changeRate(state, value, context)
%CHANGERATE Update requested rate and an active monitor timer.
state.session.acquisition.rate = string(value);
if state.session.acquisition.monitoring
    monitorTimer = context.getResource("application", "mark10Timer");
    wasRunning = strcmp(monitorTimer.Running, "on");
    if wasRunning, stop(monitorTimer); end
    monitorTimer.Period = mark10_monitor.acquisition.ratePeriod(value);
    if wasRunning, start(monitorTimer); end
end
end
