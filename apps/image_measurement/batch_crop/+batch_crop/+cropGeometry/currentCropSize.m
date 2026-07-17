% Expected callers: Batch Crop geometry and export actions. Input is canonical
% state. Output is the current pixel crop size after physical-scale conversion.
function sizeValue = currentCropSize(state)
    parameters = state.project.parameters;
    index = max(0, round(double(state.session.selection.currentIndex)));
    hasCurrent = index >= 1 && index <= numel(state.project.inputs.items) && ...
        index <= numel(state.session.cache.images) && ...
        ~isempty(state.session.cache.images{index});
    if strcmpi(parameters.scaleMode, "Physical") && hasCurrent
        calibration = state.project.inputs.items(index).scaleCalibration;
        if batch_crop.scaleCalibration.isSet(calibration)
            pixelsPerUnit = ...
                batch_crop.cropGeometry.pixelsPerUnitForUnit( ...
                calibration, parameters.scaleUnit);
            sizeValue = max(1, round([parameters.physicalWidth, ...
                parameters.physicalHeight] * pixelsPerUnit));
            return;
        end
    end
    sizeValue = max(1, round( ...
        [parameters.cropWidth, parameters.cropHeight]));
end
