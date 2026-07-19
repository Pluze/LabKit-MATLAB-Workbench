% Expected caller: chrono_overlay.stateHandlers and unit tests. Inputs are
% one chrono item struct with time/current/voltage and pulse fields. Outputs
% return the aligned item and status message. No file or UI side effects.

function [item, msg] = alignByPulseGap(item)
    t = chronoTime(item);
    if isempty(t)
        error('Chrono item has no time vector.');
    end

    pulseMsg = '';
    if isfield(item, 'pulseMessage')
        pulseMsg = item.pulseMessage;
    elseif isfield(item, 'pulse') && isfield(item.pulse, 'message')
        pulseMsg = item.pulse.message;
    end

    pulse = emptyPulse();
    if isfield(item, 'pulse')
        pulse = item.pulse;
    end

    if isfield(item, 'name')
        itemName = item.name;
    else
        itemName = '';
    end

    if isfield(pulse, 'ok') && pulse.ok
        alignTime = 0.5 * (pulse.gap_start + pulse.gap_end);
        if isfinite(alignTime)
            item.alignTime = alignTime;
            item.tAligned = t - alignTime;
            item.alignTime_s = item.alignTime;
            item.tAligned_s = item.tAligned;
            msg = sprintf('%s: aligned to cathodic/anodic blank center at %.9g s (gap %.9g to %.9g s, %s).', ...
                itemName, alignTime, pulse.gap_start, pulse.gap_end, pulse.method);
            return;
        end

        item.alignTime = t(1);
        item.tAligned = t - item.alignTime;
        item.alignTime_s = item.alignTime;
        item.tAligned_s = item.tAligned;
        msg = sprintf('%s: blank center not found, fallback to first sample (%s).', itemName, pulseMsg);
        return;
    end

    item.alignTime = t(1);
    item.tAligned = t - item.alignTime;
    item.alignTime_s = item.alignTime;
    item.tAligned_s = item.tAligned;
    msg = sprintf('%s: pulse gap not found, fallback to first sample (%s).', itemName, pulseMsg);
end

function t = chronoTime(item)
    if isfield(item, 't_s') && ~isempty(item.t_s)
        t = item.t_s;
    elseif isfield(item, 't') && ~isempty(item.t)
        t = item.t;
    else
        t = [];
    end
    t = t(:);
end

function pulse = emptyPulse()
    pulse = struct( ...
        'ok', false, ...
        'method', '-', ...
        'message', '', ...
        'cath_start', NaN, ...
        'cath_end', NaN, ...
        'anod_start', NaN, ...
        'anod_end', NaN, ...
        'Ic_nominal', NaN, ...
        'Ia_nominal', NaN, ...
        'pre_start', NaN, ...
        'pre_end', NaN, ...
        'gap_start', NaN, ...
        'gap_end', NaN, ...
        'post_start', NaN, ...
        'post_end', NaN);

    pulse.cath = struct('start_s', NaN, 'end_s', NaN, 'current_A', NaN);
    pulse.anod = struct('start_s', NaN, 'end_s', NaN, 'current_A', NaN);
    pulse.gap = struct('start_s', NaN, 'end_s', NaN, 'center_s', NaN);
end
