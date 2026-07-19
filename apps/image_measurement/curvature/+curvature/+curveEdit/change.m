function state = change(state, points, ~)
state.project.annotations.curvePoints = double(points);
state = curvature.curveEdit.clearMeasurements(state);
end
