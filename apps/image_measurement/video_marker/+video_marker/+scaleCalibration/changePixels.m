function state = changePixels(state, value, ~)
%CHANGEPIXELS Set the reference pixel length directly.
calibration = state.project.annotations.calibration;
pixels = NaN;
if isnumeric(value) && isscalar(value) && isfinite(double(value)) && value > 0
    pixels = double(value);
end
state.project.annotations.calibration = ...
    labkit.app.interaction.scaleCalibration( ...
    pixels, calibration.referenceLength, calibration.unit);
state.session.view.scaleBar = [];
state = video_marker.resultFiles.clearExportState(state);
end
