function applicationState = clearBoundary( ...
        applicationState, callbackContext)
applicationState.project.annotations.maskPoints = zeros(0, 2);
callbackContext.appendStatus("Cleared mask ROI boundary anchors.");
end
