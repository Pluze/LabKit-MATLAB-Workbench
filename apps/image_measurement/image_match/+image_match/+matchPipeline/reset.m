function applicationState = reset(applicationState, callbackContext)
%RESET Clear every saved match step.
steps = repmat(image_match.analysisRun.emptyStep(), 0, 1);
applicationState.project.annotations.steps = steps;
applicationState.session.workflow.pendingDirty = false;
applicationState = ...
    image_match.matchPipeline.invalidateResults(applicationState);
applicationState.session.cache = image_match.matchPipeline.refreshPreview( ...
    applicationState.session.cache, steps);
callbackContext.appendStatus("Reset match history.");
end
