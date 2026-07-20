% App-owned implementation for batch_crop.cropGeometry.useImageCenter within the batch_crop product workflow.
function applicationState = useImageCenter(applicationState, callbackContext)
applicationState = batch_crop.cropGeometry.useSourceCenter( ...
    applicationState, "xy", callbackContext);
end
