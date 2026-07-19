function state = changeLength(state, value, ~)
calibration = state.project.annotations.calibration;
state.project.annotations.calibration = labkit.app.interaction.scaleCalibration( ...
    calibration.referencePixels, max(0,double(value)), calibration.unit, ...
    struct("referenceLine", calibration.referenceLine));
state = curvature.curveEdit.clearMeasurements(state);
end
