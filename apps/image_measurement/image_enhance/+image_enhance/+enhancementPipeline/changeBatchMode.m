function applicationState = changeBatchMode( ...
        applicationState, batchMode, callbackContext)
%CHANGEBATCHMODE Switch between shared and per-image history.
applicationState.project.parameters.batchMode = logical(batchMode);
applicationState.session.workflow.pendingDirty = false;
applicationState.session.view.roiEditing = false;
applicationState = ...
    image_enhance.enhancementPipeline.invalidateResults(applicationState);
applicationState.session.cache.previewResult = [];
applicationState.session.cache.previewResultKey = "";
applicationState = ...
    image_enhance.enhancementPipeline.rebuildPreview(applicationState);
if applicationState.project.parameters.batchMode
    callbackContext.appendStatus( ...
        "Enabled shared batch enhancement history.");
else
    callbackContext.appendStatus( ...
        "Enabled per-image enhancement history.");
end
end
