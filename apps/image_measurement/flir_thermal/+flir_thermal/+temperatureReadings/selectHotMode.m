% App-owned implementation for flir_thermal.temperatureReadings.selectHotMode within the flir_thermal product workflow.
function applicationState = selectHotMode( ...
        applicationState, callbackContext)
%SELECTHOTMODE Configure dragged regions to report their hottest pixel.
applicationState.project.parameters.roiMode = "hot";
callbackContext.appendStatus( ...
    "ROI mode: ROI hot spot. Drag on the thermal image to set the ROI.");
end
