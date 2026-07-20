% App-owned implementation for image_match.matchPipeline.undo within the image_match product workflow.
function applicationState = undo(applicationState, callbackContext)
%UNDO Remove the most recent match step.
steps = applicationState.project.annotations.steps;
if isempty(steps)
    return
end
steps = steps(:);
removed = steps(end);
steps(end) = [];
steps = steps(:);
applicationState.project.annotations.steps = steps;
applicationState.session.workflow.pendingDirty = false;
applicationState = ...
    image_match.matchPipeline.invalidateResults(applicationState);
applicationState.session.cache = image_match.matchPipeline.refreshPreview( ...
    applicationState.session.cache, steps);
callbackContext.appendStatus( ...
    "Undid match step: " + string(removed.label));
end
