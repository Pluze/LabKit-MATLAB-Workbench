function applicationState = rebuildPreview(applicationState)
%REBUILDPREVIEW Replay committed history plus the current pending draft.
steps = applicationState.project.annotations.steps;
steps = steps(:);
if applicationState.session.workflow.pendingDirty
    parameters = applicationState.project.parameters;
    steps(end + 1, 1) = image_match.analysisRun.makeStep( ...
        parameters.matchMethod, parameters.matchStrength, ...
        parameters.toneStrength, parameters.colorStrength);
end
applicationState.session.cache = ...
    image_match.matchPipeline.refreshPreview( ...
        applicationState.session.cache, steps);
end
