function state = updateLimits(state, reset)
%UPDATELIMITS Derive one path-independent viewport from displayed samples.
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
    proposed = struct( ...
        "time_s", dataLimits(a.plotTime_s, policy.timeMargin_s, true), ...
        "force_N", dataLimits(a.plotForce_N, ...
            estimatedSignalMargin(a.plotForce_N), false), ...
        "travel_mm", dataLimits(a.plotTravel_mm, ...
            estimatedSignalMargin(a.plotTravel_mm), false));
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

function limits = dataLimits(values, margin, nonnegative)
values = double(values(isfinite(values)));
limits = [min(values), max(values)] + [-margin, margin];
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
