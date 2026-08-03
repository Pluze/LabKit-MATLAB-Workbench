% App-owned implementation for gait_analysis.stepPreview.previous within the gait_analysis product workflow.
function applicationState = previous(applicationState, ~)
%PREVIOUS Select the preceding detected gait step.
previous = applicationState.session.selection.currentStepIndex;
selected = ...
    gait_analysis.stepPreview.boundedIndex(applicationState, ...
        applicationState.session.selection.currentStepIndex - 1);
applicationState.session.selection.currentStepIndex = selected;
if selected ~= previous
    applicationState.session.cache.plotViewRevision = ...
        applicationState.session.cache.plotViewRevision + 1;
end
end
