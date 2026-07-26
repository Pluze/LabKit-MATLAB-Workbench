% App-owned implementation for dic_preprocess.analysisRun.cancelCropRoi within the dic_preprocess product workflow.
function applicationState = cancelCropRoi( ...
        applicationState, callbackContext)
if applicationState.session.workflow.mode ~= "crop"
    return
end
applicationState = dic_preprocess.analysisRun.stopEditors(applicationState);
callbackContext.log("info", "dic_preprocess.analysisrun.cancelcroproi.status", "Crop ROI cancelled.");
end
