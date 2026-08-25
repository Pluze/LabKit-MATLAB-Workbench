function state = changeProperty(state, value, ~)
state.session.editor.activeProperty = string(value);
state.session.editor.propertyDraft = "";
end
