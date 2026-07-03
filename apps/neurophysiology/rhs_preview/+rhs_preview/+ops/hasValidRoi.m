% Expected caller: rhs_preview.actions.table. Input is app state. Output indicates
% whether a dragged ROI has a positive time width.
function tf = hasValidRoi(S)
%HASVALIDROI True for a finite nonzero preview ROI.

    tf = false;
    if ~isstruct(S) || ~isfield(S, "roiSec")
        return;
    end
    roiSec = double(S.roiSec);
    tf = numel(roiSec) == 2 && all(isfinite(roiSec)) && ...
        max(roiSec) > min(roiSec);
end
