% App-owned implementation for dic_preprocess.analysisRun.resetToOriginals within the dic_preprocess product workflow.
function applicationState = resetToOriginals( ...
        applicationState, callbackContext)
cache = applicationState.session.cache;
if isempty(cache.referenceImage) || isempty(cache.movingImage)
    callbackContext.alert( ...
        "Load both images before resetting the working pair.", "Reset");
    return
end
applicationState.project = ...
    dic_preprocess.editHistory.appendEditHistory( ...
        applicationState.project, "reset to originals");
applicationState.project = ...
    dic_preprocess.editHistory.resetToOriginals(applicationState.project);
applicationState = dic_preprocess.analysisRun.rebuildCache(applicationState);
applicationState = dic_preprocess.analysisRun.stopEditors(applicationState);
applicationState.project.parameters.previewMode = "Current pair";
applicationState.session.workflow.details = {'Restored original image pair.'};
applicationState = dic_preprocess.analysisRun.clearResults(applicationState);
callbackContext.log("info", "dic_preprocess.analysisrun.resettooriginals.status", "Reset the working pair to originals.");
end
