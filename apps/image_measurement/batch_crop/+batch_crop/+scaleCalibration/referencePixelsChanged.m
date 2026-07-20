% App-owned implementation for batch_crop.scaleCalibration.referencePixelsChanged within the batch_crop product workflow.
function applicationState = referencePixelsChanged(applicationState, value, ~)
applicationState = batch_crop.scaleCalibration.changeCalibrationField( ...
    applicationState, "pixels", value);
end
