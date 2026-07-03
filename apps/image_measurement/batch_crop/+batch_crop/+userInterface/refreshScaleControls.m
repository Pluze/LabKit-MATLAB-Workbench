% App-owned scale UI helper. Expected caller: batch_crop/run refresh logic.
% Inputs are the scale-bar tool, optional status text control, item list,
% current index, scale mode, requested physical size, and unit. Side effects
% are limited to scale-tool enablement/calibration and status text refresh.
function refreshScaleControls(scaleTool, statusControl, items, currentIndex, mode, physicalSize, unitName)
    hasImage = ~isempty(items) && currentIndex >= 1 && currentIndex <= numel(items) && ...
        ~isempty(items(currentIndex).image);
    physicalMode = strcmpi(string(mode), "Physical");
    if scaleTool.isReferenceEditActive()
        scaleTool.setEnabled(struct( ...
            'hasImage', hasImage && physicalMode, ...
            'blockInputs', ~physicalMode, ...
            'blockPlacement', true));
    else
        applyScaleToolState(scaleTool, items, currentIndex, hasImage, physicalMode);
    end
    if ~isempty(statusControl) && isvalid(statusControl)
        statusControl.Value = batch_crop.userInterface.scaleStatusText( ...
            struct('items', items), currentIndex, mode, physicalSize, unitName);
    end
end

function applyScaleToolState(scaleTool, items, currentIndex, hasImage, physicalMode)
    if hasImage
        scaleTool.setCalibration(items(currentIndex).scaleCalibration);
        scaleTool.setImageSize(size(items(currentIndex).image));
    else
        scaleTool.setCalibration([]);
        scaleTool.setImageSize([]);
    end
    scaleTool.setEnabled(struct( ...
        'hasImage', hasImage && physicalMode, ...
        'blockInputs', ~physicalMode, ...
        'blockPlacement', true));
end
