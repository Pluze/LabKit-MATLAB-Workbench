function R = integrateCVCTSignSplit(t, V, I, scanRate)
%INTEGRATECVCTSIGNSPLIT Legacy-compatible sign-split CT/CV integration.

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
            bp(end+1) = s0; %#ok<AGROW>
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
                dtErrList(end+1) = abs(dt_act - dt_cv); %#ok<AGROW>

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
