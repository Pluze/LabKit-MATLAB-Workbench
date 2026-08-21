% App-owned implementation for csc.sourceFiles.reloadSelected within the csc product workflow.
function applicationState = reloadSelected( ...
        applicationState, callbackContext)
%RELOADSELECTED Decode the currently selected portable DTA source again.
selection = applicationState.session.selection.files;
if isempty(selection.Indices)
    return
end
index = selection.Indices(1);
paths = labkit.app.source.paths( ...
    applicationState.project.inputs.sources);
if index > numel(paths)
    return
end
[item, status] = labkit.dta.loadFile(paths(index), "cvct");
if ~status.ok
    callbackContext.alert(status.message, "Reload failed");
    return
end
applicationState.session.cache.items(index) = item;
applicationState.session.selection.currentCurve = ...
    csc.analysisRun.analysisChoices().allCycles;
applicationState.project.results.lastResultsExport = [];
applicationState.project.results.lastVoltageCurrentExport = [];
    callbackContext.log("info", "csc.sourcefiles.reloadselected.status", ...
        "Reloaded the selected source.");
end
