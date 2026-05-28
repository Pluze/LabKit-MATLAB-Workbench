function [pulse, ok, msg] = pulsesFromMetadata(meta, t)
%PULSESFROMMETADATA Detect pulses from ISTEP/TSTEP or VSTEP/TSTEP metadata.

    pulse = gamrywb.analysis.emptyPulse();
    ok = false;

    if isempty(meta) || ~isfield(meta, 'steps') || isempty(meta.steps)
        msg = 'Metadata pulse detection: no ISTEP/TSTEP or VSTEP/TSTEP steps found.';
        pulse.message = msg;
        return;
    end

    steps = meta.steps;
    Ivals = [steps.I];
    Vvals = [steps.V];
    Tvals = [steps.T];
    if all(~isfinite(Tvals))
        msg = 'Metadata pulse detection: invalid step values.';
        pulse.message = msg;
        return;
    end

    stepMode = '';
    stepVals = [];
    if any(isfinite(Ivals))
        stepVals = Ivals;
        stepMode = 'current';
    elseif any(isfinite(Vvals))
        stepVals = Vvals;
        stepMode = 'voltage';
    else
        msg = 'Metadata pulse detection: neither current nor voltage step values were found.';
        pulse.message = msg;
        return;
    end

    [minStep, idxCath] = min(stepVals);
    [maxStep, idxAnod] = max(stepVals);
    if ~isfinite(minStep) || ~isfinite(maxStep) || minStep >= 0 || maxStep <= 0
        msg = sprintf('Metadata pulse detection: could not find both negative and positive %s steps.', stepMode);
        pulse.message = msg;
        return;
    end

    if idxAnod < idxCath
        msg = sprintf('Metadata pulse detection: positive %s step appears before negative step.', stepMode);
        pulse.message = msg;
        return;
    end

    t0 = 0;
    starts = zeros(size(Tvals));
    ends = zeros(size(Tvals));
    for k = 1:numel(Tvals)
        starts(k) = t0;
        ends(k) = t0 + Tvals(k);
        t0 = ends(k);
    end

    pulse.ok = true;
    pulse.method = ['metadata-' stepMode];
    pulse.cath_start = starts(idxCath);
    pulse.cath_end = ends(idxCath);
    pulse.anod_start = starts(idxAnod);
    pulse.anod_end = ends(idxAnod);
    if strcmp(stepMode, 'current')
        pulse.Ic_nominal = Ivals(idxCath);
        pulse.Ia_nominal = Ivals(idxAnod);
    else
        pulse.Ic_nominal = NaN;
        pulse.Ia_nominal = NaN;
    end

    if idxCath > 1
        pulse.pre_start = starts(idxCath - 1);
        pulse.pre_end = ends(idxCath - 1);
    else
        pulse.pre_start = t(1);
        pulse.pre_end = pulse.cath_start;
    end

    if idxAnod > idxCath
        pulse.gap_start = pulse.cath_end;
        pulse.gap_end = pulse.anod_start;
    else
        pulse.gap_start = pulse.cath_end;
        pulse.gap_end = pulse.cath_end;
    end

    if idxAnod < numel(Tvals)
        pulse.post_start = starts(idxAnod + 1);
        pulse.post_end = ends(idxAnod + 1);
    else
        pulse.post_start = pulse.anod_end;
        pulse.post_end = t(end);
    end

    ok = true;
    msg = sprintf('Metadata pulse detection OK (%s-controlled): cath step %d, anod step %d.', ...
        stepMode, idxCath, idxAnod);
    pulse = addNormalizedFields(pulse, msg);
end

function pulse = addNormalizedFields(pulse, msg)
    pulse.message = msg;
    pulse.cath = struct('start_s', pulse.cath_start, 'end_s', pulse.cath_end, 'current_A', pulse.Ic_nominal);
    pulse.anod = struct('start_s', pulse.anod_start, 'end_s', pulse.anod_end, 'current_A', pulse.Ia_nominal);
    pulse.gap = struct('start_s', pulse.gap_start, 'end_s', pulse.gap_end, ...
        'center_s', 0.5 * (pulse.gap_start + pulse.gap_end));
end
