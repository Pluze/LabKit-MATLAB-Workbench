% App-owned implementation for image_enhance.enhancementPipeline.reset within the image_enhance product workflow.
function applicationState = reset(applicationState, callbackContext)
%RESET Clear the shared or selected per-image history.
if isempty(image_enhance.analysisRun.activeSteps(applicationState))
    return;
end
applicationState = image_enhance.analysisRun.setActiveSteps( ...
    applicationState, ...
    repmat(image_enhance.analysisRun.emptyStep(), 0, 1));
applicationState.session.workflow.pendingDirty = false;
applicationState.session.view.roiEditing = false;
applicationState = ...
    image_enhance.enhancementPipeline.invalidateResults(applicationState);
applicationState.session.cache.previewResult = [];
applicationState.session.cache.previewResultKey = "";
applicationState = ...
    image_enhance.enhancementPipeline.rebuildPreview(applicationState);
callbackContext.appendStatus("Reset enhancement history.");
end
