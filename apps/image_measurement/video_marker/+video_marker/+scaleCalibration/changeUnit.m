function state = changeUnit(state, value, ~)
%CHANGEUNIT Set the physical calibration unit.
calibration = state.project.annotations.calibration;
state.project.annotations.calibration = ...
    labkit.app.interaction.scaleCalibration( ...
    calibration.referencePixels, calibration.referenceLength, string(value), ...
    struct("referenceLine", calibration.referenceLine));
state.session.view.scaleBar = [];
state = video_marker.resultFiles.clearExportState(state);
end
