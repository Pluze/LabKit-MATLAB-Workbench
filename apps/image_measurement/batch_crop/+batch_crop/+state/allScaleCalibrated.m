% App-owned scale-state readiness helper. Expected caller: batch-crop export
% enablement and validation. Input is a crop item vector. Output is logical.
function tf = allScaleCalibrated(items)
%ALLSCALECALIBRATED True when every item has usable scale calibration.

    tf = true;
    for k = 1:numel(items)
        tf = tf && isfield(items(k), 'scaleCalibration') && ...
            batch_crop.state.isScaleCalibrationSet(items(k).scaleCalibration);
    end
end
