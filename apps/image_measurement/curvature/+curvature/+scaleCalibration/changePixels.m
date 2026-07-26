% App-owned implementation for curvature.scaleCalibration.changePixels within the curvature product workflow.
function applicationState = changePixels( ...
        applicationState, referencePixels, callbackContext)
%CHANGEPIXELS Replace the measured line with a typed pixel distance.
calibration = applicationState.project.annotations.calibration;
referencePixels = finiteNonnegative(referencePixels, 0);
applicationState.project.annotations.calibration = ...
    labkit.app.interaction.scaleCalibration( ...
        referencePixels, calibration.referenceLength, calibration.unit);
applicationState.session.view.scaleBar = [];
applicationState = curvature.curveEdit.clearMeasurements(applicationState);
callbackContext.log("info", ...
    "curvature.scalecalibration.changepixels.status", ...
    "Reference pixels set to " + string(referencePixels) + ".");
end

function value = finiteNonnegative(value, fallback)
value = double(value);
if ~isscalar(value) || ~isfinite(value) || value < 0
    value = fallback;
end
end
