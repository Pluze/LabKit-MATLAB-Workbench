% App-owned implementation for curvature.scaleCalibration.barSettingChanged within the curvature product workflow.
function applicationState = barSettingChanged( ...
        applicationState, changedValue, callbackContext)
%BARSETTINGCHANGED Normalize display-bar settings and invalidate its geometry.
barLength = double(applicationState.project.parameters.scaleBarLength);
if ~isscalar(barLength) || ~isfinite(barLength) || barLength < 0
    barLength = 0;
end
applicationState.project.parameters.scaleBarLength = barLength;
applicationState.session.view.scaleBar = [];
callbackContext.log("info", ...
    "curvature.scalecalibration.barsettingchanged.status", ...
    "Scale bar setting changed to " + string(changedValue) + ".");
end
