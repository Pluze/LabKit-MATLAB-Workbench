% Expected caller: VT resistance app runner and unit tests. Inputs are a DTA item
% struct and option struct. Output is the stable resistance result struct. No
% file or UI side effects.

function A = computeResistance(item, opts)
%COMPUTERESISTANCE Compute VT resistance metrics for the VT app.

    if nargin < 2
        opts = struct();
    end
    opts = fillResistanceOptions(opts);

    A = struct();
    A.ok = false;
    A.message = '';
    A.windowMode = opts.windowMode;
    A.voltageMode = opts.voltageMode;
    A.logOnFailure = false;

    [curve, okCurve, msgCurve] = mainCurve(item);
    if ~okCurve
        A.message = msgCurve;
        A.logOnFailure = true;
        return;
    end

    t = labkit.dta.getColumn(curve, 'T');
    Vf = labkit.dta.getColumn(curve, 'Vf');
    Im = labkit.dta.getColumn(curve, 'Im');
    pt = labkit.dta.getColumn(curve, 'Pt');
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

    meta = struct();
    if isfield(item, 'meta')
        meta = item.meta;
    end
    [pulse, pulseMsg] = labkit.dta.detectPulses(t, Im, meta, opts.pulseMode);
    A.pulse = pulse;
    A.detectMode = pulse.method;
    A.detectMsg = pulseMsg;
    if ~pulse.ok
        A.message = pulseMsg;
        A.logOnFailure = true;
        return;
    end

    [cStart, cEnd] = selectSteadyWindow(pulse.cath_start, pulse.cath_end, A.windowMode);
    [aStart, aEnd] = selectSteadyWindow(pulse.anod_start, pulse.anod_end, A.windowMode);
    cathMask = t >= cStart & t <= cEnd;
    anodMask = t >= aStart & t <= aEnd;
    if nnz(cathMask) < 2 || nnz(anodMask) < 2
        A.message = 'Steady windows are too short after pulse detection.';
        return;
    end

    A.cathMask = cathMask;
    A.anodMask = anodMask;
    A.cathSteadyStart = cStart;
    A.cathSteadyEnd = cEnd;
    A.anodSteadyStart = aStart;
    A.anodSteadyEnd = aEnd;

    A.Ic_est_A = median(Im(cathMask), 'omitnan');
    A.Ia_est_A = median(Im(anodMask), 'omitnan');
    A.Vc_ss_V = median(Vf(cathMask), 'omitnan');
    A.Va_ss_V = median(Vf(anodMask), 'omitnan');

    A.cathBaselineStart = pulse.pre_start;
    A.cathBaselineEnd = pulse.pre_end;
    A.anodBaselineStart = pulse.post_start;
    A.anodBaselineEnd = pulse.post_end;
    [A.Vc_baseline_V, A.cathBaselineWindow_s] = estimateBaseline( ...
        t, Vf, pulse.pre_start, pulse.pre_end, 0);
    [A.Va_baseline_V, A.anodBaselineWindow_s] = estimateBaseline( ...
        t, Vf, pulse.post_start, pulse.post_end, chooseFinite(A.Vc_baseline_V, 0));

    A.dVc_V = A.Vc_ss_V - A.Vc_baseline_V;
    A.dVa_V = A.Va_ss_V - A.Va_baseline_V;
    A.Rc_raw_ohm = safeDivide(A.Vc_ss_V, A.Ic_est_A);
    A.Ra_raw_ohm = safeDivide(A.Va_ss_V, A.Ia_est_A);
    A.Rc_dV_ohm = safeDivide(A.dVc_V, A.Ic_est_A);
    A.Ra_dV_ohm = safeDivide(A.dVa_V, A.Ia_est_A);

    if strcmp(A.voltageMode, 'Raw Vf/I')
        A.Rc_ohm = A.Rc_raw_ohm;
        A.Ra_ohm = A.Ra_raw_ohm;
    else
        A.Rc_ohm = A.Rc_dV_ohm;
        A.Ra_ohm = A.Ra_dV_ohm;
    end
    A.Rc_abs_ohm = abs(A.Rc_ohm);
    A.Ra_abs_ohm = abs(A.Ra_ohm);
    A.Ravg_abs_ohm = mean([A.Rc_abs_ohm, A.Ra_abs_ohm], 'omitnan');

    A.ok = isfinite(A.Ravg_abs_ohm);
    if A.ok
        A.message = 'OK';
    else
        A.message = 'Resistance could not be computed; check current and pulse detection.';
        A.logOnFailure = true;
    end
end

function opts = fillResistanceOptions(opts)
    if ~isfield(opts, 'windowMode')
        opts.windowMode = 'Full pulse median';
    end
    if ~isfield(opts, 'voltageMode')
        opts.voltageMode = 'Baseline-corrected dV/I';
    end
    if ~isfield(opts, 'pulseMode')
        opts.pulseMode = 'Metadata first, then auto';
    end
end

function [curve, ok, msg] = mainCurve(item)
    if isfield(item, 'curve') && ~isempty(item.curve)
        curve = item.curve;
        ok = true;
        msg = sprintf('Using table: %s', curve.name);
    elseif isfield(item, 'tables')
        [curve, ok, msg] = labkit.dta.getMainCurve(item.tables);
    else
        curve = struct();
        ok = false;
        msg = 'Main transient table not found.';
    end
end

function q = safeDivide(a, b)
    if ~isscalar(a) || ~isscalar(b) || ~isfinite(a) || ~isfinite(b) || abs(b) < eps
        q = NaN;
    else
        q = a / b;
    end
end

function v = chooseFinite(varargin)
    v = NaN;
    for k = 1:nargin
        x = varargin{k};
        if isscalar(x) && isfinite(x)
            v = x;
            return;
        end
    end
end

function [t1, t2] = selectSteadyWindow(p1, p2, modeText)
    t1 = p1;
    t2 = p2;
    if strcmp(modeText, 'Center 60% median') && isfinite(p1) && isfinite(p2) && p2 > p1
        dt = p2 - p1;
        t1 = p1 + 0.20 * dt;
        t2 = p1 + 0.80 * dt;
    end
end

function [v, window_s] = estimateBaseline(t, y, t1, t2, fallbackValue)
    if nargin < 5
        fallbackValue = NaN;
    end

    v = medianInWindow(t, y, t1, t2);
    if ~isfinite(v)
        v = fallbackValue;
    end
    window_s = max(0, t2 - t1);
end

function m = medianInWindow(t, y, t1, t2)
    if ~isfinite(t1) || ~isfinite(t2) || t2 < t1
        m = NaN;
        return;
    end

    mask = t >= t1 & t <= t2;
    if ~any(mask)
        m = NaN;
    else
        m = median(y(mask), 'omitnan');
    end
end
