% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function [pulse, ok, msg] = pulsesFromMetadata(meta, t)
%PULSESFROMMETADATA Detect pulse windows from chrono step metadata.
%
% Called by:
%   detectPulseCore in metadata-first or metadata-only modes.
%
% Inputs:
%   meta - chrono parser metadata with steps containing I, V, and T fields.
%   t - measured time vector used to clamp derived windows to available data.
%
% Outputs:
%   pulse - pulse struct with cathodic/anodic/gap windows when ok.
%   ok - true when negative and positive current/voltage steps are usable.
%   msg - detection status for logs and item.message.
%
% Notes:
%   Current-step metadata is preferred when present; otherwise voltage-step
%   metadata is used with NaN nominal currents in the pulse struct.

    pulse = emptyPulse();
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
    cathCurrent = NaN;
    anodCurrent = NaN;
    if strcmp(stepMode, 'current')
        cathCurrent = Ivals(idxCath);
        anodCurrent = Ivals(idxAnod);
    end

    if idxCath > 1
        preStart = starts(idxCath - 1);
        preEnd = ends(idxCath - 1);
    else
        preStart = t(1);
        preEnd = starts(idxCath);
    end

    if idxAnod > idxCath
        gapStart = ends(idxCath);
        gapEnd = starts(idxAnod);
    else
        gapStart = ends(idxCath);
        gapEnd = ends(idxCath);
    end

    if idxAnod < numel(Tvals)
        postStart = starts(idxAnod + 1);
        postEnd = ends(idxAnod + 1);
    else
        postStart = ends(idxAnod);
        postEnd = t(end);
    end
    pulse.pre = struct('start_s', preStart, 'end_s', preEnd);
    pulse.cath = struct('start_s', starts(idxCath), ...
        'end_s', ends(idxCath), 'current_A', cathCurrent);
    pulse.gap = struct('start_s', gapStart, 'end_s', gapEnd, ...
        'center_s', 0.5 * (gapStart + gapEnd));
    pulse.anod = struct('start_s', starts(idxAnod), ...
        'end_s', ends(idxAnod), 'current_A', anodCurrent);
    pulse.post = struct('start_s', postStart, 'end_s', postEnd);

    ok = true;
    msg = sprintf('Metadata pulse detection OK (%s-controlled): cath step %d, anod step %d.', ...
        stepMode, idxCath, idxAnod);
    pulse.message = msg;
end
