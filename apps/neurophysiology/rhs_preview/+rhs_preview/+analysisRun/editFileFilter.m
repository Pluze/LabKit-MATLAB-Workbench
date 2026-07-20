function applicationState = editFileFilter( ...
        applicationState, edit, callbackContext)
%EDITFILEFILTER Apply typed label/comment edits and persist their source order.
arguments
    applicationState (1, 1) struct
    edit (1, 1) labkit.app.event.TableCellEdit
    callbackContext (1, 1) labkit.app.CallbackContext
end
rows = rhs_preview.analysisRun.applyFileFilterTableData( ...
    applicationState.session.cache.filterRows, edit.Data);
applicationState.session.cache.filterRows = rows;
applicationState = storeAnnotations(applicationState);
applicationState.session.workflow.statusMessage = "File filter updated.";
applicationState.session.workflow.lastAction = "Updated file filter";
end

function applicationState = storeAnnotations(applicationState)
rows = applicationState.session.cache.filterRows;
applicationState.project.annotations.filterLabels = string(rows.label);
applicationState.project.annotations.filterComments = string(rows.comment);
sources = applicationState.project.inputs.sources;
if isempty(sources)
    applicationState.project.annotations.filterSourceIds = strings(0, 1);
    return;
end
mask = string({sources.role}) == "filterRecording";
applicationState.project.annotations.filterSourceIds = ...
    string({sources(mask).id}).';
end
