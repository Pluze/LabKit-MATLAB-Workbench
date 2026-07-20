% App-owned implementation for response_review_stats.analysisRun.changePreviewMode within the response_review_stats product workflow.
function state = changePreviewMode(state, value, ~)
value = string(value);
if isscalar(value) && any(value == ["Summary", "Aligned"])
    state.session.view.previewMode = value;
end
end
