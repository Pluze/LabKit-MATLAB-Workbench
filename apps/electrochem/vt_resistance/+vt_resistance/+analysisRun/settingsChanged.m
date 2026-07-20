% App-owned implementation for vt_resistance.analysisRun.settingsChanged within the vt_resistance product workflow.
function applicationState = settingsChanged( ...
        applicationState, ~, callbackContext)
%SETTINGSCHANGED Recompute every loaded item with shared VT parameters.
items = applicationState.session.cache.items;
if isempty(items)
    applicationState.project.results.lastExport = [];
    return
end
options = vt_resistance.analysisRun.optionsFromParameters( ...
    applicationState.project.parameters);
applicationState.session.cache.items = ...
    vt_resistance.analysisRun.recomputeItems(items, options);
applicationState.project.results.lastExport = [];
callbackContext.appendStatus(sprintf( ...
    "Reanalyzed %d loaded VT file(s).", numel(items)));
end
