% App-owned implementation for dic_preprocess.maskEditing.undoAnchor within the dic_preprocess product workflow.
function applicationState = undoAnchor(applicationState, ~)
if ~isempty(applicationState.project.annotations.maskPoints)
    applicationState.project.annotations.maskPoints(end, :) = [];
end
end
