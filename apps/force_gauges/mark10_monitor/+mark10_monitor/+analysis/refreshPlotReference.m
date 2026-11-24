function applicationState = refreshPlotReference(applicationState, event, context)
%CHANGEEXPERIMENTTYPE Refresh shared coordinates after test or exclusion changes.
applicationState = mark10_monitor.analysis.invalidateReference(applicationState,context,event);
applicationState = mark10_monitor.analysis.reprojectPlots(applicationState,context);
end
