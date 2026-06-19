% Expected caller: rhs_preview.run. Inputs are requested ROI seconds and the
% current preview time vector. Output is a sorted ROI clamped to preview time.
function roiSec = clampRoi(roiSec, timeSec)
%CLAMPROI Clamp dragged ROI to preview samples.

    timeSec = double(timeSec(:));
    roiSec = sort(double(roiSec(:))).';
    roiSec(1) = max(min(timeSec), min(max(timeSec), roiSec(1)));
    roiSec(2) = max(min(timeSec), min(max(timeSec), roiSec(2)));
end
