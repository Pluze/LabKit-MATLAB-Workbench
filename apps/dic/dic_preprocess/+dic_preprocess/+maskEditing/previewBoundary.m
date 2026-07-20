% App-owned implementation for dic_preprocess.maskEditing.previewBoundary within the dic_preprocess product workflow.
function applicationState = previewBoundary( ...
        applicationState, callbackContext)
[mask, accepted] = ...
    dic_preprocess.maskEditing.currentBoundaryMask(applicationState);
if accepted
    applicationState.project.annotations.maskImage = mask;
    applicationState.project.parameters.previewMode = "ROI mask";
    callbackContext.appendStatus("Previewed ROI mask boundary.");
elseif ~isempty(applicationState.project.annotations.maskImage)
    applicationState.project.parameters.previewMode = "ROI mask";
else
    callbackContext.alert( ...
        "Mask ROI needs at least three anchors.", "Not enough anchors");
end
end
