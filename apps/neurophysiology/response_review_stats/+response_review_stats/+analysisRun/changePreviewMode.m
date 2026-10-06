function state = changePreviewMode(state, value, ~)
value = string(value);
if isscalar(value) && any(value == ["Summary", "Aligned"])
    state.session.view.previewMode = value;
end
end
