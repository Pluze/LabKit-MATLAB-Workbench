% App-owned scale-state predicate. Expected caller: batch-crop UI/export
% readiness checks. Input is a calibration-like struct. Output is logical.
function tf = isScaleCalibrationSet(cal)
%ISSCALECALIBRATIONSET True when a per-image scale calibration is usable.

    tf = isstruct(cal) && isfield(cal, 'isCalibrated') && cal.isCalibrated && ...
        isfield(cal, 'pixelsPerUnit') && isfinite(double(cal.pixelsPerUnit)) && ...
        double(cal.pixelsPerUnit) > 0;
end
