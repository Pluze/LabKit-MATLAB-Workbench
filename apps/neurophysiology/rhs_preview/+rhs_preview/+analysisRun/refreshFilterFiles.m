% App-owned implementation for rhs_preview.analysisRun.refreshFilterFiles within the rhs_preview product workflow.
function applicationState = refreshFilterFiles( ...
        applicationState, callbackContext)
%REFRESHFILTERFILES Rescan the currently selected RHS filter files.
rows = applicationState.session.cache.filterRows;
if ~istable(rows) || height(rows) == 0
    applicationState.session.workflow.statusMessage = ...
        "Select RHS filter files first.";
    return;
end
try
    rows = rhs_preview.analysisRun.discoverFilterRows( ...
        string(rows.filePath), rows);
catch ME
    callbackContext.reportError("Folder scan failed", ME);
    applicationState.session.workflow.statusMessage = string(ME.message);
    return;
end
applicationState.session.cache.filterRows = rows;
applicationState.project.annotations.filterLabels = string(rows.label);
applicationState.project.annotations.filterComments = string(rows.comment);
sources = applicationState.project.inputs.sources;
mask = string({sources.role}) == "filterRecording";
applicationState.project.annotations.filterSourceIds = ...
    string({sources(mask).id}).';
applicationState.session.workflow.statusMessage = string(sprintf( ...
    "Discovered %d RHS file(s).", height(rows)));
applicationState.session.workflow.lastAction = "Discovered RHS files";
callbackContext.log("info", ...
    "rhs_preview.analysisrun.refreshfilterfiles.completed", ...
    applicationState.session.workflow.statusMessage);
end
