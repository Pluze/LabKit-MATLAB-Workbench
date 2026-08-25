function state = changeDraft(state, value, ~)
state.session.editor.propertyDraft = string(value);
end
