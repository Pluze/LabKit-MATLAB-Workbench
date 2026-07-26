% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function [pulse, ok, msg] = pulsesFromCurrent(t, Im)
%PULSESFROMCURRENT Detect cathodic/anodic pulse windows from current data.
%
% Called by:
%   detectPulseCore when metadata is absent or current-only mode is selected.
%
% Inputs:
%   t - time vector in seconds.
%   Im - measured current vector in ampere, same length/order as t.
%
% Outputs:
%   pulse - pulse struct with unit-explicit phase windows populated when ok.
%   ok - true when both cathodic and later anodic segments are found.
%   msg - detection status for DTA item logs.
%
% Notes:
%   The segment threshold is 25 percent of max(abs(Im)) with a small floor.
%   This is a fallback detector, not an app-facing analysis API.

    pulse = emptyPulse();
    ok = false;

    Iabs = abs(Im);
    % Constant: the 1e-12 A floor avoids a zero detector threshold for
    % numerically quiet traces; 25 percent selects dominant pulse segments.
    currentFloorA = 1e-12;
    dominantPulseFraction = 0.25;
    thr = max(currentFloorA, dominantPulseFraction * max(Iabs));
    cathMask = Im <= -thr;
    anodMask = Im >= thr;

    cathSeg = contiguousSegments(cathMask);
    anodSeg = contiguousSegments(anodMask);

    if isempty(cathSeg) || isempty(anodSeg)
        msg = 'Auto pulse detection: could not find both cathodic and anodic segments.';
        pulse.message = msg;
        return;
    end

    cathLen = cathSeg(:, 2) - cathSeg(:, 1) + 1;
    [~, ic] = max(cathLen);
    cseg = cathSeg(ic, :);

    asegCandidates = anodSeg(anodSeg(:, 1) > cseg(2), :);
    if isempty(asegCandidates)
        msg = 'Auto pulse detection: found cathodic segment but no later anodic segment.';
        pulse.message = msg;
        return;
    end

    anodLen = asegCandidates(:, 2) - asegCandidates(:, 1) + 1;
    [~, ia] = max(anodLen);
    aseg = asegCandidates(ia, :);

    pulse.ok = true;
    pulse.method = 'auto-from-Im';
    pulse.pre = struct('start_s', t(1), 'end_s', t(cseg(1)));
    pulse.cath = struct( ...
        'start_s', t(cseg(1)), ...
        'end_s', t(cseg(2)), ...
        'current_A', median(Im(cseg(1):cseg(2)), 'omitnan'));
    pulse.gap = struct( ...
        'start_s', pulse.cath.end_s, ...
        'end_s', t(aseg(1)), ...
        'center_s', 0.5 * (pulse.cath.end_s + t(aseg(1))));
    pulse.anod = struct( ...
        'start_s', t(aseg(1)), ...
        'end_s', t(aseg(2)), ...
        'current_A', median(Im(aseg(1):aseg(2)), 'omitnan'));
    pulse.post = struct('start_s', pulse.anod.end_s, 'end_s', t(end));

    ok = true;
    msg = sprintf('Auto pulse detection OK: cath [%d %d], anod [%d %d].', cseg(1), cseg(2), aseg(1), aseg(2));
    pulse.message = msg;
end

function seg = contiguousSegments(mask)
    mask = mask(:).';
    d = diff([false, mask, false]);
    starts = find(d == 1);
    ends = find(d == -1) - 1;
    seg = [starts(:), ends(:)];
end
