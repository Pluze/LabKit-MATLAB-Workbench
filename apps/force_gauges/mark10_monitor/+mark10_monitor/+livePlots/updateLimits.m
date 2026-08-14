function state = updateLimits(state, reset)
%UPDATELIMITS Expand buffered plot limits only after displayed data escapes.
arguments
    state (1, 1) struct
    reset (1, 1) logical = false
end
a = state.session.acquisition;
rate_Hz = estimatedRate(a);
policy = mark10_monitor.livePlots.limitPolicy(rate_Hz);
current = state.session.cache.plotLimits;
if isempty(a.plotTime_s)
    proposed = mark10_monitor.livePlots.defaultLimits(rate_Hz);
else
    proposed = current;
    proposed.time_s = bufferedLimits(current.time_s, a.plotTime_s, ...
        policy.timeMargin_s, reset, true);
    proposed.force_N = bufferedLimits(current.force_N, a.plotForce_N, ...
        estimatedSignalMargin(a.plotForce_N), reset, false);
    proposed.travel_mm = bufferedLimits(current.travel_mm, a.plotTravel_mm, ...
        estimatedSignalMargin(a.plotTravel_mm), reset, false);
end
changed = reset || ~isequaln(current, proposed);
state.session.cache.plotLimits = proposed;
if changed
    state.session.cache.plotViewRevision = ...
        state.session.cache.plotViewRevision + 1;
end
end

function margin = estimatedSignalMargin(values)
% Predict a bounded block of recent motion without a fixed unit margin.
values = double(values(isfinite(values)));
span = max(values) - min(values);
level = max(abs(values));
recent = values(max(1, end - 100):end);
steps = abs(diff(recent));
if isempty(steps)
    predicted = 0;
else
    predicted = median(steps) * min(100, numel(steps));
end
margin = max([0.1 * span, 0.1 * level, predicted, eps(max(1, level))]);
end

function limits = bufferedLimits(current, values, margin, reset, nonnegative)
values = double(values(isfinite(values)));
if isempty(values)
    limits = current;
    return;
end
dataLimits = [min(values), max(values)];
if reset
    limits = dataLimits + [-margin, margin];
else
    limits = current;
    if dataLimits(1) < current(1)
        limits(1) = dataLimits(1) - margin;
    end
    if dataLimits(2) > current(2)
        limits(2) = dataLimits(2) + margin;
    end
end
if nonnegative
    limits(1) = max(0, limits(1));
end
if diff(limits) <= 0
    limits = limits(1) + [0, 2 * margin];
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
