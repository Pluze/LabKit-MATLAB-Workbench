% App-owned implementation for cic.analysisRun.settingsChanged within the cic product workflow.
function applicationState = settingsChanged( ...
        applicationState, ~, ~)
%SETTINGSCHANGED Recompute loaded analysis after one committed parameter edit.
items = applicationState.session.cache.items;
if ~isempty(items)
    applicationState.session.cache.items = ...
        cic.analysisRun.recomputeLoaded( ...
            items, applicationState.project.parameters);
end
applicationState.project.results.lastExport = [];
end
