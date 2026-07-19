function applicationState = useImageYCenter(applicationState, callbackContext)
applicationState = batch_crop.cropGeometry.useSourceCenter( ...
    applicationState, "y", callbackContext);
end
