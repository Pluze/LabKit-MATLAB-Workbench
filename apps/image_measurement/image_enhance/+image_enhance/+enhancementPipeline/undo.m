% App-owned implementation for image_enhance.enhancementPipeline.undo within the image_enhance product workflow.
function applicationState = undo(applicationState, callbackContext)
%UNDO Remove the newest shared or selected per-image history step.
steps = image_enhance.analysisRun.activeSteps(applicationState);
if isempty(steps)
    return;
end
removed = steps(end);
steps(end) = [];
steps = steps(:);
applicationState = image_enhance.analysisRun.setActiveSteps( ...
    applicationState, steps);
applicationState.session.workflow.pendingDirty = false;
applicationState.session.view.roiEditing = false;
applicationState = ...
    image_enhance.enhancementPipeline.invalidateResults(applicationState);
applicationState.session.cache.previewResult = [];
applicationState.session.cache.previewResultKey = "";
applicationState = ...
    image_enhance.enhancementPipeline.rebuildPreview(applicationState);
callbackContext.log("info", ...
    "image_enhance.enhancementpipeline.undo.completed", ...
    "Undid the latest enhancement step.");
end
