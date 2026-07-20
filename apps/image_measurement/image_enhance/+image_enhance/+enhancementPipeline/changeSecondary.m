% App-owned implementation for image_enhance.enhancementPipeline.changeSecondary within the image_enhance product workflow.
function applicationState = changeSecondary( ...
        applicationState, value, callbackContext)
%CHANGESECONDARY Update and preview the secondary tool parameter.
defaults = image_enhance.analysisRun.defaultStepValues( ...
    applicationState.session.view.toolKind);
applicationState.session.view.toolSecondary = finiteClampedValue( ...
    value, defaults.secondary, defaults.secondaryLimits);
applicationState.session.workflow.pendingDirty = true;
applicationState = ...
    image_enhance.enhancementPipeline.invalidateResults(applicationState);
applicationState.session.cache.previewResult = [];
applicationState.session.cache.previewResultKey = "";
applicationState = ...
    image_enhance.enhancementPipeline.rebuildPreview(applicationState);
end

function value = finiteClampedValue(value, fallback, limits)
value = double(value);
if isempty(value) || ~isscalar(value) || ~isfinite(value)
    value = fallback;
end
value = min(max(value, limits(1)), limits(2));
end
