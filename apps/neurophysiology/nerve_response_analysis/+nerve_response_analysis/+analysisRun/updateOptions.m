function state = updateOptions(state, ~, ~)
state.project.parameters.maxRecordings = finiteNonnegative( ...
    state.project.parameters.maxRecordings);
state.project.parameters.maxDurationSec = finiteNonnegative( ...
    state.project.parameters.maxDurationSec);
state.project.results.lastExport = [];
state.session.cache.analysis = [];
end

function value = finiteNonnegative(value)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    value = 0;
else
    value = max(0, double(value));
end
end
