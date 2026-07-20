% App-owned implementation for dic_preprocess.analysisRun.stopEditors within the dic_preprocess product workflow.
function applicationState = stopEditors(applicationState)
%STOPEDITORS Leave active registration, crop, and mask interactions.
applicationState.session.workflow.mode = "idle";
applicationState.project.annotations.matchReferencePoints = zeros(0, 2);
applicationState.project.annotations.matchMovingPoints = zeros(0, 2);
end
