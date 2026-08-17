function state = updateLimits(state, reset)
%UPDATELIMITS Refit only on request or when displayed data leaves the viewport.
arguments
    state (1, 1) struct
    reset (1, 1) logical = false
end
a = state.session.acquisition;
rate_Hz = estimatedRate(a);
current = state.session.cache.plotLimits;
if isempty(a.plotTime_s)
    if reset
        proposed = mark10_monitor.livePlots.defaultLimits(rate_Hz);
    else
        proposed = current;
    end
else
    proposed = current;
    proposed.time_s = refitIfNeeded(current.time_s, ...
        a.plotTime_s, true, reset);
    proposed.force_N = refitIfNeeded(current.force_N, ...
        a.plotForce_N, false, reset);
    proposed.travel_mm = refitIfNeeded(current.travel_mm, ...
        a.plotTravel_mm, false, reset);
end
changed = reset || ~isequaln(current, proposed);
state.session.cache.plotLimits = proposed;
if changed
    state.session.cache.plotViewRevision = ...
        state.session.cache.plotViewRevision + 1;
end
end

function limits = refitIfNeeded(current, values, nonnegative, reset)
values = double(values(isfinite(values)));
if isempty(values)
    limits = current;
    return;
end
outside = min(values) < current(1) || max(values) > current(2);
if reset || outside
    limits = tightDataLimits(values, nonnegative, diff(current));
else
    limits = current;
end
end

function limits = tightDataLimits(values, nonnegative, priorSpan)
dataBounds = [min(values), max(values)];
dataSpan = diff(dataBounds);
if dataSpan > 0
    margin = 0.02 * dataSpan;
else
    level = max(abs(dataBounds));
    margin = max([0.02 * level, 0.01 * priorSpan, eps(max(1, level))]);
end
limits = dataBounds + [-margin, margin];
if nonnegative
    limits(1) = max(0, limits(1));
end
end

function rate_Hz = estimatedRate(acquisition)
rate_Hz = acquisition.actualRate_Hz;
if ~isfinite(rate_Hz) || rate_Hz <= 0
    rate_Hz = str2double(extractBefore(string(acquisition.rate), " "));
end
if ~isfinite(rate_Hz) || rate_Hz <= 0
    rate_Hz = 50;
end
end
