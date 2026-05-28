function R = computeCTCharge(t, V, I)
%COMPUTECTCHARGE Compute sign-split charge using recorded time.

    R = struct();
    R.ok = false;
    R.message = '';

    if nargin < 3 || numel(t) < 2 || numel(V) < 2 || numel(I) < 2
        R.message = 'Not enough points';
        R = fillEmpty(R);
        return;
    end

    S = integrateCVCTSignSplit(t, V, I, NaN);
    R = copyFields(R, S, {'QctCath', 'QctAnod', 'IcathDisp', 'IanodDisp'});
    R.QctFull = R.QctCath + R.QctAnod;
    R.ok = true;
    R.message = 'OK';
end

function R = fillEmpty(R)
    R.QctCath = 0;
    R.QctAnod = 0;
    R.QctFull = 0;
    R.IcathDisp = [];
    R.IanodDisp = [];
end

function out = copyFields(out, in, names)
    for k = 1:numel(names)
        out.(names{k}) = in.(names{k});
    end
end
