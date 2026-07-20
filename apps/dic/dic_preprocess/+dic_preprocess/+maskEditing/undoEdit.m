% App-owned implementation for dic_preprocess.maskEditing.undoEdit within the dic_preprocess product workflow.
function applicationState = undoEdit(applicationState, callbackContext)
history = applicationState.project.annotations.maskHistory;
if isempty(history)
    return
end
snapshot = history(end);
applicationState.project.annotations.maskHistory(end) = [];
applicationState.project = ...
    dic_preprocess.maskEditing.restoreMaskSnapshot( ...
        applicationState.project, snapshot);
applicationState.project.parameters.previewMode = "ROI mask";
applicationState = dic_preprocess.analysisRun.clearResults(applicationState);
callbackContext.appendStatus( ...
    "Undid mask edit: " + string(snapshot.description) + ".");
end
