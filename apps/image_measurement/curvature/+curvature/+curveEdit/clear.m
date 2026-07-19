function state = clear(state, ~)
state.project.annotations.curvePoints = zeros(0,2);
state = curvature.curveEdit.clearMeasurements(state);
end
