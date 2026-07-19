function applicationState = undoPointPair(applicationState, ~)
reference = applicationState.project.annotations.matchReferencePoints;
moving = applicationState.project.annotations.matchMovingPoints;
if isempty(reference)
    return
end
reference(end, :) = [];
if size(reference, 1) < size(moving, 1)
    moving(end, :) = [];
end
applicationState.project.annotations.matchReferencePoints = reference;
applicationState.project.annotations.matchMovingPoints = moving;
end
