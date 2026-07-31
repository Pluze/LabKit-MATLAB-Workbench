% App-owned implementation for image_enhance.enhancementPipeline.changeAmount within the image_enhance product workflow.
function applicationState = changeAmount( ...
        applicationState, value, ~)
%CHANGEAMOUNT Update and preview the primary tool parameter.
defaults = image_enhance.analysisRun.defaultStepValues( ...
    applicationState.session.view.toolKind);
applicationState.session.view.toolAmount = finiteClampedValue( ...
    value, defaults.amount, defaults.amountLimits);
applicationState = draftChanged(applicationState);
end

function applicationState = draftChanged(applicationState)
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
