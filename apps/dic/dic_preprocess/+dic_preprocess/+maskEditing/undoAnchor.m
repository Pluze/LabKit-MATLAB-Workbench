function applicationState = undoAnchor(applicationState, ~)
if ~isempty(applicationState.project.annotations.maskPoints)
    applicationState.project.annotations.maskPoints(end, :) = [];
end
end
