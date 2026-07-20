% App-owned implementation for batch_crop.cropGeometry.useImageXCenter within the batch_crop product workflow.
function applicationState = useImageXCenter(applicationState, callbackContext)
applicationState = batch_crop.cropGeometry.useSourceCenter( ...
    applicationState, "x", callbackContext);
end
