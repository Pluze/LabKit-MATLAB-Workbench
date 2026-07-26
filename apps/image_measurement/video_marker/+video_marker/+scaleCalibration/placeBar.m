% App-owned implementation for video_marker.scaleCalibration.placeBar within the video_marker product workflow.
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
    context.log("error", "video_marker.scalecalibration.placebar.exception", "Could not place scale bar", ...
        Category="failure", Audience="developer", Exception=cause);
    context.alert(cause.message, "Could not place scale bar");
end
end
