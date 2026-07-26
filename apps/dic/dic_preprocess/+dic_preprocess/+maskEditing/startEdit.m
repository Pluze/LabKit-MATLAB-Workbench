% App-owned implementation for dic_preprocess.maskEditing.startEdit within the dic_preprocess product workflow.
function applicationState = startEdit(applicationState, callbackContext)
if isempty(applicationState.session.cache.currentReferenceImage)
    callbackContext.alert( ...
        "Load a reference image before editing the ROI mask.", ...
        "Missing reference image");
    return
end
applicationState = dic_preprocess.analysisRun.stopEditors(applicationState);
applicationState.session.workflow.mode = "mask";
applicationState.project.parameters.previewMode = "ROI mask";
applicationState.session.workflow.details = ...
    dic_preprocess.maskEditing.maskDraftDetails( ...
        applicationState.project.annotations.maskPoints);
callbackContext.log("info", "dic_preprocess.maskediting.startedit.status", "Started ROI mask editing.");
end
