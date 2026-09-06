function A = computeCIC(item, opts)
%COMPUTECIC Calculate charge-injection and voltage-transient metrics.
%
% Usage:
%   A = cic.analysisRun.computeCIC(item)
%   A = cic.analysisRun.computeCIC(item, opts)
%
% Description:
%   Analyzes one biphasic chronopotentiometry transient. The function detects
%   the cathodic and anodic pulse windows, samples the polarization voltage
%   after each phase, integrates injected charge, normalizes charge by
%   electrode area, and checks the measured voltages against the selected
%   cathodic and anodic limits. It performs no plotting or file export.
%
% Inputs:
%   item - Scalar DTA item structure. item.curve, or the main curve selected
%       from item.tables, must provide T in seconds, Vf in volts, and Im in
%       amperes. Pt is optional; sample numbers are generated when it is
%       absent. item.meta may contain pulse metadata and area_cm2.
%   opts - Optional scalar structure. See Options.
%
% Options:
%   delay_s - Time in seconds from the end of each pulse phase to the Emc or
%       Ema sample. The voltage is linearly interpolated at cath_end+delay_s
%       and anod_end+delay_s. Default: 10e-6 seconds.
%   cathLimit - Cathodic water-window limit in volts. Emc passes when
%       Emc >= cathLimit. Default: -0.6 V.
%   anodLimit - Anodic water-window limit in volts. Ema passes when
%       Ema <= anodLimit. Default: 0.8 V.
%   areaOverride - Positive electrode area in square centimetres, supplied as
%       a numeric scalar or numeric text. A valid value takes precedence over
%       area_cm2 and item.meta.area_cm2. Default: "".
%   area_cm2 - Positive numeric electrode area in square centimetres used when
%       areaOverride is empty or invalid. If neither option supplies an area,
%       item.meta.area_cm2 is used. Without a valid area, charge is still
%       calculated but CIC density fields are NaN. Default: NaN.
%   pulseMode - Pulse-detection policy. Allowed display values are "Metadata
%       first, then auto", "Metadata only", and "Auto from Im only". The
%       equivalent values "metadata_first", "metadata_only", and
%       "current_only" are also accepted by labkit.dta.detectPulses. Default:
%       "Metadata first, then auto".
%   usedMeasuredCurrent - Logical scalar. When true, Qc and Qa are the absolute
%       trapezoidal integrals of measured Im over the detected phase windows.
%       When false, charge is the absolute nominal phase current multiplied by
%       phase duration. Default: true.
%
% Calculations:
%   Samples with nonfinite T, Vf, or Im are removed together. At least five remaining
%   samples are required. Emc is Vf at cath_end+delay_s and Ema is Vf at
%   anod_end+delay_s. The cathodic baseline Eipp uses the first finite value in
%   this order: pre-pulse median, interpulse median, post-pulse median, zero.
%   The anodic baseline Eipp_gap prefers the interpulse median, followed by the
%   pre-pulse median, post-pulse median, and Eipp.
%
%   Qc_C and Qa_C are stored as positive charge magnitudes in coulombs;
%   Qt_C = Qc_C + Qa_C. For a valid area, CIC density is
%   1000*Q/area_cm2 in mC/cm^2. CICc_mCcm2, CICa_mCcm2, and CICt_mCcm2 refer
%   to the cathodic, anodic, and summed biphasic charge respectively.
%
% Outputs:
%   A - Scalar result structure. A.ok is true only when curve selection, pulse
%       detection, delayed voltage sampling, and both charge integrations
%       succeed. A.message is "OK" on success and explains the first failed
%       stage otherwise.
%
% Output Fields:
%   ok - Logical success flag.
%   message - "OK" or a description of the first failed stage.
%   delay_s - Effective delayed-voltage sampling interval in seconds.
%   cathLimit - Effective cathodic voltage limit in volts.
%   anodLimit - Effective anodic voltage limit in volts.
%   area_cm2 - Selected positive electrode area in cm^2, or NaN when missing.
%   usedMeasuredCurrent - Effective charge-integration policy.
%   logOnFailure - True for failures that the app should copy into its visible
%       diagnostic log; false for ordinary incomplete-input results.
%   Emc - Delayed cathodic polarization voltage in volts.
%   Ema - Delayed anodic polarization voltage in volts.
%   t_emc - Requested Emc sample time in seconds.
%   t_ema - Requested Ema sample time in seconds.
%   emc_idx - Index of the recorded sample nearest t_emc.
%   ema_idx - Index of the recorded sample nearest t_ema.
%   Epre - Median pre-pulse voltage in volts.
%   Ebetween - Median interpulse voltage in volts.
%   Epost - Median post-pulse voltage in volts.
%   Eipp - Baseline selected for the cathodic phase, in volts.
%   Eipp_gap - Baseline selected for the anodic phase, in volts.
%   baselineCathSource - Text naming the cathodic baseline source.
%   baselineAnodSource - Text naming the anodic baseline source.
%   baselineCathWindow - Two-element time window used for Eipp, in seconds.
%   baselineAnodWindow - Two-element time window used for Eipp_gap, in seconds.
%   Vc_on - Voltage sampled delay_s after cathodic phase onset, in volts.
%   Va_on - Voltage sampled delay_s after anodic phase onset, in volts.
%   t_conset - Requested cathodic onset sample time in seconds.
%   t_aonset - Requested anodic onset sample time in seconds.
%   Va_cath_mag - Absolute Eipp-to-Vc_on voltage change, in volts.
%   Va_anod_mag - Absolute Eipp_gap-to-Va_on voltage change, in volts.
%   tc_s - Cathodic phase duration in seconds.
%   ta_s - Anodic phase duration in seconds.
%   tip_s - Interpulse gap duration in seconds.
%   Ic_est_A - Median measured cathodic current in amperes.
%   Ia_est_A - Median measured anodic current in amperes.
%   cathMask - Logical vector selecting cathodic phase samples.
%   anodMask - Logical vector selecting anodic phase samples.
%   Qc_C - Cathodic charge magnitude in coulombs.
%   Qa_C - Anodic charge magnitude in coulombs.
%   Qt_C - Qc_C + Qa_C in coulombs.
%   CICc_mCcm2 - Cathodic charge density in mC/cm^2.
%   CICa_mCcm2 - Anodic charge density in mC/cm^2.
%   CICt_mCcm2 - Total biphasic charge density in mC/cm^2.
%   cathOK - True when Emc is not below cathLimit.
%   anodOK - True when Ema is not above anodLimit.
%   safe - True when both cathOK and anodOK are true.
%   limitSide - "safe", "cathodic exceeded", "anodic exceeded", or "both
%       exceeded".
%   pulse - Pulse geometry returned by labkit.dta.detectPulses.
%   detectMode - Pulse-detection method that produced pulse.
%   detectMsg - Pulse-detection status message.
%   t - Filtered time vector in seconds.
%   Vf - Filtered voltage vector in volts.
%   Im - Filtered current vector in amperes.
%   pt - Filtered source point numbers or generated zero-based sample numbers.
%   sample_dt - Median difference between consecutive filtered times, in
%       seconds. sample_dt_report contains the same value for exports.
%   ampEstimate_A - Largest absolute filtered current in amperes.
%
% Failure Behavior:
%   Missing curves, too few valid samples, failed pulse detection, an
%   out-of-range delay, or a pulse window with fewer than two samples returns
%   A.ok=false. These data failures normally return a message instead of
%   throwing. Invalid MATLAB types or malformed structures can still raise an
%   error from the DTA access or numeric functions.
%
% Typical Call:
%   [item, status] = labkit.dta.loadFile("pulse.DTA", "chrono");
%   assert(status.ok, status.message)
%   opts = struct( ...
%       "delay_s", 10e-6, ...
%       "cathLimit", -0.6, ...
%       "anodLimit", 0.8, ...
%       "area_cm2", 0.03, ...
%       "pulseMode", "Metadata first, then auto", ...
%       "usedMeasuredCurrent", true);
%   A = cic.analysisRun.computeCIC(item, opts);
%   assert(A.ok, A.message)
%   fprintf("Cathodic CIC: %.4g mC/cm^2\n", A.CICc_mCcm2)
%
% See also labkit.dta.detectPulses, vt_resistance.analysisRun.computeResistance

    if nargin < 2
        opts = struct();
    end
    opts = fillCICOptions(opts);

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

    t = labkit.dta.getColumn(curve, 'T');
    Vf = labkit.dta.getColumn(curve, 'Vf');
    Im = labkit.dta.getColumn(curve, 'Im');
    pt = labkit.dta.getColumn(curve, 'Pt');
    if isempty(pt)
        pt = (0:numel(t)-1).';
    end

    valid = isfinite(t) & isfinite(Vf) & isfinite(Im);
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
    [pulse, pulseMsg] = labkit.dta.detectPulses(t, Im, meta, opts.pulseMode);
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
    if ~V.ok
        A.message = V.message;
        A.logOnFailure = true;
        return;
    end

    Q = computeInjectedCharge(t, Im, pulse, A.usedMeasuredCurrent);
    A = mergeStructs(A, Q);
    if ~Q.ok
        A.message = Q.message;
        return;
    end

    if isfinite(A.area_cm2) && A.area_cm2 > 0
        % Constant: 1000 converts coulombs to millicoulombs for CIC density.
        millicoulombsPerCoulomb = 1e3;
        A.CICc_mCcm2 = millicoulombsPerCoulomb * A.Qc_C / A.area_cm2;
        A.CICa_mCcm2 = millicoulombsPerCoulomb * A.Qa_C / A.area_cm2;
        A.CICt_mCcm2 = millicoulombsPerCoulomb * A.Qt_C / A.area_cm2;
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

function opts = fillCICOptions(opts)
    if ~isfield(opts, 'delay_s')
        % Constant: 10 microseconds is the app's default post-pulse sampling
        % delay for estimating maximum polarization voltage.
        defaultDelaySeconds = 10e-6;
        opts.delay_s = defaultDelaySeconds;
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
        choices = cic.analysisRun.analysisChoices();
        opts.pulseMode = char(choices.pulseModes(1));
    end
    if ~isfield(opts, 'usedMeasuredCurrent')
        opts.usedMeasuredCurrent = true;
    end
end

function area = chooseArea(item, opts)
    area = NaN;
    if isfield(opts, 'areaOverride')
        area = parsePositiveScalar(opts.areaOverride);
    end
    if ~isfinite(area) && isfield(opts, 'area_cm2')
        area = parsePositiveScalar(opts.area_cm2);
    end
    if ~isfinite(area) && isfield(item, 'meta') && isfield(item.meta, 'area_cm2') ...
            && isfinite(item.meta.area_cm2) && item.meta.area_cm2 > 0
        area = item.meta.area_cm2;
    end
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

function out = mergeStructs(out, in)
    names = fieldnames(in);
    for i = 1:numel(names)
        out.(names{i}) = in.(names{i});
    end
end

function V = computeVoltageTransientMetrics(t, Vf, pulse, delay_s)
    V = struct();
    V.t_emc = pulse.cath.end_s + delay_s;
    V.t_ema = pulse.anod.end_s + delay_s;
    V.ok = V.t_emc >= min(t) && V.t_emc <= max(t) && ...
        V.t_ema >= min(t) && V.t_ema <= max(t);
    if ~V.ok
        % Constant: one million converts seconds to microseconds for UI text.
        microsecondsPerSecond = 1e6;
        V.message = sprintf(['Sample delay %.6g us places Emc or Ema outside ' ...
            'the recorded time range.'], microsecondsPerSecond * delay_s);
        return;
    end
    V.message = 'OK';
    V.emc_idx = nearestIndex(t, V.t_emc);
    V.ema_idx = nearestIndex(t, V.t_ema);
    V.Emc = interp1Safe(t, Vf, V.t_emc);
    V.Ema = interp1Safe(t, Vf, V.t_ema);

    V.Epre = medianInWindow(t, Vf, pulse.pre.start_s, pulse.pre.end_s);
    V.Ebetween = medianInWindow(t, Vf, pulse.gap.start_s, pulse.gap.end_s);
    V.Epost = medianInWindow(t, Vf, pulse.post.start_s, pulse.post.end_s);
    [V.Eipp, V.baselineCathSource, V.baselineCathWindow] = chooseBaselineCandidate( ...
        [V.Epre, V.Ebetween, V.Epost, 0], ...
        {'pre-pulse median', 'interpulse median', 'post-pulse median', 'zero fallback'}, ...
        [pulse.pre.start_s pulse.pre.end_s; pulse.gap.start_s pulse.gap.end_s; pulse.post.start_s pulse.post.end_s; NaN NaN]);
    [V.Eipp_gap, V.baselineAnodSource, V.baselineAnodWindow] = chooseBaselineCandidate( ...
        [V.Ebetween, V.Epre, V.Epost, V.Eipp], ...
        {'interpulse median', 'pre-pulse median', 'post-pulse median', 'cathodic baseline fallback'}, ...
        [pulse.gap.start_s pulse.gap.end_s; pulse.pre.start_s pulse.pre.end_s; pulse.post.start_s pulse.post.end_s; V.baselineCathWindow]);

    V.tc_s = max(0, pulse.cath.end_s - pulse.cath.start_s);
    V.ta_s = max(0, pulse.anod.end_s - pulse.anod.start_s);
    V.tip_s = max(0, pulse.anod.start_s - pulse.cath.end_s);
    V.t_conset = pulse.cath.start_s + delay_s;
    V.t_aonset = pulse.anod.start_s + delay_s;
    V.Vc_on = interp1Safe(t, Vf, V.t_conset);
    V.Va_on = interp1Safe(t, Vf, V.t_aonset);
    V.Va_cath_mag = abs(V.Eipp - V.Vc_on);
    V.Va_anod_mag = abs(V.Eipp_gap - V.Va_on);
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

function v = interp1Safe(x, y, xq)
    if numel(x) < 2 || any(~isfinite([x(:); y(:)])) || ...
            xq < min(x) || xq > max(x)
        v = NaN;
        return;
    end

    try
        v = interp1(x, y, xq, 'linear');
    catch
        idx = nearestIndex(x, xq);
        v = y(idx);
    end
end

function idx = nearestIndex(x, xq)
    [~, idx] = min(abs(x - xq));
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

function Q = computeInjectedCharge(t, Im, pulse, useMeasuredCurrent)
    if nargin < 4
        useMeasuredCurrent = true;
    end

    Q = struct();
    cathMask = (t >= pulse.cath.start_s) & (t <= pulse.cath.end_s);
    anodMask = (t >= pulse.anod.start_s) & (t <= pulse.anod.end_s);
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
        Q.Ic_est_A = pulse.cath.current_A;
    end
    if ~isfinite(Q.Ia_est_A)
        Q.Ia_est_A = pulse.anod.current_A;
    end

    if useMeasuredCurrent
        Qc = abs(trapz(t(cathMask), Im(cathMask)));
        Qa = abs(trapz(t(anodMask), Im(anodMask)));
    else
        Qc = abs(pulse.cath.current_A * (pulse.cath.end_s - pulse.cath.start_s));
        Qa = abs(pulse.anod.current_A * (pulse.anod.end_s - pulse.anod.start_s));
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
