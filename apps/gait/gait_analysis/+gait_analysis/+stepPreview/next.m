% App-owned implementation for gait_analysis.stepPreview.next within the gait_analysis product workflow.
function applicationState = next(applicationState, ~)
%NEXT Select the following detected gait step.
applicationState.session.selection.currentStepIndex = ...
    gait_analysis.stepPreview.boundedIndex(applicationState, ...
        applicationState.session.selection.currentStepIndex + 1);
end
