function applicationState = cancelCropRoi( ...
        applicationState, callbackContext)
if applicationState.session.workflow.mode ~= "crop"
    return
end
applicationState = dic_preprocess.analysisRun.stopEditors(applicationState);
callbackContext.log("info", "dic_preprocess.analysisrun.cancelcroproi.status", "Crop ROI cancelled.");
end
