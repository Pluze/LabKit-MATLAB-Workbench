function applicationState = unitChanged(applicationState, value, ~)
applicationState = batch_crop.scaleCalibration.changeCalibrationField( ...
    applicationState, "unit", value);
end
