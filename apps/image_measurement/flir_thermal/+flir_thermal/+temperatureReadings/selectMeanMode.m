% App-owned implementation for flir_thermal.temperatureReadings.selectMeanMode within the flir_thermal product workflow.
function applicationState = selectMeanMode( ...
        applicationState, callbackContext)
%SELECTMEANMODE Configure dragged regions to report their mean temperature.
applicationState.project.parameters.roiMode = "mean";
callbackContext.appendStatus( ...
    "ROI mode: ROI mean. Drag on the thermal image to set the ROI.");
end
