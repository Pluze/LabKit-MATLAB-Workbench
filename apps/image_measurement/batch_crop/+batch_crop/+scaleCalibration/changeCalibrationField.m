function applicationState = changeCalibrationField( ...
        applicationState, field, value)
if ~batch_crop.sourceFiles.hasCurrentImage(applicationState)
    return
end
index = batch_crop.sourceFiles.currentIndex(applicationState);
calibration = applicationState.project.inputs.items(index).scaleCalibration;
switch field
    case "pixels"
        calibration.referencePixels = positiveOrNaN(value);
        calibration.referenceLine = zeros(0, 2);
    case "length"
        calibration.referenceLength = nonnegative( ...
            value, calibration.referenceLength);
    case "unit"
        calibration.unit = char(string(value));
end
applicationState.project.inputs.items(index).scaleCalibration = ...
    makeCalibration(calibration);
applicationState.session.view.scaleBar = [];
applicationState = batch_crop.cropGeometry.clearDerived(applicationState);
end

function calibration = makeCalibration(value)
calibration = labkit.app.interaction.scaleCalibration( ...
    value.referencePixels, value.referenceLength, value.unit, ...
    struct("referenceLine", value.referenceLine, "defaultUnit", "um"));
end

function value = positiveOrNaN(candidate)
value = NaN;
if isnumeric(candidate) && isscalar(candidate) && ...
        isfinite(double(candidate)) && double(candidate) > 0
    value = double(candidate);
end
end

function value = nonnegative(candidate, fallback)
value = fallback;
if isnumeric(candidate) && isscalar(candidate) && ...
        isfinite(double(candidate)) && double(candidate) >= 0
    value = double(candidate);
end
end
