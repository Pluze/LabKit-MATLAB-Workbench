% App-owned implementation for gait_analysis.stepPreview.previous within the gait_analysis product workflow.
function applicationState = previous(applicationState, ~)
%PREVIOUS Select the preceding detected gait step.
applicationState.session.selection.currentStepIndex = ...
    gait_analysis.stepPreview.boundedIndex(applicationState, ...
        applicationState.session.selection.currentStepIndex - 1);
end
