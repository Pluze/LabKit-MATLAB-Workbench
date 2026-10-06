function applicationState = changeBoundaryPoints( ...
        applicationState, points, ~)
if applicationState.session.workflow.mode ~= "mask"
    return
end
applicationState.project.annotations.maskPoints = double(points);
applicationState.session.workflow.details = ...
    dic_preprocess.maskEditing.maskDraftDetails(double(points));
end
