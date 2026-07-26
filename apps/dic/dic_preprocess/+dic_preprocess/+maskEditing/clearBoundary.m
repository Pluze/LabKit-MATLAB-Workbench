% App-owned implementation for dic_preprocess.maskEditing.clearBoundary within the dic_preprocess product workflow.
function applicationState = clearBoundary( ...
        applicationState, callbackContext)
applicationState.project.annotations.maskPoints = zeros(0, 2);
callbackContext.log("info", "dic_preprocess.maskediting.clearboundary.status", "Cleared mask ROI boundary anchors.");
end
