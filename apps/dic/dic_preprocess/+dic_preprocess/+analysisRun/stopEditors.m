function applicationState = stopEditors(applicationState)
%STOPEDITORS Leave active registration, crop, and mask interactions.
applicationState.session.workflow.mode = "idle";
applicationState.project.annotations.matchReferencePoints = zeros(0, 2);
applicationState.project.annotations.matchMovingPoints = zeros(0, 2);
end
