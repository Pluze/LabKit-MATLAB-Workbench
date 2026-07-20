% App-owned implementation for batch_crop.scaleCalibration.referenceLengthChanged within the batch_crop product workflow.
function applicationState = referenceLengthChanged(applicationState, value, ~)
applicationState = batch_crop.scaleCalibration.changeCalibrationField( ...
    applicationState, "length", value);
end
