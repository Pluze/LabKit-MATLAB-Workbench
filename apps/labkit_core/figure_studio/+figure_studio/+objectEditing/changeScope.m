function state = changeScope(state, value, ~)
state.session.editor.activeScope = string(value);
end
