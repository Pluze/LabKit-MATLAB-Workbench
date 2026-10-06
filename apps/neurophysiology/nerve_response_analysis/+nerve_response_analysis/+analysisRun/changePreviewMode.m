function state = changePreviewMode(state, value, ~)
value = string(value);
if isscalar(value) && any(value == ["Counts", "Issues"])
    state.session.view.previewMode = value;
end
end
