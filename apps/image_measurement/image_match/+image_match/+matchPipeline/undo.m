function applicationState = undo(applicationState, callbackContext)
%UNDO Remove the most recent match step.
steps = applicationState.project.annotations.steps;
if isempty(steps)
    return
end
steps(end) = [];
applicationState.project.annotations.steps = steps;
applicationState.session.workflow.pendingDirty = true;
applicationState.session.cache = image_match.matchPipeline.refreshPreview( ...
    applicationState.session.cache, steps);
callbackContext.appendStatus("Undid last match step.");
end
