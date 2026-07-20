function applicationState = barSettingChanged( ...
        applicationState, changedValue, callbackContext)
%BARSETTINGCHANGED Normalize display-bar settings and invalidate its geometry.
barLength = double(applicationState.project.parameters.scaleBarLength);
if ~isscalar(barLength) || ~isfinite(barLength) || barLength < 0
    barLength = 0;
end
applicationState.project.parameters.scaleBarLength = barLength;
applicationState.session.view.scaleBar = [];
callbackContext.appendStatus( ...
    "Scale bar setting changed to " + string(changedValue) + ".");
end
