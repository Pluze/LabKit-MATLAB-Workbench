% Expected caller: CSC app runner and unit tests. Inputs are a CV/CT curve struct
% and CSC options. Output is the stable CSC comparison result struct. No file or
% UI side effects.

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
    A.area_cm2 = parsePositiveScalar(opts.area_cm2);

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

    CT = computeCTCharge(t, V, I);
    CV = computeCVCharge(t, V, I, A.scanRate);
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

function R = computeCTCharge(t, V, I)
    R = struct();
    R.ok = false;
    R.message = '';

    if nargin < 3 || numel(t) < 2 || numel(V) < 2 || numel(I) < 2
        R.message = 'Not enough points';
        R = fillEmptyCT(R);
        return;
    end

    S = integrateCVCTSignSplit(t, V, I, NaN);
    R = copyFields(R, S, {'QctCath', 'QctAnod', 'IcathDisp', 'IanodDisp'});
    R.QctFull = R.QctCath + R.QctAnod;
    R.ok = true;
    R.message = 'OK';
end

function R = integrateCVCTSignSplit(t, V, I, scanRate)
    if nargin < 4
        scanRate = NaN;
    end

    t = t(:);
    V = V(:);
    I = I(:);

    R = struct();
    R.QctCath = 0;
    R.QctAnod = 0;
    R.QcvCath = 0;
    R.QcvAnod = 0;
    R.dtErr = NaN;

    R.IcathDisp = I;
    R.IanodDisp = I;
    R.IcathDisp(I >= 0) = NaN;
    R.IanodDisp(I <= 0) = NaN;

    dtErrList = [];
    useCV = isscalar(scanRate) && isfinite(scanRate) && scanRate > 0;

    for k = 1:numel(t)-1
        t1 = t(k);   t2 = t(k+1);
        V1 = V(k);   V2 = V(k+1);
        I1 = I(k);   I2 = I(k+1);

        if any(~isfinite([t1 t2 V1 V2 I1 I2]))
            continue;
        end

        bp = [0, 1];
        s0 = crossingFraction(I1, I2, 0);
        if ~isempty(s0)
            bp(end+1) = s0;
        end
        bp = unique(sort(bp));

        for j = 1:numel(bp)-1
            sa = bp(j);
            sb = bp(j+1);

            ta = lerp(t1, t2, sa);
            tb = lerp(t1, t2, sb);
            Va = lerp(V1, V2, sa);
            Vb = lerp(V1, V2, sb);
            Ia = lerp(I1, I2, sa);
            Ib = lerp(I1, I2, sb);

            Imid = 0.5 * (Ia + Ib);
            if Imid < 0
                R.QctCath = R.QctCath + abs(trapz([ta tb], [Ia Ib]));
            elseif Imid > 0
                R.QctAnod = R.QctAnod + trapz([ta tb], [Ia Ib]);
            end

            if useCV
                dt_act = tb - ta;
                dt_cv = abs(Vb - Va) / scanRate;
                dtErrList(end+1) = abs(dt_act - dt_cv);

                if Imid < 0
                    R.QcvCath = R.QcvCath + abs(trapz([0 dt_cv], [Ia Ib]));
                elseif Imid > 0
                    R.QcvAnod = R.QcvAnod + trapz([0 dt_cv], [Ia Ib]);
                end
            end
        end
    end

    if ~isempty(dtErrList)
        R.dtErr = max(dtErrList);
    end
end

function y = lerp(a, b, s)
    y = a + s * (b - a);
end

function s = crossingFraction(y1, y2, y0)
    if ~isfinite(y1) || ~isfinite(y2) || y1 == y2
        s = [];
        return;
    end
    s = (y0 - y1) / (y2 - y1);
    if ~(s > 0 && s < 1)
        s = [];
    end
end

function R = fillEmptyCT(R)
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

function R = computeCVCharge(t, V, I, scanRate)
    R = struct();
    R.ok = false;
    R.message = '';

    if nargin < 4 || ~(isscalar(scanRate) && isfinite(scanRate) && scanRate > 0)
        R.message = 'scan rate missing';
        R = fillEmptyCV(R);
        return;
    end
    if numel(t) < 2 || numel(V) < 2 || numel(I) < 2
        R.message = 'Not enough points';
        R = fillEmptyCV(R);
        return;
    end

    S = integrateCVCTSignSplit(t, V, I, scanRate);
    R = copyFields(R, S, {'QcvCath', 'QcvAnod', 'dtErr', 'IcathDisp', 'IanodDisp'});
    R.QcvFull = R.QcvCath + R.QcvAnod;
    R.ok = true;
    R.message = 'OK';
end

function R = fillEmptyCV(R)
    R.QcvCath = 0;
    R.QcvAnod = 0;
    R.QcvFull = 0;
    R.dtErr = NaN;
    R.IcathDisp = [];
    R.IanodDisp = [];
end

function q = parsePositiveScalar(x)
    if isnumeric(x)
        q = x;
    else
        x = strtrim(char(x));
        if isempty(x)
            q = NaN;
            return;
        end
        q = str2double(x);
    end

    if ~isscalar(q) || ~isfinite(q) || q <= 0
        q = NaN;
    end
end
