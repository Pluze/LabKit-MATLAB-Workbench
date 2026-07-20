% App-owned implementation for dic_preprocess.maskEditing.changeBoundaryPoints within the dic_preprocess product workflow.
function applicationState = changeBoundaryPoints( ...
        applicationState, points, ~)
if applicationState.session.workflow.mode ~= "mask"
    return
end
applicationState.project.annotations.maskPoints = double(points);
applicationState.session.workflow.details = ...
    dic_preprocess.maskEditing.maskDraftDetails(double(points));
end
