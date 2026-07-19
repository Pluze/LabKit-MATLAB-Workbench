function model = presentationModel(state)
analysis = state.session.cache.analysis;
hasAnalysis = isstruct(analysis) && ~isempty(fieldnames(analysis));
model = struct("analysis", analysis, "hasAnalysis", hasAnalysis, ...
    "previewMode", state.session.view.previewMode, ...
    "statusMessage", state.session.workflow.statusMessage);
end
