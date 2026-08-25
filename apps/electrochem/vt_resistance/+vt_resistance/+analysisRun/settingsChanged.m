% App-owned implementation for vt_resistance.analysisRun.settingsChanged within the vt_resistance product workflow.
function applicationState = settingsChanged( ...
        applicationState, ~, ~)
%SETTINGSCHANGED Recompute loaded analysis after one committed parameter edit.
items = applicationState.session.cache.items;
if ~isempty(items)
    options = vt_resistance.analysisRun.optionsFromParameters( ...
        applicationState.project.parameters);
    applicationState.session.cache.items = ...
        vt_resistance.analysisRun.recomputeItems(items, options);
end
applicationState.project.results.lastExport = [];
end
