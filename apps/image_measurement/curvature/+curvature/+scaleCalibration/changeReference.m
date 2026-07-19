function state = changeReference(state, endpoints, ~)
calibration = state.project.annotations.calibration;
endpoints = double(endpoints);
pixels = NaN;
if size(endpoints,1) == 2, pixels = norm(diff(endpoints,1,1)); end
state.project.annotations.calibration = labkit.app.interaction.scaleCalibration( ...
    pixels, calibration.referenceLength, calibration.unit, struct("referenceLine", endpoints));
state = curvature.curveEdit.clearMeasurements(state);
end
