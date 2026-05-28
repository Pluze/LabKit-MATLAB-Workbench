function R = computeCVCharge(t, V, I, scanRate)
%COMPUTECVCHARGE Compute sign-split charge using abs(dV) / scanRate.

    R = struct();
    R.ok = false;
    R.message = '';

    if nargin < 4 || ~(isscalar(scanRate) && isfinite(scanRate) && scanRate > 0)
        R.message = 'scan rate missing';
        R = fillEmpty(R);
        return;
    end
    if numel(t) < 2 || numel(V) < 2 || numel(I) < 2
        R.message = 'Not enough points';
        R = fillEmpty(R);
        return;
    end

    S = integrateCVCTSignSplit(t, V, I, scanRate);
    R = copyFields(R, S, {'QcvCath', 'QcvAnod', 'dtErr', 'IcathDisp', 'IanodDisp'});
    R.QcvFull = R.QcvCath + R.QcvAnod;
    R.ok = true;
    R.message = 'OK';
end

function R = fillEmpty(R)
    R.QcvCath = 0;
    R.QcvAnod = 0;
    R.QcvFull = 0;
    R.dtErr = NaN;
    R.IcathDisp = [];
    R.IanodDisp = [];
end

function out = copyFields(out, in, names)
    for k = 1:numel(names)
        out.(names{k}) = in.(names{k});
    end
end
