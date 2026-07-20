function applicationState = toggleReference( ...
        applicationState, callbackContext)
%TOGGLEREFERENCE Enter or leave managed two-point reference editing.
if isempty(applicationState.session.cache.image)
    callbackContext.alert( ...
        "Open an image before measuring reference pixels.", ...
        "No image loaded");
    return
end
if string(applicationState.session.workflow.editMode) == "reference"
    applicationState.session.workflow.editMode = "none";
    callbackContext.appendStatus("Finished reference-pixel edit.");
else
    applicationState.session.workflow.editMode = "reference";
    applicationState.session.view.scaleBar = [];
    applicationState = ...
        curvature.curveEdit.clearMeasurements(applicationState);
    callbackContext.appendStatus( ...
        "Started reference-pixel edit. Double-click two endpoints and " + ...
        "drag them to refine the reference line.");
end
end
