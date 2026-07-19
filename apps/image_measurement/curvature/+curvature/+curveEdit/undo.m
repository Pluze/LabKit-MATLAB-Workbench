function state = undo(state, ~)
points = state.project.annotations.curvePoints;
if ~isempty(points), points(end,:) = []; end
state.project.annotations.curvePoints = points;
state = curvature.curveEdit.clearMeasurements(state);
end
