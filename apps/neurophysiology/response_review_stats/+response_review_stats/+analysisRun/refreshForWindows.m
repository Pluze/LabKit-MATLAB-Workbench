function state = refreshForWindows(state, ~, context)
state.project.parameters.baselineWindowSec = validRange( ...
    state.project.parameters.baselineWindowSec, [0.007 0.009]);
state.project.parameters.noiseWindowSec = validRange( ...
    state.project.parameters.noiseWindowSec, [0.007 0.009]);
state = response_review_stats.analysisRun.refreshMetrics(state, context);
end

function value = validRange(value, fallback)
if ~isnumeric(value) || ~isequal(size(value), [1 2]) || any(~isfinite(value))
    value = fallback;
end
end
