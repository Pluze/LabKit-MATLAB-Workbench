function applicationState = useImageCenter(applicationState, callbackContext)
applicationState = batch_crop.cropGeometry.useSourceCenter( ...
    applicationState, "xy", callbackContext);
end
