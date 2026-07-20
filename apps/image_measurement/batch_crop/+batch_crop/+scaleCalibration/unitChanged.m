% App-owned implementation for batch_crop.scaleCalibration.unitChanged within the batch_crop product workflow.
function applicationState = unitChanged(applicationState, value, ~)
applicationState = batch_crop.scaleCalibration.changeCalibrationField( ...
    applicationState, "unit", value);
end
