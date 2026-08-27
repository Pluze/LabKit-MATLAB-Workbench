% Expected callers: Chrono source loading and direct tests. Inputs are
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
        alignTime = 0.5 * (pulse.gap.start_s + pulse.gap.end_s);
        if isfinite(alignTime)
            item.alignTime_s = alignTime;
            item.tAligned_s = t - alignTime;
            msg = sprintf('%s: aligned to cathodic/anodic blank center at %.9g s (gap %.9g to %.9g s, %s).', ...
                itemName, alignTime, pulse.gap.start_s, pulse.gap.end_s, pulse.method);
            return;
        end

        item.alignTime_s = t(1);
        item.tAligned_s = t - item.alignTime_s;
        msg = sprintf('%s: blank center not found, fallback to first sample (%s).', itemName, pulseMsg);
        return;
    end

    item.alignTime_s = t(1);
    item.tAligned_s = t - item.alignTime_s;
    msg = sprintf('%s: pulse gap not found, fallback to first sample (%s).', itemName, pulseMsg);
end

function t = chronoTime(item)
    if ~isfield(item, 't_s') || isempty(item.t_s)
        t = [];
    else
        t = item.t_s;
    end
    t = t(:);
end

function pulse = emptyPulse()
    pulse = struct('ok', false, 'method', '-', 'message', '');
    pulse.pre = struct('start_s', NaN, 'end_s', NaN);
    pulse.cath = struct('start_s', NaN, 'end_s', NaN, 'current_A', NaN);
    pulse.gap = struct('start_s', NaN, 'end_s', NaN, 'center_s', NaN);
    pulse.anod = struct('start_s', NaN, 'end_s', NaN, 'current_A', NaN);
    pulse.post = struct('start_s', NaN, 'end_s', NaN);
end
