% App-owned implementation for image_match.matchPipeline.settingsChanged within the image_match product workflow.
function applicationState = settingsChanged( ...
        applicationState, ~, callbackContext)
%SETTINGSCHANGED Preview one bounded draft without committing history.
parameters = applicationState.project.parameters;
method = string(parameters.matchMethod);
if ~isscalar(method) || ...
        ~any(method == string(image_match.matchPipeline.methods()))
    method = "Balanced";
    callbackContext.log("warning", ...
        "image_match.matchpipeline.settingschanged.repaired", ...
        "Reset an unsupported match method to Balanced.");
end
applicationState.project.parameters.matchMethod = method;
for name = ["matchStrength" "toneStrength" "colorStrength"]
    applicationState.project.parameters.(name) = boundedPercent( ...
        parameters.(name), 100);
end
applicationState.session.workflow.pendingDirty = true;
applicationState = ...
    image_match.matchPipeline.invalidateResults(applicationState);
applicationState = ...
    image_match.matchPipeline.rebuildPreview(applicationState);
end

function value = boundedPercent(value, fallback)
value = double(value);
if isempty(value) || ~isscalar(value) || ~isfinite(value)
    value = double(fallback);
end
if isempty(value) || ~isscalar(value) || ~isfinite(value)
    value = 100;
end
value = min(max(value, 0), 100);
end
