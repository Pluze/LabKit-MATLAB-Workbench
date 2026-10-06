function state = invalidate(state, ~, ~)
%INVALIDATE Discard a result after one fusion setting changes.
state.session.cache.result = focus_stack.analysisRun.emptyResult();
state.project.results.registrationLines = strings(0, 1);

state.project.results.lastOutputPath = "";
end
