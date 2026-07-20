% App-owned implementation for nerve_response_analysis.analysisRun.changePreviewMode within the nerve_response_analysis product workflow.
function state = changePreviewMode(state, value, ~)
value = string(value);
if isscalar(value) && any(value == ["Counts", "Issues"])
    state.session.view.previewMode = value;
end
end
