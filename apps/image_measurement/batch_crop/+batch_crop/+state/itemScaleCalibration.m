% App-owned state helper. Expected caller: batch-crop GUI and tests. Inputs
% are item array and current index. Output is the current item's calibration
% struct or [] when no valid current item exists.
function cal = itemScaleCalibration(items, currentIndex)
    cal = [];
    if ~isempty(items) && currentIndex >= 1 && currentIndex <= numel(items) && ...
            isfield(items(currentIndex), 'scaleCalibration')
        cal = items(currentIndex).scaleCalibration;
    end
end
