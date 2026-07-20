function applicationState = clear(applicationState, callbackContext)
%CLEAR Remove every curve anchor and invalidate measurements.
applicationState.project.annotations.curvePoints = zeros(0, 2);
applicationState = curvature.curveEdit.clearMeasurements(applicationState);
callbackContext.appendStatus("Cleared curve points.");
end
