function applicationState = changeTool( ...
        applicationState, toolKind, callbackContext)
%CHANGETOOL Select one enhancement draft and its default values.
toolKind = string(toolKind);
if ~isscalar(toolKind) || ...
        ~any(toolKind == ...
        string(image_enhance.enhancementPipeline.toolKinds()))
    callbackContext.appendStatus("Ignored an unsupported enhancement tool.");
    return;
end
defaults = image_enhance.analysisRun.defaultStepValues(toolKind);
applicationState.session.view.toolKind = toolKind;
applicationState.session.view.toolAmount = defaults.amount;
applicationState.session.view.toolSecondary = defaults.secondary;
applicationState.session.view.roiEditing = false;
applicationState.session.workflow.pendingDirty = true;
applicationState = ...
    image_enhance.enhancementPipeline.invalidateResults(applicationState);
applicationState.session.cache.previewResult = [];
applicationState.session.cache.previewResultKey = "";
applicationState = ...
    image_enhance.enhancementPipeline.rebuildPreview(applicationState);
end
