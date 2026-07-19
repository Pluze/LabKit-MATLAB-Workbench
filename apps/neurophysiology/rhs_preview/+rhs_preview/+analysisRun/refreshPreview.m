function state = refreshPreview(state, ~)
state.session = rhs_preview.createSession(state.project, labkit.app.CallbackContext());
end
