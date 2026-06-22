% App-owned scale-state summary helper. Expected caller: batch-crop UI status
% refresh. Input is a crop item vector. Output is the calibrated item count.
function count = countScaleCalibrations(items)
%COUNTSCALECALIBRATIONS Count items with usable per-image scale calibration.

    count = 0;
    for k = 1:numel(items)
        if isfield(items(k), 'scaleCalibration') && ...
                batch_crop.state.isScaleCalibrationSet(items(k).scaleCalibration)
            count = count + 1;
        end
    end
end
