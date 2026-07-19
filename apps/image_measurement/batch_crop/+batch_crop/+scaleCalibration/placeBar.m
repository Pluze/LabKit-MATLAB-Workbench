function applicationState = placeBar(applicationState, callbackContext)
if ~batch_crop.sourceFiles.hasCurrentImage(applicationState)
    callbackContext.alert("Open an image before placing a scale bar.", ...
        "No image loaded");
    return
end
item = batch_crop.sourceFiles.currentItem(applicationState);
if ~batch_crop.scaleCalibration.isSet(item.scaleCalibration)
    callbackContext.alert( ...
        "Measure or enter reference pixels, then enter a positive reference length and unit.", ...
        "Calibration required");
    return
end
try
    parameters = applicationState.project.parameters;
    applicationState.session.view.scaleBar = ...
        labkit.app.interaction.scaleBarGeometry( ...
            size(item.image), item.scaleCalibration, ...
            parameters.scaleBarLength, parameters.scaleBarPosition, ...
            parameters.scaleBarColor);
    applicationState.session.workflow.scaleReferenceEditing = false;
catch cause
    callbackContext.reportError("Could not place scale bar", cause);
    callbackContext.alert(cause.message, "Could not place scale bar");
end
end
