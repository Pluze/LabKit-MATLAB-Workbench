% App-owned implementation for gait_analysis.stepPreview.next within the gait_analysis product workflow.
function applicationState = next(applicationState, ~)
%NEXT Select the following detected gait step.
previous = applicationState.session.selection.currentStepIndex;
selected = ...
    gait_analysis.stepPreview.boundedIndex(applicationState, ...
        applicationState.session.selection.currentStepIndex + 1);
applicationState.session.selection.currentStepIndex = selected;
if selected ~= previous
    applicationState.session.cache.plotViewRevision = ...
        applicationState.session.cache.plotViewRevision + 1;
end
end
