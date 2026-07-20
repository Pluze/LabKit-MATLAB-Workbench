% App-owned implementation for dic_preprocess.maskEditing.clearCanvas within the dic_preprocess product workflow.
function applicationState = clearCanvas(applicationState, callbackContext)
if isempty(applicationState.project.annotations.maskImage)
    return
end
applicationState.project = ...
    dic_preprocess.maskEditing.appendMaskHistory( ...
        applicationState.project, "clear mask canvas");
applicationState.project.annotations.maskImage = [];
applicationState = dic_preprocess.analysisRun.clearResults(applicationState);
callbackContext.appendStatus("Cleared ROI mask canvas.");
end
