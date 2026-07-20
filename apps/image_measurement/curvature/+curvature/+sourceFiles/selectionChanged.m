% App-owned implementation for curvature.sourceFiles.selectionChanged within the curvature product workflow.
function applicationState = selectionChanged( ...
        applicationState, selection, callbackContext)
%SELECTIONCHANGED Reset image-owned annotations after source replacement.
calibration = applicationState.project.annotations.calibration;
applicationState.project.annotations.curvePoints = zeros(0, 2);
applicationState.project.annotations.calibration = ...
    labkit.app.interaction.scaleCalibration( ...
        [], calibration.referenceLength, calibration.unit);
applicationState.session.workflow.editMode = "none";
applicationState.session.view.scaleBar = [];
applicationState = curvature.curveEdit.clearMeasurements(applicationState);
if isempty(selection.Indices) || isempty(applicationState.session.cache.image)
    applicationState.session.workflow.statusMessage = ...
        "Open an image to trace a curve.";
    callbackContext.appendStatus("Image cleared.");
else
    applicationState.session.workflow.statusMessage = "Image loaded.";
    callbackContext.appendStatus("Loaded image.");
end
end
