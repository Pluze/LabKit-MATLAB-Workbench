function applicationState = cancelCropRoi( ...
        applicationState, callbackContext)
if applicationState.session.workflow.mode ~= "crop"
    return
end
applicationState = dic_preprocess.analysisRun.stopEditors(applicationState);
callbackContext.appendStatus("Crop ROI cancelled.");
end
