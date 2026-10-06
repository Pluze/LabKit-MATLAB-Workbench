function state = changeLength(state, value, ~)
%CHANGELENGTH Set the physical reference length.
calibration = state.project.annotations.calibration;
lengthValue = calibration.referenceLength;
if isnumeric(value) && isscalar(value) && ...
        isfinite(double(value)) && value >= 0
    lengthValue = double(value);
end
state.project.annotations.calibration = ...
    labkit.app.interaction.scaleCalibration( ...
    calibration.referencePixels, lengthValue, calibration.unit, ...
    struct("referenceLine", calibration.referenceLine));
state.session.view.scaleBar = [];
state = video_marker.resultFiles.clearExportState(state);
end
