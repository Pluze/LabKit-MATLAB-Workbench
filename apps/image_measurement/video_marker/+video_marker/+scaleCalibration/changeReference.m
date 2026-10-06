function state = changeReference(state, endpoints, ~)
%CHANGEREFERENCE Store a measured pixel reference line.
if state.session.cache.videoInfo.frameCount <= 0 || size(endpoints, 2) ~= 2
    return
end
calibration = state.project.annotations.calibration;
endpoints = double(endpoints);
pixels = NaN;
if size(endpoints, 1) == 2
    pixels = norm(diff(endpoints, 1, 1));
end
state.project.annotations.calibration = ...
    labkit.app.interaction.scaleCalibration( ...
    pixels, calibration.referenceLength, calibration.unit, ...
    struct("referenceLine", endpoints));
state.session.view.scaleBar = [];
state = video_marker.resultFiles.clearExportState(state);
end
