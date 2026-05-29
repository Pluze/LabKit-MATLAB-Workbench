function A = computeCIC(item, opts)
%COMPUTECIC Compute legacy-compatible CIC / voltage-transient metrics.

    if nargin < 2
        opts = struct();
    end
    opts = fillOptions(opts);

    A = struct();
    A.ok = false;
    A.message = '';
    A.delay_s = opts.delay_s;
    A.cathLimit = opts.cathLimit;
    A.anodLimit = opts.anodLimit;
    A.area_cm2 = chooseArea(item, opts);
    A.usedMeasuredCurrent = opts.usedMeasuredCurrent;
    A.logOnFailure = false;

    [curve, okCurve, msgCurve] = mainCurve(item);
    if ~okCurve
        A.message = msgCurve;
        A.logOnFailure = true;
        return;
    end

    t = gamrywb.data.getColumn(curve, 'T');
    Vf = gamrywb.data.getColumn(curve, 'Vf');
    Im = gamrywb.data.getColumn(curve, 'Im');
    pt = gamrywb.data.getColumn(curve, 'Pt');
    if isempty(pt)
        pt = (0:numel(t)-1).';
    end

    valid = ~(isnan(t) | isnan(Vf) | isnan(Im));
    t = t(valid);
    Vf = Vf(valid);
    Im = Im(valid);
    pt = pt(valid);
    if numel(t) < 5
        A.message = 'Not enough valid T/Vf/Im points.';
        return;
    end

    A.t = t;
    A.Vf = Vf;
    A.Im = Im;
    A.pt = pt;
    A.sample_dt = median(diff(t));
    A.sample_dt_report = A.sample_dt;
    A.ampEstimate_A = max(abs(Im));

    meta = struct();
    if isfield(item, 'meta')
        meta = item.meta;
    end
    [pulse, pulseMsg] = gamrywb.analysis.detectPulses(t, Im, meta, opts.pulseMode);
    A.pulse = pulse;
    A.detectMode = pulse.method;
    A.detectMsg = pulseMsg;

    if ~pulse.ok
        A.message = pulseMsg;
        A.logOnFailure = true;
        return;
    end

    V = computeVoltageTransientMetrics(t, Vf, pulse, A.delay_s);
    A = mergeStructs(A, V);

    Q = computeInjectedCharge(t, Im, pulse, A.usedMeasuredCurrent);
    A = mergeStructs(A, Q);
    if ~Q.ok
        A.message = Q.message;
        return;
    end

    if isfinite(A.area_cm2) && A.area_cm2 > 0
        A.CICc_mCcm2 = 1e3 * A.Qc_C / A.area_cm2;
        A.CICa_mCcm2 = 1e3 * A.Qa_C / A.area_cm2;
        A.CICt_mCcm2 = 1e3 * A.Qt_C / A.area_cm2;
    else
        A.CICc_mCcm2 = NaN;
        A.CICa_mCcm2 = NaN;
        A.CICt_mCcm2 = NaN;
    end

    safety = checkWaterWindowSafety(A.Emc, A.Ema, A.cathLimit, A.anodLimit);
    A = mergeStructs(A, safety);

    A.ok = true;
    A.message = 'OK';
end

function opts = fillOptions(opts)
    if ~isfield(opts, 'delay_s')
        opts.delay_s = 10e-6;
    end
    if ~isfield(opts, 'cathLimit')
        opts.cathLimit = -0.6;
    end
    if ~isfield(opts, 'anodLimit')
        opts.anodLimit = 0.8;
    end
    if ~isfield(opts, 'areaOverride')
        opts.areaOverride = '';
    end
    if ~isfield(opts, 'area_cm2')
        opts.area_cm2 = NaN;
    end
    if ~isfield(opts, 'pulseMode')
        opts.pulseMode = 'Metadata first, then auto';
    end
    if ~isfield(opts, 'usedMeasuredCurrent')
        opts.usedMeasuredCurrent = true;
    end
end

function area = chooseArea(item, opts)
    area = NaN;
    if isfield(opts, 'areaOverride')
        area = gamrywb.util.parsePositiveScalar(opts.areaOverride);
    end
    if ~isfinite(area) && isfield(opts, 'area_cm2')
        area = gamrywb.util.parsePositiveScalar(opts.area_cm2);
    end
    if ~isfinite(area) && isfield(item, 'meta') && isfield(item.meta, 'area_cm2') ...
            && isfinite(item.meta.area_cm2) && item.meta.area_cm2 > 0
        area = item.meta.area_cm2;
    end
end

function [curve, ok, msg] = mainCurve(item)
    if isfield(item, 'curve') && ~isempty(item.curve)
        curve = item.curve;
        ok = true;
        msg = sprintf('Using table: %s', curve.name);
    elseif isfield(item, 'tables')
        [curve, ok, msg] = gamrywb.data.getMainCurve(item.tables);
    else
        curve = struct();
        ok = false;
        msg = 'Main transient table not found.';
    end
end

function out = mergeStructs(out, in)
    names = fieldnames(in);
    for i = 1:numel(names)
        out.(names{i}) = in.(names{i});
    end
end

function V = computeVoltageTransientMetrics(t, Vf, pulse, delay_s)
    V = struct();
    V.t_emc = pulse.cath_end + delay_s;
    V.t_ema = pulse.anod_end + delay_s;
    V.emc_idx = gamrywb.util.nearestIndex(t, V.t_emc);
    V.ema_idx = gamrywb.util.nearestIndex(t, V.t_ema);
    V.Emc = interp1Safe(t, Vf, V.t_emc);
    V.Ema = interp1Safe(t, Vf, V.t_ema);

    V.Epre = gamrywb.util.medianInWindow(t, Vf, pulse.pre_start, pulse.pre_end);
    V.Ebetween = gamrywb.util.medianInWindow(t, Vf, pulse.gap_start, pulse.gap_end);
    V.Epost = gamrywb.util.medianInWindow(t, Vf, pulse.post_start, pulse.post_end);
    [V.Eipp, V.baselineCathSource, V.baselineCathWindow] = chooseBaselineCandidate( ...
        [V.Epre, V.Ebetween, V.Epost, 0], ...
        {'pre-pulse median', 'interpulse median', 'post-pulse median', 'zero fallback'}, ...
        [pulse.pre_start pulse.pre_end; pulse.gap_start pulse.gap_end; pulse.post_start pulse.post_end; NaN NaN]);
    [V.Eipp_gap, V.baselineAnodSource, V.baselineAnodWindow] = chooseBaselineCandidate( ...
        [V.Ebetween, V.Epre, V.Epost, V.Eipp], ...
        {'interpulse median', 'pre-pulse median', 'post-pulse median', 'cathodic baseline fallback'}, ...
        [pulse.gap_start pulse.gap_end; pulse.pre_start pulse.pre_end; pulse.post_start pulse.post_end; V.baselineCathWindow]);

    V.tc_s = max(0, pulse.cath_end - pulse.cath_start);
    V.ta_s = max(0, pulse.anod_end - pulse.anod_start);
    V.tip_s = max(0, pulse.anod_start - pulse.cath_end);
    V.t_conset = pulse.cath_start + delay_s;
    V.t_aonset = pulse.anod_start + delay_s;
    V.Vc_on = interp1Safe(t, Vf, V.t_conset);
    V.Va_on = interp1Safe(t, Vf, V.t_aonset);
    V.Va_cath_mag = abs(V.Eipp - V.Vc_on);
    V.Va_anod_mag = abs(V.Eipp_gap - V.Va_on);
end

function Q = computeInjectedCharge(t, Im, pulse, useMeasuredCurrent)
    if nargin < 4
        useMeasuredCurrent = true;
    end

    Q = struct();
    cathMask = (t >= pulse.cath_start) & (t <= pulse.cath_end);
    anodMask = (t >= pulse.anod_start) & (t <= pulse.anod_end);
    Q.cathMask = cathMask;
    Q.anodMask = anodMask;

    if sum(cathMask) < 2 || sum(anodMask) < 2
        Q.ok = false;
        Q.message = 'Pulse windows too short after detection.';
        return;
    end

    Q.Ic_est_A = median(Im(cathMask), 'omitnan');
    Q.Ia_est_A = median(Im(anodMask), 'omitnan');
    if ~isfinite(Q.Ic_est_A)
        Q.Ic_est_A = pulse.Ic_nominal;
    end
    if ~isfinite(Q.Ia_est_A)
        Q.Ia_est_A = pulse.Ia_nominal;
    end

    if useMeasuredCurrent
        Qc = abs(trapz(t(cathMask), Im(cathMask)));
        Qa = abs(trapz(t(anodMask), Im(anodMask)));
    else
        Qc = abs(pulse.Ic_nominal * (pulse.cath_end - pulse.cath_start));
        Qa = abs(pulse.Ia_nominal * (pulse.anod_end - pulse.anod_start));
    end

    Q.Qc_C = Qc;
    Q.Qa_C = Qa;
    Q.Qt_C = Qc + Qa;
    Q.ok = true;
    Q.message = 'OK';
end

function safety = checkWaterWindowSafety(Emc, Ema, cathLimit, anodLimit)
    safety = struct();
    safety.cathOK = Emc >= cathLimit;
    safety.anodOK = Ema <= anodLimit;
    safety.safe = safety.cathOK && safety.anodOK;

    if safety.safe
        safety.limitSide = 'safe';
    elseif ~safety.cathOK && ~safety.anodOK
        safety.limitSide = 'both exceeded';
    elseif ~safety.cathOK
        safety.limitSide = 'cathodic exceeded';
    else
        safety.limitSide = 'anodic exceeded';
    end
end

function v = interp1Safe(x, y, xq)
    if numel(x) < 2 || any(~isfinite([x(:); y(:)]))
        v = NaN;
        return;
    end
    try
        v = interp1(x, y, xq, 'linear', 'extrap');
    catch
        idx = gamrywb.util.nearestIndex(x, xq);
        v = y(idx);
    end
end

function [v, sourceLabel, window] = chooseBaselineCandidate(candidates, sourceLabels, windows)
    v = NaN;
    sourceLabel = 'unavailable';
    window = [NaN NaN];
    for k = 1:numel(candidates)
        if isfinite(candidates(k))
            v = candidates(k);
            sourceLabel = sourceLabels{k};
            if size(windows, 1) >= k
                window = windows(k, :);
            end
            return;
        end
    end
end
