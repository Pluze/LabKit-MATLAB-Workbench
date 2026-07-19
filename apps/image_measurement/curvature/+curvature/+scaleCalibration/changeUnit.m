function state = changeUnit(state, value, ~)
calibration = state.project.annotations.calibration;
state.project.annotations.calibration = labkit.app.interaction.scaleCalibration( ...
    calibration.referencePixels, calibration.referenceLength, string(value), ...
    struct("referenceLine", calibration.referenceLine));
state = curvature.curveEdit.clearMeasurements(state);
end
