% App-owned implementation for batch_crop.cropGeometry.useImageYCenter within the batch_crop product workflow.
function applicationState = useImageYCenter(applicationState, callbackContext)
applicationState = batch_crop.cropGeometry.useSourceCenter( ...
    applicationState, "y", callbackContext);
end
