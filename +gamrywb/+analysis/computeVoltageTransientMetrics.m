function V = computeVoltageTransientMetrics(t, Vf, pulse, delay_s)
%COMPUTEVOLTAGETRANSIENTMETRICS Compute legacy VT timing and voltage metrics.

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
