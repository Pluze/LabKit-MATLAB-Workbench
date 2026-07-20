% App-owned implementation for focus_stack.analysisRun.invalidate within the focus_stack product workflow.
function state = invalidate(state, ~, ~)
%INVALIDATE Discard a result after one fusion setting changes.
state.session.cache.alignedImages = {};
state.session.cache.result = focus_stack.analysisRun.emptyResult();
state.session.cache.currentFingerprint = "";
state.project.results.lastRun = focus_stack.analysisRun.emptyResult();
state.project.results.lastRunFingerprint = "";
state.project.results.registrationLines = strings(0, 1);
state.project.results.lastExport = [];
state.project.results.resultManifestPath = "";
end
