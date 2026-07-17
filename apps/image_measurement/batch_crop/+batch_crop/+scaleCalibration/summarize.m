% App-owned scale-state summary helper. Expected caller: batch-crop UI,
% export validation, and tests. Input is a crop item vector. Output is a
% struct with calibrated, missing, and all-calibrated readiness fields.
function summary = summarize(items)
%SUMMARIZE Summarize per-item scale calibration readiness.

    total = numel(items);
    calibrated = false(total, 1);
    for k = 1:total
        calibrated(k) = isfield(items(k), 'scaleCalibration') && ...
            batch_crop.scaleCalibration.isSet(items(k).scaleCalibration);
    end

    count = sum(calibrated);
    summary = struct( ...
        'total', total, ...
        'calibratedCount', count, ...
        'missingCount', total - count, ...
        'allCalibrated', count == total);
end
