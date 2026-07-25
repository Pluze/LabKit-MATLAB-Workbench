function A = computeResistance(item, opts)
%COMPUTERESISTANCE Estimate cathodic and anodic resistance from a VT pulse.
%
% Usage:
%   A = vt_resistance.analysisRun.computeResistance(item)
%   A = vt_resistance.analysisRun.computeResistance(item, opts)
%
% Inputs:
%   item - Scalar DTA item struct. item.curve, or the main curve selected from
%       item.tables, must provide T in seconds, Vf in volts, and Im in amperes.
%       Pt is optional; zero-based sample numbers are generated when absent.
%       item.meta may contain pulse timing and current metadata.
%   opts - Optional scalar struct described below. Default: struct().
%
% Options:
%   windowMode - Samples used for steady voltage/current medians: "Full pulse
%       median" or "Center 60% median". The latter excludes the first and last
%       20% of each detected phase. Default: "Full pulse median".
%   voltageMode - Resistance numerator: "Baseline-corrected dV/I" or "Raw
%       Vf/I". Default: "Baseline-corrected dV/I".
%   pulseMode - Pulse-detection policy: "Metadata first, then auto", "Metadata
%       only", or "Auto from Im only". Default: "Metadata first, then auto".
%
% Outputs:
%   A - Scalar result struct. Success is indicated by A.ok and A.message="OK".
%       Data-validation failures return ok=false and the fields calculated up
%       to the failed stage.
%
% Result Fields:
%   ok - True when the final mean absolute resistance is finite.
%   message - "OK" or an explanation of the first failed stage.
%   windowMode - Effective steady-window label.
%   voltageMode - Effective voltage-numerator label.
%   logOnFailure - True when the app should surface the failure in its log.
%   t - Filtered time vector in seconds.
%   Vf - Filtered voltage vector in volts.
%   Im - Filtered current vector in amperes.
%   pt - Filtered source point numbers or generated zero-based sample numbers.
%   pulse - Pulse geometry returned by labkit.dta.detectPulses.
%   detectMode - Detection method that produced pulse.
%   detectMsg - Pulse-detection status message.
%   cathMask - Logical samples in the selected cathodic steady window.
%   anodMask - Logical samples in the selected anodic steady window.
%   cathSteadyStart, cathSteadyEnd - Cathodic steady-window bounds in seconds.
%   anodSteadyStart, anodSteadyEnd - Anodic steady-window bounds in seconds.
%   Ic_est_A - Median cathodic current in amperes.
%   Ia_est_A - Median anodic current in amperes.
%   Vc_ss_V - Median cathodic steady voltage in volts.
%   Va_ss_V - Median anodic steady voltage in volts.
%   cathBaselineStart, cathBaselineEnd - Requested pre-pulse cathodic baseline
%       bounds in seconds.
%   anodBaselineStart, anodBaselineEnd - Requested post-pulse anodic baseline
%       bounds in seconds.
%   Vc_baseline_V - Median pre-pulse voltage, or 0 when unavailable.
%   Va_baseline_V - Median post-pulse voltage; falls back to the cathodic
%       baseline and then 0.
%   cathBaselineWindow_s - Duration of the requested cathodic baseline window.
%   anodBaselineWindow_s - Duration of the requested anodic baseline window.
%   dVc_V - Vc_ss_V-Vc_baseline_V in volts.
%   dVa_V - Va_ss_V-Va_baseline_V in volts.
%   Rc_raw_ohm - Vc_ss_V/Ic_est_A in ohms.
%   Ra_raw_ohm - Va_ss_V/Ia_est_A in ohms.
%   Rc_dV_ohm - dVc_V/Ic_est_A in ohms.
%   Ra_dV_ohm - dVa_V/Ia_est_A in ohms.
%   Rc_ohm - Selected cathodic raw or baseline-corrected resistance.
%   Ra_ohm - Selected anodic raw or baseline-corrected resistance.
%   Rc_abs_ohm - Absolute Rc_ohm.
%   Ra_abs_ohm - Absolute Ra_ohm.
%   Ravg_abs_ohm - Mean of the finite absolute cathodic and anodic values.
%
% Description:
%   computeResistance analyzes one detected biphasic voltage transient and
%   reports phase-specific as well as averaged resistance. Apps may choose raw
%   steady voltage or subtract the adjacent baseline before division. The
%   function performs no plotting, file selection, or export.
%
% Calculations:
%   Rows containing NaN in T, Vf, or Im are removed together. Pulse detection
%   is delegated to labkit.dta.detectPulses. Steady values are phase-window
%   medians. Division returns NaN when either operand is nonfinite or current is
%   smaller than eps in magnitude. The reported average uses absolute phase
%   resistances so opposite current signs do not cancel.
%
% Failure Behavior:
%   Missing curve data, fewer than five remaining samples, failed pulse
%   detection, undersampled steady windows, or nonfinite final resistance
%   returns ok=false. Malformed structs and unsupported MATLAB value types may
%   still throw from DTA access or numeric operations.
%
% Typical Call:
%   [item, status] = labkit.dta.loadFile("transient.DTA", "chrono");
%   assert(status.ok, status.message)
%   opts = struct("windowMode", "Center 60% median", ...
%       "voltageMode", "Baseline-corrected dV/I", ...
%       "pulseMode", "Metadata first, then auto");
%   A = vt_resistance.analysisRun.computeResistance(item, opts);
%   assert(A.ok, A.message)
%   fprintf("Mean resistance: %.4g ohm\n", A.Ravg_abs_ohm)
%
% See also labkit.dta.detectPulses, cic.analysisRun.computeCIC

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

    [cStart, cEnd] = selectSteadyWindow(pulse.cath.start_s, pulse.cath.end_s, A.windowMode);
    [aStart, aEnd] = selectSteadyWindow(pulse.anod.start_s, pulse.anod.end_s, A.windowMode);
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

    A.cathBaselineStart = pulse.pre.start_s;
    A.cathBaselineEnd = pulse.pre.end_s;
    A.anodBaselineStart = pulse.post.start_s;
    A.anodBaselineEnd = pulse.post.end_s;
    [A.Vc_baseline_V, A.cathBaselineWindow_s] = estimateBaseline( ...
        t, Vf, pulse.pre.start_s, pulse.pre.end_s, 0);
    [A.Va_baseline_V, A.anodBaselineWindow_s] = estimateBaseline( ...
        t, Vf, pulse.post.start_s, pulse.post.end_s, chooseFinite(A.Vc_baseline_V, 0));

    A.dVc_V = A.Vc_ss_V - A.Vc_baseline_V;
    A.dVa_V = A.Va_ss_V - A.Va_baseline_V;
    A.Rc_raw_ohm = safeDivide(A.Vc_ss_V, A.Ic_est_A);
    A.Ra_raw_ohm = safeDivide(A.Va_ss_V, A.Ia_est_A);
    A.Rc_dV_ohm = safeDivide(A.dVc_V, A.Ic_est_A);
    A.Ra_dV_ohm = safeDivide(A.dVa_V, A.Ia_est_A);

    choices = vt_resistance.analysisRun.analysisChoices();
    if string(A.voltageMode) == choices.voltageModes(2)
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
    choices = vt_resistance.analysisRun.analysisChoices();
    if ~isfield(opts, 'windowMode')
        opts.windowMode = choices.steadyWindows(1);
    end
    if ~isfield(opts, 'voltageMode')
        opts.voltageMode = choices.voltageModes(1);
    end
    if ~isfield(opts, 'pulseMode')
        opts.pulseMode = choices.pulseModes(1);
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
    choices = vt_resistance.analysisRun.analysisChoices();
    if string(modeText) == choices.steadyWindows(2) && ...
            isfinite(p1) && isfinite(p2) && p2 > p1
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
