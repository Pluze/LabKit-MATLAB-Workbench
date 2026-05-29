function [item, msg] = alignByPulseGap(item)
%ALIGNBYPULSEGAP Align chrono item time to the blank pulse gap center.

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

    pulse = gamrywb.analysis.emptyPulse();
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
    if isfield(item, 't') && ~isempty(item.t)
        t = item.t;
    elseif isfield(item, 't_s') && ~isempty(item.t_s)
        t = item.t_s;
    else
        t = [];
    end
    t = t(:);
end
