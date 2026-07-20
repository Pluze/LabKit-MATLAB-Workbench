function applicationState = changeReference( ...
        applicationState, endpoints, callbackContext)
%CHANGEREFERENCE Commit the managed two-point reference measurement.
calibration = applicationState.project.annotations.calibration;
endpoints = normalizeEndpoints(endpoints);
if size(endpoints, 1) > 2
    endpoints = endpoints(end - 1:end, :);
end
applicationState.project.annotations.calibration = ...
    labkit.app.interaction.scaleCalibration( ...
        NaN, calibration.referenceLength, calibration.unit, ...
        struct("referenceLine", endpoints));
applicationState.session.view.scaleBar = [];
applicationState = curvature.curveEdit.clearMeasurements(applicationState);
callbackContext.appendStatus("Scale reference updated.");
end

function endpoints = normalizeEndpoints(endpoints)
if isempty(endpoints)
    endpoints = zeros(0, 2);
    return
end
endpoints = double(endpoints);
if size(endpoints, 2) ~= 2 || any(~isfinite(endpoints), "all")
    endpoints = zeros(0, 2);
end
end
