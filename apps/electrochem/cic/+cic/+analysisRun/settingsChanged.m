function applicationState = settingsChanged( ...
        applicationState, ~, callbackContext)
%SETTINGSCHANGED Recompute every loaded CIC item with current parameters.
items = applicationState.session.cache.items;
if isempty(items)
    applicationState.project.results.lastExport = [];
    return
end
applicationState.session.cache.items = ...
    cic.analysisRun.recomputeLoaded( ...
        items, applicationState.project.parameters);
applicationState.project.results.lastExport = [];
callbackContext.appendStatus(sprintf( ...
    "Reanalyzed %d loaded CIC file(s).", numel(items)));
end
