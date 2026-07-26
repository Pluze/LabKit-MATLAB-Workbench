% App-owned implementation for rhs_preview.sourceFiles.filterChanged within the rhs_preview product workflow.
function applicationState = filterChanged( ...
        applicationState, selection, callbackContext)
%FILTERCHANGED Persist label/comment ordering after bound source changes.
arguments
    applicationState (1, 1) struct
    selection (1, 1) labkit.app.event.ListSelection
    callbackContext (1, 1) labkit.app.CallbackContext
end
rows = applicationState.session.cache.filterRows;
if ~istable(rows) || height(rows) == 0
    applicationState.project.annotations.filterLabels = strings(0, 1);
    applicationState.project.annotations.filterComments = strings(0, 1);
    applicationState.project.annotations.filterSourceIds = strings(0, 1);
    applicationState.session.workflow.statusMessage = ...
        "No RHS folder selected.";
    applicationState.session.workflow.lastAction = ...
        "Cleared RHS filter files";
    if isempty(selection.Indices)
        callbackContext.log("info", ...
            "rhs_preview.sourcefiles.filterchanged.cleared", ...
            "Cleared RHS filter files.");
    end
    return;
end
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
    "rhs_preview.sourcefiles.filterchanged.completed", ...
    applicationState.session.workflow.statusMessage);
end
