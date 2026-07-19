function state = placeBar(state, context)
%PLACEBAR Build display-only scale-bar geometry for the current frame.
calibration = state.project.annotations.calibration;
if isempty(state.session.cache.currentImage) || ~calibration.isCalibrated
    context.alert(["Measure or enter reference pixels, then enter a positive " ...
        "reference length and unit."], "Calibration required");
    return
end
try
    parameters = state.project.parameters;
    state.session.view.scaleBar = ...
        labkit.app.interaction.scaleBarGeometry( ...
        size(state.session.cache.currentImage), calibration, ...
        parameters.scaleBarLength, parameters.scaleBarPosition, ...
        parameters.scaleBarColor);
    state.session.workflow.scaleReferenceEditing = false;
catch cause
    context.reportError("Could not place scale bar", cause);
    context.alert(cause.message, "Could not place scale bar");
end
end
