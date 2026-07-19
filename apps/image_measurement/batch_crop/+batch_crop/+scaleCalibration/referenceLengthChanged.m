function applicationState = referenceLengthChanged(applicationState, value, ~)
applicationState = batch_crop.scaleCalibration.changeCalibrationField( ...
    applicationState, "length", value);
end
