function state = updateOptions(state, ~, ~)
state.project.parameters.maxRecordings = finiteNonnegative( ...
    state.project.parameters.maxRecordings);
state.project.parameters.maxDurationSec = finiteNonnegative( ...
    state.project.parameters.maxDurationSec);
state.project.results.lastExport = [];
if isstruct(state.session.cache.analysis) && ...
        ~isempty(state.session.cache.analysis) && ...
        ~isempty(fieldnames(state.session.cache.analysis))
    state.session.workflow.statusMessage = ...
        "Analysis options changed. Analyze session to refresh.";
end
state.session.cache.analysis = [];
state.session.workflow.lastAction = "Updated analysis options";
end

function value = finiteNonnegative(value)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    value = 0;
else
    value = max(0, double(value));
end
end
