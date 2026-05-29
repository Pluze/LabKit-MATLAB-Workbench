function A = computeCSC(curve, opts)
%COMPUTECSC Compute CV/CT charge comparison and CSC for the CSC app.

    if nargin < 2
        opts = struct();
    end
    opts = fillOptions(opts);

    A = struct();
    A.ok = false;
    A.message = '';
    A.logMessage = '';
    A.mode = opts.mode;
    A.scanRate = opts.scanRate;
    A.area_cm2 = gamrywb.util.parsePositiveScalar(opts.area_cm2);

    if ~(isscalar(A.scanRate) && isfinite(A.scanRate) && A.scanRate > 0)
        A.message = 'scan rate missing';
        A.logMessage = 'Compare skipped: scan rate missing.';
        return;
    end

    if ~hasExactColumns(curve, {'T', 'Vf', 'Im'})
        A.message = 'Need T, Vf, Im';
        A.logMessage = 'Compare skipped: T/Vf/Im not all present.';
        return;
    end

    t = exactColumn(curve, 'T');
    V = exactColumn(curve, 'Vf');
    I = exactColumn(curve, 'Im');

    good = ~(isnan(t) | isnan(V) | isnan(I));
    t = t(good);
    V = V(good);
    I = I(good);

    if numel(t) < 2
        A.message = 'Not enough points';
        A.logMessage = 'Compare skipped: not enough valid points.';
        return;
    end

    CT = gamrywb_apps.csc.computeCTCharge(t, V, I);
    CV = gamrywb_apps.csc.computeCVCharge(t, V, I, A.scanRate);
    if ~CT.ok
        A.message = CT.message;
        A.logMessage = 'Compare skipped: not enough valid points.';
        return;
    end
    if ~CV.ok
        A.message = CV.message;
        A.logMessage = 'Compare skipped: scan rate missing.';
        return;
    end

    A.t = t;
    A.Vf = V;
    A.Im = I;
    A.IcathDisp = CT.IcathDisp;
    A.IanodDisp = CT.IanodDisp;
    A.QctCath = CT.QctCath;
    A.QctAnod = CT.QctAnod;
    A.QctFull = CT.QctFull;
    A.QcvCath = CV.QcvCath;
    A.QcvAnod = CV.QcvAnod;
    A.QcvFull = CV.QcvFull;
    A.dtErr = CV.dtErr;

    switch A.mode
        case 'Cathodic'
            A.Qct = A.QctCath;
            A.Qcv = A.QcvCath;
        case 'Anodic'
            A.Qct = A.QctAnod;
            A.Qcv = A.QcvAnod;
        otherwise
            A.mode = 'Full';
            A.Qct = A.QctFull;
            A.Qcv = A.QcvFull;
    end

    A.diff_C = A.Qct - A.Qcv;
    denom = max(abs(A.Qct), abs(A.Qcv));
    if denom == 0
        A.rel_pct = 0;
    else
        A.rel_pct = 100 * abs(A.diff_C) / denom;
    end

    if isfinite(A.area_cm2) && A.area_cm2 > 0
        A.Qct_mC_cm2 = 1e3 * A.Qct / A.area_cm2;
        A.Qcv_mC_cm2 = 1e3 * A.Qcv / A.area_cm2;
        A.diff_mC_cm2 = 1e3 * A.diff_C / A.area_cm2;
    else
        A.Qct_mC_cm2 = NaN;
        A.Qcv_mC_cm2 = NaN;
        A.diff_mC_cm2 = NaN;
    end

    A.ok = true;
    A.message = 'OK';
end

function opts = fillOptions(opts)
    if ~isfield(opts, 'mode')
        opts.mode = 'Full';
    end
    if ~isfield(opts, 'scanRate')
        opts.scanRate = NaN;
    end
    if ~isfield(opts, 'area_cm2')
        opts.area_cm2 = NaN;
    end
end

function tf = hasExactColumns(curve, names)
    tf = isfield(curve, 'headers');
    if ~tf
        return;
    end
    for k = 1:numel(names)
        if ~any(strcmp(curve.headers, names{k}))
            tf = false;
            return;
        end
    end
end

function col = exactColumn(curve, name)
    idx = find(strcmp(curve.headers, name), 1);
    if isempty(idx)
        col = [];
    else
        col = curve.data(:, idx);
    end
end
