function applicationState = selectColdMode( ...
        applicationState, callbackContext)
%SELECTCOLDMODE Configure dragged regions to report their coldest pixel.
applicationState.project.parameters.roiMode = "cold";
callbackContext.appendStatus( ...
    "ROI mode: ROI cold spot. Drag on the thermal image to set the ROI.");
end
